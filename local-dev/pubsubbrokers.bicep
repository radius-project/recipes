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

@description('Tag to pull for the redis container image.')
param tag string = '7'

@description('Memory request for the redis deployment.')
param memoryRequest string = '128Mi'

@description('Memory limit for the redis deployment')
param memoryLimit string = '1024Mi'

extension kubernetes with {
  kubeConfig: ''
  namespace: context.runtime.kubernetes.namespace
} as kubernetes

var uniqueName = 'daprpubsub-${uniqueString(context.resource.id)}'
var port = 6379

resource redis 'apps/Deployment@v1' = {
  metadata: {
    name: uniqueName
  }
  spec: {
    selector: {
      matchLabels: {
        app: 'dapr-pubsub-redis'
        resource: context.resource.name
      }
    }
    template: {
      metadata: {
        labels: {
          app: 'dapr-pubsub-redis'
          resource: context.resource.name

          // Label pods with the application name so `rad run` can find the logs.
          'radapp.io/application': context.application == null ? '' : context.application.name
        }
      }
      spec: {
        containers: [
          {
            // This container is the running redis instance.
            name: 'redis'
            image: 'redis:${tag}'
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
          }
        ]
      }
    }
  }
}

resource svc 'core/Service@v1' = {
  metadata: {
    name: uniqueName
  }
  spec: {
    type: 'ClusterIP'
    selector: {
      app: 'dapr-pubsub-redis'
      resource: context.resource.name
    }
    ports: [
      {
        port: port
      }
    ]
  }
}

var daprType = 'pubsub.redis'
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
        name: 'redisHost'
        value: '${svc.metadata.name}.${svc.metadata.namespace}.svc.cluster.local:${port}'
      }
      {
        name: 'redisPassword'
        value: ''
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
    '/planes/kubernetes/local/namespaces/${redis.metadata.namespace}/providers/apps/Deployment/${redis.metadata.name}'
    '/planes/kubernetes/local/namespaces/${daprComponent.metadata.namespace}/providers/dapr.io/Component/${daprComponent.metadata.name}'
  ]
  values: {
    type: daprType
    version: daprVersion
    metadata: daprComponent.spec.metadata
  }
}
