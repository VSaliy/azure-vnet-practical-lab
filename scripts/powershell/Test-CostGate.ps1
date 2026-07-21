#requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^(0[1-8])$')]
    [string]$Stage,
    [Parameter(Mandatory)]
    [ValidateSet('active-credit', 'free-services', 'no-credit', 'payg')]
    [string]$AccountMode,
    [Parameter(Mandatory)]
    [double]$StageEstimateUsd,
    [Parameter(Mandatory)]
    [double]$CumulativeEstimateUsd,
    [switch]$PriceVerified,
    [switch]$QuotaVerified,
    [switch]$AllocationVerified,
    [switch]$Approved
)

$errors = [System.Collections.Generic.List[string]]::new()
if ([double]::IsNaN($StageEstimateUsd) -or [double]::IsInfinity($StageEstimateUsd) -or $StageEstimateUsd -lt 0) {
    $errors.Add('Stage estimate must be a finite non-negative number.')
}
if ([double]::IsNaN($CumulativeEstimateUsd) -or [double]::IsInfinity($CumulativeEstimateUsd) -or $CumulativeEstimateUsd -lt 0) {
    $errors.Add('Cumulative estimate must be a finite non-negative number.')
}
if ($CumulativeEstimateUsd -lt $StageEstimateUsd) {
    $errors.Add('Cumulative estimate cannot be lower than the stage estimate.')
}
if (-not $PriceVerified) { $errors.Add('Current local-currency price is not verified.') }
if (-not $QuotaVerified) { $errors.Add('Regional SKU and quota are not verified.') }
if (-not $Approved) { $errors.Add('Explicit stage approval is missing.') }
if ($StageEstimateUsd -gt 2) { $errors.Add('Stage estimate exceeds the USD 2 equivalent envelope.') }
if ($CumulativeEstimateUsd -gt 10) { $errors.Add('Cumulative estimate exceeds the USD 10 equivalent envelope.') }
if ($AccountMode -eq 'no-credit') { $errors.Add('No-credit mode permits static/control-plane work only.') }
if ($AccountMode -eq 'free-services' -and -not $AllocationVerified) {
    $errors.Add('Free-services mode requires verified remaining allocation for every resource and quantity.')
}
if ($errors.Count) {
    $errors | ForEach-Object { Write-Error $_ }
    exit 1
}
Write-Host "COST_GATE_PASS stage=$Stage mode=$AccountMode"
