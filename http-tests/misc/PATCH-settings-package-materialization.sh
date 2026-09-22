#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# Test: importing a package materializes its ontology as a document in the admin application. A package
# delivers constructors, and constructors are only editable where this instance can write to them, so
# the copy is what makes the package's constructors editable rather than merely visible.

app_uri="urn:linkeddatahub:apps/end-user"
package_uri="https://packages.linkeddatahub.com/editor/taxonomy/#this"
package_ontology="https://raw.githubusercontent.com/AtomGraph/LinkedDataHub-Apps/refs/heads/develop/packages/editor/taxonomy/ns.ttl#"
# the document URI is derived from the package URI's path, so it is predictable rather than a digest
doc="${ADMIN_BASE_URL}ontologies/editor-taxonomy/"

# counts results of a query scoped to the materialized document's graph
count_in_doc() {
  curl -k -f -s \
    -G \
    -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
    -H 'Accept: application/sparql-results+xml' \
    --data-urlencode "query=${1}" \
    --data-urlencode "default-graph-uri=${doc}" \
    "${ADMIN_BASE_URL}sparql" \
  | xmllint --xpath "count(//*[local-name() = 'result'])" -
}

assert_in_doc() {
  local phase="$1" query="$2" expected="$3" note="$4" got
  got=$(count_in_doc "$query")
  echo "DEBUG: [$phase] Expected: $expected  Got: $got"
  if [ "$got" != "$expected" ]; then
    echo "DEBUG: [$phase] $note" >&2
    exit 1
  fi
}

# nothing is materialized before the package is imported
status=$(curl -k -s -o /dev/null -w "%{http_code}" -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" -H "Accept: text/turtle" "$doc")
echo "DEBUG: [pre-import] document status. Expected: 404  Got: $status"
if [ "$status" != "404" ]; then
  echo "DEBUG: [pre-import] <${doc}> exists before the package was imported" >&2
  exit 1
fi

# declare the package import; Settings delegates to ClearOntology, which materializes
status=$(curl -k -w "%{http_code}" -o /dev/null -s \
  -X PATCH \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Content-Type: application/sparql-update" \
  -d "INSERT { <${app_uri}> <https://w3id.org/atomgraph/linkeddatahub#import> <${package_uri}> . } WHERE { }" \
  "${END_USER_BASE_URL}settings")
echo "DEBUG: [import PATCH] Expected: $STATUS_NO_CONTENT  Got: $status"
if ! grep -qE "^(${STATUS_NO_CONTENT})$" <<< "$status"; then
  exit 1
fi

purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# the document now exists and says what it is about
assert_in_doc "primary topic" \
  "SELECT * { <${doc}> <http://xmlns.com/foaf/0.1/primaryTopic> <${package_ontology}> }" \
  1 "the materialized document does not name the package ontology as its primary topic"

# it is a document, not the ontology: conflating the two is the shape this replaced
assert_in_doc "not an ontology" \
  "SELECT * { <${doc}> a <http://www.w3.org/2002/07/owl#Ontology> }" \
  0 "the materialized document claims to be the ontology"

# the package ontology is copied verbatim, header included - that header is what lets resolving the
# ontology URI find this graph
assert_in_doc "ontology header" \
  "SELECT * { <${package_ontology}> a <http://www.w3.org/2002/07/owl#Ontology> }" \
  1 "the package ontology's own header was not copied"

# and the constructors it delivers are here, which is the point: they now have a writable home
assert_in_doc "constructors" \
  "SELECT DISTINCT ?class { ?class <http://spinrdf.org/spin#constructor> ?constructor }" \
  3 "the package's constructors were not copied into the document"

# materialization is idempotent: importing again must not mint a second document
curl -k -s -o /dev/null -X PATCH \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Content-Type: application/sparql-update" \
  -d "INSERT { <${app_uri}> <https://w3id.org/atomgraph/linkeddatahub#import> <${package_uri}> . } WHERE { }" \
  "${END_USER_BASE_URL}settings"

result=$(curl -k -f -s \
  -G \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H 'Accept: application/sparql-results+xml' \
  --data-urlencode "query=SELECT DISTINCT ?g { GRAPH ?g { ?g <http://xmlns.com/foaf/0.1/primaryTopic> <${package_ontology}> } }" \
  "${ADMIN_BASE_URL}sparql")
count=$(echo "$result" | xmllint --xpath "count(//*[local-name() = 'result'])" -)
echo "DEBUG: [idempotence] materialized documents. Expected: 1  Got: $count"
if [ "$count" != "1" ]; then
  echo "DEBUG: [idempotence] re-importing the package minted another document" >&2
  exit 1
fi
