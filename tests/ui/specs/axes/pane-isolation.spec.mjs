// A document's canvases are initialized within its pane, not across the page.
//
// A second tab is a second pane in the SAME document, and what the first pane holds has to survive
// the second one loading. It did not: after a document rendered into its pane, the flow initialized
// map, chart and 3D-graph canvases by looking them up across the whole page, so a newly opened
// dataspace was drawn as a table into every other tab's chart canvas and a second map was created
// in every other tab's map canvas (measured 2026-09-28 with three dataspace tabs: the front page's
// embedded chart became a 13-row table of the second dataspace's blocks, then an 18-row one of the
// third's). The lookups are scoped to the rendered pane now; these pin that.
//
// An axis rather than a component spec, for the reason the README gives: the claim is about the
// chart block and the map block - and the 3D graph beside them, on the same lookup - while the tab
// strip is only how a second pane is got at all. Filed under the strip it would have claimed
// coverage of two block kinds it merely opens, and left the strip's own spec asserting something
// that is not about the strip.
import { test, expect } from '../../lib/console.mjs';
import { goto } from '../../lib/settle.mjs';
import { fixtures } from '../../lib/fixtures.mjs';
import { inMode, MAP_MODE } from '../../lib/mode.mjs';
import { openSecondTab, panes } from '../../lib/tabs.mjs';

// The fixture is owner-owned, and the apps menu a second pane is opened from is offered to an
// authenticated agent - so anonymously there is no second pane to measure isolation across.
test.beforeEach(({}, testInfo) => {
    test.skip(testInfo.project.name !== 'owner',
        'a second pane is opened from the apps menu, which an anonymous reader is not offered');
});

test('a chart in the first tab is not redrawn when a second dataspace opens', { tag: '@owner' }, async ({ page }) => {
    await goto(page, fixtures.container);
    const canvas = panes(page).first().locator('.chart-canvas').first();
    await expect(canvas.locator('svg'), 'the fixture chart did not draw').toBeVisible({ timeout: 30_000 });
    const drawn = await canvas.evaluate(el => ({ svg: el.querySelectorAll('svg').length, rows: el.querySelectorAll('table tr').length, text: el.textContent.trim().slice(0, 80) }));

    await openSecondTab(page);

    // Still the chart it drew, not a table of the second dataspace's resources: the same SVG count and
    // the same rows and text, in the pane that was never rendered into again.
    await expect.poll(async () => canvas.evaluate(el => ({ svg: el.querySelectorAll('svg').length, rows: el.querySelectorAll('table tr').length, text: el.textContent.trim().slice(0, 80) })),
        'the first tab\'s chart canvas was redrawn by the second tab loading').toEqual(drawn);

    // And back on the first tab it is what the reader left: no page-level redraw on the switch either.
    await page.locator('ul.ldh-tabs a.ldh-tab').first().click();
    await expect(canvas.locator('svg')).toBeVisible();
    expect(await canvas.evaluate(el => el.querySelectorAll('svg').length)).toBe(drawn.svg);
});

test('a map in the first tab is not initialized again when a second dataspace opens', { tag: '@owner' }, async ({ page }) => {
    await goto(page, inMode(fixtures.container, MAP_MODE));
    const canvas = panes(page).first().locator('.map-canvas').first();
    await expect(canvas, 'the container did not render a map canvas in Map mode').toBeAttached({ timeout: 30_000 });
    // One map per canvas: OpenLayers mounts one viewport per map it creates into an element.
    await expect(canvas.locator('.ol-viewport')).toHaveCount(1, { timeout: 30_000 });

    await openSecondTab(page);

    // Before the fix a second map was created into this canvas, and the second set of controls showed.
    await expect(canvas.locator('.ol-viewport'), 'a second map was created in the first tab\'s map canvas').toHaveCount(1);
});
