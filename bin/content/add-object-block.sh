#!/usr/bin/env bash
set -eo pipefail

print_usage()
{
    printf "Appends an object block.\n"
    printf "\n"
    printf "Usage:  %s options TARGET_URI\n" "$0"
    printf "\n"
    printf "Options:\n"
    printf "  -f, --cert-pem-file CERT_FILE        .pem file with the WebID certificate of the agent\n"
    printf "  -p, --cert-password CERT_PASSWORD    Password of the WebID certificate\n"
    printf "  -b, --base BASE_URI                  Base URI of the application\n"
    printf "  --proxy PROXY_URL                    The host this request will be proxied through (optional)\n"
    printf "\n"
    printf "  --title TITLE                        Title\n"
    printf "  --description DESCRIPTION            Description(optional)\n"
    printf "  --uri URI                            URI of the object block (optional)\n"
    printf "\n"
    printf "  --value RESOURCE_URI                 URI of the object resource\n"
    printf "  --mode MODE_URI                      URI of the block mode (list, grid etc.) (optional)\n"
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
        --proxy)
        proxy="$2"
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
        --uri)
        uri="$2"
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
if [ -z "$base" ] ; then
    print_usage
    exit 1
fi
if [ -z "$value" ] ; then
    print_usage
    exit 1
fi

target="$1"

ntriples=$(get.sh \
  -f "$cert_pem_file" \
  -p "$cert_password" \
 --proxy "$proxy" \
  --accept 'application/n-triples' \
  "$target")

# extract the numbers from the sequence properties
sequence_number=$(echo "$ntriples" | grep "<${target}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#_" | cut -d " " -f 2 | cut -d'#' -f 2 | cut -d '_' -f 2 | cut -d '>' -f 1 |  sort -nr | head -n1)
sequence_number=$((sequence_number + 1)) # increase the counter
sequence_property="http://www.w3.org/1999/02/22-rdf-syntax-ns#_${sequence_number}"

args+=("-f")
args+=("$cert_pem_file")
args+=("-p")
args+=("$cert_password")
args+=("-t")
args+=("text/turtle") # content type
args+=("--proxy")
args+=("$proxy") # tunnel the proxy param

if [ -n "$uri" ] ; then
    subject="<${uri}>"
else
    subject="_:subject"
fi

turtle+="@prefix ldh:	<https://w3id.org/atomgraph/linkeddatahub#> .\n"
turtle+="@prefix dct:	<http://purl.org/dc/terms/> .\n"
turtle+="@prefix rdf:   <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .\n"
turtle+="<${target}> <${sequence_property}> ${subject} .\n"
turtle+="${subject} a ldh:Object .\n"
turtle+="${subject} rdf:value <${value}> .\n"

if [ -n "$title" ] ; then
    turtle+="${subject} dct:title \"${title}\" .\n"
fi
if [ -n "$description" ] ; then
    turtle+="${subject} dct:description \"${description}\" .\n"
fi
if [ -n "$mode" ] ; then
    turtle+="@prefix ac:	<https://w3id.org/atomgraph/client#> .\n"
    turtle+="${subject} ac:mode <${mode}> .\n"
fi

# submit Turtle doc to the server
echo -e "$turtle" | turtle --base="$target" | post.sh "${args[@]}"
