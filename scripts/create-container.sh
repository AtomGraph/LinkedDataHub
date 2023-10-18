#!/usr/bin/env bash

print_usage()
{
    printf "Creates a container document.\n"
    printf "\n"
    printf "Usage:  %s options\n" "$0"
    printf "\n"
    printf "Options:\n"
    printf "  -f, --cert-pem-file CERT_FILE        .pem file with the WebID certificate of the agent\n"
    printf "  -p, --cert-password CERT_PASSWORD    Password of the WebID certificate\n"
    printf "  -b, --base BASE_URI                  Base URI of the application\n"
    printf "  --proxy PROXY_URL                    The host this request will be proxied through (optional)\n"
    printf "\n"
    printf "  --title TITLE                        Title of the container\n"
    printf "  --description DESCRIPTION            Description of the container (optional)\n"
    printf "  --slug STRING                        String that will be used as URI path segment (optional)\n"
    printf "\n"
    printf "  --parent PARENT_URI                  URI of the parent container\n"
    printf "  --content CONTENT_URI                URI of the content list (optional)\n"
}

hash turtle 2>/dev/null || { echo >&2 "turtle not on \$PATH. Need to set \$JENA_HOME. Aborting."; exit 1; }

urlencode() {
  python -c 'import urllib, sys; print(urllib.quote(sys.argv[1], sys.argv[2]))' \
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
        --title)
        title="$2"
        shift # past argument
        shift # past value
        ;;
        --description)
        description="$2"
        shift # past argument
        shift # past value
        ;;
        --parent)
        parent="$2"
        shift # past argument
        shift # past value
        ;;
        --content)
        content="$2"
        shift # past argument
        shift # past value
        ;;
        --mode)
        mode="$2"
        shift # past argument
        shift # past value
        ;;
        --slug)
        slug="$2"
        shift # past argument
        shift # past value
        ;;
        *)    # unknown arguments
        args+=("$1") # save it in an array for later
        shift # past argument
        ;;
    esac
done
set -- "${args[@]}" # restore args parameters

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
if [ -z "$title" ] ; then
    print_usage
    exit 1
fi
if [ -z "$parent" ] ; then
    print_usage
    exit 1
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
args+=("text/turtle")
args+=("${parent}${encoded_slug}/")

turtle+="@prefix dh:	<https://www.w3.org/ns/ldt/document-hierarchy#> .\n"
turtle+="@prefix ac:	<https://w3id.org/atomgraph/client#> .\n"
turtle+="@prefix ldh:	<https://w3id.org/atomgraph/linkeddatahub#> .\n"
turtle+="@prefix rdf:	<http://www.w3.org/1999/02/22-rdf-syntax-ns#> .\n"
turtle+="@prefix dct:	<http://purl.org/dc/terms/> .\n"
#turtle+="@prefix sioc:	<http://rdfs.org/sioc/ns#> .\n"
turtle+="<${parent}${encoded_slug}/> a dh:Container .\n"
turtle+="<${parent}${encoded_slug}/> dct:title \"${title}\" .\n"
#turtle+="<${parent}${encoded_slug}/> sioc:has_parent <${parent}> .\n"
if [ -n "$content" ] ; then
    turtle+="<${parent}${encoded_slug}/> rdf:_1 <${content}> .\n"
else
    content_triples="a ldh:Content; rdf:value ldh:SelectChildren"
    if [ -n "$mode" ] ; then
        content_triples+="; ac:mode <${mode}> "
    fi
    turtle+="<${parent}${encoded_slug}/> rdf:_1 [ ${content_triples} ] .\n"
fi
if [ -n "$description" ] ; then
    turtle+="<${parent}${encoded_slug}/> dct:description \"${description}\" .\n"
fi

echo -e "$turtle" | turtle --base="$base" | ./put-document.sh "${args[@]}"