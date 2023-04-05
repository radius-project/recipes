#! /bin/bash
# This script is used to publish recipes to ACR

az acr login --name $ACR_HOST

for RECIPE in $(find . -type f -name "*.bicep")
do
    # Get the recipe name and directory name
    # ./azure/redis-azure.bicep -> redis-azure and azure, respectively
    export FILE_NAME=$(basename $RECIPE | cut -d. -f1)
    export DIR_NAME=$(dirname $RECIPE | cut -d/ -f2)

    echo "Deleting $ACR_HOST/recipes/$DIR_NAME/$FILE_NAME:1.0"
    az acr repository delete --name $ACR_HOST --image "recipes/$DIR_NAME/$FILE_NAME:1.0" --yes
done
