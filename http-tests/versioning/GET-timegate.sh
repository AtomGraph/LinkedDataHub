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

# create two versions

put_document "First version"

for i in $(seq 1 30); do
    sha1=$(head_sha)
    if [ -n "$sha1" ]; then break; fi
    sleep 1
done
[ -n "$sha1" ]

first_datetime=$(gh api "repos/${VERSIONING_TEST_REPO}/commits/${sha1}" --jq '.commit.author.date')

put_document "Second version"

for i in $(seq 1 30); do
    sha2=$(head_sha)
    if [ -n "$sha2" ] && [ "$sha2" != "$sha1" ]; then break; fi
    sleep 1
done
[ "$sha2" != "$sha1" ]

# the document advertises its TimeGate (RFC 7089 4.1.1)

response_headers=$(
ldh get \
  -f "$AGENT_CERT_KEYSTORE" \
  -p "$AGENT_CERT_PWD" \
  --accept 'application/n-triples' \
  --head \
  "$doc_url" \
| tr -d '\r')

echo "DEBUG: Original Resource headers:"
echo "$response_headers"

echo "$response_headers" | grep -q "<${doc_url}?timegate>; rel=timegate"

# without Accept-Datetime the TimeGate selects the most recent Memento

timegate_headers=$(
curl -k -s -D - -o /dev/null \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  "${doc_url}?timegate" \
| tr -d '\r')

echo "DEBUG: TimeGate headers (no Accept-Datetime):"
echo "$timegate_headers"

echo "$timegate_headers" | grep -q '^HTTP/.* 302'
echo "$timegate_headers" | grep -qi "^Location: ${doc_url}?version=${sha2}"
echo "$timegate_headers" | grep -qi '^Vary:.*accept-datetime'
echo "$timegate_headers" | grep -q "<${doc_url}>; rel=original"
# the redirect must not be cached: it would outlive the commit that made it the most recent
echo "$timegate_headers" | grep -qi '^Cache-Control:.*no-store'

# a 302 TimeGate response must not carry Memento-Datetime

if echo "$timegate_headers" | grep -qi '^Memento-Datetime:'; then
    echo "DEBUG: TimeGate 302 response must not carry Memento-Datetime"
    exit 1
fi

# with Accept-Datetime at the first commit's time, the TimeGate selects the first Memento

accept_datetime=$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$first_datetime" "+%a, %d %b %Y %H:%M:%S GMT" 2> /dev/null \
    || date -u -d "$first_datetime" "+%a, %d %b %Y %H:%M:%S GMT")

echo "DEBUG: Accept-Datetime: $accept_datetime (commit $sha1 at $first_datetime)"

dated_headers=$(
curl -k -s -D - -o /dev/null \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept-Datetime: ${accept_datetime}" \
  "${doc_url}?timegate" \
| tr -d '\r')

echo "DEBUG: TimeGate headers (Accept-Datetime at first commit):"
echo "$dated_headers"

echo "$dated_headers" | grep -qi "^Location: ${doc_url}?version=${sha1}"

# a malformed Accept-Datetime is rejected

status=$(
curl -k -w "%{http_code}\n" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept-Datetime: yesterday afternoon" \
  "${doc_url}?timegate")

echo "DEBUG: malformed Accept-Datetime status: $status (expected 400)"
[ "$status" = "400" ]

# the TimeGate is read-only

status=$(
curl -k -w "%{http_code}\n" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PUT \
  -H "Content-Type: application/n-triples" \
  --data-binary "<${doc_url}> <http://purl.org/dc/terms/title> \"Overwrite attempt\" ." \
  "${doc_url}?timegate")

echo "DEBUG: PUT to TimeGate status: $status (expected 405)"
[ "$status" = "405" ]
