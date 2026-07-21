variable "name" { type = string }
variable "network_watcher_name" { type = string }
variable "network_watcher_resource_group_name" { type = string }
variable "virtual_network_id" { type = string }
variable "storage_account_id" { type = string }
variable "retention_days" {
  type    = number
  default = 1
  validation {
    condition     = var.retention_days >= 1 && var.retention_days <= 7
    error_message = "Lab flow-log retention must be 1-7 days."
  }
}
