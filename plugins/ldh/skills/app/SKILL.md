---
name: app
description: Build a LinkedDataHub application declaratively with the ldh CLI — the document tree (containers and items), content blocks, SPARQL views in table/grid/list/map/graph layouts, charts, federated queries, public access, and an app directory installed with ldh push. Use when the task is to present data in an existing dataspace or to package an installable app. For the domain model and data imports use ldh:dataset; for rendering that data cannot declare (custom XSLT) use ldh:package.
---

# Build a LinkedDataHub application

A LinkedDataHub app is **declared, not generated**: it is RDF documents in the dataspace, with no code
and no build step. Pages are documents. A page's content is an ordered list of blocks. Lists, tables,
maps and charts are blocks backed by SPARQL queries. The whole app can live in a directory of Turtle
files that `ldh push` writes into the dataspace, so it is versioned in git and re-installable.

References:
- HTTP API for agents: https://github.com/AtomGraph/LinkedDataHub/blob/master/AGENTS.md
- CLI (incl. `push`): https://docs.linkeddatahub.com/reference/command-line-interface/
- Documents and blocks: https://docs.linkeddatahub.com/reference/data-model/
- Worked examples, one directory per app:
  https://github.com/AtomGraph/LinkedDataHub-Apps/tree/master/demo (`northwind-traders`: dashboards,
  faceted views, charts; `copenhagen`: map views)

## Ground rules shared with the other ldh skills

- **The default graph is empty.** Every query pattern goes inside `GRAPH ?g { … }`. Give each
  linked resource its own graph variable, because each resource lives in its own document.
- A document is not the thing it describes. The topic is `<doc#this>`, linked with
  `foaf:primaryTopic`, and its properties go there.
- Setup: `export LDH_BASE=https://<dataspace>/ LDH_CERT_FILE=<owner keystore.p12> LDH_CERT_PASSWORD=…`.
  The password is the deployment's, never a guess.

## The document model

| Resource | Shape |
|---|---|
| Container (a section other documents live under) | `<> a dh:Container ; dct:title "…"` |
| Item (a leaf page: a dashboard, a chart page, or a record) | `<> a dh:Item ; dct:title "…"`, plus `foaf:primaryTopic <#this>` when it describes a thing |
| Rich-text block | `<#intro> a ldh:XHTML ; rdf:value """<div xmlns="http://www.w3.org/1999/xhtml">…</div>"""^^rdf:XMLLiteral` |
| Embedded resource block | `<#b> a ldh:Object ; rdf:value <resource>` |
| Block order | `<> rdf:_1 <#intro> ; rdf:_2 <#b>` on the document |

**Only `ldh:XHTML` and `ldh:Object` may be `rdf:_N` values.** Views, charts and anything else are
wrapped in an `ldh:Object` whose `rdf:value` names them. Bare ones are rejected by validation.
XHTML must be well-formed, in the XHTML namespace, with each tag on one line.

Pick the type by what will live under the page, not by how it looks. A page made only of blocks
(a chart page, a dashboard, an about page) with nothing beneath it is a `dh:Item`. Make it a
`dh:Container` only when documents will be created under it, e.g. the target of an import. Both
types take the same blocks.

Built-ins worth knowing: `rdf:value ldh:ChildrenView` lists the container's children, and the query
`ldh:SelectChildren` selects them for a view of your own (e.g. a map of the children).

## Views and charts

**Views render resources; charts render numbers.** A view's `SELECT` returns resources (their rows are
navigable, facetable and linkable). A query with `COUNT`/`SUM`/`GROUP BY` belongs in a chart, never
a view.

```turtle
@prefix ldh:    <https://w3id.org/atomgraph/linkeddatahub#> .
@prefix ac:     <https://w3id.org/atomgraph/client#> .
@prefix dh:     <https://w3id.org/atomgraph/linkeddatahub/document-hierarchy#> .
@prefix rdf:    <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix dct:    <http://purl.org/dc/terms/> .
@prefix sp:     <http://spinrdf.org/sp#> .
@prefix spin:   <http://spinrdf.org/spin#> .

<> a dh:Container ;
    dct:title "Products" ;
    rdf:_1 <#intro> ;
    rdf:_2 <#products-block> ;
    rdf:_3 <#per-category-block> .

<#intro> a ldh:XHTML ;
    rdf:value """<div xmlns="http://www.w3.org/1999/xhtml"><p>Everything in the catalogue.</p></div>"""^^rdf:XMLLiteral .

<#products-block> a ldh:Object ;
    dct:title "All products" ;
    rdf:value <#products-view> .

<#products-view> a ldh:View ;
    dct:title "All products" ;
    spin:query <#select-products> ;
    ac:mode ac:TableMode .

<#select-products> a sp:Select ;
    dct:title "Select products" ;
    sp:text """PREFIX schema: <https://schema.org/>
SELECT DISTINCT ?product
WHERE { GRAPH ?g { ?product a schema:Product ; schema:name ?name } }
ORDER BY ?name""" .

<#per-category-block> a ldh:Object ;
    dct:title "Products per category" ;
    rdf:value <#per-category> .

<#per-category> a ldh:ResultSetChart ;
    dct:title "Products per category" ;
    spin:query <#count-per-category> ;
    ldh:chartType ac:BarChart ;
    ldh:categoryVarName "categoryName" ;
    ldh:seriesVarName "productCount" .

<#count-per-category> a sp:Select ;
    dct:title "Count products per category" ;
    sp:text """PREFIX schema: <https://schema.org/>
SELECT ?categoryName (COUNT(DISTINCT ?product) AS ?productCount)
WHERE {
    GRAPH ?pg { ?product a schema:Product ; schema:category ?category }
    GRAPH ?cg { ?category schema:name ?categoryName }
}
GROUP BY ?category ?categoryName
ORDER BY DESC(?productCount)""" .
```

- View layout modes (`ac:mode`): `ac:ListMode`, `ac:TableMode`, `ac:GridMode`, `ac:MapMode` (the
  resources need `geo:lat`/`geo:long`), `ac:GraphMode`.
- Chart types (`ldh:chartType`): `ac:BarChart`, `ac:LineChart`, `ac:ScatterChart`.
  `ldh:categoryVarName` and `ldh:seriesVarName` name the query's variables, without `?`.
- A query runs against the dataspace's own endpoint unless it names a service:
  `<#q> ldh:service <#dbpedia>` with `<#dbpedia> a sd:Service ; dct:title "DBpedia" ;
  sd:endpoint <https://dbpedia.org/sparql> ; sd:supportedLanguage sd:SPARQL11Query`. Time a remote
  query before building on it, and write it against the remote store's own graph layout.
- Every non-optional pattern filters rows. A pattern that is there only to sort or to display
  (`?book schema:datePublished ?year` for `ORDER BY ?year`) goes in `OPTIONAL`, or resources missing
  that value silently drop out of the view.
- Per-resource panels ("orders of this customer") are property views in the ontology (ldh:dataset),
  not blocks.

## The app as a directory

`ldh push` maps a directory onto the document tree:

```
my-app/
├── root.ttl              → PUT to $LDH_BASE (the root document itself)
├── products.ttl          → PUT to ${LDH_BASE}products/
├── products/
│   ├── products.csv      → uploaded into products/ (unless ignored)
│   └── featured.ttl      → PUT to ${LDH_BASE}products/featured/
├── admin/model/ns.ttl    → the ontology, installed separately (ldh:dataset), so ignored
└── .ldhignore            → gitignore-style: admin/  *.sh  *.csv
```

Relative URIs in each file resolve against its target URL, so write `<>` and `<#…>`. A
subdirectory's document `name.ttl` sits beside it, not inside it. Non-RDF files are uploaded and
addressed as `${LDH_BASE}uploads/{sha1}`, and `.xml` files count as RDF/XML. Ignore CSVs that
`ldh import csv` uploads itself.

**`root.ttl` replaces the seeded root document**, so keep its type: read it first
(`ldh get --accept text/turtle "$LDH_BASE"`) and start `root.ttl` from that. A push replaces every
document it writes, so a re-push converges. It stops at the first failed request, and stdout lists
what was written before it.

```bash
ldh push --dry-run --dir my-app "$LDH_BASE"   # parses every file, prints the plan, sends nothing
ldh push --dir my-app "$LDH_BASE"
```

### Install order

An installable app is an `install.sh` that runs, in this order:

1. `ldh admin make-public` (only if anonymous visitors should read it). Each run adds another
   authorization, so run it once.
2. Install the namespace ontology and any `ldh packages add` (ldh:dataset).
3. `ldh push --dir "$app_dir" "$LDH_BASE"`, which creates the containers the imports write into.
4. `ldh import csv|rdf` per data file (ldh:dataset), then wait for each import to finish.

**The script is self-contained.** It needs `ldh` and nothing else, so it runs from wherever the app
directory is copied. The demo apps in LinkedDataHub-Apps source a shared `lib/ldh-app.sh`, which is
internal to that repository. Do not copy that `source` line, and do not reference any other checkout
by path.

```bash
#!/usr/bin/env bash
# Installs the app with the ldh CLI. Reads LDH_BASE, LDH_CERT_FILE, LDH_CERT_PASSWORD (and LDH_PROXY).
set -euo pipefail
: "${LDH_BASE:?}" "${LDH_CERT_FILE:?}" "${LDH_CERT_PASSWORD:?}"

app_dir="$(cd "$(dirname "$0")" && pwd)"
admin_base=$(echo "$LDH_BASE" | sed 's|://|://admin.|')
ontology_doc="${admin_base}ontologies/namespace/"

ldh admin make-public

# namespace ontology: reset, append, evict the cache (ldh:dataset)
{ echo "BASE <${ontology_doc}>"; cat "$app_dir/admin/model/patch-ontology.ru"; } | ldh patch "$ontology_doc"
{ echo "@base <${LDH_BASE}ns> ."; cat "$app_dir/admin/model/ns.ttl"; } | ldh post -t text/turtle "$ontology_doc"
ldh admin clear ontology --ontology "${LDH_BASE}ns#" "$admin_base"

ldh push --dir "$app_dir" "$LDH_BASE"

# the target is the container the documents go under; the import is added to that document
ldh import csv --title "Books" --query-file "$app_dir/books/books.rq" \
    --csv-file "$app_dir/books/books.csv" "${LDH_BASE}books/"

# imports in a document that do not carry prov:endedAtTime yet
pending() {
    ldh get --accept application/n-triples "$1" | awk '
        $2 == "<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>" && $3 ~ /#(CSV|RDF)Import>$/ { i[$1] }
        $2 == "<http://www.w3.org/ns/prov#endedAtTime>" { e[$1] }
        END { n = 0; for (k in i) if (!(k in e)) n++; print n }'
}
for doc in "${LDH_BASE}books/"; do
    until [ "$(pending "$doc")" = 0 ]; do sleep 5; done
done
```

`patch-ontology.ru` is the reset update from ldh:dataset, saved in the app directory. Keep `admin/`,
`*.sh`, `*.rq` and `*.csv` in `.ldhignore` so `push` does not upload them.

Finer access control: `ldh admin create group`, `ldh admin add agent`, `ldh admin create authorization`
(https://docs.linkeddatahub.com/reference/administration/acl/).

## Building incrementally instead

For one-off changes to a live dataspace, the `create`/`add` commands each make one request and print
the new URL:

```bash
products=$(ldh create container --parent "$LDH_BASE" --title "Products" --slug products)
ldh add select --uri "${products}#select-products" --title "Select products" \
    --query-file "$PWD/select-products.rq" "$products"
ldh add view --uri "${products}#products-view" --title "All products" \
    --query "${products}#select-products" --mode https://w3id.org/atomgraph/client#TableMode "$products"
ldh add object-block --value "${products}#products-view" --title "All products" "$products"
ldh add xhtml-block --value '<div xmlns="http://www.w3.org/1999/xhtml"><p>…</p></div>' "$products"
ldh add result-set-chart --query <select URI> --chart-type https://w3id.org/atomgraph/client#BarChart \
    --category-var-name categoryName --series-var-name productCount --title "…" "$products"
ldh remove block --block "${products}#products-block" "$products"   # without --block: removes ALL blocks
```

Pass `--uri` so later commands can reference what you added; without it the resource is a blank
node. If the app is meant to be reinstalled, put the change in the directory too, since the next
push overwrites the document.

## Verify

- `ldh get --accept text/turtle <doc>` shows the document as stored.
- Run each view and chart query against the dataspace's SPARQL endpoint (`${LDH_BASE}sparql`)
  before trusting the page. A view with no rows is usually a missing `GRAPH`, or two resources'
  patterns sharing one graph variable.
- Open the page in a browser. The HTML is rendered client-side from the same RDF, so an RDF check
  alone does not show layout problems.

## Next

When a property or class needs rendering that no mode or block can declare, write a stylesheet as a
reusable package: **ldh:package**.
