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

# Regression: ProxyRequestFilter must forward the client's Accept header verbatim to the
# upstream, NOT substitute its own readable-types list. Previously the filter built its
# outbound Accept from MediaTypes.getReadable(Model.class) + getReadable(ResultSet.class)
# (everything Jena could ingest, all q=1.0), discarding what the client actually asked for.
# The upstream then content-negotiated against that broad list and could legally pick any
# RDF format — e.g. application/rdf+thrift — even when the client (e.g. SaxonJS document())
# explicitly requested application/rdf+xml or application/xml.
#
# Verify by requesting one specific RDF type and asserting the response matches it.

for accept in 'application/rdf+xml' 'text/turtle' 'application/n-triples'; do
    content_type=$(curl -k -f -s -G -w "%{content_type}" -o /dev/null \
      -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
      -H "Accept: $accept" \
      --data-urlencode "uri=${END_USER_BASE_URL}" \
      "$ADMIN_BASE_URL")

    case "$content_type" in
        "$accept"*) ;;
        *) exit 1 ;;
    esac
done
