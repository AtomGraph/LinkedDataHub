#!/bin/bash

pushd . && cd ./admin/acl

printf "\n### Creating authorization to make the app public\n\n"

./make-public.sh "$@"

printf "\n### Make Instrument documents publicly readable\n\n"

./create-authorizations.sh "$@"

cd ../sitemap

printf "\n### Creating template queries\n\n"

./create-queries.sh "$@"

printf "\n### Creating parameters\n\n"

./create-parameters.sh "$@"

printf "\n### Creating templates\n\n"

./create-templates.sh "$@"

printf "\n### Clearing ontologies\n\n"

./clear-ontologies.sh "$@"

popd

printf "\n### Creating containers\n\n"

./create-containers.sh "$@"