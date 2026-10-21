#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# A response to an authenticated agent is that agent's, so no shared cache may store it. An anonymous response to a public
# document may be stored, but is revalidated

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

# the owner

cache_control=$(curl -k -s -f -D - -o /dev/null \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$container" \
| grep -i '^cache-control:' | tr -d '\r' || true)

echo "DEBUG: owner GET Expected: Cache-Control with private  Got: $cache_control"
if ! grep -qi 'private' <<< "$cache_control"; then
  exit 1
fi
if grep -qi 'public' <<< "$cache_control"; then
  exit 1
fi

# anonymous

cache_control=$(curl -k -s -f -D - -o /dev/null \
  -H "Accept: application/n-triples" \
  "$container" \
| grep -i '^cache-control:' | tr -d '\r' || true)

echo "DEBUG: anonymous GET Expected: Cache-Control: no-cache, without private  Got: $cache_control"
if grep -qi 'private' <<< "$cache_control"; then
  exit 1
fi
if ! grep -qi 'no-cache' <<< "$cache_control"; then
  exit 1
fi
