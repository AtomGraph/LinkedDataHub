This repository is for:
* CLI shell scripts that can be used to automate LDH tasks
* public LDH datasets and files such as those from the [Demo](https://linkeddatahub.com/demo/) context
* reported LDH [issues](../../issues)

Command line interface (CLI)
============================

You can use [LinkedDataHub](https://linkeddatahub.com/docs/about) CLI to execute most of the common tasks that can be performed in the UI, such as application and document creation, file uploads, data import etc.

The CLI wraps the [HTTP API](https://linkeddatahub.com/docs/http-api) into a set of shell scripts with convenient parameters. The scripts can be used for testing, automation, scheduled execution and such.
We are continuously expanding and improving the script library. Pull requests and issue reports are welcome!

Most scripts correspond to a single [atomic request](#atomic-commands) to LinkedDataHub. Some of the scripts combine others into a [task](#tasks) with multiple interdependent requests.

Dependencies
------------

Required libraries and environmental variables:
* Java - required by Jena. `$JAVA_HOME` must be set.
* [Apache Jena](https://jena.apache.org/) - must be installed and `$JENA_HOME` and `$PATH` [must be set](https://jena.apache.org/documentation/tools/index.html) for most scripts in order to be able to convert between RDF formats
* [Python](https://www.python.org/) 2.x - must be installed so that the scripts can do URL-encoding using `urllib.quote()`
* [curl](https://curl.haxx.se/) - command line HTTP client

Written for bash shell. Tested on [Ubuntu 16.04.3 LTS (Windows Linux Subsystem)](https://www.microsoft.com/en-us/p/ubuntu-1804/9n9tngvndl3q).

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
    * [Create service](scripts/apps/create-service.sh)
    * [Install dataset](scripts/apps/install-dataset.sh)
    * [Dydra-specific](scripts/apps/dydra)
        * [Create service](scripts/apps/dydra/create-service.sh)
* [Imports](scripts/imports)
    * [Create file](scripts/imports/create-file.sh)
    * [Create query](scripts/imports/create-query.sh)
    * [Create CSV import](scripts/imports/create-csv-import.sh)

Usage example:

    ./create-file https://linkeddatahub.com/my-context/my-dataspace/ linkeddatahub.pem Password "Friends" 44f18281-6afa-408e-a7c4-bad38487f198 646af756-a49f-40da-a25e-ea8d81f6d306 friends.csv text/csv

### Tasks

Tasks consist of multiple chained commands, e.g. creating a service, then creating an app that uses that service etc.

* [Apps](scripts/apps)
    * [Create context](scripts/apps/create-context.sh)
    * [Create dataspace](scripts/apps/create-dataspace.sh)
    * [Install context](scripts/apps/install-context.sh)
    * [Install dataspace](scripts/apps/install-dataspace.sh)
    * [Dydra-specific](scripts/apps/dydra)
        * [Create context](scripts/apps/dydra/create-context.sh)
        * [Create dataspace](scripts/apps/dydra/create-dataspace.sh)
        * [Install context](scripts/apps/dydra/install-context.sh)
        * [Install dataspace](scripts/apps/dydra/install-dataspace.sh)
* [Imports](scripts/imports)
    * [Import CSV data](scripts/imports/import-csv.sh)

Usage example:

    ./create-dataspace.sh https://linkeddatahub.com/my-context/ linkeddatahub.pem Password "My dataspace" my-dataspace https://linkeddatahub.com/my-context/my-dataspace/ http://localhost:3030/admin/sparql http://localhost:3030/admin/data AdminServiceUser AdminServicePassword http://localhost:3030/end-user/sparql http://localhost:3030/end-user/data EndUserServiceUser EndUserServicePassword