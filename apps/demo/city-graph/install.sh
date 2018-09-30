#!/bin/bash

pushd . && cd ./admin

printf "\n### Creating authorization to make the app public\n\n"

./make-public.sh "$@"

cd ./sitemap

printf "\n### Creating template queries\n\n"

./create-queries.sh "$@"

printf "\n### Creating templates\n\n"

./create-templates.sh "$@"

printf "\n### Clearing ontologies\n\n"

./clear-ontologies.sh "$@"

popd

popd

printf "\n### Creating containers\n\n"

./create-containers.sh "$@"

printf "\n### Importing CSV data\n\n"

./import-csv.sh "$@"