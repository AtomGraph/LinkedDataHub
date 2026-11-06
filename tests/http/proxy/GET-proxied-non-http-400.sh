#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# Only http(s) is proxied: ?uri= is anyone's to set, and the client opens the document it names when the proxy fails
# (formal/client, fallback_web). A javascript: URI is refused as a bad request, for RDF and for the HTML shell alike.

for uri in 'javascript:alert(document.domain)' 'data:text/html,<script>alert(1)</script>' 'file:///etc/passwd'
do
    for accept in 'application/n-triples' 'text/html'
    do
        status=$(curl -k -s -o /dev/null -w "%{http_code}" \
          -G \
          -H "Accept: $accept" \
          --data-urlencode "uri=$uri" \
          "$END_USER_BASE_URL")
        echo "DEBUG: ?uri=$uri, Accept: $accept: Expected: $STATUS_BAD_REQUEST Got: $status"
        [ "$status" = "$STATUS_BAD_REQUEST" ]
    done
done
