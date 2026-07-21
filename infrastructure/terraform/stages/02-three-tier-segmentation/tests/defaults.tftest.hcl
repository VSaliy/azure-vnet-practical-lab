mock_provider "azurerm" {}

run "safe_defaults_exact_topology" {
  command = plan
  assert {
    condition = jsonencode(output.subnet_prefixes) == jsonencode({
      management  = ["10.20.16.0/24"]
      web         = ["10.20.17.0/24"]
      application = ["10.20.18.0/24"]
      data        = ["10.20.19.0/24"]
    })
    error_message = "Stage 02 IP allocation changed."
  }

  assert {
    condition     = output.cost_relevant_inventory.virtual_machines == 0
    error_message = "Live topology must default off."
  }
  assert {
    condition     = length(output.communication_matrix) == 5
    error_message = "The required communication matrix must have five rows."
  }
}

run "reject_live_without_cost_gate" {
  command = plan
  variables {
    enable_live          = true
    admin_ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILabOnlyMockKey"
  }
  expect_failures = [terraform_data.deployment_guard]
}
