#requires -Version 7.0
[CmdletBinding()]
param(
    [string]$ResourceGroup = 'vnetlab-06-rg',
    [Parameter(Mandatory)]
    [ValidatePattern('^[a-z0-9]{3,24}$')]
    [string]$StorageAccountName,
    [Parameter(Mandatory)]
    [string]$ExpectedPrivateIp,
    [string]$EvidencePath = '.lab/stage06-private-connectivity.txt'
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true

$parsedIp = $null
if (-not [Net.IPAddress]::TryParse($ExpectedPrivateIp, [ref]$parsedIp) -or
    $parsedIp.AddressFamily -ne [Net.Sockets.AddressFamily]::InterNetwork) {
    throw 'ExpectedPrivateIp must be a valid IPv4 address.'
}

$remoteScript = @"
python3 - <<'PY'
import email.utils
import json
import socket
import urllib.request

account = "$StorageAccountName"
expected_ip = "$ExpectedPrivateIp"
hostname = f"{account}.blob.core.windows.net"
addresses = {item[4][0] for item in socket.getaddrinfo(hostname, 443, type=socket.SOCK_STREAM)}
if expected_ip not in addresses:
    raise SystemExit(f"DNS_PRIVATE_MISMATCH expected={expected_ip} actual={sorted(addresses)}")
print(f"DNS_PRIVATE_OK hostname={hostname} ip={expected_ip}")

metadata = urllib.request.Request(
    "http://169.254.169.254/metadata/identity/oauth2/token"
    "?api-version=2018-02-01&resource=https%3A%2F%2Fstorage.azure.com%2F",
    headers={"Metadata": "true"},
)
with urllib.request.urlopen(metadata, timeout=10) as response:
    token = json.load(response)["access_token"]

request = urllib.request.Request(
    f"https://{hostname}/?comp=list",
    headers={
        "Authorization": f"Bearer {token}",
        "x-ms-date": email.utils.formatdate(usegmt=True),
        "x-ms-version": "2023-11-03",
    },
)
with urllib.request.urlopen(request, timeout=15) as response:
    if response.status != 200:
        raise SystemExit(f"STORAGE_DATA_FAILED status={response.status}")
print("STORAGE_DATA_OK status=200")
PY
"@

$result = az vm run-command invoke --resource-group $ResourceGroup --name 'vnetlab-06-test-vm' `
    --command-id RunShellScript --scripts $remoteScript --query 'value[0].message' --output tsv
if ($result -notmatch 'DNS_PRIVATE_OK' -or $result -notmatch 'STORAGE_DATA_OK') {
    throw "Private connectivity evidence was incomplete: $result"
}

$resolvedEvidence = [IO.Path]::GetFullPath((Join-Path (Get-Location) $EvidencePath))
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $resolvedEvidence) | Out-Null
"PRIVATE_CONNECTIVITY_VERIFIED:$StorageAccountName" |
    Set-Content -Path $resolvedEvidence -Encoding utf8NoBOM
Write-Host "PRIVATE_CONNECTIVITY_VERIFIED evidence=$resolvedEvidence"
