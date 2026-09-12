// Locating an ontology-defined view block, and the constructor modal its Create button opens.
//
// A view declared in the ontology (`?property ldh:view ?block`) is injected into the page
// client-side and carries the attachment on the block element itself, so the property is
// what addresses it - there is no stored block in the document to name. The Create button
// arrives later still: the view renders its results, asks which container a new solution
// would be stored in, checks the access it has there, and only then decides on a button.
// Every locator here is therefore used with an auto-retrying assertion, never counted.
const SKOS = 'http://www.w3.org/2004/02/skos/core#';

export const BROADER = `${SKOS}broader`;
export const NARROWER = `${SKOS}narrower`;
export const PREF_LABEL = `${SKOS}prefLabel`;
export const IN_SCHEME = `${SKOS}inScheme`;

export const viewBlock = (page, property) =>
    page.locator(`div.block.ldh-block[data-property="${property}"]`);

// List mode: one li per solution, and a solution paired with its document renders as one
// row whose href is the DOCUMENT and whose title is the topic.
export const rows = block => block.locator('ul.ldh-list-block > li > a.row');
export const rowFor = (block, href) => rows(block).and(block.page().locator(`[href="${href}"]`));
export const rowLabels = block => rows(block).locator('span.ti');

export const createButton = block => block.locator('button.add-instance');

export const constructorModal = page => page.locator('div.modal.modal-constructor');

// One property's control group inside a constructor form: the group whose hidden RDF/POST
// predicate input names that property.
export const fieldFor = (modal, property) =>
    modal.locator(`div.ldh-prop-group:has(input[name="pu"][value="${property}"])`);

// A resource control is an `ou` input with a type-ahead attached, and the type-ahead only
// helps you FIND a URI - nothing validates or rewrites what is in the box, and focusout
// merely hides the panel. So a spec that already knows the URI fills it, and stays a spec
// about what the save produces rather than about the type-ahead.
export const fillResource = (modal, property, uri) =>
    fieldFor(modal, property).locator('input[name="ou"]').fill(uri);

export const fillText = (modal, property, text) =>
    fieldFor(modal, property).locator('input[name="ol"]').fill(text);

export const save = modal => modal.locator('button.btn-save').click();
