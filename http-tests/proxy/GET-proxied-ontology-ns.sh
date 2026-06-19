#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# add agent to the readers group to be able to read documents

add-agent-to-group.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/readers/"

# use a made-up hash-based namespace: not mapped as a static file, not a registered app
namespace_uri="http://made-up-test-ns.example/ns"
class1="${namespace_uri}#ClassOne"
class2="${namespace_uri}#ClassTwo"
ontology_doc="${ADMIN_BASE_URL}ontologies/namespace/"
namespace="${END_USER_BASE_URL}ns#"

# add two classes with URIs in the made-up namespace to the app's ontology

add-class.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  -b "$ADMIN_BASE_URL" \
  --uri "$class1" \
  --label "Class One" \
  "$ontology_doc"

add-class.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  -b "$ADMIN_BASE_URL" \
  --uri "$class2" \
  --label "Class Two" \
  "$ontology_doc"

# clear the in-memory ontology so the new classes are present on next request

clear_out=$(clear-ontology.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  -b "$ADMIN_BASE_URL" \
  --ontology "$namespace" 2>&1) && clear_exit=0 || clear_exit=$?
echo "DEBUG: clear-ontology.sh exit=$clear_exit output=$clear_out"
[ "$clear_exit" -eq 0 ] || exit "$clear_exit"

# request the namespace document URI (without fragment) via ?uri= proxy.
# the namespace document is not DataManager-mapped and not a registered app,
# so ProxyRequestFilter falls through to the OntModel DESCRIBE path, which
# returns descriptions of all #-fragment terms in that namespace.

response=$(curl -k -f -s \
  -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  --data-urlencode "uri=${namespace_uri}" \
  "$END_USER_BASE_URL" 2>&1) && proxy_exit=0 || proxy_exit=$?
echo "DEBUG: proxy GET exit=$proxy_exit"
echo "DEBUG: proxy response (first 500 chars): ${response:0:500}"
[ "$proxy_exit" -eq 0 ] || exit "$proxy_exit"

# verify both class descriptions are present in the response

echo "$response" | grep -q "$class1" && echo "DEBUG: class1 found" || { echo "DEBUG: class1 NOT found"; exit 1; }
echo "$response" | grep -q "$class2" && echo "DEBUG: class2 found" || { echo "DEBUG: class2 NOT found"; exit 1; }
