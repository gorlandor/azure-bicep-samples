param location string = resourceGroup().location
param workspaceName string
param departmentTag string
param environmentTag string
param serviceBusName string

resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location  
  properties: {
    sku: {
      name: 'PerGB2018'            
    }
    workspaceCapping: {
      dailyQuotaGb: 1
    }
    retentionInDays: 30    
  }
  tags: {
    Department: departmentTag
    Environment: environmentTag
  }
}

resource service_bus 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' existing = {
  name: serviceBusName
}

resource diagnostic 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'servicebus-diag'
  scope: service_bus
  properties: {
    workspaceId: workspace.id
    logs: [
      {
        enabled: true
        category: 'OperationalLogs'        
      }
      {
        enabled: true
        category: 'RuntimeAuditLogs'
      }
      {
        enabled: true
        category: 'ApplicationMetricsLogs'        
      }
    ]
    metrics: [
      {
        enabled: true
        category: 'AllMetrics'
      }
    ]
  }
}
