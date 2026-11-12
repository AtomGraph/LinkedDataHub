#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# An ontology created without --uri is a blank node. Writing it must not fail on the ontology cache, which holds
# ontologies by URI and so has nothing of a blank node's to clear.

ontology_doc=$(ldh admin create ontology \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --label "Blank node ontology" \
  --slug "blank-node-ontology" \
  "$ADMIN_BASE_URL")

# the document holds the ontology, labelled

curl -k -f -s \
  -G \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H 'Accept: application/sparql-results+xml' \
  --data-urlencode "query=SELECT * { ?ontology a <http://www.w3.org/2002/07/owl#Ontology> ; <http://www.w3.org/2000/01/rdf-schema#label> \"Blank node ontology\" }" \
  --data-urlencode "default-graph-uri=${ontology_doc}" \
  "${ADMIN_BASE_URL}sparql" \
| grep '<result>' > /dev/null
