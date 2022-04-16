#!/usr/bin/env bash

print_usage()
{
    printf "Appends content instance to document.\n"
    printf "\n"
    printf "Usage:  %s options [TARGET_URI]\n" "$0"
    printf "\n"
    printf "Options:\n"
    printf "  -f, --cert-pem-file CERT_FILE        .pem file with the WebID certificate of the agent\n"
    printf "  -p, --cert-password CERT_PASSWORD    Password of the WebID certificate\n"
    printf "\n"
    printf "  --this DOCUMENT_URI                  Document URI\n"
    printf "  --first RESOURCE_URI                 URI of the content element (query, chart etc.)\n"
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
        --this)
        first="$2"
        shift # past argument
        shift # past value
        ;;
        --first)
        first="$2"
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
if [ -z "$this" ] ; then
    print_usage
    exit 1
fi
if [ -z "$first" ] ; then
    print_usage
    exit 1
fi

if [ -z "$1" ] ; then
    target="$this"
else
    target="$1"
fi

if [ -n "$mode" ] ; then
    mode_bgp="?content ac:mode <${mode}> ."
fi

# SPARQL update logic from https://afs.github.io/rdf-lists-sparql#a-nameadd-lastaadd-an-element-to-the-end-of-a-list

curl -X PATCH \
    -v -f -k \
    -E "$cert_pem_file":"$cert_password" \
    -H "Content-Type: application/sparql-update" \
    "$target" \
     --data-binary @- <<EOF
PREFIX  ldh:  <https://w3id.org/atomgraph/linkeddatahub#>
PREFIX  ac:   <https://w3id.org/atomgraph/client#>
PREFIX  rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#>

INSERT {
  GRAPH ?g {
    ?this ldh:content rdf:nil .
  }
}
WHERE
  { SELECT  ?g ?this
    WHERE
      { GRAPH ?g
          { ?this  ?p  ?o
            FILTER NOT EXISTS { ?this  ldh:content  ?content }
          }
        VALUES ?this { <${this}> }
      }
  };

# List of length >= 1
DELETE {
    GRAPH ?g {
        ?elt rdf:rest rdf:nil
    }
}
INSERT {
    GRAPH ?g {
        ?elt rdf:rest ?content .
        ?content a ldh:Content ;
            rdf:first <$first> ;
            rdf:rest rdf:nil .
        ${mode_bgp}
    }
}
WHERE
{
    GRAPH ?g {
        <${this}> ldh:content ?list .
        # List of length >= 1
        ?list rdf:rest* ?elt .
        ?elt rdf:rest rdf:nil .
        # ?elt is last cons cell
        BIND (uri(concat(str(<${this}>), '#', struuid())) as ?content)
    }
};

# List of length = 0
DELETE {
    GRAPH ?g {
        <${this}> ldh:content rdf:nil .
    }
}
INSERT {
    GRAPH ?g {
        <${this}> ldh:content ?content .
        ?content a ldh:Content ;
            rdf:first <$first> ;
            rdf:rest rdf:nil .
        ${mode_bgp}
    }
}
WHERE
{
    GRAPH ?g {
        <${this}> ldh:content rdf:nil .
        BIND (uri(concat(str(<${this}>), '#', struuid())) as ?content)
    }
};

EOF