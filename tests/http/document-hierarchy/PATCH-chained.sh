#!/usr/bin/env bash
set -euo pipefail

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
# one PATCH of three operations, executed in order: the title is replaced, a member is inserted as data, and a
# DELETE WHERE removes what the second operation inserted beside it - so the third sees the second's result

update=$(cat <<EOF
PREFIX  rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX  dct:  <http://purl.org/dc/terms/>

DELETE { <${END_USER_BASE_URL}> dct:title ?title }
INSERT { <${END_USER_BASE_URL}> dct:title "Chained" }
WHERE  { <${END_USER_BASE_URL}> dct:title ?title } ;

INSERT DATA
{
  <${END_USER_BASE_URL}> rdf:_2 <${END_USER_BASE_URL}#chained> .
  <${END_USER_BASE_URL}#chained> dct:description "removed by the next operation"
} ;

DELETE WHERE
{
  <${END_USER_BASE_URL}#chained> dct:description ?description
}
EOF
)

curl -k -w "%{http_code}\n" -o /dev/null -f -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PATCH \
  -H "Accept: application/n-triples" \
  -H "If-Match: $(etag "$END_USER_BASE_URL" "$AGENT_CERT_FILE" "$AGENT_CERT_PWD" "application/n-triples")" \
  -H "Content-Type: application/sparql-update" \
  "$END_USER_BASE_URL" \
   --data-binary "$update" \
| grep -q "$STATUS_NO_CONTENT"

body=$(curl -k -f -s -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$END_USER_BASE_URL")

echo "$body" | grep -qF "<${END_USER_BASE_URL}> <http://purl.org/dc/terms/title> \"Chained\""
echo "$body" | grep -qF "<${END_USER_BASE_URL}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#_2> <${END_USER_BASE_URL}#chained>"

if echo "$body" | grep -qF "removed by the next operation"; then
    echo "FAIL: the third operation did not see the second's result"
    exit 1
fi
