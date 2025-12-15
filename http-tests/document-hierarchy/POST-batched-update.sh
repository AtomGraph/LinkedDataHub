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

# create two test documents
pushd . > /dev/null && cd "$SCRIPT_ROOT/admin/acl"

GRAPH1_URI="${END_USER_BASE_URL}test-graph-1/"
GRAPH2_URI="${END_USER_BASE_URL}test-graph-2/"

# create first test graph
./create-authorization.sh \
  -b "$END_USER_BASE_URL" \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --label "Test Graph 1" \
  --uri "$GRAPH1_URI" \
  --agent "${ADMIN_BASE_URL}acl/agents/test/#this"

# create second test graph
./create-authorization.sh \
  -b "$END_USER_BASE_URL" \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --label "Test Graph 2" \
  --uri "$GRAPH2_URI" \
  --agent "${ADMIN_BASE_URL}acl/agents/test/#this"

popd > /dev/null

# add initial data to both graphs
(
curl -k -w "%{http_code}\n" -o /dev/null -f -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Content-Type: application/n-triples" \
  --data-binary @- \
  "$GRAPH1_URI" <<EOF
<${GRAPH1_URI}> <http://purl.org/dc/terms/title> "Graph 1" .
<${GRAPH1_URI}#item> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://xmlns.com/foaf/0.1/Document> .
<${GRAPH1_URI}#item> <http://purl.org/dc/terms/title> "Item 1" .
EOF
) | grep -q "$STATUS_CREATED"

(
curl -k -w "%{http_code}\n" -o /dev/null -f -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Content-Type: application/n-triples" \
  --data-binary @- \
  "$GRAPH2_URI" <<EOF
<${GRAPH2_URI}> <http://purl.org/dc/terms/title> "Graph 2" .
<${GRAPH2_URI}#item> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://xmlns.com/foaf/0.1/Document> .
<${GRAPH2_URI}#item> <http://purl.org/dc/terms/title> "Item 2" .
EOF
) | grep -q "$STATUS_CREATED"

# perform batched update on both graphs using the new /update endpoint
update=$(cat <<EOF
WITH <${GRAPH1_URI}>
DELETE { ?item <http://purl.org/dc/terms/title> ?oldTitle }
INSERT { ?item <http://purl.org/dc/terms/title> "Updated Item 1" }
WHERE { ?item <http://purl.org/dc/terms/title> ?oldTitle } ;

WITH <${GRAPH2_URI}>
DELETE { ?item <http://purl.org/dc/terms/title> ?oldTitle }
INSERT { ?item <http://purl.org/dc/terms/title> "Updated Item 2" }
WHERE { ?item <http://purl.org/dc/terms/title> ?oldTitle }
EOF
)

curl -k -w "%{http_code}\n" -o /dev/null -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -X POST \
  -H "Content-Type: application/sparql-update" \
  "${END_USER_BASE_URL}update" \
  --data-binary "$update" \
| grep -q "$STATUS_NO_CONTENT"

# verify both graphs were updated
curl -k -f -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$GRAPH1_URI" \
| grep -q "Updated Item 1"

curl -k -f -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$GRAPH2_URI" \
| grep -q "Updated Item 2"
