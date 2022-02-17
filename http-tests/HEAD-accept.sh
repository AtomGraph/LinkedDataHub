#!/bin/bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_backend_cache "$END_USER_VARNISH_SERVICE"
purge_backend_cache "$ADMIN_VARNISH_SERVICE"

pushd . > /dev/null && cd "$SCRIPT_ROOT/admin/acl"

# add agent to the writers group to be able to read/write documents (might already be done by another test)

./add-agent-to-group.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

popd > /dev/null

# check that ?accept URL param overrides Accept header and returns Turtle (use Chrome's default Accept value)

content_type=$(curl -G --head -k -w "%{content_type}\n" -f -s -o /dev/null \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' \
  --data-urlencode "accept=text/turtle" \
  "$END_USER_BASE_URL")

[ "$content_type" = 'text/turtle;charset=UTF-8' ] || exit 1

# check that ?accept URL param overrides Accept header and returns RDF/XML (use Chrome's default Accept value)

content_type=$(curl -G --head -k -w "%{content_type}\n" -f -s -o /dev/null \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' \
  --data-urlencode "accept=application/rdf+xml" \
  "$END_USER_BASE_URL")

[ "$content_type" = 'application/rdf+xml;charset=UTF-8' ] || exit 1

# TO-DO: try to actually parse the response as Turtle and RDF/XML?