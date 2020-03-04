#!/bin/bash

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
        --path)
        path="$2"
        shift # past argument
        shift # past value
        ;;
        --fragment)
        fragment="$2"
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
    echo '-f|--cert-pem-file not set'
    exit 1
fi
if [ -z "$cert_password" ] ; then
    echo '-p|--cert-password not set'
    exit 1
fi
if [ -z "$base" ] ; then
    echo '-b|--base not set'
    exit 1
fi
if [ -z "$label" ] ; then
    echo '--label not set'
    exit 1
fi

container="${base}model/classes/"

# if target URL is not provided, it equals container
if [ -z "$1" ] ; then
    args+=("${container}")
fi

# allow explicit URIs
if [ -n "$uri" ] ; then
    class="<${uri}>" # URI
else
    class="_:class" # blank node
fi

args+=("-f")
args+=("${cert_pem_file}")
args+=("-p")
args+=("${cert_password}")
args+=("-c")
args+=("${base}ns#Class") # class
args+=("-t")
args+=("text/turtle") # content type

turtle+="@prefix ns:	<ns#> .\n"
turtle+="@prefix rdfs:	<http://www.w3.org/2000/01/rdf-schema#> .\n"
turtle+="@prefix ldt:	<https://www.w3.org/ns/ldt#> .\n"
turtle+="@prefix dct:	<http://purl.org/dc/terms/> .\n"
turtle+="@prefix foaf:	<http://xmlns.com/foaf/0.1/> .\n"
turtle+="@prefix dh:	<https://www.w3.org/ns/ldt/document-hierarchy/domain#> .\n"
turtle+="@prefix spin:	<http://spinrdf.org/spin#> .\n"
turtle+="@prefix sioc:	<http://rdfs.org/sioc/ns#> .\n"
turtle+="${class} a ns:Class .\n"
turtle+="${class} rdfs:label \"${label}\" .\n"
turtle+="${class} foaf:isPrimaryTopicOf _:item .\n"
turtle+="${class} rdfs:isDefinedBy <../ns/domain#> .\n"
turtle+="_:item a ns:ClassItem .\n"
turtle+="_:item sioc:has_container <${container}> .\n"
turtle+="_:item dct:title \"${label}\" .\n"
turtle+="_:item foaf:primaryTopic ${class} .\n"

if [ -n "$comment" ] ; then
    turtle+="${class} rdfs:comment \"${comment}\" .\n"
fi
if [ -n "$slug" ] ; then
    turtle+="_:item dh:slug \"${slug}\" .\n"
fi
if [ -n "$constructor" ] ; then
    turtle+="${class} spin:constructor <$constructor> .\n"
fi
if [ -n "$constraint" ] ; then
    turtle+="${class} spin:constraint <$constraint> .\n"
fi
if [ -n "$path" ] ; then
    turtle+="${class} ldt:path \"${path}\" .\n"
fi
if [ -n "$fragment" ] ; then
    turtle+="${class} ldt:fragment \"${fragment}\" .\n"
fi

for sub_class_of in "${super_classes[@]}"
do
    turtle+="${class} rdfs:subClassOf <$sub_class_of> .\n"
done

# submit Turtle doc to the server
echo -e "$turtle" | turtle --base="$base" | ../../create-document.sh "${args[@]}"