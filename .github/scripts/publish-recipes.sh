#! /bin/bash

# Fail immedietly if any command fails
set -e

# Get command line arguments
BICEP_PATH=$1
ACR_HOST=$2
RECIPE_VERSION=$3

BICEP_EXECUTABLE="$BICEP_PATH/rad-bicep"

# Print usage information
function print_usage() {
    echo "Usage: $0 <BICEP_PATH> <ACR_HOST>"
    echo "  Publishes all recipes in the repository to the Azure Container Registry. Requires you to be logged into Azure via az login."
    echo "  BICEP_PATH: Path to the bicep executable. For example, ~/.rad/bin"
    echo "  ACR_HOST: Host name of the Azure Container Registry. For example, myregistry.azurecr.io."
    echo "  RECIPE_VERSION: Version of the recipe to publish. For example, 1.0"
}

# Verify that the required arguments are present
if [ -z "$BICEP_PATH" ] || [ -z "$ACR_HOST" ] || [ -z "$RECIPE_VERSION" ]; then
    echo "Missing required arguments"
    print_usage
    exit 1
fi

echo "## Recipes published to $ACR_HOST" >> $GITHUB_STEP_SUMMARY
for RECIPE in $(find . -type f -name "*.bicep")
do
    # Get the platform (file) name and resource (directory) name
    # ./rediscaches/aws.bicep -> aws and rediscaches, respectively
    export FILE_NAME=$(basename $RECIPE | cut -d. -f1)
    export DIR_NAME=$(dirname $RECIPE | cut -d/ -f2)

    echo "Publishing $DIR_NAME/$FILE_NAME to $ACR_HOST from $RECIPE"
    echo "- $ACR_HOST/recipes/$DIR_NAME/$FILE_NAME:$RECIPE_VERSION" >> $GITHUB_STEP_SUMMARY
    $BICEP_EXECUTABLE publish $RECIPE --target "br:$ACR_HOST/recipes/$DIR_NAME/$FILE_NAME:$RECIPE_VERSION"
done
