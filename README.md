# Radius Community Recipes

This repo contains commonly used [Recipe](https://docs.radapp.dev/recipes) templates for Radius environments.

## Recipes

Recipes provide self-service infrastructure provisioning for developers. Developers select the resource(s) they need, and operators can configure Recipes with secure, approved, infrastructure.

## Available Recipes

### dev

The [dev](/dev) directory contains lightweight Recipes for development purposes. They run containerized infrastructure which is not persisted across restarts and is optimized for CPU and memory usage on a local machine.

| Recipe | Description | Template Path |
|--------|-------------|---------------|
| [`dev/rediscaches`](/dev/rediscaches.bicep) | A lightweight container running the `redis` image for development purposes. | `https://radius.azurecr.io/recipes/dev/rediscaches:0.21` |

### azure

The [azure](/azure) directory contains Recipes for Azure resources. They are configurable via parameters, with the default values optimizing for cost and security.

| Recipe | Description | Template Path |
|--------|-------------|---------------|
| [`azure/rediscaches`](/azure/rediscaches.bicep) | An Azure Cache for Redis resource with a configurable size and SKU. | `https://radius.azurecr.io/recipes/azure/rediscaches:0.21` |

### aws

The [aws](/aws) directory contains Recipes for AWS resources. They are configurable via parameters, with the default values optimizing for cost and security.

| Recipe | Description | Template Path |
|--------|-------------|---------------|
| [`aws/rediscaches`](/aws/rediscaches.bicep) | An AWS MemoryDB resource with a configurable size and SKU. | `https://radius.azurecr.io/recipes/aws/rediscaches:0.21` |

## Usage

To use a community recipe from this repo, simply use [`rad recipe register`](https://docs.radapp.dev/reference/cli/rad_recipe_register) with the Recipe's template path, or update your environment's Bicep definition with the Recipe:

### CLI

```bash
rad recipe register azure \
  --environment myenv \
  --template-kind bicep \ 
  --template-path "https://radius.azurecr.io/recipes/azure/rediscaches:0.21" \
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
          template-path: 'https://radius.azurecr.io/recipes/azure/rediscaches:0.21'
        }
      }
    }
  }
}
```

## Contributing

We welcome contributions to this repo! Please see our [contributing guide](/CONTRIBUTING.md) for more information.
