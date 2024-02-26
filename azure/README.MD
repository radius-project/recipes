## Azure recipes

The [azure](/azure) directory contains Recipes for Azure resources. They are configurable via parameters, with the default values optimizing for cost and security.

## Available Recipes

| Recipe | Resource | Description | Template Path |
|--------|----------|-------------|---------------|
| [`azure/rediscaches`](/azure/rediscaches.bicep) | `Applications.Datastores/redisCaches` | An Azure Cache for Redis resource with a configurable size and SKU. | `ghcr.io/radius-project/recipes/azure/rediscaches:TAG` |
| [`azure/sqldatabases`](/azure/sqldatabases.bicep) | `Applications.Datastores/sqlDatabases` | An Azure SQL server resource with a configurable size and SKU. | `ghcr.io/radius-project/recipes/azure/sqldatabases:TAG` |
| [`azure/statestores`](/azure/statestores.bicep) | `Applications.Dapr/stateStores` |An Azure blob storage state store. | `ghcr.io/radius-project/recipes/azure/statestores:TAG` |

You can also contribute your own Azure recipes for the supported resource types and IaC languages. Visit the [contributions guide](/contributing/contributing-recipes.md) to learn how to write your own recipes and contribute to the community.

## Tags

1. For Azure recipes, make sure to add tags to the recipe to indicate the infrastructure deployed by Recipes is created by Radius. For example:

    ```bicep
    @description('The user-defined tags that will be applied to the resource. Default is null')
    param tags object = {}

    @description('The Radius specific tags that will be applied to the resource')
    var radiusTags = {
    'radapp.io-environment': context.environment.id
    'radapp.io-application': context.application == null ? '' : context.application.id
    'radapp.io-resource': context.resource.id
    }
    ```