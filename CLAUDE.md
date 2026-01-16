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
docker-compose up --build
```

### Core Build Commands
```bash
# Maven build (Java 17 required)
mvn clean install

# Build specific profiles
mvn -Pstandalone clean install  # Standalone WAR
mvn -Pdependency clean install  # JAR dependency
mvn -Prelease clean install     # Release with signing

# Docker-based development
docker-compose up --build                    # Start all services
docker-compose down -v                       # Stop and remove volumes
sudo rm -rf data uploads && docker-compose down -v  # Complete reset
```

### Testing
```bash
# HTTP tests (requires running application)
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

### Service Architecture
The application runs as a multi-container setup:
- **nginx**: Reverse proxy and SSL termination
- **linkeddatahub**: Main Java application (Tomcat)
- **fuseki-admin/fuseki-end-user**: Separate SPARQL stores
- **varnish-frontend/varnish-admin/varnish-end-user**: Caching layers

### Data Flow
1. Requests come through nginx proxy
2. Varnish provides caching layer
3. LinkedDataHub application handles business logic
4. Data persisted to appropriate Fuseki triplestore
5. XSLT transforms data for client presentation

### Key Extension Points
- **Vocabulary definitions** in `com.atomgraph.linkeddatahub.vocabulary`
- **Custom resource handlers** in `com.atomgraph.linkeddatahub.resource`
- **Import processors** in `com.atomgraph.linkeddatahub.imports`
- **XSLT transformations** in `src/main/webapp/static/com/atomgraph/linkeddatahub/xsl`

## CLI Tools
LinkedDataHub includes extensive CLI tools in the `bin/` directory:
- Resource management: `create-container.sh`, `create-item.sh`, `get.sh`, `post.sh`, `put.sh`
- Import functionality: `imports/create-csv-import.sh`, `imports/import-rdf.sh`
- Admin operations: `admin/model/add-class.sh`, `admin/acl/create-authorization.sh`
- Certificate management: `webid-keygen.sh`, `server-cert-gen.sh`

Add CLI tools to PATH for development:
```bash
export PATH="$(find bin -type d -exec realpath {} \; | tr '\n' ':')$PATH"
```

## Development Notes
- Java 17 is required for compilation
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
