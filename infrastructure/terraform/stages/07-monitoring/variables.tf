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
  description = "Enables two short-lived private diagnostics endpoints."
  type        = bool
  default     = false
}
variable "admin_ssh_public_key" {
  type      = string
  default   = null
  nullable  = true
  sensitive = true
}
variable "flow_log_storage_account_name" {
  type    = string
  default = "vnetlab07flowexample"
  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.flow_log_storage_account_name))
    error_message = "Storage account name must be 3-24 lowercase alphanumeric characters."
  }
}
variable "enable_vnet_flow_logs" {
  description = "Optional VNet flow logs; never NSG flow logs."
  type        = bool
  default     = false
}
variable "network_watcher_resource_group_name" {
  description = "Existing regional Network Watcher group discovered during Stage 00."
  type        = string
  default     = "NetworkWatcherRG"
}
variable "network_watcher_name" {
  description = "Existing watcher name; null uses NetworkWatcher_<location>."
  type        = string
  default     = null
  nullable    = true
}
variable "retention_days" {
  type    = number
  default = 1
  validation {
    condition     = var.retention_days >= 1 && var.retention_days <= 7
    error_message = "Lab retention is limited to 1-7 days."
  }
}
