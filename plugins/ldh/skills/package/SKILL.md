---
name: package
description: Write a reusable LinkedDataHub package — an ontology plus an XSLT 3 stylesheet whose templates customise rendering in the platform's open modes (property rows, form controls, value cells, tree nodes, a navigation column) — and publish it to a package registry so any dataspace imports it with ldh packages add. Use when a vocabulary needs rendering or editing behaviour that views, modes and blocks cannot declare. For declarative UI use ldh:app; for a dataspace's own model use ldh:dataset.
---

# Write a LinkedDataHub package

A **package** bundles an ontology (`ns.ttl`: vocabulary imports, constructors, constraints, property
views) with an optional XSLT 3 stylesheet. A dataspace imports it with one triple,
`<app> ldh:import <package#this>`, which `ldh packages add` writes. From the next request the
ontology joins the dataspace's imports closure and the stylesheet is composed into the dataspace's
stylesheet. Packages are how a vocabulary gets its own UI without touching the platform.

Try ldh:app first. Most presentation needs (layout modes, charts, maps, XHTML blocks, property views)
are declarative and need no XSLT.

References, read before writing a stylesheet:
- Packages, the extension contract and the open-mode table:
  https://github.com/AtomGraph/LinkedDataHub-Apps/blob/master/packages/README.md
- The open modes and their generic fallbacks, which are the templates you override:
  https://github.com/AtomGraph/LinkedDataHub/blob/master/src/main/webapp/static/com/atomgraph/linkeddatahub/xsl/hooks.xsl,
  `client/hooks.xsl` and `imports/values.xsl` beside it
- Worked example, the taxonomy editor (SKOS):
  https://github.com/AtomGraph/LinkedDataHub-Apps/tree/master/packages/editor/taxonomy
- https://docs.linkeddatahub.com/reference/administration/packages/ and
  https://docs.linkeddatahub.com/reference/stylesheets/

## Ground rules shared with the other ldh skills

- Every document is a named graph and the default graph is empty, so queries in views use `GRAPH ?g { … }`.
- A document is not the thing it describes. The topic is `<doc#this>` via `foaf:primaryTopic`.
- `ldh` reads `LDH_BASE`, `LDH_CERT_FILE`, `LDH_CERT_PASSWORD`, `LDH_PROXY` from the environment.

## What a package stylesheet can and cannot do

The package stylesheet is imported directly above the platform's `hooks.xsl` and below everything
else. **Import precedence beats template priority**, so its position is the whole contract:

- In an **open mode** a package rule outranks the generic fallback whatever its priority. Replace
  the fallback, or decorate it with `xsl:next-match`, or hide with an empty template.
- Everything else is **sealed**: the page shell, the content body, component modes (`ldh:Modal`,
  `ac:FieldShell`, …), the platform's own typed vocabulary rules, and the library of keys, params and
  functions. A package rule there loses whatever priority you give it, and redeclaring a sealed
  global loses the same way. Do not try to fight this with priorities.
- An open mode is a leaf. It renders one node and cannot interrupt a walk or drop a subtree.

Open modes: `ldh:TreeNode`, `ac:PropertyEditor`, `ldh:ContentColumn`, the value leaves in
`imports/values.xsl` (`ac:FormControl`, `ac:PropertyListValue`, `ac:ValueAnnotations`,
`ldh:TypeControl`, `ac:property-label`, `ac:object-label`, `ac:ResultsTableHeaderCell`, the unnamed
mode's property row and value link), and client-only `ldh:TreeChildrenLoad` and `ldh:RowHook`.
Read the fallback in the platform source before overriding it. A replacement must emit the same
markup contract (element, classes, attributes) the fallback does, or the rest of the page breaks.

Match on your own vocabulary only, i.e. your properties, classes and datatypes. Never match generic
shapes in a way that changes rendering for data that is not yours.

## The stylesheet runs on the server AND in the browser

The same stylesheet is composed into the server-side tree (Saxon-HE) and the client-side tree
(Saxon-JS, compiled to SEF). Anything client-only, meaning `ixsl:` instructions and functions, event
handlers, `ixsl:updating` functions and the `ldh:RowHook`/`ldh:TreeChildrenLoad` rules, must carry
`use-when="system-property('xsl:product-name') = 'SaxonJS'"`. A client-only construct without the
guard fails the **server** compile. The dataspace then silently falls back to its stylesheet
*without any package rules*, so the package appears to do nothing at all.

Keep first-paint rendering (property rows, tree nodes, the content column) unguarded so the server
renders it. A directly loaded URL gets only the server's paint at first.

```xml
<!DOCTYPE xsl:stylesheet [
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY ex     "https://example.org/ns#">
]>
<xsl:stylesheet version="3.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:ac="&ac;"
xmlns:ldh="https://w3id.org/atomgraph/linkeddatahub#"
xmlns:rdf="&rdf;"
xmlns:ex="&ex;"
exclude-result-prefixes="#all">

    <!-- hide a property that another widget already shows -->
    <xsl:template match="ex:internalCode" mode="ac:PropertyEditor"/>

    <!-- decorate the generic value cell for the package's own property -->
    <xsl:template match="ex:rating/text()" mode="ac:PropertyListValue">
        <span class="rating" data-value="{.}">
            <xsl:next-match/>
        </span>
    </xsl:template>

</xsl:stylesheet>
```

Use the entity and namespace declarations the taxonomy package uses as the template. Labels shown to
users come from the data or the platform's translations, never hardcoded English. Read the fallback's
match pattern before writing yours, because the node a mode is applied to (element, attribute or
text node) varies by mode.

## Layout and publishing

A registry is itself a LinkedDataHub dataspace, readable anonymously: the importing dataspace
dereferences the descriptor, ontology and stylesheet without a certificate. The public one is
`https://packages.linkeddatahub.com/` (contribute through the LinkedDataHub-Apps repository). For your
own, provision a dataspace (ldh:dataspace) and publish it the way `packages/install.sh` in
LinkedDataHub-Apps does:

```
registry/
├── root.ttl                 the catalog: each package an rdfs:member of the root, with dct:title/description
├── vendor.ttl               container document for the vendor/ folder
└── vendor/
    ├── rating.ttl           the descriptor document, PUT to vendor/rating/
    └── rating/
        ├── ns.ttl           the package ontology, PUT to vendor/rating/ns/
        └── rating.xsl       the stylesheet, uploaded to uploads/{sha1}
```

The descriptor is the `foaf:primaryTopic` of the package document:

```turtle
<> a dh:Container ; dct:title "Rating" ; foaf:primaryTopic <#this> .

<#this> a lds:Package ;
    dct:title "Rating" ;
    dct:description "…" ;
    lds:ontology <ns/#> .      # the ontology IRI ns.ttl declares (`: a owl:Ontology` with `@prefix : <#>`), not the document URL
```

Leave `ac:stylesheet` out of the file. After the push, add it pointing at the upload, whose URI
is the SHA-1 of the stylesheet's bytes:

```bash
ldh admin make-public                       # once: the registry must be anonymously readable
ldh push --dir registry "$LDH_BASE"
sha=$(shasum -a 1 registry/vendor/rating/rating.xsl | cut -d' ' -f1)
echo "INSERT { <${LDH_BASE}vendor/rating/#this> <https://w3id.org/atomgraph/client#stylesheet> <${LDH_BASE}uploads/${sha}> } WHERE { }" \
    | ldh patch "${LDH_BASE}vendor/rating/"
```

## Import and verify

In the target dataspace:

```bash
ldh packages list --registry https://<registry>/          # the package shows as "available"
ldh packages add --package https://<registry>/vendor/rating/#this
ldh packages list --registry https://<registry>/          # now "installed"
```

Then load a page showing the package's vocabulary **in a browser** and check both paints: the
server's (view the page source, or `ldh get --accept text/html`) and the client's (navigate to the
page from another one). If nothing the package does appears, the composed stylesheet most likely
failed to compile and the dataspace fell back to its own. Check the platform log
(`docker compose logs linkeddatahub` on a self-hosted instance) for the XSLT error.

**Copies are taken once.** At import the ontology is materialised as an editable document under the
admin `ontologies/` container, and the stylesheet is copied under
`/static/com/linkeddatahub/packages/`. A republished package does not reach a dataspace that already
imported it until that ontology document is deleted (the next request recreates it) and the ontology
cache is cleared (`ldh admin clear ontology`). A changed stylesheet gets a new
upload URI and so a new copy, once the dataspace reads the updated descriptor. Confirm on the page
that the new version is live and do not assume it.

## Pitfalls

- `lds:ontology` naming the ontology **document** instead of its IRI loads the graph twice and fails
  with "Another graph with name … is already in the hierarchy".
- Package imports added with `ldh packages add` are lost on a platform restart unless declared in
  `config/dataspaces.trig` (ldh:dataspace).
- A package changes rendering for every dataspace that imports it. Keep matches scoped to its
  vocabulary.
