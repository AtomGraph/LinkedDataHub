#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# Regression: ProxyRequestFilter sent every upstream request with the platform's own client
# certificate and delegated (On-Behalf-Of) only when the caller was authenticated. An anonymous
# caller therefore reached the origin AS THE SECRETARY - a member of every dataspace's writers
# group - and the origin's acl:agent and acl:mode Link headers, forwarded verbatim, told the
# client it held acl:Write. The browser drew edit controls on a block embedded from another
# dataspace for a reader holding no certificate at all.
#
# An anonymous proxied read has to answer with the modes an anonymous reader holds on the
# document: acl:Read on a public one, and no acl:agent, because nobody was authenticated.

# a document only the owner may edit, which everyone may read

item=$(ldh create item \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --title "Proxied public document" \
  --slug "proxied-public-$(date +%s)" \
  --container "$END_USER_BASE_URL")

ldh admin create authorization \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --label "Public read of the proxied document" \
  --agent-class "http://xmlns.com/foaf/0.1/Agent" \
  --to "$item" \
  --read \
  "$ADMIN_BASE_URL" > /dev/null

# read it anonymously through the admin origin's proxy, so the request crosses origins and is
# forwarded rather than rewritten onto the local document

response_headers=$(mktemp)

status=$(curl -k -s -G \
  -o /dev/null \
  -w "%{http_code}" \
  -D "$response_headers" \
  -H 'Accept: application/n-triples' \
  --data-urlencode "uri=${item}" \
  "$ADMIN_BASE_URL")

cat "$response_headers"

if [ "$status" != "$STATUS_OK" ]; then
    echo "Expected $STATUS_OK for the public document, got $status"
    exit 1
fi

# the public grant is what the reader holds

grep -q "Link:.*<http://www.w3.org/ns/auth/acl#Read>; rel=\"http://www.w3.org/ns/auth/acl#mode\"" "$response_headers"

# and nothing the secretary holds

if grep -q "<http://www.w3.org/ns/auth/acl#Write>; rel=\"http://www.w3.org/ns/auth/acl#mode\"" "$response_headers"; then
    echo "An anonymous proxied read reports acl:Write"
    exit 1
fi
if grep -q "<http://www.w3.org/ns/auth/acl#Append>; rel=\"http://www.w3.org/ns/auth/acl#mode\"" "$response_headers"; then
    echo "An anonymous proxied read reports acl:Append"
    exit 1
fi
if grep -q "<http://www.w3.org/ns/auth/acl#Control>; rel=\"http://www.w3.org/ns/auth/acl#mode\"" "$response_headers"; then
    echo "An anonymous proxied read reports acl:Control"
    exit 1
fi
if grep -qi "rel=\"http://www.w3.org/ns/auth/acl#agent\"" "$response_headers"; then
    echo "An anonymous proxied read asserts an agent"
    exit 1
fi

rm "$response_headers"
