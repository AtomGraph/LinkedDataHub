// Blocks over a query that names a SPARQL service of its own.
//
// A query runs against the dataspace's endpoint unless it names an sd:Service with ldh:service, and a
// view or a chart runs the query it references - so a view or a chart over such a query shows another
// endpoint's data on the page. The fixture (lib/fixtures.mjs, `serviceDocument`) holds one of each
// block over queries that name a service whose endpoint nothing serves; lib/service.mjs answers it in
// the browser, with values that are nowhere in the dataspace.
//
// So each test asserts three things: the block shows the mock's values, the mock was sent the block's
// query, and the dataspace's own endpoint was not. The last is what tells "ran against the named
// service" from "ran locally and happened to render": a query sent to /sparql instead would come back
// empty, but a block that falls back to the local endpoint on a missing service would fail the same
// way as one that never looked - this pins which endpoint it asked.
import { test, expect } from '../../../lib/console.mjs';
import { goto } from '../../../lib/settle.mjs';
import { fixtures } from '../../../lib/fixtures.mjs';
import { endUserBase } from '../../../lib/stack.mjs';
import { mockService, things, kindCounts } from '../../../lib/service.mjs';
import { listTitles, resultCount, counting } from '../../../lib/view.mjs';
import { chartBlock, canvas } from '../../../lib/chart.mjs';

const block = (page, about) => page.locator(`div.block.ldh-block[about="${about}"]`);

// The queries the page sent to the dataspace's own endpoint, GET and POST alike.
function localQueries(page) {
    const queries = [];
    page.on('request', request => {
        const url = new URL(request.url());
        if (url.href.split('?')[0] !== `${endUserBase}sparql`) return;
        queries.push(url.searchParams.get('query') ?? request.postData() ?? '');
    });
    return queries;
}

// The fixture queries project ?thing; nothing the platform queries locally does.
const isServiceQuery = query => /\?thing\b/.test(query);

test.describe('blocks over a query that names a service', { tag: '@owner' }, () => {
    test.beforeEach(({ allowNoise }) => {
        // The page carries a query block, and the query block's editor brings the noise with it.
        allowNoise.push({
            pattern: /prefix\.cc/,
            reason: 'YASQE 2 fetches http://prefix.cc for prefix completion, which the browser blocks as '
                + 'mixed content - a platform defect in the editor initialisation, not this spec\'s doing',
        });
    });

    test('the query block runs its query against the service and tables the result', async ({ page }) => {
        const remote = await mockService(page);
        const local = localQueries(page);
        await goto(page, fixtures.serviceDocument);

        const table = block(page, fixtures.serviceQuery).locator('.sparql-query-results .google-visualization-table');
        await expect(table).toBeVisible({ timeout: 30_000 });
        await expect(table.locator('tr')).toHaveCount(things.length + 1);
        for (const thing of things) await expect(table).toContainText(thing.title);

        expect(remote.some(query => /SELECT\s+\?thing\s+\?title\s+\?kind/.test(query))).toBe(true);
        expect(local.filter(isServiceQuery)).toEqual([]);
    });

    test('a view over the query lists the service\'s resources', async ({ page }) => {
        const remote = await mockService(page);
        const local = localQueries(page);
        await goto(page, fixtures.serviceDocument);

        const view = block(page, fixtures.serviceView);
        await expect(listTitles(view)).toHaveText(things.map(t => t.title).toSorted(), { timeout: 30_000 });
        await expect(resultCount(view)).toHaveText(counting(things.length));

        // The view wraps the query in a DESCRIBE of its first variable.
        expect(remote.some(query => /^DESCRIBE/.test(query) && /\?thing/.test(query))).toBe(true);
        expect(local.filter(isServiceQuery)).toEqual([]);
    });

    test('a chart over the query plots the service\'s results', async ({ page }) => {
        const remote = await mockService(page);
        const local = localQueries(page);
        await goto(page, fixtures.serviceDocument);

        const table = canvas(chartBlock(page, fixtures.serviceChart)).locator('.google-visualization-table');
        await expect(table).toBeVisible({ timeout: 30_000 });
        // A header row, then one row per kind with its count.
        await expect(table.locator('tr')).toHaveCount(kindCounts.length + 1);
        for (const [i, { kind, count }] of kindCounts.entries()) {
            await expect(table.locator('tr').nth(i + 1).locator('td')).toHaveText([kind, String(count)]);
        }

        expect(remote.some(query => /GROUP\s+BY\s+\?kind/.test(query))).toBe(true);
        expect(local.filter(isServiceQuery)).toEqual([]);
    });
});
