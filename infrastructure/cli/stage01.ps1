#requires -Version 7.0
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$ResourceGroup = 'vnetlab-01-cli-rg',
    [ValidateSet('westeurope', 'northeurope')]
    [string]$Location = 'westeurope',
    [string]$Owner = 'learner',
    [switch]$Execute
)

$expires = [DateTime]::UtcNow.Date.AddDays(1).ToString('yyyy-MM-dd')
$PSNativeCommandUseErrorActionPreference = $true
if ($Owner -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]{1,30}$') {
    throw 'Owner must be a 2-31 character non-sensitive alias.'
}
$tags = @(
    'environment=lab'
    "owner=$Owner"
    "expires-on=$expires"
    'managed-by=terraform'
    'lab-stage=01'
)
if (-not $Execute) {
    Write-Host 'Dry run. Pass -Execute only after Stage 00. Terraform is authoritative.'
    exit
}
if (-not $PSCmdlet.ShouldProcess($ResourceGroup, 'Create the scoped Stage 01 Azure CLI comparison')) {
    return
}
az group create --name $ResourceGroup --location $Location --tags @tags
az network nsg create --resource-group $ResourceGroup --name vnetlab-01-management-nsg-cli --location $Location --tags @tags
az network nsg create --resource-group $ResourceGroup --name vnetlab-01-application-nsg-cli --location $Location --tags @tags
az network nsg rule create --resource-group $ResourceGroup --nsg-name vnetlab-01-application-nsg-cli --name allow-management-ssh --priority 100 --access Allow --direction Inbound --protocol Tcp --source-address-prefixes 10.20.0.0/24 --destination-address-prefixes 10.20.1.0/24 --destination-port-ranges 22
az network vnet create --resource-group $ResourceGroup --name vnetlab-01-vnet-cli --location $Location --address-prefixes 10.20.0.0/20 --tags @tags
az network vnet subnet create --resource-group $ResourceGroup --vnet-name vnetlab-01-vnet-cli --name management --address-prefixes 10.20.0.0/24 --network-security-group vnetlab-01-management-nsg-cli --default-outbound false
az network vnet subnet create --resource-group $ResourceGroup --vnet-name vnetlab-01-vnet-cli --name application --address-prefixes 10.20.1.0/24 --network-security-group vnetlab-01-application-nsg-cli --default-outbound false
Write-Host "Destroy with: az group delete --name $ResourceGroup --yes"
