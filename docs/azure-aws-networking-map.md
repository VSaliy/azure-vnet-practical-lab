# Azure and AWS networking map

| Azure | Approximate AWS concept | Important difference |
|---|---|---|
| VNet | VPC | Azure subnets are regional; both reserve addresses differently. |
| NSG | Security group | NSGs can attach to subnet and NIC and have explicit priorities. |
| UDR/route table | Route table | Azure subnet association and next-hop types differ. A route does not make an NVA forward. |
| VNet peering | VPC peering | Neither is transitive; pricing and flags differ. |
| Private Endpoint | Interface VPC endpoint | Azure Private DNS zone integration and service firewall behavior differ. |
| Service endpoint | Gateway/service routing feature | It keeps the service's public endpoint and extends subnet identity to it. |
| Azure Firewall | AWS Network Firewall/NAT combinations | Capabilities, routing, and cost are not one-to-one. |
| Network Watcher | Reachability Analyzer/VPC diagnostics | Diagnostic methods and evidence differ. |
| VPN Gateway | Virtual private gateway/transit components | SKUs, active-active design, BGP, and billing differ. |

Treat these as learning analogies, never migration mappings.
