// The dataspace tab strip, and the apps menu that fills it.
//
// A LinkedDataHub instance serves several dataspaces, each on its own subdomain, and the strip is
// how a reader keeps more than one open at a time. With a single dataspace there is nothing to
// choose between, and the strip stays out of the way - present in the DOM, not shown - which is
// worth pinning as the deliberate state it is rather than leaving it to look like an element that
// failed to render.
//
// The apps menu is the other half: it lists the dataspaces this instance serves, each as a link
// to its origin. Its behaviour as a menu belongs to controls/menu; what it HOLDS is here.
import { test, expect } from '../../lib/console.mjs';
import { goto, loaded, settled } from '../../lib/settle.mjs';
import { fixtures, itemUri, remoteDocument, remoteDocumentTitle } from '../../lib/fixtures.mjs';
import { inMode, MAP_MODE, READ_MODE } from '../../lib/mode.mjs';
import { apps, strip } from '../../lib/tabs.mjs';

test.beforeEach(({}, testInfo) => {
    test.skip(testInfo.project.name !== 'owner',
        'the apps list is offered to an authenticated agent; the fixture is not readable anonymously');
});

test('stays out of the way while one dataspace is open', { tag: '@owner' }, async ({ page }) => {
    await goto(page, itemUri(1));
    await settled(page);

    // Present and unshown, which is not the same as missing: the strip is what a second dataspace
    // would be added to, so it is built with the page.
    await expect(strip(page)).toBeAttached();
    await expect(strip(page)).toBeHidden();
});

test('the apps menu lists the dataspaces this instance serves', { tag: '@owner' }, async ({ page }) => {
    await goto(page, itemUri(1));
    await settled(page);

    await apps(page).locator('button.btn-apps').click();
    const entries = apps(page).locator('.ac-menu a[href]');
    expect(await entries.count(), 'the apps menu offered no dataspace').toBeGreaterThan(0);
    // Each one is an origin to open, so each carries an address rather than a script hook.
    await expect(entries.first()).toHaveAttribute('href', /^https?:\/\//);
});

// A second tab is a second pane on the same page, and what the first pane holds has to survive
// the second one loading. It did not: after a document rendered into its pane, the flow
// initialized map, chart and 3D-graph canvases by looking them up across the whole page, so a
// newly opened dataspace was drawn as a table into every other tab's chart canvas and a second
// map was created in every other tab's map canvas (measured 2026-09-28 with three dataspace tabs:
// the front page's embedded chart became a 13-row table of the second dataspace's blocks, then an
// 18-row one of the third's). The lookups are scoped to the rendered pane now; these pin that.

// The other dataspace this instance serves, as the apps menu offers it: any origin but this one.
const otherDataspace = async page => {
    await apps(page).locator('button.btn-apps').click();
    const entries = apps(page).locator('.ac-menu a[href]');
    const hrefs = await entries.evaluateAll(as => as.map(a => a.getAttribute('href')));
    const index = hrefs.findIndex(href => !href.startsWith(new URL(page.url()).origin));
    expect(index, `the apps menu offered no dataspace but this one: ${hrefs.join(', ')}`).toBeGreaterThanOrEqual(0);
    return entries.nth(index);
};

// Opening it from the menu adds a tab and renders the dataspace into a new pane while the first
// pane stays in the DOM, hidden.
const openSecondTab = async page => {
    await (await otherDataspace(page)).click();
    await expect(page.locator('ul.ldh-tabs a.ldh-tab')).toHaveCount(2, { timeout: 30_000 });
    await settled(page, { selector: '.ldh-pane.is-active .ldh-block' });
};

const firstPane = page => page.locator('div.ldh-pane').first();
const drawing = canvas => canvas.evaluate(el => ({ svg: el.querySelectorAll('svg').length, rows: el.querySelectorAll('table tr').length, text: el.textContent.trim().slice(0, 80) }));

test('a chart in the first tab is not redrawn when a second dataspace opens', { tag: '@owner' }, async ({ page }) => {
    await goto(page, fixtures.container);
    const canvas = firstPane(page).locator('.chart-canvas').first();
    await expect(canvas.locator('svg'), 'the fixture chart did not draw').toBeVisible({ timeout: 30_000 });
    const drawn = await drawing(canvas);

    await openSecondTab(page);

    // Still the chart it drew, not a table of the second dataspace's resources: the same SVG count,
    // rows and text, in the pane that was never rendered into again.
    await expect.poll(() => drawing(canvas), 'the first tab\'s chart canvas was redrawn by the second tab loading').toEqual(drawn);

    // And back on the first tab it is what the reader left: no page-level redraw on the switch either.
    await page.locator('ul.ldh-tabs a.ldh-tab').first().click();
    await expect(canvas.locator('svg')).toBeVisible();
    expect(await drawing(canvas)).toEqual(drawn);
});

test('a map in the first tab is not initialized again when a second dataspace opens', { tag: '@owner' }, async ({ page }) => {
    await goto(page, inMode(fixtures.container, MAP_MODE));
    const canvas = firstPane(page).locator('.map-canvas').first();
    await expect(canvas, 'the container did not render a map canvas in Map mode').toBeAttached({ timeout: 30_000 });
    // One map per canvas: OpenLayers mounts one viewport per map created into an element.
    await expect(canvas.locator('.ol-viewport')).toHaveCount(1, { timeout: 30_000 });

    await openSecondTab(page);

    // Before the fix a second map was created into this canvas, and a second set of controls showed.
    await expect(canvas.locator('.ol-viewport'), 'a second map was created in the first tab\'s map canvas').toHaveCount(1);
});

// A pane records the status of the response it renders (data-status), and a switch to a tab whose pane shows its document
// as it loaded - a 200 - shows the pane as it is, where any other tab loads its document again. Both tabs in ReadMode,
// the mode a remote document opens in: a tab whose link names another mode than the page being left is navigated to
// and loaded again, by design, whatever the pane holds.
const activePane = page => page.locator('#tab-content div.ldh-pane.is-active');
const tabOf = (page, uri) => page.locator(`#tab-bar-list li[data-uri="${uri}"]`);
const allowPrefixCc = allowNoise => allowNoise.push({
    pattern: /prefix\.cc/,
    reason: 'YASQE 2 fetches http://prefix.cc for prefix completion, blocked as mixed content (as in query.spec.mjs)',
});

// the documents' own loads: the local one by its URI, the remote one through the proxy (?uri=)
function loadsOf(page, remote) {
    const loads = [];
    page.on('request', request => {
        if (request.method() !== 'GET') return;
        if (request.url() === fixtures.container || new URL(request.url()).searchParams.get('uri') === remote)
            loads.push(`${request.resourceType()} ${request.headers()['accept'] ?? '-'} ${request.url()}`);
    });
    return loads;
}

async function openRemote(page, remote) {
    await page.locator('form.ldh-address input#uri').fill(remote);
    await page.locator('form.ldh-address input#uri').press('Enter');
    await expect(tabOf(page, remote)).toHaveCount(1, { timeout: 30_000 });
    await expect(activePane(page).locator('div.document-body')).toHaveAttribute('about', remote, { timeout: 30_000 });
}

test('a page that was opened records that its document loaded', { tag: '@owner' }, async ({ page, allowNoise }) => {
    allowPrefixCc(allowNoise);
    await goto(page, inMode(fixtures.container, READ_MODE));

    await expect(activePane(page)).toHaveAttribute('data-status', '200', { timeout: 30_000 });
});

test('switching back to a tab shows its pane without loading the document again', { tag: '@owner' }, async ({ page, allowNoise }) => {
    allowPrefixCc(allowNoise);
    const remote = remoteDocument();
    await goto(page, inMode(fixtures.container, READ_MODE));
    await expect(activePane(page)).toHaveAttribute('data-status', '200', { timeout: 30_000 });
    await loaded(page);
    await openRemote(page, remote);
    await expect(activePane(page)).toHaveAttribute('data-status', '200');

    const loads = loadsOf(page, remote);
    await tabOf(page, fixtures.container).locator('a').click();
    await expect(activePane(page).locator('div.document-body')).toHaveAttribute('about', fixtures.container);
    await tabOf(page, remote).locator('a').click();
    await expect(activePane(page).locator('div.document-body')).toHaveAttribute('about', remote);
    await tabOf(page, fixtures.container).locator('a').click();
    await expect(activePane(page).locator('div.document-body')).toHaveAttribute('about', fixtures.container);

    // the switches settle synchronously; anything they sent would have been issued by now
    await page.waitForTimeout(1_000);
    expect(loads, 'a tab switch loaded a document again').toEqual([]);
});

test('a tab whose document failed to load loads it again when switched back to', { tag: '@owner' }, async ({ page, allowNoise }) => {
    allowPrefixCc(allowNoise);
    allowNoise.push({ pattern: /HTTP 401|status of 401/, reason: 'the spec fails the remote document\'s first load on purpose' });
    const remote = remoteDocument();
    const isProxied = url => new URL(url).searchParams.get('uri') === remote;
    await goto(page, inMode(fixtures.container, READ_MODE));
    await expect(activePane(page)).toHaveAttribute('data-status', '200', { timeout: 30_000 });
    await loaded(page);

    // the first load is refused; the error renders in the remote document's own tab, and the pane records it
    await page.route(isProxied, route => route.request().resourceType() === 'document' ? route.fallback()
        : route.fulfill({ status: 401, contentType: 'text/html', body: '<html><body>401</body></html>' }));
    await openRemote(page, remote);
    await expect(activePane(page)).toHaveAttribute('data-status', '401');

    await tabOf(page, fixtures.container).locator('a').click();
    await expect(activePane(page).locator('div.document-body')).toHaveAttribute('about', fixtures.container);

    // the remote document answers now, and switching back asks it again rather than showing the error it left
    await page.unroute(isProxied);
    const loads = loadsOf(page, remote);
    await tabOf(page, remote).locator('a').click();
    await expect(activePane(page).locator('div.document-body')).toHaveAttribute('about', remote);
    await expect(activePane(page)).toHaveAttribute('data-status', '200', { timeout: 30_000 });
    await expect(activePane(page).locator('div.document-body')).toContainText(remoteDocumentTitle, { timeout: 30_000 });
    expect(loads.length, 'switching back loaded the document again').toBeGreaterThan(0);
});
