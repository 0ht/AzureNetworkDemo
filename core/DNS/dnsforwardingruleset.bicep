param location string
param dnsFwdRulesetName string
param outboundEndpointId string
param linkedvnetName string
//param outboundEndpointName string

/*
resource outboundEndpoint 'Microsoft.Network/dnsResolvers/outboundEndpoints@2022-07-01' existing =  {
  name: outboundEndpointName
}
*/

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' existing =  {
  name: linkedvnetName
}

resource dnsFwdRuleset 'Microsoft.Network/dnsForwardingRulesets@2022-07-01' = {
  name: dnsFwdRulesetName
  location: location
  properties: {
    dnsResolverOutboundEndpoints: [
      {
        id: outboundEndpointId
      }
    ]
  }
}

resource dnsFwdRulesetVnetLink 'Microsoft.Network/dnsForwardingRulesets/virtualNetworkLinks@2022-07-01' = {
  name: '${linkedvnetName}-Link'
  parent: dnsFwdRuleset
  properties: {
    metadata: {}
    virtualNetwork: {
      id: vnet.id
    }
  }
}

output dnsFwdRulesetId string = dnsFwdRuleset.id
output dnsFwdRulesetName string = dnsFwdRuleset.name
