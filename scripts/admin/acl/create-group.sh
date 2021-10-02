#!/bin/bash

print_usage()
{
    printf "Creates an ACL agent group.\n"
    printf "\n"
    printf "Usage:  %s options [TARGET_URI]\n" "$0"
    printf "\n"
    printf "Options:\n"
    printf "  -f, --cert-pem-file CERT_FILE        .pem file with the WebID certificate of the agent\n"
    printf "  -p, --cert-password CERT_PASSWORD    Password of the WebID certificate\n"
    printf "  -b, --base BASE_URI                  Base URI of the admin application\n"
    printf "\n"
    printf "  --name NAME                          Name of the group\n"
    printf "  --description DESCRIPTION            Description of the group (optional)\n"
    printf "  --slug STRING                        String that will be used as URI path segment (optional)\n"
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

container="${base}acl/groups/"

# allow explicit URIs
if [ -n "$uri" ] ; then
    group="<${uri}>" # URI
else
    group="_:auth" # blank node
fi

if [ -z "$1" ]; then
    # create graph

    pushd . > /dev/null && cd "$SCRIPT_ROOT/admin"

    graph=$(./create-item.sh -f "$cert_pem_file" -p "$cert_password" -b "$base" --container "$container" --title "$label")

    popd > /dev/null

    args+=("$graph") # default target URL = named graph URI
else
    graph="$1"
fi

args+=("-f")
args+=("$cert_pem_file")
args+=("-p")
args+=("$cert_password")
args+=("-t")
args+=("text/turtle") # content type

turtle+="@prefix ns:	<ns#> .\n"
turtle+="@prefix foaf:	<http://xmlns.com/foaf/0.1/> .\n"
turtle+="${group} a ns:Group .\n"
turtle+="${group} foaf:name \"${label}\" .\n"
turtle+="${group} foaf:isPrimaryTopicOf <${graph}> .\n"

if [ -n "$description" ] ; then
    turtle+="@prefix dct:	<http://purl.org/dc/terms/> .\n"
    turtle+="${group} dct:description \"${description}\" .\n"
fi

for member in "${members[@]}"
do
    turtle+="${group} foaf:member <$member> .\n"
done

pushd . > /dev/null && cd "$SCRIPT_ROOT"

# submit Turtle doc to the server
echo -e "$turtle" | turtle --base="$base" | ./create-document.sh "${args[@]}"

popd > /dev/null

echo "$graph"