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

// Table mode: one tr per solution, and a solution paired with its document renders as one
// row for the TOPIC - the view suppresses the document that names it as its primary topic
// (client/block/view.xsl, "hide documents that are paired with resources"). The row's first
// cell anchors the topic, so a row is addressed by the CONCEPT URI, not the document's.
export const rows = block => block.locator('table > tbody > tr');
export const rowFor = (block, href) => rows(block).filter({ has: block.page().locator(`a[href="${href}"]`) });
export const rowLabel = row => row.locator('td:first-child a');
export const rowLabels = block => rowLabel(rows(block));

export const createButton = block => block.locator('button.add-instance');

