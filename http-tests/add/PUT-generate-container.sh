#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# Exercises the client-orchestrated "Generate containers" flow that replaced the server-side
# /generate endpoint. The client builds one container document per checked class -- a dh:Container
# whose content block is an ldh:Object wrapping an ldh:View over a $type-parameterized SELECT -- and
# PUTs it. This test PUTs one such container (shaped exactly like ldh:generate-container-doc output)
# and verifies: creation succeeds (the Object-wrapped block passes ldh:InvalidContentBlockType /
# MissingValue / MissingQuery validation), the server stamps metadata, and the block persists.

# add agent to the writers group

ldh admin add agent \
  -f "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

parent="$END_USER_BASE_URL"
uuid=$(uuidgen | tr '[:upper:]' '[:lower:]')
container="${parent}${uuid}/"
class="https://www.w3.org/ns/ldt/document-hierarchy#Container"

# PUT the generated container document (blank nodes are skolemized server-side)

http_code=$(curl -k -s -o /dev/null -w "%{http_code}" \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PUT \
  -H "Content-Type: application/rdf+xml" \
  --data-binary @- \
  "$container" <<EOF
<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:dct="http://purl.org/dc/terms/" xmlns:sioc="http://rdfs.org/sioc/ns#" xmlns:dh="https://www.w3.org/ns/ldt/document-hierarchy#" xmlns:ldh="https://w3id.org/atomgraph/linkeddatahub#" xmlns:spin="http://spinrdf.org/spin#" xmlns:sp="http://spinrdf.org/sp#">
  <rdf:Description rdf:about="${container}">
    <rdf:type rdf:resource="https://www.w3.org/ns/ldt/document-hierarchy#Container"/>
    <sioc:has_parent rdf:resource="${parent}"/>
    <dct:title>Containers</dct:title>
    <dh:slug>${uuid}</dh:slug>
    <rdf:_1>
      <rdf:Description>
        <rdf:type rdf:resource="https://w3id.org/atomgraph/linkeddatahub#Object"/>
        <rdf:value>
          <rdf:Description>
            <rdf:type rdf:resource="https://w3id.org/atomgraph/linkeddatahub#View"/>
            <spin:query>
              <rdf:Description>
                <rdf:type rdf:resource="http://spinrdf.org/sp#Select"/>
                <dct:title>Select Container</dct:title>
                <sp:text>SELECT DISTINCT ?s WHERE { ?s a &lt;${class}&gt; ; ?p ?o }</sp:text>
              </rdf:Description>
            </spin:query>
          </rdf:Description>
        </rdf:value>
      </rdf:Description>
    </rdf:_1>
  </rdf:Description>
</rdf:RDF>
EOF
)

[ "$http_code" = "$STATUS_CREATED" ]

# fetch the created container and verify the shape + server-stamped metadata

ntriples=$(curl -k -f -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$container")

# parent link, generated title, and server-stamped creation date
echo "$ntriples" | grep -q "<http://rdfs.org/sioc/ns#has_parent> <${parent}>"
echo "$ntriples" | grep -q "<http://purl.org/dc/terms/title> \"Containers\""
echo "$ntriples" | grep -q "<http://purl.org/dc/terms/created>"

# content block persisted as an ldh:Object, and the SELECT carries the substituted class IRI
echo "$ntriples" | grep -q "<https://w3id.org/atomgraph/linkeddatahub#Object>"
echo "$ntriples" | grep "<http://spinrdf.org/sp#text>" | grep -q "${class}"
