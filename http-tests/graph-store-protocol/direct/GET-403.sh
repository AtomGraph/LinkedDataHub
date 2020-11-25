#!/bin/bash

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"

# check that non-existing graph is forbidden

curl -k -w "%{http_code}\n" -f -s -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  "${END_USER_BASE_URL}graphs/non-existing/" \
| grep -q "${STATUS_FORBIDDEN}"