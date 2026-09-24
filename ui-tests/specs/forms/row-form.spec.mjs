// Editing in place: the form that appears inside a block rather than over the page.
//
// Where a form is rendered is not a style choice in LDH, it is a statement about what is being
// edited. A resource described BY the document being read is edited inline, in its own block; a
// resource that lives in its own document is edited in a dialog. The reader can tell the two
// apart without being told, because one keeps the page and the other covers it.
//
// A concept page is where the distinction is visible: the concept is described by the document,
// so pressing its block's edit control has to turn that block into a form and leave the rest of
// the page - the other blocks, the tree in the content column - readable behind it. The failure
// to catch is the easy one: reaching for the dialog helper because it is there.
import { test, expect } from '../../lib/console.mjs';
import { goto } from '../../lib/settle.mjs';
import { concept, document } from '../../lib/taxonomy.mjs';
import { READ_MODE, inMode } from '../../lib/mode.mjs';

const blockFor = (page, name) => page.locator(`div.block.ldh-block[about="${concept(name)}"]`);

test.beforeEach(({}, testInfo) => {
    test.skip(testInfo.project.name !== 'owner', 'editing is offered to an agent who may write');
});

test('turns the block into a form, in place', async ({ page }) => {
    await goto(page, inMode(document('coffee'), READ_MODE));

    const block = blockFor(page, 'coffee');
    await expect(block).toBeVisible();
    await expect(block.locator('form')).toHaveCount(0);

    await block.locator('button.btn-edit').first().click();

    // The form is INSIDE the block whose resource it edits.
    await expect(block.locator('form').first()).toBeVisible({ timeout: 30_000 });
});

test('leaves the rest of the page readable, opening no dialog', async ({ page }) => {
    await goto(page, inMode(document('coffee'), READ_MODE));

    const block = blockFor(page, 'coffee');
    await block.locator('button.btn-edit').first().click();
    await expect(block.locator('form').first()).toBeVisible({ timeout: 30_000 });

    // No backdrop, and the content column still there: the document is being edited in the middle
    // of itself rather than behind a sheet.
    await expect(page.locator('div.ac-backdrop.modal')).toHaveCount(0);
    await expect(page.locator('.ldh-content-aside ul.concept-tree')).toBeVisible();
});
