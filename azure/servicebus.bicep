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

resource servicebus 'Microsoft.ServiceBus/namespaces@2021-06-01-preview' = {
  name: 'servicebus-namespace-${uniqueString(context.resource.id, resourceGroup().id)}'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }

  resource topic 'topics' = {
    name: topicName
    properties: {
      defaultMessageTimeToLive: 'P14D'
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
        defaultMessageTimeToLive: 'P14D'
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

