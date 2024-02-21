# AWS Recipes

The [aws](/aws) directory contains Recipes for AWS resources. They are configurable via parameters, with the default values optimizing for cost and security.

## Available Recipes

| Recipe | Resource | Description | Template Path |
|--------|----------|-------------|---------------|
| [`aws/rediscaches`](/aws/rediscaches.bicep) | `Applications.Datastores/redisCaches` | An AWS MemoryDB resource with a configurable size and SKU. | `ghcr.io/radius-project/recipes/aws/rediscaches:TAG` |
| [`aws/sqldatabases`](/aws/sqldatabases.bicep) | `Applications.Datastores/sqlDatabases` | An AWS RDS resource with a configurable size and SKU. | `ghcr.io/radius-project/recipes/aws/sqldatabases:TAG` |

You can also contribute your own Azure recipes for the supported resource types and IaC languages. Visit the [contributions guide](/contributing/contributing-recipes.md) to learn how to write your own recipes and contribute to the community.


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
