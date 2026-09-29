// The code block: a `pre` and the control that copies it.
//
// One emitter (`ldh:CodeBlock`, imports/default.xsl) with three hosts and no home of its own -
// prose written as an XMLLiteral, the text of a stored query, the technical detail of an error -
// which is the same reason the dropdown menu is asserted here rather than under any one of the
// places it appears.
//
// The hosts are not equally testable, and the difference is worth stating rather than working
// around. Prose is stable: what the stylesheet emits is what stays on the page. A stored query's
// `sp:text` never reaches the reader as a `pre` at all - measured 2026-09-28 on the fixture query
// document, which settles with no `pre`, no wrapper and no `sp:text` cell in the DOM, because
// client/block/query.xsl's ldh:RowHook takes that row over and puts the folded editor and the
// result table there instead. The `pre` exists only in the tree the hook inspects on its way past,
// which is exactly why the hook's match predicate had to learn to read it through the wrapper -
// and document/blocks/query's three live tests go red the moment it stops matching.
//
// Two claims here are about the control rather than the markup:
//
//   · IT COPIES THE SAMPLE, NOT THE BLOCK. The prose block carries a Copy URI button of its own,
//     three inches away and doing something else entirely; the handlers share only the flash that
//     follows. A control that resolved its source the way its neighbour does would look right in
//     every screenshot and put a URI on the clipboard. Asserting the newline is what makes this a
//     copy of the sample rather than of something that merely starts like it.
//   · IT STAYS OUT OF THE READING LINE. `is-reveal` is opacity, never display, so the control
//     keeps its footprint and the prose does not reflow when a reader's pointer crosses it.
import { test, expect } from '../../lib/console.mjs';
import { goto } from '../../lib/settle.mjs';
import { fixtures, proseSample } from '../../lib/fixtures.mjs';
import { endUserBase } from '../../lib/stack.mjs';

const prose = page => page.locator('.block.ldh-block:has([typeof$="#XHTML"])').first();
const codeBlock = page => prose(page).locator('div.ldh-code-block').first();
const copyButton = block => block.locator('button.btn-copy-code');
const glyph = button => button.locator('span.msi').first();

// The clipboard is a permission, and Chromium grants it per origin. Granted before anything is
// pressed, not before it is read: `writeText` is what the button calls, and an ungranted one throws
// inside the handler - which the page reports as a pageerror and lib/console.mjs fails the test on,
// so the denial shows up as a broken control rather than as a missing permission.
const readClipboard = page => page.evaluate(() => navigator.clipboard.readText());

test.beforeEach(async ({ page }) => {
    await page.context().grantPermissions(['clipboard-read', 'clipboard-write'], { origin: endUserBase });
});

test('puts the sample in a wrapper of its own, with the control beside it', async ({ page }) => {
    await goto(page, fixtures.container);

    // The anatomy, in the order it has to be: the wrapper holds the `pre` and the button as
    // siblings. The button cannot live inside the `pre` - preformatted text would take its glyph
    // into the copy - and cannot live outside the wrapper, which is the only positioned ancestor
    // that does not scroll with the code.
    await expect(codeBlock(page)).toBeVisible();
    await expect(codeBlock(page).locator('> pre')).toHaveText(proseSample);
    await expect(copyButton(codeBlock(page))).toBeAttached();
    await expect(glyph(copyButton(codeBlock(page)))).toHaveText('content_copy');

    // Not the block's Copy URI, which is a different control in a different place.
    await expect(copyButton(codeBlock(page))).not.toHaveClass(/btn-copy-uri/);
    await expect(prose(page).locator('.ldh-block-corner button.btn-copy-uri')).toBeAttached();
});

test('no pre the page shows is left without one', async ({ page }) => {
    await goto(page, fixtures.container);

    // The claim the emitter exists to make, asserted over the page rather than over the one
    // sample: a `pre` reaching the reader outside a wrapper is a `pre` with no way to be copied.
    const stray = await page.locator('pre').evaluateAll(nodes =>
        nodes.filter(pre => !pre.parentElement?.classList.contains('ldh-code-block'))
            .map(pre => pre.outerHTML.slice(0, 120)));
    expect(stray, 'a pre rendered outside ldh:CodeBlock').toEqual([]);
});

test('stays out of the reading line until the block is hovered', async ({ page }) => {
    await goto(page, fixtures.container);

    const button = copyButton(codeBlock(page));
    const opacity = () => button.evaluate(node => getComputedStyle(node).opacity);

    expect(await opacity(), 'the control was visible over the prose at rest').toBe('0');

    await codeBlock(page).hover();
    await expect.poll(opacity, { message: 'hovering the block did not reveal the control' }).toBe('1');

    // Opacity, not display: the control held its place, so the prose never reflowed under the
    // pointer. A zero-size box here would mean it had been mounted on hover instead.
    const box = await button.boundingBox();
    expect(box.width).toBeGreaterThan(0);
});

test('copies the sample, newline and all - not the block it sits in', async ({ page }) => {
    await goto(page, fixtures.container);

    await copyButton(codeBlock(page)).click();

    const copied = await readClipboard(page);
    expect(copied).toBe(proseSample);
    expect(copied, 'the control copied its neighbour\'s URI instead of the sample')
        .not.toContain(fixtures.container);
});

test('confirms, then goes back to offering', async ({ page }) => {
    await goto(page, fixtures.container);

    const button = copyButton(codeBlock(page));
    await button.click();

    // The flash is the only feedback a copy gets, and it has to be temporary: a control stuck on
    // `check` reads as done rather than as available, and the next reader does not press it.
    await expect(button).toHaveClass(/is-confirmed/);
    await expect(glyph(button)).toHaveText('check');

    await expect(button).not.toHaveClass(/is-confirmed/, { timeout: 5_000 });
    await expect(glyph(button)).toHaveText('content_copy');
});
