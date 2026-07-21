#requires -Version 7.0
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [ValidateSet('01', '02', '03', '04', '05', '06', '07', '08')]
    [string]$Stage,
    [Parameter(Mandatory)]
    [ValidateSet('fmt', 'validate', 'test', 'plan', 'apply', 'destroy')]
    [string]$Action,
    [switch]$CostGateApproved,
    [string[]]$TerraformArguments = @()
)

$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '../..')
$stageDirectory = Get-ChildItem (Join-Path $root 'infrastructure/terraform/stages') -Directory |
    Where-Object Name -Like "$Stage-*" | Select-Object -First 1
if (-not $stageDirectory) { throw "Unknown stage $Stage" }
if ($Action -in @('apply') -and -not $CostGateApproved) { throw 'Apply requires -CostGateApproved after Test-CostGate passes.' }

Push-Location $stageDirectory.FullName
try {
    if ($Action -eq 'fmt') { & terraform fmt -check; exit $LASTEXITCODE }
    if (-not (Test-Path '.terraform')) {
        Write-Host 'Initializing local backend. Provider download and lock-file review may require network access.'
        & terraform init
        if ($LASTEXITCODE) { exit $LASTEXITCODE }
    }
    $args = switch ($Action) {
        'validate' { @('validate') }
        'test'     { @('test') }
        'plan'     { @('plan') + $TerraformArguments }
        'apply'    { @('apply') + $TerraformArguments }
        'destroy'  { @('destroy') + $TerraformArguments }
    }
    if ($PSCmdlet.ShouldProcess($stageDirectory.FullName, "terraform $Action")) {
        & terraform @args
        exit $LASTEXITCODE
    }
}
finally {
    Pop-Location
}
