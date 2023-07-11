# Radius Community Recipes

This repo contains commonly used [Recipe](https://docs.radapp.dev/recipes) templates for Radius environments.

## Recipes

Recipes provide self-service infrastructure provisioning for developers. Developers select the resource(s) they need, and operators can configure Recipes with secure, approved, infrastructure.

## Available Recipes

### dev

The [dev](/dev) directory contains lightweight Recipes for development purposes. They run containerized infrastructure which is not persisted across restarts and is optimized for CPU and memory usage on a local machine.

> **Note**: These Recipes are automatically installed via `rad init`

| Recipe | Description | Template Path |
|--------|-------------|---------------|
| [`dev/daprstatestores`](/dev/daprstatestores.bicep) | A lightweight container running the `redis` image and a Redis Dapr state store component for development purposes. | `radius.azurecr.io/recipes/dev/daprstatestores:TAG` |
| [`dev/rabbitmqmessagequeues`](/dev/rabbitmqmessagequeues.bicep) | A lightweight container running the `rabbitmq` image for development purposes. | `radius.azurecr.io/recipes/dev/rabbitmqmessagequeues:TAG` |
| [`dev/rediscaches`](/dev/rediscaches.bicep) | A lightweight container running the `redis` image for development purposes. | `radius.azurecr.io/recipes/dev/rediscaches:TAG` |
| [`dev/mongodatabases`](/dev/mongodatabases.bicep) | A lightweight container running the `mongo` image for development purposes. | `radius.azurecr.io/recipes/dev/mongodatabases:TAG` |
| [`dev/sqldatabases`](/dev/sqldatabases.bicep) | A lightweight container running the `azure-sql-edge` image for development purposes. | `radius.azurecr.io/recipes/dev/sqldatabases:TAG` |

### azure

The [azure](/azure) directory contains Recipes for Azure resources. They are configurable via parameters, with the default values optimizing for cost and security.

| Recipe | Description | Template Path |
|--------|-------------|---------------|
| [`azure/rediscaches`](/azure/rediscaches.bicep) | An Azure Cache for Redis resource with a configurable size and SKU. | `radius.azurecr.io/recipes/azure/rediscaches:TAG` |

### aws

The [aws](/aws) directory contains Recipes for AWS resources. They are configurable via parameters, with the default values optimizing for cost and security.

| Recipe | Description | Template Path |
|--------|-------------|---------------|
| [`aws/rediscaches`](/aws/rediscaches.bicep) | An AWS MemoryDB resource with a configurable size and SKU. | `radius.azurecr.io/recipes/aws/rediscaches:TAG` |

## Versioning and Tags

Recipes are versioned using [semantic versioning](https://semver.org/). Each Recipe is tagged with its version number, and the `latest` tag points to the latest version of each Recipe. For example, Radius v0.21 uses the `0.21` tag for each Recipe:

```
radius.azurecr.io/recipes/azure/rediscaches:0.21
```

### Patching

Patched versions of Recipes are tagged with the patch number, e.g. `0.21.1`. When the tag is created for a patch, the patch and minor tags are updated to point to the new patch version. For example, if `0.21.1` is released, the `0.21` and `0.21.1` tags will be pushed. Consumers of `0.21` will automatically receive the patch update. It is recommended to use the minor tag when consuming Recipes, e.g. `0.21`.

## Usage

To use a community recipe from this repo, simply use [`rad recipe register`](https://docs.radapp.dev/reference/cli/rad_recipe_register) with the Recipe's template path, or update your environment's Bicep definition with the Recipe:

### CLI

```bash
rad recipe register azure \
  --environment myenv \
  --template-kind bicep \ 
  --template-path "radius.azurecr.io/recipes/azure/rediscaches:TAG" \
  --resource-type "Applications.Link/redisCaches"
```

### Bicep

```bicep
import radius as rad

resource myenv 'Applications.Core/environments' = {
  name: 'myenv'
  properties: {
    compute: {...}
    recipes: {
      'Applications.Core/redisCaches': {
        'azure': {
          template-kind: 'bicep'
          template-path: 'radius.azurecr.io/recipes/azure/rediscaches:0.21'
        }
      }
    }
  }
}
```

For more information on using Recipes refer to the [Radius docs](https://docs.radapp.dev/author-apps/recipes).

## Contributing

We welcome contributions to this repo! Please see our [contributing guide](/CONTRIBUTING.md) for more information.

## Code of Conduct

Please refer to our [Radius Community Code of Conduct](https://github.com/project-radius/radius/blob/main/CODE_OF_CONDUCT.md)
