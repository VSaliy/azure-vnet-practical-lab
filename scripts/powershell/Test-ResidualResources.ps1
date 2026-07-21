#requires -Version 7.0
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
$knownGroups = @(
    (1..8 | ForEach-Object { 'vnetlab-{0:d2}-rg' -f $_ })
    'vnetlab-01-bicep-rg'
    'vnetlab-01-cli-rg'
)
$relatedTypes = @(
    'microsoft.network/networkwatchers/flowlogs',
    'microsoft.storage/storageaccounts',
    'microsoft.network/networkinterfaces',
    'microsoft.compute/disks',
    'microsoft.network/publicipaddresses',
    'microsoft.compute/snapshots',
    'microsoft.network/privateendpoints',
    'microsoft.insights/diagnosticsettings',
    'microsoft.operationalinsights/workspaces'
)

$all = az resource list --output json | ConvertFrom-Json
$union = [ordered]@{}
function Test-LabReference {
    param([AllowNull()][string]$Id)
    if (-not $Id) { return $false }
    foreach ($group in $knownGroups) {
        if ($Id -match [regex]::Escape("/resourceGroups/$group/")) { return $true }
    }
    return $Id -match '/vnetlab-'
}

foreach ($resource in $all) {
    $tags = $resource.tags
    $mandatoryTags = $tags -and
        $tags.environment -eq 'lab' -and
        $tags.'managed-by' -eq 'terraform' -and
        $tags.owner -and $tags.'expires-on' -and $tags.'lab-stage'
    $knownGroup = $knownGroups -contains $resource.resourceGroup
    $knownName = $resource.name -like 'vnetlab-*' -or $resource.name -like '*/vnetlab-*'
    $related = $relatedTypes -contains $resource.type.ToLowerInvariant()
    $networkWatcherArtifact = $resource.resourceGroup -eq 'NetworkWatcherRG' -and $knownName

    if ($knownGroup -or $mandatoryTags -or $networkWatcherArtifact -or ($related -and ($knownName -or $mandatoryTags))) {
        $union[$resource.id] = $resource
    }
}

# Private Endpoint NICs can be generated names; include those attached to known lab private endpoints.
$nics = az network nic list --output json | ConvertFrom-Json
foreach ($nic in $nics) {
    $peId = $nic.privateEndpoint.id
    if ((Test-LabReference $peId) -or (Test-LabReference $nic.virtualMachine.id)) {
        $union[$nic.id] = $nic
    }
}

# Include dependencies that can be placed outside the source resource group.
foreach ($disk in (az disk list --output json | ConvertFrom-Json)) {
    if (Test-LabReference $disk.managedBy) { $union[$disk.id] = $disk }
}
foreach ($snapshot in (az snapshot list --output json | ConvertFrom-Json)) {
    if (Test-LabReference $snapshot.creationData.sourceResourceId) { $union[$snapshot.id] = $snapshot }
}
foreach ($publicIp in (az network public-ip list --output json | ConvertFrom-Json)) {
    if (Test-LabReference $publicIp.ipConfiguration.id) { $union[$publicIp.id] = $publicIp }
}

# VNet flow logs are child resources of a regional watcher and may live in NetworkWatcherRG.
foreach ($location in @((az network watcher list --query '[].location' --output tsv) | Sort-Object -Unique)) {
    if (-not $location) { continue }
    try {
        $flowLogs = az network watcher flow-log list --location $location --output json 2>$null | ConvertFrom-Json
        foreach ($flowLog in $flowLogs) {
            if ((Test-LabReference $flowLog.targetResourceId) -or $flowLog.name -like '*vnetlab-*') {
                $union[$flowLog.id] = $flowLog
            }
        }
    }
    catch {
        Write-Warning "Could not enumerate flow logs in $location; cleanup cannot be declared complete."
        exit 1
    }
}

$union.Values | Sort-Object resourceGroup, type, name |
    Select-Object resourceGroup, type, name, id | Format-Table -AutoSize
if ($union.Count) {
    Write-Error "CLEANUP_INCOMPLETE: $($union.Count) lab or related resources remain. Do not delete NetworkWatcherRG wholesale."
    exit 1
}
Write-Host 'CLEANUP_COMPLETE: no known, mandatorily tagged, or related chargeable lab resource remains.'
