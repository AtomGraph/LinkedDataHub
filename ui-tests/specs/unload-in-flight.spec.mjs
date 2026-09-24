// A request cancelled by leaving the page is not a failure.
//
// It reported as one. Pressing F5 while a block chain still had a request in flight made the
// browser cancel that fetch, which rejects with a plain TypeError ("NetworkError when attempting
// to fetch resource." in Firefox, "Failed to fetch" in Chromium). SaxonJS wraps it as SXJS0009
// "HTTP request failed: …", and ldh:promise-failure read SXJS0009 as a request that did not
// complete - which it is - and painted "Failed to load block data" into the document the reader
// had already left. The old document stays on screen until the new one arrives, so the alert
// flashed and vanished, about one refresh in fifteen: whenever a chain was still in flight.
//
// The function already knew one way a request is superseded, its own abort controller, and said
// nothing for it. Now it knows the other: beforeunload raises LinkedDataHub.unloading, and a
// rejection arriving after that reports nothing.
//
// Driven from inside the page. Playwright's page.reload() tears the document down before the
// rejections run and never shows it; location.reload() is what F5 does, and does. Every block
// request is held open so the reload is certain to land while one is in flight, and what the OLD
// document paints is recorded through a binding, because anything kept on its window dies with it.
import { test, expect } from '../lib/console.mjs';
import { goto, hydrated } from '../lib/settle.mjs';
import { document } from '../lib/taxonomy.mjs';

const READ_MODE = 'https://w3id.org/atomgraph/client#ReadMode';
const pageFor = name => `${document(name)}?mode=${encodeURIComponent(READ_MODE)}`;

test.describe('leaving the page mid-flight', () => {
    test.beforeEach(({}, testInfo) => {
        test.skip(testInfo.project.name !== 'owner', 'a concept page is not readable anonymously');
    });

    test('paints no failure into the document being left', async ({ page }) => {
        const painted = [];
        await page.exposeBinding('__failurePainted', (_, text) => painted.push(text));
        await page.addInitScript(() => {
            const report = el => window.__failurePainted(el.innerText);
            new MutationObserver(mutations => {
                for (const mutation of mutations) for (const node of mutation.addedNodes) {
                    if (node.nodeType !== 1) continue;
                    if (node.matches('.ldh-failure')) report(node);
                    node.querySelectorAll('.ldh-failure').forEach(report);
                }
            }).observe(document, { childList: true, subtree: true });
        });

        // The view fan-outs, the object metadata lookups and the tree's hierarchy queries all go
        // through one of these two; holding them guarantees an in-flight chain at the reload.
        let held = 0;
        await page.route(/\/(sparql|ns)(\?|$)/, async route => {
            held++;
            await new Promise(resolve => setTimeout(resolve, 5000));
            await route.continue().catch(() => {});
        });

        await page.goto(pageFor('espresso'), { waitUntil: 'domcontentloaded' });
        await hydrated(page);
        await expect.poll(() => held).toBeGreaterThan(0);

        await page.evaluate(() => location.reload());
        await page.waitForLoadState('domcontentloaded');
        await hydrated(page);
        await page.waitForTimeout(2000);

        expect(painted, 'a request the reload cancelled is not a failure to report').toEqual([]);
    });

    // The same rejection with the page staying put is a failure, and has to keep reporting: the flag
    // is raised by beforeunload alone, so a fetch the network drops rejects the same way and reports
    // the same way it did before.
    test('still reports a request that fails while the page stays', async ({ page, allowNoise }) => {
        allowNoise.push({
            pattern: /console\.error: Failed to load resource.*(ERR_FAILED|NetworkError)/i,
            reason: 'the browser logs the request this spec drops on purpose',
        });

        // The view lookup of a resource block, dropped at the network: one per block, so one failure
        // per block reports. The lookup is the GET; the POSTs to the same path are the document chain's
        // metadata lookups, and dropping those would fail the document instead of its blocks.
        await page.route(/\/ns\?query=/, route =>
            route.request().method() === 'GET' ? route.abort('failed') : route.continue());

        await goto(page, pageFor('espresso'));

        const failure = page.locator('.content-body > .ldh-failure').first();
        await expect(failure).toContainText('The request did not complete.');
    });
});
