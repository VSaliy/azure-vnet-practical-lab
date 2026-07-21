#!/usr/bin/env bash
set -euo pipefail
host="${1:?destination IP/host required}"
port="${2:?port required}"
expected="${3:-allow}"
[[ "$host" =~ ^[A-Za-z0-9.-]+$ ]] || { echo "Invalid destination host" >&2; exit 2; }
[[ "$port" =~ ^[0-9]+$ ]] && ((port >= 1 && port <= 65535)) || {
  echo "Invalid destination port" >&2
  exit 2
}
[[ "$expected" == allow || "$expected" == deny ]] || {
  echo "Expected result must be allow or deny" >&2
  exit 2
}
if timeout 6 bash -c '</dev/tcp/$1/$2' _ "$host" "$port" 2>/dev/null; then
  result=allow
else
  result=deny
fi
echo "EVIDENCE target=$host port=$port result=$result"
[[ "$result" == "$expected" ]]
