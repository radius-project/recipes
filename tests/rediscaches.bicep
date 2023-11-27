import radius as radius

param scope string = resourceGroup().id

resource env 'Applications.Core/environments@2023-10-01-preview' = {
  name: 'dsrp-resources-env-recipe-env'
  location: 'global'
  properties: {
    compute: {
      kind: 'kubernetes'
      resourceId: 'self'
      namespace: 'dsrp-resources-env-recipe-env' 
    }
    providers: {
      azure: {
        scope: scope
      }
    }
    recipes: {
      'Applications.Datastores/redisCaches':{
        rediscache: {
          templateKind: 'bicep'
          plainHTTP: true
          templatePath: 'reciperegistry:5000/recipes/local-dev/rediscaches:latest'
        }
      }
    }
  }
}

resource app 'Applications.Core/applications@2023-10-01-preview' = {
  name: 'dsrp-resources-redis-recipe'
  location: 'global'
  properties: {
    environment: env.id
    extensions: [
      {
          kind: 'kubernetesNamespace'
          namespace: 'dsrp-resources-redis-recipe-app'
      }
    ]
  }
}

resource redis 'Applications.Datastores/redisCaches@2023-10-01-preview' = {
  name: 'rds-recipe'
  location: 'global'
  properties: {
    environment: env.id
    application: app.id
    recipe: {
      name: 'rediscache'
    }
  }
}
