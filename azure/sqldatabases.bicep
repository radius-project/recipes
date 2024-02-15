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

@description('SQL administrator username')
param adminLogin string = 'sqladmin'

@description('SQL administrator password')
@secure()
param adminPassword string = newGuid()

@description('Name of the SQL database. Defaults to the name of the Radius SQL resource.')
param database string = context.resource.name

@description('The type of SQL database to deploy. Valid values: (Basic, Standard, Premium)')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param skuName string = 'Standard'

@description('The size of the SQL database to deploy. Valid values: (Basic, Standard, Premium)')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param skuTier string = 'Standard'

@description('The user-defined tags that will be applied to the resource. Default is null')
param tags object = {}

@description('The Radius specific tags that will be applied to the resource')
var radiusTags = {
  'radapp.io-environment': context.environment.id
  'radapp.io-application': context.application == null ? '' : context.application.id
  'radapp.io-resource': context.resource.id
}

var mssqlPort = 1433

resource mssql 'Microsoft.Sql/servers@2021-02-01-preview' = {
  name: '${context.resource.name}-${uniqueString(context.resource.id, resourceGroup().id)}'
  location: location
  tags: union(tags, radiusTags)
  properties: {
    administratorLogin: adminLogin
    administratorLoginPassword: adminPassword
  }

  resource firewallAllowEverything 'firewallRules' = {
    name: 'firewall-allow-everything'
    properties: {
      startIpAddress: '0.0.0.0'
      endIpAddress: '255.255.255.255'
    }
  }

  resource db 'databases' = {
    name: database
    location: location
    tags: union(tags, radiusTags)
    sku: {
      name: skuName
      tier: skuTier
    }
  }
}

output result object = {
  values: {
    server: mssql.properties.fullyQualifiedDomainName
    port: mssqlPort
    database: database
    username: adminLogin
  }
  secrets: {
    #disable-next-line outputs-should-not-contain-secrets
    password: adminPassword
    #disable-next-line outputs-should-not-contain-secrets
    connectionString: 'Server=tcp:${mssql.properties.fullyQualifiedDomainName},${mssqlPort};Initial Catalog=${database};User Id=${adminLogin};Password=${adminPassword};Encrypt=false'
  }
}
