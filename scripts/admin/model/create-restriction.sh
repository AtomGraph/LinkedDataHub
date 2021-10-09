#!/bin/bash

print_usage()
{
    printf "Creates an OWL restriction.\n"
    printf "\n"
    printf "Usage:  %s options [TARGET_URI]\n" "$0"
    printf "\n"
    printf "Options:\n"
    printf "  -f, --cert-pem-file CERT_FILE        .pem file with the WebID certificate of the agent\n"
    printf "  -p, --cert-password CERT_PASSWORD    Password of the WebID certificate\n"
    printf "  -b, --base BASE_URI                  Base URI of the admin application\n"
    printf "\n"
    printf "  --label LABEL                        Label of the restriction\n"
    printf "  --comment COMMENT                    Description of the restriction (optional)\n"
    printf "  --slug STRING                        String that will be used as URI path segment (optional)\n"
    printf "\n"
    printf "  --uri URI                            URI of the restriction (optional)\n"
    printf "  --on-property PROPERTY_URI           URI of the restricted property (optional)\n"
    printf "  --all-values-from URI                URI value of owl:allValuesFrom (optional)\n"
    printf "  --has-value URI                      URI value of owl:hasValue (optional)\n"
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
        --on-property)
        on_property="$2"
        shift # past argument
        shift # past value
        ;;
        --all-values-from)
        all_values_from="$2"
        shift # past argument
        shift # past value
        ;;
        --has-value)
        has_value="$2"
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

container="${base}model/restrictions/"

# allow explicit URIs
if [ -n "$uri" ] ; then
    restriction="<${uri}>" # URI
else
    restriction="_:restriction" # blank node
fi

if [ -z "$1" ]; then
    print_usage
    exit 1
fi

#if [ -z "$1" ]; then
#    args+=("${base}service") # default target URL = graph store
#fi

args+=("-f")
args+=("${cert_pem_file}")
args+=("-p")
args+=("${cert_password}")
args+=("-t")
args+=("text/turtle") # content type

turtle+="@prefix adm:	<https://w3id.org/atomgraph/linkeddatahub/admin#> .\n"
turtle+="@prefix rdfs:	<http://www.w3.org/2000/01/rdf-schema#> .\n"
turtle+="@prefix owl:	<http://www.w3.org/2002/07/owl#> .\n"
turtle+="@prefix ldt:	<https://www.w3.org/ns/ldt#> .\n"
turtle+="@prefix dct:	<http://purl.org/dc/terms/> .\n"
turtle+="@prefix foaf:	<http://xmlns.com/foaf/0.1/> .\n"
turtle+="@prefix spin:	<http://spinrdf.org/spin#> .\n"
turtle+="@prefix sioc:	<http://rdfs.org/sioc/ns#> .\n"
turtle+="${restriction} a adm:Restriction .\n"
turtle+="${restriction} rdfs:label \"${label}\" .\n"
turtle+="${restriction} foaf:isPrimaryTopicOf _:item .\n"
turtle+="${restriction} rdfs:isDefinedBy <model/ontologies/namespace/#> .\n"
turtle+="_:item a adm:Item .\n"
turtle+="_:item sioc:has_container <${container}> .\n"
turtle+="_:item dct:title \"${label}\" .\n"

if [ -n "$comment" ] ; then
    turtle+="${restriction} rdfs:comment \"${comment}\" .\n"
fi
if [ -n "$slug" ] ; then
    turtle+="@prefix dh:	<https://www.w3.org/ns/ldt/document-hierarchy/domain#> .\n"
    turtle+="_:item dh:slug \"${slug}\" .\n"
fi
if [ -n "$on_property" ] ; then
    turtle+="${restriction} owl:onProperty <$on_property> .\n"
fi
if [ -n "$all_values_from" ] ; then
    turtle+="${restriction} owl:allValuesFrom <$all_values_from> .\n"
fi
if [ -n "$has_value" ] ; then
    turtle+="${restriction} owl:hasValue <$has_value> .\n"
fi

# submit Turtle doc to the server
echo -e "$turtle" | turtle --base="$base" | ../../create-document.sh "${args[@]}"