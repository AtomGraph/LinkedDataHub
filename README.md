# The Knowledge Graph management system

_LinkedDataHub_ (LDH) is open source software you can use to manage data, create visualizations and build apps on RDF Knowledge Graphs.

LDH features a completely data-driven application architecture: generic server and client components process declarative RDF/OWL, SPARQL, and XSLT instructions.
The default application structure and user interface are provided, making LDH a standalone product, yet they can be completely overridden and customized, thus also making LDH a [low-code application platform](https://en.wikipedia.org/wiki/Low-code_development_platform). Unless a custom processing is required, no imperative code such as Java or JavaScript needs to be involved at all.

## Getting started

1. [Install Docker](https://docs.docker.com/install/)
   - [Install Docker Compose](https://docs.docker.com/compose/install/), if it is not already included in the Docker installation
2. Checkout this repository into a folder
3. In the folder, create an `.env` file and fill out the missing values (you can use [`.env_sample`](https://github.com/AtomGraph/LinkedDataHub/blob/master/.env_sample) as a template). For example:
```
COMPOSE_CONVERT_WINDOWS_PATHS=1
COMPOSE_PROJECT_NAME=linkeddatahub

BASE_URI=https://localhost:4443/

OWNER_MBOX=john@doe.com
OWNER_GIVEN_NAME=John
OWNER_FAMILY_NAME=Doe
OWNER_ORG_UNIT=My unit
OWNER_ORGANIZATION=My org
OWNER_LOCALITY=Copenhagen
OWNER_STATE_OR_PROVINCE=Denmark
OWNER_COUNTRY_NAME=DK
OWNER_KEY_PASSWORD=changeit
```
4. Run this from command line:
```bash
docker-compose up
```
5. LinkedDataHub will start and create the following sub-folders:
   - `certs` where your WebID certificates are stored
   - `data` where the triplestore(s) will persist RDF data
   - `uploads` where LDH stores content-hashed file uploads
6. Install `certs/owner.p12` into a web browser of your choice (password is the `OWNER_KEY_PASSWORD` value)
   - Google Chrome: `Settings > Advanced > Manage Certificates > Import...`
   - Mozilla Firefox: `Options > Privacy > Security > View Certificates... > Import...`
   - Apple Safari: The file is installed directly into the operating system. Open the file and import it using the [Keychain Access](https://support.apple.com/guide/keychain-access/what-is-keychain-access-kyca1083/mac) tool.
   - Microsoft Edge: Does not support certificate management, you need to install the file into Windows. [Read more here](https://social.technet.microsoft.com/Forums/en-US/18301fff-0467-4e41-8dee-4e44823ed5bf/microsoft-edge-browser-and-ssl-certificates?forum=win10itprogeneral).
7. Open **https://localhost:4443/** in that web browser

_You will likely get a browser warning such as `Your connection is not private` in Chrome or `Warning: Potential Security Risk Ahead` in Firefox due to the self-signed server certificate. Ignore it: click `Advanced` and `Proceed` or `Accept the risk` to proceed._

You may need to run the commands as `sudo` or be in the `docker` group.

## [Documentation](https://linkeddatahub.com:4443/linkeddatahub/docs/)

## Demo applications

*TBD*

## Command line interface (CLI)

You can use [LinkedDataHub](https://linkeddatahub.com:4443/linkeddatahub/docs/about/) CLI to execute most of the common tasks that can be performed in the UI, such as application and document creation, file uploads, data import, ontology management etc.

The CLI wraps the [HTTP API](https://linkeddatahub.com:4443/linkeddatahub/docs/http-api/) into a set of shell scripts with convenient parameters. The scripts can be used for testing, automation, scheduled execution and such. It is usually much quicker to perform actions using CLI rather than the [user interace](https://linkeddatahub.com:4443/linkeddatahub/docs/user-interface/), as well as easier to reproduce.

Most scripts correspond to a single [atomic request](#atomic-commands) to LinkedDataHub. Some of the scripts combine others into a [task](#tasks) with multiple interdependent requests.

### Dependencies

Required libraries and environmental variables:
* Java - required by Jena. `$JAVA_HOME` must be set.
* [Apache Jena](https://jena.apache.org/) - must be installed and `$JENA_HOME` and `$PATH` [must be set](https://jena.apache.org/documentation/tools/index.html) for most scripts in order to be able to convert between RDF formats
* [Python](https://www.python.org/) 2.x - must be installed so that the scripts can do URL-encoding using `urllib.quote()`
* [curl](https://curl.haxx.se/) - command line HTTP client

Written for bash shell. Tested on [Ubuntu 16.04.3 LTS (Windows Linux Subsystem)](https://www.microsoft.com/en-us/p/ubuntu-1804/9n9tngvndl3q).

### Usage

You can execute each script without parameters and it will print out what parameters it accepts.

Authentication is done using client certificates, which are provided during [signup](https://linkeddatahub.com:4443/linkeddatahub/docs/getting-started/#sign-up).
Note that `curl` uses PEM as the certificate format, rather than PKCS12 issued by LinkedDataHub. You can easily convert from PKCS12 to PEM using this one-liner (OpenSSL should
be installed together with curl):

    openssl pkcs12 -in cert.p12 -out cert.pem

### Atomic commands

Atomic commands are focused on performing a single request, such as creating a document or an application.

* [Create document](scripts/create-document.sh)
* [Create container](scripts/create-container.sh)
* [Create item](scripts/create-container.sh)
* [Admin](scripts/admin)
    * [Clear ontology](scripts/admin/clear-ontology.sh)
    * [Model](scripts/admin/model)
        * [Create class](scripts/admin/model/create-class.sh)
        * [Create `CONSTRUCT` query](scripts/admin/model/create-construct.sh)
        * [Create property constraint](scripts/admin/model/create-property-constraint.sh)
        * [Create restriction](scripts/admin/model/create-restriction.sh)
    * [Sitemap](scripts/admin/sitemap)
        * [Create `CONSTRUCT` query](scripts/admin/sitemap/create-construct.sh)
        * [Create `DESCRIBE` query](scripts/admin/sitemap/create-describe.sh)
        * [Create template](scripts/admin/sitemap/create-template.sh)
* [Imports](scripts/imports)
    * [Create file](scripts/imports/create-file.sh)
    * [Create query](scripts/imports/create-query.sh)
    * [Create CSV import](scripts/imports/create-csv-import.sh)

Usage example:

    ./create-file https://localhost:4443/my-context/my-dataspace/ \
    -f linkeddatahub.pem \
    -p CertPassword \
    --title "Friends" \
    --file-slug 646af756-a49f-40da-a25e-ea8d81f6d306 \
    --file friends.csv \
    --file-content-type text/csv

### Tasks

Tasks consist of multiple chained commands, e.g. creating a service, then creating an app that uses that service etc.

* [Imports](scripts/imports)
    * [Import CSV data](scripts/imports/import-csv.sh)

Usage example:

    TBD