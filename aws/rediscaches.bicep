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

@description('List of subnetIds for the subnet group')
param subnetIds array = []

resource eksCluster 'AWS.EKS/Cluster@default' existing = {
  alias: eksClusterName
  properties: {
    Name: eksClusterName
  }
}

param memoryDBSubnetGroupName string = 'memorydb-subnetgroup-${uniqueString(eksClusterName, context.resource.id)}'
resource subnetGroup 'AWS.MemoryDB/SubnetGroup@default' = {
  alias: memoryDBSubnetGroupName
  properties: {
    SubnetGroupName: memoryDBSubnetGroupName
    SubnetIds: ((empty(subnetIds)) ? eksCluster.properties.ResourcesVpcConfig.SubnetIds : concat(subnetIds,eksCluster.properties.ResourcesVpcConfig.SubnetIds))
  }
}

param memoryDBClusterName string = 'memorydb-cluster-${uniqueString(eksClusterName, context.resource.id)}'
resource memoryDBCluster 'AWS.MemoryDB/Cluster@default' = {
  alias: memoryDBClusterName
  properties: {
    ClusterName: memoryDBClusterName
    NodeType: 'db.t4g.small'
    ACLName: 'open-access'
    SecurityGroupIds: [eksCluster.properties.ClusterSecurityGroupId] 
    SubnetGroupName: subnetGroup.name
    NumReplicasPerShard: 0
  }
}

output result object = {
  values: {
    host: memoryDBCluster.properties.ClusterEndpoint.Address
    port: memoryDBCluster.properties.ClusterEndpoint.Port
    tls: true
  }
}
