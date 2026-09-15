// The SPARQL endpoint's own page: a result set asked for as a document, rendered as the application
// shell with a results table in it.
//
// Both halves of the round trip are asserted because both were broken and neither was visible to
// http-tests. The server used to answer 500 - the shell binds its content pane as="element()" and
// ldh:TabPanel matched rdf:RDF only, so a result set produced no pane and failed the cardinality
// check rather than degrading to an unstyled page. Then the client wiped what the server did send:
// it re-fetches the document after hydrating, and the re-fetch dropped the ?query= that the
// representation is a function of, so the endpoint answered 400 "Query string not provided" and the
// error block was painted over the table. That second failure is invisible to a suite that only
// reads responses - the table is in the HTML either way, for about a second.
//
// The query binds its own values, so what the table shows is a function of the query alone and the
// assertions hold against any dataset.
import { test, expect } from '../lib/console.mjs';
import { settled } from '../lib/settle.mjs';
import { endUserBase } from '../lib/stack.mjs';

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
    test.beforeEach(({}, testInfo) => {
        test.skip(testInfo.project.name !== 'owner',
            'the endpoint grants acl:Read to authenticated agents; an anonymous request is a 401 and says nothing about rendering');
    });

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
});
