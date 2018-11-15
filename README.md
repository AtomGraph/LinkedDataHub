LinkedDataHub is a delarative Linked Data application platform that builds on open-source client/server components:
<dl>
  <dt><a href="https://github.com/AtomGraph/Core">Atomgraph Core</a></dt>
  <dd>Generic Linked Data framework for SPARQL tripestore backends</dd>
  <dt><a href="https://github.com/AtomGraph/Processor">AtomGraph Processor</a></dt>
  <dd>Ontology-driven Linked Data processor and server for SPARQL backends</dd>
  <dt><a href="https://github.com/AtomGraph/Web-Client">AtomGraph Web-Client</a></dt>
  <dd>Generic Linked Data browser and UX component framework</dd>
</dl>

This repository is for:
* CLI shell scripts that can be used to automate LDH tasks
* public LDH apps/datasets/files, such as those from the [Demo](https://linkeddatahub.com/demo/) context
* reported LDH [issues](../../issues)

Demo applications
=================

City Graph
----------

![City Graph geospatial view](../../raw/master/apps/demo/city-graph/screenshot.png "City Graph geospatial view")

<dl>
    <dt>Source</dt>
    <dd><a href="../../tree/master/apps/demo/city-graph/">demo/city-graph/</a></dd>
    <dt>Base URI</dt>
    <dd><a href="https://linkeddatahub.com/demo/city-graph/">https://linkeddatahub.com/demo/city-graph/</a></dd>
</dl>

Browser of Copenhagen's geospatial open data, imported from [Open Data København](https://data.kk.dk/). Provides a type-colored geospatial overview. Geo resources provide a view with neighbouring resources included.

Features:
* RDF [import from CSV](../../blob/master/apps/demo/city-graph/import-csv.sh)
* [item template](../../blob/master/apps/demo/city-graph/admin/sitemap/create-templates.sh)
    * [query](../../blob/master/apps/demo/city-graph/admin/sitemap/queries/describe-place.rq) describes not only the requested resource, but also other resources with coordinates in a bounding box around it

SKOS
----

![SKOS editor view](../../raw/master/apps/demo/skos/screenshot.png "SKOS editor view")

<dl>
    <dt>Source</dt>
    <dd><a href="../../tree/master/apps/demo/skos/">demo/skos/</a></dd>
    <dt>Base URI</dt>
    <dd><a href="https://linkeddatahub.com/demo/skos/">https://linkeddatahub.com/demo/skos/</a></dd>
</dl>


Basic SKOS editor. Concepts and concept schemas can be created, edited, and linked with each other. Ontology types have separate URI templates; required instance properties are validated using constraints.

Features:
* domain [classes](../../blob/master/apps/demo/skos/admin/model/create-classes.sh) with
    * [constructors](../../blob/master/apps/demo/skos/admin/model/create-constructors.sh)
    * [constraints](../../blob/master/apps/demo/skos/admin/model/create-constraints.sh)
    * [restrictions](../../blob/master/apps/demo/skos/admin/model/create-restrictions.sh)

Command line interface (CLI)
============================

You can use [LinkedDataHub](https://linkeddatahub.com/docs/about) CLI to execute most of the common tasks that can be performed in the UI, such as application and document creation, file uploads, data import, ontology management etc.

The CLI wraps the [HTTP API](https://linkeddatahub.com/docs/http-api) into a set of shell scripts with convenient parameters. The scripts can be used for testing, automation, scheduled execution and such. It is usually much quicker to perform actions using CLI rather than the [user interace](https://linkeddatahub.com/docs/user-interface), as well as easier to reproduce.

We are continuously expanding and improving the script library. Pull requests and issue reports are welcome!

Most scripts correspond to a single [atomic request](#atomic-commands) to LinkedDataHub. Some of the scripts combine others into a [task](#tasks) with multiple interdependent requests.

If you use [Dydra](https://dydra.com) as the triplestore, you may use the Dydra-specific scripts (they accept a repository URI instead of SPARQL endpoint and graph store URIs). Otherwise, use the generic scripts.

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

    ./create-file https://linkeddatahub.com/my-context/my-dataspace/ \
    -f linkeddatahub.pem \
    -p CertPassword \
    --title "Friends" \
    --file-slug 646af756-a49f-40da-a25e-ea8d81f6d306 \
    --file friends.csv \
    --file-content-type text/csv

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

    ./create-dataspace.sh \
    -b https://linkeddatahub.com/my-context/ \
    -f linkeddatahub.pem \
    -p CertPassword \
    --title "My dataspace" \
    --description "Dataspace for my data" \
    --slug my-dataspace \
    --app-base https://linkeddatahub.com/my-context/my-dataspace/ \
    --admin-endpoint http://localhost:3030/admin/sparql \
    --admin-graph-store http://localhost:3030/admin/data \
    --admin-service-user AdminServiceUser \
    --admin-service-password AdminServicePassword \
    --end-user-endpoint http://localhost:3030/end-user/sparql \
    --end-user-graph-store http://localhost:3030/end-user/data \
    --end-user-service-user EndUserServiceUser \
    --end-user-service-password EndUserServicePassword
