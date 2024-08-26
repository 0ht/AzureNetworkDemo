param privateDNSZoneName string
param tags object
param vnetName string
param vnetId string


resource DNSzone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: privateDNSZoneName
}

resource vnetlink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'vnetlink-${vnetName}'
  location: 'global'
  tags: tags
  parent: DNSzone
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}
