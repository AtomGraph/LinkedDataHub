# LinkedDataHub CLI

`ldh` is a command line interface for the [LinkedDataHub](https://github.com/AtomGraph/LinkedDataHub) HTTP API.
It mirrors the shell scripts in [`bin/`](../bin) one command per script, with the same option names,
implemented in Java on top of AtomGraph [Core](https://github.com/AtomGraph/Core)'s `GraphStoreClient`
(picocli + Apache Jena). It replaces the scripts' external dependencies (`curl`, `turtle`, `python`,
`uuidgen`, `shasum`) with a single executable jar.

The `bin/` HTTP API scripts it replaces are deprecated. The [http-tests](../http-tests) suite builds
all of its fixtures with `ldh`, so the commands are exercised against a live instance on every CI run;
`run.sh` aborts if `ldh` is not on `PATH`.

## Install

Every LinkedDataHub release attaches an `ldh-<version>.tar.gz` archive holding the launcher and the
jar. It needs a Java 21 runtime and nothing else:

```bash
tar -xzf ldh-<version>.tar.gz
export PATH="$PWD/ldh-<version>:$PATH"
ldh --help
```

## Build

Building from source requires Java 21 and Maven. From the repository root:

```bash
make cli
```

which prints the `export PATH=...` line to run afterwards. It is the equivalent of:

```bash
cd cli
mvn package
export PATH="$PWD/bin:$PATH"
```

This produces the self-contained `target/ldh.jar`, which the `cli/bin/ldh` launcher runs. The
launcher prefers `LDH_JAR`, then a jar sitting beside it (the release archive layout), then
`../target/ldh.jar` (the source checkout layout).

The launcher starts the JVM with `-XX:TieredStopAtLevel=1 -XX:+UseSerialGC`, trading peak
throughput for startup time — a command exits long before C2 could pay for itself, and spends
most of its life waiting on HTTP. `LDH_JAVA_OPTS` replaces those flags outright.

The CLI carries the same version as the platform: it ships with a LinkedDataHub release and is
exercised by the same http-tests, so `cli/pom.xml` tracks the root `pom.xml`. `release.sh` keeps
the two in step across the release bumps, and `make cli-version` sets `cli/pom.xml` from the
platform version if they ever drift.

`ldh --version` reports the version the jar was built at, read back from its `Implementation-Version`
manifest entry.

## Authentication

Commands authenticate with a WebID client certificate from a **PKCS12 (.p12) keystore** — the format
produced by `bin/webid-keygen.sh`:

```bash
ldh get --accept text/turtle \
  -f ssl/owner/keystore.p12 -p "$OWNER_CERT_PWD" \
  https://localhost:4443/
```

Server certificates are not validated (equivalent of `curl -k`), matching the shell scripts'
behavior against self-signed development instances.

### Environment variable defaults

Repeated options can be set once via environment variables:

| Variable | Option |
|---|---|
| `LDH_CERT_FILE` | `-f`, `--cert-file` |
| `LDH_CERT_PASSWORD` | `-p`, `--cert-password` |
| `LDH_BASE` | `-b`, `--base` |
| `LDH_PROXY` | `--proxy` |

```bash
export LDH_CERT_FILE=ssl/owner/keystore.p12 LDH_CERT_PASSWORD=... LDH_BASE=https://localhost:4443/

ldh create-container --parent "$LDH_BASE" --title "Some" --slug some
ldh create-item --container https://localhost:4443/some/ --title "My item" --slug my-item
```

## Conventions

- Commands that create or append to a document print its URL as the only line on stdout, so shell
  pipelines keep working: `item=$(ldh create-item ...)`. `add-file` prints the content-addressed
  upload URI (`{base}uploads/{sha1}`). All diagnostics go to stderr.
- Exit codes: `0` success, `1` HTTP error status or runtime failure (message on stderr, stack trace
  with `--verbose`), `2` usage error.
- `--proxy` rewrites the request URI's origin to the proxy's origin, like the scripts do; printed
  URLs keep the logical origin.
- `post`/`put` read RDF from stdin and resolve relative URIs against the target URI (the scripts'
  `turtle --base` piping); `patch` reads a SPARQL 1.1 update from stdin, validates it and sends it
  verbatim.

Shell completion: `source <(ldh generate-completion)` (bash/zsh).

## Script → command migration

| Script | Command |
|---|---|
| `get.sh` | `ldh get` |
| `post.sh` | `ldh post` |
| `put.sh` | `ldh put` |
| `patch.sh` | `ldh patch` |
| `delete.sh` | `ldh delete` |
| `create-item.sh` | `ldh create-item` |
| `create-container.sh` | `ldh create-container` |
| `add-view.sh` | `ldh add-view` |
| `add-construct.sh` | `ldh add-construct` |
| `add-select.sh` | `ldh add-select` |
| `add-result-set-chart.sh` | `ldh add-result-set-chart` |
| `add-file.sh` | `ldh add-file` |
| `add-generic-service.sh` | `ldh add-generic-service` |
| `admin/clear-ontology.sh` | `ldh admin clear-ontology` |
| `admin/add-ontology-import.sh` | `ldh admin add-ontology-import` |
| `admin/ontologies/create-ontology.sh` | `ldh admin ontologies create-ontology` |
| `admin/ontologies/import-ontology.sh` | `ldh admin ontologies import-ontology` |
| `admin/ontologies/add-class.sh` | `ldh admin ontologies add-class` |
| `admin/ontologies/add-constructor.sh` | `ldh admin ontologies add-constructor` |
| `admin/ontologies/add-select.sh` | `ldh admin ontologies add-select` |
| `admin/ontologies/add-property-constraint.sh` | `ldh admin ontologies add-property-constraint` |
| `admin/ontologies/add-restriction.sh` | `ldh admin ontologies add-restriction` |
| `admin/acl/create-group.sh` | `ldh admin acl create-group` |
| `admin/acl/create-authorization.sh` | `ldh admin acl create-authorization` |
| `admin/acl/add-agent-to-group.sh` | `ldh admin acl add-agent-to-group` |
| `admin/acl/make-public.sh` | `ldh admin acl make-public` |
| `content/add-object-block.sh` | `ldh content add-object-block` |
| `content/add-xhtml-block.sh` | `ldh content add-xhtml-block` |
| `content/remove-block.sh` | `ldh content remove-block` |
| `imports/add-csv-import.sh` | `ldh imports add-csv-import` |
| `imports/add-rdf-import.sh` | `ldh imports add-rdf-import` |
| `imports/import-csv.sh` | `ldh imports import-csv` |
| `imports/import-rdf.sh` | `ldh imports import-rdf` |

Local certificate tooling (`webid-keygen.sh`, `webid-keygen-pem.sh`, `webid-uri.sh`,
`webid-modulus.sh`, `server-cert-gen.sh`) and the experimental `sitemap/` generator remain
shell scripts.

Packages have no command: an application imports one with a single `<app> ldh:import <package-uri>`
triple, so `ldh patch` on the application's `/settings` document is the whole interface.

### Differences from the scripts

- `-f/--cert-pem-file` is now `-f/--cert-file` and takes the `.p12` keystore directly — no
  PEM conversion needed.
- `create-group` writes the `--name` value into `foaf:name`/`dct:title` (the script wrote an
  unset variable, producing empty literals).
- `add-generic-service` drops the documented-but-unparsed `--slug` option.
- `add-csv-import`/`import-csv` default `--delimiter` to `,` (the script required it despite
  documenting a default).
- `import-csv`/`import-rdf` run their steps in-process instead of spawning subscripts, and pass
  `--description` through to the import metadata.
- `import-ontology` reads the `construct-constructors` query text by dereferencing its document
  instead of going through a `SELECT` on `/sparql`; the CONSTRUCT it then runs over the scratch
  graph is unchanged.
