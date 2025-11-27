#!/usr/bin/env bash
set -eo pipefail

print_usage()
{
    printf "Creates a new ontology.\n"
    printf "\n"
    printf "Usage:  %s options [TARGET_URI]\n" "$0"
    printf "\n"
    printf "Options:\n"
    printf "  -f, --cert-pem-file CERT_FILE        .pem file with the WebID certificate of the agent\n"
    printf "  -p, --cert-password CERT_PASSWORD    Password of the WebID certificate\n"
    printf "  -b, --base BASE_URI                  Base URI of the admin application\n"
    printf "  --proxy PROXY_URL                    The host this request will be proxied through (optional)\n"
    printf "\n"
    printf "  --label LABEL                        Label of the ontology\n"
    printf "  --comment COMMENT                    Description of the ontology (optional)\n"
    printf "  --slug STRING                        String that will be used as URI path segment (optional)\n"
    printf "\n"
    printf "  --uri URI                            URI of the ontology (optional)\n"
}

hash turtle 2>/dev/null || { echo >&2 "turtle not on \$PATH.  Aborting."; exit 1; }

urlencode() {
  python -c 'import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1], sys.argv[2]))' \
    "$1" "$urlencode_safe"
}

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
        --label)
        label="$2"
        shift # past argument
        shift # past value
        ;;
        --comment)
        comment="$2"
        shift # past argument
        shift # past value
        ;;
        --slug)
        slug="$2"
        shift # past argument
        shift # past value
        ;;
        --uri)
        uri="$2"
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

target="$1"

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
if [ -z "$label" ] ; then
    print_usage
    exit 1
fi

container="${base}ontologies/"

# allow explicit URIs
if [ -n "$uri" ] ; then
    ontology="<${uri}>" # URI
else
    ontology="_:ontology" # blank node
fi

if [ -z "$slug" ] ; then
    slug=$(uuidgen | tr '[:upper:]' '[:lower:]') # lowercase
fi
encoded_slug=$(urlencode "$slug")

args+=("-f")
args+=("$cert_pem_file")
args+=("-p")
args+=("$cert_password")
args+=("-t")
args+=("text/turtle") # content type
args+=("${container}${encoded_slug}/")

turtle+="@prefix dh:	<https://www.w3.org/ns/ldt/document-hierarchy#> .\n"
turtle+="@prefix owl:	<http://www.w3.org/2002/07/owl#> .\n"
turtle+="@prefix rdfs:	<http://www.w3.org/2000/01/rdf-schema#> .\n"
turtle+="@prefix dct:	<http://purl.org/dc/terms/> .\n"
turtle+="@prefix foaf:	<http://xmlns.com/foaf/0.1/> .\n"
turtle+="@prefix sp:	<http://spinrdf.org/sp#> .\n"
turtle+="${ontology} a owl:Ontology .\n"
turtle+="${ontology} rdfs:label \"${label}\" .\n"
turtle+="<${container}${encoded_slug}/> a dh:Item .\n"
turtle+="<${container}${encoded_slug}/> foaf:primaryTopic ${ontology} .\n"
turtle+="<${container}${encoded_slug}/> dct:title \"${label}\" .\n"

if [ -n "$comment" ] ; then
    turtle+="${ontology} rdfs:comment \"${comment}\" .\n"
fi

# submit Turtle doc to the server
echo -e "$turtle" | turtle --base="$target" | put.sh "${args[@]}"