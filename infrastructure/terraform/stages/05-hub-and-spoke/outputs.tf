output "resource_group_name" {
  value = azurerm_resource_group.this.name
}
output "address_spaces" {
  value = {
    hub    = module.hub.address_space
    spoke1 = module.spoke1.address_space
    spoke2 = module.spoke2.address_space
  }
}
output "transitive_routing_enabled" {
  description = "Peering alone cannot route spoke-to-spoke."
  value       = false
}
output "endpoint_private_ips" {
  value = { for name, vm in module.endpoint : name => vm.private_ip_address }
}
output "cost_relevant_inventory" {
  value = {
    virtual_machines  = length(module.endpoint)
    firewalls         = 0
    gateways          = 0
    public_ips        = 0
    private_dns_zones = length(azurerm_private_dns_zone.internal)
  }
}
