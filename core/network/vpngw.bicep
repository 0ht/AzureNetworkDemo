@description('The shared key used to establish connection between the two vNet Gateways.')
@secure()
param sharedKey string

@description('The SKU for the VPN Gateway. Cannot be Basic SKU.')
@allowed([
  'Standard'
  'HighPerformance'
  'VpnGw1'
  'VpnGw2'
  'VpnGw3'
  'VpnGw1Az'
  'VpnGw2Az'
  'VpnGw3Az'
])
param gatewaySku string = 'VpnGw1Az'

@description('Location of the resources')
param location string 
param hubVnetCfg object 
param onpremVnetCfg object
//param udrName string

resource hubVnet 'Microsoft.Network/virtualNetworks@2022-01-01' existing = {
  name: hubVnetCfg.name
}

/*
resource udr 'Microsoft.Network/routeTables@2023-05-01' existing = {
  name: udrName
}
*/

resource hubVnetGatewaySubnet 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' = {
  name: 'GatewaySubnet'
  parent: hubVnet
  properties: {
    addressPrefix: hubVnetCfg.gatewaySubnetPrefix
    //routeTable: ( udr.id != '' ) ? {
    //  id: udr.id
    //} : null
  }  
}

resource onpremVnet 'Microsoft.Network/virtualNetworks@2022-01-01' existing = {
  name: onpremVnetCfg.name
}

resource onpremVnetGatewaySubnet 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' = {
  name: 'GatewaySubnet'
  parent: onpremVnet
  properties: {
    addressPrefix: onpremVnetCfg.gatewaySubnetPrefix
  }  
}

resource gwHubpip 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: hubVnetCfg.gatewayPublicIPName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource gwOnprempip 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: onpremVnetCfg.gatewayPublicIPName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource hubVnetGateway 'Microsoft.Network/virtualNetworkGateways@2020-06-01' = {
  name: hubVnetCfg.gatewayName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'vnet1GatewayConfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: hubVnetGatewaySubnet.id
          }
          publicIPAddress: {
            id: gwHubpip.id
          }
        }
      }
    ]
    gatewayType: 'Vpn'
    sku: {
      name: gatewaySku
      tier: gatewaySku
    }
    vpnType: 'RouteBased'
    enableBgp: true
    bgpSettings: {
      asn: hubVnetCfg.asn
    }
  }
}

resource onpremVnetGateway 'Microsoft.Network/virtualNetworkGateways@2020-05-01' = {
  name: onpremVnetCfg.gatewayName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'vNet2GatewayConfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: onpremVnetGatewaySubnet.id
          }
          publicIPAddress: {
            id: gwOnprempip.id
          }
        }
      }
    ]
    gatewayType: 'Vpn'
    sku: {
      name: gatewaySku
      tier: gatewaySku
    }
    vpnType: 'RouteBased'
    enableBgp: true
    bgpSettings: {
      asn: onpremVnetCfg.asn
    }
  }
}

module vpnConnection './vpnconnection.bicep' = {
  name: 'vpnConnection-${location}'
  params: {
    sharedKey: sharedKey
    location1: location
    location2: location
    gw1Name: hubVnetCfg.gatewayName
    gw2Name: onpremVnetCfg.gatewayName
  }
  dependsOn: [
    hubVnetGateway
    onpremVnetGateway
  ]
}
