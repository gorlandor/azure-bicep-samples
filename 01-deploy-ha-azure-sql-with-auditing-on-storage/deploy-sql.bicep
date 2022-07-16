@minLength(3)
@maxLength(24)
@description('Name of the storage account for the primary region')
param storageAccountName_primary string

@minLength(3)
@maxLength(24)
@description('Name of the storage account for the secondary region')
param storageAccountName_secondary string

@description('Name of the logical SQL Server for the primary region')
param serverName_primary string

@description('Name of the logical SQL Server for the secondary region')
param serverName_secondary string

@description('Name of the Virtual Network for the primary region')
param vnetName_primary string

@description('Name of the Virtual Network for the secondary region')
param vnetName_secondary string

@description('Name of the Failover Group for SQL')
param failoverGroupName string

@allowed(['centralus', 'eastus', 'eastus2', 'northcentralus', 'westus', 'westus2', 'westus3'])
@description('Location of the primary region')
param location_primary string = 'centralus'

@allowed(['eastus2', 'westus', 'centralus', 'southcentralus', 'eastus', 'westcentralus', 'eastus'])
@description('Location of the secondary region')
param location_secondary string = 'eastus2'

@description('SID (object ID) of the server administrator.')
param sid string

@description('Administrator username for the server. Once created it cannot be changed.')
param administratorLogin string

@secure()
@minLength(8)
@maxLength(128)
@description('The administrator login password (required for server creation).')
param administratorLoginPassword string

@description('Login name of the server administrator.')
param loginName string

@allowed(['Group', 'User'])
@description('Principal Type of the sever administrator.')
param principalType string


resource vnet_primary 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: vnetName_primary
  location: location_primary
  tags: {    
    Department: 'IT'
    Environment: 'Learn'
    Location: location_primary
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.10.0.0/16'
      ]    
    }
    subnets: [
      {
        name: 'JumpboxSubnet'
        properties: {
          addressPrefix: '10.10.1.0/24'
          serviceEndpoints: [
            {
              locations: [
                location_primary
                location_secondary
              ]
              service: 'Microsoft.Storage'
            }
          ]
        }
      }
      {
        name: 'WebServerSubnet'
        properties: {
          addressPrefix: '10.10.2.0/24'
          serviceEndpoints: [
            {
              locations: [
                location_primary
                location_secondary
              ]
              service: 'Microsoft.KeyVault'
            }
            {
              locations: [
                location_primary
                location_secondary
              ]
              service: 'Microsoft.Storage'
            }
            {
              locations: [
                location_primary
                location_secondary
              ]
              service: 'Microsoft.Sql'
            }
          ]
        }
      }
      {
        name: 'DatabaseSubnet'
        properties: {
          addressPrefix: '10.10.3.0/24'
          serviceEndpoints: [
            {
              locations: [
                location_primary
                location_secondary
              ]
              service: 'Microsoft.Storage'
            }
            {
              locations: [
                location_primary
                location_secondary
              ]
              service: 'Microsoft.Sql'
            }
          ]
        }
      }
      {
        name: 'AppServiceSubnet'
        properties: {
          addressPrefix: '10.10.4.0/24'
          serviceEndpoints: [
            {
              locations: [
                location_primary
                location_secondary
              ]
              service: 'Microsoft.KeyVault'
            }
            {
              locations: [
                location_primary
                location_secondary
              ]
              service: 'Microsoft.Storage'
            }
            {
              locations: [
                location_primary
                location_secondary
              ]
              service: 'Microsoft.Sql'
            }
          ]
          delegations: [
            {  
              name: '0'                          
              properties:{
                serviceName: 'Microsoft.Web/serverFarms'                
              }
              type: 'Microsoft.Network/virtualNetworks/subnets/delegations'
            }
          ]
        }
      }
      {
        name: 'AppGatewaySubnet'
        properties: {
          addressPrefix: '10.10.5.0/24'
          serviceEndpoints: [
            {
              locations: [
                location_primary
                location_secondary
              ]
              service: 'Microsoft.Web'
            }
          ]
        }
      }
    ]    
  }

  resource JumpboxSubnet_primary  'subnets' existing = {    
    name: 'JumpboxSubnet'    
  }
  
  resource WebServerSubnet_primary 'subnets' existing = {    
    name: 'WebServerSubnet'    
  }
  
  resource DatabaseSubnet_primary 'subnets' existing = {
    name: 'DatabaseSubnet'    
  }
  
  resource AppServiceSubnet_primary 'subnets' existing = {    
    name: 'AppServiceSubnet'    
  }
  
  resource AppGatewaySubnet_primary 'subnets' existing = {    
    name: 'AppGatewaySubnet'    
  }
}

resource vnet_secondary 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: vnetName_secondary
  location: location_secondary
  tags: {
    Department: 'IT'
    Environment: 'Learn'
    Location: location_secondary
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.20.0.0/16'
      ]    
    }
    subnets: [
      {
        name: 'JumpboxSubnet'
        properties: {
          addressPrefix: '10.20.1.0/24'
          serviceEndpoints: [
            {
              locations: [
                location_primary
                location_secondary
              ]
              service: 'Microsoft.Storage'
            }
          ]
        }
      }
      {
        name: 'WebServerSubnet'
        properties: {
          addressPrefix: '10.20.2.0/24'
          serviceEndpoints: [
            {
              locations: [
                location_primary
                location_secondary
              ]
              service: 'Microsoft.KeyVault'
            }
            {
              locations: [
                location_primary
                location_secondary
              ]
              service: 'Microsoft.Storage'
            }
            {
              locations: [
                location_primary
                location_secondary
              ]
              service: 'Microsoft.Sql'
            }
          ]
        }
      }
      {
        name: 'DatabaseSubnet'
        properties: {
          addressPrefix: '10.20.3.0/24'
          serviceEndpoints: [
            {
              locations: [
                location_primary
                location_secondary
              ]
              service: 'Microsoft.Storage'
            }
            {
              locations: [
                location_primary
                location_secondary
              ]
              service: 'Microsoft.Sql'
            }
          ]
        }
      }
      {
        name: 'AppServiceSubnet'
        properties: {
          addressPrefix: '10.20.4.0/24'
          serviceEndpoints: [
            {
              locations: [
                location_primary
                location_secondary
              ]
              service: 'Microsoft.KeyVault'
            }
            {
              locations: [
                location_primary
                location_secondary
              ]
              service: 'Microsoft.Storage'
            }
            {
              locations: [
                location_primary
                location_secondary
              ]
              service: 'Microsoft.Sql'
            }
          ]
          delegations: [
            {  
              name: '0'                          
              properties:{
                serviceName: 'Microsoft.Web/serverFarms'                
              }
              type: 'Microsoft.Network/virtualNetworks/subnets/delegations'
            }
          ]
        }
      }
      {
        name: 'AppGatewaySubnet'
        properties: {
          addressPrefix: '10.20.5.0/24'
          serviceEndpoints: [
            {
              locations: [
                location_primary
                location_secondary
              ]
              service: 'Microsoft.Web'
            }
          ]
        }
      }
    ]    
  }

  resource JumpboxSubnet_secondary  'subnets' existing = {    
    name: 'JumpboxSubnet'    
  }
  
  resource WebServerSubnet_secondary 'subnets' existing = {    
    name: 'WebServerSubnet'    
  }
  
  resource DatabaseSubnet_secondary 'subnets' existing = {
    name: 'DatabaseSubnet'    
  }
  
  resource AppServiceSubnet_secondary 'subnets' existing = {    
    name: 'AppServiceSubnet'    
  }
  
  resource AppGatewaySubnet_secondary 'subnets' existing = {    
    name: 'AppGatewaySubnet'    
  }
}

resource virtualNetworkPeerings_primary_secondary 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-01-01' = {        
  parent: vnet_primary
  name: 'peer-centralus-vnet-to-eastus2-vnet'
  properties: {
    allowVirtualNetworkAccess: true
    remoteVirtualNetwork: {
      id: vnet_secondary.id
    }
    allowForwardedTraffic: true
  }
}

resource virtualNetworkPeerings_secondary_primary 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-01-01' = {        
  parent: vnet_secondary
  name: 'peer-eastus2-vnet-to-centralus-vnet'
  properties: {
    allowVirtualNetworkAccess: true
    remoteVirtualNetwork: {
      id: vnet_primary.id
    }
    allowForwardedTraffic: true
  }
}

resource storageAcct_primary 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  kind: 'StorageV2'
  location: location_primary
  name: storageAccountName_primary
  sku: {
    name: 'Standard_GRS'
  }
  tags: {    
    Department: 'IT'
    Environment: 'Learn'
    Location: location_primary
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    accessTier: 'Cool'
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'    
    supportsHttpsTrafficOnly: true  
    networkAcls: {
      defaultAction:  'Deny'
      bypass: 'AzureServices'
      virtualNetworkRules: [
        {
          action: 'Allow'
          id: vnet_primary::JumpboxSubnet_primary.id
        }
        {
          action: 'Allow'
          id: vnet_primary::WebServerSubnet_primary.id
        }
        {
          action: 'Allow'
          id: vnet_primary::DatabaseSubnet_primary.id
        }
        {
          action: 'Allow'
          id: vnet_primary::AppServiceSubnet_primary.id
        }        
      ]
      resourceAccessRules: [
        {
          resourceId: sqlServer_primary.id
          tenantId: subscription().tenantId
        }
      ]
    }  
  }
}

resource storageAcct_secondary 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  kind: 'StorageV2'
  location: location_secondary
  name: storageAccountName_secondary
  sku: {
    name: 'Standard_GRS'
  }
  tags: {
    Department: 'IT'
    Environment: 'Learn'
    Location: location_secondary
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    accessTier: 'Cool'
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'    
    supportsHttpsTrafficOnly: true  
    networkAcls: {
      defaultAction:  'Deny'
      bypass: 'AzureServices'
      virtualNetworkRules: [
        {
          action: 'Allow'
          id: vnet_secondary::JumpboxSubnet_secondary.id
        }
        {
          action: 'Allow'
          id: vnet_secondary::WebServerSubnet_secondary.id
        }
        {
          action: 'Allow'
          id: vnet_secondary::DatabaseSubnet_secondary.id
        }
        {
          action: 'Allow'
          id: vnet_secondary::AppServiceSubnet_secondary.id
        }
      ]
      resourceAccessRules: [
        {
          resourceId: sqlServer_secondary.id
          tenantId: subscription().tenantId
        }
      ]
    }  
  }
}

resource sqlServer_primary 'Microsoft.Sql/servers@2021-11-01-preview' = {
  location: location_primary
  name: serverName_primary
  tags: {
    Department: 'IT'
    Environment: 'Learn'
    Location: location_primary
  }
  identity: {
    type: 'SystemAssigned'    
  }
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    administrators: {
      administratorType: 'ActiveDirectory'
      azureADOnlyAuthentication: false
      tenantId: subscription().tenantId
      login: loginName
      principalType: principalType
      sid: sid   
    }
    minimalTlsVersion: '1.2'     
  }
  dependsOn: [
    vnet_primary
  ]
}

resource sqlServer_secondary 'Microsoft.Sql/servers@2021-11-01-preview' = {
  location: location_secondary
  name: serverName_secondary
  tags: {    
    Department: 'IT'
    Environment: 'Learn'
    Location: location_secondary
  }
  identity: {
    type: 'SystemAssigned'    
  }
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    administrators: {
      administratorType: 'ActiveDirectory'
      azureADOnlyAuthentication: false
      tenantId: subscription().tenantId
      login: loginName
      principalType: principalType
      sid: sid   
    }
    minimalTlsVersion: '1.2'     
  }
  dependsOn: [
    vnet_secondary
  ]
}

resource failoverGroup 'Microsoft.Sql/servers/failoverGroups@2021-11-01-preview' = {
  parent: sqlServer_primary
  name: failoverGroupName
  properties: {
    partnerServers: [
      {
        id: sqlServer_secondary.id
      }
    ]
    readWriteEndpoint: {
      failoverPolicy: 'Automatic'
      failoverWithDataLossGracePeriodMinutes: 60
    }
  }
}

resource allowWebServerSubnetVNetRule_primary 'Microsoft.Sql/servers/virtualNetworkRules@2021-11-01-preview' = {
  parent: sqlServer_primary
  name: 'Allow-WebServerSubnet-1'
  properties:{
    virtualNetworkSubnetId: vnet_primary::WebServerSubnet_primary.id
  }
}
resource allowAppServiceSubnetVNetRule_primary 'Microsoft.Sql/servers/virtualNetworkRules@2021-11-01-preview' = {
  parent: sqlServer_primary
  name: 'Allow-AppServiceSubnet-1'
  properties:{
    virtualNetworkSubnetId: vnet_primary::AppServiceSubnet_primary.id
  }
}

resource allowWebServerSubnetVNetRule_secondary 'Microsoft.Sql/servers/virtualNetworkRules@2021-11-01-preview' = {
  parent: sqlServer_secondary
  name: 'Allow-WebServerSubnet-2'
  properties:{
    virtualNetworkSubnetId: vnet_secondary::WebServerSubnet_secondary.id
  }
}
resource allowAppServiceSubnetVNetRule_eastus2 'Microsoft.Sql/servers/virtualNetworkRules@2021-11-01-preview' = {
  parent: sqlServer_secondary
  name: 'Allow-AppServiceSubnet-2'
  properties:{
    virtualNetworkSubnetId: vnet_secondary::AppServiceSubnet_secondary.id
  }
}

@description('This is the built-in Reader role. See https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#reader')
resource readerRoleAssignment_primary 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(resourceGroup().id, 'f63c107e-e49d-4f83-a9b8-a9ff397859a1')
  scope: storageAcct_primary
  properties: {        
    principalId: sqlServer_primary.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')
  }
}

@description('This is the built-in Storage Blob Data Contributor role. See https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#storage-blob-data-contributor')
resource blobDataContributorRoleAssignment_primary 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(resourceGroup().id, 'bda44757-ba7f-41bd-b1d1-263b5f9b69a0')  
  scope: storageAcct_primary
  properties: {    
    principalId: sqlServer_primary.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
  }
}

@description('This is the built-in Reader role. See https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#reader')
resource readerRoleAssignment_secondary 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(resourceGroup().id, '2f89e7ff-f2e9-4b37-8d66-8d5e5aa78c4c')
  scope: storageAcct_secondary
  properties: {        
    principalId: sqlServer_secondary.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')
  }
}

@description('This is the built-in Storage Blob Data Contributor role. See https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#storage-blob-data-contributor')
resource blobDataContributorRoleAssignment_secondary 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(resourceGroup().id, '69c8cece-361f-4912-be2b-5dcf4513d782')  
  scope: storageAcct_secondary
  properties: {    
    principalId: sqlServer_secondary.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
  }
}

resource sqlServerAuditing_primary 'Microsoft.Sql/servers/auditingSettings@2021-11-01-preview' = {
  name: 'default'
  parent: sqlServer_primary
  properties: {
    state: 'Enabled'
    auditActionsAndGroups: [
      'BATCH_COMPLETED_GROUP'
      'SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP'
      'FAILED_DATABASE_AUTHENTICATION_GROUP'
    ]
    isManagedIdentityInUse: true
    storageEndpoint: storageAcct_primary.properties.primaryEndpoints.blob
    storageAccountAccessKey: json('null')    
    storageAccountSubscriptionId: subscription().subscriptionId    
    isStorageSecondaryKeyInUse: false
    retentionDays: 14
  }
  dependsOn: [
    vnet_primary
  ]
}

resource sqlServerAuditing_secondary 'Microsoft.Sql/servers/auditingSettings@2021-11-01-preview' = {
  name: 'default'
  parent: sqlServer_secondary
  properties: {
    state: 'Enabled'
    auditActionsAndGroups: [
      'BATCH_COMPLETED_GROUP'
      'SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP'
      'FAILED_DATABASE_AUTHENTICATION_GROUP'
    ]
    isManagedIdentityInUse: true
    storageEndpoint: storageAcct_secondary.properties.primaryEndpoints.blob
    storageAccountAccessKey: json('null')    
    storageAccountSubscriptionId: subscription().subscriptionId    
    isStorageSecondaryKeyInUse: false
    retentionDays: 14
  }
  dependsOn: [
    vnet_secondary
  ]
}

resource sqlServerDevOpsAuditing_primary 'Microsoft.Sql/servers/devOpsAuditingSettings@2021-11-01-preview' = {
  name: 'default'
  parent: sqlServer_primary
  properties: {
    state: 'Enabled'        
    storageEndpoint: storageAcct_primary.properties.primaryEndpoints.blob
    storageAccountAccessKey: json('null')    
    storageAccountSubscriptionId: subscription().subscriptionId     
  }
  dependsOn: [
    vnet_primary
    sqlServerAuditing_primary
  ]
}

resource sqlServerDevOpsAuditing_secondary 'Microsoft.Sql/servers/devOpsAuditingSettings@2021-11-01-preview' = {
  name: 'default'
  parent: sqlServer_secondary
  properties: {
    state: 'Enabled'
    storageEndpoint: storageAcct_secondary.properties.primaryEndpoints.blob
    storageAccountAccessKey: json('null')    
    storageAccountSubscriptionId: subscription().subscriptionId        
  }
  dependsOn: [
    vnet_secondary
    sqlServerAuditing_secondary
  ]
}

output vnet_primary_id string = vnet_primary.id
output vnet_secondary_id string = vnet_secondary.id

output readerRoleAssignment_primary_id string = readerRoleAssignment_primary.id
output blobDataContributorRoleAssignment_primary_id string = blobDataContributorRoleAssignment_primary.id

output readerRoleAssignment_eastus2_id string = readerRoleAssignment_secondary.id
output blobDataContributorRoleAssignment_eastus2_id string = blobDataContributorRoleAssignment_secondary.id

output storageAcct_primary string = storageAcct_primary.id
output storageAcct_secondary string = storageAcct_secondary.id

output sqlServer_primary string = sqlServer_primary.id
output sqlServer_secondary string = sqlServer_secondary.id
