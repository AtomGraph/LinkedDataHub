#!/usr/bin/env bash

print_usage()
{
    printf "Creates an ontology class.\n"
    printf "\n"
    printf "Usage:  %s options [TARGET_URI]\n" "$0"
    printf "\n"
    printf "Options:\n"
    printf "  -f, --cert-pem-file CERT_FILE        .pem file with the WebID certificate of the agent\n"
    printf "  -p, --cert-password CERT_PASSWORD    Password of the WebID certificate\n"
    printf "  -b, --base BASE_URI                  Base URI of the admin application\n"
    printf "  --proxy PROXY_URL                    The host this request will be proxied through (optional)\n"
    printf "\n"
    printf "  --label LABEL                        Label of the class\n"
    printf "  --comment COMMENT                    Description of the class (optional)\n"
    printf "  --slug STRING                        String that will be used as URI path segment (optional)\n"
    printf "  --fragment STRING                    String that will be used as URI fragment identifier (optional)\n"
    printf "\n"
    printf "  --uri URI                            URI of the class (optional)\n"
    printf "  --constructor CONSTRUCT_URI          URI of the constructor CONSTRUCT query (optional)\n"
    printf "  --constraint CONSTRAINT_URI          URI of the SPIN constraint (optional)\n"
    printf "  --sub-class-of SUPER_CLASS_URI       URI of the superclass (optional)\n"

}

hash turtle 2>/dev/null || { echo >&2 "turtle not on \$PATH. Need to set \$JENA_HOME. Aborting."; exit 1; }

args=()
super_classes=() # --super-class-of can have multiple values, so we need an array
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
        --constructor)
        constructor="$2"
        shift # past argument
        shift # past value
        ;;
        --constraint)
        constraint="$2"
        shift # past argument
        shift # past value
        ;;
        --sub-class-of)
        super_classes+=("$2")
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

container="${base}model/classes/"

# allow explicit URIs
if [ -n "$uri" ] ; then
    class="<${uri}>" # URI
else
    class="_:class" # blank node
fi

if [ -z "$1" ]; then
    print_usage
    exit 1
fi

args+=("-f")
args+=("$cert_pem_file")
args+=("-p")
args+=("$cert_password")
args+=("-t")
args+=("text/turtle") # content type

turtle+="@prefix ldh:	<https://w3id.org/atomgraph/linkeddatahub#> .\n"
turtle+="@prefix dh:	<https://www.w3.org/ns/ldt/document-hierarchy#> .\n"
turtle+="@prefix owl:	<http://www.w3.org/2002/07/owl#> .\n"
turtle+="@prefix rdfs:	<http://www.w3.org/2000/01/rdf-schema#> .\n"
turtle+="@prefix ldt:	<https://www.w3.org/ns/ldt#> .\n"
turtle+="@prefix dct:	<http://purl.org/dc/terms/> .\n"
turtle+="@prefix foaf:	<http://xmlns.com/foaf/0.1/> .\n"
turtle+="@prefix spin:	<http://spinrdf.org/spin#> .\n"
turtle+="@prefix sioc:	<http://rdfs.org/sioc/ns#> .\n"
turtle+="${class} a owl:Class .\n"
turtle+="${class} rdfs:label \"${label}\" .\n"
turtle+="_:item a dh:Item .\n"
turtle+="_:item foaf:primaryTopic ${class} .\n"
turtle+="_:item sioc:has_container <${container}> .\n"
turtle+="_:item dct:title \"${label}\" .\n"

if [ -n "$comment" ] ; then
    turtle+="${class} rdfs:comment \"${comment}\" .\n"
fi
if [ -n "$slug" ] ; then
    turtle+="_:item dh:slug \"${slug}\" .\n"
fi
if [ -n "$fragment" ] ; then
    turtle+="${class} ldh:fragment \"${fragment}\" .\n"
fi
if [ -n "$constructor" ] ; then
    turtle+="${class} spin:constructor <$constructor> .\n"
fi
if [ -n "$constraint" ] ; then
    turtle+="${class} spin:constraint <$constraint> .\n"
fi

for sub_class_of in "${super_classes[@]}"
do
    turtle+="${class} rdfs:subClassOf <$sub_class_of> .\n"
done

# submit Turtle doc to the server
echo -e "$turtle" | turtle --base="$base" | ../../create-document.sh "${args[@]}"