#!/bin/bash
set -e

### LETSENCRYPT-TOMCAT ###

if [ -z "$P12_FILE" ] ; then
    echo '$P12_FILE not set'
    exit 1
fi

if [ -z "$PKCS12_KEY_PASSWORD" ] ; then
    echo '$PKCS12_KEY_PASSWORD not set'
    exit 1
fi

if [ -z "$PKCS12_STORE_PASSWORD" ] ; then
    echo '$PKCS12_STORE_PASSWORD not set'
    exit 1
fi

# set timezone

if [ -n "$TZ" ] ; then
    export CATALINA_OPTS="$CATALINA_OPTS -Duser.timezone=$TZ"
fi

# ln -snf /usr/share/zoneinfo/$TZ /etc/localtime
# echo $TZ > /etc/timezone

# if server's SSL certificates do not exist (e.g. not mounted), generate them
# https://community.letsencrypt.org/t/cry-for-help-windows-tomcat-ssl-lets-encrypt/22902/4

if [ ! -f "$P12_FILE" ]; then
    if [ ! -d "$LETSENCRYPT_CERT_DIR" ] || [ -z "$(ls -A "$LETSENCRYPT_CERT_DIR")" ]; then
        echo "### Generating server certificate"

        keytool \
          -genkeypair \
          -storetype PKCS12 \
          -alias "$KEY_ALIAS" \
          -keyalg RSA \
          -keypass "$PKCS12_KEY_PASSWORD" \
          -storepass "$PKCS12_STORE_PASSWORD" \
          -dname 'CN=localhost,OU=LinkedDataHub,O=AtomGraph,L=Copenhagen,ST=Copenhagen,C=DK' \
          -keystore "$P12_FILE"
    else
        echo "### Converting provided LetsEncrypt fullchain.pem/privkey.pem to server certificate"

        openssl pkcs12 \
          -export \
          -in "$LETSENCRYPT_CERT_DIR"/fullchain.pem \
          -inkey "$LETSENCRYPT_CERT_DIR"/privkey.pem \
          -name "$KEY_ALIAS" \
          -out "$P12_FILE" \
          -password pass:"$PKCS12_KEY_PASSWORD"
    fi
else
    echo "### Server certificate exists"
fi

# change server configuration

P12_FILE_PARAM="--stringparam https.keystoreFile '$P12_FILE' "
PKCS12_KEY_PASSWORD_PARAM="--stringparam https.keystorePass '$PKCS12_KEY_PASSWORD' "
PKCS12_STORE_PASSWORD_PARAM="--stringparam https.keyPass '$PKCS12_STORE_PASSWORD' "

if [ -n "$HTTP_PORT" ] ; then
    HTTP_PORT_PARAM="--stringparam http.port '$HTTP_PORT' "
fi

if [ -n "$HTTP_PROXY_NAME" ] ; then
    HTTP_PROXY_NAME_PARAM="--stringparam http.proxyName '$HTTP_PROXY_NAME' "
fi

if [ -n "$HTTP_PROXY_PORT" ] ; then
    HTTP_PROXY_PORT_PARAM="--stringparam http.proxyPort '$HTTP_PROXY_PORT' "
fi

if [ -n "$HTTP_REDIRECT_PORT" ] ; then
    HTTP_REDIRECT_PORT_PARAM="--stringparam http.redirectPort '$HTTP_REDIRECT_PORT' "
fi

if [ -n "$HTTP_CONNECTION_TIMEOUT" ] ; then
    HTTP_CONNECTION_TIMEOUT_PARAM="--stringparam http.connectionTimeout '$HTTP_CONNECTION_TIMEOUT' "
fi

if [ -n "$HTTPS_PORT" ] ; then
    HTTPS_PORT_PARAM="--stringparam https.port '$HTTPS_PORT' "
fi

if [ -n "$HTTPS_MAX_THREADS" ] ; then
    HTTPS_MAX_THREADS_PARAM="--stringparam https.maxThreads '$HTTPS_MAX_THREADS' "
fi

if [ -n "$HTTPS_CLIENT_AUTH" ] ; then
    HTTPS_CLIENT_AUTH_PARAM="--stringparam https.clientAuth '$HTTPS_CLIENT_AUTH' "
fi

if [ -n "$HTTPS_PROXY_NAME" ] ; then
    HTTPS_PROXY_NAME_PARAM="--stringparam https.proxyName '$HTTPS_PROXY_NAME' "
fi

if [ -n "$HTTPS_PROXY_PORT" ] ; then
    HTTPS_PROXY_PORT_PARAM="--stringparam https.proxyPort '$HTTPS_PROXY_PORT' "
fi

if [ -n "$KEY_ALIAS" ] ; then
    KEY_ALIAS_PARAM="--stringparam https.keyAlias '$KEY_ALIAS' "
fi

transform="xsltproc \
  --output conf/server.xml \
  $HTTP_PORT_PARAM \
  $HTTP_PROXY_NAME_PARAM \
  $HTTP_PROXY_PORT_PARAM \
  $HTTP_REDIRECT_PORT_PARAM \
  $HTTP_CONNECTION_TIMEOUT_PARAM \
  $HTTPS_PORT_PARAM \
  $HTTPS_MAX_THREADS_PARAM \
  $HTTPS_CLIENT_AUTH_PARAM \
  $HTTPS_PROXY_NAME_PARAM \
  $HTTPS_PROXY_PORT_PARAM \
  $P12_FILE_PARAM \
  $PKCS12_KEY_PASSWORD_PARAM \
  $KEY_ALIAS_PARAM \
  $PKCS12_STORE_PASSWORD_PARAM \
  conf/letsencrypt-tomcat.xsl \
  conf/server.xml"

eval "$transform"

### PLATFORM ###

# check mandatory environmental variables (which are used in conf/ROOT.xml)

if [ -z "$PROXY_HOST" ] ; then
    echo '$PROXY_HOST not set'
    exit 1
fi

if [ -z "$TIMEOUT" ] ; then
    echo '$TIMEOUT not set'
    exit 1
fi

if [ -z "$BASE_URI" ] ; then
    echo '$BASE_URI not set'
    exit 1
fi

if [ -z "$CLIENT_KEYSTORE" ] ; then
    echo '$CLIENT_KEYSTORE not set'
    exit 1
fi

if [ -z "$SECRETARY_CERT_ALIAS" ] ; then
    echo '$SECRETARY_CERT_ALIAS not set'
    exit 1
fi

if [ -z "$CLIENT_TRUSTSTORE" ] ; then
    echo '$SECRETARY_CERT_ALIAS not set'
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

if [ -z "$ATOMGRAPH_UPLOAD_ROOT" ] ; then
    echo '$ATOMGRAPH_UPLOAD_ROOT not set'
    exit 1
fi

if [ -z "$SIGN_UP_CERT_VALIDITY" ] ; then
    echo '$SIGN_UP_CERT_VALIDITY not set'
    exit 1
fi

if [ -z "$CONTEXT_DATASET" ] ; then
    echo '$CONTEXT_DATASET not set'
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

if [ -z "$MAIL_PASSWORD" ] ; then
    echo '$MAIL_PASSWORD not set'
    exit 1
fi

# create AtomGraph upload root

mkdir -p "$ATOMGRAPH_UPLOAD_ROOT"/"$UPLOAD_CONTAINER_PATH"

# functions that wait for other services to start

wait_for_host()
{
    local host="$1"
    local counter="$2"
    i=1

    while [ "$i" -le "$counter" ] && ! ping -c1 "${host}" >/dev/null 2>&1
    do
        sleep 1 ;
        i=$(( i+1 ))
    done

    if ! ping -c1 "${host}" >/dev/null 2>&1 ; then
        echo "### ${host} not responding, exiting..."
        exit 1
    else
        echo "### ${host} responded"
    fi
}

wait_for_url()
{
    local url="$1"
    local counter="$2"
    local accept="$3"
    i=1

    while [ "$i" -le "$counter" ] && ! curl -s "${url}" -H "Accept: ${accept}" >/dev/null 2>&1
    do
        sleep 1 ;
        i=$(( i+1 ))
    done

    if ! curl -s "${url}" -H "Accept: ${accept}" >/dev/null 2>&1 ; then
        echo "### ${url} not responding, exiting..."
        exit 1
    else
        echo "### ${url} responded"
    fi
}

# function to extract a WebID-compatible modulus from a .p12 certificate

get_modulus()
{
    local cert="$1"
    local password="$2"

    modulus_string=$(openssl pkcs12 -in "$cert" -nodes -passin pass:"$password" 2>/dev/null | openssl x509 -noout -modulus)
    modulus="${modulus_string##*Modulus=}" # cut Modulus= text
    echo "${modulus}" | tr '[:upper:]' '[:lower:]' # lowercase
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
            --user "${auth_user}":"${auth_pwd}" \
            "${quad_store_url}" \
            -H "Content-Type: ${content_type}" \
            --data-binary @"${filename}"
    else
        curl \
            -f \
            "${quad_store_url}" \
            -H "Content-Type: ${content_type}" \
            --data-binary @"${filename}"
    fi
}

# extract the quad store endpoint (and auth credentials) of the root app from the system dataset using SPARQL and XPath queries
# $PWD == $CATALINA_HOME

envsubst '$BASE_URI' < select-root-services.rq.template > select-root-services.rq

sparql --data="${PWD}/webapps/ROOT${CONTEXT_DATASET}" --query="select-root-services.rq" --results=XML > root_admin_service_metadata.xml

root_end_user_quad_store_url=$(cat root_admin_service_metadata.xml | xmlstarlet sel -B -N srx="http://www.w3.org/2005/sparql-results#" -T -t -v "/srx:sparql/srx:results/srx:result/srx:binding[@name = 'endUserQuadStore']" -n)
root_admin_base_uri=$(cat root_admin_service_metadata.xml | xmlstarlet sel -B -N srx="http://www.w3.org/2005/sparql-results#" -T -t -v "/srx:sparql/srx:results/srx:result/srx:binding[@name = 'adminBaseUri']" -n)
root_admin_quad_store_url=$(cat root_admin_service_metadata.xml | xmlstarlet sel -B -N srx="http://www.w3.org/2005/sparql-results#" -T -t -v "/srx:sparql/srx:results/srx:result/srx:binding[@name = 'adminQuadStore']" -n)
root_admin_service_auth_user=$(cat root_admin_service_metadata.xml | xmlstarlet sel -B -N srx="http://www.w3.org/2005/sparql-results#" -T -t -v "/srx:sparql/srx:results/srx:result/srx:binding[@name = 'adminAuthUser']" -n)
root_admin_service_auth_pwd=$(cat root_admin_service_metadata.xml | xmlstarlet sel -B -N srx="http://www.w3.org/2005/sparql-results#" -T -t -v "/srx:sparql/srx:results/srx:result/srx:binding[@name = 'adminAuthPwd']" -n)

rm -f root_admin_service_metadata.xml
rm -f select-root-services.rq

if [ -z "$root_admin_base_uri" ] || [ -z "$root_admin_quad_store_url" ] ; then
    echo "Admin base URI and/or admin quad store could not be extracted from ${CONTEXT_DATASET} for root app with base URI ${BASE_URI}. Exiting..."
    exit 1
fi

printf "\n### Quad store URL of the root admin service: %s\n" "${root_admin_quad_store_url}"

# if CLIENT_TRUSTSTORE does not exist:
# 1. generate a secretary (server) certificate with a WebID relative to the BASE_URI
# 2. import the certificate into the CLIENT_TRUSTSTORE
# 3. initialize an Agent/PublicKey with secretary's metadata and key modulus
# 4. import the secretary metadata metadata into the quad store

if [ ! -f "${CLIENT_TRUSTSTORE}" ]; then
    # generate secretary WebID certificate and extract its modulus

    SECRETARY_KEY_PASSWORD="LinkedDataHub"

    secretary_dname="CN=LinkedDataHub,OU=LinkedDataHub,O=AtomGraph,L=Copenhagen,ST=Denmark,C=DK"
    SECRETARY_URI="${BASE_URI}admin/acl/agents/e413f97b-15ee-47ea-ba65-4479aa7f1f9e/#this"

    printf "\n### Secretary's WebID URI: %s\n" "${SECRETARY_URI}"

    keytool \
        -genkeypair \
        -alias "${SECRETARY_CERT_ALIAS}" \
        -keyalg RSA \
        -storetype PKCS12 \
        -keystore "${CLIENT_KEYSTORE}" \
        -storepass "${CLIENT_KEYSTORE_PASSWORD}" \
        -keypass "${SECRETARY_KEY_PASSWORD}" \
        -dname "${secretary_dname}" \
        -ext SAN=uri:"${SECRETARY_URI}" \
        -validity "${SECRETARY_CERT_VALIDITY}"
    printf "\n### Secretary WebID certificate's DName attributes: %s\n" "${secretary_dname}"

    secretary_cert_modulus=$(get_modulus "${CLIENT_KEYSTORE}" "${SECRETARY_KEY_PASSWORD}")
    export secretary_cert_modulus
    printf "\n### Secretary WebID certificate's modulus: %s\n" "${secretary_cert_modulus}"

    # append secretary metadata to the root admin dataset

    envsubst < root-secretary.trig.template > root-secretary.trig
    trig --base="${root_admin_base_uri}" --output=nq root-secretary.trig > root-secretary.nq

    echo "### Waiting for ${root_admin_quad_store_url}..."

    wait_for_url "${root_admin_quad_store_url}" "${TIMEOUT}" "application/trig"

    printf "\n### Uploading the metadata of the secretary agent...\n\n"

    append_quads "${root_admin_quad_store_url}" "${root_admin_service_auth_user}" "${root_admin_service_auth_pwd}" "root-secretary.nq" "application/n-quads"

    rm -f root-secretary.trig
    rm -f root-secretary.nq

    # if server certificate is self-signed, import it into client (secretary) truststore

    if [ "$SELF_SIGNED_CERT" = true ] ; then
      # export certficate

      keytool -exportcert \
        -alias "$KEY_ALIAS" \
        -file letsencrypt.cer \
        -keystore "$P12_FILE" \
        -storepass "$PKCS12_STORE_PASSWORD" \
        -storetype PKCS12

      # import server certificate into client truststore

      keytool -importcert \
        -alias "$KEY_ALIAS" \
        -file letsencrypt.cer \
        -keystore "${CLIENT_TRUSTSTORE}" \
        -noprompt \
        -storepass "$CLIENT_KEYSTORE_PASSWORD" \
        -storetype PKCS12 \
        -trustcacerts
    fi

    # import default CA certs from the JRE

    export CACERTS="${JAVA_HOME}/lib/security/cacerts"

    keytool -importkeystore \
      -destkeystore "${CLIENT_TRUSTSTORE}" \
      -deststorepass "$CLIENT_KEYSTORE_PASSWORD" \
      -deststoretype PKCS12 \
      -noprompt \
      -srckeystore "$JAVA_HOME"/lib/security/cacerts \
      -srcstorepass changeit > /dev/null
fi

# generate root owner WebID certificate if $OWNER_KEYSTORE does not exist

if [ ! -f "${OWNER_KEYSTORE}" ]; then
    if [ -z "$OWNER_MBOX" ] ; then
        echo '$OWNER_MBOX not set'
        exit 1
    fi

    if [ -z "$OWNER_GIVEN_NAME" ] ; then
        echo '$OWNER_GIVEN_NAME not set'
        exit 1
    fi

    if [ -z "$OWNER_FAMILY_NAME" ] ; then
        echo '$OWNER_FAMILY_NAME not set'
        exit 1
    fi

    if [ -z "$OWNER_ORG_UNIT" ] ; then
        echo '$OWNER_ORG_UNIT not set'
        exit 1
    fi

    if [ -z "$OWNER_ORGANIZATION" ] ; then
        echo '$OWNER_ORGANIZATION not set'
        exit 1
    fi

    if [ -z "$OWNER_LOCALITY" ] ; then
        echo '$OWNER_LOCALITY not set'
        exit 1
    fi

    if [ -z "$OWNER_STATE_OR_PROVINCE" ] ; then
        echo '$OWNER_STATE_OR_PROVINCE not set'
        exit 1
    fi

    if [ -z "$OWNER_COUNTRY_NAME" ] ; then
        echo '$OWNER_COUNTRY_NAME not set'
        exit 1
    fi

    if [ -z "$OWNER_KEY_PASSWORD" ] ; then
        echo '$OWNER_KEY_PASSWORD not set'
        exit 1
    fi

    root_owner_dname="CN=${OWNER_GIVEN_NAME} ${OWNER_FAMILY_NAME},OU=${OWNER_ORG_UNIT},O=${OWNER_ORGANIZATION},L=${OWNER_LOCALITY},ST=${OWNER_STATE_OR_PROVINCE},C=${OWNER_COUNTRY_NAME}"
    printf "\n### Root owner WebID certificate's DName attributes: %s\n" "${root_owner_dname}"

    root_owner_uuid=$(uuidgen | tr '[:upper:]' '[:lower:]') # lowercase
    OWNER_DOC_URI="${BASE_URI}admin/acl/agents/${root_owner_uuid}/"
    OWNER_URI="${OWNER_DOC_URI}#this"

    printf "\n### Root owner's WebID URI: %s\n" "${OWNER_URI}"

    keytool \
        -genkeypair \
        -alias "${OWNER_CERT_ALIAS}" \
        -keyalg RSA \
        -storetype PKCS12 \
        -keystore "${OWNER_KEYSTORE}" \
        -storepass "${OWNER_KEY_PASSWORD}" \
        -keypass "${OWNER_KEY_PASSWORD}" \
        -dname "${root_owner_dname}" \
        -ext SAN=uri:"${OWNER_URI}" \
        -validity "${OWNER_CERT_VALIDITY}"

    # convert owner's certificate to PEM

    openssl \
        pkcs12 \
        -in "${OWNER_KEYSTORE}" \
        -passin pass:"${OWNER_KEY_PASSWORD}" \
        -out "${OWNER_KEYSTORE}.pem" \
        -passout pass:"${OWNER_KEY_PASSWORD}"

    owner_cert_modulus=$(get_modulus "${OWNER_KEYSTORE}" "${OWNER_KEY_PASSWORD}")
    export owner_cert_modulus
    printf "\n### Root owner WebID certificate's modulus: %s\n" "${owner_cert_modulus}"

    # generate unique UUIDs for RDF graph URIs

    owner_meta_graph_uuid=$(uuidgen | tr '[:upper:]' '[:lower:]') # lowercase
    export owner_meta_graph_uuid
    owner_graph_uuid=$(uuidgen | tr '[:upper:]' '[:lower:]') # lowercase
    export owner_graph_uuid
    public_key_meta_graph_uuid=$(uuidgen | tr '[:upper:]' '[:lower:]') # lowercase
    export public_key_meta_graph_uuid
    public_key_graph_uuid=$(uuidgen | tr '[:upper:]' '[:lower:]') # lowercase
    export public_key_graph_uuid
    public_key_uuid=$(uuidgen | tr '[:upper:]' '[:lower:]') # lowercase
    export public_key_uuid

    # append root owner metadata to the root admin dataset

    envsubst < root-owner.trig.template > root-owner.trig
    trig --base="${root_admin_base_uri}" --output=nq root-owner.trig > root-owner.nq

    printf "\n### Uploading the metadata of the owner agent...\n\n"

    append_quads "${root_admin_quad_store_url}" "${root_admin_service_auth_user}" "${root_admin_service_auth_pwd}" "root-owner.nq" "application/n-quads"

    rm -f root-owner.trig
    rm -f root-owner.nq
fi

# change server configuration 
# the TrustManager code is located in lib/trust-manager.jar

TRUST_MANAGER_CLASS_NAME="com.atomgraph.linkeddatahub.server.ssl.TrustManager"

xsltproc \
  --output conf/server.xml \
  --stringparam https.trustManagerClassName "$TRUST_MANAGER_CLASS_NAME" \
  conf/server.xsl \
  conf/server.xml

# change context configuration

CLIENT_KEYSTORE_PARAM="--stringparam aplc:clientKeyStore 'file://$CLIENT_KEYSTORE' "
SECRETARY_CERT_ALIAS_PARAM="--stringparam aplc:secretaryCertAlias '$SECRETARY_CERT_ALIAS' "
CLIENT_TRUSTSTORE_PARAM="--stringparam aplc:clientTrustStore 'file://$CLIENT_TRUSTSTORE' "
CLIENT_KEYSTORE_PASSWORD_PARAM="--stringparam aplc:clientKeyStorePassword '$CLIENT_KEYSTORE_PASSWORD' "
CLIENT_TRUSTSTORE_PASSWORD_PARAM="--stringparam aplc:clientTrustStorePassword '$CLIENT_TRUSTSTORE_PASSWORD' "
ATOMGRAPH_UPLOAD_ROOT_PARAM="--stringparam aplc:uploadRoot 'file://$ATOMGRAPH_UPLOAD_ROOT' "
SIGN_UP_CERT_VALIDITY_PARAM="--stringparam aplc:signUpCertValidity '$SIGN_UP_CERT_VALIDITY' "
CONTEXT_DATASET_PARAM="--stringparam aplc:contextDataset '$CONTEXT_DATASET' "
MAIL_SMTP_HOST_PARAM="--stringparam mail.smtp.host '$MAIL_SMTP_HOST' "
MAIL_SMTP_PORT_PARAM="--stringparam mail.smtp.port '$MAIL_SMTP_PORT' "
MAIL_USER_PARAM="--stringparam mail.user '$MAIL_USER' "
MAIL_PASSWORD_PARAM="--stringparam mail.password '$MAIL_PASSWORD' "

# stylesheet URL must be relative to the base context URL
if [ -n "$STYLESHEET" ] ; then
    STYLESHEET_PARAM="--stringparam ac:stylesheet '$STYLESHEET' "
fi

if [ -n "$CACHE_STYLESHEET" ] ; then
    CACHE_STYLESHEET_PARAM="--stringparam ac:cacheStylesheet '$CACHE_STYLESHEET' "
fi

if [ -n "$AUTH_QUERY" ] ; then
    AUTH_QUERY_PARAM="--stringparam aplc:authQuery '$AUTH_QUERY' "
fi

if [ -n "$OWNER_AUTH_QUERY" ] ; then
    OWNER_AUTH_QUERY_PARAM="--stringparam aplc:ownerAuthQuery '$OWNER_AUTH_QUERY' "
fi

transform="xsltproc \
  --output conf/Catalina/localhost/ROOT.xml \
  $STYLESHEET_PARAM \
  $CACHE_STYLESHEET_PARAM \
  $CLIENT_KEYSTORE_PARAM \
  $SECRETARY_CERT_ALIAS_PARAM \
  $CLIENT_TRUSTSTORE_PARAM \
  $CLIENT_KEYSTORE_PASSWORD_PARAM \
  $CLIENT_TRUSTSTORE_PASSWORD_PARAM \
  $ATOMGRAPH_UPLOAD_ROOT_PARAM \
  $SIGN_UP_CERT_VALIDITY_PARAM \
  $CONTEXT_DATASET_PARAM \
  $AUTH_QUERY_PARAM \
  $OWNER_AUTH_QUERY_PARAM \
  $MAIL_SMTP_HOST_PARAM \
  $MAIL_SMTP_PORT_PARAM \
  $MAIL_USER_PARAM \
  $MAIL_PASSWORD_PARAM \
  conf/context.xsl \
  conf/Catalina/localhost/ROOT.xml"

eval "$transform"

# print Java's memory settings

java -XX:+PrintFlagsFinal -version | grep -iE 'HeapSize|PermSize|ThreadStackSize'

# wait for the end-user GSP service

echo "### Waiting for ${root_end_user_quad_store_url}..."

wait_for_url "${root_end_user_quad_store_url}" "${TIMEOUT}" "application/trig"

# wait for the admin GSP service

echo "### Waiting for ${root_admin_quad_store_url}..."

wait_for_url "${root_admin_quad_store_url}" "${TIMEOUT}" "application/trig"

# wait for the proxy server

echo "### Waiting for ${PROXY_HOST}..."

wait_for_host "${PROXY_HOST}" "${TIMEOUT}"

# set localhost to the nginx IP address - we want to loopback to it

proxy_ip=$(getent hosts "${PROXY_HOST}" | awk '{ print $1 }')

echo "${proxy_ip} localhost" >> /etc/hosts

# run Tomcat (in debug mode if $JPDA_ADDRESS is defined)

if [ -z "$JPDA_ADDRESS" ] ; then
    catalina.sh run
else
    catalina.sh jpda run
fi