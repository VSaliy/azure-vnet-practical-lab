module "conventions" {
  source   = "../../modules/conventions"
  stage    = "05"
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
      condition     = !var.enable_live || (var.cost_gate_approved && var.account_mode != "no-credit" && var.admin_ssh_public_key != null)
      error_message = "Three topology endpoints require approved current cost/quota and an SSH public key."
    }
    precondition {
      condition     = !var.enable_private_dns || (var.cost_gate_approved && var.account_mode != "no-credit")
      error_message = "Private DNS is chargeable and requires current pricing/eligibility and approval."
    }
  }
}

module "hub" {
  source              = "../../modules/network"
  name                = "${module.conventions.prefix}-hub-vnet"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  address_space       = ["10.20.32.0/20"]
  tags                = module.conventions.tags
  subnets = {
    shared-services = { address_prefixes = ["10.20.32.0/24"] }
    management      = { address_prefixes = ["10.20.33.0/24"] }
    dns             = { address_prefixes = ["10.20.34.0/24"] }
  }
}

module "spoke1" {
  source              = "../../modules/network"
  name                = "${module.conventions.prefix}-spoke1-vnet"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  address_space       = ["10.20.48.0/20"]
  tags                = module.conventions.tags
  subnets             = { workload = { address_prefixes = ["10.20.48.0/24"] } }
}

module "spoke2" {
  source              = "../../modules/network"
  name                = "${module.conventions.prefix}-spoke2-vnet"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  address_space       = ["10.20.64.0/20"]
  tags                = module.conventions.tags
  subnets             = { workload = { address_prefixes = ["10.20.64.0/24"] } }
}

module "hub_spoke1" {
  source              = "../../modules/peering"
  resource_group_name = azurerm_resource_group.this.name
  left_name           = module.hub.name
  left_id             = module.hub.id
  right_name          = module.spoke1.name
  right_id            = module.spoke1.id
}

module "hub_spoke2" {
  source              = "../../modules/peering"
  resource_group_name = azurerm_resource_group.this.name
  left_name           = module.hub.name
  left_id             = module.hub.id
  right_name          = module.spoke2.name
  right_id            = module.spoke2.id
}

module "topology_nsg" {
  source              = "../../modules/nsg"
  name                = "${module.conventions.prefix}-topology-nsg"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  tags                = module.conventions.tags
  subnet_ids = {
    hub    = module.hub.subnet_ids["management"]
    spoke1 = module.spoke1.subnet_ids["workload"]
    spoke2 = module.spoke2.subnet_ids["workload"]
  }
  rules = {
    allow-lab-8080 = {
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      destination_port_range     = "8080"
      source_address_prefix      = "10.20.0.0/16"
      destination_address_prefix = "10.20.0.0/16"
    }
    deny-vnet-inbound = {
      priority                   = 4096
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      destination_port_range     = "*"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "*"
    }
  }
}

resource "azurerm_private_dns_zone" "internal" {
  count = var.enable_private_dns ? 1 : 0

  name                = "lab.internal"
  resource_group_name = azurerm_resource_group.this.name
  tags                = module.conventions.tags
  depends_on          = [terraform_data.deployment_guard]
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each = var.enable_private_dns ? {
    hub    = module.hub.id
    spoke1 = module.spoke1.id
    spoke2 = module.spoke2.id
  } : {}

  name                  = "${each.key}-link"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.internal[0].name
  virtual_network_id    = each.value
  registration_enabled  = false
  tags                  = module.conventions.tags
}

locals {
  endpoints = {
    hub    = module.hub.subnet_ids["management"]
    spoke1 = module.spoke1.subnet_ids["workload"]
    spoke2 = module.spoke2.subnet_ids["workload"]
  }
}

module "endpoint" {
  for_each = var.enable_live ? local.endpoints : {}

  source               = "../../modules/test-vm"
  name                 = "${module.conventions.prefix}-${each.key}-vm"
  resource_group_name  = azurerm_resource_group.this.name
  location             = var.location
  subnet_id            = each.value
  admin_ssh_public_key = var.admin_ssh_public_key
  listen_ports         = [8080]
  tags                 = module.conventions.tags
  depends_on           = [terraform_data.deployment_guard]
}
