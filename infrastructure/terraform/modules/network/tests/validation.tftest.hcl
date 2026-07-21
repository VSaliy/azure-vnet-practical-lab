mock_provider "azurerm" {}

variables {
  name                = "validation-vnet"
  resource_group_name = "validation-rg"
  location            = "westeurope"
  address_space       = ["10.20.0.0/20"]
  tags = {
    environment = "lab"
  }
}

run "accept_non_overlapping_subnets" {
  command = plan
  variables {
    subnets = {
      one = { address_prefixes = ["10.20.0.0/24"] }
      two = { address_prefixes = ["10.20.1.0/24"] }
    }
  }
}

run "reject_overlapping_subnets" {
  command = plan
  variables {
    subnets = {
      one = { address_prefixes = ["10.20.0.0/24"] }
      two = { address_prefixes = ["10.20.0.128/25"] }
    }
  }
  expect_failures = [terraform_data.cidr_guard]
}

run "reject_subnet_outside_vnet" {
  command = plan
  variables {
    subnets = {
      outside = { address_prefixes = ["10.21.0.0/24"] }
    }
  }
  expect_failures = [terraform_data.cidr_guard]
}

run "reject_host_bits_in_subnet_cidr" {
  command = plan
  variables {
    subnets = {
      invalid = { address_prefixes = ["10.20.0.1/24"] }
    }
  }
  expect_failures = [var.subnets]
}
