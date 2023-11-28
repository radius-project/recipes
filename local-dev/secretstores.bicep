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

import kubernetes as kubernetes {
  namespace: context.runtime.kubernetes.namespace
  kubeConfig: ''
}

param context object

resource dapr 'dapr.io/Component@v1alpha1' = {
  metadata: {
    name: context.resource.name
    namespace: context.runtime.kubernetes.namespace
  }
  spec: {
    type: 'secretstores.kubernetes'
    version: 'v1'
    metadata: []
  }
}

output result object = {
  values: {
    componentName: dapr.metadata.name
  }
}
