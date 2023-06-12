@description('Information about what resource is calling this Recipe. Generated by Radius. For more information visit https://docs.radapp.dev/operations/custom-recipes/')
param context object

@description('Admin username for the Mongo database. Default is "admin"')
param username string = 'admin'

@description('Admin password for the Mongo database')
@secure()
param password string = newGuid()

import kubernetes as kubernetes {
  kubeConfig: ''
  namespace: context.runtime.kubernetes.namespace
}

var uniqueName = 'mongo-${uniqueString(context.resource.id)}'
var port = 27017

resource mongo 'apps/Deployment@v1' = {
  metadata: {
    name: uniqueName
  }
  spec: {
    selector: {
      matchLabels: {
        app: 'mongo'
        resource: context.resource.name
      }
    }
    template: {
      metadata: {
        labels: {
          app: 'mongo'
          resource: context.resource.name
        }
      }
      spec: {
        containers: [
          {
            name: 'mongo'
            image: 'mongo:4.2'
            ports: [
              {
                containerPort: port
              }
            ]
            env: [
              {
                name: 'MONGO_INITDB_ROOT_USERNAME'
                value: username
              }
              {
                name: 'MONGO_INITDB_ROOT_PASSWORD'
                value: password
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
      app: 'mongo'
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
  //
  // Once this gap is addressed, users won't need to do this.
  resources: [
    '/planes/kubernetes/local/namespaces/${svc.metadata.namespace}/providers/core/Service/${svc.metadata.name}'
    '/planes/kubernetes/local/namespaces/${mongo.metadata.namespace}/providers/apps/Deployment/${mongo.metadata.name}'
  ]
  values: {
    host: '${svc.metadata.name}.${svc.metadata.namespace}.svc.cluster.local'
    port: port
  }
  secrets: {
    // Temporarily workaround until secure outputs are added
    #disable-next-line outputs-should-not-contain-secrets
    connectionString: 'mongodb://${username}:${password}@${svc.metadata.name}.${svc.metadata.namespace}.svc.cluster.local:27017'
    username: username
    #disable-next-line outputs-should-not-contain-secrets
    password: password
  }
}
