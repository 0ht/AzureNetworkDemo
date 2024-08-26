param udrName string
param location string
//param addressPrefix string = ''
//param nextHopAddress string = ''
//param nextHopType string = ''
param disableBgpRoutePropagation bool = false
//param hasBgpOverride bool = false
param routeCfg array

resource udr 'Microsoft.Network/routeTables@2023-05-01' = {
  name: udrName
  location: location
  properties: {
    // conditionally deploy route
    disableBgpRoutePropagation: disableBgpRoutePropagation
    routes: routeCfg
  }
}


output udrId string = udr.id
