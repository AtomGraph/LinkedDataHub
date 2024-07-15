#!/usr/bin/env bash

print_usage()
{
    printf "Appends a view for SPARQL SELECT query results.\n"
    printf "\n"
    printf "Usage:  %s options\n" "$0"
    printf "\n"
    printf "Options:\n"
    printf "  -f, --cert-pem-file CERT_FILE        .pem file with the WebID certificate of the agent\n"
    printf "  -p, --cert-password CERT_PASSWORD    Password of the WebID certificate\n"
    printf "  -b, --base BASE_URI                  Base URI of the application\n"
    printf "  --proxy PROXY_URL                    The host this request will be proxied through (optional)\n"
    printf "\n"
    printf "  --title TITLE                        Title of the view\n"
    printf "  --description DESCRIPTION            Description of the view (optional)\n"
    printf "  --fragment STRING                    String that will be used as URI fragment identifier (optional)\n"
    printf "\n"
    printf "  --query QUERY_URI                    URI of the SELECT query\n"
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
        --fragment)
        fragment="$2"
        shift # past argument
        shift # past value
        ;;
        --query)
        query="$2"
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
if [ -z "$title" ] ; then
    print_usage
    exit 1
fi
if [ -z "$query" ] ; then
    print_usage
    exit 1
fi

args+=("-f")
args+=("$cert_pem_file")
args+=("-p")
args+=("$cert_password")
args+=("-t")
args+=("text/turtle") # content type

ntriples=$(./get.sh "${args[@]}")
echo "$ntriples"


if [ -n "$fragment" ] ; then
    # relative URI that will be resolved against the request URI
    subject="<#${fragment}>"
else
    subject="_:subject"
fi

turtle+="@prefix ldh:	<https://w3id.org/atomgraph/linkeddatahub#> .\n"
turtle+="@prefix dct:	<http://purl.org/dc/terms/> .\n"
turtle+="@prefix spin:  <http://spinrdf.org/spin#> .\n"
turtle+="${subject} a ldh:View .\n"
turtle+="${subject} dct:title \"${title}\" .\n"
turtle+="${subject} spin:query <${query}> .\n"

if [ -n "$description" ] ; then
    turtle+="${subject} dct:description \"${description}\" .\n"
fi

# submit Turtle doc to the server
echo -e "$turtle" | ./post.sh "${args[@]}"
