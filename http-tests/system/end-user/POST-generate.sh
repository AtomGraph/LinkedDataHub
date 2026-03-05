#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# add agent to the writers group

add-agent-to-group.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

# create a parent container to generate into

slug=$(uuidgen | tr '[:upper:]' '[:lower:]')

parent=$(create-container.sh \
  -f "$AGENT_CERT_FILE" \
  -p "$AGENT_CERT_PWD" \
  -b "$END_USER_BASE_URL" \
  --title "Generate parent" \
  --slug "$slug" \
  --parent "$END_USER_BASE_URL")

# POST /generate with a writer: generate a container for dh:Container class using ldh:SelectChildren query

(
curl -k -w "%{http_code}\n" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X POST \
  -H "Content-Type: text/turtle" \
  --data-binary @- \
  "${END_USER_BASE_URL}generate" <<EOF
@prefix sioc: <http://rdfs.org/sioc/ns#> .
@prefix void: <http://rdfs.org/ns/void#> .
@prefix spin: <http://spinrdf.org/spin#> .
@prefix dh: <https://www.w3.org/ns/ldt/document-hierarchy#> .
@prefix ldh: <https://w3id.org/atomgraph/linkeddatahub#> .

[] sioc:has_parent <${parent}> ;
   void:class dh:Container ;
   spin:query ldh:SelectChildren .
EOF
) \
| grep -q "$STATUS_OK"
