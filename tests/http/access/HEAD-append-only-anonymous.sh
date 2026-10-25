#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# A HEAD is granted to any agent with a mode on the document, acl:Append included, so that a writer who may not
# read can still learn the entity tag its conditional write has to quote; a GET needs acl:Read. An anonymous
# request is the one the front Varnish would cache, and on a miss Varnish fetches a HEAD as a GET - which the
# platform then decided as a read and refused. HEAD passes the cache now, so the decision is the HEAD's own.

# the owner creates a document and grants everyone acl:Append on it, and nothing else

item=$(ldh create item \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --title "Append only" \
  --slug "append-only" \
  --container "$END_USER_BASE_URL")

ldh admin create authorization \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --label "Anyone may append" \
  --agent-class "http://xmlns.com/foaf/0.1/Agent" \
  --to "$item" \
  --append \
  "$ADMIN_BASE_URL"

purge_cache "$FRONTEND_VARNISH_SERVICE"

# an anonymous HEAD is allowed by the append grant: 200, with the entity tag

headers=$(curl -k -s -I \
  -H "Accept: application/n-triples" \
  "$item")
status=$(echo "$headers" | head -1 | awk '{print $2}')
echo "DEBUG: anonymous HEAD with acl:Append only. Expected: $STATUS_OK Got: $status"
[ "$status" = "$STATUS_OK" ] || exit 1

etag=$(echo "$headers" | grep -i '^ETag:' || true)
echo "DEBUG: ETag header on the HEAD. Expected: present Got: '$etag'"
[ -n "$etag" ] || exit 1

# the same HEAD again, in case the first left something behind in the cache: still 200

status=$(curl -k -s -I -o /dev/null -w "%{http_code}" \
  -H "Accept: application/n-triples" \
  "$item")
echo "DEBUG: second anonymous HEAD. Expected: $STATUS_OK Got: $status"
[ "$status" = "$STATUS_OK" ] || exit 1

# content still needs acl:Read: an anonymous GET is refused, and nothing the HEADs did answers it instead

status=$(curl -k -s -o /dev/null -w "%{http_code}" \
  -H "Accept: application/n-triples" \
  "$item")
echo "DEBUG: anonymous GET with acl:Append only. Expected: $STATUS_FORBIDDEN Got: $status"
[ "$status" = "$STATUS_FORBIDDEN" ] || exit 1
