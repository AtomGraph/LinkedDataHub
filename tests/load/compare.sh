#!/usr/bin/env bash
set -euo pipefail

# Measure the SPARQL load scenarios against two or more revisions and print them side by side - the
# before/after for the concurrency-cap + OOM-restart change. For each ref this builds the stack from
# that ref's own docker-compose.yml (so the "before" ref runs without the guards) but with THIS
# worktree's tests/load/ copied in (so both runs use the same loadgen network, heap and scenarios).
# The scenarios run in MEASURE_ONLY mode - they report, they do not assert - so a ref without the
# guards produces numbers rather than a failure.
#
# This is a one-off measurement, not part of `run.sh`. It is resource-intensive: it builds an image and brings up a
# full stack per ref, one at a time. Needs ~8 GB free disk, the ports 81/4443/5443 free (stop any
# other local LDH stack first), and `ldh` on PATH (any version - make-public is an HTTP-API call).
#
# Usage: tests/load/compare.sh [<ref> ...]      (default: 647f5e8d5^ 647f5e8d5)

REFS=("$@"); [ "${#REFS[@]}" -gt 0 ] || REFS=("647f5e8d5^" "647f5e8d5")

hash ldh 2>/dev/null || { echo >&2 "ldh not on PATH - build it (mvn package in cli/) and add cli/bin. Aborting."; exit 1; }

here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../.." && pwd)
work=$(mktemp -d)
results=$(mktemp -d)
trap 'rm -rf "$work" "$results"' EXIT

echo "repo:    $repo"
echo "refs:    ${REFS[*]}"
echo "scratch: $work"
echo

for ref in "${REFS[@]}"; do
    safe=$(echo "$ref" | tr -c 'A-Za-z0-9' '-')
    project="ldh-cmp-$safe"
    tree="$work/$safe"
    echo "########## $ref ##########"

    git -C "$repo" worktree add --quiet --detach "$tree" "$ref"
    # this worktree's test assets over the ref's: same scenarios, network and heap for every ref
    rm -rf "$tree/tests/load"
    cp -a "$here" "$tree/tests/load"
    # certs and secrets the stack needs, generated once in the main checkout
    cp -a "$repo/secrets" "$tree/secrets"
    cp -a "$repo/tests/http/ssl" "$tree/tests/http/ssl"

    compose="docker compose -p $project \
-f $tree/docker-compose.yml \
-f $tree/tests/http/docker-compose.http-tests.yml \
-f $tree/tests/load/docker-compose.load-tests.yml \
--env-file $tree/tests/http/.env"

    echo "[$ref] building and starting the stack..."
    WEBALGEBRA_VERSION="${WEBALGEBRA_VERSION:-latest}" $compose up --build -d >/dev/null 2>&1

    echo "[$ref] waiting for the platform..."
    until [ "$(docker inspect -f '{{.State.Health.Status}}' "$($compose ps -q linkeddatahub)" 2>/dev/null)" = healthy ]; do sleep 5; done

    echo "[$ref] making the dataspace public..."
    LDH_BASE="https://localhost:4443/" \
    LDH_CERT_FILE="$tree/tests/http/ssl/owner/keystore.p12" \
    LDH_CERT_PASSWORD="$(cat "$tree/secrets/owner_cert_password.txt")" \
        ldh admin make-public >/dev/null 2>&1

    out="$results/$safe.txt"
    {
        echo "================ $ref ================"
        for scenario in sparql-concurrency-site-stays-up sparql-heap-fuseki-recovers sparql-rate-limited; do
            echo "[$ref] $scenario" >&2
            COMPOSE_CMD="$compose" MEASURE_ONLY=1 bash "$tree/tests/load/$scenario.sh" 2>&1 || true
            echo
        done
    } | tee "$out"

    echo "[$ref] tearing down..."
    $compose down -v >/dev/null 2>&1
    git -C "$repo" worktree remove --force "$tree"
    echo
done

echo
echo "################## SUMMARY ##################"
for ref in "${REFS[@]}"; do
    safe=$(echo "$ref" | tr -c 'A-Za-z0-9' '-')
    cat "$results/$safe.txt"
    echo
done
