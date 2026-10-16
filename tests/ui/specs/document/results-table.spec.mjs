// The SPARQL endpoint's own page: a result set asked for as a document, rendered as the application
// shell with a results table in it.
//
// Both halves of the round trip are asserted because both were broken and neither was visible to
// tests/http. The server used to answer 500 - the shell binds its content pane as="element()" and
// ldh:TabPanel matched rdf:RDF only, so a result set produced no pane and failed the cardinality
// check rather than degrading to an unstyled page. Then the client wiped what the server did send:
// it re-fetches the document after hydrating, and the re-fetch dropped the ?query= that the
// representation is a function of, so the endpoint answered 400 "Query string not provided" and the
// error block was painted over the table. That second failure is invisible to a suite that only
// reads responses - the table is in the HTML either way, for about a second.
//
// The query binds its own values, so what the table shows is a function of the query alone and the
// assertions hold against any dataset.
import { test, expect } from '../../lib/console.mjs';
import { settled } from '../../lib/settle.mjs';
import { endUserBase } from '../../lib/stack.mjs';

const query = 'SELECT ?s ?label WHERE { VALUES (?s ?label) { (<https://example.org/results-table> "Results table") } }';
const resultsUrl = `${endUserBase}sparql?query=${encodeURIComponent(query)}`;

const table = page => page.locator('#tab-content .ldh-pane table.ac-table');

// The client's own re-fetch of the document, as distinct from the browser's navigation to it: the
// same URL arrives twice, and it is what happens after the second one that these specs are about.
// Waiting on it rather than on a timeout is what keeps the assertion from passing against markup
// that is about to be replaced.
const refetch = page => page.waitForResponse(response =>
    response.url().startsWith(`${endUserBase}sparql?`) && response.request().resourceType() !== 'document');

async function expectResults(page) {
    await expect(table(page)).toHaveCount(1);
    // textContent, not innerText: the design system upper-cases header cells in CSS, and the
    // variable names are what the query projects, not what the reader sees
    await expect(table(page).locator('thead th')).toHaveText(['s', 'label']);
    await expect(table(page).locator('tbody tr')).toHaveCount(1);
    // a URI binding is a link to the resource, not the text of whatever label was found for it.
    // @title rather than @href: an off-origin URI is linked through the proxy and that form is not
    // this spec's subject
    await expect(table(page).locator('tbody tr td').first().locator('a'))
        .toHaveAttribute('title', 'https://example.org/results-table');
    await expect(table(page).locator('tbody tr td').nth(1)).toHaveText('Results table');
}

test.describe('SPARQL results', () => {
    test('renders a result set as a table that survives the client re-fetching the document', async ({ page }) => {
        const refetched = refetch(page);
        await page.goto(resultsUrl, { waitUntil: 'domcontentloaded' });

        // what the server sent, before Saxon-JS has touched it
        await expectResults(page);

        await refetched;
        await settled(page);

        // and what is left after it has
        await expectResults(page);
    });

    test('rebuilds the table client-side when returning to it with no server-rendered body', async ({ page }) => {
        await page.goto(resultsUrl, { waitUntil: 'domcontentloaded' });
        await refetch(page);
        await settled(page);

        // leave through the shell's own link, which navigates client-side, and come back. The pane is
        // then rebuilt from the result set alone - the path a link to the endpoint from another
        // document takes, where there is no server-rendered table to fall back on
        await page.locator('a.ldh-wordmark').first().click();
        await expect(table(page)).toHaveCount(0);

        await page.goBack();
        await settled(page);

        await expectResults(page);
    });

    // The table's frame is its own rounded border, which the collapsing border model ignores: the border
    // drew square while the head cells rounded inside it, and left a wedge of page in each corner. In the
    // separating model the radius takes, the row rules have to live on the cells - a row's border exists
    // only in the collapsing one - and the table still does not clip (overflow would make it a
    // scrollport, and the sticky head inert), so the four corner cells round their own fills to the
    // table's inner curve. Two rows, so there is a rule between rows to find and a last row without one.
    test('draws a rounded frame with the corner cells inside it and rules between the rows', async ({ page }) => {
        const twoRows = 'SELECT ?s ?label WHERE { VALUES (?s ?label) { (<https://example.org/results-table/1> "One") (<https://example.org/results-table/2> "Two") } }';
        const refetched = refetch(page);
        await page.goto(`${endUserBase}sparql?query=${encodeURIComponent(twoRows)}`, { waitUntil: 'domcontentloaded' });
        await refetched;
        await settled(page);

        await expect(table(page).locator('tbody tr')).toHaveCount(2);
        const frame = await table(page).evaluate(t => {
            const s = getComputedStyle(t), px = (el, prop) => parseFloat(getComputedStyle(el)[prop]);
            const head = t.tHead.rows[0].cells, rows = t.tBodies[0].rows, last = rows[rows.length - 1].cells;
            return {
                collapse: s.borderCollapse,
                inner: Math.max(0, parseFloat(s.borderTopLeftRadius) - parseFloat(s.borderLeftWidth)),
                corners: [px(head[0], 'borderTopLeftRadius'), px(head[head.length - 1], 'borderTopRightRadius'),
                    px(last[0], 'borderBottomLeftRadius'), px(last[last.length - 1], 'borderBottomRightRadius')],
                headRule: px(head[0], 'borderBottomWidth'),
                rowRule: px(rows[0].cells[0], 'borderBottomWidth'),
                lastRowRule: px(last[0], 'borderBottomWidth'),
            };
        });

        expect(frame.collapse).toBe('separate');
        expect(frame.inner).toBeGreaterThan(0);
        for (const corner of frame.corners) expect(corner).toBeCloseTo(frame.inner, 2);
        expect(frame.headRule).toBe(1);
        expect(frame.rowRule).toBe(1);
        expect(frame.lastRowRule).toBe(0);
    });
});
