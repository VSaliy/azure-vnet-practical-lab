#requires -Version 7.0
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '../..')
Push-Location $root
try {
    terraform fmt -recursive -check
    if ($LASTEXITCODE) { throw 'terraform fmt check failed' }
    python -m unittest discover -s tests/static -p 'test_*.py'
    if ($LASTEXITCODE) { throw 'static policy tests failed' }
    Write-Host 'STATIC_CHECKS_PASS'
}
finally {
    Pop-Location
}
