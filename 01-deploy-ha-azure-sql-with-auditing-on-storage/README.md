# Using Bicep to Deploy Multi-Region Azure SQL and Storage Accounts for Auditing

## Introduction
Today we will be exploring how to deploy Azure Resources using [Infrastructure as Code (IaC)](https://docs.microsoft.com/en-us/devops/deliver/what-is-infrastructure-as-code), specifically using Azure Bicep. The resources that will be deployed today include the following:

* [Virtual Networks](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/scenarios-virtual-networks) with their Subnets
* [Azure SQL Servers](https://docs.microsoft.com/en-us/azure/azure-sql/database/single-database-create-bicep-quickstart?view=azuresql&tabs=CLI)
* [Azure Storage Accounts](https://docs.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts?tabs=bicep)
* [RBAC Role Assignments](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/scenarios-rbac)
* Azure SQL Server [Auditing Settings](https://docs.microsoft.com/en-us/azure/templates/microsoft.sql/servers/auditingsettings?tabs=bicep)

This setup deploys resources in a Primary and Secondary region, to provide High Availability (e.g. centralus and eastus2).

Also, it creates the Azure SQL Server with the following Features enabled:

* Active Directory admin
* Automatic tuning
* Auditing
* Failover Groups
* Transparent data encryption (using Service Managed Key)

A storage account is deployed in each of the regions with the purpose of low latency writes when sending the Auditing logs from the Azure SQL Server.

The communication for this happens using the Azure SQL Server's [System Assigned Managed Identity](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/overview)

In order for the Azure SQL Server's System Assigned Managed Identity to be able to access the Storage Account, the following role assignments are made at **Storage Account** scope:
* Reader
* Storage Blob Data Contributor

Our setup has the storage accounts behind a Virtual Network, which is also important for the Managed Identity to work.

## Azure Bicep Overview
[Azure Bicep](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview?tabs=bicep) is a domain-specific language (DSL) that uses declarative syntax to deploy Azure resources. In a Bicep file, you define the infrastructure you want to deploy to Azure, and then use that file throughout the development lifecycle to repeatedly deploy your infrastructure. Your resources are deployed in a consistent manner.

Bicep provides concise syntax, reliable type safety, and support for code reuse. Bicep offers a first-class authoring experience for your infrastructure-as-code solutions in Azure.

## Azure SQL Database Overview

[Azure SQL Database](https://docs.microsoft.com/en-us/azure/azure-sql/azure-sql-iaas-vs-paas-what-is-overview?view=azuresql) is a relational database-as-a-service (DBaaS) hosted in Azure that falls into the industry category of Platform-as-a-Service (PaaS).

* Best for modern cloud applications that want to use the latest stable SQL Server features and have time constraints in development and marketing.
* A fully managed SQL Server database engine, based on the latest stable Enterprise Edition of SQL Server. SQL Database has two deployment options built on standardized hardware and software that is owned, hosted, and maintained by Microsoft.

## Failover Group Overview

A [failover group](https://docs.microsoft.com/en-us/azure/azure-sql/database/auto-failover-group-sql-db) is a named group of databases managed by a single server that can fail over as a unit to another Azure region in case all or some primary databases become unavailable due to an outage in the primary region.

The name of the failover group must be globally unique within the .database.windows.net domain.

## Diagram

TODO: Include Diagram

## Code

Let's see how this would look like in our Bicep code.

### Parameters

```bicep
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

@description('Administrator username for the server. Once created it cannot be changed.')
param administratorLogin string

@secure()
@minLength(8)
@maxLength(128)
@description('The administrator login password (required for server creation).')
param administratorLoginPassword string

@description('Login name of the server administrator.')
param loginName string

@description('SID (object ID) of the server administrator.')
param sid string

@allowed(['Group', 'User'])
@description('Principal Type of the sever administrator.')
param principalType string

```

### Virtual Networks

Azure virtual network enables Azure resources to securely communicate with each other, the internet, and on-premises networks.

```bicep
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

  resource JumpboxSubnetCus  'subnets' existing = {    
    name: 'JumpboxSubnet'    
  }
  
  resource WebServerSubnetCus 'subnets' existing = {    
    name: 'WebServerSubnet'    
  }
  
  resource DatabaseSubnetCus 'subnets' existing = {
    name: 'DatabaseSubnet'    
  }
  
  resource AppServiceSubnetCus 'subnets' existing = {    
    name: 'AppServiceSubnet'    
  }
  
  resource AppGatewaySubnetCus 'subnets' existing = {    
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

  resource JumpboxSubnetEUS2  'subnets' existing = {    
    name: 'JumpboxSubnet'    
  }
  
  resource WebServerSubnetEUS2 'subnets' existing = {    
    name: 'WebServerSubnet'    
  }
  
  resource DatabaseSubnetEUS2 'subnets' existing = {
    name: 'DatabaseSubnet'    
  }
  
  resource AppServiceSubnetEUS2 'subnets' existing = {    
    name: 'AppServiceSubnet'    
  }
  
  resource AppGatewaySubnetEUS2 'subnets' existing = {    
    name: 'AppGatewaySubnet'    
  }
}
```

### Virtual Network Peerings

```bicep
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
```

### Storage Accounts

```bicep
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
          id: vnet_primary::JumpboxSubnetCus.id
        }
        {
          action: 'Allow'
          id: vnet_primary::WebServerSubnetCus.id
        }
        {
          action: 'Allow'
          id: vnet_primary::DatabaseSubnetCus.id
        }
        {
          action: 'Allow'
          id: vnet_primary::AppServiceSubnetCus.id
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
          id: vnet_secondary::JumpboxSubnetEUS2.id
        }
        {
          action: 'Allow'
          id: vnet_secondary::WebServerSubnetEUS2.id
        }
        {
          action: 'Allow'
          id: vnet_secondary::DatabaseSubnetEUS2.id
        }
        {
          action: 'Allow'
          id: vnet_secondary::AppServiceSubnetEUS2.id
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
```

### Azure SQL Servers

```bicep
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
```

### Failover Group

The [auto-failover groups](https://docs.microsoft.com/en-us/azure/azure-sql/database/auto-failover-group-configure-sql-db?view=azuresql&tabs=azure-portal&pivots=azure-sql-single-db) feature allows you to manage the replication and failover of a group of databases on a server or all user databases in a managed instance to another Azure region. It is an abstraction on top of the active geo-replication feature.

```bicep
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
```

### Azure SQL Server Virtual Network Rules

[Virtual network rules](https://docs.microsoft.com/en-us/azure/azure-sql/database/vnet-service-endpoint-rule-overview?view=azuresql) are a firewall security feature that controls whether the server for your databases and elastic pools in Azure SQL Database or for your dedicated SQL pool (formerly SQL DW) databases in Azure Synapse Analytics accepts communications that are sent from particular subnets in virtual networks.

In our setup, we are allowing communication from the WebServerSubnet and AppServiceSubnet from the corresponding region.

```bicep
resource allowWebServerSubnetVNetRule_primary 'Microsoft.Sql/servers/virtualNetworkRules@2021-11-01-preview' = {
  parent: sqlServer_primary
  name: 'Allow-CUS-WebServerSubnet'
  properties:{
    virtualNetworkSubnetId: vnet_primary::WebServerSubnetCus.id
  }
}
resource allowAppServiceSubnetVNetRule_primary 'Microsoft.Sql/servers/virtualNetworkRules@2021-11-01-preview' = {
  parent: sqlServer_primary
  name: 'Allow-CUS-AppServiceSubnet'
  properties:{
    virtualNetworkSubnetId: vnet_primary::AppServiceSubnetCus.id
  }
}

resource allowWebServerSubnetVNetRule_secondary 'Microsoft.Sql/servers/virtualNetworkRules@2021-11-01-preview' = {
  parent: sqlServer_secondary
  name: 'Allow-EUS2-WebServerSubnet'
  properties:{
    virtualNetworkSubnetId: vnet_secondary::WebServerSubnetEUS2.id
  }
}
resource allowAppServiceSubnetVNetRule_eastus2 'Microsoft.Sql/servers/virtualNetworkRules@2021-11-01-preview' = {
  parent: sqlServer_secondary
  name: 'Allow-EUS2-AppServiceSubnet'
  properties:{
    virtualNetworkSubnetId: vnet_secondary::AppServiceSubnetEUS2.id
  }
}
```

### Role Assignments
Azure role-based access control (Azure RBAC) helps you manage who has access to Azure resources, what they can do with those resources, and what areas they have access to.

A [role assignment](https://docs.microsoft.com/en-us/azure/role-based-access-control/overview) is the process of attaching a role definition to a user, group, service principal, or managed identity at a particular scope for the purpose of granting access. Access is granted by creating a role assignment, and access is revoked by removing a role assignment.

```bicep
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
```

### Auditing Settings

Azure SQL Auditing tracks database events and writes them to an audit log in your Azure Storage account, Log Analytics workspace or Event Hub.

```bicep
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
```

### Outputs

```bicep
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

```

## Conclusion

Hope you learned something today, I sure did. If you found this helpful, please share with your friends and teams.

Follow me on GitHub: [@gorlandor](https://github.com/gorlandor)
Follow me on Twitter: [@gorlandor](https://twitter.com/gorlandor)