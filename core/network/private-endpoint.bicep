param privateDnsZoneName string
param location string
param tags object = {}
param vnetId string = ''
param vnetName string
param subnetId string = ''
param privateEndpointName string = ''
param privateLinkServiceId string =''
param privateLinkServicegroupId string =''

resource privateDnsZone'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: 'global'
  tags: tags

  resource vnetlink 'virtualNetworkLinks' = {
    name: 'vnetlink-${vnetName}'
    location: 'global'
    tags: tags
    properties: {
      virtualNetwork: { 
        id: vnetId 
      }
      registrationEnabled: false
    }
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-01-01' = {
  name: privateEndpointName
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: privateLinkServiceId
          groupIds: [
            privateLinkServicegroupId
          ]
        }
      }
    ]
  }
  resource privateEndpointDnsGroup 'privateDnsZoneGroups' = {
    name: '${privateDnsZoneName}-group'
    //name: 'default'
    properties: {
      privateDnsZoneConfigs: [
        {
          name: '${privateDnsZoneName}-config'
          properties: {
            privateDnsZoneId: privateDnsZone.id
          }
        }
      ]
    }
  }
}
