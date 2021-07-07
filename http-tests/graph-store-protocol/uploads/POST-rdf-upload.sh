#!/bin/bash

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_backend_cache "$END_USER_VARNISH_SERVICE"
purge_backend_cache "$ADMIN_VARNISH_SERVICE"

pushd . > /dev/null && cd "$SCRIPT_ROOT/admin/acl"

# add agent to the writers

./add-agent-to-group.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

popd > /dev/null

# upload RDF file

urlencode()
{
    python2 -c "import urllib, sys; print urllib.quote(sys.argv[1] if len(sys.argv) > 1 else sys.stdin.read()[0:-1], safe='')" "$1"
}

file="timbl.ttl"
file_content_type="text/turtle"
graph_uri='http://dig.csail.mit.edu/2008/webdav/timbl/foaf.rdf'

echo "Importing file: $file"

rdf_post+="-F \"rdf=\"\n"
rdf_post+="-F \"sb=file\"\n"
rdf_post+="-F \"pu=http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#fileName\"\n"
rdf_post+="-F \"ol=@${file};type=${file_content_type}\"\n"
rdf_post+="-F \"pu=http://purl.org/dc/terms/title\"\n"
rdf_post+="-F \"ol=Whateverest\"\n"
rdf_post+="-F \"pu=http://www.w3.org/1999/02/22-rdf-syntax-ns#type\"\n"
rdf_post+="-F \"ou=${END_USER_BASE_URL}ns/domain/system#File\"\n"
rdf_post+="-F \"pu=http://www.w3.org/ns/sparql-service-description#name\"\n"
rdf_post+="-F \"ou=${graph_uri}\"\n"

forClass=$(urlencode "${END_USER_BASE_URL}ns/domain/system#File")

# POST RDF/POST multipart form from stdin to the server
echo -e "$rdf_post" \
| curl -w "%{http_code}\n" -v -k -D - --config - \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: text/turtle" \
  "${END_USER_BASE_URL}uploads?import=true&forClass=${forClass}" \
| grep -q "$STATUS_SEE_OTHER"

pushd . > /dev/null && cd "$SCRIPT_ROOT"

doc_ntriples=$(./get-document.sh \
  -f "$AGENT_CERT_FILE" \
  -p "$AGENT_CERT_PWD" \
  --accept 'application/n-triples' \
  "${END_USER_BASE_URL}service?graph=${graph_uri}")

popd > /dev/null

# check that the graph has been imported and contains the right triples

echo "$doc_ntriples" | grep "<http://dig.csail.mit.edu/2008/webdav/timbl/foaf.rdf> <http://xmlns.com/foaf/0.1/maker> <http://www.w3.org/People/Berners-Lee/card#i>"