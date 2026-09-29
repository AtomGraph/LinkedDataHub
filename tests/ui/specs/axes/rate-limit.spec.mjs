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
import { fixtures, itemTitle } from '../../lib/fixtures.mjs';
import { chartBlock, drawing } from '../../lib/chart.mjs';
import { fixtureView } from '../../lib/view.mjs';

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
    await page.route('**/*', route => {
        const request = route.request();
        if (!fromBlocks(request, origin)) return route.fallback();

        const key = keyOf(request);
        if (refuse && !refused.has(key)) {
            refused.add(key);
            // No Retry-After, as nginx sends none: the client falls back to its default wait.
            return route.fulfill({ status: 429, contentType: 'text/html', body: '<html><body>429 Too Many Requests</body></html>' });
        }
        sent.add(key);
        shapes.set(shapeOf(key), (shapes.get(shapeOf(key)) ?? 0) + 1);
        return route.fallback();
    });
    return { sent, shapes, refused };
}

// Every block on the fixture page, drawn: the chart has a picture, the view its first item, the
// object block the resource it names.
async function rendered(page) {
    await expect(drawing(chartBlock(page)), 'the chart draws').toBeVisible({ timeout: 30_000 });
    await expect(fixtureView(page), 'the view lists the items').toContainText(itemTitle(1), { timeout: 30_000 });
    await expect(page.locator(`div.block.ldh-block[about="${fixtures.object}"] .ldh-obj-value`).first(),
        'the object block renders its resource').not.toBeEmpty({ timeout: 30_000 });
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
    await unrefused.waitForLoadState('networkidle');
    await unrefused.close();

    const { sent, shapes, refused } = await record(page, { refuse: true });
    await goto(page, fixtures.container);
    await rendered(page);

    expect(refused.size, 'the page made block requests to refuse').toBeGreaterThan(0);
    // Polled: a block renders from its first response, and the view's count and facet requests are
    // still waiting out their Retry-After when its items are already on the page.
    await expect.poll(() => [...refused].filter(key => !sent.has(key)), {
        message: 'every refused request is sent again',
        timeout: 20_000,
    }).toEqual([]);
    await page.waitForLoadState('networkidle');
    const extra = [...shapes].filter(([shape, count]) => count > (baseline.shapes.get(shape) ?? 0))
        .map(([shape, count]) => `${count}x (baseline ${baseline.shapes.get(shape) ?? 0}x) ${shape}`);
    expect(extra, 'nothing is fetched more often than an unrefused load fetches it').toEqual([]);
});
