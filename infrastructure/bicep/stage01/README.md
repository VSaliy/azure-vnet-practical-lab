# Stage 01 Bicep comparison

Terraform remains authoritative. This resource-group-scoped comparison creates only the Stage 01 VNet and NSGs; it does not create the resource group, VM, public IP, egress, or state backend.

```powershell
$expires = [DateTime]::UtcNow.Date.AddDays(1).ToString('yyyy-MM-dd')
$tags = @(
  'environment=lab'
  'owner=learner'
  "expires-on=$expires"
  'managed-by=terraform'
  'lab-stage=01'
)
az group create `
  --name vnetlab-01-bicep-rg `
  --location westeurope `
  --tags @tags
az deployment group what-if `
  --resource-group vnetlab-01-bicep-rg `
  --template-file ./main.bicep `
  --parameters owner=learner expiresOn=$expires
```

Deploy only after the same preflight. Remove the comparison resource group immediately. Do not manage the same named resource with Terraform and Bicep.
