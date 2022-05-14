#!/usr/bin/env bash

print_usage()
{
    printf "Removes content from document.\n"
    printf "\n"
    printf "Usage:  %s options TARGET_URI\n" "$0"
    printf "\n"
    printf "Options:\n"
    printf "  -f, --cert-pem-file CERT_FILE        .pem file with the WebID certificate of the agent\n"
    printf "  -p, --cert-password CERT_PASSWORD    Password of the WebID certificate\n"
    printf "  --proxy PROXY_URL                    The host this request will be proxied through (optional)\n"
}

hash turtle 2>/dev/null || { echo >&2 "turtle not on \$PATH. Need to set \$JENA_HOME. Aborting."; exit 1; }

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
        --proxy)
        proxy="$2"
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

target="$1"
this="$1"

if [ -n "$proxy" ]; then
    # rewrite target hostname to proxy hostname
    target_host=$(echo "$target" | cut -d '/' -f 1,2,3)
    proxy_host=$(echo "$proxy" | cut -d '/' -f 1,2,3)
    target="${target/$target_host/$proxy_host}"
fi

# SPARQL update logic from https://afs.github.io/rdf-lists-sparql#a-namedel-all-1adelete-the-whole-list-common-case

curl -X PATCH \
    -v -f -k \
    -E "$cert_pem_file":"$cert_password" \
    -H "Content-Type: application/sparql-update" \
    "$target" \
     --data-binary @- <<EOF
PREFIX  ldh:  <https://w3id.org/atomgraph/linkeddatahub#>
PREFIX  ac:   <https://w3id.org/atomgraph/client#>
PREFIX  rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#>

DELETE {
  GRAPH ?g {
    ?z a ?type .
    ?z rdf:first ?head .
    ?z rdf:rest ?tail .
    ?z ac:mode ?mode .
  }
}
WHERE
  { GRAPH ?g
      { <${this}> ldh:content  ?content .
        ?content (rdf:rest)* ?z .
        ?z  rdf:first  ?head ;
            rdf:rest   ?tail
        OPTIONAL
          { ?z  a  ?type }
        OPTIONAL
          { ?z  ac:mode  ?mode }
      }
  };

DELETE WHERE {
  GRAPH ?g {
    <${this}> ldh:content  ?content .
  }
};

EOF