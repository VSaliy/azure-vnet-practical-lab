# Testing strategy

## Credential-free

`terraform fmt -check`, Python `unittest` policy checks, Bash syntax, and Terraform mock-provider tests need no Azure subscription. Mock tests assert exact prefixes, safe defaults, Stage 02 matrix shape, non-transitivity, and safe public-access sequencing.

PowerShell Pester tests are provided when Pester is already available; it is not installed automatically. TFLint, Checkov, ShellCheck, Bicep lint, Markdown link checking, and secret scanners are useful optional defense-in-depth, but they are not made hidden prerequisites or installed by repository scripts.

## Azure integration

Only the manual, OIDC, environment-approved workflow can run live tests. It enforces stage/cumulative cost inputs, serializes runs, uses an ephemeral key, and destroys in `always()`. Stage 02 verifies source-specific allowed/denied sockets and target listener evidence. Diagnostics cover DNS, peering status, effective routes/NSGs, and private endpoint resolution as described in each lab.

A canceled runner can evade `always()`. `cancel-in-progress` is disabled, and Stage 09 plus the separate cleanup workflow are mandatory recovery controls.
