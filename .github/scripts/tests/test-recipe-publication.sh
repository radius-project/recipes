#!/bin/bash

# Offline recipe publication and version tests using only Bash and jq.
set -euo pipefail
SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HELPER="$SCRIPTS/recipe-oci.sh"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/recipe-publication-tests-XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT
REPOSITORY=ghcr.io/example/recipes/demo
SOURCE=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
DIGEST="sha256:$(printf '1%.0s' {1..64})"
OLDER="sha256:$(printf '2%.0s' {1..64})"
NEWER="sha256:$(printf '3%.0s' {1..64})"
CASES=0

mkdir -p "$TEST_ROOT/bin"
cat >"$TEST_ROOT/bin/oras" <<'EOF'
#!/bin/bash
set -euo pipefail
state="${REGISTRY_STATE:?}"
tool="${0##*/}"
call="$(jq -cn --args '$ARGS.positional' -- "$tool" "$@")"
jq --argjson call "$call" '.calls += [$call]' "$state" >"$state.tmp"
mv "$state.tmp" "$state"
error() { echo "$*" >&2; exit 1; }
write_tag() {
    jq --arg ref "$1" --arg digest "$2" '.tags[$ref] = $digest' "$state" >"$state.tmp"
    mv "$state.tmp" "$state"
}
if [[ "$tool" == rad ]]; then
    if jq -e '.build_error == true' "$state" >/dev/null; then
        error "Bicep compilation failed"
    fi
    while (($#)); do
        if [[ "$1" == --target ]]; then
            target="${2#br:}"
            digest="$(jq -r '.build_digest' "$state")"
            write_tag "$target" "$(jq -r '.staged_digest // .build_digest' "$state")"
            jq -r --arg output "Pushed to ${target%:*}@$digest" \
                '.build_output // $output' "$state"
            exit
        fi
        shift
    done
    error "Missing publication target"
fi
case "${1:-}" in
resolve)
    if message="$(jq -er --arg ref "$2" '.resolve_errors[$ref] // empty' "$state")"; then
        error "$message"
    fi
    if digest="$(jq -er --arg ref "$2" '.tags[$ref] // empty' "$state")"; then
        echo "$digest"
    else
        error "Error response from registry: $2: not found"
    fi
    ;;
repo)
    [[ "${2:-} ${4:-} ${5:-}" == "tags --format json" ]] || error "Expected native ORAS --format json"
    if message="$(jq -er '.list_error // empty' "$state")"; then
        error "$message"
    fi
    if jq -e '.invalid_list == true' "$state" >/dev/null; then
        echo '{}'
    else
        jq --arg prefix "$3:" '{tags: [.tags | keys[] | select(startswith($prefix)) | ltrimstr($prefix)]}' "$state"
    fi
    ;;
tag)
    fault="$(jq -r '.tag_fault // empty' "$state")"
    [[ "$fault" != before ]] || error "Registry connection failed before write"
    repository="${2%@*}"
    digest="${2##*@}"
    shift 2
    for tag in "$@"; do write_tag "$repository:$tag" "$digest"; done
    [[ "$fault" != after ]] || error "Registry response lost after write"
    ;;
*) error "Unexpected invocation: $*" ;;
esac
EOF
cp "$TEST_ROOT/bin/oras" "$TEST_ROOT/bin/rad"
chmod +x "$TEST_ROOT/bin/oras" "$TEST_ROOT/bin/rad"
export PATH="$TEST_ROOT/bin:$PATH"

fail() {
    echo "FAIL ($CASE_NAME): $*" >&2
    exit 1
}
new_case() {
    CASE_NAME="$1"
    ((++CASES))
    CASE_ROOT="$TEST_ROOT/$CASES"
    mkdir "$CASE_ROOT"
    export REGISTRY_STATE="$CASE_ROOT/state.json"
    jq -n --arg digest "$DIGEST" '{tags:{}, calls:[], build_digest:$digest}' >"$REGISTRY_STATE"
    SUBJECTS="$CASE_ROOT/subjects.txt"
    printf '%s  %s\n' "${DIGEST#sha256:}" "$REPOSITORY" >"$SUBJECTS"
}
change() {
    jq "$@" "$REGISTRY_STATE" >"$REGISTRY_STATE.tmp"
    mv "$REGISTRY_STATE.tmp" "$REGISTRY_STATE"
}
seed() { change --arg ref "$REPOSITORY:$1" --arg digest "$2" ".tags[\$ref] = \$digest"; }
tag_is() {
    [[ "$(jq -r --arg ref "$REPOSITORY:$1" '.tags[$ref]' "$REGISTRY_STATE")" == "$2" ]] ||
        fail "unexpected digest for $1"
}
writes() { jq '[.calls[] | select(.[0] == "rad" or .[0:2] == ["oras","tag"])] | length' "$REGISTRY_STATE"; }
tag_writes() { jq '[.calls[] | select(.[0:2] == ["oras","tag"])] | length' "$REGISTRY_STATE"; }
run_helper() {
    if STDOUT="$(bash "$HELPER" "$@" 2>"$CASE_ROOT/stderr")"; then STATUS=0; else STATUS=$?; fi
    RESULT="$STDOUT$(<"$CASE_ROOT/stderr")"
}
publish() { run_helper publish recipe.bicep "$REPOSITORY" "$SOURCE" "$@"; }
promote() { run_helper promote "${1:-0.62.1}" "$SUBJECTS" "${2:-0.62}"; }
success() { [[ "$STATUS" == 0 ]] || fail "$RESULT"; }
failure() { [[ "$STATUS" != 0 && "$RESULT" == *"$1"* ]] || fail "expected failure '$1': $RESULT"; }
no_writes() { [[ "$(writes)" == 0 ]] || fail "unexpected registry writes"; }

new_case main
seed latest "$OLDER"
seed 0.62 "$OLDER"
publish edge
success
[[ "$STDOUT" == "$DIGEST" ]] || fail "publisher output must be one digest"
tag_is edge "$DIGEST"
tag_is latest "$OLDER"
tag_is 0.62 "$OLDER"

new_case retry
publish "$SOURCE" 0.62.1
success
before="$(tag_writes)"
publish "$SOURCE" 0.62.1
success
[[ "$(tag_writes)" == "$before" ]] || fail "retry retagged identical content"
[[ "$(jq '[.calls[] | select(.[0] == "rad")] | length' "$REGISTRY_STATE")" == 2 ]] ||
    fail "retry trusted the source tag without rebuilding"

for tag in edge 0.62.1 "$SOURCE"; do
    new_case tampered_source
    seed "$SOURCE" "$OLDER"
    seed edge "$OLDER"
    seed latest "$OLDER"
    seed 0.62.1 "$OLDER"
    publish "$tag"
    failure "conflicting digest"
    [[ -z "$STDOUT" ]] || fail "unverified digest returned for attestation"
    [[ "$(tag_writes)" == 0 ]] || fail "tampered content was tagged"
    tag_is "$SOURCE" "$OLDER"
    tag_is edge "$OLDER"
    tag_is latest "$OLDER"
    tag_is 0.62.1 "$OLDER"
done

new_case staging_readback
change --arg digest "$OLDER" ".staged_digest = \$digest"
publish edge
failure "Staged recipe digest"
[[ -z "$STDOUT" && "$(tag_writes)" == 0 ]] ||
    fail "registry digest replaced the locally built digest"

for output in '' "Pushed to ghcr.io/untrusted/recipe@$DIGEST" \
    "Pushed to $REPOSITORY@sha256:1234" \
    "Pushed to $REPOSITORY@$DIGEST"$'\n'"Pushed to $REPOSITORY@$OLDER"; do
    new_case invalid_build_output
    change --arg output "$output" ".build_output = \$output"
    publish edge
    failure "build digest"
    [[ -z "$STDOUT" && "$(tag_writes)" == 0 ]] ||
        fail "invalid publisher output was trusted"
done

new_case immutable_conflict
seed "$SOURCE" "$DIGEST"
seed 0.62.1 "$OLDER"
publish 0.62.1
failure "conflicting digest"
[[ "$(tag_writes)" == 0 ]] || fail "immutable conflict changed a tag"
tag_is 0.62.1 "$OLDER"

for tag in latest 0.62 'bad tag' "$(printf 'a%.0s' {1..129})"; do
    new_case invalid_tag
    publish "$tag"
    [[ "$STATUS" != 0 ]] || fail "accepted $tag"
    no_writes
done

for message in 'manifest unknown: HTTP 401 unauthorized' \
    'manifest unknown: HTTP 403 forbidden' 'manifest unknown: denied' 'TLS handshake timeout'; do
    new_case lookup_failure
    change --arg ref "$REPOSITORY:$SOURCE" --arg message "$message" ".resolve_errors[\$ref] = \$message"
    publish edge
    failure "$message"
    no_writes
done

new_case malformed_digest
seed "$SOURCE" sha256:1234
publish edge
failure "Invalid digest"
no_writes

new_case build_failure
seed "$SOURCE" "$DIGEST"
seed edge "$OLDER"
seed latest "$OLDER"
change '.build_error = true'
publish edge
failure "Bicep compilation failed"
tag_is edge "$OLDER"
tag_is latest "$OLDER"

new_case prerelease_staging
seed edge "$OLDER"
seed latest "$OLDER"
publish 0.63.0-rc.1
success
tag_is 0.63.0-rc.1 "$DIGEST"
tag_is edge "$OLDER"
tag_is latest "$OLDER"

new_case stable_promotion
seed 0.62.1 "$DIGEST"
seed latest "$OLDER"
seed 0.62 "$OLDER"
seed edge "$NEWER"
promote
success
tag_is latest "$DIGEST"
tag_is 0.62 "$DIGEST"
tag_is edge "$NEWER"
[[ "$(jq '[.calls[] | select(.[0] == "rad")] | length' "$REGISTRY_STATE")" == 0 ]] || fail "promotion rebuilt content"

new_case older_line
seed 0.62.1 "$DIGEST"
seed 0.63.0 "$NEWER"
seed latest "$NEWER"
seed 0.62 "$OLDER"
promote
success
tag_is latest "$NEWER"
tag_is 0.62 "$DIGEST"

new_case older_same_line
seed 0.62.1 "$DIGEST"
seed 0.62.2 "$NEWER"
seed latest "$NEWER"
seed 0.62 "$NEWER"
promote
success
no_writes
[[ "$RESULT" == *"newer version 0.62.2"* ]] || fail "missing skip reason"

new_case channel_boundary
seed 0.62.1 "$DIGEST"
seed 10.62.2 "$NEWER"
seed latest "$NEWER"
promote
success
tag_is 0.62 "$DIGEST"
tag_is latest "$NEWER"

new_case numeric_order
seed 0.62.10 "$DIGEST"
seed 0.62.9 "$OLDER"
seed 99.0.0-rc.1 "$NEWER"
promote 0.62.10 0.62
success
tag_is latest "$DIGEST"

new_case no_rc_promotion
promote 0.63.0-rc.1
failure "stable full version"
no_writes

new_case subject_digest
seed 0.62.1 "$OLDER"
promote
failure "Full-version digest changed"
no_writes

for subject in '' $'\n' 'invalid subject' "${DIGEST#sha256:}  $REPOSITORY extra"; do
    new_case invalid_subject
    printf '%s' "$subject" >"$SUBJECTS"
    promote
    [[ "$STATUS" != 0 ]] || fail "accepted malformed subjects"
    no_writes
done

new_case listing_failure
seed 0.62.1 "$DIGEST"
change '.list_error = "HTTP 403 forbidden"'
promote
failure "HTTP 403 forbidden"
no_writes

new_case malformed_listing
seed 0.62.1 "$DIGEST"
change '.invalid_list = true'
promote
failure "Invalid registry tag listing"
no_writes

new_case lost_response
seed 0.62.1 "$DIGEST"
change '.tag_fault = "after"'
promote
success
tag_is latest "$DIGEST"
before="$(writes)"
promote
success
[[ "$(writes)" == "$before" ]] || fail "reconciled retry wrote again"

new_case failed_write
seed 0.62.1 "$DIGEST"
seed latest "$OLDER"
seed 0.62 "$OLDER"
change '.tag_fault = "before"'
promote
failure "did not resolve"
tag_is latest "$OLDER"

new_case publisher_subjects
mkdir -p "$CASE_ROOT/checkout with spaces/local-dev"
echo "param context object" >"$CASE_ROOT/checkout with spaces/local-dev/demo.bicep"
: >"$SUBJECTS"
(
    cd "$CASE_ROOT/checkout with spaces"
    GITHUB_SHA="$SOURCE" RECIPE_SUBJECTS_FILE="$SUBJECTS" \
        bash "$SCRIPTS/publish-recipes.sh" example recipes 0.62.1
) || fail "publisher failed"
[[ "$(<"$SUBJECTS")" == "${DIGEST#sha256:}  ghcr.io/example/recipes/local-dev/demo" ]] ||
    fail "wrong attestation subject"

new_case publisher_rejects_tampered_subject
mkdir -p "$CASE_ROOT/checkout/local-dev"
echo "param context object" >"$CASE_ROOT/checkout/local-dev/demo.bicep"
change --arg ref "ghcr.io/example/recipes/local-dev/demo:$SOURCE" \
    --arg digest "$OLDER" ".tags[\$ref] = \$digest"
: >"$SUBJECTS"
if (
    cd "$CASE_ROOT/checkout"
    GITHUB_SHA="$SOURCE" RECIPE_SUBJECTS_FILE="$SUBJECTS" \
        bash "$SCRIPTS/publish-recipes.sh" example recipes 0.62.1
) >"$CASE_ROOT/output" 2>&1; then
    fail "publisher accepted substituted source content"
fi
grep -Fq 'conflicting digest' "$CASE_ROOT/output" || fail "wrong rejection reason"
[[ ! -s "$SUBJECTS" ]] || fail "unverified content was recorded for attestation"

while IFS='|' read -r ref version channel tag stable; do
    new_case "version:$ref"
    env_file="$CASE_ROOT/github-env"
    GITHUB_REF="$ref" GITHUB_ENV="$env_file" bash "$SCRIPTS/get-release-version.sh" >/dev/null ||
        fail "valid ref rejected"
    for expected in "REL_VERSION=$version" "REL_CHANNEL=$channel" "REL_TAG=$tag" "UPDATE_RELEASE=$stable"; do
        grep -Fxq "$expected" "$env_file" || fail "missing $expected"
    done
done <<'CASES'
refs/heads/main|edge|edge|edge|false
refs/tags/v0.62.1|0.62.1|0.62|0.62.1|true
refs/tags/v0.63.0-rc.1|0.63.0-rc.1|0.63.0-rc.1|0.63.0-rc.1|false
refs/tags/v0.63.0-rc1|0.63.0-rc1|0.63.0-rc1|0.63.0-rc1|false
refs/tags/v0.63.0-beta.2|0.63.0-beta.2|0.63.0-beta.2|0.63.0-beta.2|false
refs/pull/12/merge|pr-12|edge|pr-12|false
refs/pull/12/head|pr-12|edge|pr-12|false
|edge|edge|local|false
CASES

for ref in refs/tags/v0 refs/tags/v0.62 refs/tags/v0.62.1+metadata \
    refs/tags/v01.2.3 refs/tags/v1.2.3-rc.01 refs/heads/feature \
    refs/tags/v1.2.3-rc..1 refs/tags/v1.2.3-; do
    new_case "invalid_version:$ref"
    if GITHUB_REF="$ref" GITHUB_ENV="$CASE_ROOT/github-env" \
        bash "$SCRIPTS/get-release-version.sh" >"$CASE_ROOT/output" 2>&1; then
        fail "invalid ref accepted"
    fi
    [[ ! -s "$CASE_ROOT/github-env" ]] || fail "invalid ref wrote publication metadata"
done

new_case workflow_contract
workflow="$SCRIPTS/../workflows/publish-recipes.yaml"
for expected in \
    'queue: max' \
    'needs: [publish-public, attest-public]' \
    "if: needs.publish-public.outputs.stable == 'true'" \
    "publish-recipes.sh radius-project recipes \"\$tag\"" \
    "tag=\"\$GITHUB_SHA\""; do
    grep -Fq "$expected" "$workflow" || fail "missing workflow contract: $expected"
done
grep -Eq '^  group: publish-recipes$' "$workflow" ||
    fail "publication must use one shared concurrency group"
[[ "$(grep -Fc 'id-token: write' "$workflow")" == 1 ]] || fail "signing permissions leaked"
if grep -Eq 'python|get_release_version[.]py' "$workflow"; then
    fail "workflow still invokes Python"
fi

echo "Recipe publication tests passed ($CASES cases)"
