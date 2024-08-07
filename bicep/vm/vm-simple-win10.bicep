param location string = resourceGroup().location
param tags object = {}

param vmName string
param vmSize string
param adminUsername string
@secure()
param adminPassword string

param vnetName string
param subnetName string
param isSpotVM bool = false 

var imageReference = {
  'Windows-10': {
    publisher: 'MicrosoftWindowsDesktop'
    offer: 'Windows-10'
    sku: 'win10-22h2-pro'
    version: 'latest'
  }
}
//var publicIPAddressName = '${vmName}PublicIP'
var networkInterfaceName = '${vmName}NetInt'
var osDiskType = 'Standard_LRS'

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' existing =  {
  name: vnetName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' existing =  {
  name: subnetName
  parent: vnet
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2021-05-01' = {
  name: networkInterfaceName
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnet.id
          }
          privateIPAllocationMethod: 'Dynamic'
          //publicIPAddress: {
          //  id: publicIPAddress.id
          //}
        }
      }
    ]
    //networkSecurityGroup: {
    //  id: networkSecurityGroup.id
    //}
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2021-11-01' = {
  name: vmName
  location: location
  properties: {
    priority: ((isSpotVM) ? 'Spot' : null)  // Enable spot instance
    evictionPolicy:  ((isSpotVM) ? 'Deallocate' : null)  // Deallocate the VM on eviction
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
      imageReference: imageReference['Windows-10']
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
        patchSettings: {
          patchMode: 'AutomaticByOS'
          assessmentMode: 'ImageDefault'
         }
      } 
    }
  }
}
