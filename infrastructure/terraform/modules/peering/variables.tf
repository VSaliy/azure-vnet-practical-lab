variable "resource_group_name" { type = string }
variable "left_name" { type = string }
variable "left_id" { type = string }
variable "right_name" { type = string }
variable "right_id" { type = string }
variable "allow_virtual_network_access" {
  type    = bool
  default = true
}
variable "allow_forwarded_traffic" {
  type    = bool
  default = false
}
variable "allow_gateway_transit" {
  type    = bool
  default = false
}
variable "use_remote_gateways" {
  type    = bool
  default = false
}
