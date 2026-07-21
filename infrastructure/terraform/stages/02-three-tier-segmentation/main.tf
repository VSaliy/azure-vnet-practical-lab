module "conventions" {
  source   = "../../modules/conventions"
  stage    = "02"
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
      error_message = "Exactly four live VMs require verified price, allocation/quota, funded mode, and an ephemeral SSH public key."
    }
    precondition {
      condition     = length(local.endpoints) == 4
      error_message = "Stage 02 topology must define exactly four endpoint roles."
    }
  }
}

module "network" {
  source              = "../../modules/network"
  name                = "${module.conventions.prefix}-vnet"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  address_space       = ["10.20.16.0/20"]
  tags                = module.conventions.tags
  subnets = {
    management  = { address_prefixes = ["10.20.16.0/24"] }
    web         = { address_prefixes = ["10.20.17.0/24"] }
    application = { address_prefixes = ["10.20.18.0/24"] }
    data        = { address_prefixes = ["10.20.19.0/24"] }
  }
}

module "management_nsg" {
  source              = "../../modules/nsg"
  name                = "${module.conventions.prefix}-management-nsg"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  tags                = module.conventions.tags
  subnet_ids          = { management = module.network.subnet_ids["management"] }
  rules = {
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

module "web_nsg" {
  source              = "../../modules/nsg"
  name                = "${module.conventions.prefix}-web-nsg"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  tags                = module.conventions.tags
  subnet_ids          = { web = module.network.subnet_ids["web"] }
  rules = {
    allow-management-ssh = {
      priority                   = 100, direction = "Inbound", access = "Allow", protocol = "Tcp"
      destination_port_range     = "22", source_address_prefix = "10.20.16.0/24"
      destination_address_prefix = "10.20.17.0/24"
    }
    deny-vnet-inbound = {
      priority                   = 4096, direction = "Inbound", access = "Deny", protocol = "*"
      destination_port_range     = "*", source_address_prefix = "VirtualNetwork"
      destination_address_prefix = "*"
    }
  }
}

module "application_nsg" {
  source              = "../../modules/nsg"
  name                = "${module.conventions.prefix}-application-nsg"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  tags                = module.conventions.tags
  subnet_ids          = { application = module.network.subnet_ids["application"] }
  rules = {
    allow-web-8080 = {
      priority                   = 100, direction = "Inbound", access = "Allow", protocol = "Tcp"
      destination_port_range     = "8080", source_address_prefix = "10.20.17.0/24"
      destination_address_prefix = "10.20.18.0/24"
    }
    deny-internet-any = {
      priority                   = 200, direction = "Inbound", access = "Deny", protocol = "*"
      destination_port_range     = "*", source_address_prefix = "Internet"
      destination_address_prefix = "10.20.18.0/24"
    }
    deny-vnet-inbound = {
      priority                   = 4096, direction = "Inbound", access = "Deny", protocol = "*"
      destination_port_range     = "*", source_address_prefix = "VirtualNetwork"
      destination_address_prefix = "*"
    }
  }
}

module "data_nsg" {
  source              = "../../modules/nsg"
  name                = "${module.conventions.prefix}-data-nsg"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  tags                = module.conventions.tags
  subnet_ids          = { data = module.network.subnet_ids["data"] }
  rules = {
    allow-application-5432 = {
      priority                   = 100, direction = "Inbound", access = "Allow", protocol = "Tcp"
      destination_port_range     = "5432", source_address_prefix = "10.20.18.0/24"
      destination_address_prefix = "10.20.19.0/24"
    }
    deny-web-5432 = {
      priority                   = 110, direction = "Inbound", access = "Deny", protocol = "Tcp"
      destination_port_range     = "5432", source_address_prefix = "10.20.17.0/24"
      destination_address_prefix = "10.20.19.0/24"
    }
    deny-vnet-inbound = {
      priority                   = 4096, direction = "Inbound", access = "Deny", protocol = "*"
      destination_port_range     = "*", source_address_prefix = "VirtualNetwork"
      destination_address_prefix = "*"
    }
  }
}

locals {
  endpoints = {
    management  = { subnet = "management", ports = [] }
    web         = { subnet = "web", ports = [] }
    application = { subnet = "application", ports = [8080] }
    data        = { subnet = "data", ports = [5432] }
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
