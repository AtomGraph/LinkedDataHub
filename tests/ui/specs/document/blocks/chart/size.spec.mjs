// A chart is as tall as what it draws.
//
// Every chart was drawn 400px tall, by the canvas's CSS and again by the height ldh:RenderChart handed Google Charts,
// whatever the chart type. A Table of three rows stretched them to fill 400px and cut a long one off. A bar chart
// draws its categories down the side, and once they no longer fit in 400px Google Charts skips every other label, so
// a bar chart of 25 items named 13 of them.
//
// Each test seeds a document of its own: the shared fixtures chart three kinds, which fit either way.
import { test, expect } from '../../../../lib/console.mjs';
import { goto } from '../../../../lib/settle.mjs';
import { fixtures, ldh, itemNumbers, itemTitle } from '../../../../lib/fixtures.mjs';
import { endUserBase } from '../../../../lib/stack.mjs';
import { canvas, chartBlock, drawing } from '../../../../lib/chart.mjs';
import { mkdtempSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const AC = 'https://w3id.org/atomgraph/client#';

// One row per kind: three
const kindsQuery = `PREFIX  sioc: <http://rdfs.org/sioc/ns#>
PREFIX  dct:  <http://purl.org/dc/terms/>

SELECT  ?kind (COUNT(?item) AS ?items)
WHERE
  { GRAPH ?g
      { ?item  sioc:has_container  <${fixtures.container}> ;
               dct:description  ?kind
      }
  }
GROUP BY ?kind
ORDER BY ?kind`;

// One row per item, named by its number alone, so that no label is long enough to be cut short
const itemsQuery = `PREFIX  sioc: <http://rdfs.org/sioc/ns#>
PREFIX  dct:  <http://purl.org/dc/terms/>

SELECT  ?number (STRLEN(?title) AS ?chars)
WHERE
  { GRAPH ?g
      { ?item  sioc:has_container  <${fixtures.container}> ;
               dct:title  ?title
      }
    BIND (STRAFTER(?title, "item ") AS ?number)
  }
ORDER BY ?number`;

const queryFile = text => {
    const file = join(mkdtempSync(join(tmpdir(), 'ui-chart-size-')), 'q.rq');
    writeFileSync(file, text);
    return file;
};

async function seedChart(slug, query, type, category, series) {
    const doc = `${endUserBase}${slug}/`;
    await ldh(['delete', doc], { allowFailure: true });
    await ldh(['create', 'item', '--container', endUserBase, '--title', `Chart size ${slug}`, '--slug', slug]);
    await ldh(['add', 'select', '--title', 'Query', '--uri', `${doc}#query`, '--query-file', queryFile(query), doc]);
    await ldh(['add', 'result-set-chart', '--title', 'Chart', '--uri', `${doc}#chart`, '--query', `${doc}#query`,
        '--chart-type', type, '--category-var-name', category, '--series-var-name', series, doc]);
    await ldh(['add', 'object-block', '--title', 'Chart block', '--uri', `${doc}#block`, '--value', `${doc}#chart`, doc]);
    return { doc, chart: `${doc}#chart` };
}

// the documents are the owner's, unpublished, so only the owner can read them
test.describe('the size of a chart', { tag: '@owner' }, () => {
    test('a table is as tall as its rows', async ({ page }) => {
        const { doc, chart } = await seedChart('ui-chart-size-table', kindsQuery, `${AC}Table`, 'kind', 'items');
        try {
            await goto(page, doc);
            const table = canvas(chartBlock(page, chart)).locator('.google-visualization-table-table');
            await expect(table.locator('tr')).toHaveCount(4, { timeout: 30_000 });

            // a header and three rows, drawn at the height of a header and three rows - not stretched to 400px
            const rows = await table.locator('tr').evaluateAll(trs => trs.map(tr => tr.getBoundingClientRect().height));
            expect(Math.max(...rows), 'a row was stretched').toBeLessThan(80);
            expect((await canvas(chartBlock(page, chart)).boundingBox()).height).toBeLessThan(400);
        } finally {
            await ldh(['delete', doc], { allowFailure: true });
        }
    });

    test('a bar chart names every bar', async ({ page }) => {
        const { doc, chart } = await seedChart('ui-chart-size-bars', itemsQuery, `${AC}BarChart`, 'number', 'chars');
        try {
            await goto(page, doc);
            const block = chartBlock(page, chart);
            await expect(drawing(block)).toBeVisible({ timeout: 30_000 });

            const numbers = itemNumbers().map(n => itemTitle(n).split(' ').pop());
            const labels = await canvas(block).locator('svg text').allTextContents();
            expect(numbers.filter(number => !labels.includes(number)), 'bars without a label').toEqual([]);
        } finally {
            await ldh(['delete', doc], { allowFailure: true });
        }
    });
});
