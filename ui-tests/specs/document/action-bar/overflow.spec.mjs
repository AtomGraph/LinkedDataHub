// The overflow kebab: where every action that acts on the document as a whole is kept.
//
// How the panel opens belongs to the dropdown it rides (specs/controls/menu.spec.mjs). What is
// asserted here is what the kebab HOLDS and, just as much, that it holds them out of the way -
// editing, deleting and re-permissioning a document are one press apart from each other and none
// of them is on the surface of the page, which is the point of putting them behind a menu.
import { test, expect } from '../../../lib/console.mjs';
import { goto, settled } from '../../../lib/settle.mjs';
import { itemUri } from '../../../lib/fixtures.mjs';

const overflow = page => page.locator('div.ldh-of-wrap').first();
const menu = page => overflow(page).locator('div.ldh-of-menu');

// WHICH actions an agent is offered is the authorization axis, asserted in axes/. That the
// offered ones live in this menu is this spec's, and it needs an agent who is offered some.
test.beforeEach(({}, testInfo) => {
    test.skip(testInfo.project.name !== 'owner', 'an agent with no write actions has an empty menu');
});

test('keeps the document\'s actions out of the way until asked', async ({ page }) => {
    await goto(page, itemUri(1));
    await settled(page);

    // Present, not absent: the menu is built with the page and hidden, which is why a spec that
    // wants one of these buttons has to open the kebab rather than click through it.
    await expect(menu(page)).toBeAttached();
    await expect(menu(page)).toBeHidden();
});

test('holds the actions that act on the whole document', async ({ page }) => {
    await goto(page, itemUri(1));
    await settled(page);

    await overflow(page).locator('button.drop-toggle').click();
    await expect(menu(page)).toBeVisible();

    for (const action of ['button.btn-edit', 'button.btn-delete', 'button.btn-save-as']) {
        await expect(menu(page).locator(action).first(), `${action} is not in the overflow menu`)
            .toBeVisible();
    }
});
