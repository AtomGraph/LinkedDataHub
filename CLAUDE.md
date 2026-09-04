# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

LinkedDataHub (LDH) is a low-code Knowledge Graph application platform that enables managing data, creating visualizations, and building apps on RDF Knowledge Graphs. It's a completely data-driven platform where applications and documents are defined as data, managed using a single generic HTTP API, and presented using declarative technologies.

## Build System and Development Commands

LinkedDataHub uses Maven as the primary build system with Docker for containerization.

### Development Setup
```bash
# Initial setup (requires .env file configuration)
./bin/server-cert-gen.sh .env nginx ssl
make up -- --build
```

Service credentials (used by the entrypoint for Bearer auth) are stored in `secrets/credentials.trig`.

### Core Build Commands
```bash
# Maven build (Java 21 required)
mvn clean install

# Build specific profiles
mvn -Pstandalone clean install  # Standalone WAR
mvn -Pdependency clean install  # JAR dependency
mvn -Prelease clean install     # Release with signing

# Docker-based development. `make up`/`make down` forward their arguments to
# `docker-compose`; `--` is needed before any argument starting with `-` so make
# does not claim it as one of its own options
make up                                      # Start all services
make up -- --build                           # Rebuild images and start
make up nginx                                # Start named services only
make down                                    # Stop the services
make down -- -v                              # Stop and remove volumes
make drop                                    # Complete reset (down -v, then wipe local dirs)

make cli                                     # Build the ldh CLI, print the PATH export to run
make cli-version                             # Set cli/pom.xml to the platform version in pom.xml
```

### Testing
```bash
# HTTP tests (requires a running application). Depends on the `cli` target, so it builds
# the CLI and puts it on PATH for run.sh, which builds the suite's fixtures with it
make tests  # runs http-tests/run.sh with the certificates and secrets/ passwords

# For other certificates, invoke the runner directly
cd http-tests
./run.sh ssl/owner/cert.pem [password] ssl/secretary/cert.pem [password]

# Test individual suites
find ./document-hierarchy/ -name '*.sh' -exec bash {} \;
```

## Architecture Overview

### Core Application Structure
- **JAX-RS based**: Uses Jersey framework for RESTful web services
- **Multi-application architecture**: Separate admin and end-user applications
- **Data-driven design**: Applications and resources defined as RDF data
- **XSLT-based UI**: Client-side rendering using Saxon-JS with XSLT transformations

### Key Components

#### Applications (`com.atomgraph.linkeddatahub.apps.model`)
- `AdminApplication` - Administrative interface and functions
- `EndUserApplication` - Main user-facing application
- Applications are data-driven and loaded from RDF datasets

#### Security & Authentication (`com.atomgraph.linkeddatahub.server.filter.request.auth`)
- WebID-based authentication with client certificates
- OAuth2 integration (Google)
- Authorization filters and context management
- Multi-level security: Agent, Authorization, and Application filters

#### Data Management (`com.atomgraph.linkeddatahub.model`)
- RDF-native data handling with Jena
- Import/Export functionality for CSV, RDF, and other formats
- SPARQL endpoint integration with separate admin and end-user stores

#### Resource Handling (`com.atomgraph.linkeddatahub.resource`)
- RESTful resource endpoints for CRUD operations
- File upload and content-addressed storage
- Transformation and generation utilities

#### Service Layer
- `ServiceContext` decouples HTTP infrastructure from `Service`, holding dataspace and service metadata separately
- Dataspace metadata and service metadata are split in configuration; types for `lapp:endUserApplication`/`lapp:adminApplication` are inferred on the fly from `system.trig`

### Dataspaces
Since v5.1.0, a single LDH instance supports multiple **dataspaces**, each identified by a distinct subdomain (origin). Each dataspace is a pair of applications: an end-user app (`<subdomain>`) and an admin app (`admin.<subdomain>`), routed by nginx via wildcard subdomain matching.

Configuration is split across two files:
- `config/dataspaces.trig` — public metadata: origins (`lapp:origin`), ontologies (`ldt:ontology`), stylesheets (`ac:stylesheet`)
- `config/system.trig` — internal wiring: maps apps to SPARQL services (`ldt:service`) and assigns types (`lapp:AdminApplication`/`lapp:EndUserApplication`)

Multiple dataspaces can share the same backend SPARQL service.

### Service Architecture
The application runs as a multi-container setup:
- **nginx**: Reverse proxy and SSL termination (wildcard subdomain routing for dataspaces)
- **linkeddatahub**: Main Java application (Tomcat)
- **fuseki-admin/fuseki-end-user**: Separate SPARQL stores
- **varnish-frontend/varnish-admin/varnish-end-user**: Caching layers

### Data Flow
1. Requests come through nginx proxy
2. Varnish provides caching layer
3. LinkedDataHub application handles business logic
4. RDF data is read/written via the **Graph Store Protocol** — each document in the hierarchy corresponds to a named graph in the triplestore; the document URI is the graph name
5. Data persisted to appropriate Fuseki triplestore
6. XSLT transforms data for client presentation

### Linked Data Proxy and Client-Side Rendering

LDH includes a Linked Data proxy that dereferences external URIs on behalf of the browser. The original design rendered proxied resources identically to local ones — server-side RDF fetch + XSLT. This created a DDoS/resource-exhaustion vector: scraper bots routing arbitrary external URIs through the proxy would trigger a full server-side pipeline (HTTP fetch → XSLT rendering) per request, exhausting HTTP connection pools and CPU.

The current design splits rendering by request origin:

- **Browser requests** (`Accept: text/html`): `ProxyRequestFilter` bypasses the proxy entirely. The server returns the local application shell. Saxon-JS then issues a second, RDF-typed request (`Accept: application/rdf+xml`) from the browser.
- **RDF requests** (API clients, Saxon-JS second pass): `ProxyRequestFilter` fetches the external RDF, parses it, and returns it to the caller. No XSLT happens server-side.
- **Client-side rendering**: Saxon-JS receives the raw RDF and applies the same XSLT 3 templates used server-side (shared stylesheet), so proxied resources look almost identical to local ones.

Key implementation files:
- `ProxyRequestFilter.java` — intercepts `?uri=` and `lapp:Dataset` proxy requests; HTML bypass; forwards external `Link` headers
- `ApplicationFilter.java` — registers external proxy target URI in request context (`AC.uri` property) as authoritative proxy marker
- `ResponseHeadersFilter.java` — skips local-only hypermedia links (`sd:endpoint`, `ldt:ontology`, `ac:stylesheet`) for proxy requests; external ones are forwarded by `ProxyRequestFilter`
- `client.xsl` (`ldh:rdf-document-response`) — receives the RDF proxy response client-side; extracts `sd:endpoint` from `Link` header; stores it in `LinkedDataHub.endpoint`
- `functions.xsl` (`sd:endpoint()`) — returns `LinkedDataHub.endpoint` when set (external proxy), otherwise falls back to the local SPARQL endpoint

The SPARQL endpoint forwarding chain ensures ContentMode blocks (charts, maps) query the **remote** app's SPARQL endpoint, not the local one. `LinkedDataHub.endpoint` is reset to the local endpoint by `ldh:HTMLDocumentLoaded` on every HTML page navigation, so there is no stale state when navigating back to local documents.

### UI Conventions

**Form placement follows document membership.** A creation/edit form for a resource that lives (or will live) in its **own document** renders as a modal (`div.modal.modal-constructor` — Container/Item creation, document edit, inline creation in views); a form for a resource being added **to the current document** renders inline in the content body (`ldh:render-add-row-form`, content-block forms). The main content body renders only the current document's content.

### Key Extension Points
- **Vocabulary definitions** in `com.atomgraph.linkeddatahub.vocabulary`
- **Custom resource handlers** in `com.atomgraph.linkeddatahub.resource`
- **Import processors** in `com.atomgraph.linkeddatahub.imports`
- **XSLT transformations** in `src/main/webapp/static/com/atomgraph/linkeddatahub/xsl`

## CLI Tools

`ldh` (in `cli/`) is the command line interface for the HTTP API — one command per `bin/` script,
same option names, grouped by verb (`create`, `add`, `remove`, `import`) plus the `packages`
family and the `admin` scope. Built with Maven on Java 21
into a shaded `cli/target/ldh.jar` that `cli/bin/ldh` launches. See `cli/README.md` for the full
script → command table and the behavioral differences from the scripts.

```bash
cd cli && mvn package && export PATH="$PWD/bin:$PATH"

ldh create container --parent "$LDH_BASE" --title "Some" --slug some
ldh admin add agent --agent "$AGENT_URI" "${ADMIN_BASE}acl/groups/writers/"
```

`cli/` is not a module of the platform reactor (the root pom is the webapp artifact, so it cannot
carry `<modules>`), but it shares the platform's version: `release.sh` runs `versions:set` on it
around both release bumps, and `make cli-version` re-aligns it if it drifts.

`LDH_CERT_FILE`, `LDH_CERT_PASSWORD`, `LDH_BASE` and `LDH_PROXY` supply defaults for `-f`, `-p`,
`-b` and `--proxy`. Commands that create or append to a document print its URL as the only line on
stdout (diagnostics go to stderr), so `item=$(ldh create item ...)` works; exit codes are `0`
success, `1` HTTP or runtime failure, `2` usage error.

Packages are declarative: an application imports one with a single `<app> ldh:import <package>`
triple in its settings, and `ldh packages list`, `ldh packages add` and
`ldh packages remove` write that triple through `PATCH /settings`. `packages list` reads the
registry catalog through the Linked Data proxy, marking the imported ones.

`ldh get` also addresses the RFC 7089 Memento roles of a versioned document, as mutually exclusive
options: `--timemap` (version history), `--version <sha>` (a historical version) and `--timegate`
with an optional `--datetime` (RFC 1123 or ISO 8601), which prints the selected version's URI as the
only line on stdout so it pipes into another `ldh get`.

The `bin/` HTTP API scripts are **deprecated** — `ldh` replaces them, and http-tests build their
fixtures with it. Authentication moves from the `.pem` the scripts feed `curl -E` to the PKCS12
keystore beside it (`-f ssl/owner/keystore.p12`).

Certificate and WebID tooling stays in `bin/` and is not deprecated: `webid-keygen.sh`,
`webid-keygen-pem.sh`, `webid-uri.sh`, `webid-modulus.sh`, `server-cert-gen.sh`.

```bash
export PATH="$(find bin -type d -exec realpath {} \; | tr '\n' ':')$PATH"
```

## Development Notes
- Java 21 is required for compilation (both the platform and the `cli/` project)
- The application uses AtomGraph's Processor and Web-Client libraries as core dependencies
- XSLT stylesheets are processed during build to inline XML entities
- Saxon-JS SEF files are generated during Maven package phase for client-side XSLT
- WebID certificates are required for authenticated API access
- The system expects Jena CLI tools to be available (`JENA_HOME` environment variable)

## Debugging Test Failures

When HTTP tests fail:
1. NEVER speculate about failures - always add debug output first
2. Add echo statements showing:
    - The actual values being tested
    - The expected values
    - HTTP response codes and bodies where relevant
3. Run the test to see actual output
4. Only then diagnose and fix

Example debug pattern:
```bash
result=$(curl ...)
expected="..."
echo "DEBUG: Expected: $expected"
echo "DEBUG: Got: $result"
if [ "$result" != "$expected" ]; then
echo "DEBUG: Mismatch!"
exit 1
fi
