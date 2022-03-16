#!/usr/bin/env bash

# LetsEncrypt staging certs from https://github.com/letsencrypt/website/tree/master/static/certs/staging TO-DO: put into an extending image

for cert in 'letsencrypt-stg-int-e1.der' \
        'letsencrypt-stg-int-e2.der' \
        'letsencrypt-stg-int-r3-cross-signed.der' \
        'letsencrypt-stg-int-r3.der' \
        'letsencrypt-stg-int-r4-cross-signed.der' \
        'letsencrypt-stg-int-r4.der' \
        'letsencrypt-stg-root-dst.der' \
        'letsencrypt-stg-root-x1-signed-by-dst.der' \
        'letsencrypt-stg-root-x1.der' \
        'letsencrypt-stg-root-x2-signed-by-x1.der' \
        'letsencrypt-stg-root-x2.der'; \
do \
    curl "https://raw.githubusercontent.com/letsencrypt/website/master/static/certs/staging/${cert}" -o "/etc/letsencrypt/staging/${cert}" \

    echo "LetsEncrypt staging cert: ${cert}"

    cert_alias=$(echo "$cert" | cut -d '.' -f 1) \

    keytool -import \
        -cacerts \
        -storepass changeit \
        -noprompt \
        -trustcacerts \
        -alias "$cert_alias" \
        -file "/etc/letsencrypt/staging/${cert}"
done