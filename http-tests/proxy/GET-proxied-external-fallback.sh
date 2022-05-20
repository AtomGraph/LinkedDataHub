#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_backend_cache "$END_USER_VARNISH_SERVICE"
purge_backend_cache "$ADMIN_VARNISH_SERVICE"

pwd=$(realpath -s "$PWD")

pushd . > /dev/null && cd "$SCRIPT_ROOT/admin/acl"

# add agent to the writers group to be able to write documents (might already be done by another test)

./add-agent-to-group.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

popd > /dev/null

cd "$SCRIPT_ROOT"

# import data with URIs that do *not* dereference as RDF

cat "$pwd/../imports/test.ttl" \
| ./add-data.sh \
  -f "$AGENT_CERT_FILE" \
  -p "$AGENT_CERT_PWD" \
  -t 'text/turtle' \
  "$END_USER_BASE_URL"

concept7367_triple_count=14

popd > /dev/null

# attempt to load the concept7367 URI using LDH as a proxy

triple_count=$(curl -k -f -s \
  -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H 'Accept: application/n-triples' \
  --data-urlencode "uri=http://vocabularies.unesco.org/thesaurus/concept7367" \
  "$END_USER_BASE_URL" \
| rapper -q --input ntriples --output ntriples /dev/stdin - \
| wc -l)

# confirm that the number of triples is the same as returned by DESCRIBE over the local service (which is a fallback if the URL did not dereference)

if [ "$triple_count" != "$concept7367_triple_count" ]; then
    exit 1
fi