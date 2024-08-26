param location string
param dnsresolverName string
param inboundEndpointName string
param outboundEndpointName string
param vnetName string
param inboundsubnetName string
param outboundsubnetName string


resource vnet 'Microsoft.Network/virtualNetworks@2024-01-01' existing = {
  name: vnetName
  resource inboundSubnet 'subnets@2024-01-01' existing =  {
    name: inboundsubnetName
  }
  resource outboundSubnet 'subnets@2024-01-01' existing =  {
    name: outboundsubnetName
  }
}

resource dnsresolver 'Microsoft.Network/dnsResolvers@2022-07-01' = {
  name: dnsresolverName
  location: location
  properties: {
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource inboundEndpoint 'Microsoft.Network/dnsResolvers/inboundEndpoints@2022-07-01' = {
  name: inboundEndpointName
  location: location
  parent: dnsresolver
  properties: {
    ipConfigurations: [
      {
        subnet: {
          id: vnet::inboundSubnet.id
        }
      }
    ]
  }
}

resource outboundEndpoint 'Microsoft.Network/dnsResolvers/outboundEndpoints@2022-07-01' = {
  name: outboundEndpointName
  location: location
  parent: dnsresolver
  properties: {
    subnet: {
      id: vnet::outboundSubnet.id
    }
  }
}

output dnsresolverId string = dnsresolver.id
output inboundEndpointId string = inboundEndpoint.id
output inboundEndpointAddress string = inboundEndpoint.properties.ipConfigurations[0].privateIpAddress
output outboundEndpointId string = outboundEndpoint.id
