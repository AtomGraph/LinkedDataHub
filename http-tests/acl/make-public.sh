# re-initialize writable dataset

initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"

# create public authorization

pushd . > /dev/null && cd "$SCRIPT_ROOT/admin/acl"

./create-authorization.sh \
-f "$CERT_FILE" \
-p "$CERT_PWD" \
-b "$ADMIN_BASE_URL" \
--label "Test authorization" \
--agent-class 'http://xmlns.com/foaf/0.1/Agent' \
--to "$END_USER_BASE_URL" \
--read

popd > /dev/null

# public access is allowed after authorization is created

curl -k -E "${CERT}" -w "%{http_code}\n" -f -s \
  -H "Accept: application/n-quads" \
  "${END_USER_BASE_URL}" \
| grep -q "${STATUS_OK}"