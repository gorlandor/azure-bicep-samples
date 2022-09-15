@description('Cosmos DB account name')
@maxLength(36)
param accountName string

@description('Object ID of the AAD identity / Enterprise Application. Must be a GUID.')
param principalId string

@allowed(['Cosmos DB Built-in Data Reader', 'Cosmos DB Built-in Data Contributor'])
@description('Cosmos DB SQL Role Name')
param cosmosDbSqlRole string

param sqlRoleDefinitionName string = (cosmosDbSqlRole == 'Cosmos DB Built-in Data Reader') ? '00000000-0000-0000-0000-000000000001' : '00000000-0000-0000-0000-000000000002'

var sqlRoleDefinitionId = cosmosDbAccount::sqlRoleDefinition.id  
var roleAssignmentId = guid(sqlRoleDefinitionId, principalId, cosmosDbAccount.id)

resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2022-05-15' existing = {
  name: accountName

  resource sqlRoleDefinition 'sqlRoleDefinitions@2022-05-15' existing = {
    name: sqlRoleDefinitionName
  }

  resource roleAssignment 'sqlRoleAssignments@2021-10-15' = {
    name: roleAssignmentId
    properties: {       
      scope: cosmosDbAccount.id
      principalId: principalId    
      roleDefinitionId: sqlRoleDefinitionId
    }  
  }
}

output cosmosDbSqlRole string = cosmosDbSqlRole
output cosmosDbAccountId string = cosmosDbAccount.id
output sqlRoleDefinitionId string = sqlRoleDefinitionId
