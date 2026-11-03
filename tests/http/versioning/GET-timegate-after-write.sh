#!/usr/bin/env bash
set -euo pipefail

# requires a dataspace configured with lds:versioningRepository (branch "main", path prefix "graphs")
# pointing at $VERSIONING_TEST_REPO ("owner/repo"), with the token in secrets/credentials.trig

if [ -z "${VERSIONING_TEST_REPO:-}" ] || [ -z "${GITHUB_TOKEN:-}" ] || ! command -v gh > /dev/null; then
    echo "SKIPPED: VERSIONING_TEST_REPO/GITHUB_TOKEN not set or gh CLI not available"
    exit 0
fi

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# add agent to the writers group

ldh admin add agent \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

slug=$(uuidgen | tr '[:upper:]' '[:lower:]')
doc_url="${END_USER_BASE_URL}${slug}/"
path="${VERSIONING_PATH_PREFIX:-graphs}/${slug}.nt"

put_document()
{
    echo "<${doc_url}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://w3id.org/atomgraph/linkeddatahub/document-hierarchy#Item> .
<${doc_url}> <http://purl.org/dc/terms/title> \"${1}\" ." | \
      ldh put \
        -c "$AGENT_CERT_KEYSTORE" \
        -p "$AGENT_CERT_PWD" \
        -t "application/n-triples" \
        "$doc_url"
}

head_sha()
{
    gh api "repos/${VERSIONING_TEST_REPO}/commits?path=${path}&sha=${VERSIONING_TEST_BRANCH:-main}&per_page=1" --jq '.[0].sha' 2> /dev/null || true
}

# the first version, committed

put_document "First version"

for i in $(seq 1 30); do
    sha1=$(head_sha)
    if [ -n "$sha1" ]; then break; fi
    sleep 1
done
[ -n "$sha1" ]

# the second write's commit is made after its response: until it is in the history, the TimeGate asks the client to
# come back (503 with Retry-After) and never redirects to the first version, which is no longer the current state

put_document "Second version"

location=""
waited=false
for i in $(seq 1 60); do
    headers=$(
    curl -k -s -I \
      -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
      "${doc_url}?timegate" \
    | tr -d '\r')
    status=$(echo "$headers" | head -n 1 | cut -d ' ' -f 2)

    if [ "$status" = "503" ]; then
        echo "$headers" | grep -qi '^Retry-After: [0-9]'
        echo "$headers" | grep -qi '^Cache-Control:.*no-store'
        waited=true
        sleep 1
        continue
    fi

    [ "$status" = "302" ]
    location=$(echo "$headers" | grep -i '^Location: ' | cut -d ' ' -f 2)
    break
done

[ -n "$location" ]
[ "$location" != "${doc_url}?version=${sha1}" ]

sha2=$(head_sha)
[ "$location" = "${doc_url}?version=${sha2}" ]

echo "TimeGate after a write: waited=${waited}, redirected to the new version"
