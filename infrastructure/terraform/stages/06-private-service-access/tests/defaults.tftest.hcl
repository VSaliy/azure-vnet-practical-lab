mock_provider "azurerm" {}

run "safe_phase_zero" {
  command = plan
  assert {
    condition = jsonencode(output.subnet_prefixes) == jsonencode({
      workload          = ["10.20.82.0/24"]
      private-endpoints = ["10.20.83.0/24"]
    })
    error_message = "Stage 06 allocation changed."
  }
  assert {
    condition = (
      output.public_network_access_enabled &&
      output.cost_relevant_inventory.storage_accounts == 0 &&
      output.cost_relevant_inventory.private_endpoints == 0
    )
    error_message = "Storage and private endpoint must default off with public access flag safe."
  }
}

run "reject_unsafe_public_disable" {
  command = plan
  variables {
    public_network_access_enabled = false
  }
  expect_failures = [terraform_data.deployment_guard]
}
