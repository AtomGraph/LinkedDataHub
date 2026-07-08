#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# sp:Describe is declared only as rdfs:Class (not owl:Class) in sp.ttl.
# OntologyFilter must promote rdfs:Class to owl:Class during materialization so
# that OWL2 profiles recognise third-party vocab terms and return their SPIN constructors.

response=$(curl -k -f -s \
  -G \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/rdf+xml" \
  --data-urlencode "forClass=http://spinrdf.org/sp#Describe" \
  "${END_USER_BASE_URL}ns")

# response must be non-empty: sp:Describe must be recognised as an OntClass
echo "$response" | grep -q "http://spinrdf.org/sp#Describe"
