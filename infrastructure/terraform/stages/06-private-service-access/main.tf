module "conventions" {
  source   = "../../modules/conventions"
  stage    = "06"
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
      error_message = "Storage and its private test VM require verified price/eligibility, approval, and an ephemeral SSH public key."
    }
    precondition {
      condition     = !var.enable_private_endpoint || var.enable_live
      error_message = "Enable the service endpoint phase before the private endpoint."
    }
    precondition {
      condition = var.public_network_access_enabled || (
        var.enable_live &&
        var.enable_private_endpoint &&
        var.private_connectivity_verified &&
        try(
          var.private_connectivity_evidence_file != null ? (
            fileexists(var.private_connectivity_evidence_file) ?
            trimspace(file(var.private_connectivity_evidence_file)) == "PRIVATE_CONNECTIVITY_VERIFIED:${var.storage_account_name}" :
            false
          ) : false,
          false
        )
      )
      error_message = "Public Storage access can be disabled only with evidence produced after a successful private DNS and managed-identity test."
    }
  }
}

module "network" {
  source              = "../../modules/network"
  name                = "${module.conventions.prefix}-vnet"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  address_space       = ["10.20.82.0/23"]
  tags                = module.conventions.tags
  subnets = {
    workload = {
      address_prefixes  = ["10.20.82.0/24"]
      service_endpoints = ["Microsoft.Storage"]
    }
    private-endpoints = {
      address_prefixes                  = ["10.20.83.0/24"]
      private_endpoint_network_policies = "Enabled"
    }
  }
}

module "workload_nsg" {
  source              = "../../modules/nsg"
  name                = "${module.conventions.prefix}-workload-nsg"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  tags                = module.conventions.tags
  subnet_ids          = { workload = module.network.subnet_ids["workload"] }
  rules = {
    deny-vnet-inbound = {
      priority                   = 4096, direction = "Inbound", access = "Deny", protocol = "*"
      destination_port_range     = "*", source_address_prefix = "VirtualNetwork"
      destination_address_prefix = "*"
    }
  }
}

module "private_endpoint_nsg" {
  source              = "../../modules/nsg"
  name                = "${module.conventions.prefix}-private-endpoint-nsg"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  tags                = module.conventions.tags
  subnet_ids          = { private-endpoints = module.network.subnet_ids["private-endpoints"] }
  rules = {
    allow-workload-https = {
      priority                   = 100, direction = "Inbound", access = "Allow", protocol = "Tcp"
      destination_port_range     = "443", source_address_prefix = "10.20.82.0/24"
      destination_address_prefix = "10.20.83.0/24"
    }
    deny-vnet-inbound = {
      priority                   = 4096, direction = "Inbound", access = "Deny", protocol = "*"
      destination_port_range     = "*", source_address_prefix = "VirtualNetwork"
      destination_address_prefix = "*"
    }
  }
}

module "service" {
  count = var.enable_live ? 1 : 0

  source                        = "../../modules/private-service"
  name                          = var.storage_account_name
  resource_group_name           = azurerm_resource_group.this.name
  location                      = var.location
  tags                          = module.conventions.tags
  service_subnet_id             = module.network.subnet_ids["workload"]
  private_endpoint_subnet_id    = module.network.subnet_ids["private-endpoints"]
  virtual_network_id            = module.network.id
  enable_private_endpoint       = var.enable_private_endpoint
  public_network_access_enabled = var.public_network_access_enabled
  private_connectivity_verified = var.private_connectivity_verified
  depends_on                    = [terraform_data.deployment_guard]
}

module "test_vm" {
  count = var.enable_live ? 1 : 0

  source               = "../../modules/test-vm"
  name                 = "${module.conventions.prefix}-test-vm"
  resource_group_name  = azurerm_resource_group.this.name
  location             = var.location
  subnet_id            = module.network.subnet_ids["workload"]
  admin_ssh_public_key = var.admin_ssh_public_key
  listen_ports         = []
  tags                 = module.conventions.tags
  depends_on           = [terraform_data.deployment_guard]
}

resource "azurerm_role_assignment" "storage_reader" {
  count = var.enable_live ? 1 : 0

  scope                = module.service[0].storage_account_id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = module.test_vm[0].principal_id
}
