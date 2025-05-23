#!/usr/bin/env bash
set -e

# set timezone

if [ -n "$TZ" ]; then
    export CATALINA_OPTS="$CATALINA_OPTS -Duser.timezone=$TZ -Dorg.apache.tomcat.util.buf.UDecoder.ALLOW_ENCODED_SLASH=true"
fi

# ln -snf /usr/share/zoneinfo/$TZ /etc/localtime
# echo $TZ > /etc/timezone

# change server configuration

if [ -n "$HTTP" ]; then
    HTTP_PARAM="--stringparam http $HTTP "
fi

if [ -n "$HTTP_SCHEME" ]; then
    HTTP_SCHEME_PARAM="--stringparam http.scheme $HTTP_SCHEME "
fi

if [ -n "$HTTP_PORT" ]; then
    HTTP_PORT_PARAM="--stringparam http.port $HTTP_PORT "
fi

if [ -n "$HTTP_PROXY_NAME" ]; then
    lc_proxy_name=$(echo "$HTTP_PROXY_NAME" | tr '[:upper:]' '[:lower:]') # make sure it's lower-case
    HTTP_PROXY_NAME_PARAM="--stringparam http.proxyName $lc_proxy_name "
fi

if [ -n "$HTTP_PROXY_PORT" ]; then
    HTTP_PROXY_PORT_PARAM="--stringparam http.proxyPort $HTTP_PROXY_PORT "
fi

if [ -n "$HTTP_REDIRECT_PORT" ]; then
    HTTP_REDIRECT_PORT_PARAM="--stringparam http.redirectPort $HTTP_REDIRECT_PORT "
fi

if [ -n "$HTTP_CONNECTION_TIMEOUT" ]; then
    HTTP_CONNECTION_TIMEOUT_PARAM="--stringparam http.connectionTimeout $HTTP_CONNECTION_TIMEOUT "
fi

if [ -n "$HTTP_COMPRESSION" ]; then
    HTTP_COMPRESSION_PARAM="--stringparam http.compression $HTTP_COMPRESSION "
fi

if [ -n "$HTTPS" ]; then
    HTTPS_PARAM="--stringparam https $HTTPS "
fi

transform="xsltproc \
  --output conf/server.xml \
  $HTTP_PARAM \
  $HTTP_SCHEME_PARAM \
  $HTTP_PORT_PARAM \
  $HTTP_PROXY_NAME_PARAM \
  $HTTP_PROXY_PORT_PARAM \
  $HTTP_REDIRECT_PORT_PARAM \
  $HTTP_CONNECTION_TIMEOUT_PARAM \
  $HTTP_COMPRESSION_PARAM \
  $HTTPS_PARAM \
  conf/letsencrypt-tomcat.xsl \
  conf/server.xml"

eval "$transform"

### PLATFORM ###

# check mandatory environmental variables (which are used in conf/ROOT.xml)

if [ -z "$TIMEOUT" ]; then
    echo '$TIMEOUT not set'
    exit 1
fi

if [ -z "$PROTOCOL" ]; then
    echo '$PROTOCOL not set'
    exit 1
fi

if [ -z "$HTTP_PROXY_PORT" ]; then
    echo '$HTTP_PROXY_PORT not set'
    exit 1
fi

if [ -z "$HTTPS_PROXY_PORT" ]; then
    echo '$HTTPS_PROXY_PORT not set'
    exit 1
fi

if [ -z "$HOST" ]; then
    echo '$HOST not set'
    exit 1
fi

if [ -z "$ABS_PATH" ]; then
    echo '$ABS_PATH not set'
    exit 1
fi

if [ -z "$OWNER_MBOX" ]; then
    echo '$OWNER_MBOX not set'
    exit 1
fi

if [ -z "$OWNER_GIVEN_NAME" ]; then
    echo '$OWNER_GIVEN_NAME not set'
    exit 1
fi

if [ -z "$OWNER_FAMILY_NAME" ]; then
    echo '$OWNER_FAMILY_NAME not set'
    exit 1
fi

if [ -z "$OWNER_PUBLIC_KEY" ]; then
    echo '$OWNER_PUBLIC_KEY not set'
    exit 1
fi

if [ -z "$CLIENT_KEYSTORE" ]; then
    echo '$CLIENT_KEYSTORE not set'
    exit 1
fi

if [ -z "$CLIENT_KEYSTORE_MOUNT" ]; then
    echo '$CLIENT_KEYSTORE_MOUNT not set'
    exit 1
fi

if [ -z "$SECRETARY_CERT_ALIAS" ]; then
    echo '$SECRETARY_CERT_ALIAS not set'
    exit 1
fi

if [ -z "$SECRETARY_COMMON_NAME" ]; then
    echo '$SECRETARY_COMMON_NAME not set'
    exit 1
fi

if [ -z "$CLIENT_TRUSTSTORE" ]; then
    echo '$CLIENT_TRUSTSTORE not set'
    exit 1
fi

if [ -z "$UPLOAD_ROOT" ]; then
    echo '$UPLOAD_ROOT not set'
    exit 1
fi

if [ -z "$SIGN_UP_CERT_VALIDITY" ]; then
    echo '$SIGN_UP_CERT_VALIDITY not set'
    exit 1
fi

if [ -z "$CONTEXT_DATASET_URL" ]; then
    echo '$CONTEXT_DATASET_URL not set'
    exit 1
fi

if [ -z "$END_USER_DATASET_URL" ]; then
    echo '$END_USER_DATASET_URL not set'
    exit 1
fi

if [ -z "$ADMIN_DATASET_URL" ]; then
    echo '$ADMIN_DATASET_URL not set'
    exit 1
fi

if [ -z "$MAIL_SMTP_HOST" ]; then
    echo '$MAIL_SMTP_HOST not set'
    exit 1
fi

if [ -z "$MAIL_SMTP_PORT" ]; then
    echo '$MAIL_SMTP_PORT not set'
    exit 1
fi

if [ -z "$MAIL_USER" ]; then
    echo '$MAIL_USER not set'
    exit 1
fi

# construct base URI (ignore default HTTP and HTTPS ports)

if [ "$PROTOCOL" = "https" ]; then
    if [ "$HTTPS_PROXY_PORT" = 443 ]; then
        export BASE_URI="${PROTOCOL}://${HOST}${ABS_PATH}"
    else
        export BASE_URI="${PROTOCOL}://${HOST}:${HTTPS_PROXY_PORT}${ABS_PATH}"
    fi
else
    if [ "$HTTP_PROXY_PORT" = 80 ]; then
        export BASE_URI="${PROTOCOL}://${HOST}${ABS_PATH}"
    else
        export BASE_URI="${PROTOCOL}://${HOST}:${HTTP_PROXY_PORT}${ABS_PATH}"
    fi
fi

BASE_URI=$(echo "$BASE_URI" | tr '[:upper:]' '[:lower:]') # make sure it's lower-case

printf "\n### Base URI: %s\n" "$BASE_URI"

# functions that wait for other services to start

wait_for_host()
{
    local host="$1"
    local counter="$2"
    i=1

    while [ "$i" -le "$counter" ] && ! ping -c1 "$host" >/dev/null 2>&1
    do
        sleep 1 ;
        i=$(( i+1 ))
    done

    if ! ping -c1 "$host" >/dev/null 2>&1 ; then
        printf "\n### Host %s not responding after ${counter} retries, exiting..." "$host"
        exit 1
    else
        printf "\n### Host %s responded\n" "$host"
    fi
}

wait_for_url()
{
    local url="$1"
    local auth_user="$2"
    local auth_pwd="$3"
    local counter="$4"
    local accept="$5"
    i=1

    # use HTTP Basic auth if username/password are provided
    if [ -n "$auth_user" ] && [ -n "$auth_pwd" ]; then
        while [ "$i" -le "$counter" ] && ! curl -s -f -X OPTIONS "$url" --user "$auth_user":"$auth_pwd" -H "Accept: ${accept}" >/dev/null 2>&1
        do
            sleep 1 ;
            i=$(( i+1 ))
        done

        if ! curl -s -f -X OPTIONS "$url" --user "$auth_user":"$auth_pwd" -H "Accept: ${accept}" >/dev/null 2>&1 ; then
            printf "\n### URL %s not responding after %s retries, exiting...\n" "$url" "$counter"
            exit 1
        else
            printf "\n### URL %s responded\n" "$url"
        fi
    else
        while [ "$i" -le "$counter" ] && ! curl -s -f -X OPTIONS "$url" -H "Accept: ${accept}"
        do
            sleep 1 ;
            i=$(( i+1 ))
        done

        if ! curl -s -f -X OPTIONS "$url" -H "Accept: ${accept}" >/dev/null 2>&1 ; then
            printf "\n### URL %s not responding after %s retries, exiting...\n" "$url" "$counter"
            exit 1
        else
            printf "\n### URL %s responded\n" "$url"
        fi
    fi
}

# function to append quad data to an RDF graph store

append_quads()
{
    local quad_store_url="$1"
    local auth_user="$2"
    local auth_pwd="$3"
    local filename="$4"
    local content_type="$5"

    # use HTTP Basic auth if username/password are provided
    if [ -n "$auth_user" ] && [ -n "$auth_pwd" ]; then
        curl \
            -f \
            --basic \
            --user "$auth_user":"$auth_pwd" \
            "$quad_store_url" \
            -H "Content-Type: ${content_type}" \
            --data-binary @"$filename"
    else
        curl \
            -f \
            "$quad_store_url" \
            -H "Content-Type: ${content_type}" \
            --data-binary @"$filename"
    fi
}

generate_cert()
{
    local alias="$1"
    local webid_uri="$2"
    local common_name="$3"
    local org_unit="${4:-}"
    local organization="${5:-}"
    local locality="${6:-}"
    local state_or_province="${7:-}"
    local country_name="${8:-}"
    local validity_days="${9}"
    local keystore_output="${10}"
    local keystore_password="${11}"
    local cert_output="${12}"
    local public_key_output="${13}"
    local private_key_output="${14}"

    # Build the Distinguished Name (DN) string, only including components if they're non-empty
    dname="CN=${common_name}"
    [ -n "$organization" ] && dname="$dname,O=${organization}"
    [ -n "$org_unit" ] && dname="$dname,OU=${org_unit}"
    [ -n "$locality" ] && dname="$dname,L=${locality}"
    [ -n "$state_or_province" ] && dname="$dname,ST=${state_or_province}"
    [ -n "$country_name" ] && dname="$dname,C=${country_name}"

    mkdir -p "$(dirname "$keystore_output")"
 
    # Generate keystore using keytool with the specified alias
    keytool -genkeypair \
        -alias "$alias" \
        -keyalg RSA \
        -storetype PKCS12 \
        -keystore "$keystore_output" \
        -storepass "$keystore_password" \
        -keypass "$keystore_password" \
        -dname "$dname" \
        -ext "SAN=uri:${webid_uri}" \
        -validity "$validity_days"

    if [ -n "$cert_output" ]; then
        mkdir -p "$(dirname "$cert_output")"

        # Convert keystore to PEM certificate
        openssl pkcs12 -in "$keystore_output" \
            -passin pass:"$keystore_password" \
            -out "$cert_output" \
            -passout pass:"$keystore_password" \
            -clcerts
    fi

    if [ -n "$public_key_output" ]; then
        # Extract public key from the certificate
        openssl x509 -in "$cert_output" -pubkey -noout > "$public_key_output"
    fi
}

get_modulus()
{
    local key_pem="$1"
    modulus_string=$(openssl rsa -pubin -in "$key_pem" -modulus -noout)
    modulus="${modulus_string##*Modulus=}"  # cut the 'Modulus=' part
    echo "$modulus" | tr '[:upper:]' '[:lower:]'  # lowercase the modulus
}

OWNER_UUID=$(uuidgen | tr '[:upper:]' '[:lower:]') # lowercase
OWNER_URI="${OWNER_URI:-${BASE_URI}admin/acl/agents/${OWNER_UUID}/#this}" # WebID URI. Can be external!
OWNER_COMMON_NAME="$OWNER_GIVEN_NAME $OWNER_FAMILY_NAME" # those are required

SECRETARY_UUID=$(uuidgen | tr '[:upper:]' '[:lower:]') # lowercase
SECRETARY_URI="${SECRETARY_URI:-${BASE_URI}admin/acl/agents/${SECRETARY_UUID}/#this}" # WebID URI. Can be external!

OWNER_DATASET_PATH="/var/linkeddatahub/datasets/owner/${OWNER_CERT_ALIAS}.trig"

printf "\n### Owner's WebID URI: %s\n" "$OWNER_URI"

# generate owner's keystore, cert, and public key if the public key does not exist
# store owner's metadata in an RDF dataset
if [ ! -f "$OWNER_PUBLIC_KEY" ]; then
    printf "\n### Generating owner's certificates and public key since they're not provided\n"

    if [ ! -f "/run/secrets/owner_cert_password" ]; then
        echo "'owner_cert_password' secret is missing"
        exit 1
    fi

    OWNER_CERT_PASSWORD=$(cat /run/secrets/owner_cert_password)

    generate_cert "$OWNER_CERT_ALIAS" "$OWNER_URI" \
                  "$OWNER_GIVEN_NAME $OWNER_FAMILY_NAME" \
                  "$OWNER_ORG_UNIT" "$OWNER_ORGANIZATION" \
                  "$OWNER_LOCALITY" "$OWNER_STATE_OR_PROVINCE" "$OWNER_COUNTRY_NAME" \
                  "$CERT_VALIDITY" "$OWNER_KEYSTORE" "$OWNER_CERT_PASSWORD" \
                  "$OWNER_CERT" "$OWNER_PUBLIC_KEY" "$OWNER_PRIVATE_KEY"

    # write owner's metadata to a file

    mkdir -p "$(dirname "$OWNER_DATASET_PATH")"

    OWNER_DOC_URI="${BASE_URI}admin/acl/agents/${OWNER_UUID}/"
    OWNER_KEY_UUID=$(uuidgen | tr '[:upper:]' '[:lower:]') # lowercase
    OWNER_PUBLIC_KEY_MODULUS=$(get_modulus "$OWNER_PUBLIC_KEY")

    printf "\n### Root owner WebID public key modulus: %s\n" "$OWNER_PUBLIC_KEY_MODULUS"

    export OWNER_COMMON_NAME OWNER_URI OWNER_DOC_URI OWNER_PUBLIC_KEY_MODULUS OWNER_KEY_UUID SECRETARY_URI
    envsubst < root-owner.trig.template > "$OWNER_DATASET_PATH"
fi

SECRETARY_DATASET_PATH="/var/linkeddatahub/datasets/secretary/${SECRETARY_CERT_ALIAS}.trig"

printf "\n### Secretary's WebID URI: %s\n" "$SECRETARY_URI"

# generate secretary's keystore,  cert, and public key if the public key does not exist
# store secretary's metadata in an RDF dataset
if [ ! -f "$SECRETARY_PUBLIC_KEY" ]; then
    printf "\n### Generating secretary's certificates and public key since they're not provided\n"

    if [ ! -f "/run/secrets/secretary_cert_password" ]; then
        echo "'secretary_cert_password' secret is missing"
        exit 1
    fi

    SECRETARY_CERT_PASSWORD=$(cat /run/secrets/secretary_cert_password)

    generate_cert "$SECRETARY_CERT_ALIAS" "$SECRETARY_URI" \
                  "$SECRETARY_COMMON_NAME" \
                  "" "" \
                  "" "" "" \
                  "$CERT_VALIDITY" "$SECRETARY_KEYSTORE" "$SECRETARY_CERT_PASSWORD" \
                  "$SECRETARY_CERT" "$SECRETARY_PUBLIC_KEY" "$SECRETARY_PRIVATE_KEY"

    # write secretary's metadata to a file

    mkdir -p "$(dirname "$SECRETARY_DATASET_PATH")"

    SECRETARY_DOC_URI="${BASE_URI}admin/acl/agents/${SECRETARY_UUID}/"
    SECRETARY_KEY_UUID=$(uuidgen | tr '[:upper:]' '[:lower:]') # lowercase
    SECRETARY_PUBLIC_KEY_MODULUS=$(get_modulus "$SECRETARY_PUBLIC_KEY")

    printf "\n### Secretary WebID public key modulus: %s\n" "$SECRETARY_PUBLIC_KEY_MODULUS"

    export SECRETARY_URI SECRETARY_DOC_URI SECRETARY_PUBLIC_KEY_MODULUS SECRETARY_KEY_UUID
    envsubst < root-secretary.trig.template > "$SECRETARY_DATASET_PATH"
fi

if [ -z "$LOAD_DATASETS" ]; then
    if [ ! -d /var/linkeddatahub/based-datasets ]; then
        LOAD_DATASETS=true
    else
        LOAD_DATASETS=false
    fi
fi

# base the $CONTEXT_DATASET

webapp_context_dataset="/WEB-INF/classes/com/atomgraph/linkeddatahub/system.nq"
based_context_dataset="${PWD}/webapps/ROOT${webapp_context_dataset}"

case "$CONTEXT_DATASET_URL" in
    "file://"*)
        CONTEXT_DATASET=$(echo "$CONTEXT_DATASET_URL" | cut -c 8-) # strip leading file://

        printf "\n### Reading context dataset from a local file: %s\n" "$CONTEXT_DATASET" ;;
    *)  
        CONTEXT_DATASET=$(mktemp)

        printf "\n### Downloading context dataset from a URL: %s\n" "$CONTEXT_DATASET_URL"

        curl "$CONTEXT_DATASET_URL" > "$CONTEXT_DATASET" ;;
esac

trig --base="$BASE_URI" "$CONTEXT_DATASET" > "$based_context_dataset"

sparql --data="$based_context_dataset" --query="select-root-services.rq" --results=XML > root_service_metadata.xml

# extract app metadata from the system dataset using SPARQL and XPath queries

readarray apps < <(xmlstarlet sel -B \
    -N srx="http://www.w3.org/2005/sparql-results#" \
    -T -t -m "/srx:sparql/srx:results/srx:result" \
    -o "\"" \
    -v "srx:binding[@name = 'endUserApp']" \
    -o "\" \"" \
    -v "srx:binding[@name = 'endUserBase']" \
    -o "\" \"" \
    -v "srx:binding[@name = 'endUserQuadStore']" \
    -o "\" \"" \
    -v "srx:binding[@name = 'endUserEndpoint']" \
    -o "\" \"" \
    -v "srx:binding[@name = 'endUserAuthUser']" \
    -o "\" \"" \
    -v "srx:binding[@name = 'endUserAuthPwd']" \
    -o "\" \"" \
    -v "srx:binding[@name = 'endUserMaker']" \
    -o "\" \"" \
    -v "srx:binding[@name = 'adminApp']" \
    -o "\" \"" \
    -v "srx:binding[@name = 'adminBase']" \
    -o "\" \"" \
    -v "srx:binding[@name = 'adminQuadStore']" \
    -o "\" \"" \
    -v "srx:binding[@name = 'adminEndpoint']" \
    -o "\" \"" \
    -v "srx:binding[@name = 'adminAuthUser']" \
    -o "\" \"" \
    -v "srx:binding[@name = 'adminAuthPwd']" \
    -o "\" \"" \
    -v "srx:binding[@name = 'adminMaker']" \
    -o "\"" \
    -n \
    root_service_metadata.xml)

for app in "${apps[@]}"; do
    app_array=(${app})
    end_user_app="${app_array[0]//\"/}"
    end_user_base_uri="${app_array[1]//\"/}"
    end_user_quad_store_url="${app_array[2]//\"/}"
    end_user_endpoint_url="${app_array[3]//\"/}"
    end_user_service_auth_user="${app_array[4]//\"/}"
    end_user_service_auth_pwd="${app_array[5]//\"/}"
    end_user_owner="${app_array[6]//\"/}"
    admin_app="${app_array[7]//\"/}"
    admin_base_uri="${app_array[8]//\"/}"
    admin_quad_store_url="${app_array[9]//\"/}"
    admin_endpoint_url="${app_array[10]//\"/}"
    admin_service_auth_user="${app_array[11]//\"/}"
    admin_service_auth_pwd="${app_array[12]//\"/}"
    admin_owner="${app_array[13]//\"/}"

    printf "\n### Processing dataspace. End-user app: %s Admin app: %s\n" "$end_user_app" "$admin_app"

    if [ -z "$end_user_app" ]; then
        printf "\nEnd-user app URI could not be extracted from %s. Exiting...\n" "$CONTEXT_DATASET"
        exit 1
    fi
    if [ -z "$end_user_quad_store_url" ]; then
        printf "\nEnd-user quad store URL could not be extracted for the <%s> app. Exiting...\n" "$end_user_app"
        exit 1
    fi
    if [ -z "$admin_app" ]; then
        printf "\nAdmin app URI could not be extracted for the <%s> app. Exiting...\n" "$end_user_app"
        exit 1
    fi
    if [ -z "$admin_base_uri" ]; then
        printf "\nAdmin base URI extracted for the <%s> app. Exiting...\n" "$end_user_app"
        exit 1
    fi
    if [ -z "$admin_quad_store_url" ]; then
        printf "\nAdmin quad store URL could not be extracted for the <%s> app. Exiting...\n" "$end_user_app"
        exit 1
    fi

    # check if this app is the root app
    if [ "$end_user_base_uri" = "$BASE_URI" ]; then
        root_end_user_app="$end_user_app"
        root_end_user_quad_store_url="$end_user_quad_store_url"
        root_end_user_service_auth_user="$end_user_service_auth_user"
        root_end_user_service_auth_pwd="$end_user_service_auth_pwd"
        root_admin_app="$admin_app"
        root_admin_quad_store_url="$admin_quad_store_url"
        root_admin_service_auth_user="$admin_service_auth_user"
        root_admin_service_auth_pwd="$admin_service_auth_pwd"
    fi

    # append ownership metadata to apps if it's not present (apps have to be URI resources!)

    if [ -z "$end_user_owner" ]; then
        echo "<${end_user_app}> <http://xmlns.com/foaf/0.1/maker> <${OWNER_URI}> ." >> "$based_context_dataset"
    fi
    if [ -z "$admin_owner" ]; then
        echo "<${admin_app}> <http://xmlns.com/foaf/0.1/maker> <${OWNER_URI}> ." >> "$based_context_dataset"
    fi

    printf "\n### Quad store URL of the root end-user service: %s\n" "$end_user_quad_store_url"
    printf "\n### Quad store URL of the root admin service: %s\n" "$admin_quad_store_url"

    # load default admin/end-user datasets if we haven't yet created a folder with re-based versions of them (and then create it)
    if [ "$LOAD_DATASETS" = "true" ]; then
        mkdir -p /var/linkeddatahub/based-datasets

        # create query file by injecting environmental variables into the template

        case "$END_USER_DATASET_URL" in
            "file://"*)
                END_USER_DATASET=$(echo "$END_USER_DATASET_URL" | cut -c 8-) # strip leading file://

                printf "\n### Reading end-user dataset from a local file: %s\n" "$END_USER_DATASET" ;;
            *)  
                END_USER_DATASET=$(mktemp)

                printf "\n### Downloading end-user dataset from a URL: %s\n" "$END_USER_DATASET_URL"

                curl "$END_USER_DATASET_URL" > "$END_USER_DATASET" ;;
        esac

        case "$ADMIN_DATASET_URL" in
            "file://"*)
                ADMIN_DATASET=$(echo "$ADMIN_DATASET_URL" | cut -c 8-) # strip leading file://

                printf "\n### Reading admin dataset from a local file: %s\n" "$ADMIN_DATASET" ;;
            *)  
                ADMIN_DATASET=$(mktemp)

                printf "\n### Downloading admin dataset from a URL: %s\n" "$ADMIN_DATASET_URL"

                curl "$ADMIN_DATASET_URL" > "$ADMIN_DATASET" ;;
        esac

        trig --base="$end_user_base_uri" "$END_USER_DATASET" > /var/linkeddatahub/based-datasets/end-user.nq

        printf "\n### Waiting for %s...\n" "$end_user_quad_store_url"
        wait_for_url "$end_user_quad_store_url" "$end_user_service_auth_user" "$end_user_service_auth_pwd" "$TIMEOUT" "application/n-quads"

        printf "\n### Loading end-user dataset into the triplestore...\n"
        append_quads "$end_user_quad_store_url" "$end_user_service_auth_user" "$end_user_service_auth_pwd" /var/linkeddatahub/based-datasets/end-user.nq "application/n-quads"

        trig --base="$admin_base_uri" "$ADMIN_DATASET" > /var/linkeddatahub/based-datasets/admin.nq

        printf "\n### Waiting for %s...\n" "$admin_quad_store_url"
        wait_for_url "$admin_quad_store_url" "$admin_service_auth_user" "$admin_service_auth_pwd" "$TIMEOUT" "application/n-quads"

        printf "\n### Loading admin dataset into the triplestore...\n"
        append_quads "$admin_quad_store_url" "$admin_service_auth_user" "$admin_service_auth_pwd" /var/linkeddatahub/based-datasets/admin.nq "application/n-quads"

        trig --base="$admin_base_uri" --output=nq "$OWNER_DATASET_PATH" > /var/linkeddatahub/based-datasets/root-owner.nq

        printf "\n### Uploading the metadata of the owner agent...\n\n"
        append_quads "$admin_quad_store_url" "$admin_service_auth_user" "$admin_service_auth_pwd" /var/linkeddatahub/based-datasets/root-owner.nq "application/n-quads"

        trig --base="$admin_base_uri" --output=nq "$SECRETARY_DATASET_PATH" > /var/linkeddatahub/based-datasets/root-secretary.nq

        printf "\n### Uploading the metadata of the secretary agent...\n\n"
        append_quads "$admin_quad_store_url" "$admin_service_auth_user" "$admin_service_auth_pwd" /var/linkeddatahub/based-datasets/root-secretary.nq "application/n-quads"
    fi
done

rm -f root_service_metadata.xml

if [ -z "$root_end_user_app" ]; then
    printf "\nRoot end-user app with base URI <%s> not found. Exiting...\n" "$BASE_URI"
    exit 1
fi
if [ -z "$root_admin_app" ]; then
    printf "\nRoot admin app (for end-user app with base URI <%s>) not found. Exiting...\n" "$BASE_URI"
    exit 1
fi

# copy mounted client keystore to a location where the webapp can access it

mkdir -p "$(dirname "$CLIENT_KEYSTORE")"

cp -f "$CLIENT_KEYSTORE_MOUNT" "$(dirname "$CLIENT_KEYSTORE")"

# set passwords from secrets

if [ ! -f "/run/secrets/secretary_cert_password" ]; then
    echo "'secretary_cert_password' secret is missing"
    exit 1
fi
if [ ! -f "/run/secrets/client_truststore_password" ]; then
    echo "'client_truststore_password' secret is missing"
    exit 1
fi

CLIENT_KEYSTORE_PASSWORD=$(cat /run/secrets/secretary_cert_password)
CLIENT_TRUSTSTORE_PASSWORD=$(cat /run/secrets/client_truststore_password)

# if CLIENT_TRUSTSTORE does not exist:
# 1. import the certificate into the CLIENT_TRUSTSTORE
# 2. initialize an Agent/PublicKey with secretary's metadata and key modulus
# 3. import the secretary metadata metadata into the quad store

if [ ! -f "$CLIENT_TRUSTSTORE" ]; then
    # if server certificate is self-signed, import it into client truststore

    if [ "$SELF_SIGNED_CERT" = true ]; then
        printf "\n### Importing server certificate into the client truststore\n\n"

        mkdir -p "$(dirname "$CLIENT_TRUSTSTORE")"

        keytool -importcert \
            -alias "$SECRETARY_CERT_ALIAS" \
            -file "$SERVER_CERT" \
            -keystore "$CLIENT_TRUSTSTORE" \
            -noprompt \
            -storepass "$CLIENT_TRUSTSTORE_PASSWORD" \
            -storetype PKCS12 \
            -trustcacerts
    fi

    export CACERTS="${JAVA_HOME}/lib/security/cacerts"

    printf "\n### Importing default CA certificates into the client truststore\n\n"
 
    keytool -importkeystore \
        -destkeystore "$CLIENT_TRUSTSTORE" \
        -deststorepass "$CLIENT_TRUSTSTORE_PASSWORD" \
        -deststoretype PKCS12 \
        -noprompt \
        -srckeystore "$CACERTS" \
        -srcstorepass changeit
fi

# create empty properties file if it doesn't exist

if [ -n "$OIDC_REFRESH_TOKENS" ] && [ ! -f "$OIDC_REFRESH_TOKENS" ]; then
    mkdir -p "$(dirname "$OIDC_REFRESH_TOKENS")"

    touch "$OIDC_REFRESH_TOKENS"
fi

# if configured, generate XML sitemap: https://www.sitemaps.org/protocol.html

if [ "$GENERATE_SITEMAP" = true ]; then
    export admin_endpoint_url
    envsubst < /var/linkeddatahub/sitemap/sitemap.rq.template > /var/linkeddatahub/sitemap/sitemap.rq
    sitemap_results=$(mktemp)

    curl -k -G -H "Accept: application/sparql-results+xml" "$end_user_endpoint_url" --data-urlencode "query@/var/linkeddatahub/sitemap/sitemap.rq" -o "$sitemap_results"

    xsltproc --output "${PWD}/webapps/ROOT/sitemap.xml" /var/linkeddatahub/sitemap/sitemap.xsl "$sitemap_results"

    rm "$sitemap_results"
fi

# change context configuration

BASE_URI_PARAM="--stringparam ldhc:baseUri '$BASE_URI' "
CLIENT_KEYSTORE_PARAM="--stringparam ldhc:clientKeyStore 'file://$CLIENT_KEYSTORE' "
SECRETARY_CERT_ALIAS_PARAM="--stringparam ldhc:secretaryCertAlias '$SECRETARY_CERT_ALIAS' "
CLIENT_TRUSTSTORE_PARAM="--stringparam ldhc:clientTrustStore 'file://$CLIENT_TRUSTSTORE' "
CLIENT_KEYSTORE_PASSWORD_PARAM="--stringparam ldhc:clientKeyStorePassword '$CLIENT_KEYSTORE_PASSWORD' "
CLIENT_TRUSTSTORE_PASSWORD_PARAM="--stringparam ldhc:clientTrustStorePassword '$CLIENT_TRUSTSTORE_PASSWORD' "
UPLOAD_ROOT_PARAM="--stringparam ldhc:uploadRoot 'file://$UPLOAD_ROOT' "
SIGN_UP_CERT_VALIDITY_PARAM="--stringparam ldhc:signUpCertValidity '$SIGN_UP_CERT_VALIDITY' "
CONTEXT_DATASET_PARAM="--stringparam ldhc:contextDataset '$webapp_context_dataset' "
MAIL_SMTP_HOST_PARAM="--stringparam mail.smtp.host '$MAIL_SMTP_HOST' "
MAIL_SMTP_PORT_PARAM="--stringparam mail.smtp.port '$MAIL_SMTP_PORT' "
MAIL_USER_PARAM="--stringparam mail.user '$MAIL_USER' "

if [ -n "$PROXY_SCHEME" ]; then
    PROXY_SCHEME_PARAM="--stringparam ldhc:proxyScheme '$PROXY_SCHEME' "
fi

if [ -n "$PROXY_HOST" ]; then
    PROXY_HOST_PARAM="--stringparam ldhc:proxyHost '$PROXY_HOST' "
fi

if [ -n "$PROXY_PORT" ]; then
    PROXY_PORT_PARAM="--stringparam ldhc:proxyPort '$PROXY_PORT' "
fi

if [ -n "$CACHE_MODEL_LOADS" ]; then
    CACHE_MODEL_LOADS_PARAM="--stringparam a:cacheModelLoads '$CACHE_MODEL_LOADS' "
fi

# stylesheet URL must be relative to the base context URL
if [ -n "$STYLESHEET" ]; then
    STYLESHEET_PARAM="--stringparam ac:stylesheet '$STYLESHEET' "
fi

if [ -n "$CACHE_STYLESHEET" ]; then
    CACHE_STYLESHEET_PARAM="--stringparam ac:cacheStylesheet '$CACHE_STYLESHEET' "
fi

if [ -n "$RESOLVING_UNCACHED" ]; then
    RESOLVING_UNCACHED_PARAM="--stringparam ac:resolvingUncached '$RESOLVING_UNCACHED' "
fi

if [ -n "$AUTH_QUERY" ]; then
    AUTH_QUERY_PARAM="--stringparam ldhc:authQuery '$AUTH_QUERY' "
fi

if [ -n "$OWNER_AUTH_QUERY" ]; then
    OWNER_AUTH_QUERY_PARAM="--stringparam ldhc:ownerAuthQuery '$OWNER_AUTH_QUERY' "
fi

if [ -n "$ENABLE_LINKED_DATA_PROXY" ]; then
    ENABLE_LINKED_DATA_PROXY_PARAM="--stringparam ldhc:enableLinkedDataProxy '$ENABLE_LINKED_DATA_PROXY' "
fi

if [ -n "$MAX_CONTENT_LENGTH" ]; then
    MAX_CONTENT_LENGTH_PARAM="--stringparam ldhc:maxContentLength '$MAX_CONTENT_LENGTH' "
fi

if [ -n "$MAX_CONN_PER_ROUTE" ]; then
    MAX_CONN_PER_ROUTE_PARAM="--stringparam ldhc:maxConnPerRoute '$MAX_CONN_PER_ROUTE' "
fi

if [ -n "$MAX_TOTAL_CONN" ]; then
    MAX_TOTAL_CONN_PARAM="--stringparam ldhc:maxTotalConn '$MAX_TOTAL_CONN' "
fi

if [ -n "$MAX_REQUEST_RETRIES" ]; then
    MAX_REQUEST_RETRIES_PARAM="--stringparam ldhc:maxRequestRetries '$MAX_REQUEST_RETRIES' "
fi

if [ -n "$MAX_IMPORT_THREADS" ]; then
    MAX_IMPORT_THREADS_PARAM="--stringparam ldhc:maxImportThreads '$MAX_IMPORT_THREADS' "
fi

if [ -n "$NOTIFICATION_ADDRESS" ]; then
    NOTIFICATION_ADDRESS_PARAM="--stringparam ldhc:notificationAddress '$NOTIFICATION_ADDRESS' "
fi

if [ -n "$ENABLE_WEBID_SIGNUP" ]; then
    ENABLE_WEBID_SIGNUP_PARAM="--stringparam ldhc:enableWebIDSignUp '$ENABLE_WEBID_SIGNUP' "
fi

if [ -n "$OIDC_REFRESH_TOKENS" ]; then
    OIDC_REFRESH_TOKENS_PARAM="--stringparam ldhc:oidcRefreshTokens '$OIDC_REFRESH_TOKENS' "
fi

if [ -n "$MAIL_PASSWORD" ]; then
    MAIL_PASSWORD_PARAM="--stringparam mail.password '$MAIL_PASSWORD' "
fi

if [ -f "/run/secrets/google_client_id" ]; then
    GOOGLE_CLIENT_ID=$(cat /run/secrets/google_client_id)
    GOOGLE_CLIENT_ID_PARAM="--stringparam google:clientID '$GOOGLE_CLIENT_ID' "
fi

if [ -f "/run/secrets/google_client_secret" ]; then
    GOOGLE_CLIENT_SECRET=$(cat /run/secrets/google_client_secret)
    GOOGLE_CLIENT_SECRET_PARAM="--stringparam google:clientSecret '$GOOGLE_CLIENT_SECRET' "
fi

transform="xsltproc \
  --output conf/Catalina/localhost/ROOT.xml \
  $CACHE_MODEL_LOADS_PARAM \
  $STYLESHEET_PARAM \
  $CACHE_STYLESHEET_PARAM \
  $RESOLVING_UNCACHED_PARAM \
  $BASE_URI_PARAM \
  $PROXY_SCHEME_PARAM \
  $PROXY_HOST_PARAM \
  $PROXY_PORT_PARAM \
  $CLIENT_KEYSTORE_PARAM \
  $SECRETARY_CERT_ALIAS_PARAM \
  $CLIENT_TRUSTSTORE_PARAM \
  $CLIENT_KEYSTORE_PASSWORD_PARAM \
  $CLIENT_TRUSTSTORE_PASSWORD_PARAM \
  $UPLOAD_ROOT_PARAM \
  $SIGN_UP_CERT_VALIDITY_PARAM \
  $CONTEXT_DATASET_PARAM \
  $AUTH_QUERY_PARAM \
  $OWNER_AUTH_QUERY_PARAM \
  $ENABLE_LINKED_DATA_PROXY_PARAM \
  $MAX_CONTENT_LENGTH_PARAM \
  $MAX_CONN_PER_ROUTE_PARAM \
  $MAX_TOTAL_CONN_PARAM \
  $MAX_REQUEST_RETRIES_PARAM \
  $MAX_IMPORT_THREADS_PARAM \
  $NOTIFICATION_ADDRESS_PARAM \
  $ENABLE_WEBID_SIGNUP_PARAM \
  $OIDC_REFRESH_TOKENS_PARAM \
  $MAIL_SMTP_HOST_PARAM \
  $MAIL_SMTP_PORT_PARAM \
  $MAIL_USER_PARAM \
  $MAIL_PASSWORD_PARAM \
  $GOOGLE_CLIENT_ID_PARAM \
  $GOOGLE_CLIENT_SECRET_PARAM \
  /var/linkeddatahub/xsl/context.xsl \
  conf/Catalina/localhost/ROOT.xml"

eval "$transform"

# change webapp (servlet) configuration

if [ -n "$SERVLET_NAME" ]; then
    SERVLET_NAME_PARAM="--stringparam jee:servlet-name '$SERVLET_NAME' "
fi

transform="xsltproc \
  --output /usr/local/tomcat/webapps/ROOT/WEB-INF/web.xml \
  $SERVLET_NAME_PARAM \
  /var/linkeddatahub/xsl/web.xsl \
  /usr/local/tomcat/webapps/ROOT/WEB-INF/web.xml"

eval "$transform"

# print Java's memory settings

java -XX:+PrintFlagsFinal -version | grep -iE 'HeapSize|PermSize|ThreadStackSize'

# wait for the end-user GSP service

printf "\n### Waiting for %s...\n" "$root_end_user_quad_store_url"

wait_for_url "$root_end_user_quad_store_url" "$root_end_user_service_auth_user" "$root_end_user_service_auth_pwd" "$TIMEOUT" "application/n-quads"

# wait for the admin GSP service

printf "\n### Waiting for %s...\n" "$root_admin_quad_store_url"

wait_for_url "$root_admin_quad_store_url" "$root_admin_service_auth_user" "$root_admin_service_auth_pwd" "$TIMEOUT" "application/n-quads"

# run Tomcat (in debug mode if $JPDA_ADDRESS is defined)

if [ -z "$JPDA_ADDRESS" ]; then
    catalina.sh run
else
    catalina.sh jpda run
fi
