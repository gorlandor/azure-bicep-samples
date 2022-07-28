@description('The app service plan resource name')
param appServicePlanName string

@description('The app service webapp resource name')
param appServiceName string

var appServiceNameLowerCase = toLower(appServiceName)

@description('Diagnostic Logs Storage Account Name')
param storageAccountName string

@description('Resource Location')
param location string

@allowed(['linux', 'windows'])
@description('Kind of resource')
param operatingSystem string

@description('Log Analytics Workspace Name')
param logAnalyticsWorkspaceName string

var alwaysOnFeatureAvailable = startsWith(sku, 'P')

@allowed([
  'F1'  
  'B1'
  'B2'
  'B3'
  'S1'
  'S2'
  'S3'
  'P1v2'
  'P2v2'
  'P3v2'
  'P1v3'
  'P2v3'
  'P3v3'
])
@description('Name of the resource SKU')
param sku string

@description('Name for the application insights resource')
param applicationInsightsName string

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_GRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Cool'
  }
  tags: {
    Environment: 'Learn'
    Department: 'IT'    
  }

  resource blobServices 'blobServices@2021-09-01' = {
    name: 'default'
    properties: {}

    resource storageAccountContainerDiag 'containers@2021-09-01' = {
      name: '${appServiceNameLowerCase}-diag'
      properties: {
        publicAccess: 'Blob'
      }
    }
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
  location: location
  kind: operatingSystem
  properties: {
    zoneRedundant: false   
    reserved: operatingSystem == 'linux' ? true : false 
  }
  sku: {
    name: sku    
  }
  tags: {
    Environment: 'Learn'
    Department: 'IT'    
  }
}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: logAnalyticsWorkspaceName
  location: location
  tags: {
    Environment: 'Learn'
    Department: 'IT'    
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  kind: 'web'
  location: location
  name: applicationInsightsName
  properties: {
    Application_Type: 'web'
    IngestionMode: 'LogAnalytics'
    WorkspaceResourceId: logAnalytics.id
    RetentionInDays: 30
    Request_Source: 'rest'
  }
}

resource appServiceWebApp 'Microsoft.Web/sites@2022-03-01' = {
  location: location
  name: appServiceNameLowerCase
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    httpsOnly: true
    siteConfig: {
      alwaysOn: alwaysOnFeatureAvailable  
      http20Enabled: true 
      linuxFxVersion: 'DOTNETCORE|6.0' 
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsights.properties.ConnectionString
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsights.properties.InstrumentationKey
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
      ]
    }
    serverFarmId: appServicePlan.id  
  }
  kind: 'app'
  tags: {
    Environment: 'Learn'
    Department: 'IT'    
  }

  resource configureMetadata 'config@2022-03-01' = {
    name: 'metadata'
    properties: {
      CURRENT_STACK: 'dotnet'
    }
  }
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${appServiceNameLowerCase}-diag'
  scope: appServiceWebApp  
  properties: {    
    workspaceId: logAnalytics.id
    logs: [
      {
        category: 'AppServiceHTTPLogs'        
        enabled: true
      }
      {
        category: 'AppServiceConsoleLogs'        
        enabled: true
      }
      {
        category: 'AppServiceAppLogs'        
        enabled: true
      }
      {
        category: 'AppServiceAuditLogs'
        enabled: true
      }
      {
        category: 'AppServiceIPSecAuditLogs'
        enabled: true
      }
      {
        category: 'AppServicePlatformLogs'
        enabled: true
      }
    ]
  }
}

resource diagnosticSettingsToStorage 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${appServiceNameLowerCase}-diag-store'
  scope: appServiceWebApp  
  properties: {    
    storageAccountId: storageAccount.id
    logs: [
      {
        category: 'AppServiceHTTPLogs'        
        enabled: true
        retentionPolicy: {
          days: 90
          enabled: true
        }
      }
      {
        category: 'AppServiceConsoleLogs'        
        enabled: true
        retentionPolicy: {
          days: 90
          enabled: true
        }
      }
      {
        category: 'AppServiceAppLogs'        
        enabled: true
        retentionPolicy: {
          days: 90
          enabled: true
        }
      }
      {
        category: 'AppServiceAuditLogs'
        enabled: true
        retentionPolicy: {
          days: 90
          enabled: true
        }
      }
      {
        category: 'AppServiceIPSecAuditLogs'
        enabled: true
        retentionPolicy: {
          days: 90
          enabled: true
        }
      }
      {
        category: 'AppServicePlatformLogs'
        enabled: true
        retentionPolicy: {
          days: 90
          enabled: true
        }
      }
    ]
  }
}

resource diagnosticSettingsBlob 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${storageAccountName}-diag'
  scope: storageAccount::blobServices  
  properties: {    
    workspaceId: logAnalytics.id
    logs: [
      {
        category: 'StorageRead'        
        enabled: true
      }
      {
        category: 'StorageWrite'        
        enabled: true
      }
      {
        category: 'StorageDelete'        
        enabled: true
      }
    ]
  }
}
