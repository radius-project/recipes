#!/bin/bash

# Verify each recipe's build and use its digest for immutable version tags.
set -euo pipefail

GHCR_ORG="${1:?Expected GHCR organization}"
GHCR_PATH="${2:?Expected recipe repository path}"
RECIPE_VERSION="${3:?Expected edge, PR, or full release version}"
SOURCE_SHA="${GITHUB_SHA:?GITHUB_SHA is required}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUMMARY="${GITHUB_STEP_SUMMARY:-/dev/null}"

echo "## Recipes published to ghcr.io/$GHCR_ORG/$GHCR_PATH" >>"$SUMMARY"
while IFS= read -r -d '' recipe; do
    file_name="$(basename "$recipe" .bicep)"
    directory="${recipe#./}"
    directory="${directory%%/*}"
    repository="ghcr.io/$GHCR_ORG/$GHCR_PATH/$directory/$file_name"

    digest="$(bash "$SCRIPT_DIR/recipe-oci.sh" publish \
        "$recipe" "$repository" "$SOURCE_SHA" "$RECIPE_VERSION")"
    echo "- $repository:$RECIPE_VERSION ($digest)" >>"$SUMMARY"
    if [[ -n "${RECIPE_SUBJECTS_FILE:-}" ]]; then
        printf '%s  %s\n' "${digest#sha256:}" "$repository" >>"$RECIPE_SUBJECTS_FILE"
    fi
done < <(find . -type f -name '*.bicep' -print0)
