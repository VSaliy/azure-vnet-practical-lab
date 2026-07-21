# Azure integration tests

These tests are opt-in and require an existing Azure CLI/OIDC context. They never authenticate themselves.

- `scripts/powershell/Test-Stage02Connectivity.ps1` verifies every required matrix row and listener evidence.
- `scripts/powershell/Test-ResidualResources.ps1` is the final binary cleanup assertion.
- The manual GitHub workflow applies, tests, and destroys in one approval-gated job.

Do not describe planned tests as executed when account mode blocks live endpoints.
