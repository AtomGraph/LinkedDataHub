#!/usr/bin/env bash

print_usage()
{
    printf "Imports an external ontology into a document.\n"
    printf "\n"
    printf "Fetches the source ontology, runs the construct-constructors CONSTRUCT query over it locally\n"
    printf "(Jena sparql), and appends the result to the target graph over the Graph Store Protocol.\n"
    printf "\n"
    printf "Usage:  %s options\n" "$0"
    printf "\n"
    printf "Options:\n"
    printf "  -f, --cert-pem-file CERT_FILE        .pem file with the WebID certificate of the agent\n"
    printf "  -p, --cert-password CERT_PASSWORD    Password of the WebID certificate\n"
    printf "  -b, --base BASE_URI                  Base URI of the application\n"
    printf "  --proxy PROXY_URL                    The host requests to the application are proxied through (optional)\n"
    printf "\n"
    printf "  --source SOURCE_URI                  URI of the imported ontology\n"
    printf "  --graph GRAPH_URI                    URI of the target document the result is appended to\n"
}

hash sparql 2>/dev/null || { echo >&2 "sparql (Jena) not on \$PATH. Aborting."; exit 1; }
hash curl 2>/dev/null || { echo >&2 "curl not on \$PATH. Aborting."; exit 1; }
hash xmllint 2>/dev/null || { echo >&2 "xmllint not on \$PATH. Aborting."; exit 1; }

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

# rewrite an application URL's host to the proxy host, when a proxy is given
rewrite_proxy()
{
    local url="$1"

    if [ -n "$proxy" ]; then
        local url_host proxy_host
        url_host=$(echo "$url" | cut -d '/' -f 1,2,3)
        proxy_host=$(echo "$proxy" | cut -d '/' -f 1,2,3)
        echo "${url/$url_host/$proxy_host}"
    else
        echo "$url"
    fi
}

query_doc="${base}queries/construct-constructors/"
query_url=$(rewrite_proxy "$query_doc")
graph_url=$(rewrite_proxy "$graph")

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

# 1. fetch the construct-constructors query document, then extract its exact sp:text via a SPARQL SELECT

curl -s -k -E "$cert_pem_file":"$cert_password" -H "Accept: text/turtle" "$query_url" > "$tmp_dir/query.ttl"

cat > "$tmp_dir/extract-text.rq" <<RQ
PREFIX sp: <http://spinrdf.org/spin#>
SELECT ?text WHERE { <${base}queries/construct-constructors/#this> sp:text ?text }
RQ

sparql --data "$tmp_dir/query.ttl" --query "$tmp_dir/extract-text.rq" --results=XML \
  | xmllint --xpath 'string(//*[local-name()="literal"])' - \
  > "$tmp_dir/construct.rq"

if [ ! -s "$tmp_dir/construct.rq" ]; then
    echo >&2 "Could not extract the CONSTRUCT query (sp:text) from ${query_doc}. Aborting."
    exit 1
fi

# 2. run the CONSTRUCT over the source ontology locally, producing Turtle

sparql --data "$source" --query "$tmp_dir/construct.rq" --results=Turtle > "$tmp_dir/result.ttl"

# 3. append the transformed triples to the target graph (Graph Store Protocol POST)

curl -s -k -E "$cert_pem_file":"$cert_password" \
  --data-binary @"$tmp_dir/result.ttl" \
  -H "Content-Type: text/turtle" \
  -H "Accept: text/turtle" \
  "$graph_url" -D -
