#!/bin/bash

print_usage()
{
    printf "Creates an LDT template.\n"
    printf "\n"
    printf "Usage:  %s options [TARGET_URI]\n" "$0"
    printf "\n"
    printf "Options:\n"
    printf "  -f, --cert-pem-file CERT_FILE        .pem file with the WebID certificate of the agent\n"
    printf "  -p, --cert-password CERT_PASSWORD    Password of the WebID certificate\n"
    printf "  -b, --base BASE_URI                  Base URI of the admin application\n"
    printf "\n"
    printf "  --label LABEL                        Label of the template\n"
    printf "  --comment COMMENT                    Description of the query (optional)\n"
    printf "  --slug STRING                        String that will be used as URI path segment (optional)\n"
    printf "\n"
    printf "  --uri URI                            URI of the template (optional)\n"
    printf "  --query QUERY_URI                    URI of the CONSTRUCT/DESCRIBE query (optional)\n"
    printf "  --match URI_TEMPLATE                 Match URI template (optional)\n"
    printf "  --extends SUPER_TEMPLATE_URI         URI of the super-template (optional)\n"
    printf "  --param PARAM_URI                    URI of an LDT parameter (optional)\n"
    printf "  --load-class CLASS_URI               URI of a JAX-RS resource class (optional)\n"
    printf "  --is-defined-by ONTOLOGY_URI         URI of the ontology this template is defined in\n"
}

hash turtle 2>/dev/null || { echo >&2 "turtle not on \$PATH. Need to set \$JENA_HOME. Aborting."; exit 1; }

args=()
params=() # --param can have multiple values, so we need an array
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
        --query)
        query="$2"
        shift # past argument
        shift # past value
        ;;
        --match)
        match="$2"
        shift # past argument
        shift # past value
        ;;
        --extends)
        extends="$2"
        shift # past argument
        shift # past value
        ;;
        --param)
        params+=("$2")
        shift # past argument
        shift # past value
        ;;
        --load-class)
        load_class="$2"
        shift # past argument
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
if { [ -z "$extends" ] && [ -z "$query" ] ; } || { [ -z "$extends" ] && [ -z "$match" ] ; } ; then
    print_usage
    exit 1
fi
if [ -z "$is_defined_by" ] ; then
    print_usage
    exit 1
fi

container="${base}sitemap/templates/"

# allow explicit URIs
if [ -n "$uri" ] ; then
    template="<${uri}>" # URI
else
    template="_:template" # blank node
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
args+=("--for-class")
args+=("${base}ns#Template")

turtle+="@prefix ns:	<ns#> .\n"
turtle+="@prefix rdfs:	<http://www.w3.org/2000/01/rdf-schema#> .\n"
turtle+="@prefix ldt:	<https://www.w3.org/ns/ldt#> .\n"
turtle+="@prefix dct:	<http://purl.org/dc/terms/> .\n"
turtle+="@prefix foaf:	<http://xmlns.com/foaf/0.1/> .\n"
turtle+="@prefix dh:	<https://www.w3.org/ns/ldt/document-hierarchy/domain#> .\n"
turtle+="@prefix sioc:	<http://rdfs.org/sioc/ns#> .\n"
turtle+="${template} a ns:Template .\n"
turtle+="${template} rdfs:label \"${label}\" .\n"
turtle+="${template} foaf:isPrimaryTopicOf _:item .\n"
turtle+="${template} rdfs:isDefinedBy <${is_defined_by}> .\n"
turtle+="_:item a ns:TemplateItem .\n"
turtle+="_:item sioc:has_container <${container}> .\n"
turtle+="_:item dct:title \"${label}\" .\n"
turtle+="_:item foaf:primaryTopic ${template} .\n"

if [ -n "$comment" ] ; then
    turtle+="${template} rdfs:comment \"${comment}\" .\n"
fi
if [ -n "$slug" ] ; then
    turtle+="_:item dh:slug \"${slug}\" .\n"
fi

if [ -n "$query" ] ; then
    turtle+="${template} ldt:query <${query}> .\n"
fi
if [ -n "$extends" ] ; then
    turtle+="${template} ldt:extends <${extends}> .\n"
fi
if [ -n "$match" ] ; then
    turtle+="${template} ldt:match \"${match}\" .\n"
fi
if [ -n "$load_class" ] ; then
    turtle+="${template} ldt:loadClass <${load_class}> .\n"
fi

for param in "${params[@]}"
do
    turtle+="${template} ldt:param <${param}> .\n"
done

# submit Turtle doc to the server
echo -e "$turtle" | turtle --base="$base" | ../../create-document.sh "${args[@]}"