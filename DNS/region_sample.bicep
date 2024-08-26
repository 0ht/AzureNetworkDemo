targetScope = 'subscription'

param resourceGroupName string
param location string 
param tags object = {
  environment: 'dev'
}

// Organize resources in a resource group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// NSG rules 
param defaultNSG array = [
  {
    name: 'AllowWebInBound'
    properties: {
      description: 'AllowClientInBound'
      protocol: 'TCP'
      sourcePortRange: '*'
      destinationPortRanges: ['80','443']
      sourceAddressPrefix: '*'
      destinationAddressPrefix: 'VirtualNetwork'
      access: 'Allow'
      priority: 1000
      direction: 'Inbound'
    }
  }
  {
    name: 'AllowManagementInBound'
    properties: {
      description: 'AllowManagementInBound'
      protocol: 'TCP'
      sourcePortRange: '*'
      destinationPortRange: '22'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: 'VirtualNetwork'
      access: 'Allow'
      priority: 1001
      direction: 'Inbound'
    }
  }
]

// NSG 
module nsg 'core/network/nsg.bicep' = {
  scope: resourceGroup
  name: 'nsg-${location}'
  params: {
    nsgName: 'nsg-${location}'
    location: location
    tags: tags
    securityRules: defaultNSG
  }
}

// UDR to route traffic to Azure Firewall on spoke vnets
param udrOnSpokeName string = 'udrtoazfw-${location}'
param udrOnSpokeAddressPrefix array = ['0.0.0.0/0']
param udrOnSpokenextHopType string = 'VirtualAppliance'
param udrOnSpokedisableBgpRoutePropagation bool = true
param udrOnSpokehasBgpOverride bool = false

module udrOnSpoke 'core/network/udr.bicep' = {
  scope: resourceGroup
  name: udrOnSpokeName
  params: {
    udrName: udrOnSpokeName
    location: location
    routeCfg: [
      {
        name: udrOnSpokeName
        properties: {
          addressPrefix: udrOnSpokeAddressPrefix[0]
          nextHopType: udrOnSpokenextHopType
          nextHopIpAddress: firewall.outputs.firewallPrivateIp
          hasBgpOverride: udrOnSpokehasBgpOverride
        }
      }
    ]
    disableBgpRoutePropagation: udrOnSpokedisableBgpRoutePropagation
  }
  dependsOn: [
    firewall
  ]
}

// UDR to route traffic to Azure Firewall on VNet Gateway onHub
param udrOnGatewayName string = 'gwtoazfw-${location}'
param udrOnGatewayaddressPrefix array  = []
param udrOnGatewaynextHopType string = 'VirtualAppliance'
param udrOnGatewayhasBgpOverride bool = true
param udrOnGatewaydisableBgpRoutePropagation bool = true

module udrOnGateway 'core/network/udr.bicep' = {
  scope: resourceGroup
  name: udrOnGatewayName
  params: {
    udrName: udrOnGatewayName
    location: location
    routeCfg: [
      {
        name: 'route-to-Spoke-1'
        properties: {
          addressPrefix: udrOnGatewayaddressPrefix[0]
          nextHopType: udrOnGatewaynextHopType
          nextHopIpAddress: firewall.outputs.firewallPrivateIp
          hasBgpOverride: udrOnGatewayhasBgpOverride
        }
      }
      {
        name: 'route-to-Spoke-2'
        properties: {
          addressPrefix:  udrOnGatewayaddressPrefix[1]
          nextHopType: udrOnGatewaynextHopType
          nextHopIpAddress: firewall.outputs.firewallPrivateIp
          hasBgpOverride: udrOnGatewayhasBgpOverride
        }
      }
    ]
    disableBgpRoutePropagation: udrOnGatewaydisableBgpRoutePropagation
  }
  dependsOn: [
    firewall
  ]
}


// hub VNet
param hub1VnetName string = 'vnet-hub-1'
param hub1SubnetName string = 'subnet'
param hub1VnetAddressPrefix string = '10.0.0.0/16'
param hub1SubnetAddressPrefix string = '10.0.1.0/24'
param bastionSubnetAddressPrefix string = '10.0.2.0/24'
param azfwSubnetAddressPrefix string = '10.0.3.0/24'

module hub1Vnet 'core/network/vnet.bicep' = {
  scope: resourceGroup
  name: hub1VnetName
  params: {
    vnetName: hub1VnetName
    location: location
    tags: tags
    vnetAddressPrefix: hub1VnetAddressPrefix
    defaultSubnetName: hub1SubnetName
    subnetAddressPrefix: hub1SubnetAddressPrefix
    nsgId: nsg.outputs.nsgId
  }
  dependsOn: [
    nsg
  ]
}

// Bastion on hub1
param bastionName string = ''
param bastionsku string = 'Standard'

module bastion 'core/network/bastion.bicep' = {
  scope: resourceGroup
  name: 'bastion-${location}'
  params: {
    location: location
    bastionName: bastionName
    sku: bastionsku
    vnet: hub1Vnet.name
    hub1BastionSubnetAddressPrefix: bastionSubnetAddressPrefix
  }
  dependsOn: [
    hub1Vnet
    firewall
  ]
}

// Azure Firewall on hub1
param firewallName string
param useExisting bool = false

module firewall 'core/network/firewall.bicep' = {
  scope: resourceGroup
  name: 'firewall-${location}'
  params: {
    location: location
    firewallName: firewallName
    firewallVNetName: hub1VnetName
    useExisting: useExisting
    azfwSubnetAddressPrefix: azfwSubnetAddressPrefix
  }
  dependsOn: [
    hub1Vnet
  ]
}

// Spoke1 VNet
param spoke1VnetName string = 'vnet-spoke-1'
param spoke1SubnetName string = 'subnet'
param spoke1VnetAddressPrefix string = '10.10.0.0/16'
param spoke1SubnetAddressPrefix string = '10.10.1.0/24'

module spoke1Vnet 'core/network/vnet.bicep' = {
  scope: resourceGroup
  name: spoke1VnetName
  params: {
    vnetName: spoke1VnetName
    location: location
    tags: tags
    vnetAddressPrefix: spoke1VnetAddressPrefix
    defaultSubnetName: spoke1SubnetName
    subnetAddressPrefix: spoke1SubnetAddressPrefix
    nsgId: nsg.outputs.nsgId
    udrId: udrOnSpoke.outputs.udrId
  }
  dependsOn: [
    nsg
    udrOnSpoke
  ]
}

// Spoke2 VNet
param spoke2VnetName string = 'vnet-spoke-2'
param spoke2SubnetName string = 'subnet'
param spoke2VnetAddressPrefix string = '10.20.0.0/16'
param spoke2SubnetAddressPrefix string = '10.20.1.0/24'

module spoke2Vnet 'core/network/vnet.bicep' = {
  scope: resourceGroup
  name: spoke2VnetName
  params: {
    vnetName: spoke2VnetName
    location: location
    tags: tags
    vnetAddressPrefix: spoke2VnetAddressPrefix
    defaultSubnetName: spoke2SubnetName
    subnetAddressPrefix: spoke2SubnetAddressPrefix
    nsgId: nsg.outputs.nsgId
    udrId: udrOnSpoke.outputs.udrId
  }
  dependsOn: [
    nsg
    udrOnSpoke
  ]
}

// virtual On-premise network
param onpremVnetName string = 'vnet-onprem'
param onpremSubnetName string = 'subnet'
param onpremVnetAddressPrefix string = '10.30.0.0/16'
param onpremSubnetAddressPrefix string = '10.30.1.0/24'
@secure()
param  sharedKey string = 'azureSecureKey1234'

module onpremVnet 'core/network/vnet.bicep' = {
  scope: resourceGroup
  name: onpremVnetName
  params: {
    vnetName: onpremVnetName
    location: location
    tags: tags
    vnetAddressPrefix: onpremVnetAddressPrefix
    defaultSubnetName: onpremSubnetName
    subnetAddressPrefix: onpremSubnetAddressPrefix
    nsgId: nsg.outputs.nsgId
  }
  dependsOn: [
    nsg
  ]
}

// VNet Peerings between hub and spokes
module vnetPeerings1 'core/network/vnetpeerings.bicep' = {
  scope: resourceGroup
  name: 'vnetPeerings1'
  params: {
    peeringtype: 'hub-spoke' 
    vnet1Name: hub1VnetName
    vnet2Name: spoke1VnetName
  }
  dependsOn: [
    hub1Vnet
    spoke1Vnet
    VPNGateway
  ]
}

module vnetPeerings2 'core/network/vnetpeerings.bicep' = {
  scope: resourceGroup
  name: 'vnetPeerings2'
  params: {
    peeringtype: 'hub-spoke' 
    vnet1Name: hub1VnetName
    vnet2Name: spoke2VnetName
  }
  dependsOn: [
    hub1Vnet
    spoke2Vnet
    VPNGateway
  ]
}

// Hub-onprem Gateway
param hubVnetCfg object = {
  name: hub1VnetName
  gatewayName: 'vpngw-hub1'
  gatewaySubnetPrefix: '10.0.1.224/27'
  gatewayPublicIPName: 'pip-hubvpngw'
  connectionName: 'vNet1-to-vNet2'
  asn: 65010
}

param onpremVnetCfg object = {
  name: onpremVnetName
  gatewayName: 'vpngw-onprem1'
  gatewaySubnetPrefix: '10.30.1.224/27'
  gatewayPublicIPName: 'pip-onpremvpngw'
  connectionName: 'vNet2-to-vNet1'
  asn: 65011
}

module VPNGateway 'core/network/vpngw.bicep' = {
  scope: resourceGroup
  name: 'VPNGateway'
  params: {
    location: location
    sharedKey: sharedKey
    gatewaySku: 'VpnGw1'
    hubVnetCfg: hubVnetCfg
    onpremVnetCfg: onpremVnetCfg
    udrName: udrOnGatewayName
  }
  dependsOn: [
    hub1Vnet
    onpremVnet
    firewall
    bastion
  ]
}

// Parameters for the Virtual Machine on hub1
param vmHub1Name string = 'vm-hub-1'
param vmSize string = 'Standard_B1s'
param adminUsername string = 'azureuser'
@secure()
param adminPasswordOrKey string = 'P@ssw0rd1234'
param authenticationType string = 'password'
param securityType string = 'nsg'

module vmHub1 'core/vm/vm-simple-linux.bicep' = {
  scope: resourceGroup
  name: vmHub1Name
  params: {
    vmName: vmHub1Name
    location: location
    tags: tags
    vmSize: vmSize
    adminUsername: adminUsername
    adminPasswordOrKey: adminPasswordOrKey
    authenticationType: authenticationType
    securityType: securityType
    subnetId: hub1Vnet.outputs.subnetId
  }
}

// Parameters for the Virtual Machine on spoke1
param vmSpoke1Name string = 'vm-spoke-1'

module vmSpoke1 'core/vm/vm-simple-linux.bicep' = {
  scope: resourceGroup
  name: vmSpoke1Name
  params: {
    vmName: vmSpoke1Name
    location: location
    tags: tags
    vmSize: vmSize
    adminUsername: adminUsername
    adminPasswordOrKey: adminPasswordOrKey
    authenticationType: authenticationType
    securityType: securityType
    subnetId: spoke1Vnet.outputs.subnetId
  }
}

// Parameters for the Virtual Machine on spoke2
param vmSpoke2Name string = 'vm-spoke-2'

module vmSpoke2 'core/vm/vm-simple-linux.bicep' = {
  scope: resourceGroup
  name: vmSpoke2Name
  params: {
    vmName: vmSpoke2Name
    location: location
    tags: tags
    vmSize: vmSize
    adminUsername: adminUsername
    adminPasswordOrKey: adminPasswordOrKey
    authenticationType: authenticationType
    securityType: securityType
    subnetId: spoke2Vnet.outputs.subnetId
  }
}

// Parameters for the Virtual Machine on onprem
param vmOnpremName string = 'vm-onprem'

module vmOnprem 'core/vm/vm-simple-linux.bicep' = {
  scope: resourceGroup
  name: vmOnpremName
  params: {
    vmName: vmOnpremName
    location: location
    tags: tags
    vmSize: vmSize
    adminUsername: adminUsername
    adminPasswordOrKey: adminPasswordOrKey
    authenticationType: authenticationType
    securityType: securityType
    subnetId: onpremVnet.outputs.subnetId
  }
}

output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_RESOURCE_GROUP string = resourceGroup.name
output firewwallIpAddress string = firewall.outputs.firewallPrivateIp

