// The chart block: the block that owns the controls and the canvas.
//
// A chart reaches the page wrapped in an Object block (lib/fixtures.mjs, `chartBlock`), because a
// ldh:ResultSetChart is data until something puts it in the document's rdf:_N list. So a document
// rendering one holds two nested `div.block.ldh-block` elements, and only the INNER one carries
// the chart's @about, its card header, its controls and its canvas.
//
// Which is why the chart is addressed by the chart it draws. `:has(.chart-controls)` matches both
// blocks, and `.first()` then resolves the wrapper - reaching the toggle and the canvas through it
// by nesting alone, and only for as long as the wrapper has no header of its own. Two specs
// addressed it that way and a third by @about, which is three spellings of one block.
import { fixtures } from './fixtures.mjs';

export const chartBlock = (page, uri = fixtures.chart) =>
    page.locator(`div.block.ldh-block[about="${uri}"]`);

export const canvas = block => block.locator('.chart-canvas');

// Whatever the drawing library put in the canvas: an SVG for every chart type but Table, which
// Google Charts renders as HTML. An empty canvas is what a chart that matched nothing and a redraw
// that threw look like alike, so this is what "drawn" means.
export const drawing = block => canvas(block).locator('svg, canvas, table').first();

export const chartType = block => block.locator('select.chart-type');
