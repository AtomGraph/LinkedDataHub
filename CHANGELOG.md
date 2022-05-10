## [3.1.5] - 2022-05-10
### Added
- Spanish UI localization
- Reconciliation of OIDC accounts with existing agents by email address
- Document tree widget
- New /clear endpoint which is used to clear ontologies from memory
- Second nginx port which has WebID client certificate authentication always enabled
- `--proxy` parameter to CLI scripts

### Changed
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