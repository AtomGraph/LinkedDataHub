// The chart block's series, in the order the query projects them.
//
// ldh:seriesVarName is multi-valued, and RDF keeps no order among a property's values, so the page
// lists the series in whatever order the server happened to serialize them. Some charts read their
// columns by position: a Timeline is row label, bar label, start, end. LTLOD's timeline declared
// "seats", "start", "end", was served end, start, seats, and Google Charts refused it with "Invalid
// data table format: column #1 must be of type 'string'" - in production, with nothing here to
// notice, because every fixture chart had a single series.
//
// The fixture declares four series in the reverse of the order its query projects them, and draws
// them as a Table, whose header row is the DataTable's column order read straight off the page.
// Four, because a chart ordering by anything but the projection still matches it by chance one
// time in 24; with two it would pass half the time without the fix.
import { test, expect } from '../../../../lib/console.mjs';
import { goto } from '../../../../lib/settle.mjs';
import { fixtures, seriesProjection } from '../../../../lib/fixtures.mjs';
import { canvas, chartBlock } from '../../../../lib/chart.mjs';

test('takes its series in the order the query projects them, not the order they are declared in', async ({ page }) => {
    await goto(page, fixtures.seriesDocument);

    const block = chartBlock(page, fixtures.seriesChart);
    const table = canvas(block).locator('.google-visualization-table');
    await expect(table).toBeVisible({ timeout: 30_000 });

    // The category first, then the series as SELECT lists them.
    await expect(table.locator('tr').first().locator('th')).toHaveText(['kind', ...seriesProjection]);
});
