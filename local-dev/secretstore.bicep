import radius as rad

param environment string

resource daprSecretStore 'Applications.Link/daprSecretStores@2022-03-15-privatepreview' = {
  name: 'mysecretstore'
  properties: {
    environment: environment
    application: application.id
  }
}

resource application 'Applications.Core/applications@2022-03-15-privatepreview' = {
  name: 'myapp'
  properties: {
    environment: environment 
  }
}

resource container 'Applications.Core/containers@2022-03-15-privatepreview' = {
  name: 'busybox'
  properties: {
    application: application.id 
    container: {
      image: 'ubuntu'
      command: [
        '/bin/sleep'
        '3650d'
      ]
    }
    connections: {
      secretstore: {
        source: daprSecretStore.id
      }
    }
    extensions: [
      {
        kind: 'daprSidecar'
        appId: 'app'
      }
    ]
  }
}
