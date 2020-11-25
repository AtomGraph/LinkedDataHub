#!/bin/bash

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"

# owner access

curl --head -k -w "%{http_code}\n" -f -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: text/turtle" \
  "${END_USER_BASE_URL}ns" \
| grep -q "${STATUS_OK}"

# authenticated agent access

curl --head -k -w "%{http_code}\n" -f -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: text/turtle" \
  "${END_USER_BASE_URL}ns" \
| grep -q "${STATUS_OK}"

# public access

curl --head -k -w "%{http_code}\n" -f -s \
  -H "Accept: text/turtle" \
  "${END_USER_BASE_URL}ns" \
| grep -q "${STATUS_OK}"