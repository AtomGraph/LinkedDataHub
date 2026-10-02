#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# add agent to the writers group

ldh admin add agent \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

# A write is a read-modify-write over separate calls to the store, so the If-Match check on its own cannot
# refuse a second writer that read the document before the first one wrote it: both quote the tag they read,
# both pass, and the second write undoes the first. Several appends to the root document are fired at once,
# all quoting the one tag read beforehand. Exactly one may be accepted; every other one must be refused
# with 412, because by the time it is checked the document is no longer what it read.

etag=$(etag "$END_USER_BASE_URL" "$AGENT_CERT_FILE" "$AGENT_CERT_PWD" "application/n-triples")

writers=8
statuses=$(mktemp -d)

for i in $(seq 1 "$writers"); do
  (
  curl -k -w "%{http_code}\n" -o /dev/null -s \
    -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
    -H "If-Match: $etag" \
    -H "Accept: application/n-triples" \
    -H "Content-Type: application/n-triples" \
    --data-binary "<${END_USER_BASE_URL}#writer-${i}> <http://example.com/wrote> \"${i}\" ." \
    "$END_USER_BASE_URL" > "$statuses/$i"
  ) &
done
wait

accepted=$(cat "$statuses"/* | grep -c "^${STATUS_NO_CONTENT}$" || true)
refused=$(cat "$statuses"/* | grep -c "^${STATUS_PRECONDITION_FAILED}$" || true)

echo "DEBUG: Statuses: $(cat "$statuses"/* | tr '\n' ' ')"
echo "DEBUG: Expected: 1 accepted (${STATUS_NO_CONTENT}), $((writers - 1)) refused (${STATUS_PRECONDITION_FAILED})"
echo "DEBUG: Got: $accepted accepted, $refused refused"

if [ "$accepted" -ne 1 ] || [ "$refused" -ne $((writers - 1)) ]; then
    echo "DEBUG: Mismatch!"
    exit 1
fi

# the document holds the accepted write and no other. Body capture into a variable rather than a pipe to
# grep: the pipe races with Varnish invalidation after the write and intermittently sees stale data

body=$(curl -k -f -s -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$END_USER_BASE_URL")

written=$(echo "$body" | grep -c "<http://example.com/wrote>" || true)

echo "DEBUG: Expected: 1 write in the document"
echo "DEBUG: Got: $written"

if [ "$written" -ne 1 ]; then
    echo "DEBUG: Mismatch!"
    exit 1
fi
