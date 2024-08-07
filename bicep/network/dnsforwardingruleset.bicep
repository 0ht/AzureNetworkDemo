param dnsFwdRulesetName string
param outboundEndpointId string
//param outboundEndpointName string

/*
resource outboundEndpoint 'Microsoft.Network/dnsResolvers/outboundEndpoints@2022-07-01' existing =  {
  name: outboundEndpointName
}
*/

resource dnsFwdRuleset 'Microsoft.Network/dnsForwardingRulesets@2022-07-01' = {
  name: dnsFwdRulesetName
  location: resourceGroup().location
  properties: {
    dnsResolverOutboundEndpoints: [
      {
        id: outboundEndpointId
      }
    ]
  }
}

output dnsFwdRulesetId string = dnsFwdRuleset.id
output dnsFwdRulesetName string = dnsFwdRuleset.name
