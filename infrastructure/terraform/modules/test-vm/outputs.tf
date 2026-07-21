output "id" {
  value = azurerm_linux_virtual_machine.this.id
}

output "name" {
  value = azurerm_linux_virtual_machine.this.name
}

output "nic_id" {
  value = azurerm_network_interface.this.id
}

output "private_ip_address" {
  value = azurerm_network_interface.this.private_ip_address
}

output "shutdown_schedule_id" {
  value = azurerm_dev_test_global_vm_shutdown_schedule.this.id
}

output "principal_id" {
  value = azurerm_linux_virtual_machine.this.identity[0].principal_id
}
