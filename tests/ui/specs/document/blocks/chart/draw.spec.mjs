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
// This is the floor. What each control then does to the drawing is controls.spec's, one assertion
// per control, and every one of them would be satisfied by the picture this asserts exists.
import { test, expect } from '../../../../lib/console.mjs';
import { goto, settled } from '../../../../lib/settle.mjs';
import { fixtures } from '../../../../lib/fixtures.mjs';
import { canvas, chartBlock, drawing } from '../../../../lib/chart.mjs';

test('draws its result set, rather than merely reserving a box for it', async ({ page }) => {
    await goto(page, fixtures.container);
    await settled(page);

    const block = chartBlock(page);
    await expect(canvas(block)).toBeVisible();

    // A drawing. Not the blank state, which is what an empty result set gets and what this
    // fixture spent its whole existence showing.
    await expect(drawing(block)).toBeVisible({ timeout: 30_000 });
    await expect(canvas(block).locator('.ldh-block-blank'), 'the chart matched nothing').toHaveCount(0);
});
