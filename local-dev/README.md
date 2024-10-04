## local-dev

The [local-dev](/local-dev) directory contains lightweight Recipes for development purposes. They run containerized infrastructure which is not persisted across restarts and is optimized for CPU and memory usage on a local machine.

> **Note**: These Recipes are automatically installed via `rad init`

| Recipe | Resource | Description | Template Path |
|--------|----------|-------------|---------------|
| [`local-dev/daprconfigurationstores`](/local-dev/daprconfigurationstores.bicep) | `Applications.Dapr/configurationStores` | A lightweight container running the `redis` image and a Redis Dapr Configuration Store component for development purposes. | `ghcr.io/radius-project/recipes/local-dev/daprconfigurationstores:TAG` |
| [`local-dev/daprpubsubbrokers`](/local-dev/daprpubsubbrokers.bicep) | `Applications.Dapr/pubSubBrokers` | A lightweight container running the `redis` image and a Redis Dapr Pub/Sub component for development purposes. | `ghcr.io/radius-project/recipes/local-dev/daprpubsubbrokers:TAG` |
| [`local-dev/daprstatestores`](/local-dev/daprstatestores.bicep) | `Applications.Dapr/stateStores` |A lightweight container running the `redis` image and a Redis Dapr state store component for development purposes. | `ghcr.io/radius-project/recipes/local-dev/daprstatestores:TAG` |
| [`local-dev/secretStores`](/local-dev/daprsecretstores.bicep) | `Applications.Dapr/secretStores` | A kubernetes secret store type for development purposes. | `ghcr.io/radius-project/recipes/local-dev/secretstores:TAG` |
| [`local-dev/rabbitmqmessagequeues`](/local-dev/rabbitmqmessagequeues.bicep) | `Applications.Messaging/rabbitMQQueues` |A lightweight container running the `rabbitmq` image for development purposes. | `ghcr.io/radius-project/recipes/local-dev/rabbitmqmessagequeues:TAG` |
| [`local-dev/rediscaches`](/local-dev/rediscaches.bicep) | `Applications.Datastores/redisCaches` |A lightweight container running the `redis` image for development purposes. | `ghcr.io/radius-project/recipes/local-dev/rediscaches:TAG` |
| [`local-dev/mongodatabases`](/local-dev/mongodatabases.bicep) | `Applications.Datastores/mongoDatabases` |A lightweight container running the `mongo` image for development purposes. | `ghcr.io/radius-project/recipes/local-dev/mongodatabases:TAG` |
| [`local-dev/sqldatabases`](/local-dev/sqldatabases.bicep) | `Applications.Datastores/sqlDatabases` |A lightweight container running the `azure-sql-edge` image for development purposes. | `ghcr.io/radius-project/recipes/local-dev/sqldatabases:TAG` |

## How to use these Recipes

Visit the [how-to-guide](https://docs.radapp.io/guides/recipes/howto-dev-recipes/) in Radius docs to learn how to use the local-dev recipes in your application.