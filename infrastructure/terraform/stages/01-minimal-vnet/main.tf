module "conventions" {
  source   = "../../modules/conventions"
  stage    = "01"
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
      error_message = "Live VM requires a funded account mode, approved current cost gate, and ephemeral SSH public key."
    }
  }
}

module "network" {
  source              = "../../modules/network"
  name                = "${module.conventions.prefix}-vnet"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  address_space       = ["10.20.0.0/20"]
  tags                = module.conventions.tags
  subnets = {
    management  = { address_prefixes = ["10.20.0.0/24"] }
    application = { address_prefixes = ["10.20.1.0/24"] }
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

module "application_nsg" {
  source              = "../../modules/nsg"
  name                = "${module.conventions.prefix}-application-nsg"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  tags                = module.conventions.tags
  subnet_ids          = { application = module.network.subnet_ids["application"] }
  rules = {
    allow-management-ssh = {
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      destination_port_range     = "22"
      source_address_prefix      = "10.20.0.0/24"
      destination_address_prefix = "10.20.1.0/24"
      description                = "Private management source only"
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

module "vm" {
  count = var.enable_live ? 1 : 0

  source               = "../../modules/test-vm"
  name                 = "${module.conventions.prefix}-application-vm"
  resource_group_name  = azurerm_resource_group.this.name
  location             = var.location
  subnet_id            = module.network.subnet_ids["application"]
  admin_ssh_public_key = var.admin_ssh_public_key
  listen_ports         = []
  tags                 = module.conventions.tags
  depends_on           = [terraform_data.deployment_guard]
}
