# 05 - Deploy Azure Service Bus

![Resource Visualization](images/05-A-deploy-azure-service-bus.png)

## Intro

This Bicep template deploys an Azure Service Bus Namespace to your Resource Group with the option of adding one or more queues, a topic and one or more subscriptions. It also configures a log analytic workspace and diagnostic settings for said namespace.

### What is Service Bus?

[Azure Service Bus](https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-messaging-overview) is a fully managed enterprise message broker with message queues and publish-subscribe topics. It's primary used to decouple applications and services from each other.

There are three SKUs available: 'Basic', 'Standard', 'Premium'. The template focuses on the Standard SKU, which offers support for both Queues and Topics.

![Azure Service Bus SKUs - Basic (0.05 USD/Million Messages/Month), Standard (10.00 USD/13 Million Messages/Month), Premium (668.00 USD/Messaging Unit/Month)](images/05-service-bus-skus.png)

For more advanced features such as: Private Endpoint, Availability Zones, Geo-Disaster Recovery and Customer Managed Keys (CMK), check out the [Premium SKU]((https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-premium-messaging)).

![Resource Group Deployments](images/05-B-resource-group-deployments.png)

## Queues

Allow for first-in, first-out (FIFO) producer and consumer scenarios and represent a simple way to decouple applications from each other

![Service Bus Queues - Shows two queues: create-customer-queue and place-order-queue](images/05-C-service-bus-queues.png)

## Topic and Subscriptions

Allow for publish and subscribe scenarios. With Topics, all Subscriptions receive a copy of each message. Each subscriber can filter for the messages they care for by SQL Filter or [Correlation Filters](https://learn.microsoft.com/en-us/azure/service-bus-messaging/topic-filters) such as 'label/subject', 'sessionId', 'correlationId' and more.

![Service Bus Topic Subscriptions - Shows two subscriptions within Topic sbt-app-01: notifications-service and order-fulfillment-service](images/05-D-service-bus-topic-subscriptions.png)

## Diagnostic Settings

Send diagnostic logs and metrics from the Service Bus Namespace to Log Analytics Workspace.

Log Categories
* OperationalLogs
* RuntimeAuditLogs
* ApplicationMetricsLogs

Metric Categories
* AllMetrics

![Service Bus Diagnostic Settings - Logs and metrics configured to be sent to log analytics workspace: log-learn-az305](images/05-E-service-bus-diagnostic-settings-b.png)

## GitHub Link
https://github.com/gorlandor/azure-bicep-samples/05-deploy-azure-service-bus

## Conclusion

Hope you learned something today, I sure did. If you found this helpful, please share with your friends and teams.

Follow me on GitHub: [@gorlandor](https://github.com/gorlandor)

Follow me on Twitter: [@gorlandor](https://twitter.com/gorlandor)
