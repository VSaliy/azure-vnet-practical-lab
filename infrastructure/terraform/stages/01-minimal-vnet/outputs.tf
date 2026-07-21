output "resource_group_name" { value = azurerm_resource_group.this.name }
output "vnet_id" { value = module.network.id }
output "subnet_prefixes" { value = module.network.subnet_prefixes }
output "vm_private_ip" { value = try(module.vm[0].private_ip_address, null) }
output "cost_relevant_inventory" {
  value = {
    virtual_machines = length(module.vm)
    public_ips       = 0
    nat_gateways     = 0
  }
}
