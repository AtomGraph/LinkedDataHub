#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# A PATCH update is executed by the platform itself, on the document's graph in memory, so a SERVICE clause in its
# WHERE is fetched from inside the platform container rather than from the triplestore. It must not reach the internal
# admin store: a writer could otherwise copy agents and authorizations into a document they can read.
# SERVICE SILENT turns a refused call into a single empty solution, which leaves ?g unbound and inserts nothing, so the
# document is checked for data rather than the response for a status code

# add agent to the writers group

ldh admin add agent \
  -f "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

# create an item to patch

item=$(ldh create item \
  -f "$AGENT_CERT_KEYSTORE" \
  -p "$AGENT_CERT_PWD" \
  -b "$END_USER_BASE_URL" \
  --title "SERVICE PATCH target" \
  --container "$END_USER_BASE_URL")

endpoint="http://fuseki:3030/admin/"

update=$(cat <<EOF
INSERT
{
  <${item}> <urn:test:leak> ?g
}
WHERE
{
  SERVICE SILENT <${endpoint}>
  {
    SELECT ?g
    {
      GRAPH ?g { ?s ?p ?o }
    }
    LIMIT 1
  }
}
EOF
)

curl -k -f -s -o /dev/null \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PATCH \
  -H "Content-Type: application/sparql-update" \
  "$item" \
  --data-binary "$update"

# check that nothing from the admin store was inserted

document=$(curl -k -f -s -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$item")

echo "DEBUG: ${item} after PATCH: ${document}"

if grep -q '<urn:test:leak>' <<< "$document"; then
    echo "SERVICE <${endpoint}> in a PATCH returned data"
    exit 1
fi
