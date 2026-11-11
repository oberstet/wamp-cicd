#!/usr/bin/env bash
#
# Test that the GitHub Actions wamp-cicd itself uses are pinned, and on Node 24 (#96).
#
# Every consuming repository runs wamp-cicd's reusable workflow and composite actions `@main`,
# so a third-party action used here runs in all of them. On 2026-11-09 every job of every WAMP
# repository warned "Node.js 20 is deprecated", partly because of `actions/checkout@v4`
# (identifiers.yml) and `actions/upload-artifact@v4` (upload-artifact-verified) here.
#
# Rules, for every `uses:` in this repository's workflows and composite actions, except local
# (`./...`) and first-party (`wamp-proto/wamp-cicd/...`) refs:
#
#   1. pinned to a full 40-hex commit SHA, with the exact version as a comment
#      (`@<sha> # vX.Y.Z`): a tag can be moved, a commit cannot;
#   2. at least the first major that runs on Node 24 by default (MIN_MAJOR below).
#
# And: upload-artifact-verified uploads ZIPPED (`archive: true`). download-artifact-verified
# fetches artifacts through the REST `.../artifacts/<id>/zip` endpoint, so an unzipped upload
# (upload-artifact >= v7 with `archive: false`) would break every verified download.
#
# Reads this checkout only. No network.
#
# Run: bash tests/test-action-pins.sh
#
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${HERE}/.."

# First major running on Node 24 by default, per the actions' release notes.
declare -A MIN_MAJOR=(
    [actions/checkout]=5
    [actions/upload-artifact]=6
)

PASS=0
FAIL=0
ok()  { echo "  ok   [$1]"; PASS=$((PASS + 1)); }
bad() { echo "  FAIL [$1] $2"; FAIL=$((FAIL + 1)); }

echo "== every third-party uses: is SHA-pinned, with a version comment, on a Node 24 major"
while IFS= read -r hit; do
    file="${hit%%:*}"; rest="${hit#*:}"; line="${rest%%:*}"; text="${rest#*:}"
    ref="$(sed -E 's/^[[:space:]]*-?[[:space:]]*uses:[[:space:]]*//' <<<"$text")"
    case "$ref" in ./* | wamp-proto/wamp-cicd/*) continue ;; esac
    where="${file}:${line}"
    action="${ref%%@*}"
    if [[ "$ref" =~ ^[^@]+@[0-9a-f]{40}[[:space:]]+#[[:space:]]*v([0-9]+)\.[0-9]+\.[0-9]+[[:space:]]*$ ]]; then
        major="${BASH_REMATCH[1]}"
        ok "${where} pinned: ${ref}"
        min="${MIN_MAJOR[$action]:-}"
        if [ -z "$min" ]; then
            bad "${where}" "${action} has no MIN_MAJOR entry in this test: add one"
        elif [ "$major" -ge "$min" ]; then
            ok "${where} ${action} v${major} >= v${min} (Node 24)"
        else
            bad "${where}" "${action} v${major} < v${min}: still targets Node 20"
        fi
    else
        bad "${where}" "not pinned as @<40-hex sha> # vX.Y.Z: ${ref}"
    fi
done < <(cd "$ROOT" && grep -nE '^[[:space:]]*-?[[:space:]]*uses:' \
            .github/workflows/*.yml actions/*/action.yml)

echo "== upload-artifact-verified uploads zipped (download-artifact-verified needs the zip)"
UAV="${ROOT}/actions/upload-artifact-verified/action.yml"
if grep -qE '^[[:space:]]*archive:[[:space:]]*true[[:space:]]*(#.*)?$' "$UAV"; then
    ok "archive: true is set explicitly"
else
    bad "upload-artifact-verified" "archive: true is not set explicitly"
fi

echo ""
echo "${PASS} passed, ${FAIL} failed"
[ "${FAIL}" -eq 0 ]
