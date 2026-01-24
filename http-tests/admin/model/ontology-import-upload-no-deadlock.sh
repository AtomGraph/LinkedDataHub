#!/usr/bin/env bash
set -euo pipefail

# Test that ontology imports of uploaded files do not cause deadlock
# This verifies the fix for circular dependency when:
# 1. Request arrives for /uploads/xyz
# 2. OntologyFilter intercepts it and loads ontology
# 3. Ontology has owl:imports for /uploads/xyz
# 4. Jena FileManager makes HTTP request to /uploads/xyz
# 5. Would cause infinite loop/deadlock without the fix

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

pwd=$(realpath "$PWD")

# add agent to the writers group so they can upload files

add-agent-to-group.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

# Step 1: Upload an RDF file

file_content_type="text/turtle"

file_doc=$(create-file.sh \
  -f "$AGENT_CERT_FILE" \
  -p "$AGENT_CERT_PWD" \
  -b "$END_USER_BASE_URL" \
  --title "Test ontology for upload import" \
  --file "$pwd/test-ontology-import.ttl" \
  --file-content-type "${file_content_type}")

# Step 2: Extract the uploaded file URI (content-addressed)

file_doc_ntriples=$(get.sh \
  -f "$AGENT_CERT_FILE" \
  -p "$AGENT_CERT_PWD" \
  --accept 'application/n-triples' \
  "$file_doc")

upload_uri=$(echo "$file_doc_ntriples" | sed -rn "s/<${file_doc//\//\\/}> <http:\/\/xmlns.com\/foaf\/0.1\/primaryTopic> <(.*)> \./\1/p")

echo "Uploaded file URI: $upload_uri"

# Verify the uploaded file is accessible before we add it as an import
curl -k -f -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: ${file_content_type}" \
  "$upload_uri" > /dev/null

echo "Upload file is accessible"

# Step 3: Add the uploaded file as an owl:import to the namespace ontology

namespace_doc="${END_USER_BASE_URL}ns"
namespace="${namespace_doc}#"
ontology_doc="${ADMIN_BASE_URL}ontologies/namespace/"

add-ontology-import.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --import "$upload_uri" \
  "$ontology_doc"

echo "Added owl:import of uploaded file to namespace ontology"

# Step 4: Clear the namespace ontology from memory to force reload on next request

clear-ontology.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  -b "$ADMIN_BASE_URL" \
  --ontology "$namespace"

echo "Cleared ontology cache to force reload"

# Step 5: Make a request that triggers ontology loading
# This would cause a deadlock without the OntologyFilter fix
# Use portable timeout implementation (works on both macOS and Linux)

echo "Making request to trigger ontology loading (testing for deadlock)..."
echo "DEBUG: Target URL: $namespace_doc"
echo "DEBUG: Using cert: $OWNER_CERT_FILE"

# Portable timeout function - works on both macOS and Linux
# Use temporary file to capture curl output and status
temp_output=$(mktemp)
temp_stderr=$(mktemp)
request_pid=""
(
  curl -k -f -w "\nHTTP_STATUS:%{http_code}\n" \
    -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
    -H "Accept: application/n-triples" \
    "$namespace_doc" > "$temp_output" 2> "$temp_stderr"
) &
request_pid=$!

# Wait up to 30 seconds for the request to complete
timeout_seconds=30
elapsed=0
while kill -0 "$request_pid" 2>/dev/null; do
  if [ $elapsed -ge $timeout_seconds ]; then
    kill -9 "$request_pid" 2>/dev/null || true
    echo "ERROR: Request timed out after ${timeout_seconds} seconds - deadlock detected!"
    echo "DEBUG: Curl stderr output:"
    cat "$temp_stderr"
    rm -f "$temp_output" "$temp_stderr"
    exit 1
  fi
  sleep 1
  ((elapsed++))
done

# Check if curl succeeded
wait "$request_pid"
curl_exit_code=$?

echo "DEBUG: Curl exit code: $curl_exit_code"
echo "DEBUG: Curl stderr:"
cat "$temp_stderr"
echo "DEBUG: Response (first 500 chars):"
head -c 500 "$temp_output"
echo ""

if [ $curl_exit_code -ne 0 ]; then
  echo "ERROR: Request failed with exit code $curl_exit_code"
  rm -f "$temp_output" "$temp_stderr"
  exit 1
fi

# Extract HTTP status code
http_status=$(grep "HTTP_STATUS:" "$temp_output" | cut -d':' -f2)
echo "DEBUG: HTTP status code: $http_status"

rm -f "$temp_output" "$temp_stderr"

echo "Request completed successfully in ${elapsed}s (no deadlock)"

# Step 6: Verify the import is present in the loaded ontology

curl -k -f -s \
  -H "Accept: application/n-triples" \
  "$namespace_doc" \
| grep "<${namespace}> <http://www.w3.org/2002/07/owl#imports> <${upload_uri}>" > /dev/null

echo "Verified owl:import is present in namespace ontology"

# Step 7: Verify the uploaded file is still accessible after ontology loading

curl -k -f -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: ${file_content_type}" \
  "$upload_uri" > /dev/null

echo "Uploaded file is still accessible after ontology import"

# Step 8: Verify that the imported ontology content is accessible via the namespace document
# This confirms the import was actually loaded (not just skipped)

curl -k -f -s \
  -G \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H 'Accept: application/sparql-results+xml' \
  --data-urlencode "query=SELECT * { <https://example.org/test#TestClass> ?p ?o }" \
  "$namespace_doc" \
| grep '<literal>Test Class</literal>' > /dev/null

echo "Verified imported ontology content is accessible via SPARQL"

echo "✓ All tests passed - no deadlock detected when importing uploaded files in ontology"
