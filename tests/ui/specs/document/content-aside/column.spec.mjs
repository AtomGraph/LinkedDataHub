// The content column is a slot, and the platform renders it only when something fills it.
//
// `ldh:ContentColumn` is an extension point: the platform declares it and owns the wrapper, and
// an imported package decides whether any given document has something to put there - the SKOS
// package fills it on a concept page with the taxonomy tree, and nothing fills it on an ordinary
// document. The distinction worth pinning is that an unfilled slot is ABSENT rather than empty:
// a 300px column of nothing, reserved on every page against the chance that a package might one
// day want it, would be the obvious way to get this wrong and would look fine in a screenshot of
// the page that does have content.
import { test, expect } from '../../../lib/console.mjs';
import { goto, settled } from '../../../lib/settle.mjs';
import { itemUri } from '../../../lib/fixtures.mjs';
import { document as conceptDocument } from '../../../lib/taxonomy.mjs';
import { READ_MODE, inMode } from '../../../lib/mode.mjs';

const column = page => page.locator('.ldh-content-aside');

test.beforeEach(({}, testInfo) => {
    test.skip(testInfo.project.name !== 'owner',
        'the taxonomy fixture is owner-owned; the column renders identically for either agent');
});

test('renders where a package fills it', { tag: '@owner' }, async ({ page }) => {
    await goto(page, inMode(conceptDocument('coffee'), READ_MODE));

    await expect(column(page)).toBeVisible();
    // The platform owns the wrapper and the package owns what is in it, which is why the tree is
    // asserted as a descendant rather than as the column itself.
    await expect(column(page).locator('ul.concept-tree')).toBeVisible();
});

test('is absent, not empty, on a document nothing fills', { tag: '@owner' }, async ({ page }) => {
    await goto(page, itemUri(1));
    await settled(page);

    await expect(column(page)).toHaveCount(0);
});
