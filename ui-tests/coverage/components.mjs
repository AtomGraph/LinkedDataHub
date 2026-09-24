// What the product renders, so that what nobody has tested can be named.
//
// `specs/` mirrors this tree, but a folder cannot represent an absence - git does not track an
// empty directory - so the components with no specs are declared here and nowhere else. The
// report joins the three: what is declared, which folders hold specs, and what actually renders
// on the probe pages.
//
// FOUR RULES, each of them load-bearing:
//
//   · A `selector` answers "did this component render", never "what does it say". It is a
//     presence probe. If a spec would want it, it is too specific and belongs inline at that
//     spec's call site, where the reader of the assertion can see it.
//   · `xsl` must resolve on disk AND must emit one of the selector's own tokens, both asserted.
//     That is what keeps a CSS-only class out of the inventory: `.ldh-nblock`,
//     `.ldh-query-block`, `.ldh-auth`, `.ldh-import-flow`, `.ldh-onto-grid` and `.ldh-rdf-type`
//     are all styled in app.css and emitted by nothing, so a record for any of them would print a
//     permanent gap for a component that does not exist. Checking only that the FILE exists is
//     not enough - `.ldh-rdf-type` was declared against a real module that never mentions it, and
//     survived until the token check went in.
//   · A component is declared when a spec could reasonably be written about IT ALONE. The view
//     block is a unit; its pager and its facet pills are not, or every parent's spec would owe
//     coverage to a dozen children it already asserts.
//   · `appears: 'gesture'` marks what no page load can show - a modal, a popover, an editor
//     overlay. Its probe columns read `-`, and an uncovered one is a gap on the strength of the
//     declaration rather than of a count, because waiting for it to render would measure nothing.
//
// `xsl` resolves against src/main/webapp/static/com/atomgraph/linkeddatahub/xsl/, except a path
// beginning `packages/`, which resolves from the repository root: a package's surfaces are the
// package's, and the inventory says so rather than pretending the platform emits them.
//
// NOT YET DECLARED, because each needs a selector read off the running page rather than guessed:
// the sign-up screens, the CSV/RDF import flow, the ontology editor, the memento version list,
// the packages list, and the app-settings and access-request modals. The report's "undeclared
// anatomy" section is what will hand over their real class names.

export const components = [
    {
        id: 'shell', name: 'App shell', selector: '#visible-body', xsl: 'layout.xsl',
        children: [
            {
                id: 'header', name: 'Header bar', selector: '.ldh-header', xsl: 'layout.xsl', grouping: true,
                children: [
                    { id: 'address', name: 'Address bar', selector: '.ldh-header .ldh-address', xsl: 'layout.xsl' },
                    { id: 'account', name: 'Account menu', selector: '.ldh-avatar-wrap', xsl: 'layout.xsl' },
                ],
            },
            { id: 'tabs', name: 'Dataspace tab strip', selector: 'ul.ldh-tabs', xsl: 'layout.xsl' },
            {
                id: 'drawer', name: 'Dataspace drawer', selector: '.ldh-sidebar', xsl: 'client/navigation.xsl',
                children: [
                    {
                        id: 'document-tree', name: 'Document tree',
                        // The drawer's tree and the taxonomy package's concept tree share the
                        // .ldh-tree / div.tree-row vocabulary by design. One vocabulary, two
                        // placements, two components - so both are declared, and lib/tree.mjs
                        // takes the root as a parameter rather than knowing which one it is in.
                        selector: '.ldh-sidebar .document-tree', xsl: 'client/tree.xsl', lib: 'lib/tree.mjs',
                    },
                    { id: 'class-list', name: 'Class list', selector: '.sb-classes', xsl: 'client/navigation.xsl' },
                    { id: 'saved-views', name: 'Geo / Latest / Search views', selector: '.sb-other', xsl: 'client/navigation.xsl' },
                ],
            },
            { id: 'footer', name: 'Footer', selector: '.ldh-footer', xsl: 'layout.xsl' },
        ],
    },
    {
        id: 'document', name: 'Document body', selector: '.document-body', xsl: 'document.xsl', grouping: true,
        children: [
            {
                id: 'action-bar', name: 'Action bar', selector: '.ldh-actionbar', xsl: 'document.xsl', grouping: true,
                children: [
                    { id: 'create', name: 'Create menu', selector: '.ldh-add-wrap', xsl: 'document.xsl' },
                    { id: 'breadcrumb', name: 'Breadcrumb', selector: '.ldh-bc', xsl: 'document.xsl' },
                    { id: 'mode', name: 'Mode switcher', selector: '.ldh-actionbar .ldh-mode', xsl: 'document.xsl' },
                    { id: 'overflow', name: 'Actions kebab', selector: '.ldh-of-wrap', xsl: 'document.xsl' },
                    { id: 'timestamp', name: 'Document timestamp', selector: '.ldh-ab-ts', xsl: 'document.xsl' },
                ],
            },
            { id: 'prop-list', name: 'Property list (read mode)', selector: 'dl.ldh-prop-form', xsl: 'resource.xsl' },
            {
                id: 'results-table', name: 'Result-set table',
                // A result set asked for as a document: document.xsl renders it as the table
                // itself, a direct child of .content-body. A view block's table sits deeper, so
                // the child combinator is what keeps the two from counting as each other.
                selector: '.content-body > table.ac-table', xsl: 'document.xsl',
            },
            {
                id: 'content-aside', name: 'Content column', selector: '.ldh-content-aside', xsl: 'document.xsl',
                children: [
                    {
                        id: 'concept-tree', name: 'Concept tree', selector: '.ldh-content-aside ul.concept-tree',
                        xsl: 'packages/editor-taxonomy/skos.xsl', owner: 'package:skos', lib: 'lib/tree.mjs',
                    },
                ],
            },
            {
                id: 'blocks', name: 'Block card', selector: '.block.ldh-block', xsl: 'resource.xsl', lib: 'lib/block.mjs',
                children: [
                    {
                        id: 'view', name: 'View block', selector: '.block.ldh-block:has(.ldh-view-toolbar)',
                        xsl: 'client/block/view.xsl', lib: 'lib/view.mjs',
                    },
                    { id: 'chart', name: 'Chart block', selector: '.block.ldh-block:has(.chart-controls)', xsl: 'client/block/chart.xsl' },
                    // Uncovered for a reason worth keeping: a query reaches the page wrapped in an
                    // object block, and seeding one makes EVERY spec on that page fail. The editor
                    // YASQE fetches http://prefix.cc/popular/all.file.json for prefix completion -
                    // plain HTTP from an HTTPS page - so the browser blocks it as mixed content and
                    // the page logs a console error that lib/console.mjs rightly fails on. Measured
                    // 2026-09-25: the fixture was seeded, 14 previously-green tests went red, and
                    // the fixture was taken back out.
                    { id: 'query', name: 'Query block', selector: '.block.ldh-block:has(.ldh-sparql)', xsl: 'client/block/query.xsl' },
                    { id: 'object', name: 'Object block', selector: '.ldh-obj-value', xsl: 'client/block/object.xsl' },
                    { id: 'xhtml', name: 'XHTML content block', selector: '.block.ldh-block [typeof$="#XHTML"]', xsl: 'imports/default.xsl' },
                    { id: 'map', name: 'Map block', selector: '.map-canvas', xsl: 'client/map.xsl' },
                    { id: 'graph3d', name: '3D graph block', selector: '.graph-3d-canvas', xsl: 'client/graph3d.xsl' },
                ],
            },
        ],
    },
    {
        // Kit controls with no host of their own: they appear in the shell, in the action bar and
        // in block heads alike, so they belong to no one region's subtree. A control that writes a
        // value into a form is a form control and lives under forms/; this is for the chrome ones.
        id: 'controls', name: 'Kit controls', selector: '.ac-menu-anchor', xsl: 'client.xsl', grouping: true,
        children: [
            { id: 'menu', name: 'Dropdown menu', selector: '.ac-menu-anchor:has(button.drop-toggle)', xsl: 'client.xsl' },
        ],
    },
    {
        id: 'forms', name: 'Write layer', selector: 'form.ldh-prop-form', xsl: 'client/form.xsl',
        children: [
            { id: 'combobox', name: 'Resource combobox', selector: '.ac-cb-box', xsl: 'client/combobox.xsl', appears: 'gesture' },
            { id: 'row-form', name: 'Inline row form', selector: '.ldh-prop-row.is-editing', xsl: 'client/form.xsl', appears: 'gesture' },
            // Uncovered, and not for want of trying: the control is reached by constructing an
            // nfo:FileDataObject, and the fixture dataspace's ontology declares no File class for
            // the Create menu to offer. Covering it needs an application that does - which is a
            // fixture the suite does not have rather than a spec nobody wrote.
            { id: 'upload', name: 'File upload', selector: '.ac-fileinput', xsl: 'imports/nfo.xsl', appears: 'gesture' },
        ],
    },
    {
        id: 'overlays', name: 'Overlay layer', selector: '.ac-backdrop', xsl: 'client/modal.xsl', appears: 'gesture', grouping: true,
        children: [
            { id: 'annotation-dialog', name: 'RDFa annotation overlay', selector: '#rdfa-editor-overlay', xsl: 'rdfa-editor/overlay.xsl', appears: 'gesture' },
            { id: 'links', name: 'Block links popover', selector: '.links-pop', xsl: 'resource.xsl', appears: 'gesture' },
            {
                id: 'modal', name: 'Modal dialog', selector: '.ac-modal', xsl: 'client/modal.xsl', appears: 'gesture',
                children: [
                    { id: 'document-form', name: 'Document edit modal', selector: '.modal-constructor', xsl: 'client/modal.xsl', appears: 'gesture' },
                    { id: 'constructor-editor', name: 'Constructor editor', selector: 'fieldset.ldh-ctor-card', xsl: 'client/constructor.xsl', appears: 'gesture' },
                    { id: 'ontology-import', name: 'Import ontology dialog', selector: '#add-data', xsl: 'client/modal.xsl', appears: 'gesture', base: 'admin' },
                    { id: 'welcome', name: 'Welcome modal', selector: '.modal-first-time-message', xsl: 'client/modal.xsl', appears: 'gesture' },
                    // Uncovered, and the attempt turned up a question rather than a spec: the way
                    // in is the action bar's timestamp becoming a link to the TimeMap, and on a
                    // fixture document that HAS versions (`ldh get --timemap` lists them) no
                    // `a.document-history` is rendered at all. Until that is understood, a spec
                    // here would be asserting against a door that is not there.
                    { id: 'memento', name: 'Version diff', selector: '.ldh-diff-tint', xsl: 'client/memento.xsl', appears: 'gesture' },
                ],
            },
        ],
    },
];

// Folders under specs/ that are not components and must not be reported as uncovered ones. A
// claim that crosses components is filed by what it claims, not by what it touches.
export const axes = ['axes'];
