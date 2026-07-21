# Terraform implementation

Terraform `>=1.7.0,<2.0.0` and AzureRM `>=4.81.0,<5.0.0` are required. Every stage root is independent and uses local state. Provider registration is disabled in configuration; Stage 00 reports registration state but does not change it.

## Modules

- `conventions`: names, approved region/stage, and immutable mandatory tags
- `network`: VNet/subnets, CIDR containment/overlap checks, explicit private outbound setting
- `nsg`: validated rules and subnet associations
- `routes`: validated UDRs and associations
- `test-vm`: no-public-IP Linux endpoint and no-download Python listeners
- `peering`: two directional peerings with an explicit non-transitivity output
- `private-service`: Storage service restriction, optional PE/DNS, safe public-access transition
- `vnet-flow-logs`: optional VNet flow logs with short retention

## Dependency locks

Each stage root commits a reviewed lock for AzureRM 4.81.0 with HashiCorp-signed checksums for `windows_amd64` and `linux_amd64`. Updates must be regenerated with:

```powershell
terraform providers lock `
  -platform=windows_amd64 `
  -platform=linux_amd64
```

Lock files are separate from learner state and backend configuration. Static CI initializes each root without Azure credentials and exercises mock-provider tests.

## Lifecycle

Use `scripts/powershell/Invoke-TerraformStage.ps1`. Never run two chargeable stages concurrently. Destroy and pass the subscription residual check before moving on.
