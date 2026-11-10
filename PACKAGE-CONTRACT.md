# The package contract: a plan

Drafted 2026-11-11. A plan, not documentation: once built, the contract is documented for package authors in
LinkedDataHub-Apps (`docs/extending/create-packages.ttl`) and this file is removed.

## Where it stands

A package stylesheet is composed into the platform's import tree right after `hooks.xsl` (`client/hooks.xsl` on the
client), by `StylesheetComposer` on both render paths. Import precedence beats priority, so a package outranks the
open modes' generic fallbacks and nothing else. The comment at the top of `hooks.xsl` states that contract and lists
the open modes. `tests/http/misc/PATCH-settings-package-containment.sh` checks that a package's rules in sealed modes
lose at any priority and that its rules in open modes win.

Precedence protects the platform's own rules. It leaves four gaps:

1. **Packages against each other.** Packages are imported in the order of their URIs (`PackageService.getPackages`
   sorts them), each after the one before, so the last one outranks the rest. Two packages with a rule for the same
   node in the same open mode do not conflict. The later one wins and the earlier one disappears, silently: their
   precedences differ, so Saxon reports nothing. In a mode that collects contributions (`ldh:RowHook`, and the
   drawer modes of #527), the losing package's whole contribution is gone. The only defence is the convention that a
   rule calls `xsl:next-match`, written in a comment.
2. **Rules where the platform has none.** Precedence decides only between rules that match the same node. A package
   can add a rule in a sealed mode, or in the default mode, for a node the platform has no rule for. The known case
   is already listed in `hooks.xsl`: Web-Client's leaf and shell modes that LinkedDataHub does not re-declare
   (`ac:FieldShell`, `ac:SelectShell`, `ac:InlineAlert`, `xhtml:Option`, `ac:RDFaAttributes`, `ac:image`) sit below
   the packages.
3. **What a rule outputs.** Precedence chooses which template runs, not what it emits. A rule in an open mode can
   emit any markup, including the platform's classes and ids (`id="tab-content"`).
4. **What client code writes.** On the client, a package's IXSL can write anywhere on the page:
   - `xsl:result-document href="#tab-bar"`;
   - `ixsl:set-attribute` and `ixsl:set-style` on any element reachable by an axis from its context node;
   - `ixsl:call` on `ixsl:page()` or `ixsl:window()`, which is all of the DOM and JavaScript.

   No precedence rule covers any of these.

On the server, the same stylesheet runs in Saxon-HE. There it can call `document()`, `doc()`, `unparsed-text()`,
`json-doc()` and `collection()` on URLs of its choosing, from inside the platform's process. Whether those requests
pass `URLValidator`, as the stylesheet copy does, is not established. Rule 1 below makes the question moot for
packages.

## The contract

Two rules, both checked by the platform rather than written in comments.

### 1. A package declares only what the platform opens to it

When a package's stylesheet is taken, the platform reads it as XML and refuses it if any of the following hold:

- **Modes.** A template has a `@mode` outside the open modes, has no `@mode` (the default mode), or names `#all`,
  `#default` or `#unnamed`. The open modes are one list in Java, generated from the `xsl:mode` declarations in
  `hooks.xsl` and `client/hooks.xsl` plus the value leaves of `imports/values.xsl`, so the list and the stylesheets
  cannot drift. A named template (`@name` and no `@match`) is allowed.
- **Names.** A function, a named template, a global variable or param, a key, an accumulator or a mode is declared
  in the `ldh:`, `ac:`, `lds:`, `xhtml:` or `svg:` namespace, or in no namespace. A package declares in its own
  namespace.
- **Global settings.** `xsl:output`, `xsl:strip-space`, `xsl:preserve-space`, `xsl:decimal-format`,
  `xsl:namespace-alias`, `xsl:global-context-item`, `xsl:character-map`, or an `xsl:mode` re-declaring a platform
  mode. These change how the whole composed stylesheet behaves, not only the package's own rules.
- **Imports.** An `xsl:import` or `xsl:include`. A package is one module, as it is today.
- **Writes, on either path.** `xsl:result-document`, `ixsl:set-attribute`, `ixsl:remove-attribute`,
  `ixsl:set-property`, `ixsl:set-style`, `ixsl:remove-property`, `ixsl:schedule-action`, a template in an `ixsl:on*`
  mode, and calls to `ixsl:page()`, `ixsl:window()`, `ixsl:call()`, `ixsl:apply()`, `ixsl:eval()` and
  `ixsl:http-request()`.
- **Reads of other resources.** Calls to `document()`, `doc()`, `doc-available()`, `unparsed-text()`,
  `unparsed-text-lines()`, `unparsed-text-available()`, `json-doc()`, `collection()`, `uri-collection()` and
  `transform()`. A package gets its data from the platform: the document being rendered, the metadata the platform
  passes in, and the requests it asks the platform to make (rule 2).
- **Ids.** A literal `id` attribute on a literal result element, or an `xsl:attribute name="id"`. The platform
  finds its own elements by id (`id('tab-content', ixsl:page())`), so a package addresses its markup by class.
- **Collecting modes.** In a mode marked as collecting (`ldh:RowHook` and the drawer's sections), a template whose
  last instruction is not `xsl:next-match`. This makes a collecting mode additive by construction: every package's
  rule for a node runs, in import order, and none can hide another's.

Every check is an XPath over the stylesheet, in a Java class `PackageContract` used by `PackageService`. Function
calls are found by the names in `@select`, `@test` and text value templates, parsed with Saxon's XPath parser, not
by string matching.

**Where it is checked.**
- When the platform copies the stylesheet (`PackageService.materializeStylesheet`). That happens on every path that
  composes a package, so a stylesheet that breaks the contract is never composed. It is left out and logged, as an
  unreachable stylesheet is today.
- When a dataspace imports the package (the `ldh:import` write on its settings). The import is refused with `422`,
  and the response describes each violation: the rule, the element and its line. The owner learns at import, not
  from a server log.

### 2. A package returns values; the platform writes them

With the writes banned, every open mode returns something, and the platform places it:

| Mode | The package returns | The platform |
| --- | --- | --- |
| `ldh:TreeNode`, `ac:PropertyEditor`, the value leaves | markup | puts it where the mode was applied, as today |
| `ldh:ContentColumn` | markup | wraps it in `.ldh-content-aside`, as today |
| `ldh:RowHook` | factories, `function(item()?) as map(*)` | invokes them inside `ixsl:promise`, as today |
| `ldh:TreeChildrenLoad` | the query for one node's children | fetches it and renders the children (`ldh:TreeChildrenFetch`), as today |
| `ldh:DrawerSections` (#527) | `div.sb-section` elements | appends them above the document tree |
| `ldh:DrawerSectionUpdate` (#527) | the section's new content, or nothing | replaces the content of the section the rule matched, or leaves it |

A factory or a continuation cannot write either, since its body is package code under the same checks. It
asks the platform's functions to write, so those functions decide where a write may land:

- **Each hook application has a region.** It is the node the platform applied the mode to: the row, the content
  column or the drawer section.
- **The platform's write functions take a container** (`ldh:load-block`, `ldh:TreeChildrenFetch` and the tree
  functions below). When they are called on a package's behalf, they check that the container is inside the region
  (`$container/ancestor-or-self::* intersect $region`) and refuse otherwise.

A package can still read the whole page through axes, which is harmless. It can write only where it was asked to
contribute.

**What the platform has to add.** The taxonomy package is the only package, and every write it makes today is
inside its own concept tree:
- expanding a node: `ixsl:set-attribute` on the disclosure button, `append-content` of the children list;
- marking the current concept: `is-active`, `aria-current`;
- scrolling the tree to that concept: `ixsl:call` on `getBoundingClientRect`, `set-property` of `scrollTop`.

The drawer's document tree does the same in the platform (`ldh:doctree-descend`, `ldh:DocTreeActivateHref`), bound
to containment. These move to `client/tree.xsl` as generic operations on any `.ldh-tree`:
- expand a node;
- activate the node for a URI;
- scroll it into view;
- reveal a path.

To reveal a path, the package supplies one hop's query, the way `ldh:TreeChildrenLoad` supplies the children query.
The concept tree's climb shows that one hop at a time is the shape that works across documents. The document tree
then becomes one user of the generic reveal, and the taxonomy package another.

## What it breaks

**The taxonomy package**, in LinkedDataHub-Apps and its copy in `tests/packages/editor/taxonomy/`:
- nine functions in the `ldh:` namespace (`ldh:conceptree-*`) move to the package's own namespace;
- the reveal walk (`ldh:conceptree-reveal` and the functions it chains to) is replaced by the generic reveal, with
  the package keeping only its one-hop parents query;
- what remains is markup in `ldh:TreeNode` and `ldh:ContentColumn`, the `ldh:RowHook` factory, and the children
  query.

Before enforcement ships, the taxonomy package must pass the contract, or every dataspace that imports it loses it.

**Deployment stylesheets are not packages** and are not checked. A deployment's entry stylesheet (named by
`ac:stylesheet`, importing the platform's `layout.xsl`) outranks the platform and is trusted as the platform is.
The contract covers code a dataspace owner imports from a registry, not code the operator deploys.

## Not covered

- **Markup inside a package's own region.** A package can still emit a broken table or a class that restyles
  something. That spoils its own region, and checking it would mean validating output.
- **Two packages replacing the same node** in a replacing mode (`ldh:TreeNode`, the value leaves). The later one
  still wins, which is the meaning of "replace". The composer logs, as a warning at composition, when two packages'
  templates in the same replacing mode have textually identical match patterns. Patterns that overlap without being
  identical are not detected.
- **Denial of service.** A package can recurse without end or build a huge result. Saxon has no limit for either,
  and a check cannot find either.
- **The Web-Client modes below the packages** (gap 2). The mode allowlist closes them for packages without
  splitting Web-Client's default module. The split stays the right fix for Web-Client's own sake.

## Order of work

Each step is its own PR off `develop`, each with its tests.

1. **The check, reporting only.**
   - `PackageContract` with every rule above.
   - Unit tests with one probe stylesheet per rule (a passing one and a failing one), in the style of
     `StylesheetComposer`'s tests.
   - Wired into `materializeStylesheet` to log violations without leaving the stylesheet out.
   - The run against the taxonomy package is the work list for step 3.
2. **The generic tree operations** in `client/tree.xsl` (expand, activate, scroll into view, reveal), with the
   document tree moved onto them. The drawer's Playwright specs under `tests/ui/specs/shell/drawer/` must pass
   unchanged.
3. **The taxonomy package on the contract**, in LinkedDataHub-Apps first and then its copy in `tests/packages`.
   The concept-tree specs (`tests/ui/specs/document/content-aside/concept-tree.spec.mjs` and the ones using
   `lib/tree.mjs`) must pass unchanged.
4. **The region check** in the platform's write functions. A probe package under `tests/packages` passes a
   container outside its region to `ldh:load-block`; a Playwright spec checks that the write is refused and that the
   page outside the region is unchanged.
5. **#527 on the contract.**
   - `ldh:DrawerSections` returns sections and is a collecting mode.
   - `ldh:DrawerSectionUpdate` returns content.
   - The same probe package adds two sections from two rules in different packages; a spec checks that both
     render, in import order, above the document tree, and that each one's active entry follows an in-page
     navigation.
6. **Enforcement.**
   - `materializeStylesheet` leaves a failing stylesheet out.
   - The settings import answers `422` with the violations.
   - `tests/http/misc/` gains an import of a failing package, expecting `422` and its description.
   - `PATCH-settings-package-containment.sh` still passes: its probe breaks the contract on purpose (`ac:Head`,
     `ldh:ContentBody`), so it moves to a deployment-level fixture or is refused at import, which is then what it
     tests.
7. **The documentation** for package authors in LinkedDataHub-Apps: the open modes, what each returns, the
   collecting modes and `xsl:next-match`, the checks and their `422`. This file is then removed.

Steps 1 and 2 can go in parallel. Step 6 waits on step 3, so that the one existing package is never refused.

## Open questions

1. **Refuse or strip?** A violating stylesheet could be composed with the offending templates removed, rather than
   left out whole. *Proposal:* leave it out. A partly working package is harder to diagnose than a missing one, and
   the `422` at import says what to fix.
2. **Event handlers.** With `ixsl:on*` modes banned, a package's interactive widget (a button in its column) has
   only the platform's handlers. *Proposal:* add open modes for the events a package needs, each applied by a
   platform handler to the clicked element inside a package region and returning work like `ldh:RowHook`. Start
   with click, when a package needs one. The taxonomy package does not: its disclosure buttons go through the
   platform's tree handler.
3. **Registry packages already copied.** Existing deployments have package stylesheets in their package root
   (`materializeStylesheet` copies once). *Proposal:* check the copy on every composition, not only when copying, so
   step 6 applies to stylesheets already on disk.
