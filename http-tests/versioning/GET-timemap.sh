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

ldh admin acl add-agent-to-group \
  -f "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

slug=$(uuidgen | tr '[:upper:]' '[:lower:]')
doc_url="${END_USER_BASE_URL}${slug}/"
path="${VERSIONING_PATH_PREFIX:-graphs}/${slug}.nt"

# create a document and wait for its versioning commit

echo "<${doc_url}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://www.w3.org/ns/ldt/document-hierarchy#Item> .
<${doc_url}> <http://purl.org/dc/terms/title> \"TimeMap test\" ." | \
  ldh put \
    -f "$AGENT_CERT_KEYSTORE" \
    -p "$AGENT_CERT_PWD" \
    -t "application/n-triples" \
    "$doc_url"

# wait for the commit listing, not for the file: the TimeMap is built from that listing, and GitHub
# indexes it per path asynchronously, so it lags behind the Contents API by seconds

head_sha()
{
    gh api "repos/${VERSIONING_TEST_REPO}/commits?path=${path}&sha=${VERSIONING_TEST_BRANCH:-main}&per_page=1" --jq '.[0].sha' 2> /dev/null || true
}

sha=""

for i in $(seq 1 30); do
    sha=$(head_sha)
    if [ -n "$sha" ]; then break; fi
    sleep 1
done

if [ -z "$sha" ]; then
    echo "DEBUG: no commit listed for '${path}' on branch '${VERSIONING_TEST_BRANCH:-main}' after 30 s; the file itself:"
    gh api "repos/${VERSIONING_TEST_REPO}/contents/${path}?ref=${VERSIONING_TEST_BRANCH:-main}" || true
    exit 1
fi

# check that the document advertises its TimeMap via the Link header

response_headers=$(
ldh get \
  -f "$AGENT_CERT_KEYSTORE" \
  -p "$AGENT_CERT_PWD" \
  --accept 'application/n-triples' \
  --head \
  "$doc_url" \
| tr -d '\r')

echo "DEBUG: Response headers:"
echo "$response_headers"

# RFC 7089: the Original Resource advertises rel=timemap with the link-format media type,
# and MUST NOT carry rel=original
echo "$response_headers" | grep -q 'rel=timemap'
echo "$response_headers" | grep -q 'type="application/link-format"'

if echo "$response_headers" | grep -q 'rel=original'; then
    echo "DEBUG: Original Resource must not carry rel=original"
    exit 1
fi

# retrieve the TimeMap as RDF and check the PROV description

timemap=$(
ldh get \
  -f "$AGENT_CERT_KEYSTORE" \
  -p "$AGENT_CERT_PWD" \
  --accept 'application/n-triples' \
  "${doc_url}?timemap")

echo "DEBUG: TimeMap:"
echo "$timemap"

echo "$timemap" | grep -q "ns/prov#Collection"
echo "$timemap" | grep -q "ns/prov#hadMember"
echo "$timemap" | grep -q "ns/prov#specializationOf"
echo "$timemap" | grep -q "ns/prov#generatedAtTime"
echo "$timemap" | grep -q "${doc_url}?version="
echo "$timemap" | grep -q "$AGENT_URI"

# the same TimeMap in the serialization RFC 7089 requires

link_format=$(
ldh get \
  -f "$AGENT_CERT_KEYSTORE" \
  -p "$AGENT_CERT_PWD" \
  --accept 'application/link-format' \
  "${doc_url}?timemap")

echo "DEBUG: link-format TimeMap:"
echo "$link_format"

echo "$link_format" | grep -q "<${doc_url}>;rel=\"original\""
echo "$link_format" | grep -q "<${doc_url}?timemap>;rel=\"self\";type=\"application/link-format\""
echo "$link_format" | grep -q "<${doc_url}?timegate>;rel=\"timegate\""
echo "$link_format" | grep -q 'rel="first' # first memento, or "first last memento" on a single-version document
echo "$link_format" | grep -q 'datetime="'

# link-format is scoped to the TimeMap: an ordinary document does not offer it

status=$(
curl -k -w "%{http_code}\n" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/link-format" \
  "$doc_url")

echo "DEBUG: link-format status on the document itself: $status (expected 406)"
[ "$status" = "406" ]
