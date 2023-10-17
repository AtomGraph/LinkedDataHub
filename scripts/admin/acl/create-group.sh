#!/usr/bin/env bash

print_usage()
{
    printf "Creates an ACL agent group.\n"
    printf "\n"
    printf "Usage:  %s options\n" "$0"
    printf "\n"
    printf "Options:\n"
    printf "  -f, --cert-pem-file CERT_FILE        .pem file with the WebID certificate of the agent\n"
    printf "  -p, --cert-password CERT_PASSWORD    Password of the WebID certificate\n"
    printf "  -b, --base BASE_URI                  Base URI of the admin application\n"
    printf "  --proxy PROXY_URL                    The host this request will be proxied through (optional)\n"
    printf "\n"
    printf "  --name NAME                          Name of the group\n"
    printf "  --description DESCRIPTION            Description of the group (optional)\n"
    printf "  --slug STRING                        String that will be used as URI path segment (optional)\n"
    printf "  --fragment STRING                    String that will be used as URI fragment identifier (optional)\n"
    printf "\n"
    printf "  --uri URI                            URI of the group (optional)\n"
    printf "  --member MEMBER_URI                  URI of the member agent (optional)\n"
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
        -b|--base)
        base="$2"
        shift # past argument
        shift # past value
        ;;
        --name)
        name="$2"
        shift # past argument
        shift # past value
        ;;
        --description)
        description="$2"
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
        --member)
        members+=("$2")
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
if [ -z "$name" ] ; then
    print_usage
    exit 1
fi
if [ ${#members[@]} -eq 0 ]; then
    print_usage
    exit 1
fi
if [ -z "$slug" ] ; then
    slug=$(uuidgen | tr '[:upper:]' '[:lower:]') # lowercase
fi

encoded_slug=$(urlencode "$slug")
container="${base}acl/groups/"

# allow explicit URIs
if [ -n "$uri" ] ; then
    group="<${uri}>" # URI
else
    group="_:auth" # blank node
fi

args+=("-f")
args+=("$cert_pem_file")
args+=("-p")
args+=("$cert_password")
args+=("-t")
args+=("text/turtle") # content type
args+=("${base}service")

turtle+="@prefix ldh:	<https://w3id.org/atomgraph/linkeddatahub#> .\n"
turtle+="@prefix dh:	<https://www.w3.org/ns/ldt/document-hierarchy#> .\n"
turtle+="@prefix dct:	<http://purl.org/dc/terms/> .\n"
turtle+="@prefix foaf:	<http://xmlns.com/foaf/0.1/> .\n"
turtle+="@prefix sioc:	<http://rdfs.org/sioc/ns#> .\n"
turtle+="${group} a foaf:Group .\n"
turtle+="${group} foaf:name \"${label}\" .\n"
turtle+="<${container}${encoded_slug}/> a dh:Item .\n"
turtle+="<${container}${encoded_slug}/> foaf:primaryTopic ${group} .\n"
turtle+="<${container}${encoded_slug}/> sioc:has_container <${container}> .\n"
turtle+="<${container}${encoded_slug}/> dct:title \"${label}\" .\n"

if [ -n "$description" ] ; then
    turtle+="${group} dct:description \"${description}\" .\n"
fi
if [ -n "$fragment" ] ; then
    turtle+="${group} ldh:fragment \"${fragment}\" .\n"
fi

for member in "${members[@]}"
do
    turtle+="${group} foaf:member <$member> .\n"
done

# submit Turtle doc to the server
echo -e "$turtle" | turtle --base="$base" | ../../create-document.sh "${args[@]}"