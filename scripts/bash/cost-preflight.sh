#!/usr/bin/env bash
set -euo pipefail
location="${1:-westeurope}"
size="${2:-Standard_B1s}"
az account show --query '{name:name,state:state}' -o table
az provider list --query "[?namespace=='Microsoft.Network'||namespace=='Microsoft.Compute'||namespace=='Microsoft.Storage'||namespace=='Microsoft.Insights'||namespace=='Microsoft.DevTestLab'].{provider:namespace,state:registrationState}" -o table
az vm list-skus --location "$location" --size "$size" --all --query "[].{name:name,restrictions:restrictions}" -o table
az vm list-usage --location "$location" -o table
az network list-usages --location "$location" -o table
echo "Manually verify offer, spending limit, credit, free allocation, budgets, and current local-currency retail prices."
echo "Unknown price or eligibility blocks deployment. Budgets and expiration tags do not stop/delete resources."
