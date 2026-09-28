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
import { goto, settled } from '../../lib/settle.mjs';
import { fixtures, itemUri } from '../../lib/fixtures.mjs';
import { inMode, MAP_MODE } from '../../lib/mode.mjs';
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
