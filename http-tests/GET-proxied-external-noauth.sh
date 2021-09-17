#!/bin/bash

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_backend_cache "$END_USER_VARNISH_SERVICE"
purge_backend_cache "$ADMIN_VARNISH_SERVICE"

# load the RDF vocabulary using LDH as a proxy

proxied_triple_count=$(curl -k -f -s \
  -G \
  -H 'Accept: application/n-triples' \
  --data-urlencode "uri=http://www.w3.org/1999/02/22-rdf-syntax-ns" \
  "${END_USER_BASE_URL}" \
| rapper -q --input ntriples --output ntriples /dev/stdin - \
| wc -l)

# load the RDF vocabulary directly

direct_triple_count=$(curl -f -s \
  -H "Accept: text/turtle" \
  "http://www.w3.org/1999/02/22-rdf-syntax-ns" \
| rapper -q --input turtle --output ntriples /dev/stdin -\
| wc -l)

# confirm that the number of triples is the same

if [ "$proxied_triple_count" != "$direct_triple_count" ]; then
    exit 1
fi