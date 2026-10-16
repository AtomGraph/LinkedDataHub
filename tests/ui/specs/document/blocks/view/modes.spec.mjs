// A view switched to a canvas mode draws its canvas.
//
// Chart, map and 3D graph are the layout modes that render into a canvas a library draws on -
// Google Charts, OpenLayers, 3d-force-graph - rather than into markup. Switching a view to one
// renders the canvas and hands it over to be drawn (ldh:InitCanvas), the map from the view's own
// query and the chart and the graph from its results. What is asserted is the library's own surface
// inside the canvas: an element sized for a chart is not a chart. The graph is the one canvas a view
// keeps across renders, so coming back to it redraws the same graph rather than starting another.
import { test, expect } from '../../../../lib/console.mjs';
import { goto } from '../../../../lib/settle.mjs';
import { fixtures } from '../../../../lib/fixtures.mjs';
import { controlToggle } from '../../../../lib/block.mjs';
import { fixtureView, listRows, switchMode } from '../../../../lib/view.mjs';

test.describe('a view switched to a canvas mode', () => {
    test.beforeEach(async ({ page }) => {
        await goto(page, fixtures.container);
        await expect(listRows(fixtureView(page)).first()).toBeVisible({ timeout: 30_000 });
        // the mode switcher is in the view's toolbar, which stays collapsed until the block's controls are shown
        await controlToggle(fixtureView(page)).click();
    });

    test('draws a chart of its results', async ({ page }) => {
        const block = fixtureView(page);
        await switchMode(block, 'chart');
        await expect(block.locator('.chart-canvas').locator('svg, table').first()).toBeVisible({ timeout: 30_000 });
    });

    test('draws a map', async ({ page }) => {
        const block = fixtureView(page);
        await switchMode(block, 'map');
        await expect(block.locator('.map-canvas .ol-viewport').first()).toBeVisible({ timeout: 30_000 });
    });

    test('draws a graph, and draws the same graph again when it comes back to it', async ({ page }) => {
        const block = fixtureView(page);
        await switchMode(block, 'graph');
        const graph = block.locator('.graph-3d-canvas');
        await expect(graph.locator('canvas').first()).toBeVisible({ timeout: 30_000 });

        await switchMode(block, 'list');
        await expect(listRows(block).first()).toBeVisible({ timeout: 30_000 });
        await switchMode(block, 'graph');
        await expect(graph).toHaveCount(1);
        await expect(graph.locator('canvas').first()).toBeVisible({ timeout: 30_000 });
    });
});
