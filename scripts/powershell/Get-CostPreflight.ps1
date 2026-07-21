#requires -Version 7.0
[CmdletBinding()]
param(
    [ValidateSet('westeurope', 'northeurope')]
    [string]$Location = 'westeurope',
    [string]$VmSize = 'Standard_B1s',
    [ValidatePattern('^[A-Z]{3}$')]
    [string]$CurrencyCode = 'USD',
    [string]$OutputPath = '.lab/preflight.json'
)

$ErrorActionPreference = 'Stop'
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    throw 'Azure CLI is required. This script never signs in or changes the active subscription.'
}

function Invoke-AzJson {
    param([Parameter(Mandatory)][string[]]$Arguments)

    $output = & az @Arguments 2>$null
    if ($LASTEXITCODE -ne 0) { return $null }
    if (-not $output) { return $null }
    return $output | ConvertFrom-Json
}

function Get-RetailMeters {
    param([Parameter(Mandatory)][string]$Filter)

    $encoded = [Uri]::EscapeDataString($Filter)
    $uri = "https://prices.azure.com/api/retail/prices?currencyCode='$CurrencyCode'&`$filter=$encoded"
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Get
        return @($response.Items | Select-Object -First 50 `
                currencyCode, retailPrice, unitOfMeasure, armRegionName,
                serviceName, productName, skuName, meterName, armSkuName)
    }
    catch {
        return @([pscustomobject]@{
                status = 'unknown'
                error  = $_.Exception.Message
            })
    }
}

$account = Invoke-AzJson -Arguments @(
    'account', 'show',
    '--query', '{state:state,environment:environmentName,userType:user.type}',
    '--output', 'json'
)
if (-not $account -or $account.state -ne 'Enabled') {
    throw 'An enabled Azure CLI context is required. Authenticate separately; this script will not authenticate.'
}

$subscriptionId = & az account show --query id --output tsv
if ($LASTEXITCODE -ne 0 -or -not $subscriptionId) {
    throw 'The active subscription could not be resolved.'
}

$policy = Invoke-AzJson -Arguments @(
    'rest', '--method', 'get',
    '--url', "https://management.azure.com/subscriptions/$subscriptionId`?api-version=2022-12-01",
    '--query', 'subscriptionPolicies.{offerCategory:quotaId,spendingLimit:spendingLimit}',
    '--output', 'json'
)

$balance = Invoke-AzJson -Arguments @(
    'consumption', 'balance', 'show',
    '--query', '{currency:currency,currentBalance:currentBalance}',
    '--output', 'json'
)
$budgets = Invoke-AzJson -Arguments @(
    'consumption', 'budget', 'list',
    '--query', '[].{name:name,amount:amount,timeGrain:timeGrain}',
    '--output', 'json'
)

$providers = foreach ($namespace in @(
        'Microsoft.Network',
        'Microsoft.Compute',
        'Microsoft.Storage',
        'Microsoft.Insights',
        'Microsoft.OperationalInsights',
        'Microsoft.ManagedIdentity',
        'Microsoft.DevTestLab'
    )) {
    $provider = Invoke-AzJson -Arguments @(
        'provider', 'show',
        '--namespace', $namespace,
        '--query', '{namespace:namespace,state:registrationState}',
        '--output', 'json'
    )
    if ($provider) { $provider } else {
        [pscustomobject]@{ namespace = $namespace; state = 'unknown' }
    }
}

$sku = Invoke-AzJson -Arguments @(
    'vm', 'list-skus',
    '--location', $Location,
    '--size', $VmSize,
    '--all',
    '--query', '[].{name:name,restrictions:restrictions,capabilities:capabilities}',
    '--output', 'json'
)
$computeQuota = Invoke-AzJson -Arguments @(
    'vm', 'list-usage',
    '--location', $Location,
    '--query', "[?contains(localName.value, 'Total Regional') || contains(localName.value, 'standard BS')].{name:localName.value,current:currentValue,limit:limit}",
    '--output', 'json'
)
$networkQuota = Invoke-AzJson -Arguments @(
    'network', 'list-usages',
    '--location', $Location,
    '--query', "[?contains(name.localizedValue, 'Public IP')].{name:name.localizedValue,current:currentValue,limit:limit}",
    '--output', 'json'
)
$imagePlan = Invoke-AzJson -Arguments @(
    'vm', 'image', 'show',
    '--urn', 'Canonical:0001-com-ubuntu-server-jammy:22_04-lts-gen2:latest',
    '--query', '{plan:plan,publisher:publisher,offer:offer,sku:sku}',
    '--output', 'json'
)

$prices = [ordered]@{
    virtualMachine = Get-RetailMeters "serviceName eq 'Virtual Machines' and armRegionName eq '$Location' and armSkuName eq '$VmSize' and priceType eq 'Consumption'"
    managedDisk    = Get-RetailMeters "serviceName eq 'Storage' and armRegionName eq '$Location' and skuName eq 'E4 LRS' and priceType eq 'Consumption'"
    networking     = Get-RetailMeters "serviceName eq 'Virtual Network' and armRegionName eq '$Location' and priceType eq 'Consumption'"
    blobStorage    = Get-RetailMeters "serviceName eq 'Storage' and armRegionName eq '$Location' and skuName eq 'Hot LRS' and priceType eq 'Consumption'"
    privateLink    = Get-RetailMeters "armRegionName eq '$Location' and contains(productName, 'Private Link') and priceType eq 'Consumption'"
    privateDns     = Get-RetailMeters "serviceName eq 'Azure DNS' and priceType eq 'Consumption'"
    azureMonitor   = Get-RetailMeters "serviceName eq 'Azure Monitor' and armRegionName eq '$Location' and priceType eq 'Consumption'"
}

$developerRegions = @(
    'francecentral', 'germanywestcentral', 'italynorth', 'northeurope',
    'norwayeast', 'spaincentral', 'swedencentral', 'switzerlandnorth',
    'uksouth', 'ukwest', 'westeurope'
)

$report = [ordered]@{
    generatedAtUtc = (Get-Date).ToUniversalTime().ToString('o')
    expiresAtUtc   = (Get-Date).ToUniversalTime().AddHours(24).ToString('o')
    location       = $Location
    currency       = $CurrencyCode
    subscription   = [ordered]@{
        configured   = $true
        state        = $account.state
        environment  = $account.environment
        userType     = $account.userType
        offerCategory = if ($policy) { $policy.offerCategory } else { 'unknown' }
        spendingLimit = if ($policy) { $policy.spendingLimit } else { 'unknown' }
    }
    promotionalCredit = if ($balance) { $balance } else {
        [ordered]@{ status = 'unknown'; reason = 'Billing scope or permission did not expose a balance.' }
    }
    freeServices = [ordered]@{
        status = 'unknown'
        reason = 'Advertised free services are not treated as subscription entitlement. Verify current portal allocation and usage.'
    }
    budgets = if ($null -ne $budgets) { @($budgets) } else {
        @([ordered]@{ status = 'unknown'; reason = 'Budget API unavailable at this billing scope.' })
    }
    providerRegistrations = @($providers)
    vmSku                 = if ($sku) { @($sku) } else { @([ordered]@{ status = 'unknown' }) }
    computeQuota          = if ($computeQuota) { @($computeQuota) } else { @([ordered]@{ status = 'unknown' }) }
    publicIpQuota         = if ($networkQuota) { @($networkQuota) } else { @([ordered]@{ status = 'unknown' }) }
    image                 = if ($imagePlan) { $imagePlan } else { [ordered]@{ status = 'unknown' } }
    bastionDeveloper      = [ordered]@{
        documentedRegionCandidate = $developerRegions -contains $Location
        status                    = 'documentation-review-required'
        reference                 = 'https://learn.microsoft.com/azure/bastion/bastion-sku-comparison'
    }
    retailMeters          = $prices
    warnings              = @(
        'Unknown credit, allocation, price, quota, or feature status blocks the affected live stage.',
        'Cost Management data can lag actual usage.',
        'Budgets and expiration tags do not stop or delete resources.',
        'The Azure spending limit is a separate control and must not be removed for this lab.'
    )
}

$resolvedOutput = [IO.Path]::GetFullPath((Join-Path (Get-Location) $OutputPath))
$outputDirectory = Split-Path -Parent $resolvedOutput
New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
$report | ConvertTo-Json -Depth 12 | Set-Content -Path $resolvedOutput -Encoding utf8NoBOM

Write-Host "PREFLIGHT_RECORDED path=$resolvedOutput location=$Location currency=$CurrencyCode"
Write-Warning 'Review every unknown and choose the exact primary retail meter before enabling a chargeable stage.'
