#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"

namespace_doc="${END_USER_BASE_URL}ns"
namespace="${namespace_doc}#"
ontology_doc="${ADMIN_BASE_URL}ontologies/namespace/"
import_uri="http://www.w3.org/2004/02/skos/core"

# create item

slug="test"

item=$(create-item.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  -b "$ADMIN_BASE_URL" \
  --title "Test" \
  --slug "$slug" \
  --container "${ADMIN_BASE_URL}ontologies/")

# load the ontology, transform it and append it to the item document

curl -w "%{http_code}\n" -o /dev/null -k -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: text/turtle" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "rdf=" \
  --data-urlencode "sb=transform" \
  --data-urlencode "pu=http://spinrdf.org/spin#query" \
  --data-urlencode "ou=${ADMIN_BASE_URL}queries/construct-constructors/#this" \
  --data-urlencode "pu=http://purl.org/dc/terms/source" \
  --data-urlencode "ou=${import_uri}" \
  --data-urlencode "pu=http://www.w3.org/ns/sparql-service-description#name" \
  --data-urlencode "ou=${item}" \
  "${ADMIN_BASE_URL}transform" \
| grep -q "$STATUS_NO_CONTENT"

# add ontology import

add-ontology-import.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --import "$import_uri" \
  "$ontology_doc"

# clear the namespace ontology from memory

clear-ontology.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  -b "$ADMIN_BASE_URL" \
  --ontology "$namespace"

# check that the imported ontology is present in the ontology model TO-DO: replace with an ASK query when #118 is fixed

curl -k -f -s \
  -G \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H 'Accept: application/sparql-results+xml' \
  --data-urlencode "query=SELECT * { <${import_uri}> ?p ?o }" \
  "$namespace_doc" \
| grep '<literal xml:lang="en">SKOS Vocabulary</literal>' > /dev/null
