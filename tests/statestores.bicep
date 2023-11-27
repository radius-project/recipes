import radius as radius

param magpieimage string

resource env 'Applications.Core/environments@2023-10-01-preview' = {
  name: 'daprrp-env-recipes-env'
  properties: {
    compute: {
      kind: 'kubernetes'
      resourceId: 'self'
      namespace: 'daprrp-env-recipes-env'
    }
    recipes: {
      'Applications.Dapr/stateStores': {
        default: {
          templateKind: 'bicep'
          plainHTTP: true
          templatePath: 'reciperegistry:5000/recipes/local-dev/statestores:latest'
        }
      }
    }
  }
}

resource app 'Applications.Core/applications@2023-10-01-preview' = {
  name: 'daprrp-rs-sts-recipe'
  properties: {
    environment: env.id
    extensions: [
      {
        kind: 'kubernetesNamespace'
        namespace: 'daprrp-rs-sts-recipe'
      }
    ]
  }
}

resource webapp 'Applications.Core/containers@2023-10-01-preview' = {
  name: 'dapr-sts-recipe-ctnr'
  properties: {
    application: app.id
    connections: {
      daprstatestore: {
        source: statestore.id
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
        appId: 'dapr-sts-recipe-ctnr'
        appPort: 3000
      }
    ]
  }
}

resource statestore 'Applications.Dapr/stateStores@2023-10-01-preview' = {
  name: 'dapr-sts-recipe'
  properties: {
    application: app.id
    environment: env.id
  }
}
