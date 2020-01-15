#!/bin/bash

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"

# authenticated access is unauthorized

echo "AGENT_CERT_FILE: ${AGENT_CERT_FILE}"
cat "${AGENT_CERT_FILE}"

curl -k -w "%{http_code}\n" -f -s \
  -E "${AGENT_CERT_FILE}":"${AGENT_CERT_PWD}" \
  -H "Accept: application/n-quads" \
  "${END_USER_BASE_URL}" \
| grep -q "${STATUS_FORBIDDEN}"

pushd . > /dev/null && cd "$SCRIPT_ROOT/admin/acl"

# create group

group_doc=$(./create-group.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  -b "$ADMIN_BASE_URL" \
  --name "Test group" \
  --member "$AGENT_WEBID_URI")

group=$(curl -s -k \
  -E "${OWNER_CERT_FILE}":"${OWNER_CERT_PWD}" \
  "$group_doc" \
  -H "Accept: application/n-triples" \
  | cat \
  | sed -rn "s/<${group_doc//\//\\/}> <http:\/\/xmlns.com\/foaf\/0.1\/primaryTopic> <(.*)> \./\1/p")

# create authorization

./create-authorization.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  -b "$ADMIN_BASE_URL" \
  --label "GET authorization" \
  --agent-class "$group" \
  --to "$END_USER_BASE_URL" \
  --read

popd > /dev/null

# authenticated access is allowed after authorization is created

curl -k -w "%{http_code}\n" -f -s \
  -E "${AGENT_CERT_FILE}":"${AGENT_CERT_PWD}" \
  -H "Accept: application/n-quads" \
  "${END_USER_BASE_URL}" \
| grep -q "${STATUS_OK}"