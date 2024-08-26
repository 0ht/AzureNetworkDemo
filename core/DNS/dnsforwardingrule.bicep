param dnsFwdRulesetName string
param dnsFwdRuleName string
param domainName string
param dnsIpAddress string
param dnsPort int

resource dnsFwdRuleset 'Microsoft.Network/dnsForwardingRulesets@2022-07-01' existing = {
  name: dnsFwdRulesetName
}

resource dnsFwdRule 'Microsoft.Network/dnsForwardingRulesets/forwardingRules@2022-07-01' = {
  name: dnsFwdRuleName
  parent: dnsFwdRuleset
  properties: {
    domainName: domainName
    forwardingRuleState: 'Enabled'
    metadata: {}
    targetDnsServers: [
      {
        ipAddress: dnsIpAddress
        port: dnsPort
      }
    ]
  }
}

output dnsFwdRuleID string = dnsFwdRule.id

