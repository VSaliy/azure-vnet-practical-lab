module "conventions" {
  source   = "../../modules/conventions"
  stage    = "08"
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
      error_message = "Live troubleshooting endpoints require approved current cost/quota and an SSH public key."
    }
  }
}

module "network" {
  source              = "../../modules/network"
  name                = "${module.conventions.prefix}-vnet"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  address_space       = ["10.20.88.0/21"]
  tags                = module.conventions.tags
  subnets = {
    source = { address_prefixes = ["10.20.88.0/24"] }
    target = { address_prefixes = ["10.20.89.0/24"] }
    dns    = { address_prefixes = ["10.20.90.0/24"] }
  }
}

module "target_nsg" {
  source              = "../../modules/nsg"
  name                = "${module.conventions.prefix}-target-nsg"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  tags                = module.conventions.tags
  subnet_ids          = { target = module.network.subnet_ids["target"] }
  rules = {
    allow-source-8080 = {
      priority                   = var.fault == "nsg-priority" ? 300 : 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      destination_port_range     = "8080"
      source_address_prefix      = "10.20.88.0/24"
      destination_address_prefix = "10.20.89.0/24"
    }
    deny-source-when-faulted = {
      priority                   = 200
      direction                  = "Inbound"
      access                     = var.fault == "nsg-priority" ? "Deny" : "Allow"
      protocol                   = "Tcp"
      destination_port_range     = "8080"
      source_address_prefix      = "10.20.88.0/24"
      destination_address_prefix = "10.20.89.0/24"
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

module "source_nsg" {
  source              = "../../modules/nsg"
  name                = "${module.conventions.prefix}-source-nsg"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  tags                = module.conventions.tags
  subnet_ids          = { source = module.network.subnet_ids["source"] }
  rules = {
    deny-vnet-inbound = {
      priority                   = 4096, direction = "Inbound", access = "Deny", protocol = "*"
      destination_port_range     = "*", source_address_prefix = "VirtualNetwork"
      destination_address_prefix = "*"
    }
  }
}

module "routes" {
  source              = "../../modules/routes"
  name                = "${module.conventions.prefix}-source-rt"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  tags                = module.conventions.tags
  subnet_ids          = { source = module.network.subnet_ids["source"] }
  routes = {
    target = {
      address_prefix = "10.20.89.0/24"
      next_hop_type  = var.fault == "udr-next-hop" ? "None" : "VnetLocal"
    }
  }
}

module "return_routes" {
  source              = "../../modules/routes"
  name                = "${module.conventions.prefix}-target-rt"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  tags                = module.conventions.tags
  subnet_ids          = { target = module.network.subnet_ids["target"] }
  routes = {
    source = {
      address_prefix = "10.20.88.0/24"
      next_hop_type  = var.fault == "return-route" ? "None" : "VnetLocal"
    }
  }
}

locals {
  endpoints = {
    source = { subnet = "source", ports = [] }
    target = { subnet = "target", ports = [8080] }
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
