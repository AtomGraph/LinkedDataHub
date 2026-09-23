#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# An imported vocabulary answers for its own URI only while the document holding it exists. The graph
# is cached under that URI, the cache outlives the document, and eviction used to drop only the keys
# derived from the ontology being cleared - so a deleted document kept being served, and one test's
# import kept answering for the next. This pins the deletion end of it.
#
# It takes both caches to hold. Emptying the JVM graph cache is not enough on its own: the closure
# rebuilds by querying the admin SPARQL endpoint through a proxy that caches each CONSTRUCT under its
# own key, so a rebuild can re-read the deleted graph from there and look exactly like a failure to
# evict. That is what this test caught - the store below showed the document gone while the closure
# still served it.
#
# Counted relative to where it starts, not against zero. Every document declaring the vocabulary an
# owl:Ontology contributes to the closure - that is the feature - so an absolute count would be
# asserting that no other such document exists, which is true of a fresh instance and not what this
# test is about. The baseline is also the first thing printed, so a failure before it locates itself.

namespace_doc="${END_USER_BASE_URL}ns"
namespace="${namespace_doc}#"
ontology_doc="${ADMIN_BASE_URL}ontologies/namespace/"
import_uri="http://www.w3.org/2004/02/skos/core"

# Ground truth, straight from Fuseki: no platform, no Varnish, no JVM closure in the way. Whatever
# this prints is what the store actually holds, which is what separates "the document is gone and
# something still answers for it" from "the document was never removed in the first place".
store_query() {
  curl -s -G \
    -H 'Accept: text/csv' \
    --data-urlencode "query=$2" \
    "$1" 2>/dev/null | tail -n +2 | tr -d '\r' | paste -sd '|' - || true
}

# Everything the store knows about the vocabulary and the document that carried it, at one phase.
store_report() {
  local phase="$1"
  echo "DEBUG: [$phase] admin store, graphs asserting a skos:Concept constructor: $(store_query "$ADMIN_ENDPOINT_URL" "SELECT ?g ?constructor WHERE { GRAPH ?g { <${import_uri}#Concept> <http://spinrdf.org/spin#constructor> ?constructor } }")"
  echo "DEBUG: [$phase] admin store, graphs declaring <${import_uri}> an owl:Ontology: $(store_query "$ADMIN_ENDPOINT_URL" "SELECT ?g WHERE { GRAPH ?g { <${import_uri}> a <http://www.w3.org/2002/07/owl#Ontology> } }")"
  if [ -n "${item:-}" ]; then
    echo "DEBUG: [$phase] admin store, triples in <${item}>: $(store_query "$ADMIN_ENDPOINT_URL" "SELECT (COUNT(*) AS ?triples) WHERE { GRAPH <${item}> { ?s ?p ?o } }")"
  else
    echo "DEBUG: [$phase] admin store, the imported document does not exist yet"
  fi
  echo "DEBUG: [$phase] admin store, owl:imports of the namespace ontology: $(store_query "$ADMIN_ENDPOINT_URL" "SELECT ?import WHERE { GRAPH ?g { <${namespace}> <http://www.w3.org/2002/07/owl#imports> ?import } }")"
  echo "DEBUG: [$phase] end-user store, ldh:import (packages) in settings: $(store_query "$END_USER_ENDPOINT_URL" "SELECT ?package WHERE { GRAPH ?g { ?app <https://w3id.org/atomgraph/linkeddatahub#import> ?package } }")"
}

# The /ns probe issues the SAME URL in every phase, so an answer could come from a cache rather than
# from the closure, and a count that never moves would look identical either way. Age separates them:
# Varnish sends Age: 0 on a miss and the object's age on a hit, so a nonzero Age means the count below
# describes a cached response and says nothing about the closure. Sets CONSTRUCTORS, NS_STATUS,
# NS_AGE, NS_URIS. No -f, so a 5xx from a broken closure still yields diagnostics rather than
# aborting the test with nothing printed.
ns_probe() {
  local hdr body
  hdr=$(mktemp)
  body=$(curl -k -s -G -w $'\n%{http_code}' -D "$hdr" \
    -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
    -H 'Accept: application/sparql-results+xml' \
    --data-urlencode "query=SELECT ?constructor WHERE { <${import_uri}#Concept> <http://spinrdf.org/spin#constructor> ?constructor }" \
    "$namespace_doc") || true
  NS_STATUS="${body##*$'\n'}"
  NS_BODY="${body%$'\n'*}"
  NS_AGE=$(tr -d '\r' < "$hdr" | awk 'tolower($1) == "age:" { print $2 }' | tail -1)
  NS_AGE="${NS_AGE:-absent}"
  CONSTRUCTORS=$(printf '%s' "$NS_BODY" | xmllint --xpath "count(//*[local-name() = 'result'])" - 2>/dev/null || echo "ERR")
  NS_URIS=$(printf '%s' "$NS_BODY" | xmllint --xpath "//*[local-name() = 'uri']/text()" - 2>/dev/null | tr '\n' ' ' || true)
  rm -f "$hdr"
}

store_report "baseline"
ns_probe
before="$CONSTRUCTORS"
echo "DEBUG: [baseline] constructors for skos:Concept before the import: $before (HTTP $NS_STATUS, Age $NS_AGE) $NS_URIS"

item=$(ldh create item \
  -f "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  -b "$ADMIN_BASE_URL" \
  --title "Evicted" \
  --slug "evicted" \
  --container "${ADMIN_BASE_URL}ontologies/")

ldh admin import ontology \
  -f "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  -b "$ADMIN_BASE_URL" \
  --source "$import_uri" \
  --graph "$item"

# the application ontology imports the VOCABULARY, and resolving it reaches the document above
ldh admin add ontology-import \
  -f "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --import "$import_uri" \
  "$ontology_doc"

ldh admin clear ontology \
  -f "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  -b "$ADMIN_BASE_URL" \
  --ontology "$namespace"

store_report "imported"
ns_probe
imported="$CONSTRUCTORS"
echo "DEBUG: [imported] constructors for skos:Concept. Expected: >$before  Got: $imported (HTTP $NS_STATUS, Age $NS_AGE) $NS_URIS"
if [ "$imported" -le "$before" ]; then
  echo "DEBUG: [imported] the derived constructors never reached the closure" >&2
  exit 1
fi

# delete the document that supplied them, then clear without naming an ontology

ldh delete \
  -f "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  "$item"

clear_ontology

store_report "deleted"
ns_probe
final="$CONSTRUCTORS"
echo "DEBUG: [deleted] constructors for skos:Concept. Expected: $before  Got: $final (HTTP $NS_STATUS, Age $NS_AGE) $NS_URIS"
if [ "$final" != "$before" ]; then
  echo "DEBUG: [deleted] a graph cached under <${import_uri}> outlived the document it came from" >&2
  echo "DEBUG: [deleted] Age above says where the answer came from: nonzero means Varnish served the [imported] response and the closure was never asked" >&2
  exit 1
fi
