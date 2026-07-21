module "conventions" {
  source   = "../../modules/conventions"
  stage    = "03"
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
      error_message = "Live diagnostics endpoints require an approved funded gate and SSH public key."
    }
  }
}
module "network" {
  source              = "../../modules/network"
  name                = "${module.conventions.prefix}-vnet"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  address_space       = ["10.20.84.0/23"]
  subnets = {
    source = { address_prefixes = ["10.20.84.0/24"] }
    target = { address_prefixes = ["10.20.85.0/24"] }
  }
  tags = module.conventions.tags
}
module "nsg" {
  source              = "../../modules/nsg"
  name                = "${module.conventions.prefix}-target-nsg"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  tags                = module.conventions.tags
  subnet_ids          = { target = module.network.subnet_ids["target"] }
  rules = {
    allow-source-8080 = {
      priority                   = 100, direction = "Inbound", access = "Allow", protocol = "Tcp"
      destination_port_range     = "8080", source_address_prefix = "10.20.84.0/24"
      destination_address_prefix = "10.20.85.0/24"
    }
    deny-vnet-inbound = {
      priority                   = 4096, direction = "Inbound", access = "Deny", protocol = "*"
      destination_port_range     = "*", source_address_prefix = "VirtualNetwork"
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
    diagnostic-target = {
      address_prefix = "10.20.85.0/24"
      next_hop_type  = var.inject_blackhole_route ? "None" : "VnetLocal"
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
  for_each             = var.enable_live ? local.endpoints : {}
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
