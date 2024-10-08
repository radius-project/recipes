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

extension kubernetes with {
  kubeConfig: ''
  namespace: context.runtime.kubernetes.namespace
} as kubernetes

var daprType = 'secretstores.kubernetes'
var daprVersion = 'v1'

resource daprComponent 'dapr.io/Component@v1alpha1' = {
  metadata: {
    name: context.resource.name
  }
  spec: {
    type: daprType
    version: daprVersion
    metadata: []
  }
}

output result object = {
  // This workaround is needed because the deployment engine omits Kubernetes resources from its output.
  // This allows Kubernetes resources to be cleaned up when the resource is deleted.
  // Once this gap is addressed, users won't need to do this.
  resources: [
    '/planes/kubernetes/local/namespaces/${daprComponent.metadata.namespace}/providers/dapr.io/Component/${daprComponent.metadata.name}'
  ]
  values: {
    type: daprType
    version: daprVersion
    metadata: daprComponent.spec.metadata
  }
}
