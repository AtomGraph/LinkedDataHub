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

# a document no write has reached since versioning began: its graph goes into the store directly, so the
# platform never sees a write and makes no commit - the state of every document that predates versioning
# being enabled for its dataspace

curl -f -s \
  -X POST \
  -H "Content-Type: application/sparql-update" \
  --data-binary "INSERT DATA { GRAPH <${doc_url}> {
    <${doc_url}> a <https://w3id.org/atomgraph/linkeddatahub/document-hierarchy#Item> ;
        <http://purl.org/dc/terms/title> \"Unversioned document\" .
  } }" \
  "$END_USER_ENDPOINT_URL" > /dev/null

purge_cache "$END_USER_VARNISH_SERVICE"

# it is still advertised as versioned: every document of the dataspace is

response_headers=$(
ldh get \
  -c "$AGENT_CERT_KEYSTORE" \
  -p "$AGENT_CERT_PWD" \
  --accept 'application/n-triples' \
  --head \
  "$doc_url" \
| tr -d '\r')

echo "$response_headers" | grep -q "<${doc_url}?timemap>; rel=\"timemap\""

# so the TimeMap it points at answers - with no Mementos yet, where it used to answer 404 and the History
# link led nowhere

timemap=$(
ldh get \
  -c "$AGENT_CERT_KEYSTORE" \
  -p "$AGENT_CERT_PWD" \
  --accept 'application/n-triples' \
  --timemap \
  "$doc_url")

echo "DEBUG: TimeMap: $timemap"

echo "$timemap" | grep -q "<${doc_url}?timemap> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/ns/prov#Collection>"

if echo "$timemap" | grep -q "ns/prov#hadMember"; then
    echo "DEBUG: a document with no commits listed a Memento"
    exit 1
fi

# in link-format: the Original Resource and the TimeMap itself, with no from/until to bound and no Memento

link_format=$(
ldh get \
  -c "$AGENT_CERT_KEYSTORE" \
  -p "$AGENT_CERT_PWD" \
  --accept 'application/link-format' \
  --timemap \
  "$doc_url")

echo "DEBUG: link-format: $link_format"

echo "$link_format" | grep -q "<${doc_url}>;rel=\"original\""
echo "$link_format" | grep -q "<${doc_url}?timemap>;rel=\"self\";type=\"application/link-format\""

if echo "$link_format" | grep -q 'memento\|from="'; then
    echo "DEBUG: a document with no commits listed a Memento or a datetime range"
    exit 1
fi
