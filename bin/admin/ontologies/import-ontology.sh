#!/usr/bin/env bash
set -eo pipefail

print_usage()
{
    printf "Imports an external ontology: derives class constructors from its triples and appends them, together with an owl:imports of the source, to a document.\n"
    printf "The vocabulary itself is fetched into a scratch document (deleted afterwards) that scopes the CONSTRUCT transformation on the /sparql endpoint via the SPARQL Protocol dataset specification - only the derived annotations persist; the vocabulary resolves live through the graph repository.\n"
    printf "Use add-ontology-import.sh and clear-ontology.sh to make the annotation document part of the application ontology.\n"
    printf "\n"
    printf "Usage:  %s options\n" "$0"
    printf "\n"
    printf "Options:\n"
    printf "  -f, --cert-pem-file CERT_FILE        .pem file with the WebID certificate of the agent\n"
    printf "  -p, --cert-password CERT_PASSWORD    Password of the WebID certificate\n"
    printf "  -b, --base BASE_URI                  Base URI of the admin application\n"
    printf "  --proxy PROXY_URL                    The host this request will be proxied through (optional)\n"
    printf "\n"
    printf "  --source SOURCE_URI                  URI of the imported ontology\n"
    printf "  --graph GRAPH_URI                    URI of the document the ontology is imported into\n"
}

hash curl 2>/dev/null || { echo >&2 "curl not on \$PATH. Aborting."; exit 1; }
hash xmllint 2>/dev/null || { echo >&2 "xmllint not on \$PATH. Aborting."; exit 1; }
hash uuidgen 2>/dev/null || { echo >&2 "uuidgen not on \$PATH. Aborting."; exit 1; }

args=()
while [[ $# -gt 0 ]]
do
    key="$1"

    case $key in
        -f|--cert-pem-file)
        cert_pem_file="$2"
        shift # past argument
        shift # past value
        ;;
        -p|--cert-password)
        cert_password="$2"
        shift # past argument
        shift # past value
        ;;
        -b|--base)
        base="$2"
        shift # past argument
        shift # past value
        ;;
        --proxy)
        proxy="$2"
        shift # past argument
        shift # past value
        ;;
        --source)
        source="$2"
        shift # past argument
        shift # past value
        ;;
        --graph)
        graph="$2"
        shift # past argument
        shift # past value
        ;;
        *)    # unknown arguments
        args+=("$1") # save it in an array for later
        shift # past argument
        ;;
    esac
done
set -- "${args[@]}" # restore args

if [ -z "$cert_pem_file" ] ; then
    print_usage
    exit 1
fi
if [ -z "$cert_password" ] ; then
    print_usage
    exit 1
fi
if [ -z "$base" ] ; then
    print_usage
    exit 1
fi
if [ -z "$source" ] ; then
    print_usage
    exit 1
fi
if [ -z "$graph" ] ; then
    print_usage
    exit 1
fi

endpoint_base="$base"
graph_url="$graph"

if [ -n "$proxy" ]; then
    # rewrite request hostnames to the proxy hostname
    base_host=$(echo "$base" | cut -d '/' -f 1,2,3)
    proxy_host=$(echo "$proxy" | cut -d '/' -f 1,2,3)
    endpoint_base="${base/$base_host/$proxy_host}"
    graph_url="${graph/$base_host/$proxy_host}"
fi

tmp_source=$(mktemp)
tmp_query=$(mktemp)
tmp_constructors=$(mktemp)
trap 'rm -f "$tmp_source" "$tmp_query" "$tmp_constructors"' EXIT

# fetch the source ontology through the Linked Data proxy, which converts any Jena-parseable format to RDF/XML

curl -f -s -k \
  -E "$cert_pem_file":"$cert_password" \
  -G "$endpoint_base" \
  --data-urlencode "uri=${source}" \
  -H "Accept: application/rdf+xml" \
  > "$tmp_source"

# create the scratch document that holds the vocabulary during the constructor derivation

scratch="${base}$(uuidgen | tr '[:upper:]' '[:lower:]')/"
scratch_url="$scratch"

if [ -n "$proxy" ]; then
    scratch_url="${scratch/$base_host/$proxy_host}"
fi

printf '@prefix dh:\t<https://www.w3.org/ns/ldt/document-hierarchy#> .\n@prefix dct:\t<http://purl.org/dc/terms/> .\n<%s> a dh:Item ;\n    dct:title "Import ontology scratch" .\n' "$scratch" \
| curl -f -s -k -o /dev/null \
  -E "$cert_pem_file":"$cert_password" \
  -X PUT --data-binary @- \
  -H "Content-Type: text/turtle" \
  -H "Accept: application/rdf+xml" \
  "$scratch_url"

# the scratch document must not outlive the derivation - delete it on exit, the failure paths included

trap 'rm -f "$tmp_source" "$tmp_query" "$tmp_constructors"; curl -s -k -o /dev/null -E "$cert_pem_file":"$cert_password" -X DELETE "$scratch_url"' EXIT

# append the raw ontology to the scratch document graph

curl -f -s -k -o /dev/null \
  -E "$cert_pem_file":"$cert_password" \
  -X POST --data-binary "@$tmp_source" \
  -H "Content-Type: application/rdf+xml" \
  -H "Accept: application/rdf+xml" \
  "$scratch_url"

# read the construct-constructors query text, scoped to its own document graph

curl -f -s -k \
  -E "$cert_pem_file":"$cert_password" \
  -G "${endpoint_base}sparql" \
  --data-urlencode "query=SELECT ?text WHERE { <${base}queries/construct-constructors/#this> <http://spinrdf.org/sp#text> ?text }" \
  --data-urlencode "default-graph-uri=${base}queries/construct-constructors/" \
  -H "Accept: application/sparql-results+xml" \
| xmllint --xpath "string(//*[local-name()='literal'])" - \
  > "$tmp_query"

if [ ! -s "$tmp_query" ]; then
    echo >&2 "Could not load the transformation query. Aborting."
    exit 1
fi

# run the CONSTRUCT over the scratch graph via the SPARQL Protocol dataset specification

curl -f -s -k \
  -E "$cert_pem_file":"$cert_password" \
  -X POST "${endpoint_base}sparql" \
  --data-urlencode "query@${tmp_query}" \
  --data-urlencode "default-graph-uri=${scratch}" \
  -H "Accept: application/rdf+xml" \
  > "$tmp_constructors"

# append the derived constructors to the document graph

curl -f -s -k -o /dev/null \
  -E "$cert_pem_file":"$cert_password" \
  -X POST --data-binary "@$tmp_constructors" \
  -H "Content-Type: application/rdf+xml" \
  -H "Accept: application/rdf+xml" \
  "$graph_url"

# append the annotation-ontology header: the document imports the source vocabulary, which resolves live through the graph repository

printf '@prefix owl:\t<http://www.w3.org/2002/07/owl#> .\n<%s> a owl:Ontology ;\n    owl:imports <%s> .\n' "$graph" "$source" \
| curl -f -s -k -o /dev/null \
  -E "$cert_pem_file":"$cert_password" \
  -X POST --data-binary @- \
  -H "Content-Type: text/turtle" \
  -H "Accept: application/rdf+xml" \
  "$graph_url"
