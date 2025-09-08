## [5.0.23] - 2025-08-31
### Added
- Drag handles for content blocks - blocks can now only be dragged by their dedicated drag handles
- Client-side `ac:mode` function for layout mode detection
- New `ldh:request-uri` function for URI handling
- Container generation form improvements with optional service field

### Changed
- Layout mode is now retained after RDF file upload
- Promise cleanup and refactoring for better client-side performance
- Modal form validation fixes
- Document context handling improvements
- Removed `ldh:DocumentLoaded` named template for cleaner code

## [5.0.22] - 2025-08-29
### Added
- SPARQL query support for `ProxyResourceBase` via `POST` requests
- YouTube object block support with GRDDL transformation
- New HTTP tests for proxy SPARQL query functionality
- `JSONGRDDLFilter` feature for processing JSON-LD from HTML script elements
- New CLI command for `PATCH` requests
- Self-referencing object detection to prevent infinite loops

### Changed
- Web-Client dependency version bump
- Increased nginx rate limits for better performance
- Uniform `ldh:href` function calls across codebase
- Improved `Link` header parsing and usage fixes
- Adjusted document controls size for better UI
- Enhanced view titles for better user experience
- Improved tests for document property cardinalities
- Removed DBPedia's prefix mapping

### Fixed
- Fixed template match issues
- Improved `dct:modified` handling in Graph `POST` operations
- Fixed error handling for "Document loaded successfully but resource was not found" cases
- HTTP test fixes for better reliability

## [5.0.19] - 2025-07-01
### Fixed
- Form callback invocation

## [5.0.18] - 2025-06-30
### Added
- Proxy parameter tunneling in CLI scripts (`add-object-block.sh`, `add-xhtml-block.sh`)

### Changed
- Web-Client dependency version bump
- Chart form actions now only display when agent has write access
- CLI scripts now rewrite effective URLs back to original hostname when using proxy
- Default configuration now uses `varnish-frontend`
- `MAX_CONTENT_LENGTH` environment variable moved to `.env` file

### Fixed
- Fixed object blocks rendering for non-RDF resources (e.g. images)
- Fixed `rdf:value` cardinality constraint
- Fixed proxied return URL in `post.sh`

## [5.0.17] - 2025-06-23
### Changed
  - Replaced `xsl:value-of` usage in XSLT stylesheets
  - Removed debug output for cleaner production logs

### Fixed
  - Fixed map and chart mode rendering for general Linked Data objects in content mode
  - Refactored date/datetime comparison logic for improved accuracy
  - Fixed `@id` value handling in client-side processing
  - Fixed multiple factory promises per top-level `<div>` element
  - Fixed client-side `ldh:base` function
  - Fixed default datasets to use `ldh:ChildrenView`
  - Fixed `owl:NamedIndividual` case in `.add-constructor` onclick handler

### Removed
  - Removed the unused ldh:createGraph property

## [5.0.16] - 2025-06-15
## Added
- Javadoc comments

## [5.0.15] - 2025-06-15
### Changed
- Inlined nginx and Varnish config templates into `docker-compose.yml`
- SaxonJS 3 bump to 3.0.0-beta-2

### Fixed
- Remove user-supplied `dct:created` values to prevent timestamp conflicts
- XSLT SEF generation in Maven build

## [5.0.14] - 2025-05-25
### Added
- Inline chart save feature for better user experience

### Changed
- Improved template match patterns for better performance

### Fixed
- Fixed action URL in navbar form
- Comment fixes in codebase

## [5.0.13] - 2025-05-12
### Added
- Saxon-JS upgraded from 2.x to 3.x with "suspended promise tree" architecture
- Auto-generation of WebID certificates (owner and secretary) in entrypoint
- Request access modal forms with ACL integration
- Multi-platform Docker images (ARM64 + AMD64) with GitHub Actions
- Modal document editing forms with in-place editing
- Rate limiting and retry logic for HTTP 429 responses with `Retry-After` headers
- Conditional HTTP requests support (`ETag`, `If-None-Match`, preconditions)
- Access control endpoints for authorization management
- Progress indicators for long-running operations
- Drag-and-drop improvements for block reorganization
- SPARQL endpoint read-only access for authenticated agents
- Enhanced form controls with better `datetime-local` rendering
- New HTTP test suite for conditional requests and access endpoints
- Chart creation workflow improvements
- View system overhaul - `ldh:View` now embedded via `ldh:Object`
- Secrets management for Google OAuth credentials
- Enhanced SSL/TLS management with automated keystore generation
- MacOS compatibility improvements

### Changed
- CLI tools reorganization - scripts moved to `bin/` directory with PATH management
- Client-side named templates converted to XPath functions for better composability
- Promise-based rendering for charts, views, and objects
- `ldh:View` is now a "normal" resource instead of content block
- Authorization query optimization for better performance
- Document type injection with dynamic `VALUES` for type-based queries
- Varnish configuration improvements with separate VCL templates
- User-specific content handling with proper cache bypass
- RDF/POST parser improvements for empty values and relative URIs
- SPARQL.js 2.x compatibility with regex fixes for datatype URIs
- Container orchestration with memory limits and better configuration
- Base image updates: `atomgraph/letsencrypt-tomcat:10.1.34`, `atomgraph/fuseki:4.7.0`
- XHTML namespace handling with default `xmlns="http://www.w3.org/1999/xhtml"`
- Block system improvements with better nesting and unique identifiers
- Authorization filter improvements with `SERVICE`-less queries
- Static file optimizations with increased burst limits

### Fixed
- Multiple null pointer exceptions in Java code
- XPath syntax errors in XSLT stylesheets
- Variable naming conflicts and scoping issues
- Certificate permission issues across platforms
- Progress bar visibility and selector issues
- Block rendering and nesting logic
- Form submission and response handling
- Chart rendering and display logic
- View navigation and object loading
- HTTP status code handling (`201 Created`, `308 Permanent Redirect`)
- Double slash URI prevention in requests
- Container CSS and modal sizing issues
- RDFS-specific vocabulary support

### Removed
- `IMPORT_KEEPALIVE` parameter
- Unused `Reserialize` Saxon function (replaced with pure XSLT)
- Debug output from XSLT stylesheets
- Unnecessary `ixsl:http-request` arguments
- Secret environment variables from Dockerfile
- `bs2:RowContent` mode in XSLT

## [4.0.10] - 2024-11-07
### Changed
- Fixed namespace prefix declaration in client-side XSLT

## [4.0.9] - 2024-02-07
### Changed
- Fixed dragging within a map
- Fixed Docker build issue caused by an old Node.js version
- Fixed Login with Google caused by Varnish configuration stripping HTTP cookies

## [4.0.8] - 2023-07-11
### Changed
- Dependency on `com.atomgraph.server` (new module) instead of `com.atomgraph.processor`
- JAX-RS application now registers the `NotAcceptableExceptionMapper` so that the `406 Not Acceptable` responses are mapped correctly
- Ontologies are now cached by default
- Bumped Jena version in Dockerfile from 4.3.2 to 4.7.0 in order to avoid the Log4Shell CVE warning

## [4.0.6] - 2023-07-01
### Added
- (X)HTML writer for SPARQL XML Results

## [4.0.5] - 2023-06-23
### Added
- New Varnish proxy cache between nginx and LinkedDataHub (`varnish-frontend` service) in order to improve performance
- New `lapp:frontendProxy` and `lapp:backendProxy` properties in the LAPP ontology
- `HEALTHCHECK` configuration in Dockerfile (relies on public access to the namespace document)

### Changed
- Fixed content drag and drop logic to only work in content mode and not affect dragging in map and graph modes
- Content drag and drop is only enabled when the authenticated agent has an `acl:Write` authorization for the document
- Improved extensibility of client-side XSLT templates for faceted search and parallax navigation
- When `ENABLE_LINKED_DATA_PROXY=false`, `?uri=` proxy requests will return `405 Method Not Allowed` unless the URI is already cached or mapped to file
- Replaced the `atomgraph/varnish:6.0.11` Docker image with the official `varnish:7.3.0` image
- Replaced the `atomgraph/nginx:1.23.3` Docker image with the official `nginx:1.23.3` image

## [4.0.4] - 2023-06-07
### Changed
- Moved `Cache-Control` header settings from webapp's `web.xml` to nginx's config template

## [4.0.3] - 2023-05-24
### Added
- Option to re-arrange content blocks by drag & drop in content mode (enabled only when the agent has write access)

### Changed
- Instead of writing JSON-LD directly, `schema:BreadCrumbList` mode returns RDF/XML which is then transformed to JSON-LD using `ac:JSON-LD`

## [4.0.2] - 2023-05-08
### Added
- [XML sitemap](https://www.sitemaps.org/protocol.html) generation when env param `GENERATE_SITEMAP=true` is specified (enabled by default)
- JSON-LD output in the `<script>` tag containing [`schema:BreadCrumbList`](https://schema.org/BreadcrumbList) structured data

### Changed
- Content blocks use `@about` attributes as identifiers instead of `@data-content-uri`

## [4.0.1] - 2023-04-23
### Added
- Backlink navigation on XHTML content

### Changed
- Navigation bar is now fully rendered server-side, i.e. the whole visible HTML body is replaced via AJAX
- Generalized client-side navigation templates using XPath maps
- Fixed default `@id` value in `bs2:RowContent` mode

## [4.0.0] - 2023-01-04
### Changed
- Upgraded dependencies to use Jersey 3.x and the Servlet 5 API. That required replacing `javax.*` dependencies with `jakarta.*`
- Upgraded `atomgraph/nginx`, `atomgraph/letsencrypt-tomcat` and `atomgraph/varnish` base images
- `docker-compose.yml` now uses image versions instead of hashes
- Refactored `RDFXML2JSON-LD.xsl` converter uses the XSLT 3.0 JSON instructions instead of string concatenation
- New `<acl/authorizations/public-namespace/#this>` authorization, separate from `<acl/authorizations/public/#this>`
- Fixed editing mode for resources that do not have any `rdf:type` properties
- Replaced all SPARQLBuilder usages for query building with XSLT 3.0 transformations (SPARQLBuilder still used for query serialization)

## [3.3.2] - 2022-12-12
### Added
- A separate HTTP client used only by the Linked Data client, to avoid sharing the connection pool with the main system client
- Linked Data client now sends a `User-Agent` request header impersonating the Firefox browser

### Changed
- `@id` attributes are rewritten and `@href` attributes are resolved against base URI when XHTML content is being transcluded

## [3.3.1] - 2022-11-19
### Changed
- Fixed HTTP connection leak in the `ldh:send-request` function
- Fixed blank node labels and typeaheads in instance creation forms
- Fixed response caching in the container generation logic to make sure fresh content with the new containers is loaded after redirect

## [3.3.0] - 2022-11-16
### Added
- If content resource cannot be loaded from Linked Data, fallback to a `DESCRIBE` query over the local endpoint

### Changed
- Disabled SPARQL updates on the namespace ontology endpoint `/ns`
- Better aligned document's timestamp and breadcrumbs in the navbar
- Constraint violation responses return `422 Unprocessable Entity` instead of `400 Bad Request` (same change in Processor)
- `PUT`/`DELETE` restrictions on root/owner/secretary documents return `405 Method Not Allowed` instead of `400 Bad Request`
- Improved error handling in the modal "Add data" form
- Resources in containers with remote endpoints get `DESCRIBE` query links instead of plain resource URI which would be attempted to load as Linked Data
- Improved `rdf:type` controls in editing mode to enable adding/removing types on instances (except document instances where types are required)

## [3.2.25] - 2022-11-07
### Changed
- Public `acl:Append` access to the namespace ontology which is required because the `ldh:send-request` function sends unauthenticated SPARQL Protocol `POST` requests

## [3.2.24] - 2022-11-07
### Added
- `ldh:send-request` XSLT extension function which allows stylesheets to execute HTTP `POST` requests (e.g. if the query string is too long for `GET`).

### Changed
- Fixed datetime literal conversion from RDF/XML and SPARQL Results XML to Google Chart's `DataTable`
- Fixed encoding of URIs with special characters in HTTP client requests
- Optimized resource-level XSLT modes by consolidating HTTP requests for type/property/constructor/constraint/shape metadata using SPARQL `VALUES`

### Removed
- Fallback to a `DESCRIBE` request in `ProxyResourceBase`
- `$ldh:localGraph`/`$ldh:original` XSLT parameters. XSLT stylesheet now loads the same data over HTTP without the need for special parameters.

## [3.2.23] - 2022-10-31
### Added
- New "Generate containers" feature that loads a schema from a SPARQL service and then generates a container for each class

### Changed
- Fixed regression of multiple RDF types in the typeahead component
- Fixed container result count widget to support remote SPARQL endpoints
- Fixed regression of created/modified timestaps not rendered on documents

## [3.2.22] - 2022-10-26
### Added
- Result count widget for container content

## [3.2.21] - 2022-10-24
### Changed
- Fixed map initialization regression

## [3.2.20] - 2022-10-24
### Added
- An onboarding message show the first time LinkedDataHub starts
- ACL agent URI is passed to the client-side stylesheet as an `$acl:agent` param

### Changed
- Fixed minor signup and request-access UI issues
- Disabling "Save as" and "Delete" action buttons when the agent does not have a write permission

## [3.2.19] - 2022-10-22
### Added
- Support for recursive content blocks

### Changed
- Loading class and property descriptions from the namespace ontology before falling back to Linked Data
- Fixed shapes support for resources with multiple RDF types

## [3.2.18] - 2022-10-19
### Added
- SHACL node shape and property shape creation in the admin app
- Basic support for instance construction from SHACL node shapes

### Changed
- Improved validation of "Add data" and inline content editing forms
- SaxonJS upgraded to v2.5. Client-side XSLT code updated to take advantage of the latest bugfixes.

## [3.2.17] - 2022-09-28
### Added
- Basic support for [HTTP range requests](https://developer.mozilla.org/en-US/docs/Web/HTTP/Range_requests) when serving uploded files (`uploads/{sha1sum}`)

### Changed
- Fixed infinite XSLT loop in the WebID signup flow
- Container UI code only hydrates server-side HTML elements, does not create them if they don't exist
- Parameterized CSS classes in `bs2:RowContent` mode
- `ProxyResourceBase` guards against queries to the backend SPARQL service by requiring that agent is authorized

## [3.2.15] - 2022-09-26
### Changed
- Fixed order by dropdown population for container content
- Fixed and optimized container sorting

### Removed
- Usage of group-sort-triples.xsl because Jena RDF/XML writer takes care of grouping triples and they're sorted during container rendering anyway

## [3.2.14] - 2022-09-21
### Added
- WKT geometry support in map layout mode

## [3.2.13] - 2022-09-16
### Changed
- Fixed query builder behind faceted search to generate a correct query that loads facet values

## [3.2.12] - 2022-09-13
### Added
- Moved RDFXML2DataTable.xsl and SPARQLXMLResults2DataTable.xsl converters from Web-Client

### Changed
- Refactored RDFXML2DataTable.xsl and SPARQLXMLResults2DataTable.xsl using XSLT 3.0 JSON/XML instructions and fixed support for repeating columns

## [3.2.11] - 2022-09-10
### Changed
- Fixed the `[Actions]` button in edit mode to update the constructor list when new types are added to the edited instance
- The ontology import query now adds explicit `rdfs:isDefinedBy` triples that connect classes to the ontology

## [3.2.10] - 2022-09-09
### Changed
- Web-Client upgrade fixes the RDF/XML to DataTable converter

## [3.2.9] - 2022-09-08
### Added
- Map view is fit to the extent of loaded features

### Changed
- Fixed blank node resources rendered as empty elements in `bs2:Row` mode

## [3.2.8] - 2022-09-07
### Changed
- Fixed calculation of center coordinates correctly for all map usages

## [3.2.7] - 2022-09-06
### Changed
- Google Maps and SPARQLMap dependencies replaced with OpenLayers 7.0. All functionality ported except bounding box-based feature loader.

## [3.2.6] - 2022-08-12
### Changed
- Fixed instance creation with multiple `rdf:type`s

## [3.2.5] - 2022-08-11
### Added
- "Actions" button in edit mode allows adding and editing constructors of ontology classes without switching to the admin app
- `xsd:dateTime` literals are rendered as `datetime-local` inputs in edit mode

### Changed
- Fixed `refresh_token` cache to store a token per client ID
- Improved edit mode support for instances that have multiple `rdf:type` properties

### Removed
- Usages of `OntModelReadOnly` which broke RDF/XML writing in Jena: https://github.com/apache/jena/issues/1450

## [3.2.3] - 2022-06-30
### Added
- The persistent storage of `refresh_token`s allows long-lived sessions when authenticated with Google login

### Changed
- Fixed the back button (the history states were being mismanaged)

## [3.2.0] - 2022-06-22
### Added
- Inline creation and editing of container and XHTML content in content layout mode
- ACL access modes sent as `Link` response headers and accessible in the client-side XSLT stylesheets using the `acl:mode` function
- Results of queries that use `forClass` type after a new instance was created are banned from Varnish cache
- `endpoint` URL param can be used to override the SPARQL endpoint that the fallback `DESCRIBE` query gets executed against
- XML literals in SPARQL updates get canonicalized before reaching the SPARQL endpoint

### Changed
- Content model uses `rdf:Seq` and `rdf:_1`, `rdf:_2` ... properties instead of `rdf:List` and `rdf:first`/`rdf:rest`
- SPARQL updates submitted to the Graph Store via the `PATCH` method now have to use the default graph context, the `GRAPH` keyword is disallowed
- Fixed caching of delegated WebID agents, eliminating an unnecessary request with each authentication
- Multiple `Link` headers combined into a single one with concatenated values

## [3.1.9] - 2022-05-23
### Added
- `--fragment` parameter to CLI scripts that can be used to specify the fragment ID of the resource paired with the document (defaults to UUID)
- `ENABLE_LINKED_DATA_PROXY` env parameter that allows disabling the Linked Data proxy/browser (enabled by default)

### Changed
- Fixed double `On-Behalf-Of` header value when both WebID and OIDC agent contexts were delegated
- Fixed Linked Data proxy fallback to a local `DESCRIBE` query when the external URL does not dereference
- Fixed IP address check in the setup script
- Jena upgraded to 4.5.0
- Fuseki Docker image upgraded to 4.5.0
- Saxon-JS upgraded to 2.4
- `key()` lookups enabled in client-side XSLT as HTML page mutations do not break indexes anymore (fixed in [5036](https://saxonica.plan.io/issues/5036))


## [3.1.6] - 2022-05-10
### Added
- Spanish UI localization
- Reconciliation of OIDC accounts with existing agents by email address
- Document tree widget
- New `/clear` endpoint which is used to clear ontologies from memory
- Second nginx port which has WebID client certificate authentication always enabled
- `--proxy` parameter to CLI scripts

### Changed
- Variables in SPARQL query and update strings whose values are injected now start with `$` instead of `?`, for example `$this`
- CSV and RDF imports write data directly to the backend Graph Store
- Only namespace, signup, OAuth2 login, WebID profiles and public keys can be public in admin apps, nothing else (hardcoded in the admin authorization query)
- When graph URI not explicitly specified, the Graph Store always returns `201 Created` (even if the graph existed)
- Fuseki image upgraded to 4.3.2


## [3.0.11] - 2022-03-16
### Added
- Interactivity to the graph SVG layout
- Notifications to the requesting agent when its access request is granted (requires email server)
- JSON-LD export option for documents
- `append-content` CLI script that appends content resources to document
- `create-file` CLI script automatically recognizes the MIME type of the file being uploaded
- Linked Data browser functionality in graph layout mode
- Javadoc comments

### Changed
- The setup script requirements relaxed to make it easier to run on MacOS
- Fixed CSV imports
- Linked Data browser now supports relative URIs
- Upgraded Java from 11 to 17
- A built-in HTTP API constraint does not allow `PUT` on documents without the document description in request body
- A built-in HTTP API constraint does not allow to `DELETE` the root document
- A built-in HTTP API constraint does not allow to `DELETE` or `PUT` the the app owner's and secretary's WebID documents
- Shell script interpreter line

### Removed
- Dydra-specific code


## [3.0.3] - 2022-02-16
### Added
- Ability to copy (fork) RDF data into the local dataspace
- Block-based content layout (`ldh:ContentList` mode) and editor
- Login with Google (OpenID Connect)
- Ability to load JSON-LD data from `<script>` elements in HTML
- Namespace endpoint, which is an in-memory SPARQL endpoint over the app's ontology

### Changed
- The HTTP CRUD API is now Graph Store Protocol, not Linked Data Templates
- HTML documents are hydrated HTML fragments over AJAX
- XSLT stylesheets now load constraints and constructors using SPARQL over the namespace endpoint
- The URIs of ontology terms are not relative to the app's base URI anymore
- Additional assertions added to external ontology terms instead of subclassing them
- Every UI state generates a distinct URL which is loaded consistently on both server- and client-side
- Upgraded Jena to 4.3.2
- Upgraded Saxon-JS to 2.3
- Upgraded Fuseki, Varnish and nginx Docker images

### Removed
- Linked Data Templates support (still supported by Processor)


## [2.2.9] - 2021-04-22
### Added
- HTTP smoke tests for SPARQL endpoint and Graph Store
- HTTP test for RDF import without mapping query
- `add-data.sh` CLI script which POSTs RDF data to URL
- `ExceptionMapper` constructors with injection in order to align with Processor
- An option to override request URI using the `?uri=` URL param, implemented in `ApplicationFilter`
- `Dispatcher` as the new "entrypoint" JAX-RS resource which routes between `ResourceBase` (if app is not empty) and `ProxyResourceBase` (if app is empty)
- Missing XML namespace definitions to client-side XSLT stylesheets
- `$output-json-ld` parameter in `xhtml:Script` template which outputs the RDF document as JSON-LD in the `<script>` element

### Changed
- `select-labelled` query in the end-user dataset to include a default graph pattern
- `spin:query` property is now optional for `apl:RDFImport`
- Entrypoint script logic to load agent metadata only when `$LOAD_DATASETS` is true
- Injecting `Optional<Application>`, `Optional<Service>`, `Optional<Ontology>` instead of `Application`, `Service`, `Ontology`
- Using `javax.inject.Provider<>` for injection into providers that are not in the request scope
- If no application matches request URI, `NotFoundException` is not thrown anymore -- `Optional.empty()` is used as application instead
- Auth filters skipped if the matched application is not an instance of `lapp:EndUserApplication` or `lapp:AdminApplication`
- Simplified `ResourceBase::describe` by removing the `?uri=` indirection logic

### Removed
- Proxy injections from injection factory binders


## [2.1.55] - 2021-03-26
### Added
- varnish-admin service that proxy-caches the fuseki-admin triplestore
- `purge_backend_cache` function to the HTTP test runner script run.sh
- `purge_backend_cache` calls to clear proxy caches before each HTTP script
- `BackendInvalidationFilter` response filter with backend proxy cache invalidation heuristics
- Basic environment variable documentation to README

### Changed
- Upgraded Processor and Web-Client to the latest versions
- Upgraded Saxon-JS to 2.1
- End-user and admin Services passed to import `Executor` instead of `DatasetAccessor`
- Defined HTTP method -> ACL mode mapping as the `AuthorizationFilter.ACCESS_MODES` map

### Removed
- Unused Docker mounts from linkeddatahub service
- `ban()` calls from `ResourceBase` -- now handled by the `BackendInvalidationFilter`

## [2.1.49] - 2021-03-19
### Added
- `apl:baseUri` as a static XSLT stylesheet param

### Changed
- `bs2:PropertyControl` XSLT mode can handle multiple RDF types on a resource
- Replaced error alerts with inline HTML warning blocks
- Refactored `bs2:SignUp` template to make it more extensible

### Removed
- `ORDER BY` in `apl:ResultCounts` mode in client.xsl


## [2.1.28] - 2021-03-06
### Added
- `$request_base` parameter support in scripts allows to use a base URI for HTTP requests which is different from the RDF dataset base URI. Useful when multiple LDH instances on different domains or port numbers are backed by the same dataset. E.g. one with WebID-TLS auth enabled and the other without.
- Dydra-specific `QuadStoreClient` and `GraphStoreClient` with support for [asynchonous GSP requests](https://api.dydra.com/graphstore/asynchronous.html)

### Changed
- Ontology classes that used to be in the `ns:` namespace (`${base}ns#`) moved to `nsds:` (`${base}ns/domain/system#`)
- Ontology classes that used to be in the `def:` namespace (`${base}def#`) moved to `nsdd:` (`${base}ns/domain/default#`)
- `python` usages replaced with `python2` in CLI scripts
- Mounting only `ssl/owner/public.pem` instead of the whole `ssl/owner` folder which includes the private key

### Removed
- Expensive join with the provenance graph from the `laclt:ConstructAgentItem` query. As a result, `dct:created` value is not included in agent's description.
- Unnecessary methods from the `Import` Java interface. Passing arguments directly to `ImportListener` instead
