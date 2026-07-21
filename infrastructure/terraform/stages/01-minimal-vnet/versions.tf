terraform {
  required_version = ">= 1.7.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

provider "azurerm" {
  resource_provider_registrations = "none"
  features {}
}
