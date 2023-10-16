#! /bin/bash

# Fail immediately if any command fails
set -e

# Get command line arguments
GHCR_ORG=$1
GHCR_PATH=$2
RECIPE_VERSION=$2

# Print usage information
function print_usage() {
    echo "Usage: $0 <GHCR_ORG> <RECIPE_VERSION>"
    echo "  Deletes all recipes in the repository from the GitHub Container Registry. Requires you to be logged into GitHub."
    echo "  GHCR_ORG: Organization name of the GitHub Container Registry. For example, radius-project"
    echo "  GHCR_PATH: Path name for Recipe storage. For example, recipes"
    echo "  RECIPE_VERSION: Version of the recipe to publish. For example, 1.0"
}

# Verify that the required arguments are present
if [ -z "$GHCR_ORG" ] || [ -z "$GHCR_PATH" ] || [ -z "$RECIPE_VERSION" ]; then
    echo "Missing required arguments"
    print_usage
    exit 1
fi

for RECIPE in $(find . -type f -name "*.bicep")
do
    # Get the recipe name and directory name
    # ./azure/redis-azure.bicep -> redis-azure and azure, respectively
    export FILE_NAME=$(basename $RECIPE | cut -d. -f1)
    export DIR_NAME=$(dirname $RECIPE | cut -d/ -f2)

    echo "Deleting ghcr.io/$GHCR_ORG/$GHCR_PATH/$DIR_NAME/$FILE_NAME:$RECIPE_VERSION"
    gh api \
        --method DELETE \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        /orgs/$GHCR_ORG/packages/container/$GHCR_PATH/$DIR_NAME/$FILE_NAME:$RECIPE_VERSION
done
