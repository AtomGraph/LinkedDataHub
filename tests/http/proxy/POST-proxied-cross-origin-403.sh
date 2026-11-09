#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# A form another site makes the browser submit to the Linked Data proxy, as ?uri=: the proxy would write to the target
# with the platform's certificate and On-Behalf-Of naming the agent, to any origin that accepts the delegation. It is
# refused at the proxy, before it is forwarded, and nothing is written to the target. A write from the page's own origin
# goes through, so the proxy does not forward the Origin: the target, another origin, would refuse it.

remote_base="https://test.localhost:4443/"

item=$(ldh create item \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --title "Proxied cross-origin write target" \
  --container "$remote_base")

# Submits an RDF/POST form appending the description to the target through the proxy as the owner, against its current
# state and with the Origin and Accept given; prints the status
submit()
{
    local origin="$1" accept="$2" description="$3"

    curl -k -s -o /dev/null -w '%{http_code}' \
      -X POST \
      -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
      -H "Accept: $accept" \
      -H "If-Match: $(etag "$item" "$OWNER_CERT_FILE" "$OWNER_CERT_PWD" 'application/n-triples')" \
      -H 'Content-Type: application/x-www-form-urlencoded' \
      -H "Origin: $origin" \
      --url-query "uri=${item}" \
      --data-urlencode "rdf=" \
      --data-urlencode "su=${item}" \
      --data-urlencode "pu=http://purl.org/dc/terms/description" \
      --data-urlencode "ol=${description}" \
      "$END_USER_BASE_URL"
}

# Whether the target carries the description, read on it directly by the owner
has_description()
{
    curl -k -f -s \
      -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
      -H 'Accept: application/n-triples' \
      "$item" \
    | grep -qF "\"$1\""
}

# from another site, as an API client asks (proxied) and as a browser's form submission does (an (X)HTML Accept)

for accept in 'application/n-triples' 'text/html,application/xhtml+xml;q=0.9,*/*;q=0.8'; do
    code=$(submit "https://evil.example" "$accept" "From another site")
    echo "DEBUG: proxied POST from another site, Accept: $accept - Expected: $STATUS_FORBIDDEN  Got: $code"
    [ "$code" = "$STATUS_FORBIDDEN" ] || exit 1
done

if has_description "From another site"; then
    echo "DEBUG: the write from another site reached the target"
    exit 1
fi

# from the page's own origin

code=$(submit "${END_USER_BASE_URL%/}" 'application/n-triples' "From the dataspace")
echo "DEBUG: proxied POST from the dataspace - Expected: 2xx  Got: $code"
[[ "$code" = 2* ]] || exit 1
has_description "From the dataspace" || { echo "DEBUG: the proxied write did not land"; exit 1; }
