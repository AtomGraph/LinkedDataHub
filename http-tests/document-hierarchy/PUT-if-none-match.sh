#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# If-None-Match is a precondition in its own right - "only if this does not exist" - and a write carrying it
# is asking to CREATE, so it cannot also quote the entity tag of a thing it asserts there is none of. The
# import writer is built on that: PUT with If-None-Match: *, and on the 412 that says the document is already
# there, POST to append instead. Requiring If-Match of that PUT answered 428, which is not 412, so the
# fallback never ran and every RDF import into an existing document failed. Both halves are pinned here: the
# status the fallback keys on, and the entity tag it needs to make the append itself conditional.

# add agent to the writers group

ldh admin add agent \
  -f "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

uuid=$(uuidgen | tr '[:upper:]' '[:lower:]')
document="${END_USER_BASE_URL}${uuid}/"

body="<${document}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://w3id.org/atomgraph/linkeddatahub/document-hierarchy#Item> .
<${document}> <http://purl.org/dc/terms/title> \"Conditional create\" ."

# the document does not exist yet: creating it needs no validator, and If-None-Match: * is satisfied

status=$(printf '%s' "$body" | curl -k -w "%{http_code}" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PUT \
  -H "Accept: application/n-triples" \
  -H "Content-Type: application/n-triples" \
  -H "If-None-Match: *" \
  --data-binary @- \
  "$document")

echo "DEBUG: create with If-None-Match. Expected: $STATUS_PUT_SUCCESS Got: $status"
[[ "$status" =~ ^($STATUS_PUT_SUCCESS)$ ]] || exit 1

# the same request again now that it exists: 412, NOT 428 - the fallback keys on exactly this

response=$(printf '%s' "$body" | curl -k -s -D - -o /dev/null \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PUT \
  -H "Accept: application/n-triples" \
  -H "Content-Type: application/n-triples" \
  -H "If-None-Match: *" \
  --data-binary @- \
  "$document")

status=$(printf '%s' "$response" | sed -En 's|^HTTP/[0-9.]+ ([0-9]+).*$|\1|p' | tail -1)
echo "DEBUG: If-None-Match on an existing document. Expected: $STATUS_PRECONDITION_FAILED Got: $status"
[ "$status" = "$STATUS_PRECONDITION_FAILED" ] || exit 1

# and it names the current validator, so the append that follows needs no read of its own

etag=$(printf '%s' "$response" | grep -i '^etag:' | tr -d '\r' | sed -En 's/^[Ee][Tt][Aa][Gg]: (.*)$/\1/p')
echo "DEBUG: the 412 carries ETag: ${etag:-<none>}"
[ -n "$etag" ] || exit 1

# appending with it succeeds, which is the import writer's second step

status=$(printf '<%s> <http://purl.org/dc/terms/description> "appended" .\n' "$document" | curl -k -w "%{http_code}" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X POST \
  -H "Accept: application/n-triples" \
  -H "Content-Type: application/n-triples" \
  -H "If-Match: $etag" \
  --data-binary @- \
  "$document")

echo "DEBUG: append quoting the 412's tag. Expected: $STATUS_POST_SUCCESS Got: $status"
[[ "$status" =~ ^($STATUS_POST_SUCCESS)$ ]] || exit 1

curl -k -f -s -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$document" \
| grep -q '"appended"'
