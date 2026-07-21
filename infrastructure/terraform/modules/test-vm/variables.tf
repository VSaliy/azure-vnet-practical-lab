variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "subnet_id" { type = string }
variable "tags" { type = map(string) }
variable "admin_username" {
  type    = string
  default = "labadmin"
}
variable "admin_ssh_public_key" {
  type      = string
  sensitive = true
  validation {
    condition     = can(regex("^ssh-(rsa|ed25519) ", var.admin_ssh_public_key))
    error_message = "Provide an SSH RSA or Ed25519 public key; never commit a private key."
  }
}
variable "size" {
  type    = string
  default = "Standard_B1s"
}
variable "listen_ports" {
  type    = list(number)
  default = []
  validation {
    condition     = alltrue([for port in var.listen_ports : port >= 1 && port <= 65535])
    error_message = "Listener ports must be 1-65535."
  }
}
