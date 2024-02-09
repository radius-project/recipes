/*
Copyright 2023 The Radius Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

@description('Radius-provided object containing information about the resouce calling the Recipe')
param context object

@description('The geo-location where the resource lives.')
param location string = resourceGroup().location

@description('The name of the Service Bus Topic to create')
param topicName string

@description('The list of subscriptions to create')
param subscriptions array = []

// Service Bus configuration
// https://learn.microsoft.com/en-us/azure/templates/microsoft.servicebus/namespaces?pivots=deployment-language-bicep

@description('The SKU of the Service Bus Namespace. Valid values: (Basic, Standard, Premium)')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param skuName string = 'Standard'

@description('The tier of the Service Bus Namespace. Valid values: (Basic, Standard, Premium)')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param skuTier string = 'Standard'

@description('ISO 8601 Default message timespan to live value. This is the duration after which the message expires, starting from when the message is sent to Service Bus. This is the default value used when TimeToLive is not set on a message itself.')
param defaultMessageTimeToLive string = 'P14D'

@description('The tags that will be applied to the resource')
param tags object = {
  'radapp.io/environment': context.environment.id
  'radapp.io/application': context.application.id
  'radapp.io/resource': context.resource.id
}

resource servicebus 'Microsoft.ServiceBus/namespaces@2021-06-01-preview' = {
  name: 'servicebus-namespace-${uniqueString(context.resource.id, resourceGroup().id)}'
  location: location
  tags: tags
  sku: {
    name: skuName
    tier: skuTier
  }

  resource topic 'topics' = {
    name: topicName
    properties: {
      defaultMessageTimeToLive: defaultMessageTimeToLive
      maxSizeInMegabytes: 1024
      requiresDuplicateDetection: false
      enableBatchedOperations: true
      supportOrdering: false
      enablePartitioning: true
      enableExpress: false
    }

    resource rootRule 'authorizationRules' = {
      name: 'Root'
      properties: {
        rights: [
          'Manage'
          'Send'
          'Listen'
        ]
      }
    }

    resource createSubscriptions 'subscriptions'  = [for subscriptionName in subscriptions: {
      name: subscriptionName
      properties: {
        requiresSession: false
        defaultMessageTimeToLive: defaultMessageTimeToLive
        deadLetteringOnMessageExpiration: true
        deadLetteringOnFilterEvaluationExceptions: true
        maxDeliveryCount: 10
        enableBatchedOperations: true
      }
    }]
  }
}

output result object = {
  secrets: {
    #disable-next-line outputs-should-not-contain-secrets
    connectionString: servicebus::topic::rootRule.listKeys().primaryConnectionString
  }
}

