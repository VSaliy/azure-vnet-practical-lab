output "resource_group_name" { value = azurerm_resource_group.this.name }
output "address_spaces" { value = { left = module.left.address_space, right = module.right.address_space } }
output "endpoint_private_ips" { value = { for name, vm in module.endpoint : name => vm.private_ip_address } }
output "peering_ids" { value = module.peering.ids }
output "transitive_routing_enabled" { value = module.peering.transitive_routing_enabled }
output "cost_relevant_inventory" { value = { virtual_machines = length(module.endpoint), public_ips = 0 } }
