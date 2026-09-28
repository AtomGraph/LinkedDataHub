// Locating an ontology-defined view block, and the constructor modal its Create button opens.
//
// A view declared in the ontology (`?property ldh:view ?block`) is injected into the page
// client-side and carries the attachment on the block element itself, so the property is
// what addresses it - there is no stored block in the document to name. The Create button
// arrives later still: the view renders its results, asks which container a new solution
// would be stored in, checks the access it has there, and only then decides on a button.
// Every locator here is therefore used with an auto-retrying assertion, never counted.
import { fixtures } from './fixtures.mjs';

const SKOS = 'http://www.w3.org/2004/02/skos/core#';

export const BROADER = `${SKOS}broader`;
export const NARROWER = `${SKOS}narrower`;
export const PREF_LABEL = `${SKOS}prefLabel`;
export const IN_SCHEME = `${SKOS}inScheme`;

export const viewBlock = (page, property) =>
    page.locator(`div.block.ldh-block[data-property="${property}"]`);

// The rows a view opens with, and the size its pager resizes from. The fixture seeds 25 children
// against it so that there is a second page at all - which is what four specs each wrote out for
// themselves, two of them to decide whether they have anything to assert (`itemCount <= PAGE`).
export const PAGE = 20;

// Table mode: one tr per solution, and a solution paired with its document renders as one
// row for the TOPIC - the view suppresses the document that names it as its primary topic
// (client/block/view.xsl, "hide documents that are paired with resources"). The row's first
// cell anchors the topic, so a row is addressed by the CONCEPT URI, not the document's.
export const rows = block => block.locator('table > tbody > tr');
export const rowFor = (block, href) => rows(block).filter({ has: block.page().locator(`a[href="${href}"]`) });
export const rowLabel = row => row.locator('td:first-child a');
export const rowLabels = block => rowLabel(rows(block));

export const createButton = block => block.locator('button.add-instance');

// The fixture's own view block (lib/fixtures.mjs, `view`), addressed by the view it renders rather
// than by its chrome: the container also renders the built-in children view, and `.first()` on the
// toolbar class lands on whichever the document lists first. The block that carries the @about is
// the inner one, and it is the one that owns the card header, the toolbar and the results.
export const fixtureView = page => page.locator(`div.block.ldh-block[about="${fixtures.view}"]`);

// List mode, which a view opens in: one li per solution, the row an anchor to the document, its
// title in .ti and its description in .desc - which for the fixture items is the kind, so the
// order and the filtering of the rows can be read off the rows themselves.
export const listRows = block => block.locator('.container-results li a.row');
export const listTitles = block => listRows(block).locator('.ti');
export const listKinds = block => listRows(block).locator('.desc');

// The status line under the card title: the count, which the rows cannot state for themselves.
export const resultCount = block => block.locator('.ldh-view-status .count');

// A count as the status line may carry it, bounded so that `Total results 8` is not satisfied by
// `Total results 18`.
export const counting = n => new RegExp(`(^|\\D)${n}(\\D|$)`);

// The pager sits outside .container-results, so it survives every re-render of the rows - and is
// emptied, rather than removed, when the result set fits on one page.
export const pager = block => block.locator('.ldh-pager');

// The toolbar's mode switcher, to 'list', 'table', 'grid', 'chart', 'map' or 'graph'. It is a
// popover: the mode buttons are in the DOM from the first render and not clickable until the
// trigger opens it, so a switch is two clicks rather than one.
export async function switchMode(block, mode) {
    await block.locator('.ldh-view-toolbar .ldh-mode button.drop-toggle').click();
    await block.locator(`.view-mode-list button.${mode}-mode`).click();
}

// A facet by the SELECT variable it filters, which the pill carries as its `object` input - the
// predicate label on the pill is a display concern and may be translated.
export const facetFor = (block, varName) =>
    block.locator('.ldh-view-toolbar .facet').filter({ has: block.page().locator(`input[name="object"][value="${varName}"]`) });
// A value in an open facet popover, by the value it names.
export const facetOption = (facet, value) =>
    facet.locator('.facet-pop button.opt').filter({ has: facet.page().locator('span.nm', { hasText: new RegExp(`^${value}$`) }) });
