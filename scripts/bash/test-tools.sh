#!/usr/bin/env bash
set -euo pipefail
for tool in git terraform az; do
  command -v "$tool" >/dev/null || { echo "Missing required tool: $tool" >&2; exit 1; }
  "$tool" version 2>&1 | head -n 1
done
for tool in pwsh shellcheck tflint checkov; do
  command -v "$tool" >/dev/null && echo "$tool: available" || echo "$tool: optional/not found"
done
