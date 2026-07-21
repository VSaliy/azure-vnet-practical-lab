output "storage_account_id" {
  value = azurerm_storage_account.this.id
}

output "blob_hostname" {
  value = azurerm_storage_account.this.primary_blob_host
}

output "private_endpoint_id" {
  value = try(azurerm_private_endpoint.blob[0].id, null)
}

output "private_ip_address" {
  value = try(azurerm_private_endpoint.blob[0].private_service_connection[0].private_ip_address, null)
}
