#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# A page on another site can make the browser submit a form to a document, and the browser presents the agent's client
# certificate with it: SameSite does not govern a TLS client certificate, and an RDF/POST form needs no CORS preflight.
# The request is told by its Origin. A write whose Origin is not the dataspace's is refused and made nowhere; one from the
# dataspace's own origin, and one with no Origin (the CLI, a server-side client), is made.

item=$(ldh create item \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --title "Cross-origin write target" \
  --container "$END_USER_BASE_URL")

# Submits an RDF/POST form appending the description to the document as the owner, with the Origin given (none if it is
# empty); prints the status
submit()
{
    local origin="$1" description="$2"

    curl -k -s -o /dev/null -w '%{http_code}' \
      -X POST \
      -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
      -H 'Accept: application/n-triples' \
      -H 'Content-Type: application/x-www-form-urlencoded' \
      ${origin:+-H "Origin: $origin"} \
      --data-urlencode "rdf=" \
      --data-urlencode "su=${item}" \
      --data-urlencode "pu=http://purl.org/dc/terms/description" \
      --data-urlencode "ol=${description}" \
      "$item"
}

# Whether the document carries the description, read directly by the owner
has_description()
{
    curl -k -f -s \
      -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
      -H 'Accept: application/n-triples' \
      "$item" \
    | grep -qF "\"$1\""
}

refused()
{
    local origin="$1" description="$2" code
    code=$(submit "$origin" "$description")
    echo "DEBUG: Origin: '$origin' - Expected: $STATUS_FORBIDDEN  Got: $code"
    [ "$code" = "$STATUS_FORBIDDEN" ] || exit 1
    if has_description "$description"; then
        echo "DEBUG: the write from '$origin' was made"
        exit 1
    fi
}

made()
{
    local origin="$1" description="$2" code
    code=$(submit "$origin" "$description")
    echo "DEBUG: Origin: '$origin' - Expected: 2xx  Got: $code"
    [[ "$code" = 2* ]] || exit 1
    has_description "$description" || { echo "DEBUG: the write from '$origin' did not land"; exit 1; }
}

refused "https://evil.example" "From another site"
refused "null" "From an opaque origin"
refused "${ADMIN_BASE_URL%/}" "From the admin application"

made "${END_USER_BASE_URL%/}" "From the dataspace"
made "" "From no origin"

# the rule is the method's, not the form's: a DELETE from another site leaves the document

code=$(curl -k -s -o /dev/null -w '%{http_code}' \
  -X DELETE \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H 'Origin: https://evil.example' \
  "$item")

echo "DEBUG: DELETE from another site - Expected: $STATUS_FORBIDDEN  Got: $code"
[ "$code" = "$STATUS_FORBIDDEN" ] || exit 1
has_description "From the dataspace" || { echo "DEBUG: the document is gone"; exit 1; }
