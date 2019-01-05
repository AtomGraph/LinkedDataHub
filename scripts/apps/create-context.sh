#!/bin/bash
set -E
trap onexit ERR

function onexit() {
    local exit_status=${1:-$?}
    echo Exiting $0 with $exit_status
    exit $exit_status
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
    --slug)
    slug="$2"
    shift # past argument
    shift # past value
    ;;
    --admin-endpoint)
    admin_endpoint="$2"
    shift # past argument
    shift # past value
    ;;
    --admin-graph-store)
    admin_graph_store="$2"
    shift # past argument
    shift # past value
    ;;
    --admin-service-user)
    admin_service_user="$2"
    shift # past argument
    shift # past value
    ;;
    --admin-service-password)
    admin_service_password="$2"
    shift # past argument
    shift # past value
    ;;
    --end-user-endpoint)
    end_user_endpoint="$2"
    shift # past argument
    shift # past value
    ;;
    --end-user-graph-store)
    end_user_graph_store="$2"
    shift # past argument
    shift # past value
    ;;
    --end-user-service-user)
    end_user_service_user="$2"
    shift # past argument
    shift # past value
    ;;
    --end-user-service-password)
    end_user_service_password="$2"
    shift # past argument
    shift # past value
    ;;
    --app-base)
    app_base="$2"
    shift # past argument
    shift # past value
    ;;
    --public)
    public=true
    shift # past value
    ;;
    --logo)
    logo="$2"
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

args=()

if [ ! -z "$cert_pem_file" ] ; then
    args+=("-f")
    args+=("$cert_pem_file")
fi
if [ ! -z "$cert_password" ] ; then
    args+=("-p")
    args+=("$cert_password")
fi
if [ ! -z "$base" ] ; then
    args+=("-b")
    args+=("$base")
fi
if [ ! -z "$title" ] ; then
    args+=("--title")
    args+=("${title} admin")
fi
if [ ! -z "$slug" ] ; then
    args+=("--slug")
    args+=("${slug}-admin")
fi
if [ ! -z "$admin_endpoint" ] ; then
    args+=("--endpoint")
    args+=("$admin_endpoint")
fi
if [ ! -z "$admin_graph_store" ] ; then
    args+=("--graph-store")
    args+=("$admin_graph_store")
fi
if [ ! -z "$admin_service_user" ] ; then
    args+=("--service-user")
    args+=("$admin_service_user")
fi
if [ ! -z "$admin_service_password" ] ; then
    args+=("--service-password")
    args+=("$admin_service_password")
fi

admin_service_doc=$(./create-service.sh "${args[@]}")

args=()

if [ ! -z "$cert_pem_file" ] ; then
    args+=("-f")
    args+=("$cert_pem_file")
fi
if [ ! -z "$cert_password" ] ; then
    args+=("-p")
    args+=("$cert_password")
fi
if [ ! -z "$base" ] ; then
    args+=("-b")
    args+=("$base")
fi
if [ ! -z "$title" ] ; then
    args+=("--title")
    args+=("$title")
fi
if [ ! -z "$slug" ] ; then
    args+=("--slug")
    args+=("$slug")
fi
if [ ! -z "$end_user_endpoint" ] ; then
    args+=("--endpoint")
    args+=("$end_user_endpoint")
fi
if [ ! -z "$end_user_graph_store" ] ; then
    args+=("--graph-store")
    args+=("$end_user_repository")
fi
if [ ! -z "$end_user_service_user" ] ; then
    args+=("--service-user")
    args+=("$end_user_service_user")
fi
if [ ! -z "$end_user_service_password" ] ; then
    args+=("--service-password")
    args+=("$end_user_service_password")
fi

service_doc=$(./create-service.sh "${args[@]}")

args=()

args+=("--service")
args+=("${admin_service_doc}#this")

if [ ! -z "$cert_pem_file" ] ; then
    args+=("-f")
    args+=("$cert_pem_file")
fi
if [ ! -z "$cert_password" ] ; then
    args+=("-p")
    args+=("$cert_password")
fi
if [ ! -z "$base" ] ; then
    args+=("-b")
    args+=("$base")
fi
if [ ! -z "$title" ] ; then
    args+=("--title")
    args+=("$title")
fi
if [ ! -z "$slug" ] ; then
    args+=("--slug")
    args+=("$slug")
fi

admin_app_doc=$(./create-admin-app.sh "${args[@]}")

args=()

args+=("--service")
args+=("${service_doc}#this")
args+=("--admin-app")
args+=("${admin_app_doc}#this")

if [ ! -z "$cert_pem_file" ] ; then
    args+=("-f")
    args+=("$cert_pem_file")
fi
if [ ! -z "$cert_password" ] ; then
    args+=("-p")
    args+=("$cert_password")
fi
if [ ! -z "$base" ] ; then
    args+=("-b")
    args+=("$base")
fi
if [ ! -z "$title" ] ; then
    args+=("--title")
    args+=("$title")
fi
if [ ! -z "$slug" ] ; then
    args+=("--slug")
    args+=("$slug")
fi
if [ ! -z "$public" ] ; then
    args+=("--public")
fi
if [ ! -z "$logo" ] ; then
    args+=("--logo")
    args+=("$logo")
fi
if [ ! -z "$app_base" ] ; then
    args+=("--app-base")
    args+=("$app_base")
fi

end_user_app_doc=$(./create-context-app.sh "${args[@]}")