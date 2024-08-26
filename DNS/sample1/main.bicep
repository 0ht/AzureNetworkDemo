param resource_group_name string = 'rg-dns'
param location1 string = 'japaneast'
param location2 string = 'southeastasia'
param tags object = {}

targetScope = 'subscription'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: resource_group_name
  location: location1
}

// 各リージョンネットワークをデプロイ
// 東日本リージョン
module region1 './region.bicep' = {
  scope: resourceGroup
  name: '${location1}-Deployment'
  params: {
    location: location1
    onprem_vnetName: 'vnet-onprem-${location1}'
    onprem_vnetAddressPrefix: '10.100.0.0/16'
    onprem_defaulsubnetName: 'default'
    onprem_subnetAddressPrefix: '10.100.0.0/24'
    hub_vnetName: 'vnet-hub-${location1}'
    hub_vnetAddressPrefix: '10.110.0.0/16'
    hub_defaultSubnetName: 'default'
    hub_defaultSubnetPrefix: '10.110.0.0/24'
    hub_privateEndpointSubnetName: 'privateEndpointSubnet'
    hub_privateEndpointSubentPrefix: '10.110.10.0/24'
    hub_inboundDNSSubnetName: 'inboundDNSSubnet'
    hub_inboundDNSSubnetPrefix: '10.110.20.0/24'
    hub_outboundDNSSubnetName: 'outboundDNSSubnet'
    hub_outboundDNSSubnetPrefix: '10.110.30.0/24'
    spoke_vnetName: 'vnet-spoke-${location1}'
    spoke_vnetAddressPrefix: '10.120.0.0/16'
    spoke_defaultSubnetName: 'default'
    spoke_defaultSubnetPrefix: '10.120.0.0/24'
    spoke_privateEndpointSubnetName: 'privateEndpointSubnet'
    spoke_privateEndpointSubnetPrefix: '10.120.10.0/24'
    dnsresolverName: 'dnsResolver-${location1}'
    inboundEndpointName: 'inboundep'
    outboundEndpointName: 'outboundep'
    dnsFwdRulesetName: 'dnsFwdRuleset-${location1}'
    sharedKey: 'azureSecureKey1234'
    hubVnetCfg: {
      name: 'vnet-hub-${location1}'
      gatewayName: 'vpngw-hub-${location1}'
      gatewaySubnetPrefix: '10.110.1.224/27'
      gatewayPublicIPName: 'pip-hubvpngw1'
      connectionName: 'vNetHub${location1}-to-vNetOnprem${location1}'
      asn: 65010
    }
    onpremVnetCfg: {
      name: 'vnet-onprem-${location1}'
      gatewayName: 'vpngw-onprem-${location1}'
      gatewaySubnetPrefix: '10.100.1.224/27'
      gatewayPublicIPName: 'pip-onpremvpngw1'
      connectionName: 'vNetOnprem${location1}-to-vNetHub${location1}'
      asn: 65011
    }
  }
}

module region2 'region.bicep' = {
  scope: resourceGroup
  name: '${location2}-Deployment'
  params: {
    location: location2
    onprem_vnetName: 'vnet-onprem-${location2}'
    onprem_vnetAddressPrefix: '10.200.0.0/16'
    onprem_defaulsubnetName: 'default'
    onprem_subnetAddressPrefix: '10.200.0.0/24'
    hub_vnetName: 'vnet-hub-${location2}'
    hub_vnetAddressPrefix: '10.210.0.0/16'
    hub_defaultSubnetName: 'default'
    hub_defaultSubnetPrefix: '10.210.0.0/24'
    hub_privateEndpointSubnetName: 'privateEndpointSubnet'
    hub_privateEndpointSubentPrefix: '10.210.10.0/24'
    hub_inboundDNSSubnetName: 'inboundDNSSubnet'
    hub_inboundDNSSubnetPrefix: '10.210.20.0/24'
    hub_outboundDNSSubnetName: 'outboundDNSSubnet'
    hub_outboundDNSSubnetPrefix: '10.210.30.0/24'
    spoke_vnetName: 'vnet-spoke-${location2}'
    spoke_vnetAddressPrefix: '10.220.0.0/16'
    spoke_defaultSubnetName: 'default'
    spoke_defaultSubnetPrefix: '10.220.0.0/24'
    spoke_privateEndpointSubnetName: 'privateEndpointSubnet'
    spoke_privateEndpointSubnetPrefix: '10.220.10.0/24'
    dnsresolverName: 'dnsResolver-${location2}'
    inboundEndpointName: 'inboundep'
    outboundEndpointName: 'outboundep'
    dnsFwdRulesetName: 'dnsFwdRuleset-${location2}'
    sharedKey: 'azureSecureKey1234'
    hubVnetCfg: {
      name: 'vnet-hub-${location2}'
      gatewayName: 'vpngw-hub-${location2}'
      gatewaySubnetPrefix: '10.210.1.224/27'
      gatewayPublicIPName: 'pip-hubvpngw2'
      connectionName: 'vNetHub${location2}-to-vNetOnprem${location2}'
      asn: 65020
    }
    onpremVnetCfg: {
      name: 'vnet-onprem-${location2}'
      gatewayName: 'vpngw-onprem-${location2}'
      gatewaySubnetPrefix: '10.200.1.224/27'
      gatewayPublicIPName: 'pip-onpremvpngw2'
      connectionName: 'vNetOnprem${location2}-to-vNetHub${location2}'
      asn: 65021
    }
  }
}

// VM をデプロイ
// DNS Server を region1 の疑似オンプレにデプロイ
@secure()
param adminPassword string = 'P@ssw0rd1234'

// onprem vm
module onprem_winsvr '../../core/vm/vm-simple-winsvr.bicep' = {
  scope: resourceGroup
  name: 'onpremWinsvr-Deployment'
  params: {
    location: location1
    tags: tags
    vmName: 'onpremWinsvr'
    vmSize: 'Standard_D2s_v3'
    adminUsername: 'adminuser'
    adminPassword: adminPassword
    vnetName: 'vnet-onprem-${location1}'
    subnetName: 'default'
  }
  dependsOn: [
    region1
  ]
}
// 確認用クライアントを region2 の疑似オンプレにデプロイ
module onprem_win10 '../../core/vm/vm-simple-win10.bicep' = {
  scope: resourceGroup
  name: 'onpremWin10-Deployment'
  params: {
    location: location2
    tags: tags
    vmName: 'onpremWin10'
    vmSize: 'Standard_D2s_v3'
    adminUsername: 'adminuser'
    adminPassword: adminPassword
    vnetName: 'vnet-onprem-${location2}'
    subnetName: 'default'
  }
  dependsOn: [
    region2
  ]
}

// Spoke1の確認用のVMをデプロイ
module spoke_linux '../../core/vm/vm-simple-linux.bicep' = {
  scope: resourceGroup
  name: 'spoke-linux-${location1}-Deployment'
  params: {
    location: location1
    tags: tags
    vmName: 'vm-spoke-${location1}'
    vmSize: 'Standard_D2s_v3'
    authenticationType: 'password'
    securityType: 'Standard'
    adminUsername: 'adminuser'
    adminPasswordOrKey: adminPassword
    vnetName: 'vnet-spoke-${location1}'
    subnetName: 'default'
  }
  dependsOn: [
    region1
  ]
}
// Spoke2の確認用のVMをデプロイ
module spoke2_linux '../../core/vm/vm-simple-linux.bicep' = {
  scope: resourceGroup
  name: 'spoke-linux-${location2}-Deployment'
  params: {
    location: location2
    tags: tags
    vmName: 'vm-spoke-${location2}'
    vmSize: 'Standard_D2s_v3'
    authenticationType: 'password'
    securityType: 'Standard'
    adminUsername: 'adminuser'
    adminPasswordOrKey: adminPassword
    vnetName: 'vnet-spoke-${location2}'
    subnetName: 'default'
  }
  dependsOn: [
    region2
  ]
}

// Bastion on onprem1
module azureBastionSubnet '../../core/network/bastion.bicep' = {
  scope: resourceGroup
  name: 'BastionDeployment'
  params: {
    location: location1
    bastionName: 'bastion'
    sku: 'Standard'
    vnetName: 'vnet-onprem-${location1}'
    BastionSubnetAddressPrefix: '10.100.10.0/24'
    }
  dependsOn: [
    region1
  ]
}

// test.com の DNS Forwarding を設定
param fwdrule_dnsFwdDomain string = 'test.com.'
param dnsFwdRuleName string = 'to-onprem-test-domain-${location1}'

// region1
module dnsForwardingRule1 '../../core/DNS/dnsforwardingrule.bicep' = {
  scope: resourceGroup
  name: 'dnsForwardingRule-${location1}-Deployment'
  params:{
    dnsFwdRulesetName: 'dnsFwdRuleset-${location1}'
    dnsFwdRuleName: dnsFwdRuleName
    domainName: fwdrule_dnsFwdDomain
    dnsIpAddress: onprem_winsvr.outputs.vmPrivateIP
    dnsPort: 53
  }
  dependsOn: [
    region1
    onprem_winsvr
  ]
}

// region2
module dnsForwardingRule2 '../../core/DNS/dnsforwardingrule.bicep' = {
  scope: resourceGroup
  name: 'dnsForwardingRule-${location2}-Deployment'
  params:{
    dnsFwdRulesetName: 'dnsFwdRuleset-${location2}'
    dnsFwdRuleName: dnsFwdRuleName
    domainName: fwdrule_dnsFwdDomain
    dnsIpAddress: onprem_winsvr.outputs.vmPrivateIP
    dnsPort: 53
  }
  dependsOn: [
    region2
    onprem_winsvr
  ]
}

// Private DNS Zone を デプロイ
param privateDNSZoneName string = 'privatelink.blob.core.windows.net'
module BLOBprivateDNSZone '../../core/network/privateDNSZone.bicep' = {
  scope: resourceGroup
  name: 'BLOBDNSZoneDeployment'
  params: {
    privateDNSZoneName: privateDNSZoneName
    tags: tags
  }
}

// Private DNS ZoneにHub仮想ネットワークのリンクを追加
module vnetlink_hub1 '../../core/network/privateDNSvnetLink.bicep' = {
  scope: resourceGroup
  name: 'vnetlink-${location1}-Deployment'
  params: {
    vnetName: 'vnet-hub-${location1}'
    privateDNSZoneName: privateDNSZoneName
    tags: tags
    vnetId: region1.outputs.hub_vnetId
  }
  dependsOn: [
    region1
    BLOBprivateDNSZone
  ]
}

module vnetlink_hub2 '../../core/network/privateDNSvnetLink.bicep' = {
  scope: resourceGroup
  name: 'vnetlink-${location2}-Deployment'
  params: {
    vnetName: 'vnet-hub-${location2}'
    privateDNSZoneName: privateDNSZoneName
    tags: tags
    vnetId: region2.outputs.hub_vnetId
  }
  dependsOn: [
    region2
    BLOBprivateDNSZone
  ]
}

// region1のSpokeに BLOB Storage をデプロイし、Private EndPointを追加
param storageAccountName1 string = 'satoohtatst1'
param storageAccountName2 string = 'satoohtatst2'
param storageContainerName string = 'content'
param private bool = true

module storage1 '../../core/storage/storage-account.bicep' = {
  name: 'storage1-Deployment'
  scope: resourceGroup
  params: {
    name: storageAccountName1
    location: location1
    tags: tags
    publicNetworkAccess: 'Disabled'
    sku: {
      name: 'Standard_LRS'
    }
    containers: [
      {
        name: storageContainerName
        publicAccess: 'None'
      }
    ]
    // for private environment
    private: private
    vnetName: 'vnet-spoke-${location1}'
    peSubnetName: 'privateEndpointSubnet'
  }
  dependsOn: [
    region1
    vnetlink_hub1
  ]
}

// region2のSpokeに BLOB Storage をデプロイし、Private EndPointを追加
module storage2 '../../core/storage/storage-account.bicep' = {
  name: 'storage2-Deployment'
  scope: resourceGroup
  params: {
    name: storageAccountName2
    location: location2
    tags: tags
    publicNetworkAccess: 'Disabled'
    sku: {
      name: 'Standard_LRS'
    }
    containers: [
      {
        name: storageContainerName
        publicAccess: 'None'
      }
    ]
    // for private environment
    private: private
    vnetName: 'vnet-spoke-${location2}'
    peSubnetName: 'privateEndpointSubnet'
  }
  dependsOn: [
    region2
    vnetlink_hub2
  ]
}


// cross region onPrem間の接続を確立
module vpnConnectionOO '../../core/network/vpnconnection.bicep' = {
  scope: resourceGroup
  name: 'vpnConnectionOO-Deployment'
  params: {
    sharedKey: 'azureSecureKey1234'
    location1: location1
    location2: location2
    gw1Name: 'vpngw-onprem-${location1}'
    gw2Name: 'vpngw-onprem-${location2}'
  }
  dependsOn: [
    region1
    region2
  ]
}

// cross-region hub間の接続を確立
module vpnConnectionHH '../../core/network/vpnconnection.bicep' = {
  scope: resourceGroup
  name: 'vpnConnectionHH-Deployment'
  params: {
    sharedKey: 'azureSecureKey1234'
    location1: location1
    location2: location2
    gw1Name: 'vpngw-hub-${location1}'
    gw2Name: 'vpngw-hub-${location2}'
  }
  dependsOn: [
    region1
    region2
  ]
}

// cross-region の Onprem-hub接続を確立
module vpnConnectionOH1 '../../core/network/vpnconnection.bicep' = {
  scope: resourceGroup
  name: 'vpnConnectionOH1-Deployment'
  params: {
    sharedKey: 'azureSecureKey1234'
    location1: location1
    location2: location2
    gw1Name: 'vpngw-onprem-${location1}'
    gw2Name: 'vpngw-hub-${location2}'
  }
  dependsOn: [
    region1
    region2
  ]
}
 
module vpnConnectionOH2 '../../core/network/vpnconnection.bicep' = {
  scope: resourceGroup
  name: 'vpnConnectionOH2-Deployment'
  params: {
    sharedKey: 'azureSecureKey1234'
    location1: location2
    location2: location1
    gw1Name: 'vpngw-onprem-${location2}'
    gw2Name: 'vpngw-hub-${location1}'
  }
  dependsOn: [
    region1
    region2
  ]
}
