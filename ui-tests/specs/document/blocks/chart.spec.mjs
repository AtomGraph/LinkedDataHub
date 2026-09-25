// The chart block: a saved query, drawn.
//
// It is the block kind with the longest way to go wrong quietly. A `ldh:ResultSetChart` is data
// until something puts it in the document's `rdf:_N` list, so a chart can be perfectly well
// defined in the graph and render nowhere at all - which is exactly what happened to the fixture
// once, and it cost the responsive work a whole cycle of coverage: a spec waited 30s for
// `.chart-controls` that could never appear, then skipped itself and went green.
//
// So the assertion is that the chart IS DRAWN. Between the query and the picture there is a SPARQL
// round trip, a result set, a category and series to map it onto, a chart type and a drawing
// library; a drawn chart is the only assertion that covers all six at once, and every one of them
// failing looks identical from outside - an empty box.
//
// It was empty, for two reasons stacked one behind the other, and writing this spec is what found
// both. First the canvas read `No results. The query ran cleanly and matched nothing.` - the query
// asked for `sioc:has_parent` where an item created in a container states `sioc:has_container`, so
// it matched nothing (0 rows against the endpoint, 25 after the predicate was corrected). With rows
// finally arriving the canvas said something new: `Data column(s) for axis #0 cannot be of type
// string`. A bar chart's value axis must be numeric and the chart was plotting ?title. The fixture
// now charts a count per kind and lists the items with the other query, which is the same division
// the product's own rule makes - aggregates belong in charts, not in views.
//
// The chart block was right both times; it reported exactly what it had been given. Nothing caught
// either because no spec had ever asserted that a chart DREW anything - not here, and not in the
// responsive axis, which measures `.chart-controls` around whatever the canvas holds.
//
// The controls are collapsed until the card header's toggle is pressed - chrome behaviour that
// block-controls owns - so this presses it and then asks what the controls do.
import { test, expect } from '../../../lib/console.mjs';
import { goto, settled } from '../../../lib/settle.mjs';
import { fixtures } from '../../../lib/fixtures.mjs';
import { controlToggle } from '../../../lib/block.mjs';

const chartBlock = page => page.locator('.block.ldh-block:has(.chart-controls)').first();

test('draws its result set, rather than merely reserving a box for it', async ({ page }) => {
    await goto(page, fixtures.container);
    await settled(page);

    const canvas = chartBlock(page).locator('.chart-canvas').first();
    await expect(canvas).toBeVisible();

    // A drawing. Not the blank state, which is what an empty result set gets and what this
    // fixture spent its whole existence showing.
    await expect(canvas.locator('svg, canvas, table').first()).toBeVisible({ timeout: 30_000 });
    await expect(canvas.locator('.ldh-block-blank'), 'the chart matched nothing').toHaveCount(0);
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
    // Still drawn after the change: a redraw that throws leaves the canvas empty behind it.
    await expect(block.locator('.chart-canvas').locator('svg, canvas, table').first())
        .toBeVisible({ timeout: 30_000 });
});
