#!/bin/bash

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"

# authenticated access is unauthorized

curl -k -w "%{http_code}\n" -f -s \
  -E "${AGENT_CERT_FILE}":"${AGENT_CERT_PWD}" \
  -H "Content-Type: application/n-triples" \
  -H "Accept: application/n-quads" \
  -X PUT \
  "${END_USER_BASE_URL}" \
| grep -q "${STATUS_FORBIDDEN}"

pushd . > /dev/null && cd "$SCRIPT_ROOT/admin/acl"

# create authorization

./create-authorization.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  -b "$ADMIN_BASE_URL" \
  --label "PUT authorization" \
  --agent "$AGENT_URI" \
  --to "$END_USER_BASE_URL" \
  --write

popd > /dev/null

# authenticated access is allowed after authorization is created

curl -k -w "%{http_code}\n" -f -s \
  -E "${AGENT_CERT_FILE}":"${AGENT_CERT_PWD}" \
  -H "Content-Type: application/n-triples" \
  -H "Accept: application/n-quads" \
  -X PUT \
  "${END_USER_BASE_URL}" \
| grep -q "${STATUS_OK}"