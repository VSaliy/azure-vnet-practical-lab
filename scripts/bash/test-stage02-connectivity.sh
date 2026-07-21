#!/usr/bin/env bash
set -euo pipefail
rg="${1:-vnetlab-02-rg}"
declare -A ip
for tier in management web application data; do
  ip[$tier]="$(az vm list-ip-addresses -g "$rg" -n "vnetlab-02-$tier-vm" --query '[0].virtualMachine.network.privateIpAddresses[0]' -o tsv)"
  [[ -n "${ip[$tier]}" ]]
done

listener="$(az vm run-command invoke -g "$rg" -n vnetlab-02-data-vm --command-id RunShellScript \
  --scripts "ss -lnt | grep ':5432 '" --query 'value[0].message' -o tsv)"
grep -q 5432 <<<"$listener" || { echo "Data listener missing; denial is ambiguous." >&2; exit 1; }

probe() {
  local source="$1" target="$2" port="$3" expected="$4" output result status
  local code="import socket,sys;s=socket.socket();s.settimeout(5);exec(\"try:\\n s.connect(('$target',$port));print('CONNECT_OK')\\nexcept Exception as e:\\n print('CONNECT_DENIED',type(e).__name__);sys.exit(1)\")"
  set +e
  output="$(az vm run-command invoke -g "$rg" -n "vnetlab-02-$source-vm" --command-id RunShellScript \
    --scripts "python3 -c \"$code\"" --query 'value[0].message' -o tsv 2>&1)"
  status=$?
  set -e
  if grep -q CONNECT_OK <<<"$output"; then
    result=allow
  elif grep -q CONNECT_DENIED <<<"$output"; then
    result=deny
  else
    echo "Azure command failed without an explicit probe marker (status=$status): $output" >&2
    exit 1
  fi
  echo "EVIDENCE source=$source target=$target port=$port result=$result"
  [[ "$result" == "$expected" ]]
}

probe management "${ip[web]}" 22 allow
probe web "${ip[application]}" 8080 allow
probe application "${ip[data]}" 5432 allow
probe web "${ip[data]}" 5432 deny
[[ "$(az network public-ip list -g "$rg" --query 'length(@)' -o tsv)" == 0 ]]
echo "EVIDENCE internet->application any=deny publicIpCount=0"
