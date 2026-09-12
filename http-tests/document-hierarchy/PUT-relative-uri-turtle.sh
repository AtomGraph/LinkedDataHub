#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# add agent to the writers group

ldh admin add agent \
  -f "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

# create new document - relative URIs allowed in Turtle and should resolve against the document URI as base

item="${END_USER_BASE_URL}new-item/"

status=$(curl -k -w "%{http_code}" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PUT \
  -H "Accept: application/n-triples" \
  -H "Content-Type: text/turtle" \
  --data-binary @- \
  "$item" <<EOF
<named-subject-put> <http://example.com/default-predicate> "named object PUT" .
<named-subject-put> <http://example.com/another-predicate> "another named object PUT" .
EOF
)

if [ "$status" != "$STATUS_CREATED" ]; then
  exit 1
fi

# check that resource is accessible
#
# Assertions read from a here-string rather than piping curl into `grep -q`: `grep -q`
# closes the pipe on its first match, and with `set -o pipefail` the SIGPIPE'd upstream
# command fails the whole pipeline whenever it is still writing at that moment.

response=$(curl -k -f -G -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$item")

for triple in \
  "<${item}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://www.w3.org/ns/ldt/document-hierarchy#Item>" \
  "<${item}named-subject-put> <http://example.com/default-predicate> \"named object PUT\" ."
do
  if ! grep -qF "$triple" <<< "$response"; then
    exit 1
  fi
done
