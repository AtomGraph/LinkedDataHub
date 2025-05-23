#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

pwd=$(realpath "$PWD")

# add agent to the writers group

add-agent-to-group.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

# create container

container=$(create-container.sh \
  -f "$AGENT_CERT_FILE" \
  -p "$AGENT_CERT_PWD" \
  -b "$END_USER_BASE_URL" \
  --title "Test" \
  --slug "test" \
  --parent "$END_USER_BASE_URL")

# import CSV

import-csv.sh \
  -f "$AGENT_CERT_FILE" \
  -p "$AGENT_CERT_PWD" \
  -b "$END_USER_BASE_URL" \
  --title "Test" \
  --query-file "$pwd/csv-test.rq" \
  --file "$pwd/test.csv"

csv_id="test-item"
csv_value="42"

# wait until the imported item appears (since import is executed asynchronously)

counter=20
i=0

while [ "$i" -lt "$counter" ] && ! curl -k -s -f -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" "${container}${csv_id}/" -H "Accept: application/n-triples" >/dev/null 2>&1
do
    sleep 1 ;
    i=$(( i+1 ))

    echo "Waited ${i}s..."
done

# check item properties

curl -k -f -s -N \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "${container}${csv_id}/" \
| grep "<${container}${csv_id}/> <http://www.w3.org/1999/02/22-rdf-syntax-ns#value> \"${csv_value}\"^^<http://www.w3.org/2001/XMLSchema#integer>" > /dev/null