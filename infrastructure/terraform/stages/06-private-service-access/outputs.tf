output "resource_group_name" {
  value = azurerm_resource_group.this.name
}
output "subnet_prefixes" {
  value = module.network.subnet_prefixes
}
output "blob_hostname" {
  value = try(module.service[0].blob_hostname, null)
}
output "private_endpoint_ip" {
  value = try(module.service[0].private_ip_address, null)
}
output "test_vm_id" {
  value = try(module.test_vm[0].id, null)
}
output "test_vm_principal_id" {
  value = try(module.test_vm[0].principal_id, null)
}
output "public_network_access_enabled" {
  value = var.public_network_access_enabled
}
output "cost_relevant_inventory" {
  value = {
    storage_accounts  = length(module.service)
    private_endpoints = var.enable_private_endpoint ? 1 : 0
    virtual_machines  = length(module.test_vm)
    public_ips        = 0
  }
}
