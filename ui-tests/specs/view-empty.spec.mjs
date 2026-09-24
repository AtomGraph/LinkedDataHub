// What a view declaring ldh:showWhenEmpty false does to the page on its way to being empty.
//
// The block is injected into the content flow before its query has run, so the emptiness it is
// hidden for is not yet known when it arrives. Deciding at insert time from the DECLARATION
// rather than at results time from the count is what keeps the card out of the layout: the
// results only ever bring it back.
//
// Measured at the DOM rather than by screenshot. A MutationObserver callback is delivered at the
// microtask checkpoint that follows the insertion and precedes any paint, so the display it reads
// IS the one the browser would first have rendered. The per-frame sampler beside it is the
// independent witness: it asks whether any frame of the whole load ever gave the block a box.
import { test, expect } from '../lib/console.mjs';
import { goto } from '../lib/settle.mjs';
import { concept, document as conceptDocument } from '../lib/taxonomy.mjs';
import { BROADER, NARROWER, rowFor, rows, viewBlock } from '../lib/blocks.mjs';

const READ_MODE = 'https://w3id.org/atomgraph/client#ReadMode';
const pageFor = name => `${conceptDocument(name)}?mode=${encodeURIComponent(READ_MODE)}`;

// Installed before any of the page's own script runs, so the first injected block is seen.
const watchInjectedViews = page => page.addInitScript(() => {
    const SELECTOR = 'div.block[data-show-when-empty]';
    const properties = block => block.getAttribute('data-property');

    window.__insertions = [];
    new MutationObserver(records => {
        for (const record of records) {
            for (const node of record.addedNodes) {
                if (!(node instanceof HTMLElement)) continue;
                const blocks = [...(node.matches(SELECTOR) ? [node] : []), ...node.querySelectorAll(SELECTOR)];
                for (const block of blocks) {
                    window.__insertions.push({
                        property: properties(block),
                        showWhenEmpty: block.getAttribute('data-show-when-empty'),
                        display: getComputedStyle(block).display,
                        height: block.offsetHeight,
                    });
                }
            }
        }
    // document, not documentElement: an init script runs before the document has one.
    }).observe(document, { childList: true, subtree: true });

    window.__tallest = {};
    const sample = () => {
        for (const block of document.querySelectorAll(SELECTOR)) {
            const property = properties(block);
            window.__tallest[property] = Math.max(window.__tallest[property] ?? 0, block.offsetHeight);
        }
        requestAnimationFrame(sample);
    };
    requestAnimationFrame(sample);
});

const insertionOf = (insertions, property) => insertions.find(insertion => insertion.property === property);

test.describe('a view declared not to show when empty', () => {
    // The declaration is the package's and the results are the query's, and neither depends on
    // who is reading - the same reasoning as concept-hierarchy, which covers these same blocks.
    test.beforeEach(async ({ page }, testInfo) => {
        test.skip(testInfo.project.name !== 'owner',
            'what the block declares and what its query returns are the same for either agent');
        await watchInjectedViews(page);
    });

    test('never takes a box in the flow while it is empty', async ({ page }) => {
        // espresso is a leaf: nothing is narrower than it. Its Broader view on the same page does
        // have a result, so a build that simply hid every declared view would not pass this.
        await goto(page, pageFor('espresso'));

        await expect(rowFor(viewBlock(page, BROADER), concept('coffee'))).toHaveCount(1);
        await expect(viewBlock(page, NARROWER)).toBeHidden();

        const insertions = await page.evaluate(() => window.__insertions);
        const narrower = insertionOf(insertions, NARROWER);

        // The block does arrive - this is about how it arrives, not about it being withheld.
        expect(narrower, `no ${NARROWER} block was injected at all`).toBeDefined();
        expect(narrower.showWhenEmpty).toBe('false');
        // The two ways of saying the same thing at the moment of insertion, before any paint.
        expect(narrower.display).toBe('none');
        expect(narrower.height).toBe(0);

        // And no frame of the load ever gave it one, which is the flash itself.
        const tallest = await page.evaluate(() => window.__tallest);
        expect(tallest[NARROWER]).toBe(0);
        // The control: the view with a result did take a box.
        expect(tallest[BROADER]).toBeGreaterThan(0);
    });

    test('is shown once its results say it has something to show', async ({ page }) => {
        // hot-drinks has two children, so the same block that stays hidden above has to come back
        // here - the hide is only correct while the reveal that answers it still fires.
        await goto(page, pageFor('hot-drinks'));

        const narrower = viewBlock(page, NARROWER);
        await expect(narrower).toBeVisible();
        await expect(rows(narrower)).toHaveCount(2);

        // It was hidden on arrival here too: the reveal is what made it visible, not a different
        // insertion path.
        const insertions = await page.evaluate(() => window.__insertions);
        expect(insertionOf(insertions, NARROWER).display).toBe('none');
    });
});
