resource "azurerm_network_watcher_flow_log" "this" {
  name                 = var.name
  network_watcher_name = var.network_watcher_name
  resource_group_name  = var.network_watcher_resource_group_name
  target_resource_id   = var.virtual_network_id
  storage_account_id   = var.storage_account_id
  enabled              = true
  version              = 2

  retention_policy {
    enabled = true
    days    = var.retention_days
  }
}
