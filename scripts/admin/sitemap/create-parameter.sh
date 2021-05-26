#!/bin/bash

print_usage()
{
    printf "Creates an LDT parameter.\n"
    printf "\n"
    printf "Usage:  %s options [TARGET_URI]\n" "$0"
    printf "\n"
    printf "Options:\n"
    printf "  -f, --cert-pem-file CERT_FILE        .pem file with the WebID certificate of the agent\n"
    printf "  -p, --cert-password CERT_PASSWORD    Password of the WebID certificate\n"
    printf "  -b, --base BASE_URI                  Base URI of the admin application\n"
    printf "\n"
    printf "  --label LABEL                        Label of the parameter\n"
    printf "  --comment COMMENT                    Description of the parameter (optional)\n"
    printf "  --slug STRING                        String that will be used as URI path segment (optional)\n"
    printf "\n"
    printf "  --uri URI                            URI of the parameter (optional)\n"
    printf "  --predicate PREDICATE_URI            URI of the predicate -- its local name used as parameter name\n"
    printf "  --value-type URI                     URI value of spl:valueType\n"
    printf "  --optional                           Parameter is optional (optional)\n"
    printf "  --is-defined-by ONTOLOGY_URI         URI of the ontology this parameter is defined in\n"
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
        --predicate)
        predicate="$2"
        shift # past argument
        shift # past value
        ;;
        --value-type)
        value_type="$2"
        shift # past argument
        shift # past value
        ;;
        --optional)
        optional=true
        shift # past value
        ;;
        --is-defined-by)
        is_defined_by="$2"
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
if [ -z "$predicate" ] ; then
    print_usage
    exit 1
fi
if [ -z "$value_type" ] ; then
    print_usage
    exit 1
fi
if [ -z "$is_defined_by" ] ; then
    print_usage
    exit 1
fi

container="${base}sitemap/parameters/"

# allow explicit URIs
if [ -n "$uri" ] ; then
    param="<${uri}>" # URI
else
    param="_:param" # blank node
fi

if [ -z "$1" ]; then
    args+=("${base}service") # default target URL = graph store
fi

args+=("-f")
args+=("${cert_pem_file}")
args+=("-p")
args+=("${cert_password}")
args+=("-t")
args+=("text/turtle") # content type

turtle+="@prefix ns:	<ns#> .\n"
turtle+="@prefix rdfs:	<http://www.w3.org/2000/01/rdf-schema#> .\n"
turtle+="@prefix spl:	<http://spinrdf.org/spl#> .\n"
turtle+="@prefix dct:	<http://purl.org/dc/terms/> .\n"
turtle+="@prefix foaf:	<http://xmlns.com/foaf/0.1/> .\n"
turtle+="@prefix dh:	<https://www.w3.org/ns/ldt/document-hierarchy/domain#> .\n"
turtle+="@prefix sioc:	<http://rdfs.org/sioc/ns#> .\n"
turtle+="${param} a ns:Parameter .\n"
turtle+="${param} rdfs:label \"${label}\" .\n"
turtle+="${param} foaf:isPrimaryTopicOf _:item .\n"
turtle+="${param} rdfs:isDefinedBy <${is_defined_by}> .\n"
turtle+="_:item a ns:ParameterItem .\n"
turtle+="_:item sioc:has_container <${container}> .\n"
turtle+="_:item dct:title \"${label}\" .\n"
turtle+="_:item foaf:primaryTopic ${param} .\n"

if [ -n "$comment" ] ; then
    turtle+="${param} rdfs:comment \"${comment}\" .\n"
fi
if [ -n "$slug" ] ; then
    turtle+="_:item dh:slug \"${slug}\" .\n"
fi

if [ -n "$predicate" ] ; then
    turtle+="${param} spl:predicate <${predicate}> .\n"
fi
if [ -n "$value_type" ] ; then
    turtle+="${param} spl:valueType <${value_type}> .\n"
fi
if [ -n "$optional" ] ; then
    turtle+="${param} spl:optional true .\n"
fi

# submit Turtle doc to the server
echo -e "$turtle" | turtle --base="$base" | ../../create-document.sh "${args[@]}"