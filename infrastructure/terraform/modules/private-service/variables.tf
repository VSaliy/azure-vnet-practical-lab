variable "name" {
  type = string
  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.name))
    error_message = "Storage account name must be 3-24 lowercase alphanumeric characters."
  }
}
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "tags" { type = map(string) }
variable "service_subnet_id" { type = string }
variable "private_endpoint_subnet_id" { type = string }
variable "virtual_network_id" { type = string }
variable "enable_private_endpoint" {
  type    = bool
  default = false
}
variable "public_network_access_enabled" {
  description = "Keep true until private DNS and connectivity have succeeded."
  type        = bool
  default     = true
}
variable "private_connectivity_verified" {
  description = "Explicit phase-two acknowledgement."
  type        = bool
  default     = false
}
