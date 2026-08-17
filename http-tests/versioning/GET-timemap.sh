#!/usr/bin/env bash
set -euo pipefail

# requires a dataspace configured with lapp:versioningRepository (branch "main", path prefix "graphs")
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

# add agent to the writers group

add-agent-to-group.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

slug=$(uuidgen | tr '[:upper:]' '[:lower:]')
doc_url="${END_USER_BASE_URL}${slug}/"
path="graphs/${slug}.nt"

# create a document and wait for its versioning commit

echo "<${doc_url}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://www.w3.org/ns/ldt/document-hierarchy#Item> .
<${doc_url}> <http://purl.org/dc/terms/title> \"TimeMap test\" ." | \
  put.sh \
    -f "$AGENT_CERT_FILE" \
    -p "$AGENT_CERT_PWD" \
    -t "application/n-triples" \
    "$doc_url"

for i in $(seq 1 30); do
    if gh api "repos/${VERSIONING_TEST_REPO}/contents/${path}?ref=main" > /dev/null 2>&1; then
        break
    fi
    sleep 1
done
gh api "repos/${VERSIONING_TEST_REPO}/contents/${path}?ref=main" > /dev/null

# check that the document advertises its TimeMap via the Link header

response_headers=$(
get.sh \
  -f "$AGENT_CERT_FILE" \
  -p "$AGENT_CERT_PWD" \
  --accept 'application/n-triples' \
  --head \
  "$doc_url" \
| tr -d '\r')

echo "DEBUG: Response headers:"
echo "$response_headers"

echo "$response_headers" | grep -q "mementoweb.org/ns#timemap"

# retrieve the TimeMap and check the memento entries

timemap=$(
get.sh \
  -f "$AGENT_CERT_FILE" \
  -p "$AGENT_CERT_PWD" \
  --accept 'application/n-triples' \
  "${doc_url}?timemap")

echo "DEBUG: TimeMap:"
echo "$timemap"

echo "$timemap" | grep -q "mementoweb.org/ns#TimeMap"
echo "$timemap" | grep -q "mementoweb.org/ns#Memento"
echo "$timemap" | grep -q "${doc_url}?version="
echo "$timemap" | grep -q "mementoweb.org/ns#mementoDatetime"
echo "$timemap" | grep -q "$AGENT_URI"
