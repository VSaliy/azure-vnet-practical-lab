variable "stage" {
  description = "Two-digit lab stage."
  type        = string

  validation {
    condition     = contains(["01", "02", "03", "04", "05", "06", "07", "08"], var.stage)
    error_message = "stage must be one of 01 through 08."
  }
}

variable "owner" {
  description = "Non-sensitive learner alias."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9._-]{1,30}$", var.owner))
    error_message = "owner must be a 2-31 character non-sensitive alias."
  }
}

variable "location" {
  type = string

  validation {
    condition     = contains(["westeurope", "northeurope"], var.location)
    error_message = "Use an approved region after checking price, quota, and availability."
  }
}

variable "extra_tags" {
  type    = map(string)
  default = {}
}
