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
//
// THREE THINGS THIS SPEC LEARNED ON ITS FIRST CI RUN, having shipped unexecuted:
//
//   1. ONE NAVIGATION PER TEST. A test that visits two documents on one page aborts the
//      first one's in-flight SPARQL when it navigates; Saxon-JS reports that as
//      alert("HTTP request failed: ... (Failed to fetch)"), and lib/console.mjs fails the
//      test in teardown - after the assertion itself had passed. Being a race, it failed
//      intermittently. Each document gets its own test, and so its own page.
//   2. THE STATEMENT GRID LIVES ON THE FIXTURE CONTAINER. /ui-fixtures/item-01/ renders no
//      blocks and no dl.ldh-prop-form at all, while /ui-fixtures/ renders several -
//      calibration.spec.mjs prints the anatomy of both, which is how this was found.
//      Asserting against the item document gave three tests that could only fail on a null.
//   3. NEVER test.skip() ON A MISSING SELECTOR. The chart assertion did, and went green
//      while testing nothing - hiding that `repeat(auto-fit, ...)`, half the responsive
//      change, had no coverage at all. The controls were missing for a structural reason
//      rather than a slow one: a ldh:ResultSetChart is data until something puts it in the
//      document's rdf:_N list, so the fixture's chart rendered nowhere and no amount of
//      waiting would have produced it (lib/fixtures.mjs now wraps it in an Object, which is
//      how a chart becomes content). A missing component should fail the build rather than
//      quietly shrink it, so this is an auto-retrying expect() now.
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

// The documents worth measuring for page-level overflow. Thunks, because fixtures.container
// and itemUri() read module state that globalSetup populates.
const DOCUMENTS = [
    ['the fixture container', () => fixtures.container],
    ['a fixture item', () => itemUri(1)],
];

// The fixture container is owner-owned; an anonymous context gets an error page whose
// selectors are not the ones under test.
test.beforeEach(({}, testInfo) => {
    test.skip(testInfo.project.name !== 'owner', 'the fixture container is owner-owned');
});

// Wait for a component to exist before measuring it, and fail loudly naming it when it never
// does. Prefer this to a fixed delay: the statement grid is server-rendered, but the chart's
// controls are re-rendered client-side once its SPARQL results arrive, and settled() cannot see
// that moment because the block count does not change while it happens.
async function present(page, selector, timeout = 30_000) {
    await expect(page.locator(selector).first(), `${selector} never rendered`)
        .toBeVisible({ timeout });
}

// A block keeps its control chrome collapsed until the header's tune button is pressed, so a
// measurement of .chart-controls has to ask for it first. Every block, not one: these assertions
// measure whichever grid is widest or fits a given box, and deciding which block that is belongs
// to the assertion rather than to this helper.
//
// Two things make this more than a click, and both were found by a CI failure that ran green on
// every laptop:
//
//   - THE BANDS HAVE TO EXIST FIRST. The toggle is in the server's first paint but a view's bars
//     are rendered client-side, and the handler is explicitly a no-op while they are missing
//     (client/block.xsl). A click that lands early does nothing and is not replayed, so waiting on
//     the button is not enough - the wait is for a band. settled() cannot stand in: its signal is
//     the .ldh-block-row count, which on a slow machine goes quiet BETWEEN injections. Throttling
//     the CPU 10x reproduces the whole failure, down to ".chart-controls never rendered" 30s later
//     against a grid nothing had revealed.
//   - IT IS A TOGGLE, NOT A REVEAL. It reads its state off the block's first band and drives every
//     band under that block to match, so pressing it twice puts the chrome back. Each block is
//     therefore pressed only while its own first band still reads collapsed, which is also what
//     makes repeating the pass safe: an expanded block is never pressed a second time. Repeating is
//     what covers the blocks that arrive AFTER the first band does - waiting for one band says the
//     page has begun rendering chrome, not that it has finished, and under a 10x throttle the
//     fixture container was still two blocks short at that moment.
const TOGGLE = '.ldh-block-head .tb-controls';
const BANDS = '.chart-controls, .ldh-view-toolbar, .ldh-pivot-bar';
const COLLAPSED_BANDS = '.chart-controls.is-collapsed, .ldh-view-toolbar.is-collapsed, .ldh-pivot-bar.is-collapsed';

async function revealControls(page, timeout = 30_000) {
    // attached, not visible: a collapsed band is hidden, which is the state being waited for
    await expect(page.locator(BANDS).first(), 'no block control band ever rendered')
        .toBeAttached({ timeout });
    await expect(page.locator(TOGGLE).first(), 'no block control toggle ever rendered')
        .toBeAttached({ timeout });

    const collapsed = page.locator(COLLAPSED_BANDS);
    const deadline = Date.now() + timeout;
    do {
        for (const toggle of await page.locator(TOGGLE).all()) {
            // the handler drives the bands under the button's nearest block ancestor, and reads the
            // state it is flipping off the first of them. The class is matched as a TOKEN, the way
            // contains-token() does in the stylesheet: a substring test lands on .ldh-block-head,
            // the button's own wrapper, which holds no bands at all.
            const first = toggle.locator('xpath=ancestor::div[contains(concat(" ", normalize-space(@class), " "), " block ")][1]')
                .locator(BANDS).first();
            if (await first.count() === 0) continue;
            if (((await first.getAttribute('class')) ?? '').includes('is-collapsed')) await toggle.click();
        }
        if (await collapsed.count() === 0) break;
        await page.waitForTimeout(250);
    } while (Date.now() < deadline);

    await expect(collapsed, 'a block band stayed collapsed after its toggle was pressed')
        .toHaveCount(0);
}

// Every match of a selector, with its used track sizes and its box width.
//
// Zero-width tracks are dropped. `repeat(auto-fit, ...)` generates as many tracks as the width
// allows and collapses the ones no item landed in - at 1440px the chart controls report
// `367px 367px 367px 0px 0px 0px`. A collapsed track takes no space and neither do its gaps, so
// counting the raw list would report six columns where three are drawn.
//
// ALL matches, not the first: the fixture container holds several statement grids, and document
// order says nothing about how wide any of them is. A grid nested inside a narrow block is
// legitimately collapsed at a desktop viewport - that is the whole point of the axis - so
// pinning querySelector() would make the desktop assertion depend on which one came first.
async function measureAll(page, selector) {
    return page.evaluate((sel) => [...document.querySelectorAll(sel)].map(el => ({
        width: Math.round(el.getBoundingClientRect().width),
        tracks: getComputedStyle(el).gridTemplateColumns.split(/\s+/).map(parseFloat).filter(t => t > 0),
    })), selector);
}

// The widest match — the one laid out in the document column rather than in some inner well.
const widest = list => list.reduce((a, b) => (b.width > a.width ? b : a));

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

        // One document per test — see note 1 at the top of the file.
        for (const [label, url] of DOCUMENTS) {
            test(`${label} does not overflow the viewport`, async ({ page }) => {
                await goto(page, url());
                const { scrollWidth, innerWidth } = await overflow(page);
                // A pixel of slack for subpixel rounding; the regression this guards was 226px.
                expect(scrollWidth, `overflows by ${scrollWidth - innerWidth}px`)
                    .toBeLessThanOrEqual(innerWidth + 1);
            });
        }

        test('the address bar keeps a usable share of the header', async ({ page }) => {
            await goto(page, fixtures.container);
            // The bar's own box, not the header's middle grid track. measureAll() drops
            // zero-width tracks (it has to, for auto-fit), so track indices shift the moment
            // any track collapses - and a collapsed wordmark would silently move the address
            // bar to index 0 and measure the wrong thing.
            const width = await page.evaluate(() => {
                const el = document.querySelector('.ldh-header .ldh-address');
                return el ? Math.round(el.getBoundingClientRect().width) : null;
            });
            expect(width, 'no .ldh-address in the header').not.toBeNull();
            expect(width, `the address bar is ${width}px`).toBeGreaterThanOrEqual(ADDRESS_MIN);
        });

        test('the dataspace tab strip stays inside its own box', async ({ page }) => {
            await goto(page, fixtures.container);
            const strip = await page.evaluate(() => {
                const el = document.querySelector('.ldh-tabs');
                if (!el) return null;
                return { scrollWidth: el.scrollWidth, clientWidth: el.clientWidth,
                         overflowX: getComputedStyle(el).overflowX };
            });
            expect(strip, 'no .ldh-tabs on the page').not.toBeNull();
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
        await goto(page, fixtures.container);
        await present(page, '.ldh-prop-group');

        const group = widest(await measureAll(page, '.ldh-prop-group'));
        // Collapsed, the label is no longer a track of its own, so the value is track 1.
        expect(group.tracks.length, `the three-column grid did not collapse in ${group.width}px`)
            .toBeLessThan(3);
        expect(group.tracks[0]).toBeGreaterThanOrEqual(READABLE_VALUE);
    });

    test('the chart controls stack instead of sharing 70px each', async ({ page }) => {
        await goto(page, fixtures.container);
        // ldh:ChartControls re-renders these once the block's SPARQL results land.
        await revealControls(page);
        await present(page, '.chart-controls');

        const controls = widest(await measureAll(page, '.chart-controls'));
        expect(controls.tracks.length, `${controls.width}px held ${controls.tracks.length} columns`)
            .toBe(1);
    });
});

test.describe('desktop (1440px)', () => {
    test.use({ viewport: DESKTOP });

    // The assertion a media-query-only implementation fails.
    test('narrow containers collapse even at a wide viewport', async ({ page }) => {
        await goto(page, fixtures.container);
        await present(page, '.ldh-prop-group');

        for (const width of [ASIDE, MODAL_BODY]) {
            const group = await tracksInBox(page, '.ldh-prop-group', width);
            expect(group, 'no .ldh-prop-group to clone').not.toBeNull();
            expect(group.length, `.ldh-prop-group stayed three columns in a ${width}px container`)
                .toBeLessThan(3);
            expect(group[0], `.ldh-prop-group value column is ${group[0]}px in a ${width}px container`)
                .toBeGreaterThan(width / 2);
        }

        await revealControls(page);
        await present(page, '.chart-controls');
        const controls = await tracksInBox(page, '.chart-controls', ASIDE);
        expect(controls.length, `.chart-controls stayed ${controls.length} columns in a ${ASIDE}px container`)
            .toBe(1);
    });

    // The scope was "readable, not redesigned": desktop must not move.
    test('desktop layout is unchanged', async ({ page }) => {
        await goto(page, fixtures.container);
        await present(page, '.ldh-prop-group');

        // At least one grid is laid out in the document column, still three columns on the
        // original tracks. Others are legitimately collapsed — a grid inside a narrow block is
        // exactly what the container query is for, so "every one of them" would be wrong.
        const groups = await measureAll(page, '.ldh-prop-group');
        const full = groups.filter(g => g.tracks.length === 3 && g.tracks[0] === 200 && g.tracks[2] === 64);
        expect(full.length, `no three-column .ldh-prop-group at 1440px; measured ${JSON.stringify(groups)}`)
            .toBeGreaterThan(0);

        const { scrollWidth, innerWidth } = await overflow(page);
        expect(scrollWidth).toBeLessThanOrEqual(innerWidth + 1);

        await revealControls(page);
        await present(page, '.chart-controls');
        const controls = widest(await measureAll(page, '.chart-controls'));
        expect(controls.tracks.length, `${controls.width}px held ${controls.tracks.length} columns`)
            .toBe(3);
    });
});
