#!/usr/bin/env bash
set -euo pipefail
stage="${1:?stage 01-08 required}"
action="${2:?fmt|validate|test|plan|apply|destroy required}"
shift 2
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
directory="$(find "$root/infrastructure/terraform/stages" -maxdepth 1 -type d -name "$stage-*" | head -n 1)"
[[ -n "$directory" ]] || { echo "Unknown stage" >&2; exit 1; }
cd "$directory"
if [[ "$action" == apply && "${COST_GATE_APPROVED:-false}" != true ]]; then
  echo "Set COST_GATE_APPROVED=true only after the documented gate passes." >&2
  exit 1
fi
if [[ "$action" == fmt ]]; then terraform fmt -check; exit; fi
[[ -d .terraform ]] || terraform init
terraform "$action" "$@"
