resource "azurerm_storage_account" "this" {
  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  account_tier                  = "Standard"
  account_replication_type      = "LRS"
  account_kind                  = "StorageV2"
  public_network_access_enabled = var.public_network_access_enabled
  min_tls_version               = "TLS1_2"
  shared_access_key_enabled     = false
  local_user_enabled            = false
  tags                          = var.tags

  lifecycle {
    precondition {
      condition = var.public_network_access_enabled || (
        var.enable_private_endpoint && var.private_connectivity_verified
      )
      error_message = "Disable public access only after private endpoint DNS/connectivity is verified."
    }
  }

  network_rules {
    default_action             = "Deny"
    bypass                     = ["None"]
    virtual_network_subnet_ids = [var.service_subnet_id]
  }
}

resource "azurerm_private_dns_zone" "blob" {
  count = var.enable_private_endpoint ? 1 : 0

  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  count = var.enable_private_endpoint ? 1 : 0

  name                  = "${var.name}-vnet-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.blob[0].name
  virtual_network_id    = var.virtual_network_id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_endpoint" "blob" {
  count = var.enable_private_endpoint ? 1 : 0

  name                = "${var.name}-blob-pe"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.name}-blob"
    private_connection_resource_id = azurerm_storage_account.this.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "blob"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob[0].id]
  }
}
