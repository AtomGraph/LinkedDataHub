#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# The platform answers a PUT to a URI without a trailing slash with 308 and writes nothing. The CLI does not
# follow redirects, so it used to read the 308 as success - below 400 - and print the URI as if the document
# had been written (#454). It exits 1 now, with nothing on stdout and the Location on stderr.

# add agent to the writers group

ldh admin add agent \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

invalid_item="${END_USER_BASE_URL}no-slash"
err=$(mktemp)

set +e
out=$(printf '<%s/> <http://purl.org/dc/terms/title> "No slash" .\n' "$invalid_item" | ldh put \
  -c "$AGENT_CERT_KEYSTORE" \
  -p "$AGENT_CERT_PWD" \
  -t application/n-triples \
  "$invalid_item" 2> "$err")
code=$?
set -e

echo "DEBUG: exit code. Expected: 1 Got: $code"
echo "DEBUG: stdout: $out"
echo "DEBUG: stderr: $(cat "$err")"
[ "$code" = 1 ] || exit 1
[ -z "$out" ] || exit 1
grep -q "HTTP $STATUS_PERMANENT_REDIRECT" "$err" || exit 1
grep -q "Location: ${invalid_item}/" "$err" || exit 1
rm -f "$err"

# and nothing was written at the redirect target either

status=$(curl -k -w "%{http_code}" -o /dev/null -s -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "${invalid_item}/")
echo "DEBUG: GET of the slash URI. Expected: $STATUS_FORBIDDEN or $STATUS_NOT_FOUND Got: $status"
[[ "$status" =~ ^($STATUS_FORBIDDEN|$STATUS_NOT_FOUND)$ ]] || exit 1
