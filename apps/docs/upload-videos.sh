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
--title "Create" \
--file-slug f003180f-8a2e-42b9-95bc-65f867437814 \
--file "files/videos/Create.webm" \
--file-content-type "video/webm"

$SCRIPT_ROOT/imports/create-file.sh \
-b $base \
-f "$cert_pem_file" \
-p "$cert_password" \
--title "Delete" \
--file-slug 392fc070-1758-4df0-9175-3c96ec9d7fb8 \
--file "files/videos/Delete.webm" \
--file-content-type "video/webm"

$SCRIPT_ROOT/imports/create-file.sh \
-b $base \
-f "$cert_pem_file" \
-p "$cert_password" \
--title "Download" \
--file-slug 9304378f-da32-4863-8cd9-daeb25e14a58 \
--file "files/videos/Download.webm" \
--file-content-type "video/webm"

$SCRIPT_ROOT/imports/create-file.sh \
-b $base \
-f "$cert_pem_file" \
-p "$cert_password" \
--title "Edit" \
--file-slug e53bdca0-976c-4b3a-9088-377c077b9be2 \
--file "files/videos/Edit.webm" \
--file-content-type "video/webm"

$SCRIPT_ROOT/imports/create-file.sh \
-b $base \
-f "$cert_pem_file" \
-p "$cert_password" \
--title "Search" \
--file-slug 82dd951c-175a-4b4f-81ee-b70e636c8a04 \
--file "files/videos/Search.webm" \
--file-content-type "video/webm"

$SCRIPT_ROOT/imports/create-file.sh \
-b $base \
-f "$cert_pem_file" \
-p "$cert_password" \
--title "Upload" \
--file-slug 5d655191-accc-4b9e-badc-99fc946a09e5 \
--file "files/videos/Upload.webm" \
--file-content-type "video/webm"

$SCRIPT_ROOT/imports/create-file.sh \
-b $base \
-f "$cert_pem_file" \
-p "$cert_password" \
--title "View" \
--file-slug 2c9b4a31-0972-4090-8c81-92a3de002e0c \
--file "files/videos/View.webm" \
--file-content-type "video/webm"