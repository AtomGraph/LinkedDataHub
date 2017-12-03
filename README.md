This repository is for:
* client shell scripts that can be used to automate LDH tasks
* public LDH datasets and files such as those from the [Documentation](https://linkeddatahub.com/docs/) app
* reported LDH [issues](../../issues)

Client scripts
==============

Most scripts corresponds to a single atomic request to LinkedDataHub. Some of the scripts combine others into one task with multiple interdependent requests.

Authentication is done using PKCS12 client certificates, which are provided during [signup](https://linkeddatahub.com/docs/getting-started#sign-up).

[Apache Jena](https://jena.apache.org/) must be installed and `$JENAROOT` must be available for most scripts in order to be able to convert between RDF formats.

Written in Linux shell. Tested on Ubuntu (Windows Linux Subsystem).

Atomic
------

* [Create container](scripts/create-container.sh)
* [Apps](scripts/apps)
    * [Create context](scripts/apps/create-context-app.sh)
    * [Create end-user](scripts/apps/create-end-user-app.sh)
    * [Create admin](scripts/apps/create-admin-app.sh)
    * [Create Dydra service](scripts/apps/create-dydra-service.sh)
* [Imports](scripts/imports)
    * [Create file](scripts/imports/create-file.sh)
    * [Create query](scripts/imports/create-query.sh)
    * [Create CSV import](scripts/imports/create-csv-import.sh)

Usage example:

    https://linkeddatahub.com/my-context/my-dataspace/ linkeddatahub.pem Password "Friends" construct_friends.rq "friends.csv" https://linkeddatahub.com/my-context/my-dataspace/friends/

Tasks
-----

* [Apps](scripts/apps)
    * [Create context with Dydra services](scripts/apps/create-context-dydra.sh)
    * [Create dataspace with Dydra services](scripts/apps/create-dataspace-dydra.sh)
* [Imports](scripts/imports)
    * [Import CSV data](scripts/imports/import-csv.sh)

Usage example:

    https://linkeddatahub.com/my-context/ linkeddatahub.pem Password "My dataspace" my-dataspace https://linkeddatahub.com/my-context/my-dataspace/ http://dydra.com/my-dataspace/admin-prod AdminServiceUser AdminServicePassword http://dydra.com/my-dataspace/prod EndUserServiceUser EndUserServicePassword