// A paged view's rows stay inside the block that frames them.
//
// The design system caps a paged view's body at min(70vh, 620px) and hands the scroll box to
// its direct `.ldh-grid-block` / `.ldh-list-block` child (app.css, PAGED VIEW). LDH never has
// that child: ldh:GridViewBlock and ldh:ListViewBlock both render one level down, inside
// `.container-results`, so the cap has only ever been survivable because that wrapper is
// itself a scroll container and shrinks under it. Grid mode turns the wrapper's scrollport
// off (ldh.css) - the card draws its border as an outside box-shadow, and any clip box cuts
// the card edges - and the cap has to come off with it.
//
// It did not, and the failure was silent in the worst way: a flex item with overflow visible
// has a content-sized automatic minimum, so it neither shrinks nor scrolls. There is no
// scrollbar and no clipping to notice - the rows simply leave the block. Run against the
// pre-fix stylesheet this spec measures a 620px body ending at y=734 with its results region
// ending at y=1299: 565px of cards outside the block, painting over the pager, the create
// dock and the page footer; and because `.ldh-block-row` is positioned, over the next content
// block too, which is how a paragraph of prose came to be reported sitting inside a card.
//
// So the assertion is geometric rather than stylistic. A `max-height` or an `overflow` value
// is one way to satisfy the invariant and not the only one, and asserting the declaration
// would have to be rewritten by whoever finds a better way. What has to hold is that the
// results region ends inside the body that frames it - in EVERY mode that pages, because
// list and table are the controls that say the cap itself is not what broke.
//
// Both halves are asserted. The containment is where the defect is; the footer is what a
// reader saw. A fix that contained the rows but left the page's own height wrong would pass
// the first and fail the second.
import { test, expect } from '../../../../lib/console.mjs';
import { goto } from '../../../../lib/settle.mjs';
import { fixtures } from '../../../../lib/fixtures.mjs';
import { blockOf, controlToggle } from '../../../../lib/block.mjs';

// The rows each mode renders, and the button that switches to it. The fixture container
// seeds 25 items against a 20-row page, so every one of these pages - which is what puts a
// non-empty pager in the body and brings the cap into scope at all.
const MODES = [
    { name: 'list', button: 'list-mode', rows: 'ul.ldh-list-block' },
    { name: 'table', button: 'table-mode', rows: 'table.ac-table' },
    { name: 'grid', button: 'grid-mode', rows: 'ul.ldh-grid-block' },
];

// The body the cap is scoped to, addressed exactly as the rule addresses it. Self-addressing
// on purpose: the spec needs no fixture-specific locator, and it covers whatever paged views
// the document renders rather than one the author happened to name.
const pagedBody = page => page.locator('.ldh-block-body:has(> .ldh-pager:not(:empty))').first();

// Document coordinates, not viewport ones. The overflow runs past the fold by design, so the
// numbers that matter are only comparable once scroll is added back in.
const geometry = (page, rowSelector) => page.evaluate(selector => {
    const bottom = element => {
        const box = element.getBoundingClientRect();
        return { top: box.top + scrollY, bottom: box.bottom + scrollY };
    };
    const body = document.querySelector('.ldh-block-body:has(> .ldh-pager:not(:empty))');
    const results = body.querySelector('.container-results');
    return {
        body: bottom(body),
        results: { ...bottom(results), overflowY: getComputedStyle(results).overflowY },
        rows: bottom(body.querySelector(selector)),
        footer: bottom(document.querySelector('.ldh-footer')),
    };
}, rowSelector);

// A layout measurement, not an authorization one: the geometry is the same whichever agent
// reads the page. What differs anonymously is only whether the fixture is readable at all, and
// on a virgin instance nothing is - the shipped acl/authorizations/public/ grants no
// accessTo/accessToClass until something fills it in, which is why CI's anonymous project sees
// a 403 error page here while a dev instance that has run http-tests does not.
test.beforeEach(({}, testInfo) => {
    test.skip(testInfo.project.name !== 'owner',
        'a layout assertion; the authorization axis would measure the same thing twice');
});

for (const mode of MODES) {
    test(`a paged view in ${mode.name} mode keeps its rows inside the block`, { tag: '@owner' }, async ({ page }) => {
        await goto(page, fixtures.container);

        const body = pagedBody(page);
        await expect(body).toBeVisible();

        // The mode switcher lives in the view toolbar, which the block now keeps collapsed
        // until the header's tune button is pressed. Resolved off the body rather than off the
        // page so it is the toggle of THIS block, keeping the spec self-addressing.
        await controlToggle(blockOf(body)).click();

        // The switcher is a popover: the mode buttons are in the DOM from the first render
        // and are not clickable until it is open, so this is two clicks rather than one.
        await body.locator('button#view-modes').click();
        await body.locator(`button.${mode.button}`).click();
        await expect(body.locator(mode.rows)).toBeVisible();

        const { body: frame, results, rows, footer } = await geometry(page, mode.rows);

        // Sub-pixel throughout: the block body's own bottom padding is fractional, and the
        // rows land on it exactly in the modes that already shrink.
        expect(results.bottom).toBeLessThanOrEqual(frame.bottom + 1);
        // A results region that scrolls is doing its job when the rows run past it - that is
        // what list and table have always done, and asserting otherwise fails them for being
        // correct. One that does NOT scroll has to contain them itself, which is the whole of
        // grid mode's contract. Read which it is off the region rather than hardcoding the
        // modes, so the day a mode changes its mind the assertion follows it.
        if (results.overflowY === 'visible') {
            expect(rows.bottom).toBeLessThanOrEqual(results.bottom + 1);
        }
        // The page must have grown to hold the block, not merely clipped it: the footer is
        // the first thing after the document body, and it starts below the results.
        expect(footer.top).toBeGreaterThanOrEqual(results.bottom);
    });
}
