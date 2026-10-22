#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

pwd=$(realpath "$PWD")

# An import runs when it is defined. A PUT replaces the whole document, so it carries the document's imports
# every time; one that only retitles an import used to fetch and import its source again (RFC 9110 9.2.2).
# Every run appends a prov:startedAtTime to the import, so their number is the number of runs.

# add agent to the writers group

ldh admin add agent \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

item=$(ldh create item \
  -c "$AGENT_CERT_KEYSTORE" \
  -p "$AGENT_CERT_PWD" \
  --title "CSV import" \
  --container "$END_USER_BASE_URL")

ldh create container \
  -c "$AGENT_CERT_KEYSTORE" \
  -p "$AGENT_CERT_PWD" \
  --title "Test" \
  --slug "test" \
  --parent "$END_USER_BASE_URL" > /dev/null

import=$(ldh import csv \
  -c "$AGENT_CERT_KEYSTORE" \
  -p "$AGENT_CERT_PWD" \
  --title "Test" \
  --query-file "$pwd/csv-test.rq" \
  --csv-file "$pwd/test.csv" \
  --wait \
  "$item")

echo "DEBUG: import: $import"

# runs: prints how many times the import has started

function runs()
{
    curl -k -f -s -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" -H "Accept: application/n-triples" "$item" |
      grep -c "^<${import}> <http://www.w3.org/ns/prov#startedAtTime> " || true
}

before=$(runs)
echo "DEBUG: runs after the import. Expected: 1 Got: $before"
[ "$before" -eq 1 ] || exit 1

# re-PUT the document as it is stored, with only the import's title changed

document=$(curl -k -f -s -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" -H "Accept: application/n-triples" "$item" |
  sed "s|^<${import}> <http://purl.org/dc/terms/title> \"Test\" .|<${import}> <http://purl.org/dc/terms/title> \"Retitled\" .|")

echo "$document" | grep -q "^<${import}> <http://purl.org/dc/terms/title> \"Retitled\" ." || { echo "DEBUG: the import's title was not found to change: $document"; exit 1; }

status=$(printf '%s' "$document" | curl -k -w "%{http_code}" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PUT \
  -H "Accept: application/n-triples" \
  -H "Content-Type: application/n-triples" \
  -H "If-Match: $(etag "$item" "$AGENT_CERT_FILE" "$AGENT_CERT_PWD")" \
  --data-binary @- \
  "$item")

echo "DEBUG: retitle. Expected: $STATUS_NO_CONTENT Got: $status"
[ "$status" = "$STATUS_NO_CONTENT" ] || exit 1

# an import is asynchronous: give one that was wrongly submitted the time to start

sleep 5

after=$(runs)
echo "DEBUG: runs after the retitle. Expected: $before Got: $after"
[ "$after" -eq "$before" ] || exit 1

curl -k -f -s -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" -H "Accept: application/n-triples" "$item" |
  grep -q "^<${import}> <http://purl.org/dc/terms/title> \"Retitled\" ." || { echo "DEBUG: the retitle did not land"; exit 1; }
