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

# POST a typed sub-resource (foaf:Person) to the root document.

(
curl -k -w "%{http_code}\n" -o /dev/null -f -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "If-Match: $(etag "$END_USER_BASE_URL" "$AGENT_CERT_FILE" "$AGENT_CERT_PWD" "application/n-triples")" \
  -H "Accept: application/n-triples" \
  -H "Content-Type: application/n-triples" \
  --data-binary @- \
  "$END_USER_BASE_URL" <<EOF
<${END_USER_BASE_URL}#person> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://xmlns.com/foaf/0.1/Person> .
<${END_USER_BASE_URL}#person> <http://xmlns.com/foaf/0.1/name> "Test person" .
EOF
) \
| grep -q "$STATUS_NO_CONTENT"

# PATCH the root to remove the sub-resource's only type and keep its name. Only the document is held to being
# typed (with a document hierarchy class); a resource it describes may be described without a type, as imported
# data often is.

update=$(cat <<EOF
DELETE WHERE
{
  <${END_USER_BASE_URL}#person> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> ?type
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

# Verify the type is gone and the name stays. Body captured into a variable rather than piped, as in
# PATCH-remove-subresource.sh: the pipe races with Varnish invalidation after the PATCH.

body=$(curl -k -f -s -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$END_USER_BASE_URL")

if echo "$body" | grep -q "<${END_USER_BASE_URL}#person> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type>"; then
    echo "FAIL: sub-resource still typed after PATCH"
    exit 1
fi

echo "$body" | grep -q "<${END_USER_BASE_URL}#person> <http://xmlns.com/foaf/0.1/name> \"Test person\""
