// The dataspace tab strip, and the apps menu that fills it.
//
// A LinkedDataHub instance serves several dataspaces, each on its own subdomain, and the strip is
// how a reader keeps more than one open at a time. With a single dataspace there is nothing to
// choose between, and the strip stays out of the way - present in the DOM, not shown - which is
// worth pinning as the deliberate state it is rather than leaving it to look like an element that
// failed to render.
//
// The apps menu is the other half: it lists the dataspaces this instance serves, each as a link
// to its origin. Its behaviour as a menu belongs to controls/menu; what it HOLDS is here.
import { test, expect } from '../../lib/console.mjs';
import { goto, settled } from '../../lib/settle.mjs';
import { itemUri } from '../../lib/fixtures.mjs';

const strip = page => page.locator('ul.ldh-tabs');
const apps = page => page.locator('div.ac-menu-anchor:has(button.btn-apps)').first();

test.beforeEach(({}, testInfo) => {
    test.skip(testInfo.project.name !== 'owner',
        'the apps list is offered to an authenticated agent; the fixture is not readable anonymously');
});

test('stays out of the way while one dataspace is open', async ({ page }) => {
    await goto(page, itemUri(1));
    await settled(page);

    // Present and unshown, which is not the same as missing: the strip is what a second dataspace
    // would be added to, so it is built with the page.
    await expect(strip(page)).toBeAttached();
    await expect(strip(page)).toBeHidden();
});

test('the apps menu lists the dataspaces this instance serves', async ({ page }) => {
    await goto(page, itemUri(1));
    await settled(page);

    await apps(page).locator('button.btn-apps').click();
    const entries = apps(page).locator('.ac-menu a[href]');
    expect(await entries.count(), 'the apps menu offered no dataspace').toBeGreaterThan(0);
    // Each one is an origin to open, so each carries an address rather than a script hook.
    await expect(entries.first()).toHaveAttribute('href', /^https?:\/\//);
});
