// How a dialog is dismissed - the three affordances every modal in the product inherits from the
// shell it is rendered into, rather than from whatever opened it.
//
// Two of them are one line of XPath apart in client/modal.xsl and pull in opposite directions:
//
//   · A PRESS ON THE BACKDROP dismisses, and a press inside the card must not. The handler is
//     bound to the backdrop, so every press inside the dialog reaches it too; what separates them
//     is `empty($target/ancestor-or-self::node() intersect *)`, which asks whether the press
//     landed on the backdrop ITSELF. Assert only the dismissal and a handler that closes on every
//     press - one that drops the containment test and takes the dialog away mid-edit - still
//     passes. The negative is the half worth having.
//   · ESCAPE dismisses THE TOPMOST, `(.//div[contains-token(@class, 'modal')])[last()]`, so a
//     dialog opened over another takes the key and gives it back on the way out. One dialog
//     cannot show that: the assertion needs two, and the one underneath has to still be there.
//
// THE TOPMOST RULE IS NOT ASSERTED HERE, and the reason is a finding rather than an omission:
// nothing in the product opens a dialog from inside a dialog, so two cannot be had to compare.
// Both candidates were driven and neither produces a second one. A plain dh:Item's edit dialog
// carries no `btn-edit-constructors` - there is no constructor on it to edit. A view rendered
// into a dialog (the drawer's search results) offers no Create either, because a view decides on
// that button by asking which container a new solution would be stored in, and a search has
// none. `[last()]` is therefore future-proofing, and the day a flow stacks two dialogs this is
// the spec that owes it a test.
import { test, expect } from '../../../lib/console.mjs';
import { goto, settled } from '../../../lib/settle.mjs';
import { itemUri } from '../../../lib/fixtures.mjs';
import { cardOf, openDocumentForm } from '../../../lib/modal.mjs';

// The dialog is the subject and an edit form is only offered to an agent who may write.
test.beforeEach(({}, testInfo) => {
    test.skip(testInfo.project.name !== 'owner', 'a dialog is only offered to an agent who may write');
});

async function editForm(page) {
    await goto(page, itemUri(1));
    await settled(page);
    return openDocumentForm(page);
}

test('the head\'s close button dismisses it', async ({ page }) => {
    const modal = await editForm(page);

    await modal.locator('span.ac-modal-x button').first().click();
    await expect(modal).toBeHidden();
});

test('a press on the backdrop dismisses it', async ({ page }) => {
    const modal = await editForm(page);

    // The backdrop's own top-left corner: `pos-top` puts the card below and centred, so this is
    // the surface and not the dialog.
    await modal.click({ position: { x: 4, y: 4 } });
    await expect(modal).toBeHidden();
});

test('a press inside the card does not', async ({ page }) => {
    const modal = await editForm(page);

    // The dialog's own head, which carries no control - a press that means nothing, which is
    // exactly the press that must not close the form someone is filling in.
    await cardOf(modal).locator('.ac-modal-head').first().click();
    await expect(modal).toBeVisible();
});

test('Escape dismisses it', async ({ page }) => {
    const modal = await editForm(page);

    await page.keyboard.press('Escape');
    await expect(modal).toBeHidden();
});
