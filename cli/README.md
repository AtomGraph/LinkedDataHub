# LinkedDataHub CLI

`ldh` is a command line interface for the [LinkedDataHub](https://github.com/AtomGraph/LinkedDataHub) HTTP API.
It covers the shell scripts in [`bin/`](../bin) one command per script, with the same option names,
implemented in Java on top of AtomGraph [Core](https://github.com/AtomGraph/Core)'s `GraphStoreClient`
(picocli + Apache Jena). It replaces the scripts' external dependencies (`curl`, `turtle`, `python`,
`uuidgen`, `shasum`) with a single executable jar.

Commands group by verb: `create` `PUT`s a new document, `add` `POST`s an append onto an existing
one, `remove` likewise names the single request it makes, and `import` holds the workflows that
compose the atomic commands. `admin` scopes the same verbs to the admin application, and
`packages` manages the application's package imports:

```bash
ldh create container --parent "$LDH_BASE" --title "Some" --slug some
ldh add view ...
ldh import csv ...                # workflow: add construct + add file + add csv-import
ldh push "$LDH_BASE"              # a directory of RDF documents and files, recursively
ldh admin create ontology ...
ldh packages list
```

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

ldh create container --parent "$LDH_BASE" --title "Some" --slug some
ldh create item --container https://localhost:4443/some/ --title "My item" --slug my-item

# what the document is about: a fragment of the document itself, or a resource described elsewhere
ldh create item --container https://localhost:4443/some/ --title "Coffee" --slug coffee \
    --primary-topic '#this'
ldh create item --container https://localhost:4443/some/ --title "About Bob" --slug about-bob \
    --primary-topic https://example.org/bob#me
```

`--primary-topic` is resolved against the created document's URI, so `'#this'` names a fragment of
that document and an absolute URI names a resource described somewhere else. It is one value, not a
list: `foaf:primaryTopic` is an `owl:FunctionalProperty`, so a second value would not mean a second
topic — it would entail that the two topics are the same resource. It writes the link only; the
topic's own type and properties are the constructor's business, and a vocabulary may refuse a topic
without them (the taxonomy editor package rejects a concept with no `skos:inScheme`).

## Conventions

- Commands that create or append to a document print its URL as the only line on stdout, so shell
  pipelines keep working: `item=$(ldh create item ...)`. `add file` prints the content-addressed
  upload URI (`{base}uploads/{sha1}`). All diagnostics go to stderr.
- `push` writes many documents in one run and prints one line per written document URL or upload
  URI, in write order, so the listing greps and cuts like `packages list` does. Progress
  (`PUT <url> <- <path>`, `POST <url> <- <path>`) and `Skipping <path>` lines go to stderr. On the
  first failed request the run stops with exit code `1`; stdout holds what was written before it.
- Exit codes: `0` success, `1` HTTP error status or runtime failure (message on stderr, stack trace
  with `--verbose`), `2` usage error.
- `--proxy` rewrites the request URI's origin to the proxy's origin, like the scripts do; printed
  URLs keep the logical origin.
- `post`/`put` read RDF from an optional `FILE` argument, recognizing the syntax from its
  extension (`ldh put "$LDH_BASE" root.ttl`), or from stdin, where `-t/--content-type` is
  required since a stream carries no name; either way relative URIs resolve against the target
  URI (the scripts' `turtle --base` piping). `patch` reads a SPARQL 1.1 update from stdin,
  validates it and sends it verbatim.

Shell completion: `source <(ldh generate-completion)` (bash/zsh).

## Memento

`get` also addresses the three [RFC 7089](https://datatracker.ietf.org/doc/html/rfc7089) roles a
document serves when its application is versioned — the version history, a historical version, and
the TimeGate that negotiates between them on datetime. They are mutually exclusive:

```bash
doc=https://localhost:4443/some/

ldh get --accept text/turtle --timemap "$doc"          # version history, described with PROV-O
ldh get --accept application/link-format --timemap "$doc"
ldh get --accept text/turtle --version <sha> "$doc"    # that version, with a Memento-Datetime
```

`--timegate` asks the server which version was current at a given time and prints the selected
version's URI as the only line on stdout, so it composes:

```bash
memento=$(ldh get --timegate --datetime "2026-08-20T10:00:00Z" "$doc")
ldh get --accept text/turtle "$memento"
```

`--datetime` takes either an RFC 1123 (`Wed, 20 Aug 2026 10:00:00 GMT`) or an ISO 8601
(`2026-08-20T10:00:00Z`) datetime, so a `prov:generatedAtTime` read out of a TimeMap can be handed
straight back. Without it the TimeGate selects the most recent version. `--accept` is required for
every other request but not for `--timegate`, whose `302` has no representation of its own.

## Packages

A package bundles an ontology with an optional stylesheet, and an application imports one by
declaring a single `ldh:import` triple in its settings — the declaration *is* the installation.
The commands write that triple; they do not install anything of their own.

```bash
ldh packages list
# available	https://packages.linkeddatahub.com/editor/taxonomy/#this	Taxonomy Editor

ldh packages add --package https://packages.linkeddatahub.com/editor/taxonomy/#this
ldh packages remove --package https://packages.linkeddatahub.com/editor/taxonomy/#this
```

Both take effect on the next request, with no restart: the package ontology joins the
application's `owl:imports` closure and its stylesheet is composed into the application
stylesheet. `packages remove` is idempotent — removing an import the application does not
have succeeds and changes nothing.

`packages list` prints one tab-separated line per package — state, URI, title — so the listing
greps and cuts:

```bash
ldh packages list | grep ^available | cut -f2
```

The registry defaults to `https://packages.linkeddatahub.com/` and `--registry` overrides it. It is
read through the application's Linked Data proxy rather than fetched directly, the same way the
application settings modal reads it, so `packages list` needs `--base` as much as the other two do.

The commands go through `PATCH /settings`, which is the live path: the change is in effect
immediately but lives in the running application's context dataset. Declaring the same
`ldh:import` triple in `config/dataspaces.trig` is the permanent one, applied on restart.

## Push

`push` replays a directory into the document tree it maps to, the [app as a
repository](https://github.com/AtomGraph/LinkedDataHub-Apps) convention: one RDF file per document,
a folder beside it for the files that document holds, and subfolders for its children.

```bash
ldh push "$LDH_BASE"                       # the current directory
ldh push --dir demo/northwind-traders "$LDH_BASE"
ldh push --dry-run "$LDH_BASE"             # print the plan, send nothing
```

With `D` the URL of the directory being walked (`TARGET_URI` for the pushed directory itself):

- `root.ttl` at the top of the tree is `PUT` to `TARGET_URI`. It describes the target document
  itself, so there is no separate step for it.
- Any other RDF file `name.ext` is `PUT` to `D/name/`, with its relative URIs resolved against
  that URL (the same `turtle --base` resolution `put` applies).
- Every other file is uploaded into `D`, as `add file` would: title = file name, media type
  detected, upload URI `{base}uploads/{sha1}`.
- A subdirectory `name` maps to `D/name/`: its document is the RDF file `name.ext` beside it, its
  files are uploaded into that document, and its subdirectories recurse.

A file is a document when Jena tells its RDF syntax from the file name and can parse it: `.ttl`,
`.nt`, `.rdf`, `.jsonld`, `.n3`, `.trig`, `.nq` and the other registered extensions, case
insensitively. `.csv`, `.rq`, `.md`, images and the like are uploads. `.xml` counts as RDF/XML, so
an XML file that is not RDF has to be listed in `.ldhignore`.

Within a directory the order is the root document, then documents, then uploads, then
subdirectories, each sorted by name — a subdirectory's document exists before anything is uploaded
into it. `PUT` replaces a document, so a repeated push converges: the document is rewritten and its
uploads re-appended, not duplicated.

Entries whose name starts with `.` are never pushed. A `.ldhignore` file in any directory excludes
entries from that directory's whole subtree, gitignore-style: blank lines and `#` comments are
skipped; a pattern without a `/` matches an entry's name at any depth beneath (`*.sh`, `Makefile`,
`screenshot*.png`); a pattern with a `/` matches the path relative to the ignore file's directory
(`categories/unesco-mappings.ttl`, `/root.ttl`); a trailing `/` restricts the pattern to directories
(`admin/`). Patterns are globs (`*`, `?`, `[ab]`, `**`); negation is not supported. Skipped entries
are reported on stderr.

`--dry-run` walks the tree, parses every document (so a syntax error fails the dry run too),
computes every upload URI and prints the plan, without sending a request or loading a certificate.

## Script → command migration

| Script | Command |
|---|---|
| `get.sh` | `ldh get` |
| `post.sh` | `ldh post` |
| `put.sh` | `ldh put` |
| `patch.sh` | `ldh patch` |
| `delete.sh` | `ldh delete` |
| `create-item.sh` | `ldh create item` |
| `create-container.sh` | `ldh create container` |
| `add-view.sh` | `ldh add view` |
| `add-construct.sh` | `ldh add construct` |
| `add-select.sh` | `ldh add select` |
| `add-result-set-chart.sh` | `ldh add result-set-chart` |
| `add-file.sh` | `ldh add file` |
| `add-generic-service.sh` | `ldh add generic-service` |
| `admin/clear-ontology.sh` | `ldh admin clear ontology` |
| `admin/add-ontology-import.sh` | `ldh admin add ontology-import` |
| `admin/ontologies/create-ontology.sh` | `ldh admin create ontology` |
| `admin/ontologies/import-ontology.sh` | `ldh admin import ontology` |
| `admin/ontologies/add-class.sh` | `ldh admin add class` |
| `admin/ontologies/add-constructor.sh` | `ldh admin add constructor` |
| `admin/ontologies/add-select.sh` | `ldh admin add select` |
| `admin/ontologies/add-property-constraint.sh` | `ldh admin add property-constraint` |
| `admin/ontologies/add-restriction.sh` | `ldh admin add restriction` |
| `admin/acl/create-group.sh` | `ldh admin create group` |
| `admin/acl/create-authorization.sh` | `ldh admin create authorization` |
| `admin/acl/add-agent-to-group.sh` | `ldh admin add agent` |
| `admin/acl/make-public.sh` | `ldh admin make-public` |
| `content/add-object-block.sh` | `ldh add object-block` |
| `content/add-xhtml-block.sh` | `ldh add xhtml-block` |
| `content/remove-block.sh` | `ldh remove block` |
| `imports/add-csv-import.sh` | `ldh add csv-import` |
| `imports/add-rdf-import.sh` | `ldh add rdf-import` |
| `imports/import-csv.sh` | `ldh import csv` |
| `imports/import-rdf.sh` | `ldh import rdf` |
| `update-folder.sh` (LinkedDataHub-Apps, one copy per app) | `ldh push` |

Local certificate tooling (`webid-keygen.sh`, `webid-keygen-pem.sh`, `webid-uri.sh`,
`webid-modulus.sh`, `server-cert-gen.sh`) and the experimental `sitemap/` generator remain
shell scripts.

`bin/admin/packages/` has no counterpart under that name: a package is imported by declaring an
`ldh:import` triple rather than by installing files, and `ldh packages list`,
`ldh packages add` and `ldh packages remove` write that declaration.

### Differences from the scripts

- `-f/--cert-pem-file` is now `-f/--cert-file` and takes the `.p12` keystore directly — no
  PEM conversion needed.
- `admin create group` writes the `--name` value into `foaf:name`/`dct:title` (the script wrote an
  unset variable, producing empty literals).
- `add generic-service` drops the documented-but-unparsed `--slug` option.
- `add csv-import`/`import csv` default `--delimiter` to `,` (the script required it despite
  documenting a default).
- `import csv`/`import rdf` run their steps in-process instead of spawning subscripts, and pass
  `--description` through to the import metadata.
- `admin import ontology` reads the `construct-constructors` query text by dereferencing its
  document instead of going through a `SELECT` on `/sparql`; the CONSTRUCT it then runs over the
  scratch graph is unchanged.
- `create item`/`create container` add `--primary-topic`, which the scripts have no equivalent for:
  they could only create a document that says nothing about what it is about, leaving a `patch` as
  the only way to assert it.
- `push` replaces the apps' `update-folder.sh` together with the `root.ttl` step of their
  `install.sh`: `root.ttl` maps to the target document, so it needs neither the separate `put` nor
  its `.ldhignore` entry. `.ldhignore` applies to the whole subtree, as the apps documentation
  describes (the script matched names in its own folder only); any RDF syntax Jena parses is a
  document, not only `.ttl`; there is no `git check-ignore` and no built-in `target`/`*.sh`
  exclusion, so an app lists those in `.ldhignore`; directory and file names are percent-encoded in
  the URLs; and the run stops at the first failed request instead of carrying on.
