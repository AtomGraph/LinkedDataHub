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

container=$(ldh create container \
  -c "$AGENT_CERT_KEYSTORE" \
  -p "$AGENT_CERT_PWD" \
  --title "Test" \
  --slug "test" \
  --parent "$END_USER_BASE_URL")

# the command prints the import it created, and --wait returns only once the import has ended

import=$(ldh import csv \
  -c "$AGENT_CERT_KEYSTORE" \
  -p "$AGENT_CERT_PWD" \
  --title "Test" \
  --query-file "$pwd/csv-test.rq" \
  --csv-file "$pwd/test.csv" \
  --wait \
  "$item")

echo "DEBUG: printed import: $import"
case "$import" in
  "${item}#"*) ;;
  *) echo "DEBUG: Expected a fragment of $item"; exit 1 ;;
esac

# the import is a CSV import resource that has ended, and its data is there without polling

curl -k -f -s -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" -H "Accept: application/n-triples" "$item" |
  grep -q "<${import}> <http://www.w3.org/ns/prov#endedAtTime> " || { echo "DEBUG: <$import> has not ended"; exit 1; }

curl -k -f -s -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" -H "Accept: application/n-triples" "${container}test-item/" > /dev/null ||
  { echo "DEBUG: ${container}test-item/ was not imported"; exit 1; }
