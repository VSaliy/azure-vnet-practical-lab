variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "address_space" {
  type = list(string)

  validation {
    condition = length(var.address_space) > 0 && alltrue([
      for cidr in var.address_space :
      can(cidrnetmask(cidr)) && try(cidrhost(cidr, 0) == split("/", cidr)[0], false)
    ])
    error_message = "address_space must contain canonical network CIDRs without host bits."
  }
}

variable "subnets" {
  type = map(object({
    address_prefixes                  = list(string)
    service_endpoints                 = optional(list(string), [])
    private_endpoint_network_policies = optional(string, "Enabled")
  }))

  validation {
    condition = length(var.subnets) > 0 && alltrue(flatten([
      for subnet in values(var.subnets) : [
        for cidr in subnet.address_prefixes :
        can(cidrnetmask(cidr)) && try(cidrhost(cidr, 0) == split("/", cidr)[0], false)
      ]
    ]))
    error_message = "Every subnet prefix must be a canonical network CIDR without host bits."
  }
}

variable "tags" {
  type = map(string)
}
