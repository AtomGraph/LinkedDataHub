// The Create menu: what can be made here, and the dialog each choice opens.
//
// The menu is built from the classes the application's ontology declares a constructor for, so
// its items are data rather than markup - `@data-for-class` on each one names the class it would
// construct. That attribute is the thing worth asserting against, because it is also what the
// dialog is opened FOR: the modal carries the same class as its `@typeof`, and a pairing between
// the two is the difference between "a dialog opened" and "the right dialog opened".
//
// Creating something is view-create's subject and is not repeated here; this stops at the dialog.
import { test, expect } from '../../../lib/console.mjs';
import { goto, settled } from '../../../lib/settle.mjs';
import { fixtures } from '../../../lib/fixtures.mjs';
import { constructorModal } from '../../../lib/modal.mjs';

const create = page => page.locator('div.ldh-add-wrap').first();
const menu = page => create(page).locator('div.ldh-add-menu');
const choices = page => menu(page).locator('button.add-constructor[data-for-class]');

test.beforeEach(({}, testInfo) => {
    test.skip(testInfo.project.name !== 'owner', 'creating is offered to an agent who may write');
});

test('offers what the application knows how to construct', async ({ page }) => {
    await goto(page, fixtures.container);
    await settled(page);

    await create(page).locator('button.drop-toggle').click();
    await expect(menu(page)).toBeVisible();
    // At least one, and every one of them naming the class it makes - an item with no class to
    // construct could not open a dialog at all.
    expect(await choices(page).count()).toBeGreaterThan(0);
});

test('opens a dialog for the class that was picked', async ({ page }) => {
    await goto(page, fixtures.container);
    await settled(page);

    await create(page).locator('button.drop-toggle').click();
    const choice = choices(page).first();
    const forClass = await choice.getAttribute('data-for-class');
    await choice.click();

    const modal = constructorModal(page).first();
    await expect(modal).toBeVisible();
    await expect(modal, 'the dialog is typed for the class the menu item named')
        .toHaveAttribute('typeof', forClass);
});
