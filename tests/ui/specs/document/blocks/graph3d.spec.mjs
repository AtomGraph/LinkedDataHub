// The 3D graph: the document's statements as a graph, because that is what they are.
//
// Like the map it is a rendering mode rather than a thing in the document - `?mode=GraphMode`
// asks for it and the platform lays the current results out as nodes and links. It is the mode
// that most directly shows what the other modes are abbreviating: a property list is a graph
// drawn as a table, and this is the same data with the abbreviation removed.
//
// Its interaction rule is the one thing here that is not obvious and is easy to regress: a single
// click selects a node and shows its detail, and only a DOUBLE click expands it. Getting that
// backwards makes every incidental click pull in another hop of the graph.
import { test, expect } from '../../../lib/console.mjs';
import { goto } from '../../../lib/settle.mjs';
import { fixtures } from '../../../lib/fixtures.mjs';
import { GRAPH_MODE, inMode } from '../../../lib/mode.mjs';

const canvas = page => page.locator('.graph-3d-canvas').first();

test('draws when the URL asks for it, and not before', async ({ page }) => {
    await goto(page, fixtures.container);
    // Hidden rather than absent: the host element is part of every document's shell, and the mode
    // is what brings it forward. Asserting its absence would be asserting the wrong mechanism.
    await expect(canvas(page), 'a graph was drawn on a page that did not ask for one').toBeHidden();

    await goto(page, inMode(fixtures.container, GRAPH_MODE));
    await expect(canvas(page)).toBeVisible({ timeout: 30_000 });
});

test('renders a scene, not an empty element', async ({ page }) => {
    await goto(page, inMode(fixtures.container, GRAPH_MODE));

    // The force-graph library mounts its own WebGL canvas inside the host element. Without it the
    // host is a sized div and the page looks like a graph that is still loading, forever.
    await expect(canvas(page).locator('canvas').first()).toBeVisible({ timeout: 30_000 });
});
