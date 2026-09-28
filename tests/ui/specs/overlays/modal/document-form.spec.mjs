// The document's own edit dialog, and the write it performs.
//
// This is the other half of the placement rule that forms/row-form asserts: a resource described
// BY the document is edited inline, and the document's own resource - which lives in its own
// document - is edited in a dialog. Here it is from the dialog's side, with the write actually
// carried out, because a form that opens, accepts an edit and saves nothing is the failure this
// dialog would have.
//
// So it is a whole round trip: open, change the title, save, fetch the document again from the
// server, and read the new title out of a freshly built form. Then put it back - a spec that
// leaves its document renamed has changed what every other spec sees.
import { test, expect } from '../../../lib/console.mjs';
import { goto, settled } from '../../../lib/settle.mjs';
import { itemTitle, itemUri } from '../../../lib/fixtures.mjs';
import { fillText, save, textValue } from '../../../lib/form.mjs';
import { openDocumentForm } from '../../../lib/modal.mjs';

const TITLE = 'http://purl.org/dc/terms/title';
// Its own document, for the same reason form-bar has one: this spec writes.
const ITEM = 4;
const EDITED = 'Renamed by the document-form spec';

test.beforeEach(({}, testInfo) => {
    test.skip(testInfo.project.name !== 'owner', 'a dialog that writes is offered to an agent who may');
});

async function editForm(page) {
    await goto(page, itemUri(ITEM));
    await settled(page);
    return openDocumentForm(page);
}

test('edits the document\'s own resource, in a dialog', { tag: '@owner' }, async ({ page }) => {
    const modal = await editForm(page);

    // The form is in the dialog, and it is this document's: the title it holds is the stored one.
    await expect(modal.locator('form')).toHaveCount(1);
    await expect(textValue(modal, TITLE)).toHaveValue(itemTitle(ITEM));
});

test('writes what was typed into it', { tag: '@owner' }, async ({ page }) => {
    const modal = await editForm(page);

    try {
        await fillText(modal, TITLE, EDITED);
        await save(modal);
        await expect(modal).toBeHidden({ timeout: 30_000 });

        // Read back from the server rather than from the page the save left behind.
        const reopened = await editForm(page);
        await expect(textValue(reopened, TITLE)).toHaveValue(EDITED);
    } finally {
        // Restored whatever happened above, so the next spec sees the fixture it expects.
        const restore = await editForm(page);
        await fillText(restore, TITLE, itemTitle(ITEM));
        await save(restore);
        await expect(restore).toBeHidden({ timeout: 30_000 });
    }
});
