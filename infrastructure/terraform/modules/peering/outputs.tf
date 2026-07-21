output "ids" {
  value = [
    azurerm_virtual_network_peering.left_to_right.id,
    azurerm_virtual_network_peering.right_to_left.id
  ]
}

output "transitive_routing_enabled" {
  description = "Always false: peering alone is never transitive."
  value       = false
}
