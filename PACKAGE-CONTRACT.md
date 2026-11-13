# The package contract

A package is an ontology and, optionally, an XSLT stylesheet, imported into a dataspace with one triple
(`<app> ldh:import <package#this>`). This is what a package may do, how the platform checks it, and why.
Once enforced, the author-facing version lives in LinkedDataHub-Apps (`packages/README.md`) and this file goes.

## Two channels

A package reaches the page through two channels, and nothing else:

1. **Rendering.** Its stylesheet returns markup or data in the open modes. It has no effect of its own: no
   `ixsl:` of any kind, no I/O, no code chosen at run time. What a rule returns, the platform places.
2. **Behaviour.** Its ontology declares actions (`<class> ldh:action <action>`, an `ldh:Action` with a
   `dct:title` and a Web-Algebra `ldh:plan`). The platform evaluates a plan first, shows the write set, refuses
   or flags what the policy says, and applies it only once the reader confirms.

Tree navigation sits between the two and belongs to the platform: a package says which predicates link a node
to its children and parents (`ldh:TreeChildrenLoad`, `ldh:TreeParentsLoad`, each returning a map) and asks for a
node to be revealed (`data-tree-reveal`); the fetch, the climb, the descent, the marking and the scroll are
`client/tree.xsl`'s, once, for the drawer's document tree and a package's tree alike.

The split is checked where the effect is, not where the code is. Rendering is checked as XML, and the check is
structural because a stylesheet with nothing in `ixsl:` and no I/O can only compute. Behaviour is checked as a
write set, because the executor evaluates a plan without applying it and returns every write with its URI.
Neither needs to follow what the platform's own code does when a package calls it.

## Rule 1: the stylesheet renders

`PackageContract` reads the stylesheet when the platform copies it (`PackageService.materializeStylesheet`) and
reports each breach with its line. The rules, by name:

- **modes.** A template matches only in an open mode, never `#all`. The open modes are derived from the
  platform's stylesheets: every mode declared or matched in the modules at and below the composition marker
  (`hooks.xsl`, `client/hooks.xsl` and what they import), the unnamed mode included for the value leaves.
  Today: `ldh:TreeNode`, `ac:PropertyEditor`, `ldh:ContentColumn`, `ldh:TreeChildrenLoad`, `ldh:TreeParentsLoad`,
  `ldh:DateTimePair`, `ldh:TypeControl`, the value leaves of `imports/values.xsl` and the unnamed mode.
- **names.** A function, named template, variable, param, key, accumulator or mode is declared in the package's
  own namespace, not in `ldh:`, `ac:`, `lds:`, `xhtml:`, `svg:` or no namespace.
- **globals.** No `xsl:output`, `strip-space`, `preserve-space`, `decimal-format`, `namespace-alias`,
  `global-context-item`, `character-map`; no `xsl:mode` for the unnamed mode or a platform mode.
- **imports.** No `xsl:import`, `include`, `use-package` or `import-schema`: a package is one module.
- **ixsl.** Nothing in the `ixsl:` namespace: no instruction, no function (reading or writing), no
  `ixsl:updating`, no `ixsl:on*` event mode. A product guard (`use-when` on `xsl:product-name`) is not `ixsl:`.
- **io.** No `xsl:result-document`; no `document`, `doc`, `doc-available`, `unparsed-text*`, `json-doc`,
  `collection`, `uri-collection`, `environment-variable`, `available-environment-variables`.
- **dynamic.** No `xsl:evaluate`, shadow attributes, `function-lookup`, `transform`, `load-xquery-module`.
- **ids.** No literal `id` attribute and no constructed one: the platform finds its own elements by id, a
  package addresses its markup by class.
- **collecting.** In a mode marked `ldh:collecting="true"`, a template ends with `xsl:next-match`, so every
  package's contribution for a node runs. No open mode is collecting today; the drawer sections of #527 will be.

Calls into the platform are free. A rule may call any platform function, named template or open mode:
with no `ixsl:` and no I/O it can only compute with what they return.

What each open mode returns:

| Mode | Applied to | Returns |
| --- | --- | --- |
| `ldh:TreeNode` | a resource in a tree | the node's `li` (decorate the fallback with `xsl:next-match`) |
| `ac:PropertyEditor` | a resource or statement | its property list or row; empty hides |
| `ldh:ContentColumn` | the document | markup for the column beside the content body |
| `ldh:TreeChildrenLoad` | a node's disclosure button | `map{ 'parent-properties': xs:anyURI*, 'child-properties': xs:anyURI* }` |
| `ldh:TreeParentsLoad` | the `ul.ldh-tree` | the same map, for the climb |
| the value leaves | a property, value or control | markup |

`ldh:RowHook` is sealed: a factory of deferred work is control flow, which a package does not get. The mode and
the platform's own rules in it live in `client/block.xsl`.

## Rule 2: behaviour is declared and carried out

```turtle
skos:Concept ldh:action :DeleteConcept .

:DeleteConcept a ldh:Action ;
    dct:title "Delete concept" ;
    ldh:plan """<Sequence xmlns="https://w3id.org/atomgraph/web-algebra">…</Sequence>"""^^rdf:XMLLiteral .
```

- The platform finds a resource's actions as it finds its constructors: a SPARQL query on `/ns` through
  `rdfs:subClassOf`. They render as a menu in the block header, for a reader who may write the document and
  where the dataspace has an executor (`lds:assistant`).
- A plan takes `$wa:bindings`, one row: `?this` (the resource), `?document`, `?base` (the dataspace), `?admin`.
- A click evaluates the plan with `dry-run="true"`. The executor returns the write set: every `PUT`, `PATCH`,
  `POST` and `DELETE` with its URI, derived from a snapshot and carrying `If-Match`/`If-None-Match: *`, and
  sends nothing.
- **The policy**, applied to that set by the platform before anything is shown:
  - a write outside `?base` and `?admin` is refused; the dialog names it and offers no confirmation;
  - a write into `?admin` or to `/settings` is flagged: access control and configuration;
  - everything else is listed.
- The reader confirms, and the same plan is submitted again to be applied. The document is read again
  after; its container, when the plan deleted it. A write refused mid-way (`409`) is told in the dialog with
  the executor's message; what was applied before it stands (atomicity is per document).
- The executor acts as the reader: the platform's own ACL authorizes every write.
- The executor must take the `wa:request` envelope (`dry-run`, `wa:bindings`): Web-Algebra has it since 2026-11-03,
  the published `webalgebra-server-ldh:latest` image (2026-10-29) does not and answers "Unknown operation: request".
  The action spec needs a release of it, or a locally built image (`WEBALGEBRA_VERSION`), to run.

### What the check does not cover

- **Reads.** A plan's reads (GET, SELECT) go out with the reader's authority to this dataspace and anonymously
  elsewhere, bounded only by the deployment's egress proxy. A plan could read what the reader may read and write
  it into a public document; the write would show in the set, as a URI. A read policy is open.
- **Semantics.** The dialog shows methods and URIs, not what each update changes. Showing the bodies needs
  the executor to report them (`wa:write` carries method, uri and operations today).
- **Two packages replacing the same node** in a replacing mode: the later import wins, silently.
- **Denial of service** in a stylesheet (unbounded recursion) or a plan (the executor's deadline bounds it).

## The two cases

**Taxonomy editor** (LinkedDataHub-Apps `packages/editor/taxonomy/`, copied in `tests/packages/`): renders
(`ldh:TreeNode`, `ldh:ContentColumn`, `ac:PropertyEditor`), names its relations (`TreeChildrenLoad` by depth,
`TreeParentsLoad` over `skos:broader`/`skos:narrower`), asks for the open concept to be revealed, and offers
two actions: *Delete concept* (re-parent the narrower concepts, move the parents' `narrower` links, drop the
scheme's `hasTopConcept`, delete the document) and *Make top concept*. Zero violations; the previous version had 49.

**Messaging** (designed, not built): renders notes, threads and the inbox; contributes a drawer section (#527);
offers *Accept messages*, *Archive* and *Mark read* as actions. *Send* needs the executor to delegate to another
origin, which it does not today (it writes anonymously outside the trusted origin), so it waits on that.

## Order of work

1. The check, reporting only. Done: `PackageContract`, `PackageContractTest`.
2. Generic tree operations; the drawer on them. Done: `client/tree.xsl`.
3. The taxonomy package on the contract. Done, both copies.
4. Actions. Done: `ldh:action`, `ldh:Action`, `ldh:plan`, `client/action.xsl`, `client/webalgebra.xsl`.
5. Enforcement: a breaching stylesheet is left out of the composition, an `ldh:import` of one answers `422`
   with the violations; `tests/http/misc/PATCH-settings-package-containment.sh`'s probe moves to a
   deployment-level fixture, since it breaks the contract on purpose.
6. The read policy for plans, and write bodies in the dialog (an executor change).
7. Author documentation in LinkedDataHub-Apps; this file goes.
