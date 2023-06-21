@description('Information about what resource is calling this Recipe. Generated by Radius. For more information visit https://docs.radapp.dev/operations/custom-recipes/')
param context object

import kubernetes as kubernetes {
  kubeConfig: ''
  namespace: context.runtime.kubernetes.namespace
}

var uniqueName = 'daprpubsub-${uniqueString(context.resource.id)}'
var port = 6379

resource redis 'apps/Deployment@v1' = {
  metadata: {
    name: uniqueName
  }
  spec: {
    selector: {
      matchLabels: {
        app: 'dapr-redis'
        resource: context.resource.name
      }
    }
    template: {
      metadata: {
        labels: {
          app: 'redis'
          resource: context.resource.name

          // Label pods with the application name so `rad run` can find the logs.
          'radius.dev/application': context.application == null ? '' : context.application.name
        }
      }
      spec: {
        containers: [
          {
            // This container is the running redis instance.
            name: 'redis'
            image: 'redis:6.2'
            ports: [
              {
                containerPort: port
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
  }
  spec: {
    type: 'ClusterIP'
    selector: {
      app: 'dapr-redis'
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
        value: '${svc.metadata.name}.${svc.metadata.namespace}.svc.cluster.local'
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
    '/planes/kubernetes/local/namespaces/${daprComponent.metadata.namespace}/providers/apps/Deployment/${daprComponent.metadata.name}'
  ]
  values: {
    type: daprType
    version: daprVersion
    metadata: daprComponent.spec.metadata
  }
}