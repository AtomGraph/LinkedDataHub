#!/usr/bin/env bash


# SPDX-FileCopyrightText: 2017 Martynas Jusevicius <martynas@atomgraph.com> 
# SPDX-FileCopyrightText: 2017 LinkedDataHub
#
# SPDX-License-Identifier: Apache-2.0

# LinkedDataHub

set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_backend_cache "$END_USER_VARNISH_SERVICE"
purge_backend_cache "$ADMIN_VARNISH_SERVICE"

pushd . > /dev/null && cd "$SCRIPT_ROOT/admin/acl"

# add agent to the owners

./add-agent-to-group.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/owners/"

popd > /dev/null

# check that it's not possible to delete the root document

owner_doc=$(echo "$OWNER_URI" | cut -d '#' -f 1)

curl -k -w "%{http_code}\n" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X DELETE \
  -H "Accept: application/n-triples" \
  "$owner_doc" \
| grep -q "$STATUS_BAD_REQUEST"
