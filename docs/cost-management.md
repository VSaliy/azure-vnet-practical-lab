# Cost management

## Account modes

| Mode | Live behavior |
|---|---|
| `active-credit` | Short-lived compute may run after current price/quota/credit checks. |
| `free-services` | Run only if every SKU and quantity fits verified remaining free allocation. |
| `no-credit` | Static/control-plane learning only; live tests remain planned, not executed. |
| `payg` | Paid stages require explicit approval and the same envelope; upgrading is never recommended for this lab. |

Targets are below USD 2 equivalent per default stage and below USD 10 cumulative, in local currency after current retail-price discovery. Unknown price or eligibility blocks live deployment.

## Stage gates

| Stage | Default | Potential billers | Gate |
|---|---|---|---|
| 00 | Static | none | read-only discovery |
| 01 | Network only | optional VM/disk | price + one VM quota |
| 02 | Network only | exactly 4 VMs/disks | credit/free allocation + four-vCPU/SKU quota |
| 03 | Network only | optional endpoints | price + quota |
| 04 | Network only | optional 2 VMs, peered data | price + minimal traffic |
| 05 | Network only | peered data; no firewall/gateway | no transit appliance |
| 06 | Network/Storage opt-in | storage, transactions, private endpoint | two-phase approval |
| 07 | Network only | flow-log storage | explicit opt-in, short retention |
| 08 | Network only | optional 2 VMs | price + quota |
| 09–10 | Static | none | no deploy |

Before any live stage, run the cost gate and capture current prices from the [Azure Retail Prices API](https://learn.microsoft.com/rest/api/cost-management/retail-prices/azure-retail-prices), current SKU/quota, provider status, offer/credit, spending limit, and budget availability. Prices and eligibility are discovered, not assumed.

Budgets alert; they do not stop resources. Cost data can lag. Expiration tags are inventory hints, not deletion. Deallocated VMs may retain billed disks and public IPs; idle private endpoints, storage, snapshots, logs, NAT, gateways, and analytics can bill. Destroy and verify.

References: [Free account FAQ](https://azure.microsoft.com/free/free-account-faq/), [free services](https://azure.microsoft.com/pricing/free-services/), [spending limit](https://learn.microsoft.com/azure/cost-management-billing/manage/spending-limit), [budgets](https://learn.microsoft.com/azure/cost-management-billing/costs/tutorial-acm-create-budgets), [VNet pricing](https://azure.microsoft.com/pricing/details/virtual-network/), and [Private Link pricing](https://azure.microsoft.com/pricing/details/private-link/).
