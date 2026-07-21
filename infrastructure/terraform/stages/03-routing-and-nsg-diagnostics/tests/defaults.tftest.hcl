mock_provider "azurerm" {}
run "exact_prefix_and_safe_route" {
  command = plan
  assert {
    condition = jsonencode(output.subnet_prefixes) == jsonencode({
      source = ["10.20.84.0/24"]
      target = ["10.20.85.0/24"]
    })
    error_message = "Stage 03 allocation changed."
  }
  assert {
    condition     = output.expected_next_hop == "VnetLocal" && output.cost_relevant_inventory.virtual_machines == 0
    error_message = "Defaults must be safe and control-plane-only."
  }
}
