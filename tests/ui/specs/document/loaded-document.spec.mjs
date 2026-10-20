// The document a pane shows, as it was loaded.
//
// The client loads every document it navigates to as RDF and keeps that copy: switching back to a tab
// shows the pane already rendered instead of fetching the document again, and the chart and query
// editors find the resource they rewrite in it. The copy used to sit in LinkedDataHub.contents; it is
// now in the SaxonJS document pool, under the href the load requested, which the pane carries as
// @data-href - a proxied document's href is built on the path of the page it was opened from, so it
// cannot be rebuilt later from the document URI.
//
// Each test is a path that reads the copy back: a pane that has one, a tab switch that relies on it,
// and a save that rewrites a resource found in it.
import { test, expect } from '../../lib/console.mjs';
import { goto } from '../../lib/settle.mjs';
import { fixtures, remoteDocument } from '../../lib/fixtures.mjs';
import { controlToggle } from '../../lib/block.mjs';
import { canvas, chartBlock, chartType } from '../../lib/chart.mjs';

const AC = 'https://w3id.org/atomgraph/client#';
const READ_MODE = `${AC}ReadMode`;

const activePane = page => page.locator('#tab-content div.ldh-pane.is-active');
const tab = (page, uri) => page.locator(`#tab-bar-list li[data-uri="${uri}"]`);

// the GETs of the given hrefs - the documents' own loads, which a tab switch must not repeat
function loadsOf(page, hrefs) {
    const loads = [];
    page.on('request', request => {
        if (request.method() === 'GET' && hrefs.includes(request.url())) loads.push(request.url());
    });
    return loads;
}

test.describe('the loaded document', { tag: '@owner' }, () => {
    test('a page that was opened carries the href its document was loaded by', async ({ page }) => {
        await goto(page, fixtures.container);

        await expect(activePane(page)).toHaveAttribute('data-href', fixtures.container, { timeout: 30_000 });
    });

    // Both tabs in ReadMode, the mode a remote document opens in: a tab whose link names another mode
    // than the page being left is navigated to and loaded again, by design, whatever the client holds.
    test('switching back to a tab shows its pane without loading the document again', async ({ page, allowNoise }) => {
        // ReadMode lists the container's query, and its editor brings the prefix.cc request with it
        allowNoise.push({
            pattern: /prefix\.cc/,
            reason: 'YASQE 2 fetches http://prefix.cc for prefix completion, blocked as mixed content (as in query.spec.mjs)',
        });
        await goto(page, `${fixtures.container}?mode=${encodeURIComponent(READ_MODE)}`);
        await expect(activePane(page)).toHaveAttribute('data-href', fixtures.container, { timeout: 30_000 });

        const remote = remoteDocument();
        await page.locator('form.ldh-address input#uri').fill(remote);
        await page.locator('form.ldh-address input#uri').press('Enter');
        await expect(tab(page, remote)).toHaveCount(1, { timeout: 30_000 });
        await expect(activePane(page).locator('div.document-body')).toHaveAttribute('about', remote, { timeout: 30_000 });
        // proxied: the href is this origin's, naming the remote document as ?uri=
        const remoteHref = await activePane(page).getAttribute('data-href');
        expect(new URL(remoteHref).searchParams.get('uri'), 'the remote document is loaded through the proxy').toBe(remote);

        const loads = loadsOf(page, [fixtures.container, remoteHref]);

        await tab(page, fixtures.container).locator('a').click();
        await expect(activePane(page).locator('div.document-body')).toHaveAttribute('about', fixtures.container);
        await tab(page, remote).locator('a').click();
        await expect(activePane(page).locator('div.document-body')).toHaveAttribute('about', remote);
        await expect(activePane(page)).toHaveAttribute('data-href', remoteHref);

        // the switches settle synchronously; anything they sent would have been issued by now
        await page.waitForTimeout(1_000);
        expect(loads, 'a tab switch loaded a document again').toEqual([]);
    });

    test('saving the chart controls rewrites the chart the document was loaded with', async ({ page }) => {
        await goto(page, fixtures.container);
        const block = chartBlock(page);
        await expect(canvas(block).locator('svg')).toBeVisible({ timeout: 30_000 });
        await controlToggle(block).click();
        await expect(chartType(block)).toHaveValue(`${AC}BarChart`);

        const save = async (block, type) => {
            await chartType(block).selectOption(type);
            const patch = page.waitForResponse(response => response.request().method() === 'PATCH'
                && new URL(response.url()).pathname === new URL(fixtures.container).pathname);
            await block.locator('button.btn-save-chart').click();
            expect((await patch).status(), `saving ${type}`).toBeLessThan(300);
        };

        try {
            await save(block, `${AC}LineChart`);

            await goto(page, fixtures.container);
            await controlToggle(chartBlock(page)).click();
            await expect(chartType(chartBlock(page)), 'the saved chart type is stored').toHaveValue(`${AC}LineChart`);
        } finally {
            await goto(page, fixtures.container);
            const restored = chartBlock(page);
            await expect(canvas(restored).locator('svg')).toBeVisible({ timeout: 30_000 });
            await controlToggle(restored).click();
            if (await chartType(restored).inputValue() !== `${AC}BarChart`) await save(restored, `${AC}BarChart`);
        }
    });
});
