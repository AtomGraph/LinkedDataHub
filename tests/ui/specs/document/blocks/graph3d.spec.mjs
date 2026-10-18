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
import { fixtures, itemUri } from '../../../lib/fixtures.mjs';
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

// The graph's own requests - a node's document on a double click, its backlinks on a right click -
// went straight from the HTTP request to their handler, past ldh:handle-response, so a 429 from the
// rate limiter failed them where every block's request is retried. The limiter cannot be triggered
// on demand, so a route refuses the request once, and the graph has to get it on the retry. The
// node events are the ones the force-graph library dispatches on the document, sent here directly:
// a node is a sprite in a WebGL scene, with nothing in the DOM to click.
test.describe('a refused graph request is retried', () => {
    test.beforeEach(({ allowNoise }) => {
        allowNoise.push({ pattern: /^HTTP 429: /, reason: 'the request is refused once on purpose' });
        allowNoise.push({
            pattern: /console\.error: Failed to load resource.*429/i,
            reason: 'the browser logs the injected 429 the route fulfils',
        });
    });

    // Refuse the first request matching `matches` with a 429, and count the ones let through.
    async function refuseOnce(page, matches) {
        const counts = { refused: 0, sent: 0 };
        await page.route(url => matches(url), route => {
            if (!['xhr', 'fetch'].includes(route.request().resourceType())) return route.fallback();
            if (counts.refused === 0) {
                counts.refused++;
                // No Retry-After, as nginx sends none: the client falls back to its own backoff.
                return route.fulfill({ status: 429, contentType: 'text/html', body: '<html><body>429 Too Many Requests</body></html>' });
            }
            counts.sent++;
            return route.fallback();
        });
        return counts;
    }

    async function graphReady(page) {
        await goto(page, inMode(fixtures.container, GRAPH_MODE));
        await expect(canvas(page).locator('canvas').first()).toBeVisible({ timeout: 30_000 });
        const canvasId = await canvas(page).getAttribute('id');
        await page.waitForFunction(id => window.LinkedDataHub?.graphs?.[id]?.['loaded-uris'] !== undefined, canvasId);
        return canvasId;
    }

    const nodeEvent = (page, name, canvasId, nodeId) => page.evaluate(([name, canvasId, nodeId]) =>
        document.dispatchEvent(new CustomEvent(name, { detail: { canvasId, nodeId, nodeLabel: nodeId } })),
        [name, canvasId, nodeId]);

    const loaded = (page, canvasId, list, nodeId) => page.evaluate(([canvasId, list, nodeId]) =>
        window.LinkedDataHub.graphs[canvasId][list].includes(nodeId), [canvasId, list, nodeId]);

    test('a node\'s backlinks, on a right click', async ({ page }) => {
        const canvasId = await graphReady(page);
        const node = itemUri(1);
        // the backlinks query names the node it asks about
        const counts = await refuseOnce(page, url => url.pathname.endsWith('/sparql')
            && (url.searchParams.get('query') ?? '').includes(`<${node}>`));

        await nodeEvent(page, 'ForceGraph3DNodeRightClick', canvasId, node);

        await expect.poll(() => loaded(page, canvasId, 'loaded-backlink-uris', node),
            { message: 'the backlinks never joined the graph', timeout: 30_000 }).toBe(true);
        expect(counts).toEqual({ refused: 1, sent: 1 });
        await expect(page.locator('.ldh-failure')).toHaveCount(0);
    });

    test('a node\'s document, on a double click', async ({ page }) => {
        const canvasId = await graphReady(page);
        const node = itemUri(1);
        const counts = await refuseOnce(page, url => `${url.origin}${url.pathname}` === node);

        await nodeEvent(page, 'ForceGraph3DNodeDblClick', canvasId, node);

        await expect.poll(() => loaded(page, canvasId, 'loaded-uris', node),
            { message: 'the node\'s document never joined the graph', timeout: 30_000 }).toBe(true);
        expect(counts).toEqual({ refused: 1, sent: 1 });
        await expect(page.locator('.ldh-failure')).toHaveCount(0);
    });
});
