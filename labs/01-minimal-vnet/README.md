# Stage 01 — Minimal VNet

**Outcome:** Plan or create one `10.20.0.0/20` VNet with private management/application subnets and inspect system behavior.
**Difficulty:** Introductory

## Objectives and prerequisites

Learn CIDR, five Azure-reserved subnet addresses, NSG statefulness, system routes, private subnet behavior, and explicit outbound choices. Complete Stage 00. Live VM proof is optional and requires a passed one-VM cost/quota gate.

```mermaid
flowchart LR
  M[management 10.20.0.0/24] -->|TCP 22| A[application 10.20.1.0/24]
  A -. no default egress .-> X[Internet]
```

## Resources and cost

Resource group, VNet, two subnets, and two NSGs are the default control-plane set. One Linux VM/NIC/Standard LRS disk is optional; there is no public IP, NAT, or Bastion. Discover current [VM](https://azure.microsoft.com/pricing/details/virtual-machines/linux/) and [disk](https://azure.microsoft.com/pricing/details/managed-disks/) prices. Unknown price blocks the VM.

## Deploy

```powershell
./scripts/powershell/Invoke-TerraformStage.ps1 -Stage 01 -Action fmt
./scripts/powershell/Invoke-TerraformStage.ps1 -Stage 01 -Action validate
./scripts/powershell/Invoke-TerraformStage.ps1 -Stage 01 -Action plan
```

```bash
./scripts/bash/terraform-stage.sh 01 plan
```

Expected outputs include the exact two prefixes, `public_ips = 0`, and `virtual_machines = 0`. For approved live proof, use an ephemeral SSH public key and set `enable_live=true`, funded `account_mode`, and `cost_gate_approved=true`; never commit values.

The [Bicep](../../infrastructure/bicep/stage01/README.md) and [CLI](../../infrastructure/cli/stage01.ps1) variants are scoped comparisons only. Terraform remains authoritative.

## Verify

Positive: `terraform output subnet_prefixes` has `.0/24` and `.1/24`. Optional management-source TCP 22 succeeds. Negative: resource inventory has no public IP and application cannot reach the internet; evidence is a fresh connection timeout plus effective route inspection, not an absent listener.

## Troubleshoot and knowledge check

Inspect NIC effective NSGs/routes, then listener state. Why are only 251 addresses assignable in `/24`? Why does `default_outbound_access_enabled=false` not itself provide NAT?

## Cleanup and completion

```powershell
./scripts/powershell/Invoke-TerraformStage.ps1 -Stage 01 -Action destroy
./scripts/powershell/Test-ResidualResources.ps1
```

Complete only when the stage resource group and all tagged/related chargeable resources are absent.
