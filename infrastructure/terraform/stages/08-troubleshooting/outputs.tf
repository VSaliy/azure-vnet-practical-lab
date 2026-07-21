output "resource_group_name" {
  value = azurerm_resource_group.this.name
}
output "address_space" {
  value = module.network.address_space
}
output "subnet_prefixes" {
  value = module.network.subnet_prefixes
}
output "injected_fault" {
  value = var.fault
}
output "endpoint_private_ips" {
  value = { for name, vm in module.endpoint : name => vm.private_ip_address }
}
output "cost_relevant_inventory" {
  value = {
    virtual_machines = length(module.endpoint)
    public_ips       = 0
  }
}
