param location string 
param tags object = {}

param vnetName string
param vnetAddressPrefix string = ''
param dnsServers array = []

resource vnet 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: vnetName// On-premises subnet - VM// On-premises subnet - VM
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    dhcpOptions: {
      dnsServers: !empty(dnsServers) ? ( dnsServers ) : null        
    }    
  }
}

output vnet object = vnet
output vnetId string = vnet.id
output vnetName string = vnet.name
