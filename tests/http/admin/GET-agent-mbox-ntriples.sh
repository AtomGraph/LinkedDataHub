#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# request agent's RDF description

ntriples=$(curl -k -f -s -N \
  -H "Accept: application/n-triples" \
  "$AGENT_URI")

# check that the description does *not* include foaf:mbox property

echo "$ntriples" | grep "http://xmlns.com/foaf/0.1/mbox" > /dev/null

# check that the description includes foaf:mbox_sha1sum property

echo "$ntriples" | grep "http://xmlns.com/foaf/0.1/mbox_sha1sum" > /dev/null
# and that it is the hash of the address, not of nothing: the digest used to be read before any byte of the
# mailto: URI was fed to it, which published the SHA1 of the empty string for every agent (#455)

sha1sum=$(echo "$ntriples" | sed -En 's|^.* <http://xmlns.com/foaf/0.1/mbox_sha1sum> "([^"]*)".*$|\1|p' | head -1)
echo "DEBUG: foaf:mbox_sha1sum: $sha1sum"
[[ "$sha1sum" =~ ^[0-9a-f]{40}$ ]] || exit 1
[ "$sha1sum" != "da39a3ee5e6b4b0d3255bfef95601890afd80709" ] || exit 1
