#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# add agent to the writers group

ldh admin add agent \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

# A PUT whose body says nothing about the document itself - an ontology file pushed as a document, say -
# was validated while the document was untyped, then typed dh:Item by the server and written without a
# title. The document the server types is now held to dh:Item's constraints: def:MissingTitle trips with
# the document as spin:violationRoot, nothing is written, and the 422 body describes the document but not
# the other resources in the body.

item="${END_USER_BASE_URL}$(uuidgen | tr '[:upper:]' '[:lower:]')/"

response=$(curl -k -w "%{http_code}\n" -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PUT \
  -H "Accept: application/n-triples" \
  -H "Content-Type: application/n-triples" \
  --data-binary @- \
  "$item" <<EOF
<${item}#ontology> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/2002/07/owl#Ontology> .
<${item}#ontology> <http://www.w3.org/2000/01/rdf-schema#label> "Untitled document's ontology" .
EOF
)

status=$(echo "$response" | tail -n 1)
body=$(echo "$response" | sed '$d')

echo "DEBUG: Expected status: $STATUS_UNPROCESSABLE_ENTITY"
echo "DEBUG: Got status: $status"
if [ "$status" != "$STATUS_UNPROCESSABLE_ENTITY" ]; then
    echo "DEBUG: Status mismatch!"
    exit 1
fi

ntriples=$(echo "$body" | rapper -q --input ntriples --output ntriples /dev/stdin -)
echo "DEBUG: Response body as N-Triples:"
echo "$ntriples"

# the violation rooted in the document

expected="<http://spinrdf.org/spin#violationRoot> <${item}>"
echo "DEBUG: Expected present: $expected"
if ! echo "$ntriples" | grep -qF "$expected"; then
    echo "DEBUG: Violation root missing!"
    exit 1
fi

# the document as the server typed it

expected="<${item}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://w3id.org/atomgraph/linkeddatahub/document-hierarchy#Item>"
echo "DEBUG: Expected present: $expected"
if ! echo "$ntriples" | grep -qF "$expected"; then
    echo "DEBUG: Violating document description missing!"
    exit 1
fi

# the rest of the body is scoped out

unexpected="^<${item}#ontology> "
echo "DEBUG: Expected absent as subject: <${item}#ontology>"
if echo "$ntriples" | grep -q "$unexpected"; then
    echo "DEBUG: Non-violating resource leaked into the 422 body!"
    exit 1
fi

# nothing was written: asked of the store rather than the document URL, which answers 403 for a document
# that does not exist (a typeless URL matches no authorization)

written=$(curl -s -G \
  -H "Accept: application/sparql-results+xml" \
  --data-urlencode "query=ASK { GRAPH <${item}> { ?s ?p ?o } }" \
  "$END_USER_ENDPOINT_URL" \
| xmllint --xpath "string(//*[local-name() = 'boolean'])" -)

echo "DEBUG: Expected graph written: false"
echo "DEBUG: Got graph written: $written"
if [ "$written" != "false" ]; then
    echo "DEBUG: The refused document was written!"
    exit 1
fi
