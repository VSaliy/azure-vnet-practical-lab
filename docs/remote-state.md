# Optional remote state

Local state is the learner default. Never commit it.

Teams may manually create a dedicated Storage account/container, enable encryption and versioning, deny broad network access, grant least-privilege data-plane access, and then add an `azurerm` backend block. Bootstrap infrastructure must be owned and destroyed separately; this repository does not create or silently require it.

Do not put backend access keys in files or CLI history. Prefer Entra/OIDC authentication. Migrate only after backing up state and reviewing `terraform init -migrate-state`. A lock file records providers, not state. State may contain IDs and sensitive values even when outputs are marked sensitive.
