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

put_document()
{
    echo "<${doc_url}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://www.w3.org/ns/ldt/document-hierarchy#Item> .
<${doc_url}> <http://purl.org/dc/terms/title> \"${1}\" ." | \
      ldh put \
        -f "$AGENT_CERT_KEYSTORE" \
        -p "$AGENT_CERT_PWD" \
        -t "application/n-triples" \
        "$doc_url"
}

head_sha()
{
    gh api "repos/${VERSIONING_TEST_REPO}/commits?path=${path}&sha=${VERSIONING_TEST_BRANCH:-main}&per_page=1" --jq '.[0].sha' 2> /dev/null || true
}

# create the first version and wait for its commit

put_document "First version"

for i in $(seq 1 30); do
    sha1=$(head_sha)
    if [ -n "$sha1" ]; then break; fi
    sleep 1
done
[ -n "$sha1" ]

# update the document and wait for the second commit

put_document "Second version"

for i in $(seq 1 30); do
    sha2=$(head_sha)
    if [ -n "$sha2" ] && [ "$sha2" != "$sha1" ]; then break; fi
    sleep 1
done
[ "$sha2" != "$sha1" ]

# retrieve the first version and check its content

response_body=$(
ldh get \
  -f "$AGENT_CERT_KEYSTORE" \
  -p "$AGENT_CERT_PWD" \
  --accept 'application/n-triples' \
  --version "$sha1" \
  "$doc_url")

echo "DEBUG: Response body:"
echo "$response_body"

echo "$response_body" | grep -q "First version"

if echo "$response_body" | grep -q "Second version"; then
    echo "DEBUG: historical version response contains the updated title"
    exit 1
fi

# check the Memento-Datetime and immutable caching headers

response_headers=$(
ldh get \
  -f "$AGENT_CERT_KEYSTORE" \
  -p "$AGENT_CERT_PWD" \
  --accept 'application/n-triples' \
  --head \
  --version "$sha1" \
  "$doc_url" \
| tr -d '\r')

echo "DEBUG: Response headers:"
echo "$response_headers"

echo "$response_headers" | grep -qi '^Memento-Datetime:'
echo "$response_headers" | grep -qi '^Cache-Control:.*immutable'

# RFC 7089: the Memento-Datetime value is RFC 1123 with a zero-padded day of month,
# and a Memento MUST link to its Original Resource

echo "$response_headers" | grep -qiE '^Memento-Datetime: [A-Z][a-z]{2}, [0-9]{2} [A-Z][a-z]{2} [0-9]{4} [0-9]{2}:[0-9]{2}:[0-9]{2} GMT'
echo "$response_headers" | grep -q "<${doc_url}>; rel=original"
echo "$response_headers" | grep -q 'rel=timemap'

# a historical version is read-only: acl:Read advertised but no write modes, writes rejected with 405

echo "$response_headers" | grep -q 'acl#Read'

if echo "$response_headers" | grep -q 'acl#Write'; then
    echo "DEBUG: version response advertises acl:Write"
    exit 1
fi

if echo "$response_headers" | grep -q 'acl#Append'; then
    echo "DEBUG: version response advertises acl:Append"
    exit 1
fi

(
curl -k -w "%{http_code}\n" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PUT \
  -H "Content-Type: application/n-triples" \
  --data-binary "<${doc_url}> <http://purl.org/dc/terms/title> \"Overwrite attempt\" ." \
  "${doc_url}?version=${sha1}"
) \
| grep -q '405'
