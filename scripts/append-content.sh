#!/usr/bin/env bash

print_usage()
{
    printf "Appends content instance to document.\n"
    printf "\n"
    printf "Usage:  %s options TARGET_URI\n" "$0"
    printf "\n"
    printf "Options:\n"
    printf "  -f, --cert-pem-file CERT_FILE        .pem file with the WebID certificate of the agent\n"
    printf "  -p, --cert-password CERT_PASSWORD    Password of the WebID certificate\n"
    printf "  --proxy PROXY_URL                    The host this request will be proxied through (optional)\n"
    printf "\n"
    printf "  --value RESOURCE_URI                 URI of the content element (query, chart etc.)\n"
    printf "  --mode MODE_URI                      URI of the content mode (list, grid etc.) (optional)\n"
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
        --value)
        value="$2"
        shift # past argument
        shift # past value
        ;;
        --mode)
        mode="$2"
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
if [ -z "$value" ] ; then
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

if [ -n "$mode" ] ; then
    mode_bgp="?content ac:mode <${mode}> ."
fi

# SPARQL update logic from https://github.com/enridaga/list-benchmark/tree/master/queries

curl -X PATCH \
    -v -f -k \
    -E "$cert_pem_file":"$cert_password" \
    -H "Content-Type: application/sparql-update" \
    "$target" \
     --data-binary @- <<EOF
PREFIX  ldh:  <https://w3id.org/atomgraph/linkeddatahub#>
PREFIX  ac:   <https://w3id.org/atomgraph/client#>
PREFIX  rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX  xsd:  <http://www.w3.org/2001/XMLSchema#>

INSERT {
  GRAPH <${this}> {
    <${this}> ?property ?content .
    ?content a ldh:Content ;
        rdf:value <${value}> .
    ${mode_bgp}
  }
}
WHERE
  { { SELECT  (( MAX(?index) + 1 ) AS ?next)
      WHERE
        { GRAPH <${this}>
            { <${this}>
                        ?seq      ?content .
              ?content  a  ldh:Content
              BIND(xsd:integer(substr(str(?seq), 45)) AS ?index)
            }
        }
    }
    BIND(iri(concat(str(rdf:), "_", str(?next))) AS ?property)
    BIND(uri(concat(str(<${this}>), "#", struuid())) AS ?content)
  };

EOF