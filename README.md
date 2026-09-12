# The *low-code* Knowledge Graph application platform

**_LinkedDataHub_ (LDH) is open source software you can use to manage data, create visualizations and build apps on RDF Knowledge Graphs.**

![LinkedDataHub screenshots](https://github.com/AtomGraph/LinkedDataHub/raw/master/screenshots.png)

What's new in LinkedDataHub v5? Watch this video for a feature overview:
[![What's new in LinkedDataHub v3? Feature overview](https://img.youtube.com/vi/LaOouEYhp_c/0.jpg)](https://www.youtube.com/watch?v=LaOouEYhp_c)

We started the project with the intention to use it for Linked Data publishing, but gradually realized that we've built a multi-purpose data-driven platform.

We are building LinkedDataHub primarily for:
* researchers who need an RDF-native FAIR data environment that can consume and collect Linked Data and SPARQL documents and follows the [FAIR principles](https://www.go-fair.org/fair-principles/)
* developers who are looking for a declarative full stack framework for Knowledge Graph application development, with out-of-the-box UI and API

What makes LinkedDataHub unique is its completely _data-driven architecture_: applications and documents are defined as data, managed using a single generic HTTP API and presented using declarative technologies. The default application structure and user interface are provided, but they can be completely overridden and customized. Unless a custom server-side processing is required, no imperative code such as Java or JavaScript needs to be involved at all.

XHTML documents can be edited in-place using a built-in RDFa-aware rich text editor — annotations link selected text directly to Knowledge Graph terms, embedding machine-readable RDF statements in the markup without leaving the page.

**Follow the [Get started](https://atomgraph.github.io/LinkedDataHub/linkeddatahub/docs/get-started/) guide to LinkedDataHub.** The setup and basic configuration sections are provided below and should get you running.

**LinkedDataHub is also available as a free AWS Marketplace product!** <a href="https://aws.amazon.com/marketplace/pp/prodview-vqbeztc3f2nni" target="_blank"><img src="https://github.com/AtomGraph/LinkedDataHub/raw/master/AWS%20Marketplace.svg" width="160" alt="AWS Marketplace"/></a>  
It takes a few clicks and filling out a form to install the product into your own AWS account. No manual setup or configuration necessary!

## Setup

<details>
  <summary>Click to expand</summary>

### Prerequisites

* `bash` shell 4.x. It should be included by default on Linux. On Windows you can install the [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10).
* [Docker](https://docs.docker.com/install/) installed. At least 8GB of memory dedicated to Docker is recommended.
* [Docker Compose](https://docs.docker.com/compose/install/) installed

#### CLI

The [`ldh` command line interface](#command-line-interface) is attached to every release and needs only a Java 21 runtime; building it from source additionally requires [Maven](https://maven.apache.org/). The certificate and WebID scripts that remain in the `bin/` directory require [`openssl`](https://www.openssl.org/) and `keytool` (part of the JDK).

### Steps

  1. [Fork](https://guides.github.com/activities/forking/) this repository and clone the fork into a folder
  2. In the folder, create an `.env` file and fill out the missing values (you can use [`.env_sample`](https://github.com/AtomGraph/LinkedDataHub/blob/master/.env_sample) as a template). For example:
     ```
     COMPOSE_CONVERT_WINDOWS_PATHS=1
     COMPOSE_PROJECT_NAME=linkeddatahub
     
     PROTOCOL=https
     HTTP_PORT=81
     HTTPS_PORT=4443
     HOST=localhost
     ABS_PATH=/
     
     OWNER_MBOX=john@doe.com
     OWNER_GIVEN_NAME=John
     OWNER_FAMILY_NAME=Doe
     OWNER_ORG_UNIT=My unit
     OWNER_ORGANIZATION=My org
     OWNER_LOCALITY=Copenhagen
     OWNER_STATE_OR_PROVINCE=Denmark
     OWNER_COUNTRY_NAME=DK
     ```
  3. Setup server's SSL certificates by running this from command line:
     ```shell
     ./bin/server-cert-gen.sh .env nginx ssl
     ```
     The script will create an `ssl` sub-folder where the SSL certificates and/or public keys will be placed.
  4. Create the following secrets with certificate/truststore passwords:
     - `secrets/client_truststore_password.txt`
     - `secrets/owner_cert_password.txt`
     - `secrets/secretary_cert_password.txt`
     The one you will need to remember in order to authenticate with LinkedDataHub using WebID client certificate is `owner_cert_password`.
  5. Launch the application services by running this from command line:
     ```shell
     make up -- --build
     ```
     `make up` passes its arguments on to `docker-compose up`. The `--` is required before any argument starting with `-`, otherwise `make` treats it as one of its own options.

     It will build LinkedDataHub's Docker image, start its container and mount the following sub-folders:
     - `ssl`
       * `owner` stores root owner's WebID certificate, keystore, and public key
       * `secretary` stores root application's WebID certificate, keystore, and public key
       * `server` stores the server's certificate (also used by nginx)
     - `data` where the triplestore(s) will persist RDF data
     - `datasets` where LDH persists agent metadata files
     - `uploads` where LDH stores content-hashed file uploads
     It should take up to half a minute as datasets are being loaded into triplestores. After a successful startup you should see periodic healtcheck requests being made to the https://localhost:4443/ns URL.
  6. Install `ssl/owner/keystore.p12` into a web browser of your choice (password is the `owner_cert_password` secret value)
     - Google Chrome: `Settings > Advanced > Manage Certificates > Import...`
     - Mozilla Firefox: `Options > Privacy > Security > View Certificates... > Import...`
     - Apple Safari: The file is installed directly into the operating system. Open the file and import it using the [Keychain Access](https://support.apple.com/guide/keychain-access/what-is-keychain-access-kyca1083/mac) tool (drag it to the `local` section).
     - Microsoft Edge: Does not support certificate management, you need to install the file into Windows. [Read more here](https://social.technet.microsoft.com/Forums/en-US/18301fff-0467-4e41-8dee-4e44823ed5bf/microsoft-edge-browser-and-ssl-certificates?forum=win10itprogeneral).
  7. For authenticated API access use the `ssl/owner/cert.pem` HTTPS client certificate with `curl`, or the `ssl/owner/keystore.p12` keystore beside it with the [`ldh` CLI](#command-line-interface).
     If you are running Linux with user other than `root`, you might need to fix the certificate permissions because Docker bind mounts are owned by `root` by default. For example:
     ```shell
     sudo setfacl -m u:$(whoami):r ./ssl/owner/*
     ```
  8. Open **https://localhost:4443/** in the web browser or use the API, for example:
     ```shell
     curl -k -E ./ssl/owner/cert.pem:<your cert password> -H "Accept: text/turtle" 'https://localhost:4443/'
     ```
     ```shell
     ldh get -f ./ssl/owner/keystore.p12 -p <your cert password> --accept text/turtle 'https://localhost:4443/'
     ```

  ### Notes

  * There might go up to a minute before the web server is available because the nginx server depends on healthy LinkedDataHub and the healthcheck is done every 20s
  * You will likely get a browser warning such as `Your connection is not private` in Chrome or `Warning: Potential Security Risk Ahead` in Firefox due to the self-signed server certificate. Ignore it: click `Advanced` and `Proceed` or `Accept the risk` to proceed.
    * If this option does not appear in Chrome (as observed on some MacOS), you can open `chrome://flags/#allow-insecure-localhost`, switch `Allow invalid certificates for resources loaded from localhost` to `Enabled` and restart Chrome
  * MacOS: Chrome subdomain support: Chrome on macOS requires the server certificate to be installed to the System keychain to properly load resources from dataspace subdomains (e.g., `admin.localhost:4443`). Firefox is more lenient and will work without this step.
    1. Open **Keychain Access** (Applications > Utilities > Keychain Access)
    2. Select **System** keychain in the left sidebar
    3. **File** → **Import Items** → select `ssl/server/server.crt`
    4. Enter your admin password when prompted
    5. Double-click the "localhost" certificate
    6. Expand the **Trust** section
    7. Set "When using this certificate:" to **Always Trust**
    8. Close the window (enter password again)
    9. Completely quit Chrome (Cmd+Q) and restart

    Alternatively, use the command line:
    ```shell
    sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ssl/server/server.crt
    ```
  * `.env_sample` and `.env` files might be invisible in MacOS Finder which hides filenames starting with a dot. You should be able to [create it using Terminal](https://stackoverflow.com/questions/5891365/mac-os-x-doesnt-allow-to-name-files-starting-with-a-dot-how-do-i-name-the-hta) however.
  * On Linux your user may need to be a member of the `docker` group. Add it using
  ```shell
  sudo usermod -aG docker ${USER}
  ```
  and re-login with your user. An alternative, but not recommended, is to run
  ```shell
  sudo make up
  ```
</details>

## Configuration

<details>
  <summary>Click to expand</summary>

  ### Base URI

  A common case is changing the base URI from the default `https://localhost:4443/` to your own.

  Lets use `https://ec2-54-235-229-141.compute-1.amazonaws.com/linkeddatahub/` as an example. We need to split the URI into components and set them in the `.env` file using the following parameters:
  ```
  PROTOCOL=https
  HTTP_PORT=80
  HTTPS_PORT=443
  HOST=ec2-54-235-229-141.compute-1.amazonaws.com
  ABS_PATH=/linkeddatahub/
  ```

  `ABS_PATH` is required, even if it's just `/`.

  ### Dataspaces

  Since version 5.1.0, a single LinkedDataHub instance supports multiple **dataspaces**, each identified by a distinct subdomain (origin). Each dataspace consists of a pair of applications: an end-user app (e.g. `https://northwind-traders.demo.localhost:4443`) and an admin app on the `admin.` subdomain (e.g. `https://admin.northwind-traders.demo.localhost:4443`).

  Dataspace configuration is split across two files:
  - [`config/dataspaces.trig`](https://github.com/AtomGraph/LinkedDataHub/blob/master/config/dataspaces.trig) — public metadata: origins (`lapp:origin`), ontologies, stylesheets
  - [`config/system.trig`](https://github.com/AtomGraph/LinkedDataHub/blob/master/config/system.trig) — internal wiring: SPARQL service bindings and application types (`lapp:AdminApplication`/`lapp:EndUserApplication`)

  To add a new dataspace, add corresponding entries to both files. Relative URIs will be resolved against the base URI configured in the `.env` file.

_:warning: Do not use blank nodes to identify applications or services. We recommend using the `urn:` URI scheme, since LinkedDataHub application resources are not accessible under their own dataspace._

  ### Graph versioning

  Since version 5.9.0, LinkedDataHub can mirror every document of a dataspace into a GitHub repository. Each document (named graph) becomes an N-Triples file, and every write (`POST`/`PUT`/`PATCH`/`DELETE`) becomes a commit authored with the agent's WebID — giving you a full history, audit trail, and undo capability using plain git tooling. Commits happen asynchronously in the background and are best-effort: if GitHub is unavailable or the token is invalid, writes succeed as usual and the failures are only logged.

  Historical versions can be retrieved with the `version` query parameter using a commit SHA:
  ```shell
  curl -k -E ./ssl/owner/cert.pem:<your cert password> -H "Accept: text/turtle" 'https://localhost:4443/my-doc/?version=<commit-sha>'
  ```
  Version responses are immutable and carry a `Memento-Datetime` header with the commit's datetime. They are subject to the same access control as the live document.

  Versioning is **disabled by default**. To enable it for a dataspace:

  1. Create a GitHub repository (a private one is recommended) that will store the graph files.
  2. Obtain an access token: on GitHub, go to **Settings > Developer settings > Personal access tokens > Fine-grained tokens > Generate new token**. Under **Repository access** select **Only select repositories** and pick the repository from step 1; under **Permissions > Repository permissions** set **Contents** to **Read and write**. Generate the token and copy it (it starts with `github_pat_`). A classic token with the `repo` scope works as well, but grants far broader access.
  3. Describe the repository in [`config/system.trig`](https://github.com/AtomGraph/LinkedDataHub/blob/master/config/system.trig) and link the application to it (an example is included in the file):
     ```turtle
     <urn:linkeddatahub:apps/end-user>
     {
         <urn:linkeddatahub:apps/end-user> lapp:versioningRepository <urn:linkeddatahub:versioning/end-user> .
     }

     <urn:linkeddatahub:versioning/end-user>
     {
         <urn:linkeddatahub:versioning/end-user> a doap:GitRepository ;
             doap:location <https://github.com/OWNER/REPO> ;
             github:branch "main" ;
             github:pathPrefix "graphs" .
     }
     ```
  4. Put the token into `secrets/credentials.trig` (create the file if it does not exist) as an `a:authToken` of the repository resource:
     ```turtle
     @prefix a: <https://w3id.org/atomgraph/core#> .

     <urn:linkeddatahub:versioning/end-user>
     {
         <urn:linkeddatahub:versioning/end-user> a:authToken "github_pat_..." .
     }
     ```
  5. Enable the `credentials` secret in `docker-compose.yml` by uncommenting it in the top-level `secrets:` block and in the `linkeddatahub` service's `secrets:` list.
  6. Restart with `make up`. The startup log will confirm: `Graph versioning enabled for application <...>`.

  Multiple dataspaces can be versioned into different repositories with different tokens. The token never appears in the environment or the process table — it is merged into the internal context dataset from the Docker secret, the same mechanism used for SPARQL service credentials.

  ### Secrets

  Secrets used in `docker-compose.yml`:

  <dl>
    <dt><code>owner_cert_password</code></dt>
    <dd>Password of the owner's WebID certificate</dd>
    <dt><code>secretary_cert_password</code></dt>
    <dd>Password of the secretary's WebID certificate</dd>
    <dt><code>client_truststore_password</code></dt>
    <dd>Password of the client truststore</dd>
    <dt><code>google_client_id</code></dt>
    <dd>Google's OAuth client ID</dd>
    <dd>Login with Google authentication is enabled when this value is provided</dd>
    <dt><code>google_client_secret</code></dt>
    <dd>Google's OAuth client secret</dd>
    <dt><code>credentials</code></dt>
    <dd>TriG dataset (<code>secrets/credentials.trig</code>) with service credentials such as SPARQL auth and <a href="#graph-versioning">graph versioning</a> tokens, merged into the system dataset at startup</dd>
  </dl>

  ### Environment

  LinkedDataHub supports a range of configuration options that can be passed as environment parameters in `docker-compose.yml`. The most common ones are:

  <dl>
    <dt><code>CATALINA_OPTS</code></dt>
    <dd>Tomcat's <a href="https://tomcat.apache.org/tomcat-9.0-doc/RUNNING.txt">command line options</a></dd>
    <dt><code>SELF_SIGNED_CERT</code></dt>
    <dd><code>true</code> if the server certificate is self-signed</dd>
    <dt><code>SIGN_UP_CERT_VALIDITY</code></dt>
    <dd>Validity of the WebID certificates of signed up users (<em>not the owner's</em>)</dd>
    <dt><code>IMPORT_KEEPALIVE</code></dt>
    <dd>The period for which the data import can keep an open HTTP connection before it times out, in ms. The larger files are being imported, the longer it has to be in order for the import to complete.</dd>
    <dt><code>MAX_CONTENT_LENGTH</code></dt>
    <dd>Maximum allowed size of the request body, in bytes</dd>
    <dt><code>MAIL_SMTP_HOST</code></dt>
    <dd>Hostname of the mail server</dd>
    <dt><code>MAIL_SMTP_PORT</code></dt>
    <dd>Port number of the mail server</dd>
  </dl>

The options are described in more detail in the [configuration documentation](https://atomgraph.github.io/LinkedDataHub/linkeddatahub/docs/reference/configuration/).

  ## Reset

  If you need to start fresh and wipe the existing setup (e.g. after configuring a new base URI), you can do that using
  ```shell
  make drop
  ```
  It asks for confirmation, then stops the services and removes their volumes before deleting the `datasets`, `fuseki`, `ssl`, and `uploads` folders. Stopping first matters: deleting those folders while the containers are running leaves Fuseki writing into directories that no longer exist.

_:warning: This will **remove the persisted data and files** as well as Docker volumes._
</details>

## [Documentation](https://atomgraph.github.io/LinkedDataHub/linkeddatahub/docs/)

* [Get started](https://atomgraph.github.io/LinkedDataHub/linkeddatahub/docs/get-started/)
* [Reference](https://atomgraph.github.io/LinkedDataHub/linkeddatahub/docs/reference/)
* [User guide](https://atomgraph.github.io/LinkedDataHub/linkeddatahub/docs/user-guide/)

## [Command line interface](https://atomgraph.github.io/LinkedDataHub/linkeddatahub/docs/reference/command-line-interface/)

`ldh` wraps the HTTP API into a single executable with convenient parameters. It can be used for testing, automation, scheduled execution and such. It is usually much quicker to perform actions using the CLI rather than the user interface, as well as easier to reproduce.

Every release attaches an `ldh-<version>.tar.gz` archive, which needs only a Java 21 runtime — no build tools and no source checkout:

```shell
tar -xzf ldh-<version>.tar.gz
export PATH="$PWD/ldh-<version>:$PATH"

ldh --help
```

To build it from source instead — the CLI lives in the [`cli`](https://github.com/AtomGraph/LinkedDataHub/tree/master/cli) subfolder and needs Java 21 and Maven:

```shell
make cli
```

which prints the `export PATH=...` line to run afterwards. If you will be using LinkedDataHub's CLI regularly, add that `export` to your shell profile.

Commands authenticate with a WebID client certificate read from a **PKCS12 keystore** — `ssl/owner/keystore.p12` for the owner. Options that repeat across commands can be set once as environment variables:

```shell
export LDH_CERT_FILE=./ssl/owner/keystore.p12
export LDH_CERT_PASSWORD=$(cat secrets/owner_cert_password.txt)
export LDH_BASE=https://localhost:4443/

ldh create container --parent "$LDH_BASE" --title "Concepts" --slug concepts
ldh create item --container "${LDH_BASE}concepts/" --title "Example" --slug example
```

Commands that create or append to a document print its URL as the only line on stdout, so they compose in shell pipelines: `item=$(ldh create item ...)`. Commands group by verb — `ldh create container`, `ldh add xhtml-block`, `ldh import csv`, `ldh admin create group` — with `import` holding the workflows that compose the atomic commands. See [`cli/README.md`](https://github.com/AtomGraph/LinkedDataHub/blob/master/cli/README.md) for the full command table and the differences from the scripts.

_:warning: The `bin/` HTTP API scripts that `ldh` replaces are **deprecated**. The certificate and WebID tooling (`webid-keygen.sh`, `webid-keygen-pem.sh`, `webid-uri.sh`, `webid-modulus.sh`, `server-cert-gen.sh`) talks to no API and stays in `bin/`._

## Sample applications

### [Demo apps](https://github.com/AtomGraph/LinkedDataHub-Apps)

These demo applications can be installed into a LinkedDataHub instance using `make install`. You will need to provide the path to your WebID certificate as well as its password.

## AI-Powered Automation

### [Web-Algebra](https://github.com/AtomGraph/Web-Algebra)

Web-Algebra enables AI agents to consume Linked Data and SPARQL as well as control and automate LinkedDataHub operations through natural language instructions.
This innovative system translates human language into JSON-formatted RDF operations that can be executed against your LinkedDataHub instance.

**Key capabilities:**
* **Natural Language to RDF Operations**: Translate complex instructions into executable semantic workflows
* **LLM Agent Integration**: AI agents can compose and execute complex multi-step operations automatically
* **Atomic Execution**: Complex workflows are compiled into optimized JSON "bytecode" that executes as a single unit
* **Model Context Protocol (MCP)**: Interactive tools for AI assistants to manage LinkedDataHub content

**Example use cases:**

*Business Analytics:*
> Analyze quarterly sales performance from our Northwind dataset, identify the top 5 customers by revenue, and create an interactive dashboard showing regional sales trends with automated alerts for territories underperforming by more than 15%

*FAIR Life Sciences Integration:*
> Query federated endpoints for protein interaction data from UniProt, gene expression profiles from EBI, and clinical trial outcomes from ClinicalTrials.gov, then integrate these datasets through SPARQL CONSTRUCT queries, create cross-references using shared identifiers, and embed the unified knowledge graph into an interactive research article with live data visualizations

**Perfect for:**
* Business intelligence automation and reporting
* Federated biomedical data integration and analysis
* AI-assisted research data discovery and linking
* Natural language interfaces to knowledge graphs
* Intelligent data processing and monitoring pipelines

See the [Web-Algebra repository](https://github.com/AtomGraph/Web-Algebra) for setup instructions and examples of AI agents managing LinkedDataHub instances.

## How to get involved

* contribute a new LDH application or modify [one of ours](https://github.com/AtomGraph/LinkedDataHub-Apps)
* work on [good first issues](../../contribute)
* work on the features in our [Roadmap](../../wiki/Roadmap)
* join our [community](#community)

## Test suite

LinkedDataHub includes an HTTP [test suite](https://github.com/AtomGraph/LinkedDataHub/tree/master/http-tests), run with `make tests`. It builds its fixtures with `ldh`, which `make tests` builds and puts on the `$PATH` for the run. The server implementation is also covered by the [Processor test suite](https://github.com/AtomGraph/Processor/tree/master/http-tests).

![HTTP-tests](https://github.com/AtomGraph/LinkedDataHub/actions/workflows/http-tests.yml/badge.svg)

## Dependencies

### Browser

* [Saxon-JS](https://www.saxonica.com/saxon-js/)
* [SPARQLBuilder](https://github.com/AtomGraph/sparql-builder)
* [OpenLayers](https://openlayers.org)
* [Google Charts](https://developers.google.com/chart)
* [xml-c14n-sync](https://github.com/AtomGraph/xml-c14n-sync)

### Java

* [Jersey](https://eclipse-ee4j.github.io/jersey/)
* [JavaMail](https://javaee.github.io/javamail/)
* [Guava](https://github.com/google/guava)
* [java-jwt](https://github.com/auth0/java-jwt)
* [ExpiringMap](https://github.com/jhalterman/expiringmap)
* [CSV2RDF](https://github.com/AtomGraph/CSV2RDF)
* [Web-Client](https://github.com/AtomGraph/Web-Client)
* [Twirl](https://github.com/AtomGraph/Twirl)
* [jena-shacl](https://mvnrepository.com/artifact/org.apache.jena/jena-shacl)

### Docker

* [nginx](https://hub.docker.com/_/nginx)
* [varnish](https://hub.docker.com/_/varnish)
* [atomgraph/fuseki](https://hub.docker.com/r/atomgraph/fuseki)
* [namshi/smtp](https://hub.docker.com/r/namshi/smtp)

## Support

Please [report issues](https://github.com/AtomGraph/LinkedDataHub/issues) if you've encountered a bug or have a feature request.

Commercial consulting, development, and support are available from [AtomGraph](https://atomgraph.com).

## Community

* [linkeddatahub@groups.io](https://groups.io/g/linkeddatahub) (mailing list)
* [linkeddatahub/Lobby](https://gitter.im/linkeddatahub/Lobby) on gitter
* [@atomgraphhq](https://twitter.com/atomgraphhq) on Twitter
* [AtomGraph](https://www.linkedin.com/company/atomgraph/) on LinkedIn
* [@atomgraph](https://www.youtube.com/@atomgraph) on YouTube
