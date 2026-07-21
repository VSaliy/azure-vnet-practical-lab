output "resource_group_name" { value = azurerm_resource_group.this.name }
output "subnet_prefixes" { value = module.network.subnet_prefixes }
output "endpoint_private_ips" { value = { for name, vm in module.endpoint : name => vm.private_ip_address } }
output "expected_next_hop" { value = var.inject_blackhole_route ? "None" : "VnetLocal" }
output "cost_relevant_inventory" { value = { virtual_machines = length(module.endpoint), public_ips = 0 } }
