variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "tags" { type = map(string) }

variable "rules" {
  type = map(object({
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = optional(string, "*")
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
    description                = optional(string, null)
  }))

  validation {
    condition = alltrue([
      for rule in values(var.rules) :
      rule.priority >= 100 && rule.priority <= 4096 &&
      contains(["Inbound", "Outbound"], rule.direction) &&
      contains(["Allow", "Deny"], rule.access)
    ])
    error_message = "Rules require a valid priority, direction, and access."
  }

  validation {
    condition     = length(distinct([for rule in values(var.rules) : "${rule.direction}-${rule.priority}"])) == length(var.rules)
    error_message = "Priorities must be unique within each direction."
  }
}

variable "subnet_ids" {
  type    = map(string)
  default = {}
}
