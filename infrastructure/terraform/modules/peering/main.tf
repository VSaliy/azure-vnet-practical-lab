resource "terraform_data" "configuration_guard" {
  lifecycle {
    precondition {
      condition     = !var.use_remote_gateways || var.allow_gateway_transit
      error_message = "Gateway use requires a separately designed gateway/transit configuration."
    }
  }
}

resource "azurerm_virtual_network_peering" "left_to_right" {
  name                         = "${var.left_name}-to-${var.right_name}"
  resource_group_name          = var.resource_group_name
  virtual_network_name         = var.left_name
  remote_virtual_network_id    = var.right_id
  allow_virtual_network_access = var.allow_virtual_network_access
  allow_forwarded_traffic      = var.allow_forwarded_traffic
  allow_gateway_transit        = var.allow_gateway_transit
  use_remote_gateways          = false
  depends_on                   = [terraform_data.configuration_guard]
}

resource "azurerm_virtual_network_peering" "right_to_left" {
  name                         = "${var.right_name}-to-${var.left_name}"
  resource_group_name          = var.resource_group_name
  virtual_network_name         = var.right_name
  remote_virtual_network_id    = var.left_id
  allow_virtual_network_access = var.allow_virtual_network_access
  allow_forwarded_traffic      = var.allow_forwarded_traffic
  allow_gateway_transit        = false
  use_remote_gateways          = var.use_remote_gateways
  depends_on                   = [terraform_data.configuration_guard]
}
