// The account menu: who the page thinks you are.
//
// There is no username on screen - the avatar is the agent's initials and the agent's full name
// is its `title` - so this is the one place a reader can check which identity their certificate
// authenticated as before writing something under it. The menu item behind it links to the
// agent's OWN document, because an agent in LDH is a resource in the graph like any other; a menu
// that led to a settings page instead would have quietly stopped being Linked Data.
//
// Whether the avatar is offered at all is the authorization axis and is asserted there.
import { test, expect } from '../../../lib/console.mjs';
import { goto, settled } from '../../../lib/settle.mjs';
import { itemUri } from '../../../lib/fixtures.mjs';

const account = page => page.locator('div.ldh-avatar-wrap');
const avatar = page => account(page).locator('button.ldh-avatar');

test.beforeEach(({}, testInfo) => {
    test.skip(testInfo.project.name !== 'owner', 'an anonymous reader has no account to show');
});

test('shows the authenticated agent as initials, naming them in full on hover', { tag: '@owner' }, async ({ page }) => {
    await goto(page, itemUri(1));
    await settled(page);

    await expect(avatar(page)).toBeVisible();
    // Initials: one or two letters, derived from the agent's label rather than stored anywhere.
    await expect(avatar(page)).toHaveText(/^[A-Z]{1,2}$/);

    const label = await avatar(page).getAttribute('title');
    expect(label, 'the avatar names the agent in full for anyone who stops on it').toBeTruthy();
    // The menu button says it opens a menu, which the action bar's toggles do not yet say at rest.
    await expect(avatar(page)).toHaveAttribute('aria-haspopup', 'menu');
    await expect(avatar(page)).toHaveAttribute('aria-expanded', 'false');
});

test('leads to the agent\'s own document', { tag: '@owner' }, async ({ page }) => {
    await goto(page, itemUri(1));
    await settled(page);

    await avatar(page).click();
    const item = account(page).locator('a.ac-menu-item[role="menuitem"]').first();
    await expect(item).toBeVisible();

    // An agent is a resource in the graph, so the menu's one item is a link to it - dereferenceable
    // like anything else the reader could have navigated to.
    const href = await item.getAttribute('href');
    expect(href, 'the agent item links nowhere').toBeTruthy();
    await expect(avatar(page)).toHaveAttribute('aria-expanded', 'true');
});
