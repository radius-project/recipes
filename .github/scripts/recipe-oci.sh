#!/bin/bash

# Verify recipe content against a fresh build; promote aliases by digest.
set -euo pipefail

readonly STABLE_VERSION='(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)'

fail() {
    echo "Error: $*" >&2
    exit 1
}

resolve() {
    local reference="$1" result diagnostic
    if result="$(oras resolve "$reference" 2>&1)"; then
        [[ "$result" =~ ^sha256:[0-9a-f]{64}$ ]] ||
            fail "Invalid digest for $reference: $result"
        printf '%s\n' "$result"
        return
    fi
    diagnostic="${result//"$reference"/}"
    if grep -Eqi 'MANIFEST_UNKNOWN|manifest unknown|: not found([[:space:]]|$)' <<<"$diagnostic" &&
        ! grep -Eqi '401|403|unauthorized|denied|forbidden' <<<"$diagnostic"; then
        return 10
    fi
    echo "$result" >&2
    return 1
}

tag_digest() {
    local repository="$1" digest="$2" tag="$3" mutable="$4"
    local current status
    if current="$(resolve "$repository:$tag")"; then
        [[ "$current" != "$digest" ]] || return 0
        [[ "$mutable" == true ]] ||
            fail "Immutable tag $repository:$tag has a conflicting digest."
    else
        status=$?
        [[ "$status" == 10 ]] || return "$status"
    fi

    # A lost write response is safe only when readback proves the intended tag.
    if ! oras tag "$repository@$digest" "$tag" >&2; then
        echo "Checking the destination after an uncertain tag write." >&2
    fi
    current="$(resolve "$repository:$tag")" ||
        fail "Cannot verify $repository:$tag after tagging."
    [[ "$current" == "$digest" ]] ||
        fail "Tag $repository:$tag did not resolve to $digest."
}

publish() {
    local recipe="$1" repository="$2" source="$3"
    shift 3
    local digest tag mutable status output
    local staging="build-$source"
    [[ "$source" =~ ^[0-9a-f]{40}$ ]] || fail "A full source commit SHA is required."
    (($# > 0)) || fail "At least one destination tag is required."
    for tag in "$@"; do
        [[ "$tag" =~ ^[a-zA-Z0-9_][a-zA-Z0-9_.-]{0,127}$ ]] ||
            fail "Invalid recipe tag: $tag"
        [[ "$tag" != latest && ! "$tag" =~ ^[0-9]+\.[0-9]+$ ]] ||
            fail "Stable aliases must be promoted after verification."
    done

    resolve "$repository:$source" >/dev/null || {
        status=$?
        [[ "$status" == 10 ]] || return "$status"
    }

    # Registry SHA tags are writable. Trust the local publisher's digest,
    # not an existing source tag or a staging tag that could be substituted.
    if ! output="$(rad bicep publish --file "$recipe" --target "br:$repository:$staging")"; then
        printf '%s\n' "$output" >&2
        fail "Failed to build and publish recipe $recipe."
    fi
    printf '%s\n' "$output" >&2
    digest="$(awk -v prefix="Pushed to $repository@" \
        'index($0, prefix) == 1 { print substr($0, length(prefix) + 1) }' <<<"$output")"
    [[ "$digest" =~ ^sha256:[0-9a-f]{64}$ ]] ||
        fail "Publisher did not report one valid build digest for $repository."
    [[ "$(resolve "$repository:$staging")" == "$digest" ]] ||
        fail "Staged recipe digest does not match the local build: $repository:$staging"

    tag_digest "$repository" "$digest" "$source" false
    for tag in "$@"; do
        mutable=false
        [[ "$tag" != edge && "$tag" != pr-* ]] || mutable=true
        tag_digest "$repository" "$digest" "$tag" "$mutable"
    done
    printf '%s\n' "$digest"
}

promote() {
    local version="$1" subjects="$2" channel="${3:-}"
    local checksum repository extra digest tags stable newest alias
    local -a aliases=(latest)
    [[ "$version" =~ ^${STABLE_VERSION}$ ]] ||
        fail "Alias promotion requires a stable full version."
    [[ -s "$subjects" ]] || fail "No verified recipe subjects were supplied."
    if [[ -n "$channel" ]]; then
        [[ "$channel" == "${version%.*}" ]] || fail "Channel does not match version."
        aliases=("$channel" latest)
    fi

    while read -r checksum repository extra || [[ -n "$checksum$repository$extra" ]]; do
        [[ "$checksum" =~ ^[0-9a-f]{64}$ && "$repository" =~ ^[a-z0-9][a-z0-9./:_-]+$ &&
            -z "$extra" ]] || fail "Invalid recipe subject."
        digest="sha256:$checksum"
        [[ "$(resolve "$repository:$version")" == "$digest" ]] ||
            fail "Full-version digest changed: $repository:$version"
        tags="$(oras repo tags "$repository" --format json)"
        jq -e '.tags | type == "array" and all(.[]; type == "string")' <<<"$tags" >/dev/null ||
            fail "Invalid registry tag listing for $repository."
        stable="$(jq -r --arg pattern "^${STABLE_VERSION}$" \
            '.tags[] | select(test($pattern))' <<<"$tags")"
        for alias in "${aliases[@]}"; do
            newest="$(printf '%s\n' "$stable" "$version" |
                if [[ "$alias" == latest ]]; then
                    LC_ALL=C sort -V
                else
                    grep -E "^${channel//./\\.}\\." | LC_ALL=C sort -V
                fi | tail -n 1)"
            if [[ "$newest" != "$version" ]]; then
                echo "Keeping $repository:$alias unchanged; newer version $newest exists." >&2
                continue
            fi
            tag_digest "$repository" "$digest" "$alias" true
        done
    done <"$subjects"
}

case "${1:-}" in
publish)
    (($# >= 5)) || fail "Usage: $0 publish <file> <repository> <sha> <tag>..."
    shift
    publish "$@"
    ;;
promote)
    (($# == 3 || $# == 4)) || fail "Usage: $0 promote <version> <subjects-file> [channel]"
    shift
    promote "$@"
    ;;
*) fail "Expected publish or promote." ;;
esac
