
@allowed(['vnet-vnet', 'hub-spoke'])
param peeringtype string 
param vnet1Name string
param vnet2Name string

resource vnet1 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: vnet1Name
}
resource vnet2 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: vnet2Name
}


resource vnetPeering1to2 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-05-01' = {
  parent: vnet1
  name: '${vnet1Name}-${vnet2Name}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: (peeringtype == 'hub-spoke') ? true : false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vnet2.id
    }
  }
}

resource vnetPeeringSpoketoHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-05-01' = {
  parent: vnet2
  name: '${vnet2Name}-${vnet1Name}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: (peeringtype == 'hub-spoke') ? true : false
    remoteVirtualNetwork: {
      id: vnet1.id
    }
  }
}

