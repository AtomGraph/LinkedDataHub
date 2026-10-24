#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# Every upload used to be hashed with one MessageDigest shared by the whole application, and MessageDigest is
# not thread-safe: concurrent uploads fed and reset each other's digest, so a file could be stored under a
# SHA1 that is not its own (#455). Several distinct files go up at once here, and each one has to come back
# under its own hash, with its own bytes.

# add agent to the writers group

ldh admin add agent \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

count=8
work=$(mktemp -d)

for i in $(seq 1 $count); do
    head -c 1048576 /dev/urandom > "${work}/file-${i}"
    ldh create item \
      -c "$AGENT_CERT_KEYSTORE" \
      -p "$AGENT_CERT_PWD" \
      --title "Concurrent upload ${i}" \
      --container "$END_USER_BASE_URL" \
      --slug "$(uuidgen | tr '[:upper:]' '[:lower:]')" > "${work}/doc-${i}"
done

for i in $(seq 1 $count); do
    ldh add file \
      -c "$AGENT_CERT_KEYSTORE" \
      -p "$AGENT_CERT_PWD" \
      --title "Concurrent upload ${i}" \
      --file "${work}/file-${i}" \
      --content-type application/octet-stream \
      "$(cat "${work}/doc-${i}")" > "${work}/uri-${i}" &
done
wait

for i in $(seq 1 $count); do
    expected=$(shasum -a 1 "${work}/file-${i}" | awk '{print $1}')
    file_uri="${END_USER_BASE_URL}uploads/${expected}"

    stored=$(ldh get \
      -c "$AGENT_CERT_KEYSTORE" \
      -p "$AGENT_CERT_PWD" \
      --accept 'application/n-triples' \
      "$(cat "${work}/doc-${i}")" \
    | sed -En "s|^<${file_uri}> <http://xmlns.com/foaf/0.1/sha1> \"([^\"]*)\" \.$|\1|p")
    downloaded=$(curl -k -f -s -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" "$file_uri" | shasum -a 1 | awk '{print $1}')

    echo "DEBUG: file ${i}. Expected SHA1: $expected foaf:sha1: ${stored:-<none>} downloaded: $downloaded"
    [ "$stored" = "$expected" ] || exit 1
    [ "$downloaded" = "$expected" ] || exit 1
done

rm -rf "$work"
