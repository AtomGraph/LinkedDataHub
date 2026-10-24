#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# A PATCH inserting a malformed IRI is refused with 422, and the body names the value as an ldh:URISyntaxViolation, so
# a form can mark the field it was typed into. Two kinds: one the SPARQL lexer stops at (a space), and one it lets
# through as an IRI reference that is not one (an unterminated IPv6 host), which used to be stored. Neither changes
# the document.

item=$(ldh create item \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --title "Target" \
  --slug "patch-invalid-uri" \
  --container "$END_USER_BASE_URL")

for value in "not a uri" "http://[::1"; do
    update="INSERT DATA { <${item}#this> <http://www.w3.org/2000/01/rdf-schema#seeAlso> <${value}> }"

    response=$(curl -k -w "%{http_code}\n" -s \
      -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
      -X PATCH \
      -H "If-Match: $(etag "$item" "$OWNER_CERT_FILE" "$OWNER_CERT_PWD" "application/n-triples")" \
      -H "Accept: application/n-triples" \
      -H "Content-Type: application/sparql-update" \
      "$item" \
      --data-binary "$update")

    status=$(echo "$response" | tail -n 1)
    body=$(echo "$response" | sed '$d')

    echo "DEBUG: [${value}] Expected status: $STATUS_UNPROCESSABLE_ENTITY"
    echo "DEBUG: [${value}] Got status: $status"
    echo "DEBUG: [${value}] Body:"
    echo "$body"
    if [ "$status" != "$STATUS_UNPROCESSABLE_ENTITY" ]; then
        echo "DEBUG: Status mismatch!"
        exit 1
    fi

    expected="<https://w3id.org/atomgraph/linkeddatahub#violationValue> \"${value}\""
    echo "DEBUG: [${value}] Expected present: $expected"
    if ! grep -qF "$expected" <<< "$body"; then
        echo "DEBUG: Violation value missing!"
        exit 1
    fi

    expected="<http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://w3id.org/atomgraph/linkeddatahub#URISyntaxViolation>"
    if ! grep -qF "$expected" <<< "$body"; then
        echo "DEBUG: Violation type missing!"
        exit 1
    fi
done

# the refused updates stored nothing

item_ntriples=$(curl -k -f -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$item")

if grep -qF "<http://www.w3.org/2000/01/rdf-schema#seeAlso>" <<< "$item_ntriples"; then
    echo "DEBUG: A refused update was stored!"
    echo "$item_ntriples"
    exit 1
fi
