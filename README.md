This repository is for:
* CLI shell scripts that can be used to automate LDH tasks
* public LDH datasets and files such as those from the [Demo](https://linkeddatahub.com/demo/) context
* reported LDH [issues](../../issues)

Command line interface (CLI)
============================

Most scripts corresponds to a single atomic request to LinkedDataHub. Some of the scripts combine others into one task with multiple interdependent requests.

Dependencies
------------

* Java - required by Jena
* [Apache Jena](https://jena.apache.org/) - must be installed and `$JENAROOT` must be available for most scripts in order to be able to convert between RDF formats
* [Python](https://www.python.org/) 2.x - must be installed so that the scripts can do URL-encoding using `urllib.quote()`
* [curl](https://curl.haxx.se/) - command line HTTP client

Written for bash shell. Tested on Ubuntu 16.04.3 LTS (Windows Linux Subsystem).

Usage
-----

You can execute each script without parameters and it will print out what parameters it accepts.

Authentication is done using client certificates, which are provided during [signup](https://linkeddatahub.com/docs/getting-started#sign-up).
Note that `curl` uses PEM as the certificate format, rather than PKCS12 issued by LinkedDataHub. You can easily convert from PKCS12 to PEM using this one-liner (OpenSSL should
be installed together with curl):

    openssl pkcs12 -in cert.p12 -out cert.pem

### Atomic commands

Atomic commands are focused on performing a single request, such as creating a document or an application.

* [Create document](scripts/create-document.sh)
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

### Tasks

Tasks consist of multiple chained commands, e.g. creating a service, then creating an app that uses that service etc.

* [Apps](scripts/apps)
    * [Create context with Dydra services](scripts/apps/create-context-dydra.sh)
    * [Create dataspace with Dydra services](scripts/apps/create-dataspace-dydra.sh)
* [Imports](scripts/imports)
    * [Import CSV data](scripts/imports/import-csv.sh)

Usage example:

    https://linkeddatahub.com/my-context/ linkeddatahub.pem Password "My dataspace" my-dataspace https://linkeddatahub.com/my-context/my-dataspace/ http://dydra.com/my-dataspace/admin-prod AdminServiceUser AdminServicePassword http://dydra.com/my-dataspace/prod EndUserServiceUser EndUserServicePassword
