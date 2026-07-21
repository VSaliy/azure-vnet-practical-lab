output "resource_group_name" {
  value = azurerm_resource_group.this.name
}
output "subnet_prefixes" {
  value = module.network.subnet_prefixes
}
output "flow_log_id" {
  value = try(module.flow_logs[0].id, null)
}
output "flow_log_type" {
  value = var.enable_vnet_flow_logs ? "virtual-network-flow-log" : "disabled"
}
output "endpoint_private_ips" {
  value = { for name, vm in module.endpoint : name => vm.private_ip_address }
}
output "cost_relevant_inventory" {
  value = {
    flow_logs        = length(module.flow_logs)
    storage_accounts = length(azurerm_storage_account.flow)
    log_analytics    = 0
    virtual_machines = length(module.endpoint)
  }
}
