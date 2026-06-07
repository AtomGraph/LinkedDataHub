#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# add agent to the readers group to be able to read documents

add-agent-to-group.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/readers/"

# Regression: when an upstream proxied URI returns text/html (e.g. a schema.org term page)
# but embeds JSON-LD via <script type="application/ld+json">, ProxyRequestFilter must
# extract triples through HtmlJsonLDReader and serve them in the format the client
# requested via Accept. It must NOT relay the upstream's text/html bytes verbatim —
# that breaks downstream RDF consumers (SaxonJS, curl, anything expecting RDF).

target_uri='https://schema.org/WebSite'

# 1. Content-Type negotiation: response must satisfy the client's Accept (text/turtle),
#    not be passed through as upstream's text/html

content_type=$(curl -k -f -s -G -w "%{content_type}" -o /tmp/proxy-html-jsonld.body \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: text/turtle" \
  --data-urlencode "uri=${target_uri}" \
  "$END_USER_BASE_URL")

case "$content_type" in
    text/turtle*) ;;
    *) exit 1 ;;
esac

# 2. The body must parse as turtle and contain at least one triple with
#    <https://schema.org/WebSite> as its subject — the canonical @id of the
#    schema.org type defined by the JSON-LD embedded in the HTML page.

triple_count=$(rapper -q --input turtle --output ntriples /tmp/proxy-html-jsonld.body - \
  | grep -c "^<${target_uri}>" || true)

rm -f /tmp/proxy-html-jsonld.body

if [ "$triple_count" -lt 1 ]; then exit 1; fi
