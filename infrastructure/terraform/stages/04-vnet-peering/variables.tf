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
variable "allow_virtual_network_access" {
  description = "Directional access flag used by the peering fault exercise."
  type        = bool
  default     = true
}
