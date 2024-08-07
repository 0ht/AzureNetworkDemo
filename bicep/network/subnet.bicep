param vnetName string
param subnetName string
param subnetAddressPrefix string = ''
param nsgId string = ''
param udrId string = ''
param natgwId string = ''
param serviceEndpoints array = []
param delegations array =[]
param privateEndpointNetworkPolicies string = ''
param privateLinkServiceNetworkPolicies string = ''
param serviceEndpointPolicies array = []

resource vnet 'Microsoft.Network/virtualNetworks@2024-01-01' existing =  {
  name: vnetName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2024-01-01' = {
  name: subnetName
  parent: vnet
  properties: {
    addressPrefix: subnetAddressPrefix
    networkSecurityGroup: !empty(nsgId) ? { id: nsgId} : null
    routeTable: !empty(udrId) ? { id: udrId} : null
    natGateway: !empty(natgwId) ? { id: natgwId} : null
    delegations:  !empty(delegations) ? (delegations) : null
    serviceEndpoints: !empty(serviceEndpoints) ? (serviceEndpoints) : null
    serviceEndpointPolicies: !empty(serviceEndpointPolicies) ? (serviceEndpointPolicies) : null
    privateEndpointNetworkPolicies: !empty(privateEndpointNetworkPolicies) ? any(privateEndpointNetworkPolicies) : null
    privateLinkServiceNetworkPolicies: !empty(privateLinkServiceNetworkPolicies) ? any(privateLinkServiceNetworkPolicies) : null
  }
}

output subnetName string = subnet.name
output subnetId string = subnet.id
