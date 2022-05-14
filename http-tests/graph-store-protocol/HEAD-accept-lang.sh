#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_backend_cache "$END_USER_VARNISH_SERVICE"
purge_backend_cache "$ADMIN_VARNISH_SERVICE"

pushd . > /dev/null && cd "$SCRIPT_ROOT/admin/acl"

# add agent to the readers group to be able to read documents (might already be done by another test)

./add-agent-to-group.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/readers/"

popd > /dev/null

# check that language negotiation works (use Chrome's Accept-Language value)

content_lang=$(curl -G --head -k -f -s -o /dev/null -D - \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' \
  -H 'Accept-Language: es-ES,es;q=0.9,en-US;q=0.8,en;q=0.7' \
  --data-urlencode "accept=text/turtle" \
  "$END_USER_BASE_URL"\
| tr -d '\r' | sed -En 's/^Content-Language: (.*)/\1/p')

[ "$content_lang" = 'es' ] || exit 1
