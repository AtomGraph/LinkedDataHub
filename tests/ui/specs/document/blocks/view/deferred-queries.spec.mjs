// The two whole-result-set queries a view used to send on every load, asked only when their answer
// can be seen.
//
// Related-results discovery groups every predicate of every solution - not the page, the whole set -
// and checks that each object is a subject somewhere. The container lookup joins every solution to its
// document and that document's container. Both scale with the result set rather than the page, and on
// a view over a few thousand solutions each took 4-12 s of store time per load (measured 2026-10-19 on
// the LTLOD dataset, a member's votes). Neither shows anything until asked: the pivot chips sit in a
// bar the card draws collapsed, and the container only becomes a Create button for an agent who could
// create there. So discovery waits for the controls toggle, and the lookup for a class to construct and
// an agent who may write.
//
// The requests are told apart by the shape of their SPARQL, because nothing else distinguishes one
// POST to the endpoint from another: discovery is the only query projecting ?objectPredicate (its
// EXISTS over each object's own triples), the lookup the only one joining documents to a
// sioc:has_container ?container. The Create button that the lookup leads to is asserted where it is
// offered, in create.spec.
import { test, expect } from '../../../../lib/console.mjs';
import { goto, loaded } from '../../../../lib/settle.mjs';
import { fixtures, itemTitle } from '../../../../lib/fixtures.mjs';
import { controlToggle } from '../../../../lib/block.mjs';
import { fixtureView, listTitles } from '../../../../lib/view.mjs';

const HAS_CONTAINER = 'http://rdfs.org/sioc/ns#has_container';
const DISCOVERY = /\?objectPredicate/;
const CONTAINER_LOOKUP = /sioc\/ns#has_container> \?container/;

// Every query the page POSTs to its SPARQL endpoint, recorded from before navigation on.
function sparqlQueries(page) {
    const sent = [];
    page.on('request', request => {
        if (request.method() === 'POST' && new URL(request.url()).pathname === '/sparql') sent.push(request.postData() ?? '');
    });
    return pattern => sent.filter(query => pattern.test(query)).length;
}

// What a view sends next is decided when its results render, so "nothing was sent" can only be read
// once the block has finished loading and the requests it fired have had time to leave.
async function quiet(page) {
    await loaded(page);
    await page.waitForLoadState('networkidle');
}

test.describe('the queries a view defers', { tag: '@owner' }, () => {
    test('discovers related results only once the controls are opened', async ({ page }) => {
        const sent = sparqlQueries(page);
        await goto(page, fixtures.container);
        const block = fixtureView(page);
        await expect(listTitles(block).first()).toHaveText(itemTitle(1));
        await quiet(page);

        // Rendered with the bar collapsed: no discovery, and no chips waiting behind it.
        await expect(block.locator('.ldh-pivot-bar')).toHaveClass(/\bis-collapsed\b/);
        expect(sent(DISCOVERY)).toBe(0);
        await expect(block.locator('.ldh-pivot-pills > *')).toHaveCount(0);

        // Opening the controls discovers, once, and the chips arrive.
        await controlToggle(block).click();
        await expect(block.locator(`.ldh-pivot-bar button.ldh-pivot-pill[data-dir="out"][title="${HAS_CONTAINER}"]`)).toBeVisible();
        expect(sent(DISCOVERY)).toBe(1);

        // Closing and reopening shows the same result set, so it is not discovered again.
        await controlToggle(block).click();
        await controlToggle(block).click();
        await quiet(page);
        expect(sent(DISCOVERY)).toBe(1);
        await expect(block.locator(`.ldh-pivot-bar button.ldh-pivot-pill[data-dir="out"][title="${HAS_CONTAINER}"]`)).toBeVisible();
    });

    test('asks for no container when the view has no class to create', async ({ page }) => {
        const sent = sparqlQueries(page);
        await goto(page, fixtures.container);
        const block = fixtureView(page);
        await expect(listTitles(block).first()).toHaveText(itemTitle(1));
        await quiet(page);

        // An authored view names no class to construct - only an ontology view's property range does -
        // so no answer the lookup could give would become a button.
        await expect(block).not.toHaveAttribute('data-for-class');
        expect(sent(CONTAINER_LOOKUP)).toBe(0);
    });
});
