#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# add agent to the owners group

ldh admin add agent \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/owners/"

# A PATCH that empties a document is the DELETE it amounts to, but the root document cannot be deleted. PATCH is
# supported on it, so the answer is not 405 (which says the method is not): the update cannot be applied, 422.

update=$(cat <<EOF
DELETE
{
  ?s ?p ?o
}
WHERE
{
  ?s ?p ?o
}
EOF
)

status=$(curl -k -w "%{http_code}" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PATCH \
  -H "Accept: application/n-triples" \
  -H "If-Match: $(etag "$END_USER_BASE_URL" "$AGENT_CERT_FILE" "$AGENT_CERT_PWD" "application/n-triples")" \
  -H "Content-Type: application/sparql-update" \
  "$END_USER_BASE_URL" \
  --data-binary "$update")

echo "DEBUG: PATCH emptying the root. Expected: $STATUS_UNPROCESSABLE_ENTITY Got: $status"
[ "$status" = "$STATUS_UNPROCESSABLE_ENTITY" ] || exit 1

# and the root is untouched

curl -k -f -s -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$END_USER_BASE_URL" \
| grep -q "^<${END_USER_BASE_URL}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> "
