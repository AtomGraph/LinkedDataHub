#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# Regression test for ProxyRequestFilter swallowing PATCH to ontology-namespace URIs.
#
# Reproduces the real-world failure where editing a constructor in the UI fails
# silently on the second save. After the first save succeeds, clear-ontology
# rebuilds the in-memory OntModel from admin Fuseki. The constructor's hash URI
# is now in the OntModel. On the next PATCH via the end-user proxy, the DESCRIBE
# short-circuit in ProxyRequestFilter finds the hash URI, returns a false 200,
# and never forwards the write.
#
# Setup mirrors reality: the only admin graph that feeds the end-user OntModel
# is <admin.localhost:4443/ontologies/namespace/> (it declares
# <https://localhost:4443/ns#> a owl:Ontology). We PATCH that document directly
# to plant a constructor hash URI, then re-PATCH it via the end-user proxy.

namespace="${END_USER_BASE_URL}ns#"
ontology_doc="${ADMIN_BASE_URL}ontologies/namespace/"
constructor="${ontology_doc}#test-constructor"

initial_text="CONSTRUCT { ?this a <https://example.com/TestClass> . } WHERE {}"
updated_text="CONSTRUCT { ?this a <https://example.com/TestClassUpdated> . } WHERE {}"

# First save: PATCH the admin ontology document directly via LDH to insert the
# constructor (simulates the UI's first successful save before cache rebuild).
curl -k -f -s -o /dev/null \
  -X PATCH \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Content-Type: application/sparql-update" \
  --data-binary "
    PREFIX sp: <http://spinrdf.org/sp#>
    INSERT { <${constructor}> sp:text \"${initial_text}\" . } WHERE {}" \
  "$ontology_doc"

# Rebuild the in-memory ontology so the constructor hash URI enters the OntModel.
# After this, the DESCRIBE check in ProxyRequestFilter will fire for the PATCH.
clear-ontology.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  -b "$ADMIN_BASE_URL" \
  --ontology "$namespace"

# Second save: PATCH the same document via the end-user proxy.
# Before the fix, ProxyRequestFilter intercepts this with a false 200.
update=$(cat <<EOF
PREFIX sp: <http://spinrdf.org/sp#>
DELETE { <${constructor}> sp:text ?old . }
INSERT { <${constructor}> sp:text "${updated_text}" . }
WHERE  { OPTIONAL { <${constructor}> sp:text ?old . } }
EOF
)

curl -k -w "%{http_code}" -o /dev/null -s \
  -X PATCH \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Content-Type: application/sparql-update" \
  --url-query "uri=${ontology_doc}" \
  --data-binary "$update" \
  "$END_USER_BASE_URL" \
| grep -qE "$STATUS_PATCH_SUCCESS"

# Verify the update landed in the admin document (not silently swallowed).
curl -k -f -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$ontology_doc" \
| grep -q "TestClassUpdated"
