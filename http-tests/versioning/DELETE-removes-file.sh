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

# create a document and wait for its file to appear

echo "<${doc_url}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://www.w3.org/ns/ldt/document-hierarchy#Item> .
<${doc_url}> <http://purl.org/dc/terms/title> \"To be deleted\" ." | \
  ldh put \
    -f "$AGENT_CERT_KEYSTORE" \
    -p "$AGENT_CERT_PWD" \
    -t "application/n-triples" \
    "$doc_url"

# the poll is the assertion: re-reading the file after it succeeded only asks GitHub the same
# question again, and a read that just returned the file can still 404 moments later

found=""

for i in $(seq 1 30); do
    if gh api "repos/${VERSIONING_TEST_REPO}/contents/${path}?ref=${VERSIONING_TEST_BRANCH:-main}" > /dev/null 2>&1; then
        found=1
        break
    fi
    sleep 1
done

if [ -z "$found" ]; then
    echo "DEBUG: file '${path}' did not appear in ${VERSIONING_TEST_REPO} on branch '${VERSIONING_TEST_BRANCH:-main}' within 30 s; its commit history:"
    gh api "repos/${VERSIONING_TEST_REPO}/commits?path=${path}&sha=${VERSIONING_TEST_BRANCH:-main}&per_page=1" || true
    exit 1
fi

# delete the document and check that the file disappears

ldh delete \
  -f "$AGENT_CERT_KEYSTORE" \
  -p "$AGENT_CERT_PWD" \
  "$doc_url"

for i in $(seq 1 30); do
    if ! gh api "repos/${VERSIONING_TEST_REPO}/contents/${path}?ref=${VERSIONING_TEST_BRANCH:-main}" > /dev/null 2>&1; then
        exit 0
    fi
    sleep 1
done

echo "DEBUG: file '${path}' still present in ${VERSIONING_TEST_REPO} after document deletion"
exit 1
