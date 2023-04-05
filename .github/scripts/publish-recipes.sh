#! /bin/bash
# This script is used to publish recipes to ACR

if [[ ! -z $BICEP_PATH ]]
then
    BICEP_EXECUTABLE="$BICEP_PATH/rad-bicep"
fi

echo "## Recipes published to $ACR_HOST" >> $GITHUB_STEP_SUMMARY
for RECIPE in $(find . -type f -name "*.bicep")
do
    # Get the recipe name and directory name
    # ./azure/redis-azure.bicep -> redis-azure and azure, respectively
    export FILE_NAME=$(basename $RECIPE | cut -d. -f1)
    export DIR_NAME=$(dirname $RECIPE | cut -d/ -f2)

    echo "Publishing $FILE_NAME Recipe from $RECIPE"
    echo "- $ACR_HOST/recipes/$DIR_NAME/$FILE_NAME:$REL_VERSION" >> $GITHUB_STEP_SUMMARY
    $BICEP_EXECUTABLE publish $RECIPE --target br:$ACR_HOST/recipes/$DIR_NAME/$FILE_NAME:$REL_VERSION
done
