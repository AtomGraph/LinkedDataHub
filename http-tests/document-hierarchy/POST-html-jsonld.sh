#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# add agent to the writers group

add-agent-to-group.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

# POST an HTML document with an embedded JSON-LD <script> block;
# HtmlJsonLDReader should extract the JSON-LD and the triple should land in the graph

(
curl -k -w "%{http_code}\n" -o /dev/null -f -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  -H "Content-Type: text/html" \
  --data-binary @- \
  "$END_USER_BASE_URL" <<EOF
<!DOCTYPE html><html><head><title>HTML/JSON-LD POST test</title><script type="application/ld+json">{"@context":{"ex":"http://example.com/","label":{"@id":"ex:default-predicate"}},"@id":"${END_USER_BASE_URL}named-subject-html-jsonld","label":"named object HTML/JSON-LD POST"}</script></head><body></body></html>
EOF
) \
| grep -q "$STATUS_NO_CONTENT"

# check that the triple from the embedded JSON-LD is queryable

curl -k -f -s -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
"$END_USER_BASE_URL" \
| tr -d '\n' \
| grep '"named object HTML/JSON-LD POST"' > /dev/null
