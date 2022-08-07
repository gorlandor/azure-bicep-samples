@description('Name of the virtual machine resource')
param vmName string

@description('Azure region')
param location string = resourceGroup().location

@description('Name of the keyvault resource')
param keyVaultName string

@description('Name of the secret containing the certificate')
param secretName string

resource linuxVM 'Microsoft.Compute/virtualMachines@2022-03-01' existing = {
  name: vmName
}

resource KVForLinuxExt 'Microsoft.Compute/virtualMachines/extensions@2022-03-01' = {
  name: 'KeyVaultForLinux'
  parent: linuxVM
  location: location
  properties:{
    publisher: 'Microsoft.Azure.KeyVault'
    type: 'KeyVaultForLinux'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      secretsManagementSettings: {
        pollingIntervalInS: '3600'
        certificateStoreLocation: '/var/lib/waagent/Microsoft.Azure.KeyVault'
        observedCertificates: [
          'https://${keyVaultName}${environment().suffixes.keyvaultDns}/secrets/${secretName}'
        ]
      }
    }
  }  
}
