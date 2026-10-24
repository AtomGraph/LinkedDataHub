#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# An RDF body with a malformed IRI is refused with 422, and the body names the value as an ldh:URISyntaxViolation:
# RDF/XML, which the create forms send, and Turtle, which the CLI does. The parser stops at the first one, so it is
# the only one named. Nothing is appended.

item=$(ldh create item \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --title "Target" \
  --slug "post-invalid-uri" \
  --container "$END_USER_BASE_URL")

# POST a payload and assert the 422 names the value

post()
{
    local value="$1" content_type="$2" payload="$3" response status body expected

    response=$(printf '%s\n' "$payload" | curl -k -w "%{http_code}\n" -s \
      -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
      -H "Accept: application/n-triples" \
      -H "Content-Type: ${content_type}" \
      --data-binary @- \
      "$item")

    status=$(echo "$response" | tail -n 1)
    body=$(echo "$response" | sed '$d')

    echo "DEBUG: [${content_type} ${value}] Expected status: $STATUS_UNPROCESSABLE_ENTITY"
    echo "DEBUG: [${content_type} ${value}] Got status: $status"
    echo "DEBUG: Body:"
    echo "$body"
    [ "$status" = "$STATUS_UNPROCESSABLE_ENTITY" ] || exit 1

    expected="<https://w3id.org/atomgraph/linkeddatahub#violationValue> \"${value}\""
    echo "DEBUG: Expected present: $expected"
    grep -qF "$expected" <<< "$body" || exit 1
}

post "not a uri" "application/rdf+xml" "<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:rdfs=\"http://www.w3.org/2000/01/rdf-schema#\"><rdf:Description rdf:about=\"${item}#this\"><rdfs:seeAlso rdf:resource=\"not a uri\"/></rdf:Description></rdf:RDF>"
post "http://[::1" "text/turtle" "<${item}#this> <http://www.w3.org/2000/01/rdf-schema#seeAlso> <http://[::1> ."

# the refused payloads appended nothing

item_ntriples=$(curl -k -f -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$item")

if grep -qF "<http://www.w3.org/2000/01/rdf-schema#seeAlso>" <<< "$item_ntriples"; then
    echo "DEBUG: A refused payload was appended!"
    echo "$item_ntriples"
    exit 1
fi
