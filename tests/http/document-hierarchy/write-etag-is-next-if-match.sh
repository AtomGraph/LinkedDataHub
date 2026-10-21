#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# POST and PATCH answer with the entity tag of the graph they have just written, so a client can make its next
# write conditional without reading the document again. That tag is computed from the graph in memory; this
# checks it is the one the store then serves - a write quoting it is accepted - and that it equals what a
# fresh HEAD reports. PUT answers with no validator at all (RFC 9110 9.3.4: what it stores is not the payload).

# add agent to the writers group

ldh admin add agent \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

uuid=$(uuidgen | tr '[:upper:]' '[:lower:]')
document="${END_USER_BASE_URL}${uuid}/"

# write <method> <content-type> <if-match> <body>: prints the response headers
function write()
{
    printf '%s' "$4" | curl -k -s -D - -o /dev/null \
      -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
      -X "$1" \
      -H "Accept: application/n-triples" \
      -H "Content-Type: $2" \
      -H "$3" \
      --data-binary @- \
      "$document"
}

function status_of() { printf '%s' "$1" | sed -En 's|^HTTP/[0-9.]+ ([0-9]+).*$|\1|p' | tail -1; }
function etag_of() { printf '%s' "$1" | grep -i '^etag:' | tr -d '\r' | sed -En 's/^[Ee][Tt][Aa][Gg]: (.*)$/\1/p'; }

response=$(write PUT application/n-triples 'If-None-Match: *' "<${document}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://w3id.org/atomgraph/linkeddatahub/document-hierarchy#Item> .
<${document}> <http://purl.org/dc/terms/title> \"Tagged\" .")
echo "DEBUG: create. Expected: $STATUS_CREATED Got: $(status_of "$response") ETag: $(etag_of "$response")"
[ "$(status_of "$response")" = "$STATUS_CREATED" ] || exit 1
[ -z "$(etag_of "$response")" ] || exit 1

# a PUT that replaces the document answers 204 with no validator either

response=$(write PUT application/n-triples "If-Match: $(etag "$document" "$AGENT_CERT_FILE" "$AGENT_CERT_PWD")" "<${document}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://w3id.org/atomgraph/linkeddatahub/document-hierarchy#Item> .
<${document}> <http://purl.org/dc/terms/title> \"Tagged\" .")
echo "DEBUG: replace. Expected: $STATUS_NO_CONTENT Got: $(status_of "$response") ETag: $(etag_of "$response")"
[ "$(status_of "$response")" = "$STATUS_NO_CONTENT" ] || exit 1
[ -z "$(etag_of "$response")" ] || exit 1

# POST answers with the new tag

response=$(write POST application/n-triples "If-Match: $(etag "$document" "$AGENT_CERT_FILE" "$AGENT_CERT_PWD")" "<${document}> <http://purl.org/dc/terms/description> \"appended\" .")
posted=$(etag_of "$response")
echo "DEBUG: append. Expected: $STATUS_NO_CONTENT Got: $(status_of "$response") ETag: ${posted:-<none>}"
[ "$(status_of "$response")" = "$STATUS_NO_CONTENT" ] || exit 1
[ -n "$posted" ] || exit 1

current=$(etag "$document" "$AGENT_CERT_FILE" "$AGENT_CERT_PWD")
echo "DEBUG: the POST's tag. Expected (HEAD): $current Got: $posted"
[ "$posted" = "$current" ] || exit 1

# PATCH quoting it is accepted, and answers with the next one

response=$(write PATCH application/sparql-update "If-Match: $posted" "DELETE WHERE { <${document}> <http://purl.org/dc/terms/description> ?description }")
patched=$(etag_of "$response")
echo "DEBUG: PATCH quoting the POST's tag. Expected: $STATUS_NO_CONTENT Got: $(status_of "$response") ETag: ${patched:-<none>}"
[ "$(status_of "$response")" = "$STATUS_NO_CONTENT" ] || exit 1
[ -n "$patched" ] || exit 1

current=$(etag "$document" "$AGENT_CERT_FILE" "$AGENT_CERT_PWD")
echo "DEBUG: the PATCH's tag. Expected (HEAD): $current Got: $patched"
[ "$patched" = "$current" ] || exit 1

# and DELETE quoting that one is accepted

response=$(write DELETE application/n-triples "If-Match: $patched" "")
echo "DEBUG: DELETE quoting the PATCH's tag. Expected: $STATUS_NO_CONTENT Got: $(status_of "$response")"
[ "$(status_of "$response")" = "$STATUS_NO_CONTENT" ] || exit 1
