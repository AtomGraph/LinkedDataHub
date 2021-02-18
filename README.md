# The Knowledge Graph management system

**_LinkedDataHub_ (LDH) is an open source software you can use to manage data, create visualizations and build apps on RDF Knowledge Graphs.**

![AtomGraph LinkedDataHub screenshot](https://raw.github.com/AtomGraph/LinkedDataHub/master/screenshot.png)

Welcome to LinkedDataHub. We started the project with the intention to use it for Linked Data publishing, but gradually realized that we've built a multi-purpose data-driven platform.

We are building LinkedDataHub for:
* domain experts who work with RDF data and need an accessible low-code publishing, exploration and management tool
* developers who are looking for a declarative full stack framework for web application and API development
* data engineers who need an open-source RDF platform that can be customized for a variety of use cases

What makes LinkedDataHub unique is its completely _data-driven architecture_: applications and documents are defined as data, managed using a single generic HTTP API and presented using declarative technologies. The default application structure and user interface are provided, but they can be completely overridden and customized. Unless a custom server-side processing is required, no imperative code such as Java or JavaScript needs to be involved at all.

**Follow the [Get started](https://linkeddatahub.com/linkeddatahub/docs/get-started/) guide to build your first application on LinkedDataHub.** The setup and basic configuration sections are provided below and should get you running.

## Setup

<details>
  <summary>Click to expand</summary>

### Prerequisites

* `bash` shell. It should be included by default on Linux. On Windows you can install the [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10).
* Java's [`keytool`](https://docs.oracle.com/en/java/javase/11/tools/keytool.html) available on `$PATH`. It comes with the JDK.
* [`openssl`](https://www.openssl.org/) 1.1.x available on `$PATH`
* [Docker](https://docs.docker.com/install/) installed
* [Docker Compose](https://docs.docker.com/compose/install/) installed

### Steps

  1. [Fork](https://guides.github.com/activities/forking/) this repository and clone the fork into a folder
  2. In the folder, create an `.env` file and fill out the missing values (you can use [`.env_sample`](https://github.com/AtomGraph/LinkedDataHub/blob/master/.env_sample) as a template). For example:
     ```
     COMPOSE_CONVERT_WINDOWS_PATHS=1
     COMPOSE_PROJECT_NAME=linkeddatahub
     
     PROTOCOL=https
     PROXY_HTTP_PORT=81
     PROXY_HTTPS_PORT=4443
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
  3. Setup SSL certificates/keys by running this from command line (replace `$owner_cert_pwd` and `$secretary_cert_pwd` with your own passwords):
     ```
     ./scripts/setup.sh .env ssl $owner_cert_pwd $secretary_cert_pwd 3650 
     ```
     The script will create an `ssl` sub-folder where the SSL certificates and/or public keys will be placed.
  4. Launch the application services by running this from command line:
     ```
     docker-compose up
     ```
     LinkedDataHub will start and mount the following sub-folders:
     - `data` where the triplestore(s) will persist RDF data
     - `uploads` where LDH stores content-hashed file uploads
     The first should take around half a minute as datasets are being loaded into triplestores. After a successful startup, the last line of the Docker log should read something like:
     ```
     linkeddatahub_1     | 09-Feb-2021 14:18:10.536 INFO [main] org.apache.catalina.startup.Catalina.start Server startup in [32609] milliseconds
     ```
  5. Install `ssl/owner/keystore.p12` into a web browser of your choice (password is the `$owner_cert_pwd` value supplied to `setup.sh`)
     - Google Chrome: `Settings > Advanced > Manage Certificates > Import...`
     - Mozilla Firefox: `Options > Privacy > Security > View Certificates... > Import...`
     - Apple Safari: The file is installed directly into the operating system. Open the file and import it using the [Keychain Access](https://support.apple.com/guide/keychain-access/what-is-keychain-access-kyca1083/mac) tool.
     - Microsoft Edge: Does not support certificate management, you need to install the file into Windows. [Read more here](https://social.technet.microsoft.com/Forums/en-US/18301fff-0467-4e41-8dee-4e44823ed5bf/microsoft-edge-browser-and-ssl-certificates?forum=win10itprogeneral).
  6. Open **https://localhost:4443/** in that web browser

  ### Notes

  * You will likely get a browser warning such as `Your connection is not private` in Chrome or `Warning: Potential Security Risk Ahead` in Firefox due to the self-signed server certificate. Ignore it: click `Advanced` and `Proceed` or `Accept the risk` to proceed.
    * If this option does not appear in Chrome (as observed on some MacOS), you can open `chrome://flags/#allow-insecure-localhost`, switch `Allow invalid certificates for resources loaded from localhost` to `Enabled` and restart Chrome
  * `.env_sample` and `.env` files might be invisible in MacOS Finder which hides filenames starting with a dot. You should be able to [create it using Terminal](https://stackoverflow.com/questions/5891365/mac-os-x-doesnt-allow-to-name-files-starting-with-a-dot-how-do-i-name-the-hta) however.
  * On Linux your user may need to be a member of the `docker` group. Add it using
  ```
  sudo usermod -aG docker ${USER}
  ```
  and re-login with your user. An alternative, but not recommended, is to run
  ```
  sudo docker-compose up
  ```
</details>

## Configuration

<details>
  <summary>Click to expand</summary>

  ### Base URI

  Besides owner WebID configuration, the most common case is changing the base URI from the default `https://localhost:4443/` to your own.

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

  Dataspaces are configured in [`config/system.trig`](https://github.com/AtomGraph/LinkedDataHub/blob/master/config/system.trig). Relative URIs will be resolved against the base URI configured in the `.env` file.

_:warning: Do not use blank nodes to identify applications or services. We recommend using the `urn:` URI scheme, since LinkedDataHub application resources are not accessible under their own dataspace._

  ## Reset

  If you need to start fresh and wipe the existing setup (e.g. after configuring a new base URI), you can do that using
  ```
  sudo rm -rf data uploads && docker-compose down -v
  ```

_:warning: This will **remove the persisted data and files** as well as Docker volumes._
</details>

## [Documentation](https://linkeddatahub.com/linkeddatahub/docs/)

* [Get started](https://linkeddatahub.com/linkeddatahub/docs/get-started/)
* [Reference](https://linkeddatahub.com/linkeddatahub/docs/reference/)
* [User guide](https://linkeddatahub.com/linkeddatahub/docs/user-guide/)

## [Command line interface](https://linkeddatahub.com/linkeddatahub/docs/reference/command-line-interface/)

LinkedDataHub CLI wraps the HTTP API into a set of shell scripts with convenient parameters. The scripts can be used for testing, automation, scheduled execution and such. It is usually much quicker to perform actions using CLI rather than the user interface, as well as easier to reproduce.

The scripts can be found in the [`scripts`](https://github.com/AtomGraph/LinkedDataHub/tree/master/scripts) subfolder.

_:warning: The CLI scripts internally use [Jena's CLI commands](https://jena.apache.org/documentation/tools/). Set up the Jena environment before running the scripts._

An environment variable `JENA_HOME` is used by all the command line tools to configure the class path automatically for you. You can set this up as follows:

**On Linux / Mac**

    export JENA_HOME=the directory you downloaded Jena to
    export PATH="$PATH:$JENA_HOME/bin"

## [Demo applications](https://linkeddatahub.com/demo/)

**Get the [source code](https://github.com/AtomGraph/LinkedDataHub-Apps)**
_:warning: Before running app installation scripts that use LinkedDataHub's CLI scripts, set the `SCRIPT_ROOT` environmental variable to the [`scripts`](https://github.com/AtomGraph/LinkedDataHub/tree/master/scripts) subfolder of your LinkedDataHub fork or clone._ For example:

    export SCRIPT_ROOT="/c/Users/namedgraph/WebRoot/AtomGraph/LinkedDataHub/scripts"

## How to get involved

* contribute a new LDH application or modify [one of ours](https://github.com/AtomGraph/LinkedDataHub-Apps)
* work on [good first issues](contribute)
* work on the features in our [Roadmap](wiki/Roadmap)
* join our [community](#community)

## Test suite

LinkedDataHub includes an HTTP [test suite](https://github.com/AtomGraph/LinkedDataHub/tree/master/http-tests). The server implementation is also covered by the [Processor test suite](https://github.com/AtomGraph/Processor/tree/master/http-tests).

![HTTP-tests](https://github.com/AtomGraph/LinkedDataHub/workflows/HTTP-tests/badge.svg?branch=master)
![HTTP-tests](https://github.com/AtomGraph/LinkedDataHub/workflows/HTTP-tests/badge.svg?branch=develop)

## Dependencies

* [Jersey](https://eclipse-ee4j.github.io/jersey/)
* [XOM](http://www.xom.nu)
* [JavaMail](https://javaee.github.io/javamail/)
* [Guava](https://github.com/google/guava)
* [java-jwt](https://github.com/auth0/java-jwt)
* [ExpiringMap](https://github.com/jhalterman/expiringmap)
* [CSV2RDF](https://github.com/AtomGraph/CSV2RDF)
* [Processor](https://github.com/AtomGraph/Processor)
* [Web-Client](https://github.com/AtomGraph/Web-Client)

## Support

Please [report issues](https://github.com/AtomGraph/LinkedDataHub/issues) if you've encountered a bug or have a feature request.

Commercial consulting, development, and support are available from [AtomGraph](https://atomgraph.com).

## Community

* [linkeddatahub@groups.io](https://groups.io/g/linkeddatahub) (mailing list)
* [@atomgraphhq](https://twitter.com/atomgraphhq) on Twitter
* [AtomGraph](https://www.linkedin.com/company/atomgraph/) on LinkedIn
* W3C [Declarative Linked Data Apps Community Group](http://www.w3.org/community/declarative-apps/)