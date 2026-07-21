#!/usr/bin/env bash
set -euo pipefail
query="[?starts_with(resourceGroup,'vnetlab-') || (tags.environment=='lab' && tags.\"managed-by\"=='terraform' && tags.owner!=null && tags.\"expires-on\"!=null && tags.\"lab-stage\"!=null) || (resourceGroup=='NetworkWatcherRG' && (starts_with(name,'vnetlab-') || contains(name,'/vnetlab-')))].{rg:resourceGroup,type:type,name:name,id:id}"
remaining="$(az resource list --query "$query" -o json)"
count="$(python -c 'import json,sys; print(len(json.load(sys.stdin)))' <<<"$remaining")"
printf '%s\n' "$remaining"
[[ "$count" == 0 ]] || { echo "CLEANUP_INCOMPLETE: $count resources remain; do not delete NetworkWatcherRG wholesale." >&2; exit 1; }
echo "CLEANUP_COMPLETE"
