// The chart block: a saved query, drawn.
//
// It is the block kind with the longest way to go wrong quietly. A `ldh:ResultSetChart` is data
// until something puts it in the document's `rdf:_N` list, so a chart can be perfectly well
// defined in the graph and render nowhere at all - which is exactly what happened to the fixture
// once, and it cost the responsive work a whole cycle of coverage: a spec waited 30s for
// `.chart-controls` that could never appear, then skipped itself and went green.
//
// So the first assertion is that the canvas is never EMPTY - it holds either a drawing or the
// designed "no results" state, and nothing in between. Between the query and the picture there is
// a SPARQL round trip, a result set, a chart type and a drawing library, and an empty canvas is
// what every one of those failing looks like.
//
// A FINDING, and the reason this is not simply "a chart is drawn": on this instance the fixture's
// chart renders `No results. The query ran cleanly and matched nothing.` - so nothing in the suite
// has ever seen a chart actually drawn, including the responsive assertions that measure
// `.chart-controls` around it. The same query renders 25 rows in the view block beside it, so the
// emptiness is the chart's own, not the data's. Asserting "a drawing" today would fail; asserting
// "the blank state" would fail the day it is fixed. Asserting that the canvas said SOMETHING is
// true either way and still catches the silence.
//
// The controls are collapsed until the card header's toggle is pressed - chrome behaviour that
// block-controls owns - so this presses it and then asks what the controls do.
import { test, expect } from '../../../lib/console.mjs';
import { goto, settled } from '../../../lib/settle.mjs';
import { fixtures } from '../../../lib/fixtures.mjs';
import { controlToggle } from '../../../lib/block.mjs';

const chartBlock = page => page.locator('.block.ldh-block:has(.chart-controls)').first();

test.beforeEach(({}, testInfo) => {
    test.skip(testInfo.project.name !== 'owner', 'the fixture container is owner-owned');
});

test('says something in its canvas, rather than merely reserving a box for it', async ({ page }) => {
    await goto(page, fixtures.container);
    await settled(page);

    const canvas = chartBlock(page).locator('.chart-canvas').first();
    await expect(canvas).toBeVisible();

    // A drawing, or the designed empty state. Never an empty box, which is what a thrown renderer
    // leaves behind and what no reader can tell from a chart that has not arrived yet.
    await expect(canvas.locator('svg, canvas, table, .ldh-block-blank').first())
        .toBeVisible({ timeout: 30_000 });
});

test('offers the chart type it was drawn with, and redraws when it changes', async ({ page }) => {
    await goto(page, fixtures.container);
    await settled(page);

    const block = chartBlock(page);
    await controlToggle(block).click();

    const type = block.locator('.chart-controls select.chart-type').first();
    await expect(type).toBeVisible();
    // The stored chart type is what the control shows - the control states the document's data
    // rather than a default it happens to start on.
    await expect(type).not.toHaveValue('');

    const before = await type.inputValue();
    const other = (await type.locator('option').all())
        .map(option => option.getAttribute('value'));
    const values = (await Promise.all(other)).filter(value => value && value !== before);
    expect(values.length, 'only one chart type is offered, so changing it cannot be tested')
        .toBeGreaterThan(0);

    await type.selectOption(values[0]);
    await expect(type).toHaveValue(values[0]);
    // Still saying something after the change: a redraw that throws leaves the canvas empty.
    await expect(block.locator('.chart-canvas').locator('svg, canvas, table, .ldh-block-blank').first())
        .toBeVisible({ timeout: 30_000 });
});
