#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# Federation ontology leg: the constructor SELECT that drives A's client-side form derivation,
# posed against B's ns endpoint through A's proxy. On a remote pane the client resolves ns
# against the pane's data-base (B's base from the forwarded lapp:application Link), so forms
# for B's resources derive from B's ontology closure - this pins that contract on the wire.

remote_base="https://test.localhost:4443/"
remote_ns="${remote_base}ns"

query='SELECT DISTINCT ?constructor ?text WHERE { VALUES ?type { <https://w3id.org/atomgraph/linkeddatahub/apps#Application> <https://w3id.org/atomgraph/linkeddatahub/apps#EndUserApplication> } ?type <http://www.w3.org/2000/01/rdf-schema#subClassOf>* ?class . ?class <http://spinrdf.org/spin#constructor> ?constructor . ?constructor <http://spinrdf.org/sp#text> ?text . }'

results=$(curl -k -f -s \
  -X POST \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Content-Type: application/sparql-query" \
  -H "Accept: application/sparql-results+xml" \
  --url-query "uri=${remote_ns}" \
  --data-binary "$query" \
  "$END_USER_BASE_URL")

# the default LDH ontology is in every app's closure, so its constructors are returned by B

echo "$results" | grep -q "https://w3id.org/atomgraph/linkeddatahub#TitleConstructor"

count=$(echo "$results" | xmllint --xpath "count(//*[local-name() = 'binding'][@name = 'text']/*[local-name() = 'literal'][contains(., 'CONSTRUCT')])" -)
if [ "$count" -lt 1 ]; then
  echo "DEBUG: Expected at least 1 constructor text from the remote ns, got: $count"
  exit 1
fi
