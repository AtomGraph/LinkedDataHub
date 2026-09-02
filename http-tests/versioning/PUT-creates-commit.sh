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

# create a document

slug=$(uuidgen | tr '[:upper:]' '[:lower:]')
doc_url="${END_USER_BASE_URL}${slug}/"

echo "<${doc_url}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://www.w3.org/ns/ldt/document-hierarchy#Item> .
<${doc_url}> <http://purl.org/dc/terms/title> \"Versioned document\" ." | \
  ldh put \
    -f "$AGENT_CERT_KEYSTORE" \
    -p "$AGENT_CERT_PWD" \
    -t "application/n-triples" \
    "$doc_url"

# wait for the async versioning commit to appear in the repository, and check that its author is
# the agent's WebID. The wait polls the commit listing rather than the file: the listing is what
# carries the author, and GitHub indexes it per path asynchronously, so it lags behind the Contents
# API by seconds - a file that is already readable can still have an empty commit history.

path="${VERSIONING_PATH_PREFIX:-graphs}/${slug}.nt"

commit_author()
{
    gh api "repos/${VERSIONING_TEST_REPO}/commits?path=${path}&sha=${VERSIONING_TEST_BRANCH:-main}&per_page=1" --jq '.[0].commit.author.name' 2> /dev/null || true
}

author=""

for i in $(seq 1 30); do
    author=$(commit_author)
    if [ -n "$author" ]; then break; fi
    sleep 1
done

[ "$author" = "$AGENT_URI" ]
