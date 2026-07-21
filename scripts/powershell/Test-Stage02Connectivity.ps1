#requires -Version 7.0
[CmdletBinding()]
param(
    [string]$ResourceGroup = 'vnetlab-02-rg'
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
function Invoke-FromVm {
    param([string]$Source, [string]$DestinationIp, [int]$Port, [bool]$ShouldSucceed)
    $code = @"
import socket
s=socket.socket(); s.settimeout(5)
try:
 s.connect(('$DestinationIp',$Port)); print('CONNECT_OK'); raise SystemExit(0)
except Exception as e:
 print('CONNECT_DENIED',type(e).__name__); raise SystemExit(1)
"@
    $nativePreference = $PSNativeCommandUseErrorActionPreference
    $PSNativeCommandUseErrorActionPreference = $false
    try {
        $result = az vm run-command invoke --resource-group $ResourceGroup --name "vnetlab-02-$Source-vm" `
            --command-id RunShellScript --scripts $code --query 'value[0].message' --output tsv
        $commandStatus = $LASTEXITCODE
    }
    finally {
        $PSNativeCommandUseErrorActionPreference = $nativePreference
    }
    $allowed = $result -match 'CONNECT_OK'
    $denied = $result -match 'CONNECT_DENIED'
    if ($ShouldSucceed -and ($commandStatus -ne 0 -or -not $allowed)) {
        throw "Expected allow for $Source -> $DestinationIp`:$Port but received: $result"
    }
    if (-not $ShouldSucceed -and -not $denied) {
        throw "Expected an explicit network denial marker for $Source -> $DestinationIp`:$Port but received: $result"
    }
    Write-Host "EVIDENCE source=$Source target=$DestinationIp port=$Port expected=$ShouldSucceed result=$($result.Trim())"
}

function Assert-IpFlow {
    param(
        [string]$DestinationVm,
        [string]$LocalEndpoint,
        [string]$RemoteEndpoint,
        [ValidateSet('Allow', 'Deny')]
        [string]$ExpectedAccess,
        [string]$ExpectedRule
    )

    $result = az network watcher test-ip-flow --resource-group $ResourceGroup --vm $DestinationVm `
        --direction Inbound --protocol TCP --local $LocalEndpoint --remote $RemoteEndpoint `
        --output json | ConvertFrom-Json
    if ($result.access -ne $ExpectedAccess -or $result.ruleName -notlike "*$ExpectedRule") {
        throw "Unexpected IP Flow Verify result for ${DestinationVm}: $($result | ConvertTo-Json -Compress)"
    }
    Write-Host "IP_FLOW_EVIDENCE vm=$DestinationVm access=$($result.access) rule=$($result.ruleName)"
}

$ips = @{}
foreach ($tier in 'management', 'web', 'application', 'data') {
    $ips[$tier] = az vm list-ip-addresses --resource-group $ResourceGroup --name "vnetlab-02-$tier-vm" --query '[0].virtualMachine.network.privateIpAddresses[0]' --output tsv
    if (-not $ips[$tier]) { throw "Missing private IP for $tier" }
}

# Prove the negative target is listening independently before interpreting denial.
$listener = az vm run-command invoke --resource-group $ResourceGroup --name 'vnetlab-02-data-vm' `
    --command-id RunShellScript --scripts "ss -lnt | grep ':5432 '" --query 'value[0].message' --output tsv
if ($listener -notmatch '5432') { throw 'Data port 5432 is not listening; denial would be ambiguous.' }
Write-Host "LISTENER_EVIDENCE data:5432 $($listener.Trim())"

Invoke-FromVm management $ips.web 22 $true
Invoke-FromVm web $ips.application 8080 $true
Invoke-FromVm application $ips.data 5432 $true
Invoke-FromVm web $ips.data 5432 $false

Assert-IpFlow 'vnetlab-02-web-vm' "$($ips.web):22" "$($ips.management):60000" Allow 'allow-management-ssh'
Assert-IpFlow 'vnetlab-02-application-vm' "$($ips.application):8080" "$($ips.web):60000" Allow 'allow-web-8080'
Assert-IpFlow 'vnetlab-02-data-vm' "$($ips.data):5432" "$($ips.application):60000" Allow 'allow-application-5432'
Assert-IpFlow 'vnetlab-02-data-vm' "$($ips.data):5432" "$($ips.web):60000" Deny 'deny-web-5432'
Assert-IpFlow 'vnetlab-02-application-vm' "$($ips.application):8080" '198.51.100.10:60000' Deny 'deny-internet-any'

$publicIps = az network public-ip list --resource-group $ResourceGroup --query 'length(@)' --output tsv
if ($publicIps -ne '0') { throw 'Internet denial evidence failed: an unintended public IP exists.' }
Write-Host 'EVIDENCE internet->application any=DENY publicIpCount=0 explicitNsgRule=deny-internet-any'
Write-Host 'STAGE02_MATRIX_PASS'
