#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2017 LinkedDataHub
# SPDX-FileCopyrightText: 2017 Martynas Jusevicius <martynas@atomgraph.com> 
# SPDX-FileCopyrightText: 2017-2022 2017 Martynas Jusevicius, <martynas@atomgraph.com> et al.
#
# SPDX-License-Identifier: Apache-2.0

# LinkedDataHub


set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_backend_cache "$END_USER_VARNISH_SERVICE"
purge_backend_cache "$ADMIN_VARNISH_SERVICE"

file=$(./create-file.sh)

pushd . > /dev/null && cd "$SCRIPT_ROOT"

etag=$(
  curl -k -i -f -s -G \
    -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
    -H "Accept: text/csv" \
  "$file" \
| grep 'ETag' \
| sed -En 's/^ETag: (.*)/\1/p')

popd > /dev/null

curl -k -w "%{http_code}\n" -o /dev/null -f -s -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: text/csv" \
  "$file" \
-H "If-None-Match: ${etag}" \
| grep -q "$STATUS_NOT_MODIFIED"
