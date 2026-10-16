#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

namespace_doc="${END_USER_BASE_URL}ns"
ontology_doc="${ADMIN_BASE_URL}ontologies/namespace/"
file=$(mktemp)
trap 'rm -f "$file"' EXIT

ns_terms() {
  curl -k -f -s -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" -H "Accept: application/n-triples" "$namespace_doc"
}

# install a namespace ontology from a file, given only the end-user base: the command finds the admin application
# and the ontology IRI from the base's Link headers

cat > "$file" <<'TTL'
@prefix :     <#> .
@prefix owl:  <http://www.w3.org/2002/07/owl#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .

:Book a owl:Class ; rdfs:label "Book" ; rdfs:isDefinedBy : .
:Shelf a owl:Class ; rdfs:label "Shelf" ; rdfs:isDefinedBy : .
TTL

doc=$(ldh admin import ontology -c "$OWNER_CERT_KEYSTORE" -p "$OWNER_CERT_PWD" -t text/turtle --file "$file" "$END_USER_BASE_URL")
echo "DEBUG: Expected: $ontology_doc  Got: $doc"
[ "$doc" = "$ontology_doc" ] || exit 1

# the new terms are served by the namespace, without a manual clear

ns_terms | grep -q "<${namespace_doc}#Book> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/2002/07/owl#Class>" || { echo "DEBUG: Book missing from $namespace_doc"; exit 1; }

# re-install without Shelf: the install replaces, so Shelf is gone and Book stays

cat > "$file" <<'TTL'
@prefix :     <#> .
@prefix owl:  <http://www.w3.org/2002/07/owl#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .

:Book a owl:Class ; rdfs:label "Book" ; rdfs:isDefinedBy : .
TTL

ldh admin import ontology -c "$OWNER_CERT_KEYSTORE" -p "$OWNER_CERT_PWD" -t text/turtle --file "$file" "$END_USER_BASE_URL" > /dev/null

terms=$(ns_terms)
echo "$terms" | grep -q "<${namespace_doc}#Book> " || { echo "DEBUG: Book missing after re-install"; exit 1; }
if echo "$terms" | grep -q "<${namespace_doc}#Shelf> "; then
  echo "DEBUG: Shelf survived a re-install without it"
  exit 1
fi

# the seeded header survives, with the import of the platform's ontology

curl -k -f -s -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" -H "Accept: application/n-triples" "$ontology_doc" |
  grep -q "<${namespace_doc}#> <http://www.w3.org/2002/07/owl#imports> <https://w3id.org/atomgraph/linkeddatahub/default#>" ||
  { echo "DEBUG: owl:imports of the default ontology is gone from $ontology_doc"; exit 1; }
