FROM maven:3.5.3-jdk-8 as maven

# copy trust manager source code

WORKDIR /usr/src/trust-manager

COPY platform/trust-manager /usr/src/trust-manager

# build trust manager

RUN mvn clean install # builds target/trust-manager-1.0.0-SNAPSHOT.jar

# copy platform source code and POM

WORKDIR /usr/src/platform

COPY src /usr/src/platform/src

COPY pom.xml /usr/src/platform/pom.xml

ARG MAVEN_PROFILE=prod

RUN mvn clean install -P${MAVEN_PROFILE}

# download and extract Jena

ARG JENA_VERSION=3.12.0

ARG JENA_TAR_URL="https://archive.apache.org/dist/jena/binaries/apache-jena-${JENA_VERSION}.tar.gz"

RUN mkdir /jena && \
    curl -SL "$JENA_TAR_URL" | \
    tar -xzf - -C /jena

# ==============================

FROM atomgraph/letsencrypt-tomcat

LABEL maintainer="martynas@atomgraph.com"

# hash of the current commit

ARG SOURCE_COMMIT=

ENV SOURCE_COMMIT=$SOURCE_COMMIT

WORKDIR $CATALINA_HOME

# add XSLT stylesheet that makes changes to server.xml

COPY platform/server.xsl conf/server.xsl

# add XSLT stylesheet that makes changes to ROOT.xml

COPY platform/context.xsl conf/context.xsl

# copy trust manager from the maven stage of the build

COPY --from=maven /usr/src/trust-manager/target/trust-manager-1.0.0-SNAPSHOT.jar lib/ldh-trust-manager.jar

ENV ATOMGRAPH_UPLOAD_ROOT=

ENV PROXY_HOST=

ENV TIMEOUT=20

ENV BASE_URI=

ENV HTTP_PROXY_PORT=80

ENV HTTP_REDIRECT_PORT=443

ENV HTTP_COMPRESSION=on

ENV HTTPS_PROXY_PORT=443

ENV HTTPS_CLIENT_AUTH=want

ENV HTTPS_COMPRESSION=on

ENV P12_FILE="/var/linkeddatahub/server.p12"

ENV PKCS12_KEY_PASSWORD=

ENV PKCS12_STORE_PASSWORD=

ENV SECRETARY_CERT_ALIAS=ldh

ENV SECRETARY_CERT_VALIDITY=36500

ENV CLIENT_KEYSTORE="$CATALINA_HOME/webapps/ROOT/certs/secretary.p12"

ENV CLIENT_TRUSTSTORE="$CATALINA_HOME/webapps/ROOT/certs/secretary.truststore"

ENV OWNER_CERT_ALIAS=root-owner

ENV OWNER_CERT_VALIDITY=36500

ENV OWNER_KEYSTORE="$CATALINA_HOME/webapps/ROOT/certs/owner.p12"

ENV OWNER_URI=

ENV OWNER_DOC_URI=

# copy entrypoint

COPY platform/entrypoint.sh entrypoint.sh

# copy SPARQL query used to get metadata of the root app service from the system dataset

COPY platform/select-root-services.rq.template select-root-services.rq.template

# copy the metadata of the built-in secretary agent

COPY platform/root-secretary.trig.template root-secretary.trig.template

COPY platform/root-owner.trig.template root-owner.trig.template

# define upload container path

ENV UPLOAD_CONTAINER_PATH=uploads

# remove default Tomcat webapps and install xmlstarlet (used for XPath queries) and envsubst (for variable substitution)

RUN rm -rf webapps/* && \
    apt-get update && \
    apt-get install -y xmlstarlet && \
    apt-get install -y gettext-base && \
    apt-get install -y uuid-runtime

# copy webapp config

COPY platform/conf/ROOT.xml conf/Catalina/localhost/ROOT.xml

# copy platform webapp (exploded) from the maven stage of the build

COPY --from=maven /usr/src/platform/target/ROOT webapps/ROOT/

# copy extracted Jena from the maven stage of the build

COPY --from=maven /jena/* /jena

# setup Jena

ENV JENA_HOME=/jena

ENV PATH="${PATH}:${JENA_HOME}/bin"

# persist certificates in a volume

VOLUME /var/linkeddatahub "$CATALINA_HOME/webapps/ROOT/certs"

ENTRYPOINT ["/bin/sh", "entrypoint.sh"]