# Azure VNet Practical Lab

A cost-controlled, Terraform-first curriculum for learning Azure virtual networking. The eleven independent labs progress from preflight and CIDR planning through segmentation, peering, private service access, diagnostics, troubleshooting, and verified cleanup.

## Safety defaults

- Terraform uses local state and creates no resources until you explicitly run `apply`.
- Live compute, private endpoints, flow logs, and other chargeable options are disabled by default.
- Workload subnets disable implicit default outbound access.
- Test VMs have no public IP and use only cloud-init plus preinstalled Python and SSH.
- Prices, quota, free-service eligibility, and promotional credit are discovered before use; they are never assumed.

## Start here

1. Read [Lab 00](labs/00-prerequisites-and-cost/README.md).
2. Review the [IP plan](docs/ip-address-plan.md), [cost policy](docs/cost-management.md), and [security model](docs/security-model.md).
3. Run the credential-free checks:

   ```powershell
   ./scripts/powershell/Test-Repository.ps1
   ```

4. Work through `labs/01-*` to `labs/08-*` one stage at a time.
5. Destroy each stage and complete [Lab 09](labs/09-cleanup/README.md) before continuing.

PowerShell 7 is the primary shell. Practical Bash equivalents are provided. Azure deployment is never performed by CI unless a maintainer manually chooses the approval-gated OIDC workflow.

## Repository map

| Area | Purpose |
|---|---|
| `labs/` | Guided stages 00–10 and an authoring template |
| `infrastructure/terraform/modules/` | Reusable conventions, networking, security, routing, VM, peering, private service, and VNet flow-log modules |
| `infrastructure/terraform/stages/` | Independent, safely destroyable roots for stages 01–08 |
| `infrastructure/bicep/`, `infrastructure/cli/` | Scoped Stage 01 comparisons |
| `scripts/` | Preflight, lifecycle, evidence, and cleanup helpers |
| `tests/` | Credential-free policy tests and opt-in Azure assertions |
| `docs/` | Architecture, security, costs, operations, and references |

## Cost warning

Budget alerts lag and do not stop resources. Expiration tags do not delete resources. Stopped VMs can retain billed disks and IPs; idle private endpoints, storage, logs, and gateways can also bill. Use `terraform destroy`, then run the subscription-scoped residual check.

## License

MIT — see [LICENSE](LICENSE).
