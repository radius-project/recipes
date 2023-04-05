#! /bin/bash
# This script is used to publish recipes to ACR

echo "## Recipes published to $ACR_HOST" >> $GITHUB_STEP_SUMMARY
for RECIPE in $(find . -type f -name "*.bicep")
do
    export FILE_NAME=$(basename $RECIPE | cut -d. -f1)
    export DIR_NAME=$(dirname $RECIPE | cut -d/ -f2)
    echo "Publishing $FILE_NAME Recipe from $RECIPE"
    echo "- `$ACR_HOST/recipes/$DIR_NAME/$FILE_NAME:$REL_VERSION`" >> $GITHUB_STEP_SUMMARY
    ./rad-bicep publish $RECIPE --target br:$ACR_HOST/recipes/$DIR_NAME/$FILE_NAME:$REL_VERSION
done
