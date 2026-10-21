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
import { fixtures, itemCount, itemTitle, itemUri, ldh } from '../../../lib/fixtures.mjs';
import { endUserBase } from '../../../lib/stack.mjs';
import { mkdtempSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

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

// Saving the query: the editor's text, and the query form it names, written as a targeted update of those alone; the
// block is then drawn again from the query as the document stores it. Each test seeds documents of its own, so a save
// cannot disturb the fixture query the tests above read.
const SP = 'http://spinrdf.org/sp#';
const DCT = 'http://purl.org/dc/terms/';
const RDF_TYPE = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type';

const itemsQuery = `PREFIX  sioc: <http://rdfs.org/sioc/ns#>
PREFIX  dct:  <http://purl.org/dc/terms/>

SELECT  ?item ?title
WHERE
  { GRAPH ?g
      { ?item  sioc:has_container  <${fixtures.container}> ;
               dct:title        ?title
      }
  }
ORDER BY ?title`;

// a document holding a SELECT query, and - unless the query is to be shown from another document - the block showing it
async function seedQuery(slug, { block = true } = {}) {
    const doc = `${endUserBase}${slug}/`;
    await ldh(['delete', doc], { allowFailure: true });
    await ldh(['create', 'item', '--container', endUserBase, '--title', `Query save ${slug}`, '--slug', slug]);
    const file = join(mkdtempSync(join(tmpdir(), 'ui-query-save-')), 'q.rq');
    writeFileSync(file, itemsQuery);
    await ldh(['add', 'select', '--title', 'Saved query', '--uri', `${doc}#query`, '--query-file', file, doc]);
    if (block) await ldh(['add', 'object-block', '--title', 'Saved query block', '--uri', `${doc}#block`, '--value', `${doc}#query`, doc]);
    return { doc, query: `${doc}#query` };
}

// the objects the document stores for a subject's property, read back over the API
async function stored(doc, subject, predicate) {
    const { stdout } = await ldh(['get', '--accept', 'application/n-triples', doc]);
    return stdout.split('\n')
        .filter(line => line.startsWith(`<${subject}> <${predicate}> `))
        .map(line => line.slice(`<${subject}> <${predicate}> `.length).replace(/\s*\.\s*$/, ''))
        .map(object => object.startsWith('<') ? object.slice(1, -1) : JSON.parse(object.replace(/\^\^<[^>]*>$|@[\w-]+$/, '')));
}

// opens the editor of the block showing $query, puts $text in it and saves; returns the PATCH's status
async function saveText(page, query, writtenTo, text) {
    const block = page.locator(`div.block.ldh-block[about="${query}"]`);
    await expect(resultsTable(block)).toBeVisible({ timeout: 30_000 });
    await editorToggle(block).click();
    const textareaId = await block.locator('textarea.sparql-query-string').getAttribute('id');
    await page.evaluate(([id, value]) => window.LinkedDataHub.yasqe[id].setValue(value), [textareaId, text]);
    const patch = page.waitForResponse(response => response.request().method() === 'PATCH'
        && new URL(response.url()).pathname === new URL(writtenTo).pathname);
    await block.locator('button.btn-save-query').click();
    return (await patch).status();
}

test.describe('saving the query', { tag: '@owner' }, () => {
    test.beforeEach(({ allowNoise }, testInfo) => {
        test.skip(testInfo.project.name !== 'owner', 'saving is offered to an agent who may write');
        allowNoise.push({
            pattern: /prefix\.cc/,
            reason: 'YASQE 2 fetches http://prefix.cc for prefix completion, which the browser blocks as '
                + 'mixed content - a platform defect in the editor initialisation, not this spec\'s doing',
        });
    });

    // Quotes, a backslash and line breaks are what a SPARQL literal escapes; $this, $type and $text are the
    // placeholders the update is built from, which the query's own text must not be mistaken for
    test('stores the text exactly as written', async ({ page }) => {
        const { doc, query } = await seedQuery('ui-query-save-text');
        const text = `# a "quoted" comment, a back\\slash, and the update's placeholders: $this $type $text
${itemsQuery}
LIMIT 3`;
        try {
            await goto(page, doc);
            expect(await saveText(page, query, doc, text)).toBeLessThan(300);

            expect(await stored(doc, query, `${SP}text`)).toEqual([text]);
        } finally {
            await ldh(['delete', doc], { allowFailure: true });
        }
    });

    test('touches nothing on the query but its text and form', async ({ page }) => {
        const { doc, query } = await seedQuery('ui-query-save-rest');
        try {
            // a property the editor does not show, which the save has no business with
            await ldh(['patch', doc], { stdin: `INSERT { <${query}> <${DCT}description> "Kept" } WHERE {}` });
            await goto(page, doc);
            expect(await saveText(page, query, doc, `${itemsQuery}\nLIMIT 3`)).toBeLessThan(300);

            expect(await stored(doc, query, RDF_TYPE)).toEqual([`${SP}Select`]);
            expect(await stored(doc, query, `${DCT}title`)).toEqual(['Saved query']);
            expect(await stored(doc, query, `${DCT}description`)).toEqual(['Kept']);
        } finally {
            await ldh(['delete', doc], { allowFailure: true });
        }
    });

    test('retypes the query when the text names another form', async ({ page }) => {
        const { doc, query } = await seedQuery('ui-query-save-form');
        try {
            await goto(page, doc);
            expect(await saveText(page, query, doc, `ASK { GRAPH ?g { ?s ?p ?o } }`)).toBeLessThan(300);

            expect(await stored(doc, query, RDF_TYPE)).toEqual([`${SP}Ask`]);
        } finally {
            await ldh(['delete', doc], { allowFailure: true });
        }
    });

    // the server validates sp:text, so a text that is not SPARQL is refused rather than stored
    test('writes nothing when the text is not SPARQL', async ({ page, allowNoise }) => {
        allowNoise.push({ pattern: /422|Unprocessable/, reason: 'the spec saves a text that is not SPARQL on purpose' });
        const { doc, query } = await seedQuery('ui-query-save-unparsed');
        try {
            await goto(page, doc);
            expect(await saveText(page, query, doc, 'SELECT * WHERE { this is not SPARQL')).toBe(422);

            expect(await stored(doc, query, RDF_TYPE)).toEqual([`${SP}Select`]);
            expect(await stored(doc, query, `${SP}text`)).toEqual([itemsQuery]);
        } finally {
            await ldh(['delete', doc], { allowFailure: true });
        }
    });

    test('draws the block again from what was stored', async ({ page }) => {
        const { doc, query } = await seedQuery('ui-query-save-redraw');
        try {
            await goto(page, doc);
            expect(await saveText(page, query, doc, `${itemsQuery}\nLIMIT 3`)).toBeLessThan(300);

            // the row is replaced: the stored query runs again, with the editor folded
            const redrawn = page.locator(`div.block.ldh-block[about="${query}"]`);
            await expect(resultsTable(redrawn).locator('tr')).toHaveCount(3 + 1, { timeout: 30_000 });
            await expect(redrawn.locator('.ldh-sparql')).toBeHidden();
            await expect(redrawn.locator('.ldh-block-head')).toContainText('Saved query');
        } finally {
            await ldh(['delete', doc], { allowFailure: true });
        }
    });

    test('saves a query shown from another document into the document that holds it', async ({ page }) => {
        const { doc: holder, query } = await seedQuery('ui-query-save-holder', { block: false });
        const host = `${endUserBase}ui-query-save-host/`;
        try {
            await ldh(['delete', host], { allowFailure: true });
            await ldh(['create', 'item', '--container', endUserBase, '--title', 'Query save host', '--slug', 'ui-query-save-host']);
            await ldh(['add', 'object-block', '--title', 'Embedded query', '--uri', `${host}#block`, '--value', query, host]);

            await goto(page, host);
            expect(await saveText(page, query, holder, `${itemsQuery}\nLIMIT 3`)).toBeLessThan(300);

            expect(await stored(holder, query, `${SP}text`)).toEqual([`${itemsQuery}\nLIMIT 3`]);
        } finally {
            await ldh(['delete', host], { allowFailure: true });
            await ldh(['delete', holder], { allowFailure: true });
        }
    });

    test('refuses to save over a document that changed after the page loaded it', async ({ page, allowNoise }) => {
        allowNoise.push({ pattern: /412|Precondition Failed/, reason: 'the spec changes the document behind the page on purpose' });
        const { doc, query } = await seedQuery('ui-query-save-stale');
        try {
            await goto(page, doc);
            await expect(resultsTable(page.locator(`div.block.ldh-block[about="${query}"]`))).toBeVisible({ timeout: 30_000 });
            await ldh(['patch', doc], { stdin: `DELETE { <${query}> <${DCT}title> ?t } INSERT { <${query}> <${DCT}title> "Renamed elsewhere" } WHERE { <${query}> <${DCT}title> ?t }` });

            expect(await saveText(page, query, doc, `${itemsQuery}\nLIMIT 3`)).toBe(412);

            expect(await stored(doc, query, `${SP}text`), 'nothing was written').toEqual([itemsQuery]);
            expect(await stored(doc, query, `${DCT}title`)).toEqual(['Renamed elsewhere']);
        } finally {
            await ldh(['delete', doc], { allowFailure: true });
        }
    });
});
