@description('The shared key used to establish connection between the two vNet Gateways.')
@secure()
param sharedKey string

@description('Location of the resources')
param location1 string 
param location2 string
param gw1Name string
param gw2Name string

resource gw1 'Microsoft.Network/virtualNetworkGateways@2020-06-01' existing = {
  name: gw1Name
}

resource gw2 'Microsoft.Network/virtualNetworkGateways@2020-06-01' existing = {
  name: gw2Name
}

resource vpn1to2Connection 'Microsoft.Network/connections@2020-05-01' = {
  name: '${gw1Name}-${gw2Name}'
  location: location1
  properties: {
    virtualNetworkGateway1: {
      location: location1
      id: gw1.id
      properties: {}
    }
    virtualNetworkGateway2: {
      location: location2
      id: gw2.id
      properties: {}
    }
    connectionType: 'Vnet2Vnet'
    routingWeight: 3
    sharedKey: sharedKey
    enableBgp: true
  }
}

resource vpn2to1Connection 'Microsoft.Network/connections@2020-05-01' = {
  name: '${gw2Name}-${gw1Name}'
  location: location2
  properties: {
    virtualNetworkGateway1: {
      location: location2
      id: gw2.id
      properties: {}
    }
    virtualNetworkGateway2: {
      location: location1
      id: gw1.id
      properties: {}
    }
    connectionType: 'Vnet2Vnet'
    routingWeight: 3
    sharedKey: sharedKey
    enableBgp: true
  }
}
