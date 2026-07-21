mock_provider "azurerm" {}

run "vnet_flow_logs_default_off" {
  command = plan
  assert {
    condition = jsonencode(output.subnet_prefixes) == jsonencode({
      monitored   = ["10.20.86.0/24"]
      diagnostics = ["10.20.87.0/24"]
    })
    error_message = "Stage 07 allocation changed."
  }
  assert {
    condition = (
      output.flow_log_type == "disabled" &&
      output.cost_relevant_inventory.flow_logs == 0 &&
      output.cost_relevant_inventory.log_analytics == 0
    )
    error_message = "Flow logs and analytics must default off."
  }
}
