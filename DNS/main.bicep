param resource_group_name string = 'rg-dns-test'
param location string = 'japaneast'
param tags object = {}

targetScope = 'subscription'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: resource_group_name
  location: location
}

// 疑似オンプレ環境
// On-premises Vnet

param onprem_vnetName string = 'vnet-onprem'
param onprem_vnetAddressPrefix string = '10.100.0.0/16'
param onprem_defaulsubnetName string = 'default'
param onprem_subnetAddressPrefix string = '10.100.0.0/24'

module vnetOnprem '../bicep/network/vnet.bicep' = {
  scope: resourceGroup
  name: '${onprem_vnetName}Deployment'
  params: {
    vnetName: onprem_vnetName
    vnetAddressPrefix: onprem_vnetAddressPrefix
  }
}

// onprem subnet - default
module OnpremDefaultSubnet '../bicep/network/subnet.bicep' = {
  scope: resourceGroup
  name: '${onprem_defaulsubnetName}Dployment'
  params: {
    vnetName: onprem_vnetName
    subnetName: onprem_defaulsubnetName
    subnetAddressPrefix: onprem_subnetAddressPrefix
  }
}


param hub_vnetName string = 'vnet-hub-japaneast'
param hub_vnetAddressPrefix string = '
param hub_subnetName string = 'defparam   

param hubVnetName string = 'vnet-hub-japaneast'
param hubVnetAddressPrefix string = '
param hubSubnetName string = 'default'
param subnetName string = 'default'
param BastionSubnetAddressPrefix string = '





// hub仮想ネットワークの定義

module vnethub '../bicep/network/vnet.bicep' = {
  scope: resourceGroup
  name: 'vnetHubDeployment_${location}'
  params: {
    vnetName: 'vnet-hub-${location}'
    vnetAddressPrefix: '10.110.0.0/16'
  }
}

// Subnetの定義
module HubDefaultSubnet '../bicep/network/subnet.bicep' = {
  scope: resourceGroup
  name: 'HubDefaultSubnetDEployment'
  params: {
    vnetName: vnethub.outputs.vnetName
    subnetName: 'default'
    subnetAddressPrefix: '10.110.10.0/24'
  }
  dependsOn: [
    vnethub
  ]
}

module HubPrivateEndpointSubnet '../bicep/network/subnet.bicep' = {
  scope: resourceGroup
  name: 'HubPeSubnetDeployment'
  params: {
    vnetName: vnethub.outputs.vnetName
    subnetName: 'peSubnet'
    subnetAddressPrefix: '10.110.20.0/24'
  }
  dependsOn: [
      HubDefaultSubnet
    ]
}

module HubinboundDNSSubnet '../bicep/network/subnet.bicep' = {
  scope: resourceGroup
  name: 'inboundDNSSubnetDeployment'
  params: {
    vnetName: vnethub.outputs.vnetName
    subnetName: 'inboundDNSSubnet'
    subnetAddressPrefix: '10.110.30.0/24'
  }
  dependsOn: [
    HubPrivateEndpointSubnet
  ]
}

module HuboutboundDNSSubnet '../bicep/network/subnet.bicep' = {
  scope: resourceGroup
  name: 'outboundDNSSubnetDeployment'
  params: {
    vnetName: vnethub.outputs.vnetName
    subnetName: 'outboundDNSSubnet'
    subnetAddressPrefix: '10.110.40.0/24'
  }
  dependsOn: [
    HubinboundDNSSubnet
  ]
}

// Hub Bastion
module AzureBastionSubnet '../bicep/network/bastion.bicep' = {
  scope: resourceGroup
  name: 'bastionSubnetDeployment_${location}'
  params: {
    bastionName: 'bastion'
    sku: 'Standard'
    vnetName: vnethub.outputs.vnetName
    BastionSubnetAddressPrefix: '10.110.50.0/24'
  }
  dependsOn: [
    HuboutboundDNSSubnet
  ]
}


// hub private dns resolver
module dnsResolver '../bicep/network/dnsresolver.bicep' = {
  scope: resourceGroup
  name: 'dnsResolverDeployment'
  params: {
    dnsresolverName: 'dnsResolver'
    inboundEndpointName: 'inboundep'
    outboundEndpointName: 'outboundep'
    vnetName: vnethub.outputs.vnetName
    inboundsubnetName: 'inboundDNSSubnet'
    outboundsubnetName: 'outboundDNSSubnet'
  }
  dependsOn: [
    HubinboundDNSSubnet
    HuboutboundDNSSubnet
  ]
}

// hub dns Forwarding Ruleset
module dnsForwardingRuleset '../bicep/network/dnsforwardingruleset.bicep' = {
  scope: resourceGroup
  name: 'dnsForwardingRulesetDeployment'
  params: {
    dnsFwdRulesetName: 'dnsFwdRuleset'
    //outboundEndpointName: 'outboundep'
    outboundEndpointId: dnsResolver.outputs.outboundEndpointId
  }
  dependsOn: [
    dnsResolver
  ]
}

// hub dns forwarding rule
module dnsForwardingRule '../bicep/network/dnsforwardingrule.bicep' = {
  scope: resourceGroup
  name: 'dnsForwardingRuleDeployment'
  params: {
    dnsFwdRulesetName: dnsForwardingRuleset.outputs.dnsFwdRulesetName
    dnsFwdRuleName: 'fwd-test'
    domainName: 'test.com'
    dnsIpAddress: 
    dnsPort: '53'
  }
}

// hub dns Vnet Link



// Spoke 
module vnetspoke '../bicep/network/vnet.bicep' = {
  scope: resourceGroup
  name: 'vnetSpokeDeployment_${location}'
  params: {
    vnetName: 'vnet-spoke_${location}'
    vnetAddressPrefix: '10.120.0.0/16'
  }
}
module spokePrivateEndpointSubnet '../bicep/network/subnet.bicep' = {
  scope: resourceGroup
  name: 'spokePeSubnetDeployment_${location}'
  params: {
    vnetName: vnetspoke.outputs.vnetName
    subnetName: 'peSubnet'
    subnetAddressPrefix: '10.120.20.0/24'
  }
  dependsOn: [
      HubDefaultSubnet
    ]
}


// common
// common vnet
module vnetcommon '../bicep/network/vnet.bicep' = {
  scope: resourceGroup
  name: 'vnetCommonDeployment'
  params: {
    vnetName: 'vnet-common'
    vnetAddressPrefix: '10.120.0.0/16'
  }
}

// common subnet - default
module CommonDefaultSubnet '../bicep/network/subnet.bicep' = {
  scope: resourceGroup
  name: 'commonDefaultSubnetDployment'
  params: {
    vnetName: vnetcommon.outputs.vnetName
    subnetName: 'default'
    subnetAddressPrefix: '10.120.10.0/24'
  }
}

// common subnet - private endpoint
module PrivateEndpointSubnet '../bicep/network/subnet.bicep' = {
  scope: resourceGroup
  name: 'peSubnetDeployment'
  params: {
    vnetName: vnetcommon.outputs.vnetName
    subnetName: 'peSubnet'
    subnetAddressPrefix: '10.120.20.0/24'
  }
}

// common VM






// On-premises VM 
