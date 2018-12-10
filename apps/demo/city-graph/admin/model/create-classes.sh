#!/bin/bash

[ -z "$SCRIPT_ROOT" ] && echo "Need to set SCRIPT_ROOT" && exit 1;

if [ "$#" -ne 3 ]; then
  echo "Usage:   $0 $base $cert_pem_file $cert_password" >&2
  echo "Example: $0" 'https://localhost:4443/demo/city-graph/ ../../../../../certs/martynas.stage.localhost.pem Password' >&2
  echo "Note: special characters such as $ need to be escaped in passwords!" >&2
  exit 1
fi

base=$1
cert_pem_file=$(realpath -s $2)
cert_password=$3

pushd . && cd $SCRIPT_ROOT/admin/model

./create-class.sh \
-b "${base}admin/" \
-f "$cert_pem_file" \
-p "$cert_password" \
--uri "${base}ns/domain#BicycleParking" \
--label "Bicycle parking" \
--slug bicycle-parking \
--sub-class-of "https://schema.org/CivicStructure" \
--path "{isPrimaryTopicOf.slug}" \
--fragment "this"

./create-class.sh \
-b "${base}admin/" \
-f "$cert_pem_file" \
-p "$cert_password" \
--uri "${base}ns/domain#ChartingStation" \
--label "Charging station" \
--slug charging-station \
--sub-class-of "https://schema.org/CivicStructure" \
--path "{isPrimaryTopicOf.slug}" \
--fragment "this"

./create-class.sh \
-b "${base}admin/" \
-f "$cert_pem_file" \
-p "$cert_password" \
--uri "${base}ns/domain#Library" \
--label "Library" \
--slug library \
--sub-class-of "https://schema.org/Library" \
--path "{isPrimaryTopicOf.slug}" \
--fragment "this"

./create-class.sh \
-b "${base}admin/" \
-f "$cert_pem_file" \
-p "$cert_password" \
--uri "${base}ns/domain#ParkingFacility" \
--label "Parking facility" \
--slug parking-facility \
--sub-class-of "https://schema.org/ParkingFacility" \
--path "{isPrimaryTopicOf.slug}" \
--fragment "this"

./create-class.sh \
-b "${base}admin/" \
-f "$cert_pem_file" \
-p "$cert_password" \
--uri "${base}ns/domain#Place" \
--label "Place" \
--slug place \
--sub-class-of "https://schema.org/CivicStructure" \
--path "{isPrimaryTopicOf.slug}" \
--fragment "this"

./create-class.sh \
-b "${base}admin/" \
-f "$cert_pem_file" \
-p "$cert_password" \
--uri "${base}ns/domain#Playground" \
--label "Playground" \
--slug playground \
--sub-class-of "https://schema.org/Playground" \
--path "{isPrimaryTopicOf.slug}" \
--fragment "this"

./create-class.sh \
-b "${base}admin/" \
-f "$cert_pem_file" \
-p "$cert_password" \
--uri "${base}ns/domain#School" \
--label "School" \
--slug school \
--sub-class-of "https://schema.org/School" \
--path "{isPrimaryTopicOf.slug}" \
--fragment "this"

./create-class.sh \
-b "${base}admin/" \
-f "$cert_pem_file" \
-p "$cert_password" \
--uri "${base}ns/domain#SportsCenter" \
--label "Sports center" \
--slug sports-center \
--sub-class-of "https://schema.org/CivicStructure" \
--path "{isPrimaryTopicOf.slug}" \
--fragment "this"

./create-class.sh \
-b "${base}admin/" \
-f "$cert_pem_file" \
-p "$cert_password" \
--uri "${base}ns/domain#PublicToilet" \
--label "Toilet" \
--slug public-toilet \
--sub-class-of "http://schema.org/PublicToilet" \
--path "{isPrimaryTopicOf.slug}" \
--fragment "this"

popd