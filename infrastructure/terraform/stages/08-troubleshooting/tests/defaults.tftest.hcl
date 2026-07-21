mock_provider "azurerm" {}

run "safe_exact_troubleshooting_topology" {
  command = plan
  assert {
    condition     = contains(output.address_space, "10.20.88.0/21")
    error_message = "Stage 08 allocation changed."
  }
  assert {
    condition = (
      output.injected_fault == "none" &&
      output.cost_relevant_inventory.virtual_machines == 0
    )
    error_message = "Faults and compute must default off."
  }
}
