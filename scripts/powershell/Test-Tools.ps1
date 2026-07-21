#requires -Version 7.0
[CmdletBinding()]
param()

$required = @('git', 'terraform', 'az')
$optional = @('bash', 'shellcheck', 'tflint', 'checkov')
$failed = $false

foreach ($name in $required) {
    $command = Get-Command $name -ErrorAction SilentlyContinue
    if (-not $command) {
        Write-Error "Missing required tool: $name"
        $failed = $true
        continue
    }
    $version = & $name version 2>&1 | Select-Object -First 1
    Write-Host ("{0}: {1}" -f $name, $version)
}
foreach ($name in $optional) {
    $command = Get-Command $name -ErrorAction SilentlyContinue
    Write-Host ("{0}: {1}" -f $name, $(if ($command) { 'available' } else { 'optional/not found' }))
}
if ($failed) { exit 1 }
