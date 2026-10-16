#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# Regression: ProxyRequestFilter replaced its own Vary with the upstream's. An upstream that sends Cache-Control
# without Vary: Accept - schema.org sends max-age=600 and no Vary at all - left the proxied RDF cacheable under the
# bare URL, so varnish-frontend served it to the next browser navigation of the same ?uri=, and the browser downloaded
# RDF instead of getting the application shell. The proxy chooses between the shell and the proxied body by Accept,
# so its response varies on Accept whatever the upstream says.
#
# Both requests are anonymous: varnish-frontend passes every request that carries a client certificate, so only an
# anonymous one is cached and only an anonymous one can be served from that cache.

target_uri='https://schema.org/WebSite'

# 1. the RDF request, as Saxon-JS makes it: proxied, and varying on Accept

response_headers=$(mktemp)

status=$(curl -k -s -G \
  -o /dev/null \
  -w "%{http_code}" \
  -D "$response_headers" \
  -H 'Accept: text/turtle' \
  --data-urlencode "uri=${target_uri}" \
  "$END_USER_BASE_URL")

cat "$response_headers"

if [ "$status" != "$STATUS_OK" ]; then
    echo "Expected $STATUS_OK for the proxied RDF, got $status"
    exit 1
fi

if ! tr -d '\r' < "$response_headers" | grep -i '^vary:' | grep -qiw 'accept'; then
    echo "The proxied RDF does not vary on Accept"
    exit 1
fi

# 2. the same URL as a browser navigation: (X)HTML, never the RDF stored by the request above. The end-user app is not
# public, so the anonymous answer is a 403 page - which is still HTML, where the poisoned cache answered 200 Turtle

response_headers=$(mktemp)

content_type=$(curl -k -s -G \
  -o /dev/null \
  -w "%{content_type}" \
  -D "$response_headers" \
  -H 'Accept: text/html' \
  --data-urlencode "uri=${target_uri}" \
  "$END_USER_BASE_URL")

cat "$response_headers"

case "$content_type" in
    text/html*) ;;
    *) echo "Expected text/html for a browser navigation, got $content_type"; exit 1 ;;
esac
