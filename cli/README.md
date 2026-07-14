# LinkedDataHub CLI

`ldh` is a command line interface for the [LinkedDataHub](https://github.com/AtomGraph/LinkedDataHub) HTTP API.
It mirrors the shell scripts in [`bin/`](../bin) one command per script, with the same option names,
implemented in Java on top of AtomGraph [Core](https://github.com/AtomGraph/Core)'s `GraphStoreClient`
(picocli + Apache Jena). It replaces the scripts' external dependencies (`curl`, `turtle`, `python`,
`uuidgen`, `shasum`) with a single executable jar.

## Build

Requires Java 21 and Maven:

```bash
cd cli
mvn package
```

This produces the self-contained `target/ldh.jar`. The `cli/bin/ldh` launcher runs it:

```bash
export PATH="$PATH:$(pwd)/bin"
ldh --help
```

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
| `admin/packages/install-package.sh` | `ldh admin packages install-package` |
| `admin/packages/uninstall-package.sh` | `ldh admin packages uninstall-package` |
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

### Differences from the scripts

- `-f/--cert-pem-file` is now `-f/--cert-file` and takes the `.p12` keystore directly — no
  PEM conversion needed.
- `create-group` writes the `--name` value into `foaf:name`/`dct:title` (the script wrote an
  unset variable, producing empty literals).
- `add-generic-service` drops the documented-but-unparsed `--slug` option.
- `add-csv-import`/`import-csv` default `--delimiter` to `,` (the script required it despite
  documenting a default).
- `install-package`/`uninstall-package` print nothing on success instead of the raw HTTP status
  code; use the exit code.
- `import-csv`/`import-rdf` run their steps in-process instead of spawning subscripts, and pass
  `--description` through to the import metadata.
