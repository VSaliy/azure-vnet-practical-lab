mock_provider "azurerm" {}

run "safe_defaults_and_exact_prefixes" {
  command = plan

  assert {
    condition     = output.subnet_prefixes["management"][0] == "10.20.0.0/24"
    error_message = "Management prefix changed."
  }
  assert {
    condition     = output.subnet_prefixes["application"][0] == "10.20.1.0/24"
    error_message = "Application prefix changed."
  }
  assert {
    condition     = output.cost_relevant_inventory.virtual_machines == 0
    error_message = "Live compute must default off."
  }
}
