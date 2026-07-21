targetScope = 'resourceGroup'

@allowed([
  'westeurope'
  'northeurope'
])
param location string = resourceGroup().location
param owner string
@description('Next UTC calendar date, supplied after preflight.')
param expiresOn string

var tags = {
  environment: 'lab'
  owner: owner
  'expires-on': expiresOn
  'managed-by': 'terraform'
  'lab-stage': '01'
}

resource managementNsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'vnetlab-01-management-nsg-bicep'
  location: location
  tags: tags
}

resource applicationNsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'vnetlab-01-application-nsg-bicep'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'allow-management-ssh'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '10.20.0.0/24'
          destinationAddressPrefix: '10.20.1.0/24'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'vnetlab-01-vnet-bicep'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.20.0.0/20'
      ]
    }
    subnets: [
      {
        name: 'management'
        properties: {
          addressPrefix: '10.20.0.0/24'
          defaultOutboundAccess: false
          networkSecurityGroup: {
            id: managementNsg.id
          }
        }
      }
      {
        name: 'application'
        properties: {
          addressPrefix: '10.20.1.0/24'
          defaultOutboundAccess: false
          networkSecurityGroup: {
            id: applicationNsg.id
          }
        }
      }
    ]
  }
}

output vnetId string = vnet.id
