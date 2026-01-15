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

# Test that PATCH with DELETE WHERE that matches no triples does NOT delete the entire graph
# This is a regression test for bug where changedModel.isEmpty() incorrectly triggered graph deletion

# Create test graph URI
test_graph_uri="${ADMIN_BASE_URL}test-graph-$(date +%s)/"

# Create test graph with multiple triples using bin/put.sh
echo "<http://example.org/resource1> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://example.org/TestClass> .
<http://example.org/resource1> <http://example.org/property1> \"value1\" .
<http://example.org/resource1> <http://example.org/property2> \"value2\" .
<http://example.org/resource2> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://example.org/OtherClass> .
<http://example.org/resource2> <http://example.org/property3> \"value3\" ." | \
  put.sh \
    -f "$OWNER_CERT_FILE" \
    -p "$OWNER_CERT_PWD" \
    -t "application/n-triples" \
    "$test_graph_uri"

# Execute PATCH with DELETE WHERE that matches nothing (non-existent triple)
echo "PREFIX ex: <http://example.org/>
PREFIX owl: <http://www.w3.org/2002/07/owl#>

DELETE WHERE { ex:nonExistentResource owl:imports ex:nonExistentOntology }" | \
  patch.sh \
    -f "$OWNER_CERT_FILE" \
    -p "$OWNER_CERT_PWD" \
    "$test_graph_uri"

# Verify graph still exists and contains original triples
graph_content=$(get.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --accept "application/n-triples" \
  "$test_graph_uri")

# Verify essential triples are still present (grep for exact n-triples format)
echo "$graph_content" | grep -q "<http://example.org/resource1> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://example.org/TestClass>"
echo "$graph_content" | grep -q "<http://example.org/resource1> <http://example.org/property1> \"value1\""
echo "$graph_content" | grep -q "<http://example.org/resource2> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://example.org/OtherClass>"
echo "$graph_content" | grep -q "<http://example.org/resource2> <http://example.org/property3> \"value3\""
