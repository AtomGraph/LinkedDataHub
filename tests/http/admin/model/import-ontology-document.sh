#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# An ontology can be imported from a document of the dataspace, as a vocabulary vendored into it is. The fetched
# description is the document's too, and the document's sioc:has_container would state another application's
# hierarchy in the admin graph, which the server refuses; the import leaves it out and keeps the vocabulary.

vocabulary_uri="http://example.org/vendored-vocabulary"

# the end-user document holding the vocabulary

source=$(ldh create item \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --title "Vendored vocabulary" \
  --slug "vendored-vocabulary" \
  --container "$END_USER_BASE_URL")

ldh post \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  -t "application/n-triples" \
  "$source" <<EOF
<${vocabulary_uri}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/2002/07/owl#Ontology> .
<${vocabulary_uri}#Thing> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/2002/07/owl#Class> .
<${vocabulary_uri}#Thing> <http://www.w3.org/2000/01/rdf-schema#label> "Thing"@en .
<${vocabulary_uri}#part> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/2002/07/owl#ObjectProperty> .
<${vocabulary_uri}#part> <http://www.w3.org/2000/01/rdf-schema#domain> <${vocabulary_uri}#Thing> .
<${vocabulary_uri}#part> <http://www.w3.org/2000/01/rdf-schema#range> <${vocabulary_uri}#Thing> .
EOF

# the admin document it is imported into

item=$(ldh create item \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --title "Vendored vocabulary" \
  --slug "vendored-vocabulary" \
  --container "${ADMIN_BASE_URL}ontologies/")

ldh admin import ontology \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --source "$source" \
  --graph "$item" \
  "$ADMIN_BASE_URL"

# the vocabulary is in the item graph, with the constructor derived from it

curl -k -f -s \
  -G \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H 'Accept: application/sparql-results+xml' \
  --data-urlencode "query=SELECT * { <${vocabulary_uri}#Thing> <http://spinrdf.org/spin#constructor> ?constructor }" \
  --data-urlencode "default-graph-uri=${item}" \
  "${ADMIN_BASE_URL}sparql" \
| grep '<result>' > /dev/null

# and the source document's place in the end-user hierarchy is not

result=$(curl -k -f -s \
  -G \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H 'Accept: application/sparql-results+xml' \
  --data-urlencode "query=SELECT * { <${source}> ?containment ?parent VALUES ?containment { <http://rdfs.org/sioc/ns#has_container> <http://rdfs.org/sioc/ns#has_parent> } }" \
  --data-urlencode "default-graph-uri=${item}" \
  "${ADMIN_BASE_URL}sparql")
count=$(echo "$result" | xmllint --xpath "count(//*[local-name() = 'result'])" -)
echo "DEBUG: containment of the source document in the item graph. Expected: 0  Got: $count"
if [ "$count" != "0" ]; then
  exit 1
fi
