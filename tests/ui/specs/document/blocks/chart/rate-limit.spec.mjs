// The chart block, when its results request is rate-limited.
//
// A page of content blocks fires more requests at once than nginx's `linked_data` zone lets through
// (15 r/s, burst 30), so on a busy page some of them come back 429 and the client retries them after
// Retry-After. The retry re-sent `$context('request')` whatever step it was retrying - and for a
// chart that is the GET of the query's DOCUMENT, the first request of its chain, not the POST of
// the query. The chart was handed the document's RDF/XML as its "results", mapped `?kind` and
// `?items` as property URIs onto it, and drew "Table has no columns." over one row per resource in
// the document. Which chart it hit depended on which request the limiter refused, so on the
// Northwind demo it was a different chart on every reload, and reloading "fixed" it.
//
// The limiter is not something a spec can trigger on demand, so the 429 is fulfilled by a route -
// once, for the results POST alone - and the assertion is on both ends of the retry: the request
// that went out again, and the picture it drew.
import { test, expect } from '../../../../lib/console.mjs';
import { goto } from '../../../../lib/settle.mjs';
import { fixtures, kinds } from '../../../../lib/fixtures.mjs';
import { canvas, chartBlock, drawing } from '../../../../lib/chart.mjs';

// The results request: the fixture chart's query, POSTed to the endpoint. Its body is the query
// text, and the aggregate is what tells it from the view's query over the same items.
const isResults = request => request.method() === 'POST'
    && /COUNT\(\?item\) AS \?items/.test(request.postData() ?? '');

test('a results request refused with 429 is retried, and the chart draws its own results', async ({ page, allowNoise }) => {
    allowNoise.push({ pattern: /^HTTP 429: /, reason: 'this spec refuses the results request once on purpose' });
    allowNoise.push({
        pattern: /console\.error: Failed to load resource.*429/i,
        reason: 'the browser logs the injected 429 the route fulfils',
    });

    const results = [];
    await page.route('**/*', route => {
        const request = route.request();
        if (!isResults(request)) return route.fallback();

        results.push(request);
        // No Retry-After, as nginx sends none: the client falls back to its default wait.
        return results.length === 1
            ? route.fulfill({ status: 429, contentType: 'text/html', body: '<html><body>429 Too Many Requests</body></html>' })
            : route.fallback();
    });

    await goto(page, fixtures.container);

    const block = chartBlock(page);
    await expect(drawing(block), 'the chart draws after the retry').toBeVisible({ timeout: 30_000 });
    // What went out again is the query, not the document it is stored in. Before the fix the count
    // stayed at 1: the retry was a GET, which this route never sees.
    expect(results, 'the refused results POST is the request that is retried').toHaveLength(2);
    expect(results[1].postData()).toBe(results[0].postData());

    // And the drawing is of the query's rows: a label per kind. A chart drawn from the document's
    // RDF/XML has no column the category maps onto, so it has no kind labels either.
    const labels = await canvas(block).locator('svg text').allTextContents();
    for (const kind of kinds) {
        expect(labels, `the ${kind} bar is labelled`).toContain(kind);
    }
    await expect(canvas(block), 'the chart matched nothing').not.toContainText('Table has no columns');
});
