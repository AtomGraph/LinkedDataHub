#!/bin/bash

[ -z "$JENA_HOME" ] && echo "Need to set JENA_HOME" && exit 1;

if [ "$#" -ne 3 ]; then
  echo "Usage:   $0 base cert_pem_file cert_password" >&2
  echo "Example: $0" 'https://linkeddatahub.com/my-context/my-dataspace/ linkeddatahub.pem Password' >&2
  exit 1
fi

base=$1
cert_pem_file=$2
cert_password=$3

administration=$(
cat administration.ttl | turtle --base=${base} | $SCRIPT_ROOT/create-document.sh \
-f "$cert_pem_file" \
-p "$cert_password" \
-t "application/n-triples" \
-c "${base}ns/default#Container" \
"$base"
)

cat administration/acl.ttl | turtle --base=${base} | $SCRIPT_ROOT/create-document.sh \
-f "$cert_pem_file" \
-p "$cert_password" \
-t "application/n-triples" \
-c "${base}ns/default#Item" \
"$administration"

sitemap=$(
cat administration/sitemap.ttl | turtle --base=${base} | $SCRIPT_ROOT/create-document.sh \
-f "$cert_pem_file" \
-p "$cert_password" \
-t "application/n-triples" \
-c "${base}ns/default#Container" \
"$administration"
)

cat administration/sitemap/using-ldt-templates.ttl | turtle --base=${base} | $SCRIPT_ROOT/create-document.sh \
-f "$cert_pem_file" \
-p "$cert_password" \
-t "application/n-triples" \
-c "${base}ns/default#Item" \
"$sitemap"

cat administration/sitemap/built-ins.ttl | turtle --base=${base} | $SCRIPT_ROOT/create-document.sh \
-f "$cert_pem_file" \
-p "$cert_password" \
-t "application/n-triples" \
-c "${base}ns/default#Item" \
"$sitemap"

model=$(
cat administration/model.ttl | turtle --base=${base} | $SCRIPT_ROOT/create-document.sh \
-f "$cert_pem_file" \
-p "$cert_password" \
-t "application/n-triples" \
-c "${base}ns/default#Container" \
"$administration"
)

cat administration/model/built-ins.ttl | turtle --base=${base} | $SCRIPT_ROOT/create-document.sh \
-f "$cert_pem_file" \
-p "$cert_password" \
-t "application/n-triples" \
-c "${base}ns/default#Item" \
"$model"

tutorials=$(
cat tutorials.ttl | turtle --base=${base} | $SCRIPT_ROOT/create-document.sh \
-f "$cert_pem_file" \
-p "$cert_password" \
-t "application/n-triples" \
-c "${base}ns/default#Container" \
"$base"
)

cat tutorials/create-dataspace.ttl | turtle --base=${base} | $SCRIPT_ROOT/create-document.sh \
-f "$cert_pem_file" \
-p "$cert_password" \
-t "application/n-triples" \
-c "${base}ns/default#Item" \
"$tutorials"

cat tutorials/import-csv-data.ttl | turtle --base=${base} | $SCRIPT_ROOT/create-document.sh \
-f "$cert_pem_file" \
-p "$cert_password" \
-t "application/n-triples" \
-c "${base}ns/default#Item" \
"$tutorials"

cat tutorials/import-rdf-data.ttl | turtle --base=${base} | $SCRIPT_ROOT/create-document.sh \
-f "$cert_pem_file" \
-p "$cert_password" \
-t "application/n-triples" \
-c "${base}ns/default#Item" \
"$tutorials"

usage=$(
cat usage.ttl | turtle --base=${base} | $SCRIPT_ROOT/create-document.sh \
-f "$cert_pem_file" \
-p "$cert_password" \
-t "application/n-triples" \
-c "${base}ns/default#Container" \
"$base"
)

cat usage/import-data.ttl | turtle --base=${base} | $SCRIPT_ROOT/create-document.sh \
-f "$cert_pem_file" \
-p "$cert_password" \
-t "application/n-triples" \
-c "${base}ns/default#Item" \
"$usage"

cat usage/query-data.ttl | turtle --base=${base} | $SCRIPT_ROOT/create-document.sh \
-f "$cert_pem_file" \
-p "$cert_password" \
-t "application/n-triples" \
-c "${base}ns/default#Item" \
"$usage"

cat about.ttl | turtle --base=${base} | $SCRIPT_ROOT/create-document.sh \
-f "$cert_pem_file" \
-p "$cert_password" \
-t "application/n-triples" \
-c "${base}ns/default#Item" \
"$base"

cat command-line-interface.ttl | turtle --base=${base} | $SCRIPT_ROOT/create-document.sh \
-f "$cert_pem_file" \
-p "$cert_password" \
-t "application/n-triples" \
-c "${base}ns/default#Item" \
"$base"

cat dataset-structure.ttl | turtle --base=${base} | $SCRIPT_ROOT/create-document.sh \
-f "$cert_pem_file" \
-p "$cert_password" \
-t "application/n-triples" \
-c "${base}ns/default#Item" \
"$base"

cat getting-started.ttl | turtle --base=${base} | $SCRIPT_ROOT/create-document.sh \
-f "$cert_pem_file" \
-p "$cert_password" \
-t "application/n-triples" \
-c "${base}ns/default#Item" \
"$base"

cat http-api.ttl | turtle --base=${base} | $SCRIPT_ROOT/create-document.sh \
-f "$cert_pem_file" \
-p "$cert_password" \
-t "application/n-triples" \
-c "${base}ns/default#Item" \
"$base"

cat manage-apps.ttl | turtle --base=${base} | $SCRIPT_ROOT/create-document.sh \
-f "$cert_pem_file" \
-p "$cert_password" \
-t "application/n-triples" \
-c "${base}ns/default#Item" \
"$base"

cat user-interface.ttl | turtle --base=${base} | $SCRIPT_ROOT/create-document.sh \
-f "$cert_pem_file" \
-p "$cert_password" \
-t "application/n-triples" \
-c "${base}ns/default#Item" \
"$base"