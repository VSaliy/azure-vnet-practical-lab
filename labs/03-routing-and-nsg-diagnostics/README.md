# Stage 03 — Routes and NSG diagnostics

**Outcome:** Distinguish system routes, UDR intent, NSG decisions, and listener failures using effective evidence.
**Difficulty:** Intermediate

## Objectives and prerequisites

Inspect route precedence, effective routes/security rules, IP flow, and Connection Troubleshoot. Learn that a UDR alone never makes an appliance forward; an NVA needs forwarding enabled, forwarding software, correct return routes, and NSG allowance.

```mermaid
flowchart LR
  S[source 10.20.84.0/24] -->|VnetLocal or None fault| T[target 10.20.85.0/24:8080]
```

## Resources and cost

Default: RG, `10.20.84.0/23` VNet, two subnets, NSG, and route table. Optional: two private VMs/NICs/disks, never an NVA/public IP. Discover [Network Watcher pricing](https://azure.microsoft.com/pricing/details/network-watcher/) and VM/disk prices; some diagnostic operations may bill.

## Deploy and verify

```powershell
./scripts/powershell/Invoke-TerraformStage.ps1 -Stage 03 -Action plan
az network nic show-effective-route-table --resource-group vnetlab-03-rg --name vnetlab-03-source-vm-nic
az network nic show-effective-nsg --resource-group vnetlab-03-rg --name vnetlab-03-target-vm-nic
```

```bash
./scripts/bash/terraform-stage.sh 03 plan
./scripts/bash/test-connectivity.sh <target-private-ip> 8080 allow
```

Positive evidence is a fresh `CONNECT_OK` and `VnetLocal` effective next hop. Set `inject_blackhole_route=true` for the deliberate fault; expected negative evidence is `None` effective next hop and a failed fresh connection while target `ss -lnt` still shows 8080. IP flow verify isolates NSG allowance from route reachability.

## Troubleshoot and knowledge check

Order: listener → IP flow → effective NSG → effective route → next hop. Why does a `VirtualAppliance` route not forward packets by itself? Which wins: longest prefix, then route source precedence?

## Cleanup and completion

Destroy Stage 03 and run the subscription residual check. Complete when both healthy/fault evidence identify the intended reason and no chargeable resource remains.
