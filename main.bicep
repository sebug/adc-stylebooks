@description('Username for the virtual machines')
param adminUsername string

@description('Password for the virtual machines')
@minLength(12)
@secure()
param adminPassword string

@description('Unique DNS Name for the Public IP used to access the load balancer.')
param dnsLabelPrefix string = toLower('adc-${uniqueString(resourceGroup().id)}')

@description('Unique name for the Public IP used to manage the load balancer')
param manageDNSLabelPrefix string = toLower('manage-${uniqueString(resourceGroup().id)}')

@description('Name for the Public IP used to access the load balancer.')
param publicIpName string = 'myPublicIP'

@description('Name for the Public IP used to manage the load balancer')
param manageIpName string = 'managePublicIP'

@description('Allocation method for the Public IP used to access the load balancer.')
@allowed([
  'Dynamic'
  'Static'
])
param publicIPAllocationMethod string = 'Dynamic'

param manageIPAllocationMethod string = 'Dynamic'

@description('SKU for the Public IP used to access the load balancer.')
@allowed([
  'Basic'
  'Standard'
])
param publicIpSku string = 'Basic'

param manageIpSku string = 'Basic'

@description('The Windows version for the load balanced VMs. This will pick a fully patched image of this given Windows version.')
@allowed([
  '2016-datacenter-gensecond'
  '2016-datacenter-server-core-g2'
  '2016-datacenter-server-core-smalldisk-g2'
  '2016-datacenter-smalldisk-g2'
  '2016-datacenter-with-containers-g2'
  '2016-datacenter-zhcn-g2'
  '2019-datacenter-core-g2'
  '2019-datacenter-core-smalldisk-g2'
  '2019-datacenter-core-with-containers-g2'
  '2019-datacenter-core-with-containers-smalldisk-g2'
  '2019-datacenter-gensecond'
  '2019-datacenter-smalldisk-g2'
  '2019-datacenter-with-containers-g2'
  '2019-datacenter-with-containers-smalldisk-g2'
  '2019-datacenter-zhcn-g2'
  '2022-datacenter-azure-edition'
  '2022-datacenter-azure-edition-core'
  '2022-datacenter-azure-edition-core-smalldisk'
  '2022-datacenter-azure-edition-smalldisk'
  '2022-datacenter-core-g2'
  '2022-datacenter-core-smalldisk-g2'
  '2022-datacenter-g2'
  '2022-datacenter-smalldisk-g2'
])
param OSVersion string = '2022-datacenter-azure-edition'

@description('Size of the virtual machine.')
param vmSize string = 'Standard_D2s_v5'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Name of the first virtual machine.')
param firstVmName string = 'first-vm'

@description('Name of the second virtual machine that we load balance to')
param secondVmName string = 'second-vm'

@description('Name of the ADC vm')
param adcVmName string = 'adcvm'

@description('Security Type of the Virtual Machines.')
@allowed([
  'Standard'
  'TrustedLaunch'
])
param securityType string = 'TrustedLaunch'

var storageAccountName = 'bootdiags${uniqueString(resourceGroup().id)}'
var firstNicName = 'firstVMNic'
var secondNicName = 'secondVMNic'
var adcNicName = 'adcVMNic'
var manageNicName = 'manageVMNic'
var internalServerAccessNicName = 'isVMNic'

var frontEndSubnetName = 'NSFrontEnd'
var frontEndAddressPrefix = '22.22.0.0/16'
var frontEndSubnetPrefix = '22.22.1.0/24'
var backEndSubnetName = 'NSBackEnd'
var backEndSubnetPrefix = '22.22.2.0/24'
var manageSubnetName = 'NSManage'
var manageSubnetPrefix = '22.22.3.0/24'

var virtualNetworkName = 'MyVNET'
var manageNetworkSecurityGroupName = 'manage-NSG'
var frontendNetworkSecurityGroupName = 'frontend-NSG'
var backendNetworkSecurityGroupName = 'backend-NSG'
var securityProfileJson = {
  uefiSettings: {
    secureBootEnabled: true
    vTpmEnabled: true
  }
  securityType: securityType
}
var extensionName = 'GuestAttestation'
var extensionPublisher = 'Microsoft.Azure.Security.WindowsAttestation'
var extensionVersion = '1.0'
var maaTenantName = 'GuestAttestation'
var maaEndpoint = substring('emptyString', 0, 0)

module storageModule 'storage.bicep' = {
  name: 'storageTemplate'
  params: {
    location: location
    storageAccountName: storageAccountName
  }
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
  name: publicIpName
  location: location
  sku: {
    name: publicIpSku
  }
  properties: {
    publicIPAllocationMethod: publicIPAllocationMethod
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}

resource manageIp 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
  name: manageIpName
  location: location
  sku: {
    name: manageIpSku
  }
  properties: {
    publicIPAllocationMethod: manageIPAllocationMethod
    dnsSettings: {
      domainNameLabel: manageDNSLabelPrefix
    }
  }
}

resource manageNetworkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-05-01' = {
  name: manageNetworkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-22'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '22'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'default-allow-80'
        properties: {
          priority: 1001
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '80'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'default-allow-443'
        properties: {
          priority: 1002
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '443'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'default-allow-3008-3011'
        properties: {
          priority: 1003
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '3008-3011'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'default-allow-4001'
        properties: {
          priority: 1004
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '4001'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'default-allow-67'
        properties: {
          priority: 1005
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '67'
          protocol: 'Udp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'default-allow-123'
        properties: {
          priority: 1006
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '123'
          protocol: 'Udp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'default-allow-161'
        properties: {
          priority: 1007
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '161'
          protocol: 'Udp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'default-allow-500'
        properties: {
          priority: 1008
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '500'
          protocol: 'Udp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'default-allow-3003'
        properties: {
          priority: 1009
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '3003'
          protocol: 'Udp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'default-allow-4500'
        properties: {
          priority: 1010
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '4500'
          protocol: 'Udp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'default-allow-7000'
        properties: {
          priority: 1011
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '7000'
          protocol: 'Udp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// Allow ssh access from the complete outside to port 22
// Allow HTTP 80
resource frontendNetworkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-05-01' = {
  name: frontendNetworkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-80'
        properties: {
          priority: 1001
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '80'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'default-allow-443'
        properties: {
          priority: 1002
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '443'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// allow http traffic as well since we can only have 2 network interfaces :-(
resource backendNetworkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-05-01' = {
  name: backendNetworkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-80'
        properties: {
          priority: 1001
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '80'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'default-allow-443'
        properties: {
          priority: 1002
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '443'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-05-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        frontEndAddressPrefix
      ]
    }
    subnets: [
      {
        name: manageSubnetName
        properties: {
          addressPrefix: manageSubnetPrefix
          networkSecurityGroup: {
            id: manageNetworkSecurityGroup.id
          }
        }
      }
      {
        name: frontEndSubnetName
        properties: {
          addressPrefix: frontEndSubnetPrefix
          networkSecurityGroup: {
            id: frontendNetworkSecurityGroup.id
          }
        }
      }
      {
        name: backEndSubnetName
        properties: {
          addressPrefix: backEndSubnetPrefix
          networkSecurityGroup: {
            id: backendNetworkSecurityGroup.id
          }
        }
      }
    ]
  }
}

resource firstNic 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: firstNicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, backEndSubnetName)
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetwork
  ]
}

resource secondNic 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: secondNicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig2'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, backEndSubnetName)
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetwork
  ]
}

resource firstVm 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: firstVmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: firstVmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: OSVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
      dataDisks: [
        {
          diskSizeGB: 1023
          lun: 0
          createOption: 'Empty'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: firstNic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: storageModule.outputs.storageURI
      }
    }
    securityProfile: ((securityType == 'TrustedLaunch') ? securityProfileJson : json('null'))
  }
}

resource firstVmExtension 'Microsoft.Compute/virtualMachines/extensions@2022-03-01' = if ((securityType == 'TrustedLaunch') && ((securityProfileJson.uefiSettings.secureBootEnabled == true) && (securityProfileJson.uefiSettings.vTpmEnabled == true))) {
  parent: firstVm
  name: extensionName
  location: location
  properties: {
    publisher: extensionPublisher
    type: extensionName
    typeHandlerVersion: extensionVersion
    autoUpgradeMinorVersion: true
    settings: {
      AttestationConfig: {
        MaaSettings: {
          maaEndpoint: maaEndpoint
          maaTenantName: maaTenantName
        }
      }
    }
  }
}

resource firstVmPostCreationScript 'Microsoft.Compute/virtualMachines/runCommands@2023-03-01' = {
  parent: firstVm
  name: 'WebServerPrerequisites'
  location: location
  properties: {
    source: {
      scriptUri: 'https://raw.githubusercontent.com/sebug/adc-stylebooks/main/firstVM.ps1'
    }
  }
}

resource secondVm 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: secondVmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: secondVmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: OSVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
      dataDisks: [
        {
          diskSizeGB: 1023
          lun: 0
          createOption: 'Empty'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: secondNic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: storageModule.outputs.storageURI
      }
    }
    securityProfile: ((securityType == 'TrustedLaunch') ? securityProfileJson : json('null'))
  }
}

resource secondVmExtension 'Microsoft.Compute/virtualMachines/extensions@2022-03-01' = if ((securityType == 'TrustedLaunch') && ((securityProfileJson.uefiSettings.secureBootEnabled == true) && (securityProfileJson.uefiSettings.vTpmEnabled == true))) {
  parent: secondVm
  name: extensionName
  location: location
  properties: {
    publisher: extensionPublisher
    type: extensionName
    typeHandlerVersion: extensionVersion
    autoUpgradeMinorVersion: true
    settings: {
      AttestationConfig: {
        MaaSettings: {
          maaEndpoint: maaEndpoint
          maaTenantName: maaTenantName
        }
      }
    }
  }
}

resource secondVmPostCreationScript 'Microsoft.Compute/virtualMachines/runCommands@2023-03-01' = {
  parent: secondVm
  name: 'WebServerPrerequisites'
  location: location
  properties: {
    source: {
      scriptUri: 'https://raw.githubusercontent.com/sebug/adc-stylebooks/main/secondVM.ps1'
    }
  }
}

resource manageNic 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: manageNicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig4'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: manageIp.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, manageSubnetName)
          }
        }
      }
    ]
  }
}

// ideally we'd have a separate interface for the public sites and the one where we can relay
// traffic to the back-end machines, but the machine size only allows two, so we use this one for
// both tasks
resource adcNic 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: adcNicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig3'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIp.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, backEndSubnetName)
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetwork
  ]
}

resource adcVM 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: adcVmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: adcVmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        patchSettings: {
          patchMode: 'ImageDefault'
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'citrix'
        offer: 'netscalervpx-131'
        sku: 'netscalervpxexpress'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
      dataDisks: [
        {
          diskSizeGB: 1023
          lun: 0
          createOption: 'Empty'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: manageNic.id
          properties: {
            primary: true
          }
        }
        {
          id: adcNic.id
          properties: {
            primary: false
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: storageModule.outputs.storageURI
      }
    }
  }
  plan: {
    name: 'netscalervpxexpress'
    publisher: 'citrix'
    product: 'netscalervpx-131'
  }
}


