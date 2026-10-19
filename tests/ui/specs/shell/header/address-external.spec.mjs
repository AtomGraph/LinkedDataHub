// An external document whose RDF cannot be retrieved opens as a page, where a reader can read it.
//
// Following an external URI makes the client ask the Linked Data proxy (`?uri=`) for its RDF. When
// none comes back the document is still a page for people: the client opens it the way a
// target="_blank" link would, with no opener, and leaves the address bar, history and tab bar on the
// document being read. It used to do that only for a 406 (an HTML page with no JSON-LD), and every
// other failure ended on an error page about a document the reader never got to see - a 405 from an
// instance whose proxy is disabled, or the origin's own 500, relayed verbatim, from a site that
// serves the page to a browser but fails on an RDF Accept.
//
// Not every failure is the origin's, though. A 401 or 403 is one the reader can act on here (log in,
// request access), and a 429 that outlasted the client's retries is this platform's own rate limit -
// those still render as errors, as does any failure of a document on this platform's own origin.
//
// Injected rather than reached: the proxy's answer is the variable, and no origin can be made to
// produce each status on demand. The routes fulfil the proxy request itself, and the external origin
// is a reserved name that never resolves, served by a route as well, so nothing leaves the browser.
import { test, expect } from '../../../lib/console.mjs';
import { goto } from '../../../lib/settle.mjs';
import { itemUri } from '../../../lib/fixtures.mjs';

const EXTERNAL = 'https://external.example/document';
const EXTERNAL_ORIGIN = /^https:\/\/external\.example\//;

const uri = page => page.locator('form.ldh-address input#uri');
const activeBody = page => page.locator('#tab-content div.ldh-pane.is-active div.document-body');

// The client's RDF request for the external document: the proxy entry point on this origin, with the
// document as `uri=`. Matched on the parameter's value rather than the encoded URL string.
const isProxyRequest = request => ['fetch', 'xhr'].includes(request.resourceType())
    && new URL(request.url()).searchParams.get('uri') === EXTERNAL;

// The proxy refuses, with the status under test. Retry-After: 0 so a 429 runs through the client's
// retries at once instead of over its ~47 s exponential backoff.
async function proxyAnswers(page, status) {
    await page.route(url => new URL(url).searchParams.get('uri') === EXTERNAL, route => {
        if (!isProxyRequest(route.request())) return route.fallback();
        return route.fulfill({
            status,
            contentType: 'text/html',
            headers: status === 429 ? { 'Retry-After': '0' } : {},
            body: `<html><body>${status}</body></html>`,
        });
    });
    // The page itself, for whichever window ends up opening it. A context route, because a popup is a
    // page of its own and a page route does not reach it.
    await page.context().route(EXTERNAL_ORIGIN, route => route.fulfill({
        status: 200,
        contentType: 'text/html',
        body: '<!doctype html><html><head><title>External</title></head><body><p>An external page</p></body></html>',
    }));
}

// The injected failure is the point of the test, so its noise is declared rather than tolerated.
function allowInjected(allowNoise, status) {
    allowNoise.push({ pattern: new RegExp(`HTTP ${status}: .*uri=${EXTERNAL}`), reason: 'this spec fails the proxy request on purpose' });
    allowNoise.push({ pattern: new RegExp(`Failed to load resource.*status of ${status}`), reason: 'the browser logs the injected failure' });
}

async function follow(page, href) {
    await uri(page).fill(href);
    await uri(page).press('Enter');
}

for (const status of [405, 406, 500]) {
    test(`a ${status} from the proxy opens the external document in a new tab`, async ({ page, allowNoise }) => {
        allowInjected(allowNoise, status);
        await proxyAnswers(page, status);
        await goto(page, itemUri(1));

        const popup = page.waitForEvent('popup');
        await follow(page, EXTERNAL);
        const opened = await popup;

        await expect(opened).toHaveURL(EXTERNAL);
        await expect(opened.locator('body')).toContainText('An external page');
        // what rel="noopener" does for a link: the external page gets no handle on this one
        expect(await opened.evaluate(() => window.opener)).toBeNull();

        // and this window stays on the document being read: address, bar, pane and tab bar
        await expect(page).toHaveURL(itemUri(1));
        await expect(uri(page)).toHaveValue(itemUri(1));
        await expect(activeBody(page)).toHaveAttribute('about', itemUri(1));
        await expect(page.locator(`#tab-bar-list li[data-uri="${EXTERNAL}"]`)).toHaveCount(0);
    });
}

// Without the user activation of a click - it expired during the request, or the page was loaded with
// ?uri= in the address bar - the popup is blocked, and the window navigates there itself. Playwright's
// Chromium never blocks popups, so the blocked open is stood in for: window.open answers null, which is
// what a blocked one returns.
test('a blocked popup navigates the window to the external document', async ({ page, allowNoise }) => {
    allowInjected(allowNoise, 406);
    await page.addInitScript(() => { window.open = () => null; });
    await proxyAnswers(page, 406);
    await goto(page, itemUri(1));

    await follow(page, EXTERNAL);

    await expect(page).toHaveURL(EXTERNAL, { timeout: 30_000 });
    await expect(page.locator('body')).toContainText('An external page');
});

for (const status of [401, 403, 429]) {
    test(`a ${status} from the proxy renders the error here`, async ({ page, allowNoise }) => {
        allowInjected(allowNoise, status);
        await proxyAnswers(page, status);
        await goto(page, itemUri(1));

        const popups = [];
        page.on('popup', popup => popups.push(popup));
        await follow(page, EXTERNAL);

        // the error renders as the external document's own tab, as a document that loaded would
        await expect(page.locator(`#tab-bar-list li[data-uri="${EXTERNAL}"]`)).toHaveCount(1, { timeout: 30_000 });
        await expect(activeBody(page)).toHaveAttribute('about', EXTERNAL);
        expect(popups).toHaveLength(0);
    });
}

// A document on this platform's own origin is never handed to the browser to open: whatever it
// failed with, the reader is already where it lives.
test('a failing document on this origin renders the error here', async ({ page, allowNoise }) => {
    const local = itemUri(2);
    allowNoise.push({ pattern: new RegExp(`HTTP 500: ${local}`), reason: 'this spec fails the document request on purpose' });
    allowNoise.push({ pattern: /Failed to load resource.*status of 500/, reason: 'the browser logs the injected failure' });
    await page.route(local, route => ['fetch', 'xhr'].includes(route.request().resourceType())
        ? route.fulfill({ status: 500, contentType: 'text/html', body: '<html><body>500</body></html>' })
        : route.fallback());
    await goto(page, itemUri(1));

    const popups = [];
    page.on('popup', popup => popups.push(popup));
    await follow(page, local);

    await expect(page).toHaveURL(local);
    await expect(activeBody(page)).toHaveAttribute('about', local, { timeout: 30_000 });
    expect(popups).toHaveLength(0);
});
