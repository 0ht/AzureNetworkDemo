param privateDNSZoneName string = 'string'
param tags object = {}

resource symbolicname 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDNSZoneName
  location: 'global'
  tags: tags
  properties: {}
}
