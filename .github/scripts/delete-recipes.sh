#! /bin/bash

# Fail immedietly if any command fails
set -e

# Get command line arguments
ACR_HOST=$1
RECIPE_VERSION=$2

# Print usage information
function print_usage() {
    echo "Usage: $0 <ACR_HOST> <RECIPE_VERSION>"
    echo "  Deletes all recipes in the repository from the Azure Container Registry. Requires you to be logged into Azure via az login."
    echo "  ACR_HOST: Host name of the Azure Container Registry. For example, myregistry.azurecr.io."
    echo "  RECIPE_VERSION: Version of the recipe to publish. For example, 1.0"
}

# Verify that the required arguments are present
if [ -z "$ACR_HOST" ] || [ -z "$RECIPE_VERSION" ]; then
    echo "Missing required arguments"
    print_usage
    exit 1
fi

# Login to Azure Container Registry
az acr login --name $ACR_HOST

for RECIPE in $(find . -type f -name "*.bicep")
do
    # Get the recipe name and directory name
    # ./azure/redis-azure.bicep -> redis-azure and azure, respectively
    export FILE_NAME=$(basename $RECIPE | cut -d. -f1)
    export DIR_NAME=$(dirname $RECIPE | cut -d/ -f2)

    echo "Deleting $ACR_HOST/recipes/$DIR_NAME/$FILE_NAME:1.0"
    az acr repository delete --name $ACR_HOST --image "recipes/$DIR_NAME/$FILE_NAME:$RECIPE_VERSION" --yes
done
