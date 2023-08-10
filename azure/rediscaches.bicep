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

@description('The size of the Redis cache to deploy. Valid values: for C (Basic/Standard) family (0, 1, 2, 3, 4, 5, 6), for P (Premium) family (1, 2, 3, 4).')
@minValue(0)
@maxValue(6)
param skuCapacity int = 0

@description('The SKU family to use. Valid values: (C, P). (C = Basic/Standard, P = Premium).')
@allowed([
  'C'
  'P'
])
param skuFamily string = 'C'

@description('The type of Redis cache to deploy. Valid values: (Basic, Standard, Premium)')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param skuName string = 'Basic'

resource azureCache 'Microsoft.Cache/redis@2022-06-01' = {
  name: 'cache-${uniqueString(context.resource.id, resourceGroup().id)}'
  location: location
  properties: {
    sku: {
      capacity: skuCapacity
      family: skuFamily
      name: skuName
    }
  }
}

output result object = {
  values: {
    host: azureCache.properties.hostName
    port: azureCache.properties.sslPort
    username: ''
    tls: true
  }
  secrets: {
    #disable-next-line outputs-should-not-contain-secrets
    password: azureCache.listKeys().primaryKey
  }
}
