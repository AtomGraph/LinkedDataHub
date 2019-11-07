#!/bin/bash

initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"

# unauthenticated access is forbidden

curl -k -w "%{http_code}\n" -f -s \
  -H "Accept: application/n-quads" \
  "${END_USER_BASE_URL}" \
| grep -q "${STATUS_FORBIDDEN}"