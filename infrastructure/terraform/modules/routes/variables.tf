variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "tags" { type = map(string) }

variable "routes" {
  type = map(object({
    address_prefix         = string
    next_hop_type          = string
    next_hop_in_ip_address = optional(string)
  }))

  validation {
    condition = alltrue([
      for route in values(var.routes) :
      can(cidrnetmask(route.address_prefix)) &&
      contains(["VirtualNetworkGateway", "VnetLocal", "Internet", "VirtualAppliance", "None"], route.next_hop_type) &&
      (route.next_hop_type != "VirtualAppliance" || try(route.next_hop_in_ip_address != "", false))
    ])
    error_message = "Routes require a CIDR, supported next hop, and an IP for VirtualAppliance."
  }
}

variable "subnet_ids" {
  type    = map(string)
  default = {}
}
