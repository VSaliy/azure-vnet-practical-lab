#requires -Version 7.0
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [ValidateSet('DELETE-VNET-LAB')]
    [string]$Confirmation
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
$knownGroups = @(
    (1..8 | ForEach-Object { 'vnetlab-{0:d2}-rg' -f $_ })
    'vnetlab-01-bicep-rg'
    'vnetlab-01-cli-rg'
)
foreach ($group in $knownGroups) {
    $exists = az group exists --name $group --output tsv
    if ($exists -ne 'true') { continue }

    $groupInfo = az group show --name $group --output json | ConvertFrom-Json
    $tags = $groupInfo.tags
    $mandatoryTags = $tags -and
        $tags.environment -eq 'lab' -and
        $tags.'managed-by' -eq 'terraform' -and
        $tags.owner -and
        $tags.'expires-on' -and
        $tags.'lab-stage'
    if (-not $mandatoryTags) {
        Write-Warning "Skipped $group because the complete lab tag set was not found."
        continue
    }

    if ($PSCmdlet.ShouldProcess($group, 'Delete verified lab resource group')) {
        az group delete --name $group --yes --no-wait
    }
}

Write-Warning 'Known group deletion was requested. NetworkWatcherRG was not deleted. Re-run Test-ResidualResources.ps1 after Azure reports deletion complete, then inspect individual tagged/related artifacts.'
