// The chart controls, each asserted on the drawing it changes.
//
// chart.spec asserts that the chart draws, and that a type change leaves it drawn. That is the
// floor. A control that was handled but ignored - the select changes, the redraw runs from the old
// state - leaves a drawing too. So each control is asserted on what only IT could have changed in
// the picture, read off the SVG Google Charts renders:
//
//   · the type: Table is HTML, every other type is SVG; and between the SVG types, which axis the
//     category labels sit on - a bar chart stacks them down the vertical axis (one x, three ys),
//     a line chart lays them along the horizontal (one y, three xs);
//   · the category: what the labels ARE - the kinds, or not;
//   · the series: what is measured - the axis is titled by the column drawn against it, and the
//     ticks scale to its values. The fixture's second column is a fixed multiple of the first
//     (every title is the same length), so the scale changes by more than any tick rounding.
//
// Positions are read from the text elements' attributes rather than their boxes: the chart is
// laid out in absolute SVG coordinates, and an attribute is what the renderer wrote.
import { test, expect } from '../../../../lib/console.mjs';
import { goto } from '../../../../lib/settle.mjs';
import { fixtures, kindCount, kinds } from '../../../../lib/fixtures.mjs';
import { controlToggle } from '../../../../lib/block.mjs';

const AC = 'https://w3id.org/atomgraph/client#';

// The fixture chart, by the chart it is (lib/fixtures.mjs `chart`): the block that carries the
// @about is the inner one, which owns the controls and the canvas.
const chartBlock = page => page.locator(`div.block.ldh-block[about="${fixtures.chart}"]`);
const canvas = block => block.locator('.chart-canvas');
const texts = block => block.locator('.chart-canvas svg text').allTextContents();
// [x, y] of every label that names a kind.
const kindLabels = block => block.locator('.chart-canvas svg text')
    .evaluateAll((nodes, names) => nodes
        .filter(node => names.includes(node.textContent))
        .map(node => [node.getAttribute('x'), node.getAttribute('y')]), kinds);
const distinct = (pairs, axis) => new Set(pairs.map(pair => pair[axis])).size;

// The controls are rendered from the results, so they are not usable until the chart has drawn.
async function opened(page) {
    await goto(page, fixtures.container);
    const block = chartBlock(page);
    await expect(canvas(block).locator('svg')).toBeVisible({ timeout: 30_000 });
    await controlToggle(block).click();
    await expect(block.locator('select.chart-type')).toHaveValue(`${AC}BarChart`);
    return block;
}

test.describe('the chart controls', { tag: '@owner' }, () => {
    test('Table tables the result set, and a chart type draws it again', async ({ page }) => {
        const block = await opened(page);
        const type = block.locator('select.chart-type');

        await type.selectOption(`${AC}Table`);

        const table = canvas(block).locator('.google-visualization-table');
        await expect(table).toBeVisible();
        await expect(canvas(block).locator('svg')).toHaveCount(0);
        // Its cells are the result set: the variables as the header, a kind and its count as a row.
        await expect(table.locator('tr').first()).toContainText('kind');
        await expect(table.locator('tr').nth(1)).toContainText(kinds[0]);
        await expect(table.locator('tr').nth(1)).toContainText(String(kindCount(kinds[0])));

        await type.selectOption(`${AC}LineChart`);

        await expect(canvas(block).locator('svg')).toBeVisible();
        await expect(table).toHaveCount(0);
    });

    test('the chart type decides which axis the categories go on', async ({ page }) => {
        const block = await opened(page);

        // A bar chart: the kinds share an x and are stacked down the vertical axis.
        await expect.poll(() => kindLabels(block)).toHaveLength(kinds.length);
        const bars = await kindLabels(block);
        expect(distinct(bars, 0), 'bar chart categories share one x').toBe(1);
        expect(distinct(bars, 1), 'bar chart categories are stacked').toBe(kinds.length);

        await block.locator('select.chart-type').selectOption(`${AC}LineChart`);

        // A line chart: the kinds share a y and are spread along the horizontal axis.
        await expect.poll(async () => {
            const lines = await kindLabels(block);
            return lines.length === kinds.length && distinct(lines, 1) === 1 && distinct(lines, 0) === kinds.length;
        }, { message: 'the line chart lays the categories along the horizontal axis' }).toBe(true);
    });

    test('the category select decides what the categories are', async ({ page }) => {
        const block = await opened(page);
        await expect.poll(() => texts(block)).toContain(kinds[0]);

        await block.locator('select.chart-category').selectOption('items');

        // Charted by count now: no kind is a label any more, and no axis is titled by it.
        await expect.poll(() => texts(block)).not.toContain(kinds[0]);
        const drawn = await texts(block);
        expect(drawn).not.toContain('kind');
        await expect(canvas(block).locator('svg')).toBeVisible();

        await block.locator('select.chart-category').selectOption('kind');

        await expect.poll(() => texts(block)).toContain(kinds[0]);
    });

    test('the series select decides what is measured', async ({ page }) => {
        const block = await opened(page);
        // Counts: the value axis is titled by the column and its ticks sit around the counts.
        await expect.poll(() => texts(block)).toContain('items');

        await block.locator('select.chart-series').selectOption(['chars']);

        await expect.poll(() => texts(block)).toContain('chars');
        const drawn = await texts(block);
        expect(drawn).not.toContain('items');
        // The ticks now range over character totals, which no count comes near.
        const ticks = drawn.map(Number).filter(Number.isFinite);
        expect(Math.max(...ticks)).toBeGreaterThan(Math.max(...kinds.map(kindCount)));
    });
});
