#!/bin/bash

[ -z "$SCRIPT_ROOT" ] && echo "Need to set SCRIPT_ROOT" && exit 1;

if [ "$#" -ne 3 ]; then
  echo "Usage:   $0 -b $base $cert_pem_file $cert_password" >&2
  echo "Example: $0" 'https://linkeddatahub.com/atomgraph/app/ ../../../certs/martynas.localhost.pem Password' >&2
  echo "Note: special characters such as $ need to be escaped in passwords!" >&2
  exit 1
fi

base=$1
cert_pem_file=$(realpath -s $2)
cert_password=$3

pwd=$(realpath -s $PWD)

pushd . && cd $SCRIPT_ROOT/imports

./import-csv.sh \
-b $base \
-f "$cert_pem_file" \
-p "$cert_password" \
--title "Places" \
--query-file "$pwd/queries/copenhagen/places.rq" \
--file "$pwd/files/copenhagen/places.csv" \
--action "${base}copenhagen/places/"

./import-csv.sh \
-b $base \
-f "$cert_pem_file" \
-p "$cert_password" \
--title "Bicycle parkings" \
--query-file "$pwd/queries/copenhagen/bicycle-parkings.rq" \
--file "$pwd/files/copenhagen/bicycle-parkings.csv" \
--action "${base}copenhagen/bicycle-parkings/"

./import-csv.sh \
-b $base \
-f "$cert_pem_file" \
-p "$cert_password" \
--title "Electric car chargers" \
--query-file "$pwd/queries/copenhagen/charging-stations.rq" \
--file "$pwd/files/copenhagen/charging-stations.csv" \
--action "${base}copenhagen/charging-stations/"

./import-csv.sh \
-b $base \
-f "$cert_pem_file" \
-p "$cert_password" \
--title "Libraries" \
--query-file "$pwd/queries/copenhagen/libraries.rq" \
--file "$pwd/files/copenhagen/libraries.csv" \
--action "${base}copenhagen/libraries/"

./import-csv.sh \
-b $base \
-f "$cert_pem_file" \
-p "$cert_password" \
--title "Parking facilities" \
--query-file "$pwd/queries/copenhagen/parking-facilities.rq" \
--file "$pwd/files/copenhagen/parking-facilities.csv" \
--action "${base}copenhagen/parking-facilities/"

./import-csv.sh \
-b $base \
-f "$cert_pem_file" \
-p "$cert_password" \
--title "Playgrounds" \
--query-file "$pwd/queries/copenhagen/playgrounds.rq" \
--file "$pwd/files/copenhagen/playgrounds.csv" \
--action "${base}copenhagen/playgrounds/"

./import-csv.sh \
-b $base \
-f "$cert_pem_file" \
-p "$cert_password" \
--title "Schools" \
--query-file "$pwd/queries/copenhagen/schools.rq" \
--file "$pwd/files/copenhagen/schools.csv" \
--action "${base}copenhagen/schools/"

./import-csv.sh \
-b $base \
-f "$cert_pem_file" \
-p "$cert_password" \
--title "Sports centers" \
--query-file "$pwd/queries/copenhagen/sports-centers.rq" \
--file "$pwd/files/copenhagen/sports-centers.csv" \
--action "${base}copenhagen/sports-centers/"

./import-csv.sh \
-b $base \
-f "$cert_pem_file" \
-p "$cert_password" \
--title "Public toilets" \
--query-file "$pwd/queries/copenhagen/public-toilets.rq" \
--file "$pwd/files/copenhagen/public-toilets.csv" \
--action "${base}copenhagen/public-toilets/"

./import-csv.sh \
-b $base \
-f "$cert_pem_file" \
-p "$cert_password" \
--title "Denmark postal areas" \
--query-file "$pwd/queries/postal-areas.rq" \
--file "$pwd/files/postal-areas.csv" \
--action "${base}postal-areas/"

popd