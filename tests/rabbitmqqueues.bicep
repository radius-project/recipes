import radius as radius

@description('Specifies the location for resources.')
param location string = 'global'

@description('Specifies the image for the container resource.')
param magpieImage string

@description('Specifies the port for the container resource.')
param magpiePort int = 3000

@description('Specifies the RabbitMQ password.')
@secure()
param password string = 'guest'

resource env 'Applications.Core/environments@2023-10-01-preview' = {
  name: 'msgrp-resources-environment-rabbitmq-recipe-env'
  location: 'global'
  properties: {
    compute: {
      kind: 'kubernetes'
      resourceId: 'self'
      namespace: 'msgrp-resources-environment-rabbitmq-recipe-env'
    }
    recipes: {
      'Applications.Messaging/rabbitMQQueues': {
        default: {
          templateKind: 'bicep'
          plainHTTP: true
          templatePath: 'reciperegistry:5000/recipes/local-dev/rabbitmqqueues:latest'
          parameters: {
            password: password
          }
        }
      }
    }
  }
}

resource app 'Applications.Core/applications@2023-10-01-preview' = {
  name: 'msgrp-resources-rabbitmq-recipe'
  location: 'global'
  properties: {
    environment: env.id
    extensions: [
      {
        kind: 'kubernetesNamespace'
        namespace: 'msgrp-resources-rabbitmq-default-recipe-app'
      }
    ]
  }
}

resource webapp 'Applications.Core/containers@2023-10-01-preview' = {
  name: 'rmq-recipe-app-ctnr'
  location: location
  properties: {
    application: app.id
    container: {
      image: magpieImage
      readinessProbe: {
        kind: 'httpGet'
        containerPort: magpiePort
        path: '/healthz'
      }
    }
    connections: {
      rabbitmq: {
        source: rabbitmq.id
      }
    }
  }
}

resource rabbitmq 'Applications.Messaging/rabbitMQQueues@2023-10-01-preview' = {
  name: 'rmq-recipe-resource'
  location: location
  properties: {
    application: app.id
    environment: env.id
  }
}
