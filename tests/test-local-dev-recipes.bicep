import radius as radius

@description('Specifies the image for the container resource.')
param magpieimage string

@description('The OCI registry for test Bicep recipes.')
param registry string 

@description('The OCI tag for test Bicep recipes.')
param version string

import kubernetes as kubernetes {
  namespace: 'daprrp-rs-secretstore-recipe'
  kubeConfig: ''
}

resource env 'Applications.Core/environments@2023-10-01-preview' = {
  name: 'local-dev-recipe-env'
  location: 'global'
  properties: {
    compute: {
      kind: 'kubernetes'
      resourceId: 'self'
      namespace: 'local-dev-recipe-env'
    }
    recipes: {
      'Applications.Datastores/mongoDatabases':{
        mongoazure: {
          templateKind: 'bicep'
          plainHTTP: true
          templatePath: '${registry}/recipes/local-dev/mongodatabases:${version}'
        }
      }
      'Applications.Dapr/pubSubBrokers': {
        default: {
          templateKind: 'bicep'
          plainHTTP: true
          templatePath: '${registry}/recipes/local-dev/pubsubbrokers:${version}'
        }
      }
      'Applications.Messaging/rabbitMQQueues': {
        default: {
          templateKind: 'bicep'
          plainHTTP: true
          templatePath: '${registry}/recipes/local-dev/rabbitmqqueues:${version}'
        }
      }
      'Applications.Datastores/redisCaches':{
        default: {
          templateKind: 'bicep'
          plainHTTP: true
          templatePath: '${registry}/recipes/local-dev/rediscaches:${version}'
        }
      }
      'Applications.Dapr/secretStores': {
        default: {
          templateKind: 'bicep'
          plainHTTP: true
          templatePath: '${registry}/recipes/local-dev/secretstores:${version}'
        }
      }
      'Applications.Datastores/sqlDatabases': {
        default: {
          templateKind: 'bicep'
          plainHTTP: true
          templatePath: '${registry}/recipes/local-dev/sqldatabases:${version}'
        }
      }
      'Applications.Dapr/stateStores': {
        default: {
          templateKind: 'bicep'
          plainHTTP: true
          templatePath: '${registry}/recipes/local-dev/statestores:${version}'
        }
      }
    }
  }
}

resource app 'Applications.Core/applications@2023-10-01-preview' = {
  name: 'local-dev-recipe-app'
  location: 'global'
  properties: {
    environment: env.id
    extensions: [
      {
          kind: 'kubernetesNamespace'
          namespace: 'local-dev-recipe-app'
      }
    ]
  }
}

resource webapp 'Applications.Core/containers@2023-10-01-preview' = {
  name: 'mongodb-app-ctnr'
  location: 'global'
  properties: {
    application: app.id
    connections: {
      mongodb: {
        source: recipedb.id
      }
      daprpubsub: {
        source: pubsubBroker.id
      }
      rabbitmq: {
        source: rabbitmq.id
      }
      redis: {
        source: redis.id
      }
      daprsecretstore: {
        source: secretstore.id
      }
      sql: {
        source: db.id
        disableDefaultEnvVars: true
      }
      daprstatestore: {
        source: statestore.id
      }
    }
    container: {
      image: magpieimage
      readinessProbe:{
        kind:'httpGet'
        containerPort:3000
        path: '/healthz'
      }
    }
    extensions: [
      {
        kind: 'daprSidecar'
        appId: 'dpsb-recipe-app-ctnr'
        appPort: 3000
      }
    ]
  }
}

resource recipedb 'Applications.Datastores/mongoDatabases@2023-10-01-preview' = {
  name: 'mongodb-db'
  properties: {
    application: app.id
    environment: env.id
    recipe: {
      name: 'mongoazure'
    }
  }
}

resource pubsubBroker 'Applications.Dapr/pubSubBrokers@2023-10-01-preview' = {
  name: 'dpsb-recipe'
  properties: {
    application: app.id
    environment: env.id
  }
}

resource rabbitmq 'Applications.Messaging/rabbitMQQueues@2023-10-01-preview' = {
  name: 'rmq-recipe-resource'
  properties: {
    application: app.id
    environment: env.id
  }
}

resource redis 'Applications.Datastores/redisCaches@2023-10-01-preview' = {
  name: 'rds-recipe'
  properties: {
    environment: env.id
    application: app.id
  }
}

resource secretstore 'Applications.Dapr/secretStores@2023-10-01-preview' = {
  name: 'gnrc-scs-recipe'
  properties: {
    environment: env.id
    application: app.id
  }
}

resource mysecret 'core/Secret@v1' = {
  metadata: {
    name: 'mysecret'
    namespace: 'local-dev-recipe-app'
  }
  type: 'opaque'
  data: {}
}

resource db 'Applications.Datastores/sqlDatabases@2023-10-01-preview' = {
  name: 'sql-db-recipe'
  properties: {
    application: app.id
    environment: env.id
  }
}

resource statestore 'Applications.Dapr/stateStores@2023-10-01-preview' = {
  name: 'dapr-sts-recipe'
  properties: {
    application: app.id
    environment: env.id
  }
}
