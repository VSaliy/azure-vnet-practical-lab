locals {
  prefix     = "vnetlab-${var.stage}"
  expires_on = formatdate("YYYY-MM-DD", timeadd(timestamp(), "24h"))
  required_tags = {
    environment = "lab"
    owner       = var.owner
    expires-on  = local.expires_on
    managed-by  = "terraform"
    lab-stage   = var.stage
  }
  tags = merge(var.extra_tags, local.required_tags)
}
