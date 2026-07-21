# Security and threat model

## Controls

- Deny by default; permit only named source prefixes and destination ports.
- No unrestricted SSH/RDP, VM public IP, embedded credential, or long-lived client secret.
- Separate Azure control-plane access (OIDC/Run Command) from workload traffic evidence.
- Keep state local by default and excluded from Git; use encrypted access-controlled storage if opting into remote state.
- Prefer managed identity and Entra ID where supported.
- Public Storage access remains enabled but subnet-restricted until private DNS and private connectivity pass; only then may it be disabled.
- Resource locks, paid Defender plans, and Azure Policy assignments are discussed but disabled because they may cost money or block cleanup.

## Threat model

| Threat | Mitigation / evidence |
|---|---|
| Public exposure | No VM public IP; NSG internet-to-application deny; inventory query |
| Lateral movement | Tier-specific NSGs and explicit communication matrix |
| NSG priority error | Unique validated priorities; effective-rule/IP-flow checks |
| Route manipulation | Scoped route tables, effective-route evidence, no forwarding claims |
| DNS misconfiguration | Private-zone link and private-IP resolution test before public disable |
| Credential leakage | OIDC, ignored state/keys/tfvars, secret scanning patterns |
| Data exfiltration | Private subnets with no default outbound; narrow service access |
| Excessive Azure permission | Dedicated lab scope, approval environment, least privilege review |

Teaching compromises include broad RFC1918 source ranges in a few diagnostics examples and owner-provided SSH public keys. Tighten these for production.
