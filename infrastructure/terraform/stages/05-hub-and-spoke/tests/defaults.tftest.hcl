mock_provider "azurerm" {}

run "exact_nontransitive_hub_spoke" {
  command = plan
  assert {
    condition = (
      contains(output.address_spaces.hub, "10.20.32.0/20") &&
      contains(output.address_spaces.spoke1, "10.20.48.0/20") &&
      contains(output.address_spaces.spoke2, "10.20.64.0/20")
    )
    error_message = "Hub/spoke allocations changed."
  }
  assert {
    condition     = output.transitive_routing_enabled == false
    error_message = "Stage 05 must never claim transitive routing."
  }
  assert {
    condition     = output.cost_relevant_inventory.private_dns_zones == 0
    error_message = "Chargeable Private DNS must default off."
  }
  assert {
    condition     = output.cost_relevant_inventory.virtual_machines == 0
    error_message = "Topology endpoints must default off."
  }
}
