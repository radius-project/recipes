#! /bin/bash

# Fail immediately if any command fails
set -e

# Get command line arguments
BICEP_PATH=$1
GHCR_ORG=$2
RECIPE_VERSION=$3

BICEP_EXECUTABLE="$BICEP_PATH/rad-bicep"

# Print usage information
function print_usage() {
    echo "Usage: $0 <BICEP_PATH> <GHCR_ORG> <RECIPE_VERSION>"
    echo "  Publishes all recipes in the repository to the Azure Container Registry. Requires you to be logged into GitHub"
    echo "  BICEP_PATH: Path to the bicep executable. For example, ~/.rad/bin"
    echo "  GHCR_ORG: Organization name of the GitHub Container Registry. For example, radius-project"
    echo "  RECIPE_VERSION: Version of the recipe to publish. For example, 1.0"
}

# Verify that the required arguments are present
if [ -z "$BICEP_PATH" ] || [ -z "$GHCR_ORG" ] || [ -z "$RECIPE_VERSION" ]; then
    echo "Missing required arguments"
    print_usage
    exit 1
fi

echo "## Recipes published to ghcr.io/$GHCR_ORG" >> $GITHUB_STEP_SUMMARY
for RECIPE in $(find . -type f -name "*.bicep")
do
    # Get the platform (file) name and resource (directory) name
    export FILE_NAME=$(basename $RECIPE | cut -d. -f1) # rediscaches
    export DIR_NAME=$(dirname $RECIPE | cut -d/ -f2)   # dev

    echo "Publishing $DIR_NAME/$FILE_NAME to ghcr.io/$GHCR_ORG from $RECIPE"
    echo "- ghcr.io/$GHCR_ORG/recipes/$DIR_NAME/$FILE_NAME:$RECIPE_VERSION" >> $GITHUB_STEP_SUMMARY
    $BICEP_EXECUTABLE publish $RECIPE --target "br:ghcr.io/$GHCR_ORG/recipes/$DIR_NAME/$FILE_NAME:$RECIPE_VERSION"
done
