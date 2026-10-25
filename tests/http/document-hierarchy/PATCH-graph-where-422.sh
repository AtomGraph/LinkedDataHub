#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# A PATCH runs against the document's graph alone, as the default graph of a dataset with no named graphs.
# GRAPH outside the templates - in a DELETE WHERE, in the WHERE pattern, nested in OPTIONAL, NOT EXISTS or a
# sub-select - and WITH/USING can match nothing there, so such an update used to answer 204 having changed
# nothing, or changed half of what it said (#453). They are refused with 422 and leave the document as it was.

# add agent to the writers group

ldh admin add agent \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

uuid=$(uuidgen | tr '[:upper:]' '[:lower:]')
document="${END_USER_BASE_URL}${uuid}/"

status=$(printf '<%s> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://w3id.org/atomgraph/linkeddatahub/document-hierarchy#Item> .\n<%s> <http://purl.org/dc/terms/title> "Original" .\n<%s> <http://purl.org/dc/terms/description> "Removable" .\n' "$document" "$document" "$document" \
| curl -k -w "%{http_code}" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PUT \
  -H "Accept: application/n-triples" \
  -H "Content-Type: application/n-triples" \
  -H "If-None-Match: *" \
  --data-binary @- \
  "$document")

echo "DEBUG: create. Expected: $STATUS_PUT_SUCCESS Got: $status"
[[ "$status" =~ ^($STATUS_PUT_SUCCESS)$ ]] || exit 1

etag=$(etag "$document" "$AGENT_CERT_FILE" "$AGENT_CERT_PWD")

prefix="PREFIX dct: <http://purl.org/dc/terms/>"
updates=(
  "DELETE WHERE { GRAPH <${document}> { <${document}> dct:title ?title } }"
  "DELETE { <${document}> dct:title ?title } WHERE { GRAPH ?g { <${document}> dct:title ?title } }"
  "DELETE { <${document}> dct:title ?title } INSERT { <${document}> dct:title \"Changed\" } WHERE { OPTIONAL { GRAPH <${document}> { <${document}> dct:title ?title } } }"
  "INSERT { <${document}> dct:title \"Changed\" } WHERE { FILTER NOT EXISTS { GRAPH <${document}> { <${document}> dct:title ?title } } }"
  "DELETE { <${document}> dct:title ?title } WHERE { { SELECT ?title { GRAPH ?g { <${document}> dct:title ?title } } } }"
  "WITH <${document}> DELETE { <${document}> dct:title ?title } WHERE { <${document}> dct:title ?title }"
  "DELETE { <${document}> dct:title ?title } USING <${document}> WHERE { <${document}> dct:title ?title }"
)

for update in "${updates[@]}"; do
    status=$(printf '%s\n%s' "$prefix" "$update" | curl -k -w "%{http_code}" -o /dev/null -s \
      -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
      -X PATCH \
      -H "Accept: application/n-triples" \
      -H "Content-Type: application/sparql-update" \
      -H "If-Match: $etag" \
      --data-binary @- \
      "$document")

    echo "DEBUG: $update. Expected: $STATUS_UNPROCESSABLE_ENTITY Got: $status"
    [ "$status" = "$STATUS_UNPROCESSABLE_ENTITY" ] || exit 1
done

# none of them changed the document

current=$(etag "$document" "$AGENT_CERT_FILE" "$AGENT_CERT_PWD")
echo "DEBUG: entity tag before: $etag after: $current"
[ "$current" = "$etag" ] || exit 1

stored=$(curl -k -f -s -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$document")
echo "DEBUG: stored document: $stored"
echo "$stored" | grep -q '"Original"' || exit 1
if echo "$stored" | grep -q '"Changed"'; then exit 1; fi

# the same update without GRAPH still applies

status=$(printf '%s\nDELETE WHERE { <%s> dct:description ?description }' "$prefix" "$document" | curl -k -w "%{http_code}" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PATCH \
  -H "Accept: application/n-triples" \
  -H "Content-Type: application/sparql-update" \
  -H "If-Match: $etag" \
  --data-binary @- \
  "$document")

echo "DEBUG: DELETE WHERE without GRAPH. Expected: $STATUS_NO_CONTENT Got: $status"
[ "$status" = "$STATUS_NO_CONTENT" ] || exit 1
