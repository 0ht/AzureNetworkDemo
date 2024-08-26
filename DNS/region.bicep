param resource_group_name string = 'rg-dns-test-2'
param location string = 'japaneast'
param tags object = {}

targetScope = 'subscription'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: resource_group_name
  location: location
}

// 疑似オンプレ環境
// On-premises Vnet
param onprem_vnetName string = 'vnet-onprem-${location}'
param onprem_vnetAddressPrefix string = '10.100.0.0/16'
param onprem_defaulsubnetName string = 'default'
param onprem_subnetAddressPrefix string = '10.100.0.0/24'

module vnetOnprem 'core/network/vnet.bicep' = {
  scope: resourceGroup
  name: '${onprem_vnetName}-Deployment'
  params: {
    vnetName: onprem_vnetName
    vnetAddressPrefix: onprem_vnetAddressPrefix
  }
}

// onprem subnet - default
module OnpremDefaultSubnet 'core/network/subnet.bicep' = {
  scope: resourceGroup
  name: '${onprem_vnetName}-${onprem_defaulsubnetName}-Deployment'
  params: {
    vnetName: onprem_vnetName
    subnetName: onprem_defaulsubnetName
    subnetAddressPrefix: onprem_subnetAddressPrefix
  }
  dependsOn: [
    vnetOnprem
  ]
}


//hub
//hub vnet
param hub_vnetName string = 'vnet-hub-${location}'
param hub_vnetAddressPrefix string = '10.110.0.0/16'
param hub_defaultSubnetName string = 'default'
param hub_defaultSubnetPrefix string = '10.110.0.0/24'
param hub_privateEndpointSubnetName string = 'privateEndpointSubnet'
param hub_privateEndpointSubentPrefix string = '10.110.10.0/24'
param hub_inboundDNSSubnetName string = 'inboundDNSSubnet'
param hub_inboundDNSSubnetPrefix string = '10.110.20.0/24'
param hub_outboundDNSSubnetName string = 'outboundDNSSubnet'
param hub_outboundDNSSubnetPrefix string = '10.110.30.0/24'

// hub仮想ネットワークの定義
module vnethub 'core/network/vnet.bicep' = {
  scope: resourceGroup
  name: '${hub_vnetName}Deployment'
  params: {
    vnetName: hub_vnetName
    vnetAddressPrefix: hub_vnetAddressPrefix 
  }
}

// Subnetの定義
module hubDefaultSubnet 'core/network/subnet.bicep' = {
  scope: resourceGroup
  name: '${hub_vnetName}-${hub_defaultSubnetName}-Deployment'
  params: {
    vnetName: hub_vnetName
    subnetName: hub_defaultSubnetName
    subnetAddressPrefix: hub_defaultSubnetPrefix
  }
  dependsOn: [
    vnethub
  ]
}

module hubPrivateEndpointSubnet 'core/network/subnet.bicep' = {
  scope: resourceGroup
  name: '${hub_vnetName}-${hub_privateEndpointSubnetName}-Deployment'
  params: {
    vnetName: hub_vnetName
    subnetName: hub_privateEndpointSubnetName
    subnetAddressPrefix: hub_privateEndpointSubentPrefix
  }
  dependsOn: [
      hubDefaultSubnet
    ]
}

module hubinboundDNSSubnet 'core/network/subnet.bicep' = {
  scope: resourceGroup
  name: '${hub_vnetName}-${hub_inboundDNSSubnetName}-Deployment'
  params: {
    vnetName: hub_vnetName
    subnetName: hub_inboundDNSSubnetName
    subnetAddressPrefix: hub_inboundDNSSubnetPrefix
    delegations: [
      {
        name: 'Microsoft.Network.dnsResolvers'
        properties: {
          serviceName: 'Microsoft.Network/dnsResolvers'
        }
      }
    ]
  }
  dependsOn: [
    hubPrivateEndpointSubnet
  ]
}

module huboutboundDNSSubnet 'core/network/subnet.bicep' = {
  scope: resourceGroup
  name: '${hub_vnetName}-${hub_outboundDNSSubnetName}-Deployment'
  params: {
    vnetName: hub_vnetName
    subnetName: hub_outboundDNSSubnetName
    subnetAddressPrefix: hub_outboundDNSSubnetPrefix
    delegations: [
      {
        name: 'Microsoft.Network.dnsResolvers'
        properties: {
          serviceName: 'Microsoft.Network/dnsResolvers'
        }
      }
    ]
  }
  dependsOn: [
    hubinboundDNSSubnet
  ]
}



// Spoke 
param spoke_vnetName string = 'vnet-spoke-${location}'
param spoke_vnetAddressPrefix string = '10.120.0.0/16'
param spoke_defaultSubnetName string = 'default'
param spoke_defaultSubnetPrefix string = '10.120.0.0/24'
param spoke_privateEndpointSubnetName string = 'privateEndpointSubnet'
param spoke_privateEndpointSubnetPrefix string = '10.120.10.0/24'

module vnetSpoke 'core/network/vnet.bicep' = {
  scope: resourceGroup
  name: '${spoke_vnetName}-Deployment'
  params: {
    vnetName: spoke_vnetName
    vnetAddressPrefix: spoke_vnetAddressPrefix 
  }
}

// Subnetの定義
module spokeDefaultSubnet 'core/network/subnet.bicep' = {
  scope: resourceGroup
  name: '${spoke_vnetName}-${spoke_defaultSubnetName}-Deployment'
  params: {
    vnetName: spoke_vnetName
    subnetName: spoke_defaultSubnetName
    subnetAddressPrefix: spoke_defaultSubnetPrefix
  }
  dependsOn: [
    vnetSpoke
  ]
}

module spokePrivateEndpointSubnet 'core/network/subnet.bicep' = {
  scope: resourceGroup
  name: '${spoke_vnetName}-${spoke_privateEndpointSubnetName}-Deployment'
  params: {
    vnetName: spoke_vnetName
    subnetName: spoke_privateEndpointSubnetName
    subnetAddressPrefix: spoke_privateEndpointSubnetPrefix
  }
  dependsOn: [
    spokeDefaultSubnet
  ]
}

param dnsresolverName string = 'dnsResolver-${location}'
param inboundEndpointName string = 'inboundep'
param outboundEndpointName string = 'outboundep'

// hub private dns resolver
module dnsResolver 'core/DNS/dnsresolver.bicep' = {
  scope: resourceGroup
  name: '${dnsresolverName}-Deployment'
  params: {
    dnsresolverName: dnsresolverName
    inboundEndpointName: inboundEndpointName
    outboundEndpointName: outboundEndpointName
    vnetName: hub_vnetName
    inboundsubnetName: hub_inboundDNSSubnetName
    outboundsubnetName: hub_outboundDNSSubnetName
  }
  dependsOn: [
    hubinboundDNSSubnet
    huboutboundDNSSubnet
  ]
}

param dnsFwdRulesetName string = 'dnsFwdRuleset-${location}'

// hub dns Forwarding Ruleset
module dnsForwardingRuleset 'core/DNS/dnsforwardingruleset.bicep' = {
  scope: resourceGroup
  name: '${dnsFwdRulesetName}Deployment'
  params: {
    dnsFwdRulesetName: dnsFwdRulesetName
    //outboundEndpointName: 'outboundep'
    outboundEndpointId: dnsResolver.outputs.outboundEndpointId
    linkedvnetName: hub_vnetName
  }
  dependsOn: [
    dnsResolver
  ]
}

// VNet Peerings between hub and spokes
module vnetPeerings1 'core/network/vnetpeerings.bicep' = {
  scope: resourceGroup
  name: 'vnetPeerings1'
  params: {
    peeringtype: 'hub-spoke' 
    vnet1Name: hub_vnetName
    vnet2Name: spoke_vnetName
  }
  dependsOn: [
    vnethub
    vnetSpoke
    VPNGateway
  ]
}

// Hub-onprem Gateway
@secure()
param  sharedKey string = 'azureSecureKey1234'

param hubVnetCfg object = {
  name: hub_vnetName
  gatewayName: 'vpngw-hub1'
  gatewaySubnetPrefix: '10.110.1.224/27'
  gatewayPublicIPName: 'pip-hubvpngw'
  connectionName: 'vNet1-to-vNet2'
  asn: 65010
}

param onpremVnetCfg object = {
  name: onprem_vnetName
  gatewayName: 'vpngw-onprem1'
  gatewaySubnetPrefix: '10.100.1.224/27'
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
  }
  dependsOn: [
    huboutboundDNSSubnet
    spokePrivateEndpointSubnet
  ]
}


output hub_vnetId string = vnethub.outputs.vnetId
output onprem_vnetId string = vnetOnprem.outputs.vnetId
output spoke_vnetId string = vnetSpoke.outputs.vnetId
