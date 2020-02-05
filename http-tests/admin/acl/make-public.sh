#!/bin/bash

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"

# unauthenticated access is forbidden

curl -k -w "%{http_code}\n" -f -s \
  -H "Accept: application/n-quads" \
  "${END_USER_BASE_URL}" \
| grep -q "${STATUS_FORBIDDEN}"

# create public authorization

pushd . > /dev/null && cd "$SCRIPT_ROOT/admin/acl"

./create-authorization.sh \
-f "$OWNER_CERT_FILE" \
-p "$OWNER_CERT_PWD" \
-b "$ADMIN_BASE_URL" \
--label "Public access authorization" \
--agent-class 'http://xmlns.com/foaf/0.1/Agent' \
--to "$END_USER_BASE_URL" \
--read

popd > /dev/null

# public access is allowed after authorization is created

curl -k -w "%{http_code}\n" -f -s \
  -H "Accept: application/n-quads" \
  "${END_USER_BASE_URL}" \
| grep -q "${STATUS_OK}"