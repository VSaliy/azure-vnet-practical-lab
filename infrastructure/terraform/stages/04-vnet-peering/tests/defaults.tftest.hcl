mock_provider "azurerm" {}
run "exact_nontransitive_topology" {
  command = plan
  assert {
    condition     = contains(output.address_spaces.left, "10.20.80.0/24") && contains(output.address_spaces.right, "10.20.81.0/24")
    error_message = "Peering allocations changed."
  }
  assert {
    condition     = output.transitive_routing_enabled == false && output.cost_relevant_inventory.virtual_machines == 0
    error_message = "Peering must not claim transit and compute must default off."
  }
}
