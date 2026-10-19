// The query block: a stored SPARQL query, run and shown.
//
// Rendered from a document of its own (lib/fixtures.mjs, `queryDocument`) because its editor
// costs the page a console error: YASQE 2 fetches its prefix list from http://prefix.cc over
// plain HTTP, the browser blocks that as mixed content from an HTTPS page, and lib/console.mjs
// fails any page that logs it - rightly, and it is the reason this block was the one component
// in the inventory with no spec. The allowance below is one pattern with the defect named, and
// it is the platform's to remove: client/block/query.xsl initialises the editor with its default
// autocompleters, and the fetch goes with them.
//
// What the block does on arrival is run the query and table the result set, editor folded away.
// The editor unfolds from the card header, and Run re-queries with whatever it says - which is
// the assertion that matters, since a Run that re-ran the STORED query would table the same rows.
//
// The View tab does not work, and the last test pins that as an expected failure. Its handler
// (client/block/query.xsl, the view-mode tab) builds a detached `<div typeof="ldh:View">` and
// applies ldh:RenderRow to it with the block passed as a parameter - but ldh:RenderRow
// (client/block.xsl) declares no parameters and hands the element to ldh:RowHook bare, whose
// `block` defaults to the nearest ancestor `.block` of a node that has no ancestors at all. The
// page reports "Required cardinality of value in 'xsl:param name=\"block\"' expression is exactly
// one; supplied value is empty" and the results container stays empty. Measured 2026-09-28 on
// develop. The test passes the day the tab renders rows, and then reports the annotation as stale.
import { test, expect } from '../../../lib/console.mjs';
import { goto } from '../../../lib/settle.mjs';
import { fixtures, itemCount, itemTitle, itemUri } from '../../../lib/fixtures.mjs';
import { endUserBase } from '../../../lib/stack.mjs';

// The block that carries the query's @about is the inner one: it owns the head with the editor
// toggle, the form, and the results container.
const queryBlock = page => page.locator(`div.block.ldh-block[about="${fixtures.query}"]`);
const resultsTable = block => block.locator('.sparql-query-results .google-visualization-table');
const editorToggle = block => block.locator('.ldh-block-head button.tb-query');

test.describe('the query block', { tag: '@owner' }, () => {
    test.beforeEach(({ allowNoise }) => {
        allowNoise.push({
            pattern: /prefix\.cc/,
            reason: 'YASQE 2 fetches http://prefix.cc for prefix completion, which the browser blocks as '
                + 'mixed content - a platform defect in the editor initialisation, not this spec\'s doing',
        });
    });

    test('runs its stored query on arrival and tables the result set', async ({ page }) => {
        await goto(page, fixtures.queryDocument);
        const block = queryBlock(page);

        const table = resultsTable(block);
        await expect(table).toBeVisible({ timeout: 30_000 });
        // A header row and one row per item, the first being the first by title.
        await expect(table.locator('tr')).toHaveCount(itemCount + 1);
        await expect(table.locator('tr').first()).toContainText('title');
        await expect(table.locator('tr').nth(1)).toContainText(itemTitle(1));
        await expect(block.locator('.query-results-tabs button.chart-mode')).toHaveClass(/is-on/);
        // Results first: the editor is there, folded.
        await expect(block.locator('.ldh-sparql')).toBeAttached();
        await expect(block.locator('.ldh-sparql')).toBeHidden();
    });

    test('the head toggle unfolds the editor with the stored query in it', async ({ page }) => {
        await goto(page, fixtures.queryDocument);
        const block = queryBlock(page);
        await expect(resultsTable(block)).toBeVisible({ timeout: 30_000 });

        await editorToggle(block).click();

        await expect(block.locator('.ldh-sparql')).toBeVisible();
        await expect(block.locator('.CodeMirror')).toBeVisible();
        await expect(block.locator('.CodeMirror')).toContainText('has_container');
        await expect(editorToggle(block)).toHaveAttribute('aria-pressed', 'true');

        await editorToggle(block).click();
        await expect(block.locator('.ldh-sparql')).toBeHidden();
    });

    test('Run re-queries with what the editor now says', async ({ page }) => {
        await goto(page, fixtures.queryDocument);
        const block = queryBlock(page);
        const table = resultsTable(block);
        await expect(table).toBeVisible({ timeout: 30_000 });
        await expect(table.locator('tr')).toHaveCount(itemCount + 1);

        await editorToggle(block).click();
        // Through the editor the handler reads from, rather than the textarea it replaced: Run
        // takes the query string from the YASQE instance registered under the textarea's id.
        const textareaId = await block.locator('textarea.sparql-query-string').getAttribute('id');
        await page.evaluate(id => {
            const editor = window.LinkedDataHub.yasqe[id];
            editor.setValue(`${editor.getValue()}\nLIMIT 3`);
        }, textareaId);
        await block.locator('button.btn-run-query').click();

        await expect(table.locator('tr')).toHaveCount(3 + 1);
        await expect(table.locator('tr').nth(1)).toContainText(itemTitle(1));
    });

    // A query whose result is longer than the endpoint answers with (MAX_QUERY_RESPONSE_LENGTH, 5 MiB unless set) is
    // refused by the server, so the page never parses it: the block says why, where a 502 alone reads as an endpoint
    // that could not be reached. Before the limit, a CONSTRUCT that matched the whole dataset held the page's thread for
    // ~30 s while Saxon-JS tabled ~9 MB of it. A three-way cross join of the dataset's triples is far past the limit.
    test('a result longer than the endpoint answers with is reported, not rendered', async ({ page, allowNoise }) => {
        allowNoise.push({ pattern: /HTTP 502/, reason: 'the spec runs a query the endpoint is configured to refuse' });
        allowNoise.push({ pattern: /console\.error: Failed to load resource.*502/, reason: 'the browser logs the same refusal' });

        await goto(page, fixtures.queryDocument);
        const block = queryBlock(page);
        await expect(resultsTable(block)).toBeVisible({ timeout: 30_000 });

        await editorToggle(block).click();
        const textareaId = await block.locator('textarea.sparql-query-string').getAttribute('id');
        await page.evaluate(([id, query]) => window.LinkedDataHub.yasqe[id].setValue(query),
            [textareaId, 'SELECT * { GRAPH ?g1 { ?a ?b ?c } GRAPH ?g2 { ?d ?e ?f } GRAPH ?g3 { ?h ?i ?j } } LIMIT 100000']);
        await block.locator('button.btn-run-query').click();

        const error = block.locator('.ldh-block-error');
        await expect(error).toBeVisible({ timeout: 30_000 });
        await expect(error).toContainText('larger than this server returns');
        await expect(resultsTable(block)).toHaveCount(0);
    });

    // Open is for a query whose results are a graph: they open as a document of their own, the
    // endpoint asked the query, which is what a link to {endpoint}?query= opens too. It used to POST
    // the query and hand the response to the document renderer without the document URI the renderer
    // requires, so the click ended in a type error and the page never changed.
    test('Open shows a DESCRIBE\'s results as a document of their own', async ({ page }) => {
        await goto(page, fixtures.queryDocument);
        const block = queryBlock(page);
        await expect(resultsTable(block)).toBeVisible({ timeout: 30_000 });

        await editorToggle(block).click();
        const textareaId = await block.locator('textarea.sparql-query-string').getAttribute('id');
        await page.evaluate(([id, query]) => window.LinkedDataHub.yasqe[id].setValue(query),
            [textareaId, `DESCRIBE <${itemUri(2)}>`]);
        await block.locator('button.btn-open-query').click();

        // an address that can be reloaded: the endpoint, with the query that was opened
        await page.waitForURL(url => url.href.startsWith(`${endUserBase}sparql?`)
            && new URL(url).searchParams.get('query') === `DESCRIBE <${itemUri(2)}>`, { timeout: 30_000 });
        const body = page.locator('#tab-content .ldh-pane:visible div.document-body');
        await expect(body).toHaveAttribute('about', `${endUserBase}sparql`, { timeout: 30_000 });
        // the described document is what the pane shows, and the query block is gone with its page
        await expect(body).toContainText(itemTitle(2), { timeout: 30_000 });
        await expect(body.locator(`div.block.ldh-block[about="${fixtures.query}"]`)).toHaveCount(0);
        await expect(page.locator('.ldh-failure')).toHaveCount(0);
    });

    test('the View tab renders the same result set as rows', async ({ page, allowNoise }) => {
        test.fail(true, 'the view-mode tab applies ldh:RenderRow to a detached element, and ldh:RowHook finds no block');
        allowNoise.push({
            pattern: /pageerror: Required cardinality of value in 'xsl:param name="Q\{\}block"'/,
            reason: 'the defect this test is expected to fail on, so the failure is the assertion below and not the guard',
        });

        await goto(page, fixtures.queryDocument);
        const block = queryBlock(page);
        await expect(resultsTable(block)).toBeVisible({ timeout: 30_000 });

        await block.locator('.query-results-tabs button.view-mode').click();

        await expect(block.locator('.query-results-tabs button.view-mode')).toHaveClass(/is-on/);
        const rows = block.locator('.sparql-query-results li a.row');
        // A view pages at 20, where the table showed everything.
        await expect(rows).toHaveCount(Math.min(20, itemCount));
        await expect(rows.first().locator('.ti')).toHaveText(itemTitle(1));
        await expect(resultsTable(block)).toHaveCount(0);
    });
});
