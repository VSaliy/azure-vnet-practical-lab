output "id" {
  value = azurerm_virtual_network.this.id
}

output "name" {
  value = azurerm_virtual_network.this.name
}

output "address_space" {
  value = azurerm_virtual_network.this.address_space
}

output "subnet_ids" {
  value = { for name, subnet in azurerm_subnet.this : name => subnet.id }
}

output "subnet_prefixes" {
  value = { for name, subnet in var.subnets : name => subnet.address_prefixes }
}
