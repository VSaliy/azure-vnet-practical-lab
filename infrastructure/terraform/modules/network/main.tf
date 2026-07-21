locals {
  subnet_prefixes = flatten([
    for name, subnet in var.subnets : [
      for prefix in subnet.address_prefixes : {
        name   = name
        prefix = prefix
      }
    ]
  ])
  subnet_pairs = flatten([
    for i, left in local.subnet_prefixes : [
      for j, right in local.subnet_prefixes : {
        left  = left
        right = right
      } if i < j
    ]
  ])
  address_ranges = {
    for cidr in distinct(concat(
      var.address_space,
      [for subnet in local.subnet_prefixes : subnet.prefix]
      )) : cidr => {
      start = sum([
        for index, octet in split(".", cidrhost(cidr, 0)) :
        tonumber(octet) * pow(256, 3 - index)
      ])
      end = sum([
        for index, octet in split(".", cidrhost(cidr, 0)) :
        tonumber(octet) * pow(256, 3 - index)
      ]) + pow(2, 32 - tonumber(split("/", cidr)[1])) - 1
    }
  }
}

resource "terraform_data" "cidr_guard" {
  lifecycle {
    precondition {
      condition = alltrue([
        for subnet in local.subnet_prefixes :
        anytrue([
          for vnet_cidr in var.address_space :
          local.address_ranges[subnet.prefix].start >= local.address_ranges[vnet_cidr].start &&
          local.address_ranges[subnet.prefix].end <= local.address_ranges[vnet_cidr].end
        ])
      ])
      error_message = "Every subnet must be contained by a VNet address prefix."
    }

    precondition {
      condition = alltrue([
        for pair in local.subnet_pairs :
        local.address_ranges[pair.left.prefix].end < local.address_ranges[pair.right.prefix].start ||
        local.address_ranges[pair.right.prefix].end < local.address_ranges[pair.left.prefix].start
      ])
      error_message = "Subnet CIDRs must not overlap."
    }
  }
}

resource "azurerm_virtual_network" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.address_space
  tags                = var.tags
  depends_on          = [terraform_data.cidr_guard]
}

resource "azurerm_subnet" "this" {
  for_each = var.subnets

  name                              = each.key
  resource_group_name               = var.resource_group_name
  virtual_network_name              = azurerm_virtual_network.this.name
  address_prefixes                  = each.value.address_prefixes
  service_endpoints                 = each.value.service_endpoints
  default_outbound_access_enabled   = false
  private_endpoint_network_policies = each.value.private_endpoint_network_policies
}
