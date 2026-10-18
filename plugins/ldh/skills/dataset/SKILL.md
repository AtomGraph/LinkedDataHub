---
name: dataset
description: Model and load data into a LinkedDataHub dataspace with the ldh CLI — write the namespace ontology (classes, constructors, constraints, property views), import vocabulary packages, and map CSV or RDF into documents with SPARQL CONSTRUCT imports, or build a large CSV, JSON or XML dataset standalone (CSV2RDF, JSON2RDF, Saxon XSLT, then a quad CONSTRUCT) and bulk-load it. Use when the task is to define a domain model or get data into an existing dataspace. For the documents, views and charts that present it use ldh:app; for a new dataspace use ldh:dataspace.
---

# Model and load data into a LinkedDataHub dataspace

A dataspace's data is a set of **documents**, each a named graph whose name is the document URL. A
resource is described in the document about it: the document `https://host/products/42/` describes
`https://host/products/42/#this` and names it with `foaf:primaryTopic`. Its **model** is the
namespace ontology served at `${LDH_BASE}ns#`. The ontology drives the create/edit forms
(constructors), the validation (constraints) and the related-resource panels (property views).

References:
- HTTP API for agents: https://github.com/AtomGraph/LinkedDataHub/blob/master/AGENTS.md
- CLI: https://docs.linkeddatahub.com/reference/command-line-interface/
- Ontologies: https://docs.linkeddatahub.com/reference/administration/ontologies/
- Imports: https://docs.linkeddatahub.com/reference/imports/ (`csv/` and `rdf/` beneath it)
- Worked example: https://github.com/AtomGraph/LinkedDataHub-Apps/tree/master/demo/northwind-traders
  (`admin/model/ns.ttl`, and a `*.rq` mapping beside every `*.csv`)

## Ground rules shared with the other ldh skills

- **The default graph is empty.** Every SPARQL pattern goes inside `GRAPH ?g { … }`. A query
  without one returns no rows, which looks like missing data but is not.
- **One document per resource, so joins cross graphs.** Give each linked resource its own graph
  variable: `GRAPH ?o { ?order schema:customer ?c } GRAPH ?cg { ?c schema:name ?name }`.
- Writes go to document URLs (`PUT`/`POST`/`PATCH`); `/sparql` is read-only. Use standard SPARQL 1.1.
- Setup: `export LDH_BASE=https://<dataspace>/ LDH_CERT_FILE=<owner keystore.p12> LDH_CERT_PASSWORD=…`.
  The password is the deployment's, never a guess.
  Commands that create a document print its URL as the only stdout line; exit `1` is an HTTP failure.
- **Use an `ldh` that matches the instance.** Build it from the same LinkedDataHub checkout or release
  as the running image (`ldh --version`). An instance whose end-user responses carry no
  `https://w3id.org/atomgraph/linkeddatahub/dataspaces#admin` `Link` (check with `ldh get --head --accept text/turtle "$LDH_BASE"`)
  predates the CLI's admin discovery. There, `ldh admin` commands stop with "advertises no lds:admin link".
  An admin base advertises itself as its `lds:admin` only from 6.2.1 on. Use the image built from the same checkout as the CLI.

## 1. Reuse vocabulary before inventing it

Model with established vocabularies (schema.org, FOAF, Dublin Core, SKOS, …) and declare their
classes in the namespace ontology. Mint terms under `${LDH_BASE}ns#` only for what none of them
covers.

Check the package registry first, since a package can bring a whole vocabulary with its
constructors, views and rendering:

```bash
ldh packages list                    # state<TAB>package URI<TAB>title
ldh packages add --package https://packages.linkeddatahub.com/editor/taxonomy/#this   # SKOS
```

It takes effect on the next request, with no restart. A vocabulary the dataspace has not imported
is simply absent from the UI's property typeahead and forms.

## 2. Write the namespace ontology

Keep it as a file, `admin/model/ns.ttl`, with `@prefix : <#>` resolving against `${LDH_BASE}ns`:

```turtle
@prefix :       <#> .
@prefix ldh:    <https://w3id.org/atomgraph/linkeddatahub#> .
@prefix ac:     <https://w3id.org/atomgraph/client#> .
@prefix rdfs:   <http://www.w3.org/2000/01/rdf-schema#> .
@prefix owl:    <http://www.w3.org/2002/07/owl#> .
@prefix sp:     <http://spinrdf.org/sp#> .
@prefix spin:   <http://spinrdf.org/spin#> .
@prefix dct:    <http://purl.org/dc/terms/> .
@prefix schema: <https://schema.org/> .

: a owl:Ontology .

# a class
schema:Product a owl:Class ;
    rdfs:label "Product" ;
    rdfs:isDefinedBy : .

# constructor: the properties a new instance's form starts with, and their value types
schema:Product spin:constructor :ProductConstructor ;
    spin:constraint :MissingName .

:ProductConstructor a ldh:Constructor ;
    rdfs:label "Product constructor" ;
    sp:text """
        PREFIX schema: <https://schema.org/>
        PREFIX xsd:    <http://www.w3.org/2001/XMLSchema#>
        CONSTRUCT {
            $this schema:name [ a xsd:string ] ;
                schema:category [ a schema:ProductGroup ] .
        }
        WHERE {}""" ;
    rdfs:isDefinedBy : .

# constraint: a required property
:MissingName a ldh:MissingPropertyValue ;
    rdfs:label "Missing schema:name" ;
    sp:arg1 schema:name ;
    rdfs:isDefinedBy : .

# inverse property view: on a category page, list the products pointing at it. The view shows on the
# types in the property's rdfs:range, so the range is what puts it on a category's page
schema:category rdfs:range schema:ProductGroup ;
    ldh:inverseView :ProductsInCategory .

:ProductsInCategory a ldh:View ;
    dct:title "Products in this category" ;
    spin:query :SelectProductsInCategory ;
    ac:mode ac:TableMode ;
    rdfs:isDefinedBy : .

:SelectProductsInCategory a sp:Select ;
    rdfs:label "Select products in category" ;
    sp:text """
        PREFIX schema: <https://schema.org/>
        SELECT DISTINCT ?product
        WHERE { GRAPH ?g { ?product schema:category $about } }""" ;
    rdfs:isDefinedBy : .
```

- `$this` in a constructor is the new instance; `$about` in a view query is the resource whose page
  shows it. `ldh:view` attaches a view to a property for forward links, `ldh:inverseView` for
  backlinks.
- **A property view shows only on the types the property declares.** An `ldh:inverseView` appears on
  pages whose resource has a type in the property's `rdfs:range`. An `ldh:view` appears on those with a
  type in its `rdfs:domain`. Declare the range or domain in `ns.ttl`, even for a reused term like
  `schema:author`, since the dataspace does not import schema.org. Without it the view never appears.
  Its query can be correct and still never be run, so check the page itself, not only the query.
- Constraints run on every write, imports included. A violating write answers `422`, and an import
  attaches its violations to the import document. Do not add a constraint the data cannot satisfy.
- View queries `SELECT` resources (one variable, the resource) and do not aggregate. Aggregates
  belong in charts (ldh:app).

### Install it

The ontology lives in the admin app's document `ontologies/namespace/`, and the dataspace serves it at
`${LDH_BASE}ns`. Install the file with one command, given the end-user base (`LDH_BASE`):

```bash
ldh admin import ontology --file admin/model/ns.ttl
```

`ldh` finds the admin app and the ontology IRI (`${LDH_BASE}ns#`) from the base's `Link` headers,
`lds:admin` and `lds:ontology`. It parses the file against that IRI, so `@prefix : <#>` names the
end-user namespace. Then it replaces the document, keeping the document's own description and the
ontology's header, and clears the ontology cache. It prints the document's URL. A re-run converges,
and a class or property removed from the file is gone. Triples about the ontology IRI itself (its
label, its `owl:imports`) accumulate instead, because the header carries the platform's own
`owl:imports <https://w3id.org/atomgraph/linkeddatahub/default#>` and must keep it. To read from
stdin, use `--file -` with `-t text/turtle`.

Then check it: `ldh get --accept text/turtle "${LDH_BASE}ns"` shows the new terms.

For a single change to a live ontology, `ldh patch` that document with a SPARQL update. Get its URL
from the output above, or from `lds:admin` in `${LDH_BASE}context`. Then run
`ldh admin clear ontology --ontology "${LDH_BASE}ns#"`. A `PATCH` body must not contain the `GRAPH`
keyword, because it runs inside the document's graph. A plain `INSERT { … } WHERE {}` is the safe
shape. `ldh admin add class|constructor|restriction|property-constraint` exist for one-off
additions. But `admin add constructor` only creates the query resource: linking it with
`spin:constructor` is a separate `patch`.

`ldh admin` commands take the end-user base and follow its `lds:admin` link to the admin app, so
never derive the admin URI yourself.

## 3. Import the data

Every import is a SPARQL `CONSTRUCT` mapping that turns the input into **documents**. Each document
is a `GRAPH` block in the template, named with a URL you mint under an existing container. The
server derives each document's parent from its URL and types it `dh:Item` unless the mapping types
it `dh:Container`. So **create the target containers first**, by `ldh create container` or by
pushing the document tree (ldh:app).

### CSV

Each row becomes a resource whose cells are `xsd:string` literals on `<#column-name>` predicates.
Map one row to one document:

```sparql
PREFIX dct:    <http://purl.org/dc/terms/>
PREFIX foaf:   <http://xmlns.com/foaf/0.1/>
PREFIX schema: <https://schema.org/>
PREFIX xsd:    <http://www.w3.org/2001/XMLSchema#>

CONSTRUCT
{
    GRAPH ?graph
    {
        ?graph dct:title ?name ;                 # mandatory on every document
            foaf:primaryTopic ?product .
        ?product a schema:Product ;
            schema:name ?name ;
            schema:price ?price ;
            schema:category ?category .
    }
}
WHERE
{
    ?row <#id> ?id ;
        <#name> ?name .
    OPTIONAL { ?row <#price> ?priceString BIND(xsd:decimal(?priceString) AS ?price) }
    OPTIONAL { ?row <#categoryId> ?categoryId
        BIND(uri(concat(str($base), "categories/", encode_for_uri(?categoryId), "/#this")) AS ?category) }

    BIND(uri(concat(str($base), "products/", encode_for_uri(?id), "/")) AS ?graph)
    BIND(uri(concat(str(?graph), "#this")) AS ?product)
}
```

- `$base` is the dataspace base URI. The query's own `BASE` is the uploaded file's URI, so do not
  set one.
- Mint URLs from natural keys with `encode_for_uri`. A foreign key becomes a link by minting the same
  URL the other mapping mints (here `categories/{id}/#this`), so the import order does not matter.
- Cast with `BIND` (`xsd:decimal`, `xsd:date`, `xsd:float` for `geo:lat`/`geo:long`). Wrap
  optional cells in `OPTIONAL`. An unbound variable silently drops its triple.

```bash
ldh create container --parent "$LDH_BASE" --title "Products" --slug products
ldh import csv --title "Products" --query-file "$PWD/products.rq" \
    --csv-file "$PWD/products.csv" "${LDH_BASE}products/"
```

`--query-file` and `--csv-file` take absolute paths. `--delimiter` defaults to `,`.

### RDF

```bash
# into one document, as is
ldh import rdf --title "Mappings" --rdf-file "$PWD/mappings.ttl" --content-type text/turtle \
    --graph "${LDH_BASE}mappings/" "${LDH_BASE}mappings/"
# or split into documents with a CONSTRUCT mapping shaped like the CSV one
ldh import rdf --title "People" --rdf-file "$PWD/people.ttl" --content-type text/turtle \
    --query-file "$PWD/people.rq" "${LDH_BASE}people/"
```

Pass `--graph` or `--query-file`, not both.

### Imports run in the background

The command returns once the import exists, before the data does. It prints the URI of the import, an
`ldh:CSVImport` or `ldh:RDFImport` resource in the target document. Add `--wait` to return only once
the import has ended: it prints the triple count to stderr, and exits `1` with the error if the import
failed or did not end within `--timeout` seconds (default 1200).

```bash
import=$(ldh import csv --title "Products" --query-file "$PWD/products.rq" \
    --csv-file "$PWD/products.csv" --wait "${LDH_BASE}products/")
ldh get --accept text/turtle "${import%%#*}"     # the import, its triple count and any error
```

Without `--wait`, the import is done when it carries `prov:endedAtTime`. Its outcome points back at
it with `prov:wasGeneratedBy`: a `void:Dataset` with `void:triples` on success, an entity with the
message in `dct:description` on failure.

Then confirm the data landed with a `GRAPH` query against the dataspace's SPARQL endpoint, the
`sd:endpoint` `Link` header of any response (conventionally `${LDH_BASE}sparql`):

```sparql
SELECT (COUNT(DISTINCT ?s) AS ?n) WHERE { GRAPH ?g { ?s a <https://schema.org/Product> } }
```

Every run is a new import, so re-running one creates another import record. The documents it
writes are the same, so the data converges.

## 4. Or build the dataset standalone

`ldh import` writes one document per request through the platform, which is fine up to tens of
thousands of documents. Above that, or when the source is not CSV, build the dataset **outside
LinkedDataHub** as a re-runnable pipeline whose output is TriG that already follows the platform's
conventions, then bulk-load it. Worked example:
https://github.com/AtomGraph/LTLOD (`etl/`, with the shared scripts in `etl/lib/`).

Every source goes through four stages:

1. **Fetch** the raw source (a dump, an API export) into a cache directory. Fail loudly on an empty
   result.
2. **Transform** it into documents in the target vocabulary. How depends on the data model:
   - **CSV/TSV and JSON** take two steps. First a generic converter makes source-shaped RDF:
     [`atomgraph/csv2rdf`](https://github.com/AtomGraph/CSV2RDF), run with the identity query
     `CONSTRUCT WHERE { ?s ?p ?o }`, gives one resource per row with its cells on
     `<{base}#column>`. [`atomgraph/json2rdf`](https://github.com/AtomGraph/JSON2RDF) puts keys on
     `<{base}#key>`, types numbers and booleans, makes nested objects blank nodes and loses array
     order. Then a quad `CONSTRUCT { GRAPH ?graph { … } }` mapping, run by Jena's `arq` with `$base`
     substituted and the query `BASE` set to the base, maps that RDF to documents. This is the same
     mapping shape as a CSV import (section 3), so one `.rq` serves both paths.
   - **XML** takes one step. An XSLT 3 stylesheet on
     [`atomgraph/saxon`](https://github.com/AtomGraph/saxon-docker) emits the final RDF in the
     target vocabulary, with no follow-up `CONSTRUCT`. To keep one document per named graph, emit
     **TriX**, the XML syntax for quads: a `<graph>` per document whose `<uri>` is the document URL,
     and `<triple>`s of `<uri>`, `<id>` (blank node), `<plainLiteral>` and `<typedLiteral>`. RDF/XML
     has no named graphs, so an RDF/XML output only works with one file per document. Pass the base
     as a stylesheet parameter.

   ```bash
   docker run --rm -i -a stdin -a stdout -a stderr -v "$PWD/identity.rq":/tmp/identity.rq \
       atomgraph/csv2rdf /tmp/identity.rq "$LDH_BASE" < books.csv > books.nt
   docker run --rm -i -a stdin -a stdout -a stderr atomgraph/json2rdf "$LDH_BASE" < books.json > books.nt
   # then: arq --data books.nt --query books.rq (with $base substituted) > books.trig

   docker run --rm -v "$PWD":/work atomgraph/saxon -s:/work/books.xml -xsl:/work/books.xsl \
       base="$LDH_BASE" > books.trix
   riot --syntax=trix --output=trig books.trix > books.trig
   ```

   Because the platform does not see these writes, the output adds what the platform would
   otherwise add. Type each document `dh:Item` with `sioc:has_container <its container/>`, and give
   it a `dct:created` from a top-level `BIND(NOW() AS ?now)`, or `current-dateTime()` in XSLT. The
   containers themselves still come from the app (`ldh push`, ldh:app).
3. **Validate** the TriG: `riot --validate`, then check that every graph carries `dct:title` and
   `foaf:primaryTopic` on the graph URI, then run SHACL shapes per entity type.
4. **Load** it, as described below.

Glue code the four stages need beyond these tools (reconciliation against Wikidata, scraping,
geometry) is Python with rdflib.

Keep the output **base-relative** so one dataset loads at any deployment base: serialize with riot's
streaming TriG writer after prepending `@base <$LDH_BASE> .` (`riot --syntax=trig --output=trig`,
not `--formatted`), and strip the emitted base line. Every later read then needs the base back:
`riot --base="$LDH_BASE" …`, or the relative IRIs resolve to `file://` paths.

Load it with `tdb2.tdbloader` straight into the dataspace's end-user TDB2 dataset
(`fuseki/<dataset>/DB2`, the name from `config/fuseki/config.ttl`):

- Stop `fuseki` first. One server holds every dataset, so the admin stores go down with it.
- Remove the stale `fuseki/*/DB2/tdb.lock` files, because their PIDs are container-relative.
- Resolve the TriG to N-Quads with `riot --base=…`, since `tdbloader` has no `--base`.
- Load the N-Quads, start `fuseki`, and restart the Varnish caches.

The canonical Makefile's `make load` does all of this when `make/config.mk` sets `LOAD_STAGING`
and `docker-compose.override.yml` defines a `tdb-loader` service. LTLOD's override has one to copy.
The load is append-only: for a clean rebuild, delete the dataset directory and restart before
loading. Then run `ldh admin make-public` if the data is public. Its class-based authorizations
match the `dh:Item` documents.

## 5. Connect to external data

An external SPARQL endpoint joins as an `sd:Service`, either added to a document
(`ldh add generic-service --title … --endpoint https://… <doc>`) or written in Turtle, and is then named by
a query (`ldh:service`). Before building anything on a remote endpoint, time the query against it:
remote endpoints are slow and rate-limited. Bind local values into the remote query (`VALUES`, or
`STRLANG` for language-tagged labels) instead of fetching and filtering. Then write the result back as
links (`skos:exactMatch`, `owl:sameAs`) with an RDF import, so the connection lives in the data
and is not only displayed side by side.

## Pitfalls

- Jena's `shacl validate` ignores named graphs and always exits `0`. Merge the TriG to N-Triples
  first (`riot --merge`), and treat any report other than `Conforms` as a failure.
- `arq` 6.x cannot write quad `CONSTRUCT` results (apache/jena#4091). Graphify with Jena 5.6, and
  point `JENA_HOME` at it too: Jena's `bin/` scripts load their jars from `$JENA_HOME`, so 5.6's `arq`
  run with `JENA_HOME` set to a 6.x install still fails with "No dataset writer for Turtle_pretty".
- `arq` writes a quad `CONSTRUCT` as TriG by default and has no `--results=trig`; pass no `--results`.
- `make load` restarts the Varnish caches right before `make public`, whose first request can meet them
  mid-restart and answer `500`. The load itself has succeeded by then; run `make public` again.

- Documents built without `foaf:primaryTopic`, or with the domain properties on the document itself,
  render an empty page. The properties go on `#this`.
- A `403` for a URL you expect to be missing is normal. Non-owners get `403`, not `404`, for
  nonexistent documents.
- Package imports added with `ldh packages add` are lost on a platform restart. Re-add them, or
  declare them permanently in `config/dataspaces.trig` (ldh:dataspace).

## Next

Present the data with **ldh:app**: container pages, views, charts, and an installable app directory.
