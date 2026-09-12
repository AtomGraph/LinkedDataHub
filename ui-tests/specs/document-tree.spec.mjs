// The drawer's document tree: the lazy hierarchy, and the descent that opens the path to
// the document being read.
//
// The descent is the half that had no coverage and the most room to fail quietly. It used
// to load each level with its own copy of the shared fetch, and the copy had no loading
// row, no busy cursor and no failure handler - so a failed request during pre-expansion
// produced a branch that simply stayed shut, with nothing in the console. The two specs
// that hold the response back exist to assert the states that omission made unobservable.
import { test, expect } from '../lib/console.mjs';
import { goto, settled } from '../lib/settle.mjs';
import { fixtures, itemCount, itemTitle, itemUri } from '../lib/fixtures.mjs';
import { endUserBase } from '../lib/stack.mjs';

const tree = page => page.locator('div.document-tree');
const rowsFor = (page, uri) => tree(page).locator(`li:has(> div.tree-row > a[href="${uri}"])`);
const disclosureOf = (page, uri) => rowsFor(page, uri).locator('> div.tree-row > button');

// The drawer opens on a mousemove at the left edge of the viewport and closes when the
// pointer leaves it, so there is no button to press. clientX has to be exactly 0 - the
// handler tests `$x = 0`, not a threshold - and a move to x=2 leaves it shut with its
// subtree still in the DOM, which is how ad-hoc scripts came to assert against a hidden
// tree without noticing.
async function openDrawer(page) {
    await page.mouse.move(200, 600);
    await page.mouse.move(0, 620);
    await expect(tree(page)).toBeVisible();
}

function countChildrenQueries(page) {
    const counts = { n: 0 };
    page.on('response', response => {
        const url = decodeURIComponent(response.url());
        if (url.includes('/sparql?') && url.includes('has_parent')) counts.n++;
    });
    return counts;
}

// Holds every children query back, so the loading row and the busy cursor are observable
// instead of being raced past.
async function slowChildren(page, ms = 1500) {
    await page.route(
        url => url.href.includes('/sparql?') && decodeURIComponent(url.href).includes('has_parent'),
        async route => {
            await new Promise(resolve => setTimeout(resolve, ms));
            await route.continue();
        });
}

test.describe('document tree', () => {
    test.beforeEach(({}, testInfo) => {
        test.skip(testInfo.project.name !== 'owner',
            'the fixture container is owner-owned; these specs are not about authorization');
    });

    test('opens the path down to the document being read and marks it', async ({ page }) => {
        await goto(page, itemUri(1));
        await openDrawer(page);

        await expect(disclosureOf(page, fixtures.container)).toHaveAttribute('aria-expanded', 'true');
        await expect(rowsFor(page, itemUri(1))).toHaveClass(/is-active/);
        await expect(rowsFor(page, itemUri(1)).locator('> div.tree-row > a'))
            .toHaveAttribute('aria-current', 'page');
    });

    test('indents each level it opens', async ({ page }) => {
        await goto(page, itemUri(1));
        await openDrawer(page);
        await expect(rowsFor(page, itemUri(1))).toHaveClass(/is-active/);

        // --depth drives the indent ramp, and it is tunnelled through ldh:TreeNode for a
        // reason: a domain override delegating with xsl:next-match forwards only the
        // parameters it names, and a plain one arrived as 0, rendering every level flush.
        const depths = await tree(page).locator('li > div.tree-row').evaluateAll(rows => rows.map(row => ({
            depth: row.style.getPropertyValue('--depth'),
            nesting: (() => {
                let n = 0;
                for (let node = row.parentElement?.parentElement; node; node = node.parentElement) {
                    if (node.tagName === 'LI') n++;
                }
                return String(n);
            })(),
        })));
        expect(depths.length).toBeGreaterThan(2);
        expect(depths.filter(({ depth, nesting }) => depth !== nesting)).toEqual([]);
    });

    test('shows the loading row and the busy cursor while it walks', async ({ page }) => {
        await slowChildren(page);
        // The cursor is an inline style set for the duration of each fetch and reset after
        // it, so sampling it is a race against the gaps between levels. Recording every
        // transition is not: the assertion becomes "it was busy at some point", which is
        // what the claim actually is.
        await page.addInitScript(() => {
            window.__cursors = [];
            const record = () => window.__cursors.push(getComputedStyle(document.body).cursor);
            addEventListener('DOMContentLoaded', () => {
                record();
                new MutationObserver(record)
                    .observe(document.body, { attributes: true, attributeFilter: ['style'] });
            });
        });
        // Not goto(): the descent starts with the navigation and the point is to catch it
        // mid-flight, so this must not wait for the page to settle first.
        await page.goto(itemUri(1), { waitUntil: 'commit' });

        // Presence, not visibility - the drawer is closed at this moment, and the row is
        // what the descent put there either way.
        await expect(tree(page).locator('li.tree-loading')).not.toHaveCount(0);

        await settled(page);
        await openDrawer(page);
        await expect(rowsFor(page, itemUri(1))).toHaveClass(/is-active/);

        expect(await page.evaluate(() => window.__cursors),
            'the descent should have shown a busy cursor').toContain('progress');
        // ixsl:finally puts it back, which the hand-rolled copy never did.
        await expect(tree(page).locator('li.tree-loading')).toHaveCount(0);
        await expect.poll(() => page.evaluate(() => getComputedStyle(document.body).cursor))
            .toBe('default');
    });

    test('expands a node on click, and keeps its children when collapsed', async ({ page }) => {
        const queries = countChildrenQueries(page);
        await goto(page, endUserBase);
        await openDrawer(page);

        // On the root document the descent has nowhere to go - the target IS the root - so
        // nothing is pre-expanded and every level here is opened by a click.
        const root = disclosureOf(page, endUserBase);
        await expect(root).toHaveAttribute('aria-expanded', 'false');
        await root.click();
        await expect(rowsFor(page, fixtures.container)).toHaveCount(1);

        const disclosure = disclosureOf(page, fixtures.container);
        await expect(disclosure).toHaveAttribute('aria-expanded', 'false');
        await disclosure.click();

        await expect(rowsFor(page, itemUri(1))).toHaveCount(1);
        await expect(rowsFor(page, fixtures.container).locator('> ul > li')).toHaveCount(itemCount);
        await expect(rowsFor(page, itemUri(1))).toContainText(itemTitle(1));
        await expect(tree(page).locator('li.tree-loading')).toHaveCount(0);

        const loaded = queries.n;
        await disclosure.click();
        await expect(disclosure).toHaveAttribute('aria-expanded', 'false');
        await disclosure.click();
        await expect(disclosure).toHaveAttribute('aria-expanded', 'true');

        await expect(rowsFor(page, fixtures.container).locator('> ul > li')).toHaveCount(itemCount);
        expect(queries.n - loaded, 'the children stay in the DOM and are never refetched').toBe(0);
    });
});
