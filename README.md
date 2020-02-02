# The Knowledge Graph management system

_LinkedDataHub_ (LDH) is open source software you can use to manage data, create visualizations and build apps on RDF Knowledge Graphs.

![AtomGraph LinkedDataHub screenshot](https://raw.github.com/AtomGraph/LinkedDataHub/master/screenshot.png)

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
OWNER_KEY_PASSWORD=changeit
```
4. Run this from command line:
```
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

After a successful startup, the last line of the Docker log should read:

    linkeddatahub_1    | 02-Feb-2020 02:02:20.200 INFO [main] org.apache.catalina.startup.Catalina.start Server startup in 3420 ms

Notes:
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

## Configuration

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

Dataspaces are configured in `config/system.trig`. Their base URIs need to be aligned to the base URI configured in the `.env` file.

Reusing the `https://ec2-54-235-229-141.compute-1.amazonaws.com/linkeddatahub/` as the new base URI, the easiest way is to simple replace the default `https://localhost:4443/` value with it. It can be done using the following shell command:
```
sed -i 's/https:\/\/localhost:4443\//https:\/\/ec2-54-235-229-141.compute-1.amazonaws.com\/linkeddatahub\//g' config/system.trig
```
Note that `sed` requires to escape forward slashes `/` with backslashes `\`.

## Reset

If you need to start fresh and wipe the existing setup (e.g. after configuring a new base URI), you can do that using
```
sudo rm -rf certs data && docker-compose down -v
```

This will remove the persisted data, server and owner certificates as well as their Docker volumes.

## [Documentation](https://linkeddatahub.com/linkeddatahub/docs/)

## [Demo applications](https://github.com/AtomGraph/LinkedDataHub-Apps)

## Test suite

LinkedDataHub includes a basic HTTP [test suite](https://github.com/AtomGraph/LinkedDataHub/tree/master/http-tests).

[![Build status](https://api.travis-ci.org/AtomGraph/LinkedDataHub.svg?branch=master)](https://travis-ci.org/AtomGraph/LinkedDataHub)

## Dependencies

* [Jersey](https://eclipse-ee4j.github.io/jersey/)
* [XOM](http://www.xom.nu)
* [JavaMail](https://javaee.github.io/javamail/)
* [Guava](https://github.com/google/guava)
* [CSV2RDF](https://github.com/AtomGraph/CSV2RDF)
* [Processor](https://github.com/AtomGraph/Processor)
* [Web-Client](https://github.com/AtomGraph/Web-Client)

## Support

Please [report issues](https://github.com/AtomGraph/LinkedDataHub/issues) if you've encountered a bug or have a feature request.

Commercial consulting, development, and support are available from [AtomGraph](https://atomgraph.com).

## Community

* [@atomgraphhq](https://twitter.com/atomgraphhq)
* W3C [Declarative Linked Data Apps Community Group](http://www.w3.org/community/declarative-apps/)