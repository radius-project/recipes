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

import aws as aws

@description('Radius-provided object containing information about the resource calling the Recipe')
param context object

@description('Name of the EKS cluster used for app deployment')
param eksClusterName string

@description('SQL administrator username')
param adminLogin string

@description('SQL administrator password')
@secure()
param adminPassword string

@description('Name of the SQL database. Defaults to the name of the Radius SQL resource.')
param database string = context.resource.name

resource eksCluster 'AWS.EKS/Cluster@default' existing = {
  alias: eksClusterName
  properties: {
    Name: eksClusterName
  }
}

var rdsSubnetGroupName = 'rds-dbsubnetgroup-${uniqueString(eksClusterName, context.resource.id)}'
resource rdsDBSubnetGroup 'AWS.RDS/DBSubnetGroup@default' = {
  alias: rdsSubnetGroupName
  properties: {
    DBSubnetGroupName: rdsSubnetGroupName
    DBSubnetGroupDescription: rdsSubnetGroupName
    SubnetIds: eksCluster.properties.ResourcesVpcConfig.SubnetIds
  }
}

var rdsDBInstanceName = 'rds-dbinstance-${uniqueString(eksClusterName, context.resource.id)}'
resource rdsDBInstance 'AWS.RDS/DBInstance@default' = {
  alias: rdsDBInstanceName
  properties: {
    DBInstanceIdentifier: rdsDBInstanceName
    Engine: 'sqlserver-ex'
    EngineVersion: '15.00.4153.1.v1'
    DBInstanceClass: 'db.t3.large'
    AllocatedStorage: '20'
    MaxAllocatedStorage: 30
    MasterUsername: adminLogin
    MasterUserPassword: adminPassword
    DBSubnetGroupName: rdsDBSubnetGroup.properties.DBSubnetGroupName
    VPCSecurityGroups: [eksCluster.properties.ClusterSecurityGroupId]
    PreferredMaintenanceWindow: 'Mon:00:00-Mon:03:00'
    PreferredBackupWindow: '03:00-06:00'
    LicenseModel: 'license-included'
    Timezone: 'GMT Standard Time'
    CharacterSetName: 'Latin1_General_CI_AS'
  }
}

output result object = {
  values: {
    server: rdsDBInstance.properties.Endpoint.Address
    port: 1433
    database: database
    username: adminLogin
  }
  secrets: {
    #disable-next-line outputs-should-not-contain-secrets
    connectionString: 'Server=tcp:${rdsDBInstance.properties.Endpoint.Address},${rdsDBInstance.properties.Endpoint.Port};Initial Catalog=${database};User Id=${adminLogin};Password=${adminPassword};Encrypt=false'
    #disable-next-line outputs-should-not-contain-secrets
    password: adminPassword
  }
}
