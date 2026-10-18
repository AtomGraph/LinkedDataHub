// A request the rate limiter refuses is retried as itself, on every block kind.
//
// A page of content blocks fires more requests at once than nginx's `linked_data` zone lets through
// (15 r/s, burst 30), so on a busy page some come back 429 and the client retries them after
// Retry-After - in ldh:retry-request, which every block's request chain goes through. It re-sent
// `$context('request')` whatever step it was retrying, and that is only the FIRST request of a
// chain: a view's metadata, an object's metadata, a chart's results were each retried as the GET
// of their block's document. The chart showed it, because it draws what it gets - handed the
// document's RDF/XML as its "results" it drew "Table has no columns." - and on the Northwind demo
// that was a different chart on every reload. The other steps swallowed it quieter.
//
// An axis, not a chart spec: the claim is the retry's, and the chart is only where it was seen. So
// the page is the fixture container with a block of every kind on it, and EVERY request its blocks
// make is refused once, the limiter at its worst. The limiter cannot be triggered on demand, so a
// route stands in for it.
//
// Three assertions, because each defect has a different shape. A refused request that never goes
// out again is a retry that went elsewhere. But blocks repeat each other's requests, so "it went
// out again" can be satisfied by another block making the same one - hence the baseline: a load
// with nothing refused, and nothing may be fetched more often under refusal than it is there,
// because the misdirected retries are exactly those extra fetches. And last, what the reader sees:
// every block rendered.
import { test, expect } from '../../lib/console.mjs';
import { goto } from '../../lib/settle.mjs';
import { fixtures, itemCount, itemTitle } from '../../lib/fixtures.mjs';
import { chartBlock, drawing } from '../../lib/chart.mjs';
import { fixtureView, rows, switchMode } from '../../lib/view.mjs';
import { controlToggle } from '../../lib/block.mjs';
import { createHash } from 'node:crypto';

// DEBUG: a short id per exact request, so the timeline shows whether two sends are one request twice
const idOf = key => createHash('sha1').update(key).digest('hex').slice(0, 8);

// The requests the blocks make: XHR to this stack. Not the SEF - refusing that refuses the whole
// client, and there is nothing left to retry anything - nor a third party's.
const fromBlocks = (request, origin) => ['xhr', 'fetch'].includes(request.resourceType())
    && new URL(request.url()).origin === origin
    && !request.url().endsWith('.sef.json');

// A request by what it asks for, so a retry is recognised as the request it retries.
const keyOf = request => `${request.method()} ${request.url()}\n${request.postData() ?? ''}`;
// And by its shape, for comparing two loads: a view names its SPARQL variables with a UUID minted
// per render, so the same query differs between loads by those alone - never within a retry.
const shapeOf = key => key.replace(/[0-9a-f]{8}_[0-9a-f]{4}_[0-9a-f]{4}_[0-9a-f]{4}_[0-9a-f]{12}/g, 'UUID');

// Routing also switches the HTTP cache off, which is what makes two loads of one page comparable.
async function record(page, { refuse }) {
    const origin = new URL(fixtures.container).origin;
    const sent = new Set();
    const shapes = new Map();
    const refused = new Set();
    const events = []; // every block request in order: what quiet() waits on, and the timeline a failure prints
    const t0 = Date.now();
    await page.route('**/*', route => {
        const request = route.request();
        if (!fromBlocks(request, origin)) return route.fallback();

        const key = keyOf(request);
        if (refuse && !refused.has(key)) {
            refused.add(key);
            events.push({ t: Date.now() - t0, action: 'refused', id: idOf(key), shape: shapeOf(key) });
            // No Retry-After, as nginx sends none: the client falls back to its default wait.
            return route.fulfill({ status: 429, contentType: 'text/html', body: '<html><body>429 Too Many Requests</body></html>' });
        }
        events.push({ t: Date.now() - t0, action: refused.has(key) ? 'sent (after refusal)' : 'sent', id: idOf(key), shape: shapeOf(key) });
        sent.add(key);
        shapes.set(shapeOf(key), (shapes.get(shapeOf(key)) ?? 0) + 1);
        return route.fallback();
    });
    return { sent, shapes, refused, events };
}

// Every block on the fixture page, drawn: the chart has a picture, the view its first item, the
// object block the resource it names.
async function rendered(page) {
    await expect(drawing(chartBlock(page)), 'the chart draws').toBeVisible({ timeout: 30_000 });
    await expect(fixtureView(page), 'the view lists the items').toContainText(itemTitle(1), { timeout: 30_000 });
    await expect(page.locator(`div.block.ldh-block[about="${fixtures.object}"] .ldh-obj-value`).first(),
        'the object block renders its resource').not.toBeEmpty({ timeout: 30_000 });
}

// A load is over when its blocks have made no request for a while, and both loads end the same way so their
// counts compare. networkidle alone ends one too soon: it resolves once, at the first 500 ms with nothing in
// flight, and the page's two views each send a parallax label lookup after their results - the second one
// measured going out 38 ms after networkidle on a CPU throttled 4x (2026-10-14). A baseline cut there is one
// request short, and the refused load, which waits far longer, "over-fetches" a request every load sends twice.
async function quiet(page, events, { idle = 2_000, timeout = 30_000 } = {}) {
    await page.waitForLoadState('networkidle');
    const deadline = Date.now() + timeout;
    let count = -1;
    while (count !== events.length && Date.now() < deadline) {
        count = events.length;
        await page.waitForTimeout(idle);
    }
}

test('every request refused with 429 is retried as itself, and every block still renders', async ({ page, allowNoise }) => {
    test.setTimeout(120_000);
    allowNoise.push({ pattern: /^HTTP 429: /, reason: 'this spec refuses every block request once on purpose' });
    allowNoise.push({
        pattern: /console\.error: Failed to load resource.*429/i,
        reason: 'the browser logs each injected 429 the route fulfils',
    });

    const unrefused = await page.context().newPage();
    const baseline = await record(unrefused, { refuse: false });
    await goto(unrefused, fixtures.container);
    await rendered(unrefused);
    // Every request the page makes unprovoked, not just the ones the blocks render from.
    await quiet(unrefused, baseline.events);
    await unrefused.close();

    const { sent, shapes, refused, events } = await record(page, { refuse: true });
    await goto(page, fixtures.container);
    await rendered(page);

    expect(refused.size, 'the page made block requests to refuse').toBeGreaterThan(0);
    // Polled: a block renders from its first response, and the view's count and facet requests are
    // still waiting out their Retry-After when its items are already on the page.
    await expect.poll(() => [...refused].filter(key => !sent.has(key)), {
        message: 'every refused request is sent again',
        timeout: 20_000,
    }).toEqual([]);
    await quiet(page, events);
    const extra = [...shapes].filter(([shape, count]) => count > (baseline.shapes.get(shape) ?? 0))
        .map(([shape, count]) => `${count}x (baseline ${baseline.shapes.get(shape) ?? 0}x) ${shape}`);
    // DEBUG: the timeline of each over-fetched shape, under both loads, and every request around it
    for (const [shape, count] of shapes) {
        if (count <= (baseline.shapes.get(shape) ?? 0)) continue;
        console.log(`DEBUG: over-fetched ${count}x (baseline ${baseline.shapes.get(shape) ?? 0}x):\n${shape}`);
        for (const [load, log] of [['baseline', baseline.events], ['refused', events]])
            console.log(`DEBUG: ${load} timeline of that shape:\n` + log.filter(e => e.shape === shape)
                .map(e => `  ${String(e.t).padStart(6)}ms ${e.action.padEnd(20)} ${e.id}`).join('\n'));
    }
    console.log('DEBUG: refused load, every block request:\n' + events
        .map(e => `  ${String(e.t).padStart(6)}ms ${e.action.padEnd(20)} ${e.id} ${e.shape.split('\n')[0]}`).join('\n'));
    expect(extra, 'nothing is fetched more often than an unrefused load fetches it').toEqual([]);
});

// A table names its columns by the /ns labels of the result properties. The view-results chain fetches them,
// but did not hand them to the table, so the table's own default looked them up again - a synchronous document()
// GET, which ldh:handle-response never sees: one 429 on it and the table was gone, with nothing retried. Refusing
// every request of the switch to table mode once leaves such a fetch as the one refused request never sent again.
test('a table view renders through refusals, all its requests retried', async ({ page, allowNoise }) => {
    test.setTimeout(120_000);
    allowNoise.push({ pattern: /^HTTP 429: /, reason: 'this spec refuses every block request once on purpose' });
    allowNoise.push({
        pattern: /console\.error: Failed to load resource.*429/i,
        reason: 'the browser logs each injected 429 the route fulfils',
    });

    await goto(page, fixtures.container);
    const block = fixtureView(page);
    await expect(block, 'the view lists the items').toContainText(itemTitle(1), { timeout: 30_000 });

    const { sent, refused } = await record(page, { refuse: true });
    await controlToggle(block).click();
    await switchMode(block, 'table');

    await expect(rows(block).first(), 'the table renders its rows').toBeVisible({ timeout: 30_000 });
    await expect(block.locator('table thead th').first(), 'and its column headers').toBeVisible();
    expect(refused.size, 'the switch made requests to refuse').toBeGreaterThan(0);
    await expect.poll(() => [...refused].filter(key => !sent.has(key)), {
        message: 'every refused request is sent again',
        timeout: 30_000,
    }).toEqual([]);
});

// The retry is bounded: a limiter that keeps refusing must end in the view's error, not in a request re-sent every
// second for as long as the page is open. Eight retries after the first refusal, then the 429 goes to the chain's
// own error handling. The waits back off (mean 1, 2, 4 s, then 8 s), so the whole run takes about 47 s, 71 s at most.
test('a request refused every time is retried eight times, then the view reports the failure', async ({ page, allowNoise }) => {
    test.setTimeout(200_000);
    allowNoise.push({ pattern: /^HTTP 429: /, reason: 'this spec refuses the view results request on purpose' });
    allowNoise.push({
        pattern: /console\.error: Failed to load resource.*429/i,
        reason: 'the browser logs each injected 429 the route fulfils',
    });

    const origin = new URL(fixtures.container).origin;
    const attempts = [];
    // The fixture view's results: its SELECT wrapped into a DESCRIBE and POSTed to the endpoint. dct:description is
    // what tells it from the children view's DESCRIBE on the same page; the view renames the variables per render,
    // never the predicates.
    const isViewResults = request => fromBlocks(request, origin) && request.method() === 'POST'
        && new URL(request.url()).pathname.endsWith('/sparql')
        && /\bDESCRIBE\b/i.test(request.postData() ?? '')
        && /description/.test(request.postData() ?? '');
    await page.route('**/*', route => {
        const request = route.request();
        if (isViewResults(request)) {
            attempts.push(Date.now());
            return route.fulfill({ status: 429, contentType: 'text/html', body: '<html><body>429 Too Many Requests</body></html>' });
        }
        return route.fallback();
    });

    await goto(page, fixtures.container);
    const block = fixtureView(page);

    await expect(block.locator('.ac-alert-title'), 'the view reports the failure').toBeVisible({ timeout: 120_000 });
    // a request the client is still retrying would come in after the alert; give it the longest wait there is
    const settledAt = attempts.length;
    await page.waitForTimeout(13_000);
    expect(attempts.length, 'nothing is sent after the view gave up').toBe(settledAt);
    expect(attempts.length, 'the first refusal and eight retries').toBe(9);
    const gaps = attempts.slice(1).map((t, i) => t - attempts[i]);
    expect(gaps[gaps.length - 1], 'the retries back off').toBeGreaterThan(gaps[0]);
});

// A query block runs its stored query on arrival. It used to send that request as an ixsl:schedule-action, outside the
// promise chains, so ldh:handle-response never saw its 429: the refused results became the block's "query failed"
// alert - every load of the Northwind front page under the limiter showed one on its CONSTRUCT graph block.
test('a query block retries its results request and tables them', { tag: '@owner' }, async ({ page, allowNoise }) => {
    test.setTimeout(120_000);
    allowNoise.push({ pattern: /^HTTP 429: /, reason: 'this spec refuses every block request once on purpose' });
    allowNoise.push({
        pattern: /console\.error: Failed to load resource.*429/i,
        reason: 'the browser logs each injected 429 the route fulfils',
    });
    allowNoise.push({
        pattern: /prefix\.cc/,
        reason: 'YASQE 2 fetches http://prefix.cc for prefix completion, blocked as mixed content (as in query.spec.mjs)',
    });

    const { sent, refused } = await record(page, { refuse: true });
    await goto(page, fixtures.queryDocument);
    const block = page.locator(`div.block.ldh-block[about="${fixtures.query}"]`);
    const table = block.locator('.sparql-query-results .google-visualization-table');

    await expect(table, 'the results are tabled').toBeVisible({ timeout: 30_000 });
    await expect(table.locator('tr')).toHaveCount(itemCount + 1);
    await expect(block.locator('.ac-alert-title'), 'and the block reports no failure').toHaveCount(0);
    expect(refused.size, 'the page made block requests to refuse').toBeGreaterThan(0);
    await expect.poll(() => [...refused].filter(key => !sent.has(key)), {
        message: 'every refused request is sent again',
        timeout: 30_000,
    }).toEqual([]);
});
