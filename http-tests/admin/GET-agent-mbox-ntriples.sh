#!/bin/bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_backend_cache "$END_USER_VARNISH_SERVICE"
purge_backend_cache "$ADMIN_VARNISH_SERVICE"

# request agent's RDF description

ntriples=$(curl -k -f -s -N \
  -H "Accept: application/n-triples" \
  "$AGENT_URI")

# check that the description does *not* include foaf:mbox property

echo "$ntriples" | grep -q -v "http://xmlns.com/foaf/0.1/mbox"

# check that the description includes foaf:mbox_sha1sum property

echo "$ntriples" | grep -q "http://xmlns.com/foaf/0.1/mbox_sha1sum"