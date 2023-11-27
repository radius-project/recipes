import radius as radius

param magpieimage string

resource env 'Applications.Core/environments@2023-10-01-preview' = {
  name: 'dpsb-recipe-env'
  properties: {
    compute: {
      kind: 'kubernetes'
      resourceId: 'self'
      namespace: 'dpsb-recipe-env'
    }
    recipes: {
      'Applications.Dapr/pubSubBrokers': {
        default: {
          templateKind: 'bicep'
          plainHTTP: true
          templatePath: 'reciperegistry:5000/recipes/local-dev/pubsubbrokers:latest'
        }
      }
    }
  }
}

resource app 'Applications.Core/applications@2023-10-01-preview' = {
  name: 'dpsb-recipe-app'
  properties: {
    environment: env.id
    extensions: [
      {
        kind: 'kubernetesNamespace'
        namespace: 'dpsb-recipe-app'
      }
    ]
  }
}

resource myapp 'Applications.Core/containers@2023-10-01-preview' = {
  name: 'dpsb-recipe-app-ctnr'
  properties: {
    application: app.id
    connections: {
      daprpubsub: {
        source: pubsubBroker.id
      }
    }
    container: {
      image: magpieimage
      readinessProbe: {
        kind: 'httpGet'
        containerPort: 3000
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

resource pubsubBroker 'Applications.Dapr/pubSubBrokers@2023-10-01-preview' = {
  name: 'dpsb-recipe'
  properties: {
    application: app.id
    environment: env.id
  }
}
