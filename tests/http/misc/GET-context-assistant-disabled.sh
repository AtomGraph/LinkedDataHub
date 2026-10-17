#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# the assistant is opt-in (the "assistant" compose profile), and the test stack runs without it: the public dataspace
# context does not advertise it, so even the owner, who can append to the root, is not offered the Assistant button

for base in "$END_USER_BASE_URL" "$ADMIN_BASE_URL"; do
  context=$(curl -k -f -s -H "Accept: application/n-triples" "${base}context")

  if echo "$context" | grep -q '<https://w3id.org/atomgraph/linkeddatahub/dataspaces#assistant>'; then
    echo "DEBUG: ${base}context advertises the assistant:"
    echo "$context" | grep '<https://w3id.org/atomgraph/linkeddatahub/dataspaces#assistant>'
    exit 1
  fi
done

html=$(curl -k -f -s -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" -H "Accept: text/html" "$END_USER_BASE_URL")

# the creation bar renders for the owner, so a missing button is the gate and not a missing bar
echo "$html" | grep -q 'ldh-create-dock' || { echo "DEBUG: no creation bar in ${END_USER_BASE_URL} for the owner"; exit 1; }

if echo "$html" | grep -q 'ldh-chat-open'; then
  echo "DEBUG: ${END_USER_BASE_URL} offers the Assistant button although the assistant is disabled"
  exit 1
fi
