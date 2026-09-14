// The design system's responsive axis.
//
// Two of these assertions are the reason the spec exists, because a viewport-only fix would
// pass every other assertion here and still leave the product broken:
//
//   - THE CONTAINER ASSERTION. The same .ldh-prop-group renders at the document's full width,
//     inside a nested block, inside the 300px content aside and inside a 372px modal body -
//     four widths at ONE viewport. Measured before the fix, the 300px aside at a 1440px
//     desktop gave the value column 36px, which is WORSE than the 390px phone's 26px. A
//     media query cannot reach that, so the spec clones the component into a narrow box at a
//     desktop viewport and asserts it collapsed. Only a container query passes.
//   - THE DESKTOP SNAPSHOT. The scope was "readable, not redesigned". A responsive layer that
//     quietly restyles 1440px has exceeded it, and nothing else here would notice.
//
// The page-overflow assertion needs its own note. `html { overflow-x: clip }` (ldh.css)
// propagates to the viewport as `hidden`, so an overflowing page shows NO scrollbar and
// refuses a touch pan - scrollWidth is the only thing that still reports the truth, and the
// content past the edge is unreachable rather than merely awkward. Asserting "no horizontal
// scrollbar" would therefore have passed throughout.
import { test, expect } from '../lib/console.mjs';
import { goto } from '../lib/settle.mjs';
import { fixtures, itemUri } from '../lib/fixtures.mjs';

const PHONE = { width: 390, height: 844 };
const TABLET = { width: 768, height: 1024 };
const DESKTOP = { width: 1440, height: 1000 };

// The widths real containers hand these components at a desktop viewport: the content aside's
// gutter, and a sz-sm modal body once its padding is taken off.
const ASIDE = 300;
const MODAL_BODY = 372;

// Readability floors, and where they come from. The statement grid spends 200px on the label
// and 64px on the row actions, so a three-column layout needs ~504px before the value - the
// data - is readable at all; below that the grid has to stop being three columns. 240px is the
// value's share of that budget.
const READABLE_VALUE = 240;
const ADDRESS_MIN = 160;

// The fixture container is owner-owned; an anonymous context gets an error page whose
// selectors are not the ones under test.
test.beforeEach(({}, testInfo) => {
    test.skip(testInfo.project.name !== 'owner', 'the fixture container is owner-owned');
});

// Computed grid tracks as numbers. getComputedStyle resolves grid-template-columns to used pixel
// values, so this reports what the browser actually laid out rather than what the stylesheet asked
// for - which is the whole point: `200px 1fr 64px` looks fine in source and computes to
// `200px 26px 64px` on a phone.
//
// Zero-width tracks are dropped. `repeat(auto-fit, …)` generates as many tracks as the width
// allows and collapses the ones no item landed in - at 1440px the chart controls report
// `367px 367px 367px 0px 0px 0px`. A collapsed track takes no space and neither do its gaps, so
// counting the raw list would report six columns where three are drawn.
async function tracks(page, selector) {
    return page.evaluate((sel) => {
        const el = document.querySelector(sel);
        if (!el) return null;
        return getComputedStyle(el).gridTemplateColumns.split(/\s+/).map(parseFloat).filter(w => w > 0);
    }, selector);
}

// Clone a live component into a box of a given width and report how it lays out there. The
// clone is measured off-screen but IN the document, so it inherits the real cascade - a
// hand-written fixture would only prove that the fixture's own markup works.
async function tracksInBox(page, selector, width) {
    return page.evaluate(([sel, w]) => {
        const source = document.querySelector(sel);
        if (!source) return null;
        const host = document.createElement('div');
        // container-type mirrors what the block surfaces declare, so the clone is queried the
        // same way the original is. left:-9999px keeps it out of view without display:none,
        // which would collapse the layout being measured.
        host.style.cssText = `position:absolute;left:-9999px;top:0;width:${w}px;container-type:inline-size;`;
        const clone = source.cloneNode(true);
        host.appendChild(clone);
        document.body.appendChild(host);
        const out = getComputedStyle(clone).gridTemplateColumns.split(/\s+/).map(parseFloat).filter(t => t > 0);
        host.remove();
        return out;
    }, [selector, width]);
}

const overflow = page => page.evaluate(() => ({
    scrollWidth: document.documentElement.scrollWidth,
    innerWidth: window.innerWidth,
}));

for (const [name, viewport] of [['phone', PHONE], ['tablet', TABLET]]) {
    test.describe(`${name} (${viewport.width}px)`, () => {
        test.use({ viewport });

        test('no document overflows the viewport', async ({ page }) => {
            for (const url of [fixtures.container, itemUri(1)]) {
                await goto(page, url);
                const { scrollWidth, innerWidth } = await overflow(page);
                // A pixel of slack for subpixel rounding; the regression this guards was 226px.
                expect(scrollWidth, `${url} overflows by ${scrollWidth - innerWidth}px`)
                    .toBeLessThanOrEqual(innerWidth + 1);
            }
        });

        test('the address bar keeps a usable share of the header', async ({ page }) => {
            await goto(page, fixtures.container);
            const header = await tracks(page, '.ldh-header');
            expect(header, '.ldh-header is not a grid').not.toBeNull();
            // Track 2 is the address bar, between the wordmark and the header actions.
            expect(header[1]).toBeGreaterThanOrEqual(ADDRESS_MIN);
        });

        test('the dataspace tab strip stays inside its own box', async ({ page }) => {
            await goto(page, fixtures.container);
            const strip = await page.evaluate(() => {
                const el = document.querySelector('.ldh-tabs');
                if (!el) return null;
                return { scrollWidth: el.scrollWidth, clientWidth: el.clientWidth,
                         overflowX: getComputedStyle(el).overflowX };
            });
            test.skip(strip === null, 'no tab strip on this page');
            // Either it fits or it scrolls. What it must not do is push the page wider, which
            // is what it did with neither flex-wrap nor a scrollport - and the kit's own
            // .ac-tablist has solved this with overflow-x since before the strip existed.
            if (strip.scrollWidth > strip.clientWidth + 1) {
                expect(['auto', 'scroll']).toContain(strip.overflowX);
            }
        });
    });
}

test.describe('phone (390px) — content components', () => {
    test.use({ viewport: PHONE });

    test('the statement grid gives the value room to be read', async ({ page }) => {
        await goto(page, itemUri(1));
        const group = await tracks(page, '.ldh-prop-group');
        expect(group, 'no .ldh-prop-group on the item document').not.toBeNull();
        // Collapsed, the label is no longer a track of its own, so the value is track 1.
        expect(group.length, 'the three-column grid did not collapse').toBeLessThan(3);
        expect(group[0]).toBeGreaterThanOrEqual(READABLE_VALUE);
    });

    test('the chart controls stack instead of sharing 70px each', async ({ page }) => {
        await goto(page, fixtures.container);
        const controls = await tracks(page, '.chart-controls');
        test.skip(controls === null, 'no chart block on this page');
        expect(controls.length).toBe(1);
    });
});

test.describe('desktop (1440px)', () => {
    test.use({ viewport: DESKTOP });

    // The assertion a media-query-only implementation fails.
    test('narrow containers collapse even at a wide viewport', async ({ page }) => {
        await goto(page, itemUri(1));

        for (const width of [ASIDE, MODAL_BODY]) {
            const group = await tracksInBox(page, '.ldh-prop-group', width);
            expect(group, 'no .ldh-prop-group to clone').not.toBeNull();
            expect(group.length, `.ldh-prop-group stayed three columns in a ${width}px container`)
                .toBeLessThan(3);
            expect(group[0], `.ldh-prop-group value column is ${group[0]}px in a ${width}px container`)
                .toBeGreaterThan(width / 2);
        }

        await goto(page, fixtures.container);
        const controls = await tracksInBox(page, '.chart-controls', ASIDE);
        test.skip(controls === null, 'no chart block on this page');
        expect(controls.length, `.chart-controls stayed ${controls.length} columns in a ${ASIDE}px container`)
            .toBe(1);
    });

    // The scope was "readable, not redesigned": desktop must not move.
    test('desktop layout is unchanged', async ({ page }) => {
        await goto(page, itemUri(1));
        const group = await tracks(page, '.ldh-prop-group');
        expect(group).not.toBeNull();
        expect(group.length).toBe(3);
        expect(group[0]).toBe(200);
        expect(group[2]).toBe(64);

        await goto(page, fixtures.container);
        const { scrollWidth, innerWidth } = await overflow(page);
        expect(scrollWidth).toBeLessThanOrEqual(innerWidth + 1);

        const controls = await tracks(page, '.chart-controls');
        test.skip(controls === null, 'no chart block on this page');
        expect(controls.length).toBe(3);
    });
});
