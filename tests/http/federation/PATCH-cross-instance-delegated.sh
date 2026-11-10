#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
initialize_dataset "$REMOTE_END_USER_BASE_URL" "$TMP_REMOTE_END_USER_DATASET" "$REMOTE_END_USER_ENDPOINT_URL"
initialize_dataset "$REMOTE_ADMIN_BASE_URL" "$TMP_REMOTE_ADMIN_DATASET" "$REMOTE_ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# Federation across instances: A's owner edits a document on another LinkedDataHub instance B through A's Linked Data
# proxy. B is not one of A's dataspaces (PATCH-remote-document.sh writes to test.localhost, which is), so this is the
# path where A has to vouch for its agent to a server it does not run: its secretary's certificate plus On-Behalf-Of,
# which B verifies by dereferencing A's secretary and the owner's WebID, where the secretary delegates the owner.
# B grants A's owner write on the document, so the proxied write succeeds only if B learns who is writing.

# create the document on B, as B's owner

item=$(ldh create item \
  -c "$REMOTE_OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --title "Cross-instance write target" \
  --slug "cross-instance-patch-$(date +%s)" \
  --container "$REMOTE_END_USER_BASE_URL")

echo "DEBUG: document on B: $item"

# B grants A's owner read and write on it

ldh admin create authorization \
  -c "$REMOTE_OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --label "A's owner may edit the cross-instance target" \
  --agent "$OWNER_URI" \
  --to "$item" \
  --read \
  --write \
  "$REMOTE_ADMIN_BASE_URL" > /dev/null

# Sends a PATCH inserting the given description, under If-Match with B's current ETag. LDH ETags are variant-specific,
# so the tag is read with the Accept the write sends. Prints the status code, then the response body
function patch_description()
{
    local description="$1" target="$2"
    shift 2

    local tag
    tag=$(etag "$item" "$OWNER_CERT_FILE" "$OWNER_CERT_PWD" "application/rdf+xml")

    curl -k -s -w "\n%{http_code}" \
      -X PATCH \
      -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
      -H 'Content-Type: application/sparql-update' \
      -H 'Accept: application/rdf+xml' \
      -H "If-Match: $tag" \
      "$@" \
      --data-binary "INSERT DATA { <${item}> <http://purl.org/dc/terms/description> \"${description}\" }" \
      "$target"
}

# Reads the document on B directly, as A's owner, and checks it carries the description
function has_description()
{
    curl -k -f -s \
      -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
      -H "Accept: application/n-triples" \
      "$item" \
    | grep -q "$1"
}

# Control: A's owner writes to B directly, with its own certificate. Proves that B dereferences A's WebIDs and that the
# grant above is the one the proxied write needs, so that a failure below is the proxy's

response=$(patch_description "Written directly" "$item")
code="${response##*$'\n'}"

echo "DEBUG: direct PATCH - Expected: $STATUS_NO_CONTENT  Got: $code"
if [ "$code" != "$STATUS_NO_CONTENT" ]; then
  echo "DEBUG: direct PATCH response body: ${response%$'\n'*}"
  exit 1
fi
has_description "Written directly" || { echo "DEBUG: the direct write did not land on B"; exit 1; }

# The proxied write: the same PATCH, sent to A with the document as ?uri=. Accept is RDF, so the proxy forwards it rather
# than bypassing to the HTML shell

response=$(patch_description "Written through the proxy" "$END_USER_BASE_URL" --url-query "uri=${item}")
code="${response##*$'\n'}"

echo "DEBUG: proxied PATCH - Expected: $STATUS_NO_CONTENT  Got: $code"
if [ "$code" != "$STATUS_NO_CONTENT" ]; then
  echo "DEBUG: proxied PATCH response body: ${response%$'\n'*}"
  exit 1
fi
has_description "Written through the proxy" || { echo "DEBUG: the proxied write did not land on B"; exit 1; }
