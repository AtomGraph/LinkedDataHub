#!/usr/bin/env bash

print_usage()
{
    printf "Creates a SPIN constraint that makes a property required.\n"
    printf "\n"
    printf "Usage:  %s options [TARGET_URI]\n" "$0"
    printf "\n"
    printf "Options:\n"
    printf "  -f, --cert-pem-file CERT_FILE        .pem file with the WebID certificate of the agent\n"
    printf "  -p, --cert-password CERT_PASSWORD    Password of the WebID certificate\n"
    printf "  -b, --base BASE_URI                  Base URI of the admin application\n"
    printf "  --proxy PROXY_URL                    The host this request will be proxied through (optional)\n"
    printf "\n"
    printf "  --label LABEL                        Label of the constraint\n"
    printf "  --comment COMMENT                    Description of the constraint (optional)\n"
    printf "  --slug STRING                        String that will be used as URI path segment (optional)\n"
    printf "  --fragment STRING                    String that will be used as URI fragment identifier (optional)\n"
    printf "\n"
    printf "  --uri URI                            URI of the constraint (optional)\n"
    printf "  --property PROPERTY_URI              URI of the constrained property\n"
}

hash turtle 2>/dev/null || { echo >&2 "turtle not on \$PATH. Need to set \$JENA_HOME. Aborting."; exit 1; }

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
        --fragment)
        fragment="$2"
        shift # past argument
        shift # past value
        ;;
        --uri)
        uri="$2"
        shift # past argument
        shift # past value
        ;;
        --property)
        property="$2"
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
if [ -z "$label" ] ; then
    print_usage
    exit 1
fi
if [ -z "$property" ] ; then
    print_usage
    exit 1
fi
if [ -z "$1" ]; then
    print_usage
    exit 1
fi

# allow explicit URIs
if [ -n "$uri" ] ; then
    constraint="<${uri}>" # URI
else
    constraint="_:constraint" # blank node
fi

if [ -z "$slug" ] ; then
    slug=$(uuidgen | tr '[:upper:]' '[:lower:]') # lowercase
fi
encoded_slug=$(urlencode "$slug")

container="${base}model/constraints/"

args+=("-f")
args+=("$cert_pem_file")
args+=("-p")
args+=("$cert_password")
args+=("-t")
args+=("text/turtle") # content type

turtle+="@prefix ldh:	<https://w3id.org/atomgraph/linkeddatahub#> .\n"
turtle+="@prefix dh:	<https://www.w3.org/ns/ldt/document-hierarchy#> .\n"
turtle+="@prefix rdfs:	<http://www.w3.org/2000/01/rdf-schema#> .\n"
turtle+="@prefix dct:	<http://purl.org/dc/terms/> .\n"
turtle+="@prefix foaf:	<http://xmlns.com/foaf/0.1/> .\n"
turtle+="@prefix sp:	<http://spinrdf.org/sp#> .\n"
turtle+="@prefix sioc:	<http://rdfs.org/sioc/ns#> .\n"
turtle+="${constraint} a ldh:MissingPropertyValue .\n"
turtle+="${constraint} rdfs:label \"${label}\" .\n"
turtle+="${constraint} sp:arg1 <${property}> .\n"
turtle+="<${parent}${encoded_slug}/> a dh:Item .\n"
turtle+="<${parent}${encoded_slug}/> foaf:primaryTopic ${constraint} .\n"
turtle+="<${parent}${encoded_slug}/> sioc:has_container <${container}> .\n"
turtle+="<${parent}${encoded_slug}/> dct:title \"${label}\" .\n"

if [ -n "$comment" ] ; then
    turtle+="${constraint} rdfs:comment \"${comment}\" .\n"
fi
if [ -n "$fragment" ] ; then
    turtle+="${constraint} ldh:fragment \"${fragment}\" .\n"
fi

# submit Turtle doc to the server
echo -e "$turtle" | turtle --base="$base" | ../../create-document.sh "${args[@]}"