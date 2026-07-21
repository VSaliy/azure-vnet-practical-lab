variable "location" {
  type    = string
  default = "westeurope"
}
variable "owner" {
  type    = string
  default = "learner"
}
variable "account_mode" {
  type    = string
  default = "no-credit"
  validation {
    condition     = contains(["active-credit", "free-services", "no-credit", "payg"], var.account_mode)
    error_message = "Invalid account mode."
  }
}
variable "cost_gate_approved" {
  type    = bool
  default = false
}
variable "enable_live" {
  type    = bool
  default = false
}
variable "admin_ssh_public_key" {
  type      = string
  default   = null
  nullable  = true
  sensitive = true
}
variable "fault" {
  type    = string
  default = "none"
  validation {
    condition = contains([
      "none", "nsg-priority", "return-route", "udr-next-hop"
    ], var.fault)
    error_message = "Use this root for none, nsg-priority, return-route, or udr-next-hop. Cross-stage faults use Stage 04 or 06."
  }
}
