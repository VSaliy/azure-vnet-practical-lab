# Official references

Accessed 2026-07-21:

- [Default outbound access](https://learn.microsoft.com/azure/virtual-network/ip-services/default-outbound-access)
- [Virtual network FAQ](https://learn.microsoft.com/azure/virtual-network/virtual-networks-faq)
- [Network security groups](https://learn.microsoft.com/azure/virtual-network/network-security-groups-overview)
- [Virtual network traffic routing](https://learn.microsoft.com/azure/virtual-network/virtual-networks-udr-overview)
- [Virtual network peering](https://learn.microsoft.com/azure/virtual-network/virtual-network-peering-overview)
- [Private Endpoint DNS](https://learn.microsoft.com/azure/private-link/private-endpoint-dns)
- [Storage network security](https://learn.microsoft.com/azure/storage/common/storage-network-security)
- [Network Watcher](https://learn.microsoft.com/azure/network-watcher/network-watcher-monitoring-overview)
- [NSG flow-log retirement](https://learn.microsoft.com/azure/network-watcher/nsg-flow-logs-overview)
- [VNet flow logs](https://learn.microsoft.com/azure/network-watcher/vnet-flow-logs-overview)
- [Bastion SKU comparison](https://learn.microsoft.com/azure/bastion/bastion-sku-comparison)
- [Azure CLI](https://learn.microsoft.com/cli/azure/)
- [GitHub OIDC for Azure](https://learn.microsoft.com/azure/developer/github/connect-from-azure-openid-connect)
- [AzureRM provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Provider versioning](https://developer.hashicorp.com/terraform/tutorials/configuration-language/provider-versioning)
- [Dependency lock files](https://developer.hashicorp.com/terraform/language/files/dependency-lock)

Version-sensitive facts must be rechecked before deployment. In particular, new NSG flow logs are retired, VNet flow logs are the replacement, and current API behavior requires explicit outbound design.
