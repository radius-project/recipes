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

@description('Information about what resource is calling this Recipe. Generated by Radius. For more information visit https://docs.radapp.dev/operations/custom-recipes/')
param context object

@description('Name of the PostgreSQL database. Defaults to the name of the Radius resource.')
param database string = context.resource.name

@description('PostgreSQL username')
param user string = 'postgres'

@description('PostgreSQL password')
@secure()
#disable-next-line secure-parameter-default
param password string = 'P@ssword1234$$'

@description('Tag to pull for the postgres container image.')
param tag string = '16-alpine'

@description('Memory request for the postgres deployment.')
param memoryRequest string = '512Mi'

@description('Memory limit for the postgres deployment')
param memoryLimit string = '1024Mi'

import kubernetes as kubernetes {
  kubeConfig: ''
  namespace: context.runtime.kubernetes.namespace
}

var uniqueName = 'postgres-${uniqueString(context.resource.id)}'
var port = 5432

// Based on https://hub.docker.com/_/postgres/
resource postgresql 'apps/Deployment@v1' = {
  metadata: {
    name: uniqueName
  }
  spec: {
    selector: {
      matchLabels: {
        app: 'postgresql'
        resource: context.resource.name
      }
    }
    template: {
      metadata: {
        labels: {
          app: 'postgresql'
          resource: context.resource.name

          // Label pods with the application name so `rad run` can find the logs.
          'radapp.io/application': context.application == null ? '' : context.application.name
        }
      }
      spec: {
        containers: [
          {
            // This container is the running postgresql instance.
            name: 'postgres'
            image: 'postgres:${tag}'
            ports: [
              {
                containerPort: port 
              }
            ]
            resources: {
              requests: {
                memory: memoryRequest
              }
              limits: {
                memory: memoryLimit
              }
            }
            env: [
              {
                name: 'POSTGRES_USER'
                value: user
              }
              {
                name: 'POSTGRES_PASSWORD'
                value: password
              }
              {
                name: 'POSTGRES_DB'
                value: database
              }
            ]
          }
        ]
      }
    }
  }
}

resource svc 'core/Service@v1' = {
  metadata: {
    name: uniqueName
    labels: {
      name: uniqueName
    }
  }
  spec: {
    type: 'ClusterIP'
    selector: {
      app: 'postgresql'
      resource: context.resource.name
    }
    ports: [
      {
        port: port 
      }
    ]
  }
}

output result object = {
  // This workaround is needed because the deployment engine omits Kubernetes resources from its output.
  // This allows Kubernetes resources to be cleaned up when the resource is deleted.
  // Once this gap is addressed, users won't need to do this.
  resources: [
    '/planes/kubernetes/local/namespaces/${svc.metadata.namespace}/providers/core/Service/${svc.metadata.name}'
    '/planes/kubernetes/local/namespaces/${postgresql.metadata.namespace}/providers/apps/Deployment/${postgresql.metadata.name}'
  ]
  values: {
    host: '${svc.metadata.name}.${svc.metadata.namespace}.svc.cluster.local'
    port: port
    database: database
    username: user
  }
  secrets: {
    #disable-next-line outputs-should-not-contain-secrets
    password: password
  }
}
