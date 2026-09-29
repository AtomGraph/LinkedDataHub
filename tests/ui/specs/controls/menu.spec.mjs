// The dropdown, which is one control with four hosts: the action bar's Create and its overflow
// kebab, the mode switcher, and the header's account menu. Each host's own spec says what its
// menu HOLDS; this one says how any of them behaves, because they all ride the same
// `.ac-menu-anchor` + `.drop-toggle` handler in client.xsl and would all break together.
//
// Two of the three claims are about state nobody can see in a screenshot:
//
//   · `aria-expanded` on the toggle, FROM THE SERVER'S FIRST PAINT. The panel's visibility is CSS
//     off the anchor's `is-open`, so a handler that forgot the attribute would look perfect and
//     tell a screen reader the opposite of what is on screen. The resting state is asserted too,
//     and that half is why this spec exists: seven toggles - both action-bar menus, the two mode
//     switchers and the block menu - shipped with no `aria-expanded` at all, so until a reader
//     pressed one, assistive technology was told nothing. The handler added it on first run,
//     which is precisely the kind of gap a click-then-assert test never sees.
//   · ONE AT A TIME. Opening a menu closes whichever other one was open - a single line in the
//     handler that nothing else would notice, and whose absence leaves two panels overlapping.
//
// Escape is the third: it closes the menu and puts the focus back on the toggle it came from,
// which is what makes the keyboard path a loop rather than a dead end.
import { test, expect } from '../../lib/console.mjs';
import { goto, settled } from '../../lib/settle.mjs';
import { itemUri } from '../../lib/fixtures.mjs';

// Two hosts on one page, which is what the one-at-a-time claim needs. `.first()` on both: the
// action bar carries a second .ldh-of-wrap for the export menu, and a bare locator matches them
// both.
const overflow = page => page.locator('div.ldh-of-wrap').first();
const create = page => page.locator('div.ldh-add-wrap').first();
const toggleOf = anchor => anchor.locator('button.drop-toggle').first();

// Both hosts write to the document, so both are offered only to an agent who may.
test.beforeEach(({}, testInfo) => {
    test.skip(testInfo.project.name !== 'owner', 'these menus are offered to an agent who may write');
});

test('opens on its toggle, and says so where a screen reader can hear it', { tag: '@owner' }, async ({ page }) => {
    await goto(page, itemUri(1));
    await settled(page);

    // At rest, before any handler has run: the markup already says it is a menu button and that
    // the menu is shut.
    await expect(toggleOf(overflow(page))).toHaveAttribute('aria-haspopup', 'menu');
    await expect(toggleOf(overflow(page))).toHaveAttribute('aria-expanded', 'false');
    await expect(overflow(page)).not.toHaveClass(/is-open/);

    await toggleOf(overflow(page)).click();
    await expect(overflow(page)).toHaveClass(/is-open/);
    await expect(toggleOf(overflow(page))).toHaveAttribute('aria-expanded', 'true');
});

test('yields to the next menu opened, so only one panel is ever up', { tag: '@owner' }, async ({ page }) => {
    await goto(page, itemUri(1));
    await settled(page);

    await toggleOf(overflow(page)).click();
    await expect(overflow(page)).toHaveClass(/is-open/);

    await toggleOf(create(page)).click();
    await expect(create(page)).toHaveClass(/is-open/);
    await expect(overflow(page), 'the menu that was open stayed open under the new one')
        .not.toHaveClass(/is-open/);
    // Closed by the handler rather than by a press, and it says so: the state it was given on
    // opening has to be taken back.
    await expect(toggleOf(overflow(page))).toHaveAttribute('aria-expanded', 'false');
});

test('Escape closes it and hands the focus back to the toggle', { tag: '@owner' }, async ({ page }) => {
    await goto(page, itemUri(1));
    await settled(page);

    await toggleOf(overflow(page)).click();
    await expect(overflow(page)).toHaveClass(/is-open/);

    await page.keyboard.press('Escape');
    await expect(overflow(page)).not.toHaveClass(/is-open/);
    // Where the focus goes is the difference between a keyboard path and a keyboard trap: the
    // menu took the focus on open, so closing it has to give the focus back.
    await expect(toggleOf(overflow(page))).toBeFocused();
});
