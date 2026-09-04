#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# the constructor SELECT the client-side instantiation relies on: for a type set it returns the
# spin:constructor texts of the classes and their superclasses, deduplicated

query='SELECT DISTINCT ?constructor ?text WHERE { VALUES ?type { <https://w3id.org/atomgraph/linkeddatahub/apps#Application> <https://w3id.org/atomgraph/linkeddatahub/apps#EndUserApplication> } ?type <http://www.w3.org/2000/01/rdf-schema#subClassOf>* ?class . ?class <http://spinrdf.org/spin#constructor> ?constructor . ?constructor <http://spinrdf.org/sp#text> ?text . }'

results=$(curl -k -f -s -G \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/sparql-results+xml" \
  "${END_USER_BASE_URL}ns" \
  --data-urlencode "query=${query}")

# the end-user app class's own constructor is returned
echo "$results" | grep -q "https://w3id.org/atomgraph/linkeddatahub/apps#EndUserApplicationConstructor"

# the generic constructors attached to lapp:Application by the default ontology are returned
echo "$results" | grep -q "https://w3id.org/atomgraph/linkeddatahub#TitleConstructor"

# the constructor texts are returned (CONSTRUCT templates the client instantiates)
count=$(echo "$results" | xmllint --xpath "count(//*[local-name() = 'binding'][@name = 'text']/*[local-name() = 'literal'][contains(., 'CONSTRUCT')])" -)
if [ "$count" -lt 3 ]; then
  exit 1
fi
