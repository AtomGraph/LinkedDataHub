#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# add agent to the writers group

add-agent-to-group.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

# POST a typed sub-resource (foaf:Person) to the root document.

(
curl -k -w "%{http_code}\n" -o /dev/null -f -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  -H "Content-Type: application/n-triples" \
  --data-binary @- \
  "$END_USER_BASE_URL" <<EOF
<${END_USER_BASE_URL}#person> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://xmlns.com/foaf/0.1/Person> .
<${END_USER_BASE_URL}#person> <http://xmlns.com/foaf/0.1/name> "Test person" .
EOF
) \
| grep -q "$STATUS_NO_CONTENT"

# PATCH the root to delete all triples of the sub-resource. The sub-resource loses
# its rdf:type but is also no longer present in the graph at all, so the
# rdf:type-removal guard must NOT fire (legitimate sub-resource removal).

update=$(cat <<EOF
DELETE WHERE
{
  <${END_USER_BASE_URL}#person> ?p ?o
}
EOF
)

curl -k -w "%{http_code}\n" -o /dev/null -f -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PATCH \
  -H "Content-Type: application/sparql-update" \
  "$END_USER_BASE_URL" \
   --data-binary "$update" \
| grep -q "$STATUS_NO_CONTENT"

# Verify the sub-resource is gone. Body capture into a variable (rather than piping
# curl directly to grep) is intentional: the pipe-to-grep variant races with Varnish
# cache invalidation propagation after PATCH and intermittently sees stale data.

body=$(curl -k -f -s -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$END_USER_BASE_URL")

if echo "$body" | grep -q "<${END_USER_BASE_URL}#person>"; then
    echo "FAIL: sub-resource still present in GET body after PATCH"
    exit 1
fi
