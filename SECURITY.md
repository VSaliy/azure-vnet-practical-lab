# Security policy

Report vulnerabilities privately through GitHub Security Advisories. Do not open a public issue containing credentials, identifiers, state, or exploit details.

## Lab posture

The examples deny unsolicited inbound access, create no VM public IPs, disable default outbound access on workload subnets, and keep chargeable features opt-in. Terraform state can contain sensitive values: keep it local, encrypted at rest, and out of Git. Rotate any credential accidentally exposed and remove it from history.

These examples are educational, not a complete production baseline.
