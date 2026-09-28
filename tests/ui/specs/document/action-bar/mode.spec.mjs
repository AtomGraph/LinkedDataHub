// The mode switcher, whose whole job is to say what the URL already says.
//
// A document's rendering mode lives in `?mode=`, and every other part of the client reads it from
// there. That makes the switcher a view of the address rather than a control holding state of its
// own, and gives it two failure modes worth pinning apart: showing a mode the URL did not ask for
// (the label and the address disagreeing), and offering an item that goes somewhere other than the
// same document in that mode.
//
// Each item is a `menuitemradio`, so `aria-checked` is where the current mode is stated - not the
// button's label, which is a translated string, and not `is-active`, which is a paint.
import { test, expect } from '../../../lib/console.mjs';
import { goto, settled } from '../../../lib/settle.mjs';
import { itemUri } from '../../../lib/fixtures.mjs';
import { CONTENT_MODE, READ_MODE, inMode } from '../../../lib/mode.mjs';

const switcher = page => page.locator('div.ldh-mode').first();
const itemFor = (page, kind) => switcher(page).locator(`a.mi.${kind}`).first();

test('marks the mode the URL asked for', async ({ page }) => {
    await goto(page, inMode(itemUri(1), READ_MODE));
    await settled(page);

    await switcher(page).locator('button.drop-toggle').click();
    await expect(itemFor(page, 'read-mode')).toHaveAttribute('aria-checked', 'true');
    await expect(itemFor(page, 'content-mode')).toHaveAttribute('aria-checked', 'false');
});

test('and marks a different one when the URL asks for that instead', async ({ page }) => {
    await goto(page, inMode(itemUri(1), CONTENT_MODE));
    await settled(page);

    await switcher(page).locator('button.drop-toggle').click();
    await expect(itemFor(page, 'content-mode')).toHaveAttribute('aria-checked', 'true');
    await expect(itemFor(page, 'read-mode')).toHaveAttribute('aria-checked', 'false');
});

test('offers each mode as a link to this same document in it', async ({ page }) => {
    await goto(page, inMode(itemUri(1), READ_MODE));
    await settled(page);

    await switcher(page).locator('button.drop-toggle').click();
    // A whole URI compared against a whole URI: the item's href is the document's address with
    // the mode asked for, which is precisely what inMode() builds.
    await expect(itemFor(page, 'content-mode')).toHaveAttribute('href', inMode(itemUri(1), CONTENT_MODE));
});

test('takes the reader to the mode they pick', async ({ page }) => {
    await goto(page, inMode(itemUri(1), READ_MODE));
    await settled(page);

    await switcher(page).locator('button.drop-toggle').click();
    await itemFor(page, 'content-mode').click();

    await expect(page).toHaveURL(inMode(itemUri(1), CONTENT_MODE));
    await settled(page);
    await switcher(page).locator('button.drop-toggle').click();
    await expect(itemFor(page, 'content-mode'), 'the switcher followed the address it moved to')
        .toHaveAttribute('aria-checked', 'true');
});
