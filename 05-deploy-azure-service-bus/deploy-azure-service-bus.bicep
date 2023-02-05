param location string = resourceGroup().location
param workspaceName string
param departmentTag string
param environmentTag string
param serviceBusNamespace string
param serviceBusQueues array
param maxDeliveryCount int
param topicName string
param messageTimeToLive string
param requiresSession bool
param subscriptionNames array
param duplicateDetectionHistoryTimeWindow string

module serviceBusModule 'service-bus.bicep' = {
  name: '05-deploy-azure-service-bus'
  params: {
    departmentTag: departmentTag
    environmentTag: environmentTag
    maxDeliveryCount: maxDeliveryCount
    serviceBusNamespace: serviceBusNamespace
    serviceBusQueues: serviceBusQueues    
    location: location
  }
}
module subscriptionsModule 'service-bus-topic-subscription.bicep' = if(topicName != '') {
  name: '05-service-bus-topic-subscriptions'
  params: {
    serviceBusName: serviceBusNamespace
    topicName: topicName
    subscriptionNames: subscriptionNames
    duplicateDetectionHistoryTimeWindow: duplicateDetectionHistoryTimeWindow
    maxDeliveryCount: maxDeliveryCount
    messageTimeToLive: messageTimeToLive
    requiresSession: requiresSession
  }
  dependsOn: [
    serviceBusModule
  ]
}

module logAnalyticsModule 'log-analytics-workspace.bicep' = {
  name: '05-la-workspace-sb-diagnostic-setting'
  params: {
    serviceBusName: serviceBusNamespace
    departmentTag: departmentTag
    environmentTag: environmentTag
    workspaceName: workspaceName
    location: location
  }
  dependsOn: [
    serviceBusModule
  ]
}
