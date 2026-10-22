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

# create the first version and wait for its commit

put_document "First version"

for i in $(seq 1 30); do
    sha1=$(head_sha)
    if [ -n "$sha1" ]; then break; fi
    sleep 1
done
[ -n "$sha1" ]

# the entity tag is derived per variant from the commit SHA, and it is the tag preconditions are evaluated against:
# every variant used to be tagged with the bare SHA while If-None-Match was compared with the content digest, so
# revalidating a Memento never got a 304

version_url="${doc_url}?version=${sha1}"

ntriples_etag=$(etag "$version_url" "$AGENT_CERT_FILE" "$AGENT_CERT_PWD" "application/n-triples")
turtle_etag=$(etag "$version_url" "$AGENT_CERT_FILE" "$AGENT_CERT_PWD" "text/turtle")

echo "DEBUG: N-Triples ETag: $ntriples_etag  Turtle ETag: $turtle_etag  SHA: $sha1"
[ -n "$ntriples_etag" ] && [ -n "$turtle_etag" ]
[ "$ntriples_etag" != "$turtle_etag" ]

status=$(
curl -k -w "%{http_code}" -o /dev/null -s -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  -H "If-None-Match: ${ntriples_etag}" \
  "$version_url")

echo "DEBUG: If-None-Match: $ntriples_etag  Expected: $STATUS_NOT_MODIFIED  Got: $status"
[ "$status" = "$STATUS_NOT_MODIFIED" ]

# another variant's tag does not validate this one

status=$(
curl -k -w "%{http_code}" -o /dev/null -s -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  -H "If-None-Match: ${turtle_etag}" \
  "$version_url")

echo "DEBUG: If-None-Match: $turtle_etag  Expected: $STATUS_OK  Got: $status"
[ "$status" = "$STATUS_OK" ]
