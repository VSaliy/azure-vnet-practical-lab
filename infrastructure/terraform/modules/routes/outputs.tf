output "id" {
  value = azurerm_route_table.this.id
}

output "route_ids" {
  value = { for name, route in azurerm_route.this : name => route.id }
}
