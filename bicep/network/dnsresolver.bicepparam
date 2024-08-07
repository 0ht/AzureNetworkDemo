using './dnsresolver.bicep'

param dnsresolverName = 'dnsResolver'
param inboundEndpointName = 'inboundep'
param outboundEndpointName = 'outboundep'
param vnetName = 'vnet-hub'
param inboundsubnetName = 'inboundDNSSubnet'
param outboundsubnetName = 'outboundDNSSubnet'

