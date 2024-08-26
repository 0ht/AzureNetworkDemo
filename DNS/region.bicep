param location string
param tags object = {}

targetScope = 'resourceGroup'

// 疑似オンプレ環境
// On-premises Vnet
param onprem_vnetName string 
param onprem_vnetAddressPrefix string
param onprem_defaulsubnetName string 
param onprem_subnetAddressPrefix string 

module vnetOnprem '../core/network/vnet.bicep' = {
  name: '${onprem_vnetName}-Deployment'
  params: {
    location: location
    vnetName: onprem_vnetName
    vnetAddressPrefix: onprem_vnetAddressPrefix
  }
}

// onprem subnet - default
module OnpremDefaultSubnet '../core/network/subnet.bicep' = {
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
param hub_vnetName string 
param hub_vnetAddressPrefix string 
param hub_defaultSubnetName string 
param hub_defaultSubnetPrefix string 
param hub_privateEndpointSubnetName string
param hub_privateEndpointSubentPrefix string 
param hub_inboundDNSSubnetName string 
param hub_inboundDNSSubnetPrefix string 
param hub_outboundDNSSubnetName string
param hub_outboundDNSSubnetPrefix string

// hub仮想ネットワークの定義
module vnethub '../core/network/vnet.bicep' = {
  name: '${hub_vnetName}Deployment'
  params: {
    location: location
    vnetName: hub_vnetName
    vnetAddressPrefix: hub_vnetAddressPrefix 
  }
}

// Subnetの定義
module hubDefaultSubnet '../core/network/subnet.bicep' = {
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

module hubPrivateEndpointSubnet '../core/network/subnet.bicep' = {
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

module hubinboundDNSSubnet '../core/network/subnet.bicep' = {
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

module huboutboundDNSSubnet '../core/network/subnet.bicep' = {
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

param dnsresolverName string 
param inboundEndpointName string
param outboundEndpointName string

// hub private dns resolver
module dnsResolver '../core/DNS/dnsresolver.bicep' = {
  name: '${dnsresolverName}-Deployment'
  params: {
    location: location
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

param dnsFwdRulesetName string 

// hub dns Forwarding Ruleset
module dnsForwardingRuleset '../core/DNS/dnsforwardingruleset.bicep' = {
  name: '${dnsFwdRulesetName}Deployment'
  params: {
    location: location
    dnsFwdRulesetName: dnsFwdRulesetName
    //outboundEndpointName: 'outboundep'
    outboundEndpointId: dnsResolver.outputs.outboundEndpointId
    linkedvnetName: hub_vnetName
  }
  dependsOn: [
    dnsResolver
  ]
}


// Spoke 
param spoke_vnetName string 
param spoke_vnetAddressPrefix string 
param spoke_defaultSubnetName string 
param spoke_defaultSubnetPrefix string
param spoke_privateEndpointSubnetName string 
param spoke_privateEndpointSubnetPrefix string 

module vnetSpoke '../core/network/vnet.bicep' = {
  name: '${spoke_vnetName}-Deployment'
  params: {
    location: location
    vnetName: spoke_vnetName
    vnetAddressPrefix: spoke_vnetAddressPrefix 
    dnsServers: [dnsResolver.outputs.inboundEndpointAddress]
  }
}

// Subnetの定義
module spokeDefaultSubnet '../core/network/subnet.bicep' = {
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

module spokePrivateEndpointSubnet '../core/network/subnet.bicep' = {
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


// VNet Peerings between hub and spoke
module vnetPeerings1 '../core/network/vnetpeerings.bicep' = {
  name: 'vnetPeerings-${location}'
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
param  sharedKey string 
param hubVnetCfg object = {}
param onpremVnetCfg object = {}

module VPNGateway '../core/network/vpngw.bicep' = {
  name: 'VPNGateway-${location}'
  params: {
    location: location
    sharedKey: sharedKey
    gatewaySku: 'VpnGw1Az'
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
