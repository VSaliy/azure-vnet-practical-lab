# Troubleshooting reference

Investigate in order: intended topology → resource state → DNS → listener → NSG → route → peering/service policy → application.

```powershell
az network nic show-effective-nsg --resource-group <rg> --name <nic>
az network nic show-effective-route-table --resource-group <rg> --name <nic>
az network watcher test-ip-flow --direction Outbound --protocol TCP --local <src-ip>:50000 --remote <dst-ip>:8080 --vm <vm-id> --resource-group <watcher-rg>
az network watcher test-connectivity --source-resource <vm-id> --dest-address <ip> --dest-port 8080
az network vnet peering show --resource-group <rg> --vnet-name <vnet> --name <peering>
az network private-endpoint dns-zone-group list --resource-group <rg> --endpoint-name <pe>
```

A timeout is not automatically NSG evidence. First prove the target listener locally (`ss -lnt`) and from an allowed source. NSGs are stateful: established return traffic is allowed, and changing a rule may not terminate an existing flow. Use a new connection for every test.

For failed destroy, inventory the resource group, dependency NICs/disks/private endpoints, flow logs, and external diagnostic artifacts before touching state. Never delete shared `NetworkWatcherRG` wholesale.
