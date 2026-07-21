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
  description = "Creates the low-cost Storage service endpoint exercise."
  type        = bool
  default     = false
}
variable "admin_ssh_public_key" {
  type      = string
  default   = null
  nullable  = true
  sensitive = true
}
variable "storage_account_name" {
  description = "Globally unique lowercase name chosen by the learner."
  type        = string
  default     = "vnetlab06example"
  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "Storage account name must be 3-24 lowercase alphanumeric characters."
  }
}
variable "enable_private_endpoint" {
  type    = bool
  default = false
}
variable "public_network_access_enabled" {
  description = "Phase one must remain true. Set false only after private verification."
  type        = bool
  default     = true
}
variable "private_connectivity_verified" {
  type    = bool
  default = false
}
variable "private_connectivity_evidence_file" {
  description = "Absolute path to evidence written by Test-Stage06PrivateConnectivity.ps1 after a successful private test."
  type        = string
  default     = null
  nullable    = true
}
