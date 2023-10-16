#! /bin/bash

# Fail immediately if any command fails
set -e

# Get command line arguments
GHCR_ORG=$1
RECIPE_VERSION=$2

# Print usage information
function print_usage() {
    echo "Usage: $0 <GHCR_ORG> <RECIPE_VERSION>"
    echo "  Publishes all recipes in the repository to the GitHub Container Registry. Requires you to be logged into GitHub"
    echo "  GHCR_ORG: Organization name of the GitHub Container Registry. For example, radius-project"
    echo "  RECIPE_VERSION: Version of the recipe to publish. For example, 1.0"
}

# Verify that the required arguments are present
if [ -z "$GHCR_ORG" ] || [ -z "$RECIPE_VERSION" ]; then
    echo "Missing required arguments"
    print_usage
    exit 1
fi

# We create output that's intended to be consumed by the GitHub Action summary. If we're
# not running in a GitHub Action, we'll just silence the output.
if [[ -z "$GITHUB_STEP_SUMMARY" ]]; then
    GITHUB_STEP_SUMMARY=/dev/null
fi

echo "## Recipes published to ghcr.io/$GHCR_ORG" >> $GITHUB_STEP_SUMMARY
for RECIPE in $(find . -type f -name "*.bicep")
do
    # Get the platform (file) name and resource (directory) name
    export FILE_NAME=$(basename $RECIPE | cut -d. -f1) # rediscaches
    export DIR_NAME=$(dirname $RECIPE | cut -d/ -f2)   # dev

    echo "Publishing $DIR_NAME/$FILE_NAME to ghcr.io/$GHCR_ORG from $RECIPE"
    echo "- ghcr.io/$GHCR_ORG/recipes/$DIR_NAME/$FILE_NAME:$RECIPE_VERSION" >> $GITHUB_STEP_SUMMARY
    rad bicep publish --file $RECIPE --target "br:ghcr.io/$GHCR_ORG/recipes/$DIR_NAME/$FILE_NAME:$RECIPE_VERSION"
done
