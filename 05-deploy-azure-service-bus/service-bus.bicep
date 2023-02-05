param location string = resourceGroup().location
param serviceBusNamespace string
param serviceBusQueues array
param departmentTag string
param environmentTag string
param maxDeliveryCount int

resource service_bus 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' = {
  location: location
  name: serviceBusNamespace
  properties: {    
    disableLocalAuth: false
    minimumTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
  }
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
  tags: {
    Department: departmentTag
    Environment: environmentTag
  }
  resource service_bus_queue 'queues@2022-10-01-preview' = [for queue in serviceBusQueues: {
    name: queue
    properties: {
      maxDeliveryCount: maxDeliveryCount      
    }
  }]

  resource listen_sas 'AuthorizationRules@2022-10-01-preview' = {
    name: 'ListenSasPolicy'
    properties: {
      rights: [
        'Listen'
      ]
    }
  }
  resource send_sas 'AuthorizationRules@2022-10-01-preview' = {
    name: 'SendSasPolicy'
    properties: {
      rights: [
        'Send'
      ]
    }
  }  
}

@description('Service Bus Namespace Resource ID')
output service_bus_resource_id string = service_bus.id
