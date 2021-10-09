#!/bin/bash

print_usage()
{
    printf "Makes all documents of the end-user application publicly readable.\n"
    printf "\n"
    printf "Usage:  %s options\n" "$0"
    printf "\n"
    printf "Options:\n"
    printf "  -f, --cert-pem-file CERT_FILE        .pem file with the WebID certificate of the agent\n"
    printf "  -p, --cert-password CERT_PASSWORD    Password of the WebID certificate\n"
    printf "  -b, --base BASE_URI                  Base URI of the admin application\n"
    printf "  --request-base BASE_URI              Request base URI (if different from --base)\n"
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
        --request-base)
        request_base="$2"
        shift # past argument
        shift # past value
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

if [ -z "request_base" ]; then
    request_base="$base"
fi

curl -X PATCH \
    -v -f -k \
    -E "$cert_pem_file":"$cert_password" \
    -H "Content-Type: application/sparql-update" \
    "${request_base}admin/acl/authorizations/public/" \
     --data-binary @- <<EOF
BASE <${base}admin/>

PREFIX  acl:  <http://www.w3.org/ns/auth/acl#>
PREFIX  def: <https://w3id.org/atomgraph/linkeddatahub/default#>

INSERT DATA
{
  GRAPH <acl/authorizations/public/>
  {
    <acl/authorizations/public/#this> acl:accessToClass def:Root, def:Container, def:Item, def:File ;
        acl:accessTo <../sparql> .
  }
}
EOF