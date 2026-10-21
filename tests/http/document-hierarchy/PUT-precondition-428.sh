#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# A write to an existing document has to quote the state it was made against: If-Match with an entity tag,
# or If-None-Match: * (create-only, which fails 412 on an existing document). Any other If-None-Match only
# fails when it names the current tag, and If-Match: * holds for any state, so both used to pass the 428
# check and write unconditionally (#452). A write quoting the tag of a document that is gone is refused too,
# instead of recreating it.

# add agent to the writers group

ldh admin add agent \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

uuid=$(uuidgen | tr '[:upper:]' '[:lower:]')
document="${END_USER_BASE_URL}${uuid}/"

body="<${document}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://w3id.org/atomgraph/linkeddatahub/document-hierarchy#Item> .
<${document}> <http://purl.org/dc/terms/title> \"Original\" ."
changed="<${document}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://w3id.org/atomgraph/linkeddatahub/document-hierarchy#Item> .
<${document}> <http://purl.org/dc/terms/title> \"Overwritten\" ."

status=$(printf '%s' "$body" | curl -k -w "%{http_code}" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PUT \
  -H "Accept: application/n-triples" \
  -H "Content-Type: application/n-triples" \
  -H "If-None-Match: *" \
  --data-binary @- \
  "$document")

echo "DEBUG: create. Expected: $STATUS_PUT_SUCCESS Got: $status"
[[ "$status" =~ ^($STATUS_PUT_SUCCESS)$ ]] || exit 1

# write <method> <content-type> <header> <body>: prints the status code
function write()
{
    printf '%s' "$4" | curl -k -w "%{http_code}" -o /dev/null -s \
      -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
      -X "$1" \
      -H "Accept: application/n-triples" \
      -H "Content-Type: $2" \
      -H "$3" \
      --data-binary @- \
      "$document"
}

status=$(write PUT application/n-triples 'If-None-Match: "bogus"' "$changed")
echo "DEBUG: PUT with a made-up If-None-Match. Expected: $STATUS_PRECONDITION_REQUIRED Got: $status"
[ "$status" = "$STATUS_PRECONDITION_REQUIRED" ] || exit 1

status=$(write PUT application/n-triples 'If-Match: *' "$changed")
echo "DEBUG: PUT with If-Match: *. Expected: $STATUS_PRECONDITION_REQUIRED Got: $status"
[ "$status" = "$STATUS_PRECONDITION_REQUIRED" ] || exit 1

# the 428 explains how to resubmit (RFC 6585 3): it names If-Match and HEAD as the way to get the tag

response=$(printf '%s' "$changed" | curl -k -s -i \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PUT \
  -H "Accept: application/n-triples" \
  -H "Content-Type: application/n-triples" \
  --data-binary @- \
  "$document" | tr -d '\r')
echo "DEBUG: 428 response: $response"
echo "$response" | grep -qi '^content-type: text/plain' || { echo "DEBUG: Expected a text/plain body"; exit 1; }
body=$(echo "$response" | sed '1,/^$/d')
echo "$body" | grep -q 'If-Match' || { echo "DEBUG: Expected the body to name If-Match"; exit 1; }
echo "$body" | grep -q 'HEAD' || { echo "DEBUG: Expected the body to name HEAD"; exit 1; }

status=$(write POST application/n-triples 'If-None-Match: "bogus"' "<${document}> <http://purl.org/dc/terms/description> \"appended\" .")
echo "DEBUG: POST with a made-up If-None-Match. Expected: $STATUS_PRECONDITION_REQUIRED Got: $status"
[ "$status" = "$STATUS_PRECONDITION_REQUIRED" ] || exit 1

status=$(write PATCH application/sparql-update 'If-None-Match: "bogus"' "DELETE WHERE { <${document}> <http://purl.org/dc/terms/title> ?title }")
echo "DEBUG: PATCH with a made-up If-None-Match. Expected: $STATUS_PRECONDITION_REQUIRED Got: $status"
[ "$status" = "$STATUS_PRECONDITION_REQUIRED" ] || exit 1

status=$(write DELETE application/n-triples 'If-None-Match: "bogus"' "")
echo "DEBUG: DELETE with a made-up If-None-Match. Expected: $STATUS_PRECONDITION_REQUIRED Got: $status"
[ "$status" = "$STATUS_PRECONDITION_REQUIRED" ] || exit 1

# none of them wrote anything

stored=$(curl -k -f -s -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$document")
echo "DEBUG: stored document: $stored"
echo "$stored" | grep -q '"Original"' || exit 1
if echo "$stored" | grep -q '"Overwritten"\|"appended"'; then exit 1; fi

# the current tag still works

etag=$(etag "$document" "$AGENT_CERT_FILE" "$AGENT_CERT_PWD")

status=$(write DELETE application/n-triples "If-Match: $etag" "")
echo "DEBUG: DELETE with the current tag. Expected: $STATUS_NO_CONTENT Got: $status"
[ "$status" = "$STATUS_NO_CONTENT" ] || exit 1

# a PUT quoting the deleted document's tag must not bring it back (RFC 9110 13.1.1)

status=$(write PUT application/n-triples "If-Match: $etag" "$body")
echo "DEBUG: PUT quoting the tag of a deleted document. Expected: $STATUS_PRECONDITION_FAILED Got: $status"
[ "$status" = "$STATUS_PRECONDITION_FAILED" ] || exit 1

# a typeless URL matches no class-level authorization, so a missing document reads 403 rather than 404

status=$(curl -k -w "%{http_code}" -o /dev/null -s -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$document")
echo "DEBUG: the document stays deleted. Expected: $STATUS_FORBIDDEN or $STATUS_NOT_FOUND Got: $status"
[[ "$status" =~ ^($STATUS_FORBIDDEN|$STATUS_NOT_FOUND)$ ]] || exit 1
