// The bar that ends a form, and the one thing on it nothing else covers: Reset.
//
// Save has coverage everywhere - every spec that writes something presses it - and Cancel is the
// dialog's own dismissal, asserted where the dialog is. Reset has none, and it is the affordance
// whose failure is quietest: it acts on the form as a whole through the native `type="reset"`,
// with no handler behind it at all, so nothing in the client would report it if the markup were
// to stop being a reset button. What a reader would see is an edit they thought they had
// abandoned still sitting in the field.
//
// The last assertion is the one that matters, and it is deliberately not a DOM assertion. Putting
// the field back is worth nothing if the edit reached the store on the way, so the document is
// fetched again from the server and its form rebuilt from what came back - read, write, re-read,
// where the write is supposed to be the one that never happened.
import { test, expect } from '../../lib/console.mjs';
import { goto, settled } from '../../lib/settle.mjs';
import { itemTitle, itemUri } from '../../lib/fixtures.mjs';
import { formBar, resetButton, textValue } from '../../lib/form.mjs';
import { openDocumentForm } from '../../lib/modal.mjs';

const TITLE = 'http://purl.org/dc/terms/title';

// A document of this spec's own: it edits a title and abandons the edit, and a spec that shares
// item-01 with the dialog and combobox specs would be measuring their leftovers if it ever left
// one behind.
const ITEM = 3;

// A form is only offered to an agent who may write.
test.beforeEach(({}, testInfo) => {
    test.skip(testInfo.project.name !== 'owner', 'a form is only offered to an agent who may write');
});

async function editForm(page) {
    await goto(page, itemUri(ITEM));
    await settled(page);
    return openDocumentForm(page);
}

test('ends the form with a native Reset and a native Save', { tag: '@owner' }, async ({ page }) => {
    const form = await editForm(page);

    await expect(formBar(form)).toBeVisible();
    // The types are the mechanism, not decoration: `reset` is why Reset needs no handler, and
    // `submit` is what carries the form to its onsubmit template.
    await expect(resetButton(form)).toHaveAttribute('type', 'reset');
    await expect(form.locator('button.btn-save').first()).toHaveAttribute('type', 'submit');
});

test('Reset puts an edited field back to what the document holds', { tag: '@owner' }, async ({ page }) => {
    const form = await editForm(page);
    const title = textValue(form, TITLE);

    await expect(title).toHaveValue(itemTitle(ITEM));
    await title.fill('Edited, and then thought better of');
    await expect(title).toHaveValue('Edited, and then thought better of');

    await resetButton(form).click();
    await expect(title).toHaveValue(itemTitle(ITEM));
});

test('and the abandoned edit never reached the document', { tag: '@owner' }, async ({ page }) => {
    const form = await editForm(page);

    await textValue(form, TITLE).fill('Edited, and then thought better of');
    await resetButton(form).click();
    await form.locator('button.btn-save').first().press('Escape');

    // Fetched again, so the value the rebuilt form shows is the stored one rather than the one
    // the abandoned form was holding.
    const reopened = await editForm(page);
    await expect(textValue(reopened, TITLE)).toHaveValue(itemTitle(ITEM));
});
