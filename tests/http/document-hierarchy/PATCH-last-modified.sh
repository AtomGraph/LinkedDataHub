#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# Last-Modified is derived from the document's dct:created and dct:modified. A PATCH has to move it - otherwise
# a cache revalidating with If-Modified-Since is told 304 for content that changed - and a PATCH that INSERTs
# dates of its own must not pin it at a date of its choosing (RFC 9110 8.8.2.1).

# add agent to the writers group

ldh admin add agent \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

uuid=$(uuidgen | tr '[:upper:]' '[:lower:]')
document="${END_USER_BASE_URL}${uuid}/"

status=$(printf '%s' "<${document}> <http://purl.org/dc/terms/title> \"Dated\" ." | curl -k -w "%{http_code}" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PUT \
  -H "Accept: application/n-triples" \
  -H "Content-Type: application/n-triples" \
  -H "If-None-Match: *" \
  --data-binary @- \
  "$document")

echo "DEBUG: create. Expected: $STATUS_CREATED Got: $status"
[ "$status" = "$STATUS_CREATED" ] || exit 1

# last_modified: prints the document's Last-Modified header

function last_modified()
{
    curl -k -s -I \
      -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
      -H "Accept: application/n-triples" \
      "$document" \
    | grep -i '^last-modified:' | tr -d '\r' | sed 's/^[Ll]ast-[Mm]odified: *//'
}

# patch <update>: prints the status code

function patch()
{
    printf '%s' "$1" | curl -k -w "%{http_code}" -o /dev/null -s \
      -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
      -X PATCH \
      -H "Accept: application/n-triples" \
      -H "Content-Type: application/sparql-update" \
      -H "If-Match: $(etag "$document" "$AGENT_CERT_FILE" "$AGENT_CERT_PWD")" \
      --data-binary @- \
      "$document"
}

created=$(last_modified)
echo "DEBUG: Last-Modified after creation: $created"
[ -n "$created" ] || exit 1

# Last-Modified has a resolution of one second

sleep 2

status=$(patch "INSERT { <${document}> <http://purl.org/dc/terms/description> \"patched\" } WHERE {}")
echo "DEBUG: PATCH. Expected: $STATUS_NO_CONTENT Got: $status"
[ "$status" = "$STATUS_NO_CONTENT" ] || exit 1

patched=$(last_modified)
echo "DEBUG: Last-Modified after the PATCH. Expected other than: $created Got: $patched"
[ -n "$patched" ] || exit 1
[ "$patched" != "$created" ] || exit 1

# a PATCH that writes the dates itself: they are the server's, and the inserted ones are not kept

status=$(patch "INSERT { <${document}> <http://purl.org/dc/terms/modified> \"2099-01-01T00:00:00Z\"^^<http://www.w3.org/2001/XMLSchema#dateTime> ; <http://purl.org/dc/terms/created> \"2099-01-01T00:00:00Z\"^^<http://www.w3.org/2001/XMLSchema#dateTime> } WHERE {}")
echo "DEBUG: PATCH inserting future dates. Expected: $STATUS_NO_CONTENT Got: $status"
[ "$status" = "$STATUS_NO_CONTENT" ] || exit 1

future=$(last_modified)
echo "DEBUG: Last-Modified after the future-dated PATCH. Expected: not in 2099 Got: $future"
[ -n "$future" ] || exit 1
if echo "$future" | grep -q "2099"; then exit 1; fi

stored=$(curl -k -f -s -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$document")
echo "DEBUG: stored document: $stored"
if echo "$stored" | grep -q '"2099-'; then exit 1; fi

created_count=$(echo "$stored" | grep -c "<${document}> <http://purl.org/dc/terms/created> " || true)
modified_count=$(echo "$stored" | grep -c "<${document}> <http://purl.org/dc/terms/modified> " || true)
echo "DEBUG: dct:created count. Expected: 1 Got: $created_count"
echo "DEBUG: dct:modified count. Expected: 1 Got: $modified_count"
[ "$created_count" -eq 1 ] || exit 1
[ "$modified_count" -eq 1 ] || exit 1
