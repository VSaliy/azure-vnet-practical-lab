# Contributing

Keep stages independent, local-state-first, and disabled for chargeable options by default.

1. Do not commit state, plans, real `.tfvars`, identifiers, credentials, private keys, or public source IPs.
2. Run `./scripts/powershell/Test-Repository.ps1`.
3. Update both PowerShell and Bash examples when behavior changes.
4. Add a mock-provider test for Terraform behavior.
5. Document cost gates, expected evidence, cleanup, and residual checks.
6. Use Conventional Commits and link issues with a closing keyword where applicable.

Never add mandatory NAT Gateway, Azure Firewall, paid Bastion, gateway, public IP, or persistent analytics resources. New flow logging must be VNet flow logging.
