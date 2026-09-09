#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# create the import target item

item=$(create-item.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  -b "$END_USER_BASE_URL" \
  --title "RDF import" \
  --container "$END_USER_BASE_URL")

# POST an ldh:RDFImport with the given ldh:file / spin:query and assert 400 Bad Request:
# the import URIs must be SSRF-validated before the server dereferences them (loopback stays allowed)

post_import()
{
    file="$1"
    query="$2"

    body="@prefix ldh:  <https://w3id.org/atomgraph/linkeddatahub#> .
@prefix dct:  <http://purl.org/dc/terms/> .
@prefix spin: <http://spinrdf.org/spin#> .
_:import a ldh:RDFImport ;
    dct:title \"SSRF test\" ;
    ldh:file <${file}> ."

    if [ -n "$query" ]; then
        body="${body}
_:import spin:query <${query}> ."
    fi

    curl -k -w "%{http_code}\n" -o /dev/null -s \
      -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
      -X POST \
      -H "Content-Type: text/turtle" \
      --data-binary "$body" \
      "$item" \
    | grep -q "$STATUS_BAD_REQUEST"
}

# SSRF via ldh:file: link-local (169.254/16) and RFC-1918 (10/8, 172.16/12, 192.168/16) sources must be rejected

post_import "http://169.254.1.1/data.ttl" ""
post_import "http://10.0.0.1/data.ttl" ""
post_import "http://172.16.0.0/data.ttl" ""
post_import "http://192.168.1.1/data.ttl" ""

# SSRF via spin:query: a valid (loopback) file but an internal transform-query URI must also be rejected

post_import "http://127.0.0.1/data.ttl" "http://10.0.0.1/query#this"
