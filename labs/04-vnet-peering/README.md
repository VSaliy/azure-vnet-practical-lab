# Stage 04 — VNet peering

**Outcome:** Create bidirectional peering between exact non-overlapping `/24` VNets and explain connected but non-transitive behavior.
**Difficulty:** Intermediate

## Objectives and prerequisites

Learn two peering objects, forwarded-traffic flags, address overlap rejection, effective routes, gateway transit concepts, and peered traffic charges. No gateway is deployed.

```mermaid
flowchart LR
  A[10.20.80.0/24] <-->|two peerings| B[10.20.81.0/24]
```

## Resources and cost

Default: RG, two VNets/subnets, NSG, and two peerings. Optional: two private VMs/disks. Peering creation has no hourly charge, but traffic is billed; send minimal bytes and verify current [VNet pricing](https://azure.microsoft.com/pricing/details/virtual-network/).

## Deploy and verify

```powershell
./scripts/powershell/Invoke-TerraformStage.ps1 -Stage 04 -Action plan
az network vnet peering list --resource-group vnetlab-04-rg --vnet-name vnetlab-04-left-vnet --query "[].{name:name,state:peeringState}" -o table
```

```bash
./scripts/bash/terraform-stage.sh 04 plan
./scripts/bash/test-connectivity.sh <right-private-ip> 8080 allow
```

Positive evidence: `Connected` both ways, effective route to remote `/24` with `VNetPeering`, and minimal TCP 8080 success. Negative: attempting an overlapping prefix is rejected at plan/check or Azure; no third VNet route appears transitively. Output `transitive_routing_enabled=false` is an assertion, not a routed demonstration.

## Troubleshoot and knowledge check

Check both peering states and flags, then effective routes and NSG. Does `allow_forwarded_traffic` create a router? (No.) Can one peering object provide bidirectionality? (No.)

## Cleanup and completion

Destroy Stage 04, verify both peering objects and optional disks/NICs are gone, then run residual checks. Complete only with two connected peerings during the test and no residual chargeable resource.
