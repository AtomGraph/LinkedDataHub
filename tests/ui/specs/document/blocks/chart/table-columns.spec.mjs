// A chart drawn as a Table shows every column of its results, not only its category and series.
//
// The category and series pick what a chart plots: the axis it draws against and the values it draws. A table plots
// nothing, so it has no use for them, but the data table it was drawn from was cut down to them all the same. A
// ResultSetChart whose query selected five variables, saved with a category and one series, showed two columns, and
// nothing on the page said the other three existed. A chart of a graph lost every property but its category and
// series the same way.
//
// Each test seeds a document of its own: the shared fixtures chart one series, where a table and a chart of it would
// show the same columns and this could not fail.
import { test, expect } from '../../../../lib/console.mjs';
import { goto } from '../../../../lib/settle.mjs';
import { fixtures, ldh } from '../../../../lib/fixtures.mjs';
import { endUserBase } from '../../../../lib/stack.mjs';
import { canvas, chartBlock } from '../../../../lib/chart.mjs';
import { mkdtempSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const AC = 'https://w3id.org/atomgraph/client#';
const LDH = 'https://w3id.org/atomgraph/linkeddatahub#';
const DCT = 'http://purl.org/dc/terms/';
const SPIN = 'http://spinrdf.org/spin#';

// Three variables, of which the chart plots two
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

// Three properties per item, of which the chart plots two
const itemsConstruct = `PREFIX  sioc: <http://rdfs.org/sioc/ns#>
PREFIX  dct:  <http://purl.org/dc/terms/>

CONSTRUCT { ?item dct:title ?title ; dct:description ?kind ; sioc:has_container ?container }
WHERE
  { GRAPH ?g
      { ?item  sioc:has_container  ?container ;
               dct:title        ?title ;
               dct:description  ?kind
        FILTER ( ?container = <${fixtures.container}> )
      }
  }`;

const queryFile = text => {
    const file = join(mkdtempSync(join(tmpdir(), 'ui-chart-table-')), 'q.rq');
    writeFileSync(file, text);
    return file;
};

async function seedResultSetChart(slug) {
    const doc = `${endUserBase}${slug}/`;
    await ldh(['delete', doc], { allowFailure: true });
    await ldh(['create', 'item', '--container', endUserBase, '--title', `Table columns ${slug}`, '--slug', slug]);
    await ldh(['add', 'select', '--title', 'Counts', '--uri', `${doc}#query`, '--query-file', queryFile(countsQuery), doc]);
    await ldh(['add', 'result-set-chart', '--title', 'Counts table', '--uri', `${doc}#chart`, '--query', `${doc}#query`,
        '--chart-type', `${AC}Table`, '--category-var-name', 'kind', '--series-var-name', 'items', doc]);
    await ldh(['add', 'object-block', '--title', 'Counts table block', '--uri', `${doc}#block`, '--value', `${doc}#chart`, doc]);
    return { doc, chart: `${doc}#chart` };
}

// No CLI command writes a graph chart, so it is written as data, the way any client could
async function seedGraphChart(slug) {
    const doc = `${endUserBase}${slug}/`;
    await ldh(['delete', doc], { allowFailure: true });
    await ldh(['create', 'item', '--container', endUserBase, '--title', `Table columns ${slug}`, '--slug', slug]);
    await ldh(['add', 'construct', '--title', 'Items', '--uri', `${doc}#query`, '--query-file', queryFile(itemsConstruct), doc]);
    await ldh(['patch', doc], { stdin: `INSERT { <${doc}#chart> a <${LDH}GraphChart> ;
        <${DCT}title> "Items table" ;
        <${SPIN}query> <${doc}#query> ;
        <${LDH}chartType> <${AC}Table> ;
        <${LDH}categoryProperty> <${DCT}title> ;
        <${LDH}seriesProperty> <${DCT}description> } WHERE {}` });
    await ldh(['add', 'object-block', '--title', 'Items table block', '--uri', `${doc}#block`, '--value', `${doc}#chart`, doc]);
    return { doc, chart: `${doc}#chart` };
}

const header = (page, chart) => canvas(chartBlock(page, chart)).locator('.google-visualization-table tr').first().locator('th');

// the documents are the owner's, unpublished, so only the owner can read them
test.describe('a chart drawn as a table', { tag: '@owner' }, () => {
    test('a table of a result set shows every variable the query selects, in the order it selects them', async ({ page }) => {
        const { doc, chart } = await seedResultSetChart('ui-chart-table-results');
        try {
            await goto(page, doc);
            await expect(header(page, chart)).toHaveText(['kind', 'items', 'longest'], { timeout: 30_000 });
        } finally {
            await ldh(['delete', doc], { allowFailure: true });
        }
    });

    test('a table of a graph shows every property its resources carry', async ({ page }) => {
        const { doc, chart } = await seedGraphChart('ui-chart-table-graph');
        try {
            await goto(page, doc);
            // one column per property: the title and description the chart names, and the container it does not
            await expect(header(page, chart)).toHaveCount(3, { timeout: 30_000 });
        } finally {
            await ldh(['delete', doc], { allowFailure: true });
        }
    });
});
