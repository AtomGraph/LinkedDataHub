#!/bin/bash

[ -z "$SCRIPT_ROOT" ] && echo "Need to set SCRIPT_ROOT" && exit 1;

if [ "$#" -ne 3 ]; then
  echo "Usage:   $0 $base $cert_pem_file $cert_password" >&2
  echo "Example: $0" 'https://localhost/docs/ ../../certs/martynas.localhost.pem Password' >&2
  exit 1
fi

base=$1
cert_pem_file=$(realpath -s $2)
cert_password=$3

$SCRIPT_ROOT/imports/create-file.sh \
-b $base \
-f "$cert_pem_file" \
-p "$cert_password" \
--title "Navigation bar" \
--file-slug f620d901-326b-460f-8cff-cfc3b1e0661f \
--file "files/images/navigation bar.png" \
--file-content-type "image/png"

$SCRIPT_ROOT/imports/create-file.sh \
-b $base \
-f "$cert_pem_file" \
-p "$cert_password" \
--title "Action bar" \
--file-slug 71ba25ed-6d60-45b4-8fb8-30aa11280a05 \
--file "files/images/action.png" \
--file-content-type "image/png"

$SCRIPT_ROOT/imports/create-file.sh \
-b $base \
-f "$cert_pem_file" \
-p "$cert_password" \
--title "Create/edit dialog" \
--file-slug c0fb9127-0fa9-4a0f-a601-e51df318cc5a \
--file "files/images/create edit.png" \
--file-content-type "image/png"

$SCRIPT_ROOT/imports/create-file.sh \
-b $base \
-f "$cert_pem_file" \
-p "$cert_password" \
--title "Layout" \
--file-slug a5adf40f-4594-4246-b088-2dda2f7fa904 \
--file "files/images/layout.png" \
--file-content-type "image/png"

$SCRIPT_ROOT/imports/create-file.sh \
-b $base \
-f "$cert_pem_file" \
-p "$cert_password" \
--title "SPARQL endpoint" \
--file-slug 779b7bbc-0bb3-45ed-9562-19b996378c74 \
--file "files/images/sparql endpoint.jpg" \
--file-content-type "image/jpg"

$SCRIPT_ROOT/imports/create-file.sh \
-b $base \
-f "$cert_pem_file" \
-p "$cert_password" \
--title "LinkedDataHub ontologies" \
--file-slug 0daf8cf5-cc39-4e1f-ab4b-b7fe85eb0e0b \
--file "files/images/ontologies.svg" \
--file-content-type "image/svg+xml"

$SCRIPT_ROOT/imports/create-file.sh \
-b $base \
-f "$cert_pem_file" \
-p "$cert_password" \
--title "Dataspace hierarchy" \
--file-slug 57f6a085-eeb7-4cd8-84b6-a11bfa7893e5 \
--file "files/images/contexts.svg" \
--file-content-type "image/svg+xml"