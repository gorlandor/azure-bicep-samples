@description('Service Bus Namespace - Name')
param serviceBusName string

@description('Service Bus - Topic Name')
param topicName string

@description('Service Bus - Subscription Name(s)')
param subscriptionNames array

@description('Service Bus Subscription(s) - Requires Session')
param requiresSession bool

@minLength(3)
@description('Service Bus Topic - Duplicate Detection Window (ISO 8601)')
param duplicateDetectionHistoryTimeWindow string

@description('Service Bus Subscription(s) - Message TTL (ISO 8601)')
@minLength(3)
param messageTimeToLive string

@description('Service Bus Subscription - Maximum Delivery Count')
param maxDeliveryCount int

resource service_bus 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' existing = {
  name: serviceBusName

  resource service_bus_topic 'topics@2022-10-01-preview' = {
    name: topicName
    properties: {
      requiresDuplicateDetection: true
      duplicateDetectionHistoryTimeWindow: duplicateDetectionHistoryTimeWindow
      defaultMessageTimeToLive: messageTimeToLive
    }
    resource subscription 'subscriptions@2022-10-01-preview' = [for topicSubscription in subscriptionNames: {
      name: topicSubscription
      properties: {
        requiresSession: requiresSession
        maxDeliveryCount: maxDeliveryCount
        defaultMessageTimeToLive: messageTimeToLive
        deadLetteringOnMessageExpiration: true
        deadLetteringOnFilterEvaluationExceptions: true
      }
    }]
  }
}
