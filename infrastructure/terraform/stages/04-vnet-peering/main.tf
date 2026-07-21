module "conventions" {
  source   = "../../modules/conventions"
  stage    = "04"
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
      error_message = "Two peering endpoints require approved price/quota and a funded mode."
    }
  }
}
module "left" {
  source              = "../../modules/network"
  name                = "${module.conventions.prefix}-left-vnet"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  address_space       = ["10.20.80.0/24"]
  subnets             = { workload = { address_prefixes = ["10.20.80.0/25"] } }
  tags                = module.conventions.tags
}
module "right" {
  source              = "../../modules/network"
  name                = "${module.conventions.prefix}-right-vnet"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  address_space       = ["10.20.81.0/24"]
  subnets             = { workload = { address_prefixes = ["10.20.81.0/25"] } }
  tags                = module.conventions.tags
}
module "peering" {
  source                       = "../../modules/peering"
  resource_group_name          = azurerm_resource_group.this.name
  left_name                    = module.left.name
  left_id                      = module.left.id
  right_name                   = module.right.name
  right_id                     = module.right.id
  allow_virtual_network_access = var.allow_virtual_network_access
}
module "nsg" {
  source              = "../../modules/nsg"
  name                = "${module.conventions.prefix}-workload-nsg"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  tags                = module.conventions.tags
  subnet_ids = {
    left  = module.left.subnet_ids["workload"]
    right = module.right.subnet_ids["workload"]
  }
  rules = {
    allow-peer-8080 = {
      priority                   = 100, direction = "Inbound", access = "Allow", protocol = "Tcp"
      destination_port_range     = "8080", source_address_prefix = "10.20.80.0/23"
      destination_address_prefix = "10.20.80.0/23"
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
    left  = { subnet_id = module.left.subnet_ids["workload"], ports = [] }
    right = { subnet_id = module.right.subnet_ids["workload"], ports = [8080] }
  }
}
module "endpoint" {
  for_each             = var.enable_live ? local.endpoints : {}
  source               = "../../modules/test-vm"
  name                 = "${module.conventions.prefix}-${each.key}-vm"
  resource_group_name  = azurerm_resource_group.this.name
  location             = var.location
  subnet_id            = each.value.subnet_id
  admin_ssh_public_key = var.admin_ssh_public_key
  listen_ports         = each.value.ports
  tags                 = module.conventions.tags
  depends_on           = [terraform_data.deployment_guard]
}
