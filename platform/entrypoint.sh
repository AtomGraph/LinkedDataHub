#!/bin/bash
set -e

# set timezone

if [ -n "$TZ" ] ; then
    export CATALINA_OPTS="$CATALINA_OPTS -Duser.timezone=$TZ -Dorg.apache.tomcat.util.buf.UDecoder.ALLOW_ENCODED_SLASH=true"
fi

# ln -snf /usr/share/zoneinfo/$TZ /etc/localtime
# echo $TZ > /etc/timezone

# change server configuration

if [ -n "$HTTP" ] ; then
    HTTP_PARAM="--stringparam http $HTTP "
fi

if [ -n "$HTTP_SCHEME" ] ; then
    HTTP_SCHEME_PARAM="--stringparam http.scheme $HTTP_SCHEME "
fi

if [ -n "$HTTP_PORT" ] ; then
    HTTP_PORT_PARAM="--stringparam http.port $HTTP_PORT "
fi

if [ -n "$HTTP_PROXY_NAME" ] ; then
    HTTP_PROXY_NAME_PARAM="--stringparam http.proxyName $HTTP_PROXY_NAME "
fi

if [ -n "$HTTP_PROXY_PORT" ] ; then
    HTTP_PROXY_PORT_PARAM="--stringparam http.proxyPort $HTTP_PROXY_PORT "
fi

if [ -n "$HTTP_REDIRECT_PORT" ] ; then
    HTTP_REDIRECT_PORT_PARAM="--stringparam http.redirectPort $HTTP_REDIRECT_PORT "
fi

if [ -n "$HTTP_CONNECTION_TIMEOUT" ] ; then
    HTTP_CONNECTION_TIMEOUT_PARAM="--stringparam http.connectionTimeout $HTTP_CONNECTION_TIMEOUT "
fi

if [ -n "$HTTP_COMPRESSION" ] ; then
    HTTP_COMPRESSION_PARAM="--stringparam http.compression $HTTP_COMPRESSION "
fi

if [ -n "$HTTPS" ] ; then
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

if [ -z "$TIMEOUT" ] ; then
    echo '$TIMEOUT not set'
    exit 1
fi

if [ -z "$PROTOCOL" ] ; then
    echo '$PROTOCOL not set'
    exit 1
fi

if [ -z "$HTTP_PROXY_PORT" ] ; then
    echo '$HTTP_PROXY_PORT not set'
    exit 1
fi

if [ -z "$HTTPS_PROXY_PORT" ] ; then
    echo '$HTTPS_PROXY_PORT not set'
    exit 1
fi

if [ -z "$HOST" ] ; then
    echo '$HOST not set'
    exit 1
fi

if [ -z "$ABS_PATH" ] ; then
    echo '$ABS_PATH not set'
    exit 1
fi

if [ -z "$OWNER_PUBLIC_KEY" ] ; then
    echo '$OWNER_PUBLIC_KEY not set'
    exit 1
fi

if [ -z "$CLIENT_KEYSTORE" ] ; then
    echo '$CLIENT_KEYSTORE not set'
    exit 1
fi

if [ -z "$CLIENT_KEYSTORE_MOUNT" ] ; then
    echo '$CLIENT_KEYSTORE_MOUNT not set'
    exit 1
fi

if [ -z "$SECRETARY_CERT_ALIAS" ] ; then
    echo '$SECRETARY_CERT_ALIAS not set'
    exit 1
fi

if [ -z "$CLIENT_TRUSTSTORE" ] ; then
    echo '$CLIENT_TRUSTSTORE not set'
    exit 1
fi

if [ -z "$CLIENT_KEYSTORE_PASSWORD" ] ; then
    echo '$CLIENT_KEYSTORE_PASSWORD not set'
    exit 1
fi

if [ -z "$CLIENT_TRUSTSTORE_PASSWORD" ] ; then
    echo '$CLIENT_TRUSTSTORE_PASSWORD not set'
    exit 1
fi

if [ -z "$UPLOAD_ROOT" ] ; then
    echo '$UPLOAD_ROOT not set'
    exit 1
fi

if [ -z "$SIGN_UP_CERT_VALIDITY" ] ; then
    echo '$SIGN_UP_CERT_VALIDITY not set'
    exit 1
fi

if [ -z "$CONTEXT_DATASET_URL" ] ; then
    echo '$CONTEXT_DATASET_URL not set'
    exit 1
fi

if [ -z "$END_USER_DATASET_URL" ] ; then
    echo '$END_USER_DATASET_URL not set'
    exit 1
fi

if [ -z "$ADMIN_DATASET_URL" ] ; then
    echo '$ADMIN_DATASET_URL not set'
    exit 1
fi

if [ -z "$MAIL_SMTP_HOST" ] ; then
    echo '$MAIL_SMTP_HOST not set'
    exit 1
fi

if [ -z "$MAIL_SMTP_PORT" ] ; then
    echo '$MAIL_SMTP_PORT not set'
    exit 1
fi

if [ -z "$MAIL_USER" ] ; then
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
    if [ -n "$auth_user" ] && [ -n "$auth_pwd" ] ; then
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
    if [ -n "$auth_user" ] && [ -n "$auth_pwd" ] ; then
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

# extract the quad store endpoint (and auth credentials) of the root app from the system dataset using SPARQL and XPath queries

envsubst '$BASE_URI' < select-root-services.rq.template > select-root-services.rq

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

root_end_user_app=$(cat root_service_metadata.xml | xmlstarlet sel -B -N srx="http://www.w3.org/2005/sparql-results#" -T -t -v "/srx:sparql/srx:results/srx:result/srx:binding[@name = 'endUserApp']" -n)
root_end_user_quad_store_url=$(cat root_service_metadata.xml | xmlstarlet sel -B -N srx="http://www.w3.org/2005/sparql-results#" -T -t -v "/srx:sparql/srx:results/srx:result/srx:binding[@name = 'endUserQuadStore']" -n)
root_end_user_service_auth_user=$(cat root_service_metadata.xml | xmlstarlet sel -B -N srx="http://www.w3.org/2005/sparql-results#" -T -t -v "/srx:sparql/srx:results/srx:result/srx:binding[@name = 'endUserAuthUser']" -n)
root_end_user_service_auth_pwd=$(cat root_service_metadata.xml | xmlstarlet sel -B -N srx="http://www.w3.org/2005/sparql-results#" -T -t -v "/srx:sparql/srx:results/srx:result/srx:binding[@name = 'endUserAuthPwd']" -n)

root_admin_app=$(cat root_service_metadata.xml | xmlstarlet sel -B -N srx="http://www.w3.org/2005/sparql-results#" -T -t -v "/srx:sparql/srx:results/srx:result/srx:binding[@name = 'adminApp']" -n)
root_admin_base_uri=$(cat root_service_metadata.xml | xmlstarlet sel -B -N srx="http://www.w3.org/2005/sparql-results#" -T -t -v "/srx:sparql/srx:results/srx:result/srx:binding[@name = 'adminBaseUri']" -n)
root_admin_quad_store_url=$(cat root_service_metadata.xml | xmlstarlet sel -B -N srx="http://www.w3.org/2005/sparql-results#" -T -t -v "/srx:sparql/srx:results/srx:result/srx:binding[@name = 'adminQuadStore']" -n)
root_admin_service_auth_user=$(cat root_service_metadata.xml | xmlstarlet sel -B -N srx="http://www.w3.org/2005/sparql-results#" -T -t -v "/srx:sparql/srx:results/srx:result/srx:binding[@name = 'adminAuthUser']" -n)
root_admin_service_auth_pwd=$(cat root_service_metadata.xml | xmlstarlet sel -B -N srx="http://www.w3.org/2005/sparql-results#" -T -t -v "/srx:sparql/srx:results/srx:result/srx:binding[@name = 'adminAuthPwd']" -n)

rm -f root_service_metadata.xml select-root-services.rq

if [ -z "$root_end_user_quad_store_url" ] ; then
    printf "\nEnd-user quad store could not be extracted from %s for root app with base URI %s. Exiting...\n" "$CONTEXT_DATASET" "$BASE_URI"
    exit 1
fi
if [ -z "$root_admin_base_uri" ] ; then
    printf "\nAdmin base URI extracted from %s for root app with base URI %s. Exiting...\n" "$CONTEXT_DATASET" "$BASE_URI"
    exit 1
fi
if [ -z "$root_admin_quad_store_url" ] ; then
    printf "\nAdmin quad store could not be extracted from %s for root app with base URI %s. Exiting...\n" "$CONTEXT_DATASET" "$BASE_URI"
    exit 1
fi

printf "\n### Quad store URL of the root admin service: %s\n" "$root_admin_quad_store_url"

# append root owner's metadata to the root admin dataset

if [ -z "$OWNER_MBOX" ] ; then
    echo '$OWNER_MBOX not set'
    exit 1
fi

get_modulus()
{
    local key_pem="$1"

    modulus_string=$(openssl x509 -noout -modulus -in "$key_pem")
    modulus="${modulus_string##*Modulus=}" # cut Modulus= text
    echo "$modulus" | tr '[:upper:]' '[:lower:]' # lowercase
}

get_common_name()
{
    local key_pem="$1"

    openssl x509 -noout -subject -in "$key_pem" -nameopt lname,sep_multiline,utf8 | grep 'commonName' | cut -d "=" -f 2
}

get_webid_uri()
{
    local key_pem="$1"

    openssl x509 -in "$key_pem" -text -noout \
      -certopt no_subject,no_header,no_version,no_serial,no_signame,no_validity,no_issuer,no_pubkey,no_sigdump,no_aux \
      | awk '/X509v3 Subject Alternative Name/ {getline; print}' | xargs | tail -c +5
}

OWNER_COMMON_NAME=$(get_common_name "$OWNER_PUBLIC_KEY")

if [ -z "$OWNER_COMMON_NAME" ] ; then
    echo "Owner's public key does not contain CN (commonName) metadata"
    exit 1
fi

OWNER_URI=$(get_webid_uri "$OWNER_PUBLIC_KEY")

if [ -z "$OWNER_URI" ] ; then
    echo "Owner's public key does not contain a SAN:URI (subjectAlternativeName) extension with a WebID URI"
    exit 1
fi

printf "\n### Owner's WebID URI: %s\n" "$OWNER_URI"

# strip fragment from the URL, if any

case "$OWNER_URI" in
  *#*) OWNER_DOC_URI=$(echo "$OWNER_URI" | cut -d "#" -f 1) ;;
  *) OWNER_DOC_URI="$OWNER_URI" ;;
esac

OWNER_CERT_MODULUS=$(get_modulus "$OWNER_PUBLIC_KEY")

printf "\n### Root owner WebID certificate's modulus: %s\n" "$OWNER_CERT_MODULUS"

OWNER_KEY_UUID=$(uuidgen | tr '[:upper:]' '[:lower:]') # lowercase
export OWNER_COMMON_NAME OWNER_URI OWNER_DOC_URI OWNER_CERT_MODULUS OWNER_KEY_UUID

# copy mounted client keystore to a location where the webapp can access it

mkdir -p "$(dirname "$CLIENT_KEYSTORE")"

cp -f "$CLIENT_KEYSTORE_MOUNT" "$(dirname "$CLIENT_KEYSTORE")"

# if CLIENT_TRUSTSTORE does not exist:
# 1. import the certificate into the CLIENT_TRUSTSTORE
# 2. initialize an Agent/PublicKey with secretary's metadata and key modulus
# 3. import the secretary metadata metadata into the quad store

if [ ! -f "$CLIENT_TRUSTSTORE" ]; then
    # if server certificate is self-signed, import it into client truststore

    if [ "$SELF_SIGNED_CERT" = true ] ; then
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

    printf "\n### Importing default CA certificates into the client truststore\n\n"
 
    export CACERTS="${JAVA_HOME}/lib/security/cacerts"

    keytool -importkeystore \
        -destkeystore "$CLIENT_TRUSTSTORE" \
        -deststorepass "$CLIENT_TRUSTSTORE_PASSWORD" \
        -deststoretype PKCS12 \
        -noprompt \
        -srckeystore "$CACERTS" \
        -srcstorepass changeit
fi

SECRETARY_URI=$(get_webid_uri "$SECRETARY_CERT")

if [ -z "$SECRETARY_URI" ] ; then
    echo "Secretary's public key does not contain a SAN:URI (subjectAlternativeName) extension with a WebID URI"
    exit 1
fi

printf "\n### Secretary's WebID URI: %s\n" "$SECRETARY_URI"

# strip fragment from the URL, if any

case "$SECRETARY_URI" in
  *#*) SECRETARY_DOC_URI=$(echo "$SECRETARY_URI" | cut -d "#" -f 1) ;;
  *) SECRETARY_DOC_URI="$SECRETARY_URI" ;;
esac

SECRETARY_CERT_MODULUS=$(get_modulus "$SECRETARY_CERT")
printf "\n### Secretary WebID certificate's modulus: %s\n" "$SECRETARY_CERT_MODULUS"

SECRETARY_KEY_UUID=$(uuidgen | tr '[:upper:]' '[:lower:]') # lowercase
export SECRETARY_URI SECRETARY_DOC_URI SECRETARY_CERT_MODULUS SECRETARY_KEY_UUID

if [ -z "$LOAD_DATASETS" ]; then
    if [ ! -d /var/linkeddatahub/based-datasets ]; then
        LOAD_DATASETS=true
    else
        LOAD_DATASETS=false
    fi
fi

# load default admin/end-user datasets if we haven't yet created a folder with re-based versions of them (and then create it)
if [ "$LOAD_DATASETS" = "true" ]; then
    mkdir -p /var/linkeddatahub/based-datasets

    # create query file by injecting environmental variables into the template

    envsubst < split-default-graph.rq.template > split-default-graph.rq

    case "$END_USER_DATASET_URL" in
        "file://"*)
            END_USER_DATASET=$(echo "$END_USER_DATASET_URL" | cut -c 8-) # strip leading file://

            printf "\n### Reading end-user dataset from a local file: %s\n" "$END_USER_DATASET" ;;
        *)  
            END_USER_DATASET=$(mktemp)

            printf "\n### Downloading end-user dataset from a URL: %s\n" "$END_USER_DATASET_URL"

            curl "$END_USER_DATASET_URL" > "$END_USER_DATASET" ;;
    esac

    trig --base="$BASE_URI" "$END_USER_DATASET" > /var/linkeddatahub/based-datasets/end-user.nq
    sparql --data /var/linkeddatahub/based-datasets/end-user.nq --base "$BASE_URI" --query split-default-graph.rq --results=nq > /var/linkeddatahub/based-datasets/split.end-user.nq

    case "$ADMIN_DATASET_URL" in
        "file://"*)
            ADMIN_DATASET=$(echo "$ADMIN_DATASET_URL" | cut -c 8-) # strip leading file://

            printf "\n### Reading admin dataset from a local file: %s\n" "$ADMIN_DATASET" ;;
        *)  
            ADMIN_DATASET=$(mktemp)

            printf "\n### Downloading admin dataset from a URL: %s\n" "$ADMIN_DATASET_URL"

            curl "$ADMIN_DATASET_URL" > "$ADMIN_DATASET" ;;
    esac

    trig --base="$root_admin_base_uri" "$ADMIN_DATASET" > /var/linkeddatahub/based-datasets/admin.nq
    sparql --data /var/linkeddatahub/based-datasets/admin.nq --base "$root_admin_base_uri" --query split-default-graph.rq --results=nq > /var/linkeddatahub/based-datasets/split.admin.nq

    printf "\n### Waiting for %s...\n" "$root_end_user_quad_store_url"
    wait_for_url "$root_end_user_quad_store_url" "$root_end_user_service_auth_user" "$root_end_user_service_auth_pwd" "$TIMEOUT" "application/n-quads"

    printf "\n### Loading end-user dataset into the triplestore...\n"
    append_quads "$root_end_user_quad_store_url" "$root_end_user_service_auth_user" "$root_end_user_service_auth_pwd" /var/linkeddatahub/based-datasets/split.end-user.nq "application/n-quads"

    printf "\n### Waiting for %s...\n" "$root_admin_quad_store_url"
    wait_for_url "$root_admin_quad_store_url" "$root_admin_service_auth_user" "$root_admin_service_auth_pwd" "$TIMEOUT" "application/n-quads"

    printf "\n### Loading admin dataset into the triplestore...\n"
    append_quads "$root_admin_quad_store_url" "$root_admin_service_auth_user" "$root_admin_service_auth_pwd" /var/linkeddatahub/based-datasets/split.admin.nq "application/n-quads"

    # append owner metadata to the root admin dataset

    envsubst < root-owner.trig.template > root-owner.trig

    trig --base="$root_admin_base_uri" --output=nq root-owner.trig > root-owner.nq

    printf "\n### Uploading the metadata of the owner agent...\n\n"

    append_quads "$root_admin_quad_store_url" "$root_admin_service_auth_user" "$root_admin_service_auth_pwd" root-owner.nq "application/n-quads"

    rm -f root-owner.trig root-owner.nq

    # append ownership metadata to apps (have to be URI resources!)

    echo "<${root_admin_app}> <http://xmlns.com/foaf/0.1/maker> <${OWNER_URI}> ." >> "$based_context_dataset"
    echo "<${root_end_user_app}> <http://xmlns.com/foaf/0.1/maker> <${OWNER_URI}> ." >> "$based_context_dataset"

    # append secretary metadata to the root admin dataset

    envsubst < root-secretary.trig.template > root-secretary.trig

    trig --base="$root_admin_base_uri" --output=nq root-secretary.trig > root-secretary.nq

    printf "\n### Uploading the metadata of the secretary agent...\n\n"

    append_quads "$root_admin_quad_store_url" "$root_admin_service_auth_user" "$root_admin_service_auth_pwd" root-secretary.nq "application/n-quads"

    rm -f root-secretary.trig root-secretary.nq
fi

# change context configuration

BASE_URI_PARAM="--stringparam aplc:baseUri '$BASE_URI' "
CLIENT_KEYSTORE_PARAM="--stringparam aplc:clientKeyStore 'file://$CLIENT_KEYSTORE' "
SECRETARY_CERT_ALIAS_PARAM="--stringparam aplc:secretaryCertAlias '$SECRETARY_CERT_ALIAS' "
CLIENT_TRUSTSTORE_PARAM="--stringparam aplc:clientTrustStore 'file://$CLIENT_TRUSTSTORE' "
CLIENT_KEYSTORE_PASSWORD_PARAM="--stringparam aplc:clientKeyStorePassword '$CLIENT_KEYSTORE_PASSWORD' "
CLIENT_TRUSTSTORE_PASSWORD_PARAM="--stringparam aplc:clientTrustStorePassword '$CLIENT_TRUSTSTORE_PASSWORD' "
UPLOAD_ROOT_PARAM="--stringparam aplc:uploadRoot 'file://$UPLOAD_ROOT' "
SIGN_UP_CERT_VALIDITY_PARAM="--stringparam aplc:signUpCertValidity '$SIGN_UP_CERT_VALIDITY' "
CONTEXT_DATASET_PARAM="--stringparam aplc:contextDataset '$webapp_context_dataset' "
MAIL_SMTP_HOST_PARAM="--stringparam mail.smtp.host '$MAIL_SMTP_HOST' "
MAIL_SMTP_PORT_PARAM="--stringparam mail.smtp.port '$MAIL_SMTP_PORT' "
MAIL_USER_PARAM="--stringparam mail.user '$MAIL_USER' "

if [ -n "$PROXY_SCHEME" ] ; then
    PROXY_SCHEME_PARAM="--stringparam aplc:proxyScheme '$PROXY_SCHEME' "
fi

if [ -n "$PROXY_HOST" ] ; then
    PROXY_HOST_PARAM="--stringparam aplc:proxyHost '$PROXY_HOST' "
fi

if [ -n "$PROXY_PORT" ] ; then
    PROXY_PORT_PARAM="--stringparam aplc:proxyPort '$PROXY_PORT' "
fi

if [ -n "$CACHE_MODEL_LOADS" ] ; then
    CACHE_MODEL_LOADS_PARAM="--stringparam a:cacheModelLoads '$CACHE_MODEL_LOADS' "
fi

# stylesheet URL must be relative to the base context URL
if [ -n "$STYLESHEET" ] ; then
    STYLESHEET_PARAM="--stringparam ac:stylesheet '$STYLESHEET' "
fi

if [ -n "$CACHE_STYLESHEET" ] ; then
    CACHE_STYLESHEET_PARAM="--stringparam ac:cacheStylesheet '$CACHE_STYLESHEET' "
fi

if [ -n "$RESOLVING_UNCACHED" ] ; then
    RESOLVING_UNCACHED_PARAM="--stringparam ac:resolvingUncached '$RESOLVING_UNCACHED' "
fi

if [ -n "$AUTH_QUERY" ] ; then
    AUTH_QUERY_PARAM="--stringparam aplc:authQuery '$AUTH_QUERY' "
fi

if [ -n "$OWNER_AUTH_QUERY" ] ; then
    OWNER_AUTH_QUERY_PARAM="--stringparam aplc:ownerAuthQuery '$OWNER_AUTH_QUERY' "
fi

if [ -n "$MAX_CONTENT_LENGTH" ] ; then
    MAX_CONTENT_LENGTH_PARAM="--stringparam aplc:maxContentLength '$MAX_CONTENT_LENGTH' "
fi

if [ -n "$MAX_CONN_PER_ROUTE" ] ; then
    MAX_CONN_PER_ROUTE_PARAM="--stringparam aplc:maxConnPerRoute '$MAX_CONN_PER_ROUTE' "
fi

if [ -n "$MAX_TOTAL_CONN" ] ; then
    MAX_TOTAL_CONN_PARAM="--stringparam aplc:maxTotalConn '$MAX_TOTAL_CONN' "
fi

if [ -n "$IMPORT_KEEPALIVE" ] ; then
    IMPORT_KEEPALIVE_PARAM="--stringparam aplc:importKeepAlive '$IMPORT_KEEPALIVE' "
fi

if [ -n "$MAIL_PASSWORD" ] ; then
    MAIL_PASSWORD_PARAM="--stringparam mail.password '$MAIL_PASSWORD' "
fi

if [ -n "$GOOGLE_CLIENT_ID" ] ; then
    GOOGLE_CLIENT_ID_PARAM="--stringparam google:clientID '$GOOGLE_CLIENT_ID' "
fi

if [ -n "$GOOGLE_CLIENT_SECRET" ] ; then
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
  $MAX_CONTENT_LENGTH_PARAM \
  $MAX_CONN_PER_ROUTE_PARAM \
  $MAX_TOTAL_CONN_PARAM \
  $IMPORT_KEEPALIVE_PARAM \
  $MAIL_SMTP_HOST_PARAM \
  $MAIL_SMTP_PORT_PARAM \
  $MAIL_USER_PARAM \
  $MAIL_PASSWORD_PARAM \
  $GOOGLE_CLIENT_ID_PARAM \
  $GOOGLE_CLIENT_SECRET_PARAM \
  conf/context.xsl \
  conf/Catalina/localhost/ROOT.xml"

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

if [ -z "$JPDA_ADDRESS" ] ; then
    catalina.sh run
else
    catalina.sh jpda run
fi