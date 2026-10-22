#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# A request carrying the OAuth session cookie is authenticated by it, so the frontend cache must neither store its
# response nor answer it from what it stored for someone else. X-Varnish carries one transaction id on a miss or pass and
# two on a hit

container=$(ldh create container \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --title "Public" \
  --slug "public-$(uuidgen | tr '[:upper:]' '[:lower:]')" \
  --parent "$END_USER_BASE_URL")

ldh admin create authorization \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --label "Public read access" \
  --agent-class 'http://xmlns.com/foaf/0.1/Agent' \
  --to "$container" \
  --read \
  "$ADMIN_BASE_URL" > /dev/null

# the number of transaction ids in X-Varnish of a GET, with the given extra curl arguments
function varnish_ids()
{
    curl -k -s -D - -o /dev/null \
      -H "Accept: application/n-triples" \
      "$@" \
      "$container" \
    | grep -i '^x-varnish:' | tr -d '\r' | sed 's/^[^:]*: *//' | wc -w | tr -d ' '
}

# control: an anonymous GET is cached, so the second one is a hit - otherwise the assertions below prove nothing

varnish_ids > /dev/null
ids=$(varnish_ids)

echo "DEBUG: anonymous GET, second time. Expected X-Varnish ids: 2 (hit)  Got: $ids"
if [ "$ids" != "2" ]; then
  exit 1
fi

# with the session cookie: never a hit, neither on a stored anonymous response nor on its own

cookie="LinkedDataHub.id_token=eyJhbGciOiJub25lIn0.eyJzdWIiOiJ0ZXN0In0."

ids=$(varnish_ids -H "Cookie: $cookie")

echo "DEBUG: GET with an ID token cookie, first time. Expected X-Varnish ids: 1  Got: $ids"
if [ "$ids" != "1" ]; then
  exit 1
fi

ids=$(varnish_ids -H "Cookie: $cookie")

echo "DEBUG: GET with an ID token cookie, second time. Expected X-Varnish ids: 1  Got: $ids"
if [ "$ids" != "1" ]; then
  exit 1
fi
