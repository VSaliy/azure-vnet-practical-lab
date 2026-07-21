# Workflow setup

`static.yml` needs no Azure subscription or credentials.

The manual integration and emergency cleanup workflows require repository environment `azure-lab-approval` with required reviewers and these environment secrets:

- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`

Values are identifiers, not client secrets, and must never be committed or printed. Configure a narrowly scoped federated identity according to [Microsoft's OIDC guidance](https://learn.microsoft.com/azure/developer/github/connect-from-azure-openid-connect). No client secret is supported.

The integration environment must also define:

- `AZURE_TFSTATE_RESOURCE_GROUP`
- `AZURE_TFSTATE_STORAGE_ACCOUNT`
- `AZURE_TFSTATE_CONTAINER`

That backend is explicit and pre-created. Local learners and static CI continue to use local or disabled state.

Integration is globally concurrency-protected, enforces current cost/quota inputs, creates a runner-only SSH key, and runs apply/test/destroy in one approved job. `cancel-in-progress` is false so one run cannot cancel another's cleanup. A runner/platform outage can still interrupt `always()`; use the separately approved cleanup workflow and Stage 09 inventory immediately.

Cleanup deletes only the eight exact Terraform lab resource groups and two scoped Stage 01 comparison groups, never `NetworkWatcherRG`, then requires the subscription union check to pass. Related artifacts outside those groups must be reviewed and removed individually.
