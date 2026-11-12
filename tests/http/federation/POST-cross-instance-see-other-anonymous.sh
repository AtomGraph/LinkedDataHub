#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
initialize_dataset "$REMOTE_END_USER_BASE_URL" "$TMP_REMOTE_END_USER_DATASET" "$REMOTE_END_USER_ENDPOINT_URL"
initialize_dataset "$REMOTE_ADMIN_BASE_URL" "$TMP_REMOTE_ADMIN_DATASET" "$REMOTE_ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# A write through A's proxy to another instance is delegated, a read is not: browsing a foreign origin does not announce
# the caller. A write that origin answers with 303 See Other continues as a GET, so its next hop is a read and goes out
# anonymous too. B's test redirector (/see-other/<path>, docker-compose.http-tests.yml) answers a POST with a 303 to a
# document on B that only A's owner may read: delegated, the GET would return it; anonymous, B refuses it.

slug="see-other-target-$(date +%s)"

item=$(ldh create item \
  -c "$REMOTE_OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --title "Cross-instance redirect target" \
  --slug "$slug" \
  --container "$REMOTE_END_USER_BASE_URL")

echo "DEBUG: document on B: $item"
[ "$item" = "${REMOTE_END_USER_BASE_URL}${slug}/" ] || { echo "DEBUG: expected the document at ${REMOTE_END_USER_BASE_URL}${slug}/"; exit 1; }

ldh admin create authorization \
  -c "$REMOTE_OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --label "A's owner may read the cross-instance redirect target" \
  --agent "$OWNER_URI" \
  --to "$item" \
  --read \
  "$REMOTE_ADMIN_BASE_URL" > /dev/null

see_other="${REMOTE_END_USER_BASE_URL}see-other/${slug}/"

# Controls: B lets A's owner read the document and refuses an anonymous read, and the redirector answers a POST with a
# 303 to the document

code=$(curl -k -s -o /dev/null -w '%{http_code}' -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" -H 'Accept: application/n-triples' "$item")
echo "DEBUG: A's owner reads B's document directly - Expected: $STATUS_OK  Got: $code"
[ "$code" = "$STATUS_OK" ] || exit 1

code=$(curl -k -s -o /dev/null -w '%{http_code}' -H 'Accept: application/n-triples' "$item")
echo "DEBUG: anonymous read of B's document - Expected: $STATUS_FORBIDDEN  Got: $code"
[ "$code" = "$STATUS_FORBIDDEN" ] || exit 1

response=$(curl -k -s -o /dev/null -w '%{http_code} %{redirect_url}' -X POST -H 'Content-Type: application/n-triples' --data-binary '' "$see_other")
echo "DEBUG: POST to B's redirector - Expected: $STATUS_SEE_OTHER $item  Got: $response"
[ "$response" = "$STATUS_SEE_OTHER $item" ] || exit 1

# A's owner reading the document through A's proxy is anonymous to B

code=$(curl -k -s -o /dev/null -w '%{http_code}' \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H 'Accept: application/n-triples' \
  --url-query "uri=${item}" \
  "$END_USER_BASE_URL")
echo "DEBUG: proxied read of B's document - Expected: $STATUS_FORBIDDEN  Got: $code"
[ "$code" = "$STATUS_FORBIDDEN" ] || exit 1

# A's owner POSTing to the redirector through A's proxy: the POST is delegated, and the GET the 303 leads to is not

code=$(curl -k -s -o /dev/null -w '%{http_code}' \
  -X POST \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H 'Accept: application/n-triples' \
  -H 'Content-Type: application/n-triples' \
  --data-binary "<${item}> <http://purl.org/dc/terms/description> \"Redirected\" ." \
  --url-query "uri=${see_other}" \
  "$END_USER_BASE_URL")
echo "DEBUG: proxied POST redirected to B's document - Expected: $STATUS_FORBIDDEN  Got: $code"
[ "$code" = "$STATUS_FORBIDDEN" ] || exit 1
