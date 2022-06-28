FROM maven:3.8.4-openjdk-17 as maven

# download and extract Jena

ARG JENA_VERSION=4.3.2

ARG JENA_TAR_URL="https://archive.apache.org/dist/jena/binaries/apache-jena-${JENA_VERSION}.tar.gz"

RUN mkdir /jena && \
    curl -SL "$JENA_TAR_URL" | \
    tar -xzf - -C /jena

# copy platform source code and POM

WORKDIR /usr/src/platform

COPY src /usr/src/platform/src

COPY pom.xml /usr/src/platform/pom.xml

RUN mvn -Pstandalone clean install

# ==============================

FROM atomgraph/letsencrypt-tomcat:00336f862d03d41a83a9077a98aa39955876c999

LABEL maintainer="martynas@atomgraph.com"

# hash of the current commit

ARG SOURCE_COMMIT=

ARG UPLOAD_ROOT=/var/www/linkeddatahub/uploads

ARG UPLOAD_CONTAINER_PATH=uploads

ENV SOURCE_COMMIT=$SOURCE_COMMIT

WORKDIR $CATALINA_HOME

# add XSLT stylesheet that makes changes to ROOT.xml

COPY platform/context.xsl conf/context.xsl

ENV CACHE_MODEL_LOADS=true

ENV STYLESHEET=static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/layout.xsl

ENV CACHE_STYLESHEET=true

ENV UPLOAD_ROOT=$UPLOAD_ROOT

ENV PROXY_HOST=

ENV PROXY_HTTP_PORT=

ENV PROXY_HTTPS_PORT=

ENV TIMEOUT=20

ENV PROTOCOL=https

ENV HOST=localhost

ENV ABS_PATH=/

ENV HTTP_REDIRECT_PORT=443

ENV HTTP_COMPRESSION=on

ENV HTTPS=false

ENV SERVER_CERT=/var/linkeddatahub/ssl/server/server.crt

ENV SECRETARY_CERT=/var/linkeddatahub/ssl/secretary/cert.pem

ENV SECRETARY_CERT_ALIAS=secretary

ENV CLIENT_KEYSTORE_MOUNT=/var/linkeddatahub/ssl/secretary/keystore.p12

ENV CLIENT_KEYSTORE="$CATALINA_HOME/webapps/ROOT/ssl/keystore.p12"

ENV CLIENT_TRUSTSTORE="$CATALINA_HOME/webapps/ROOT/ssl/client.truststore"

ENV OWNER_PUBLIC_KEY=/var/linkeddatahub/ssl/owner/public.pem

ENV LOAD_DATASETS=

ENV CONTEXT_DATASET_URL=file:///var/linkeddatahub/datasets/system.trig

ENV ADMIN_DATASET_URL=file:///var/linkeddatahub/datasets/admin.trig

ENV END_USER_DATASET_URL=file:///var/linkeddatahub/datasets/end-user.trig

ENV UPLOAD_CONTAINER_PATH=$UPLOAD_CONTAINER_PATH

ENV OIDC_REFRESH_TOKENS=/var/linkeddatahub/oidc/refresh_tokens.properties

ENV MAX_CONTENT_LENGTH=

ENV MAX_CONN_PER_ROUTE=40

ENV MAX_TOTAL_CONN=40

ENV IMPORT_KEEPALIVE=

ENV GOOGLE_CLIENT_ID=

ENV GOOGLE_CLIENT_SECRET=

# HEALTHCHECK --start-period=80s CMD curl -f http://localhost:$HTTP_PORT || exit 1

# remove default Tomcat webapps and install xmlstarlet (used for XPath queries) and envsubst (for variable substitution)

RUN apt-get update --allow-releaseinfo-change && \
    apt-get install -y acl && \
    apt-get install -y xmlstarlet && \
    apt-get install -y gettext-base && \
    apt-get install -y uuid-runtime && \
    rm -rf webapps/* && \
    rm -rf /var/lib/apt/lists/*

# copy entrypoint

COPY platform/entrypoint.sh entrypoint.sh

# copy certificate import script

COPY platform/import-letsencrypt-stg-roots.sh import-letsencrypt-stg-roots.sh

# copy SPARQL query used to get metadata of the root app service from the system dataset

COPY platform/select-root-services.rq select-root-services.rq

# copy the metadata of the built-in secretary agent

COPY platform/root-secretary.trig.template root-secretary.trig.template

COPY platform/root-owner.trig.template root-owner.trig.template

# copy default datasets

COPY platform/datasets/admin.trig /var/linkeddatahub/datasets/admin.trig

COPY platform/datasets/end-user.trig /var/linkeddatahub/datasets/end-user.trig

# copy webapp config

COPY platform/conf/ROOT.xml conf/Catalina/localhost/ROOT.xml

# copy platform webapp (exploded) from the maven stage of the build

COPY --from=maven /usr/src/platform/target/ROOT webapps/ROOT/

# copy extracted Jena from the maven stage of the build

COPY --from=maven /jena/* /jena

# setup Jena

ENV JENA_HOME=/jena

ENV PATH="${PATH}:${JENA_HOME}/bin"

# add non-root user "ldh" and give it access to $CATALINA_HOME

RUN useradd --no-log-init -U ldh && \
    chown -R ldh:ldh . && \
    chown -R ldh:ldh /var/linkeddatahub && \
    mkdir -p "${UPLOAD_ROOT}/${UPLOAD_CONTAINER_PATH}" && \
    chown -R ldh:ldh "$UPLOAD_ROOT" && \
    mkdir -p /etc/letsencrypt/staging && \
    chown -R ldh:ldh /etc/letsencrypt/staging

RUN ./import-letsencrypt-stg-roots.sh

USER ldh

ENTRYPOINT ["/bin/bash", "entrypoint.sh"]
