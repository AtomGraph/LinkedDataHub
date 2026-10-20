// Saving the chart controls.
//
// The save writes what the controls own - the chart type, the category, the series - as a targeted update of those
// properties alone, and draws the block again from the chart as the document then stores it. It used to rewrite the
// whole chart from a copy of the document the page had loaded, which is why it needed one; these tests are the
// contract the targeted update keeps instead: the controls' values stored, nothing else on the chart touched, either
// chart class, more than one series, the block redrawn, a second save on the same page, and a save over a document
// that changed since the page loaded it refused.
//
// Each test seeds a document of its own, so a save cannot disturb the shared fixtures other specs read.
import { test, expect } from '../../../../lib/console.mjs';
import { goto, loaded } from '../../../../lib/settle.mjs';
import { fixtures, ldh } from '../../../../lib/fixtures.mjs';
import { endUserBase } from '../../../../lib/stack.mjs';
import { controlToggle } from '../../../../lib/block.mjs';
import { canvas, chartBlock, chartType } from '../../../../lib/chart.mjs';
import { mkdtempSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const AC = 'https://w3id.org/atomgraph/client#';
const LDH = 'https://w3id.org/atomgraph/linkeddatahub#';
const DCT = 'http://purl.org/dc/terms/';
const SPIN = 'http://spinrdf.org/spin#';
const RDF_TYPE = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type';

// Two numeric columns per kind, so a series can be added to the saved one
const countsQuery = `PREFIX  sioc: <http://rdfs.org/sioc/ns#>
PREFIX  dct:  <http://purl.org/dc/terms/>

SELECT  ?kind (COUNT(?item) AS ?items) (MAX(STRLEN(?title)) AS ?longest)
WHERE
  { GRAPH ?g
      { ?item  sioc:has_container  <${fixtures.container}> ;
               dct:title        ?title ;
               dct:description  ?kind
      }
  }
GROUP BY ?kind
ORDER BY ?kind`;

// The items with their title and kind, for a chart of a graph
const itemsConstruct = `PREFIX  sioc: <http://rdfs.org/sioc/ns#>
PREFIX  dct:  <http://purl.org/dc/terms/>

CONSTRUCT { ?item dct:title ?title ; dct:description ?kind }
WHERE
  { GRAPH ?g
      { ?item  sioc:has_container  <${fixtures.container}> ;
               dct:title        ?title ;
               dct:description  ?kind
      }
  }`;

const queryFile = text => {
    const file = join(mkdtempSync(join(tmpdir(), 'ui-chart-save-')), 'q.rq');
    writeFileSync(file, text);
    return file;
};

// A document holding one chart, wrapped in an object block so that it renders. The slug is the test's own.
async function seedResultSetChart(slug, { series = ['items'], type = `${AC}Table` } = {}) {
    const doc = `${endUserBase}${slug}/`;
    await ldh(['delete', doc], { allowFailure: true });
    await ldh(['create', 'item', '--container', endUserBase, '--title', `Chart save ${slug}`, '--slug', slug]);
    await ldh(['add', 'select', '--title', 'Counts', '--uri', `${doc}#query`, '--query-file', queryFile(countsQuery), doc]);
    await ldh(['add', 'result-set-chart', '--title', 'Saved chart', '--uri', `${doc}#chart`, '--query', `${doc}#query`,
        '--chart-type', type, '--category-var-name', 'kind', ...series.flatMap(name => ['--series-var-name', name]), doc]);
    await ldh(['add', 'object-block', '--title', 'Saved chart block', '--uri', `${doc}#block`, '--value', `${doc}#chart`, doc]);
    return { doc, chart: `${doc}#chart` };
}

// No CLI command writes a graph chart, so it is written as data, the way any client could
async function seedGraphChart(slug) {
    const doc = `${endUserBase}${slug}/`;
    await ldh(['delete', doc], { allowFailure: true });
    await ldh(['create', 'item', '--container', endUserBase, '--title', `Chart save ${slug}`, '--slug', slug]);
    await ldh(['add', 'construct', '--title', 'Items', '--uri', `${doc}#query`, '--query-file', queryFile(itemsConstruct), doc]);
    await ldh(['patch', doc], { stdin: `INSERT { <${doc}#chart> a <${LDH}GraphChart> ;
        <${DCT}title> "Saved graph chart" ;
        <${SPIN}query> <${doc}#query> ;
        <${LDH}chartType> <${AC}Table> ;
        <${LDH}categoryProperty> <${DCT}title> ;
        <${LDH}seriesProperty> <${DCT}description> } WHERE {}` });
    await ldh(['add', 'object-block', '--title', 'Saved graph chart block', '--uri', `${doc}#block`, '--value', `${doc}#chart`, doc]);
    return { doc, chart: `${doc}#chart` };
}

// the objects the document stores for a subject's property, read back over the API
async function stored(doc, subject, predicate) {
    const { stdout } = await ldh(['get', '--accept', 'application/n-triples', doc]);
    return stdout.split('\n')
        .filter(line => line.startsWith(`<${subject}> <${predicate}> `))
        .map(line => line.slice(`<${subject}> <${predicate}> `.length).replace(/\s*\.\s*$/, ''))
        .map(object => object.startsWith('<') ? object.slice(1, -1) : JSON.parse(object.replace(/\^\^<[^>]*>$|@[\w-]+$/, '')));
}

// the controls unfolded: a chart arrives with them folded, and a save draws it again with them as they were
async function shown(block) {
    if (await controlToggle(block).getAttribute('aria-pressed') !== 'true') await controlToggle(block).click();
    await expect(block.locator('.chart-controls')).toBeVisible();
}

async function opened(page, doc, chart) {
    await goto(page, doc);
    const block = chartBlock(page, chart);
    await expect(canvas(block).locator('svg, table').first()).toBeVisible({ timeout: 30_000 });
    await shown(block);
    return block;
}

// saves the controls as they are and returns the PATCH's status. A saved chart is drawn again in a row of its own, so
// the save is over once the row it was made from has left the page and the new one has drawn - not when the PATCH
// returns, which is before the document is requested again to draw it from
async function save(page, block, doc) {
    const row = await block.elementHandle();
    const patch = page.waitForResponse(response => response.request().method() === 'PATCH'
        && new URL(response.url()).pathname === new URL(doc).pathname);
    await block.locator('button.btn-save-chart').click();
    const status = (await patch).status();
    if (status < 300) {
        await expect.poll(() => row.evaluate(element => element.isConnected), { message: 'the saved chart was drawn again', timeout: 30_000 }).toBe(false);
        await loaded(page);
    }
    return status;
}

test.describe('saving the chart controls', { tag: '@owner' }, () => {
    test.beforeEach(({}, testInfo) => {
        test.skip(testInfo.project.name !== 'owner', 'saving is offered to an agent who may write');
    });

    test('stores the chart type, category and series the controls hold', async ({ page }) => {
        const { doc, chart } = await seedResultSetChart('ui-chart-save-values');
        try {
            const block = await opened(page, doc, chart);
            await chartType(block).selectOption(`${AC}BarChart`);
            expect(await save(page, block, doc)).toBeLessThan(300);

            expect(await stored(doc, chart, `${LDH}chartType`), 'one chart type, the saved one').toEqual([`${AC}BarChart`]);
            expect(await stored(doc, chart, `${LDH}categoryVarName`)).toEqual(['kind']);
            expect(await stored(doc, chart, `${LDH}seriesVarName`)).toEqual(['items']);
        } finally {
            await ldh(['delete', doc], { allowFailure: true });
        }
    });

    test('touches nothing on the chart but what the controls own', async ({ page }) => {
        const { doc, chart } = await seedResultSetChart('ui-chart-save-rest');
        try {
            const block = await opened(page, doc, chart);
            await chartType(block).selectOption(`${AC}BarChart`);
            expect(await save(page, block, doc)).toBeLessThan(300);

            expect(await stored(doc, chart, RDF_TYPE)).toEqual([`${LDH}ResultSetChart`]);
            expect(await stored(doc, chart, `${DCT}title`)).toEqual(['Saved chart']);
            expect(await stored(doc, chart, `${SPIN}query`)).toEqual([`${doc}#query`]);
        } finally {
            await ldh(['delete', doc], { allowFailure: true });
        }
    });

    test('stores every series the controls select', async ({ page }) => {
        const { doc, chart } = await seedResultSetChart('ui-chart-save-series', { series: ['items', 'longest'] });
        try {
            const block = await opened(page, doc, chart);
            await expect(block.locator('select.chart-series option:checked')).toHaveCount(2);
            expect(await save(page, block, doc)).toBeLessThan(300);

            expect((await stored(doc, chart, `${LDH}seriesVarName`)).toSorted()).toEqual(['items', 'longest']);
        } finally {
            await ldh(['delete', doc], { allowFailure: true });
        }
    });

    test('stores a chart of a graph by its properties', async ({ page }) => {
        const { doc, chart } = await seedGraphChart('ui-chart-save-graph');
        try {
            const block = await opened(page, doc, chart);
            await chartType(block).selectOption(`${AC}BarChart`);
            expect(await save(page, block, doc)).toBeLessThan(300);

            expect(await stored(doc, chart, `${LDH}chartType`)).toEqual([`${AC}BarChart`]);
            expect(await stored(doc, chart, `${LDH}categoryProperty`)).toEqual([`${DCT}title`]);
            expect(await stored(doc, chart, `${LDH}seriesProperty`)).toEqual([`${DCT}description`]);
            expect(await stored(doc, chart, `${LDH}categoryVarName`), 'no result-set property on a graph chart').toEqual([]);
            expect(await stored(doc, chart, RDF_TYPE)).toEqual([`${LDH}GraphChart`]);
        } finally {
            await ldh(['delete', doc], { allowFailure: true });
        }
    });

    test('draws the block again from what was stored', async ({ page }) => {
        const { doc, chart } = await seedResultSetChart('ui-chart-save-redraw');
        try {
            const block = await opened(page, doc, chart);
            await expect(canvas(block).locator('.google-visualization-table')).toBeVisible();
            await chartType(block).selectOption(`${AC}BarChart`);
            expect(await save(page, block, doc)).toBeLessThan(300);

            // the row is replaced: the redrawn chart is a bar chart, under its stored title, its controls on the stored type
            const redrawn = chartBlock(page, chart);
            await expect(canvas(redrawn).locator('svg')).toBeVisible({ timeout: 30_000 });
            await expect(canvas(redrawn).locator('.google-visualization-table')).toHaveCount(0);
            await expect(redrawn.locator('.ldh-block-head')).toContainText('Saved chart');
            await shown(redrawn);
            await expect(chartType(redrawn), 'the controls come up on the stored type').toHaveValue(`${AC}BarChart`);
        } finally {
            await ldh(['delete', doc], { allowFailure: true });
        }
    });

    test('saves a second time on the same page', async ({ page }) => {
        const { doc, chart } = await seedResultSetChart('ui-chart-save-twice');
        try {
            const block = await opened(page, doc, chart);
            await chartType(block).selectOption(`${AC}BarChart`);
            expect(await save(page, block, doc), 'the first save').toBeLessThan(300);

            // the redrawn block, whose save has to quote the tag the first save left behind
            const redrawn = chartBlock(page, chart);
            await shown(redrawn);
            await chartType(redrawn).selectOption(`${AC}LineChart`);
            expect(await save(page, redrawn, doc), 'the second save').toBeLessThan(300);

            expect(await stored(doc, chart, `${LDH}chartType`)).toEqual([`${AC}LineChart`]);
        } finally {
            await ldh(['delete', doc], { allowFailure: true });
        }
    });

    test('refuses to save over a document that changed after the page loaded it', async ({ page, allowNoise }) => {
        allowNoise.push({ pattern: /412|Precondition Failed/, reason: 'the spec changes the document behind the page on purpose' });
        const { doc, chart } = await seedResultSetChart('ui-chart-save-stale');
        try {
            const block = await opened(page, doc, chart);
            // another writer, after the page loaded the document and its tag
            await ldh(['patch', doc], { stdin: `DELETE { <${chart}> <${DCT}title> ?t } INSERT { <${chart}> <${DCT}title> "Renamed elsewhere" } WHERE { <${chart}> <${DCT}title> ?t }` });

            await chartType(block).selectOption(`${AC}BarChart`);
            expect(await save(page, block, doc)).toBe(412);

            expect(await stored(doc, chart, `${LDH}chartType`), 'nothing was written').toEqual([`${AC}Table`]);
            expect(await stored(doc, chart, `${DCT}title`)).toEqual(['Renamed elsewhere']);
        } finally {
            await ldh(['delete', doc], { allowFailure: true });
        }
    });
});
