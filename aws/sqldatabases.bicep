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

extension aws

@description('Radius-provided object containing information about the resource calling the Recipe')
param context object

@description('Name of the EKS cluster used for app deployment')
param eksClusterName string

@description('SQL administrator username')
param adminLogin string = 'sqladmin'

@description('SQL administrator password')
@secure()
param adminPassword string = newGuid()

@description('Name of the SQL database. Defaults to the name of the Radius SQL resource.')
param database string = context.resource.name

// RDS DBInstance configuration
// https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-rds-dbinstance.html

@description('Database engine type')
param engine string = 'sqlserver-ex'

@description('Database engine version')
param engineVersion string = '15.00.4153.1.v1'

@description('Database instance class')
param dbInstanceClass string = 'db.t3.small'

@description('Database storage size in GB')
param allocatedStorage string = '20'

@description('Database license model')
param licenseModel string = 'license-included'

@description('The number of days for which automated backups are retained. Setting this parameter to a positive number enables backups. Defaults to 1.')
@minValue(0)
@maxValue(35)
param backupRetentionPeriod int = 1

@description('Database port')
param port int = 1433

resource eksCluster 'AWS.EKS/Cluster@default' existing = {
  alias: eksClusterName
  properties: {
    Name: eksClusterName
  }
}

var rdsSubnetGroupName = 'rds-dbsubnetgroup-${uniqueString(context.resource.id, eksClusterName)}'
resource rdsDBSubnetGroup 'AWS.RDS/DBSubnetGroup@default' = {
  alias: rdsSubnetGroupName
  properties: {
    DBSubnetGroupName: rdsSubnetGroupName
    DBSubnetGroupDescription: rdsSubnetGroupName
    SubnetIds: eksCluster.properties.ResourcesVpcConfig.SubnetIds
    Tags: [
      {
        Key: 'radapp.io/environment'
        Value: context.environment.id
      }
      {
        Key: 'radapp.io/application'
        Value: context.application.id
      }
      {
        Key: 'radapp.io/resource'
        Value: context.resource.id
      }
    ]
  }
}

var rdsDBInstanceName = 'rds-dbinstance-${uniqueString(context.resource.id, eksClusterName)}'
resource rdsDBInstance 'AWS.RDS/DBInstance@default' = {
  alias: rdsDBInstanceName
  properties: {
    DBInstanceIdentifier: rdsDBInstanceName
    Engine: engine
    EngineVersion: engineVersion
    DBInstanceClass: dbInstanceClass
    AllocatedStorage: allocatedStorage
    MasterUsername: adminLogin
    MasterUserPassword: adminPassword
    DBSubnetGroupName: rdsDBSubnetGroup.properties.DBSubnetGroupName
    VPCSecurityGroups: [eksCluster.properties.ClusterSecurityGroupId]
    LicenseModel: licenseModel
    BackupRetentionPeriod: backupRetentionPeriod
    Tags: [
      {
        Key: 'radapp.io/environment'
        Value: context.environment.id
      }
      {
        Key: 'radapp.io/application'
        Value: context.application.id
      }
      {
        Key: 'radapp.io/resource'
        Value: context.resource.id
      }
    ]
  }
}

output result object = {
  values: {
    server: rdsDBInstance.properties.Endpoint.Address
    port: port
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
