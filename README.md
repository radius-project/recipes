# Radius Community Recipes

This repository contains commonly used [Recipe](https://docs.radapp.io/recipes) templates for Radius Environments.

## Recipes

Recipes provide self-service infrastructure provisioning for developers. Developers select the resource(s) they need, and operators can configure Recipes with secure, approved, infrastructure. For more information about the supported resource types and the IaC languages, please refer to the [Recipes overview](https://docs.radapp.io/guides/recipes/overview/) page.

## Available Recipes

  - [Local Dev](/local-dev)
  - [Azure](/azure)
  - [AWS](/aws) 

## Versioning and Tags

Recipes are versioned using [semantic versioning](https://semver.org/). Each Recipe is tagged with its version number, and the `latest` tag points to the latest version of each Recipe. For example, Radius v0.21 uses the `0.21` tag for each Recipe:

```
ghcr.io/radius-project/recipes/azure/rediscaches:0.21
```

### Patching

Patched versions of Recipes are tagged with the patch number, e.g. `0.21.1`. When the tag is created for a patch, the patch and minor tags are updated to point to the new patch version. For example, if `0.21.1` is released, the `0.21` and `0.21.1` tags will be pushed. Consumers of `0.21` will automatically receive the patch update. It is recommended to use the minor tag when consuming Recipes, e.g. `0.21`.

## Usage

To use a community recipe from this repo, simply use [`rad recipe register`](https://docs.radapp.io/reference/cli/rad_recipe_register) with the Recipe's template path, or update your environment's Bicep definition with the Recipe:

### CLI

```bash
rad recipe register azure \
  --environment myenv \
  --template-kind bicep \ 
  --template-path "ghcr.io/radius-project/recipes/azure/rediscaches:TAG" \
  --resource-type "Applications.Datastores/redisCaches"
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
          template-path: 'ghcr.io/radius-project/recipes/azure/rediscaches:0.21'
        }
      }
    }
  }
}
```

For more information on using Recipes refer to the [Radius docs](https://docs.radapp.io/guides/recipes/overview/).

## How to Contribute to Recipes

Visit the [contributions guide](CONTRIBUTING.md) to learn how to write your own Recipes and contribute to the community.

## Code of Conduct

Please refer to our [Radius Community Code of Conduct](https://github.com/radius-project/radius/blob/main/CODE_OF_CONDUCT.md)
