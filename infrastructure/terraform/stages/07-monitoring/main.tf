module "conventions" {
  source   = "../../modules/conventions"
  stage    = "07"
  owner    = var.owner
  location = var.location
}

resource "azurerm_resource_group" "this" {
  name     = "${module.conventions.prefix}-rg"
  location = var.location
  tags     = module.conventions.tags
}

resource "terraform_data" "deployment_guard" {
  lifecycle {
    precondition {
      condition = (
        (!var.enable_live && !var.enable_vnet_flow_logs) ||
        (var.cost_gate_approved && var.account_mode != "no-credit" && (!var.enable_live || var.admin_ssh_public_key != null))
      )
      error_message = "Endpoints/flow logs require current pricing, eligibility/quota, approval, and an SSH key for VMs."
    }
  }
}

module "network" {
  source              = "../../modules/network"
  name                = "${module.conventions.prefix}-vnet"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  address_space       = ["10.20.86.0/23"]
  tags                = module.conventions.tags
  subnets = {
    monitored   = { address_prefixes = ["10.20.86.0/24"] }
    diagnostics = { address_prefixes = ["10.20.87.0/24"] }
  }
}

data "azurerm_network_watcher" "this" {
  count = var.enable_vnet_flow_logs ? 1 : 0

  name                = coalesce(var.network_watcher_name, "NetworkWatcher_${var.location}")
  resource_group_name = var.network_watcher_resource_group_name
}

resource "azurerm_storage_account" "flow" {
  count = var.enable_vnet_flow_logs ? 1 : 0

  name                     = var.flow_log_storage_account_name
  resource_group_name      = azurerm_resource_group.this.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  tags                     = module.conventions.tags
  depends_on               = [terraform_data.deployment_guard]
}

module "flow_logs" {
  count = var.enable_vnet_flow_logs ? 1 : 0

  source                              = "../../modules/vnet-flow-logs"
  name                                = "${module.conventions.prefix}-vnet-flow"
  network_watcher_name                = data.azurerm_network_watcher.this[0].name
  network_watcher_resource_group_name = data.azurerm_network_watcher.this[0].resource_group_name
  virtual_network_id                  = module.network.id
  storage_account_id                  = azurerm_storage_account.flow[0].id
  retention_days                      = var.retention_days
}

module "diagnostics_nsg" {
  source              = "../../modules/nsg"
  name                = "${module.conventions.prefix}-diagnostics-nsg"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  tags                = module.conventions.tags
  subnet_ids          = { diagnostics = module.network.subnet_ids["diagnostics"] }
  rules = {
    allow-monitored-8080 = {
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      destination_port_range     = "8080"
      source_address_prefix      = "10.20.86.0/24"
      destination_address_prefix = "10.20.87.0/24"
    }
    deny-vnet-inbound = {
      priority                   = 4096, direction = "Inbound", access = "Deny", protocol = "*"
      destination_port_range     = "*", source_address_prefix = "VirtualNetwork"
      destination_address_prefix = "*"
    }
  }
}

module "monitored_nsg" {
  source              = "../../modules/nsg"
  name                = "${module.conventions.prefix}-monitored-nsg"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  tags                = module.conventions.tags
  subnet_ids          = { monitored = module.network.subnet_ids["monitored"] }
  rules = {
    deny-vnet-inbound = {
      priority                   = 4096, direction = "Inbound", access = "Deny", protocol = "*"
      destination_port_range     = "*", source_address_prefix = "VirtualNetwork"
      destination_address_prefix = "*"
    }
  }
}

locals {
  endpoints = {
    monitored   = { subnet = "monitored", ports = [] }
    diagnostics = { subnet = "diagnostics", ports = [8080] }
  }
}

module "endpoint" {
  for_each = var.enable_live ? local.endpoints : {}

  source               = "../../modules/test-vm"
  name                 = "${module.conventions.prefix}-${each.key}-vm"
  resource_group_name  = azurerm_resource_group.this.name
  location             = var.location
  subnet_id            = module.network.subnet_ids[each.value.subnet]
  admin_ssh_public_key = var.admin_ssh_public_key
  listen_ports         = each.value.ports
  tags                 = module.conventions.tags
  depends_on           = [terraform_data.deployment_guard]
}
