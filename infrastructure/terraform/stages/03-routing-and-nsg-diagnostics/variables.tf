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
variable "inject_blackhole_route" {
  description = "Deliberately changes the target prefix next hop to None."
  type        = bool
  default     = false
}
