#!/bin/bash

# Copyright 2023 The Radius Authors.
# SPDX-License-Identifier: Apache-2.0

# Select recipe publication tags from the current GitHub ref.
set -euo pipefail
: "${GITHUB_ENV:?GITHUB_ENV is required}"

version=edge
channel=edge
tag=edge
stable=false
number='(0|[1-9][0-9]*)'

case "${GITHUB_REF:-}" in
"") tag=local ;;
refs/heads/main) ;;
refs/pull/*)
    [[ "$GITHUB_REF" =~ ^refs/pull/([0-9]+)/(head|merge)$ ]] || {
        echo "Invalid pull request ref: $GITHUB_REF" >&2
        exit 1
    }
    version="pr-${BASH_REMATCH[1]}"
    tag="$version"
    ;;
refs/tags/v*)
    version="${GITHUB_REF#refs/tags/v}"
    core="${version%%-*}"
    [[ "$core" =~ ^${number}\.${number}\.${number}$ ]] || {
        echo "Expected a full semantic version: $GITHUB_REF" >&2
        exit 1
    }
    if [[ "$version" == *-* ]]; then
        prerelease="${version#*-}"
        [[ "$prerelease" =~ ^[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*$ ]] || {
            echo "Invalid prerelease: $version" >&2
            exit 1
        }
        IFS=. read -r -a identifiers <<<"$prerelease"
        for identifier in "${identifiers[@]}"; do
            if [[ "$identifier" =~ ^[0-9]+$ && "$identifier" =~ ^0[0-9]+$ ]]; then
                echo "Prerelease numbers cannot have leading zeroes: $version" >&2
                exit 1
            fi
        done
        channel="$version"
    else
        channel="${version%.*}"
        stable=true
    fi
    tag="$version"
    ;;
*)
    echo "Expected main, a pull request, or a full-version release tag: $GITHUB_REF" >&2
    exit 1
    ;;
esac

printf '%s\n' "UPDATE_RELEASE=$stable" "REL_VERSION=$version" \
    "REL_CHANNEL=$channel" "REL_TAG=$tag" | tee -a "$GITHUB_ENV"
