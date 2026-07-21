output "resource_group_name" { value = azurerm_resource_group.this.name }
output "subnet_prefixes" { value = module.network.subnet_prefixes }
output "endpoint_private_ips" { value = { for name, vm in module.endpoint : name => vm.private_ip_address } }
output "communication_matrix" {
  value = [
    { source = "management", destination = "web", port = 22, expected = "allow" },
    { source = "web", destination = "application", port = 8080, expected = "allow" },
    { source = "application", destination = "data", port = 5432, expected = "allow" },
    { source = "web", destination = "data", port = 5432, expected = "deny" },
    { source = "internet", destination = "application", port = 0, expected = "deny" }
  ]
}
output "cost_relevant_inventory" {
  value = { virtual_machines = length(module.endpoint), public_ips = 0 }
}
