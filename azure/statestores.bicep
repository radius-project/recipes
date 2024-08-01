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

@description('Sets this Dapr State Store as the actor state store. Only one Dapr State Store can be set as the actor state store. Defaults to false.')
param actorStateStore bool = false

@description('The name of the container to create within the Azure storage account and to reference within the Dapr component.')
var containerName = context.resource.name

@description('The user-defined tags that will be applied to the resource. Default is null')
param tags object = {}

@description('The Radius specific tags that will be applied to the resource')
var radiusTags = {
  'radapp.io-environment': context.environment.id
  'radapp.io-application': context.application == null ? '' : context.application.id
  'radapp.io-resource': context.resource.id
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: 'recipe${uniqueString(context.resource.id, resourceGroup().id)}'
  location: location
  tags: union(tags, radiusTags)
  sku: {
    name: 'Standard_ZRS'
  }
  kind: 'StorageV2'

  resource blob 'blobServices' = {
    name: 'default'

    resource container 'containers' = {
      name: containerName
    }
  }
}

extension kubernetes with {
  kubeConfig: ''
  namespace: context.runtime.kubernetes.namespace
} as k8s

var daprType = 'state.azure.blobstorage'
var daprVersion = 'v1'

resource daprComponent 'dapr.io/Component@v1alpha1' = {
  metadata: {
    name: context.resource.name
  }
  spec: {
    type: daprType
    version: daprVersion
    metadata: [
      {
        name: 'accountName'
        value: storageAccount.name
      }
      // Temporarily setting raw secret value until richer secret store support in Radius
      {
        name: 'accountKey'
        value: storageAccount.listKeys().keys[0].value
      }
      {
        name: 'containerName'
        value: containerName
      }
      {
        name: 'actorStateStore'
        value: actorStateStore ? 'true' : 'false'
      }
    ]
  }
}

output result object = {
  // This workaround is needed because the deployment engine omits Kubernetes resources from its output.
  // This allows Kubernetes resources to be cleaned up when the resource is deleted.
  // Once this gap is addressed, users won't need to do this.
  resources: [
    '/planes/kubernetes/local/namespaces/${daprComponent.metadata.namespace}/providers/dapr.io/Component/${daprComponent.metadata.name}'
  ]
  values: {
    type: daprType
    version: daprVersion
    metadata: daprComponent.spec.metadata
  }
}
