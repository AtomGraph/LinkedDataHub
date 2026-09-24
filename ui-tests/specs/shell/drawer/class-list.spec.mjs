// The drawer's class list: the type axis, cutting across containment.
//
// The document tree above it walks the hierarchy a document was filed into; this walks what
// documents ARE, which in a knowledge graph is the more useful question and the one a folder tree
// cannot answer. Its entries are not markup - they are loaded from the dataspace by query, so an
// entry appearing at all is a statement about what is in the graph, and each one opens the
// instances of that class in a dialog.
//
// The list is populated after the drawer is built, so every assertion is auto-retrying against
// the finished list rather than a count taken when the drawer opened.
import { test, expect } from '../../../lib/console.mjs';
import { goto, settled } from '../../../lib/settle.mjs';
import { itemUri } from '../../../lib/fixtures.mjs';
import { openDrawer } from '../../../lib/drawer.mjs';

const classes = page => page.locator('.ldh-sidebar ul.sb-classes');
const entries = page => classes(page).locator('.tree-link.btn-class');

test.beforeEach(({}, testInfo) => {
    test.skip(testInfo.project.name !== 'owner',
        'the class list is a query over the dataspace; anonymously the fixtures are not readable');
});

test('lists the classes the dataspace actually holds', async ({ page }) => {
    await goto(page, itemUri(1));
    await settled(page);
    await openDrawer(page);

    // At least one, because the fixtures put typed documents in the dataspace - an empty list
    // here would mean the query, not the graph, came back empty.
    await expect(entries(page).first()).toBeVisible();
    await expect(entries(page).first().locator('.tree-label')).not.toBeEmpty();
});

test('opens the instances of a class in a dialog', async ({ page }) => {
    await goto(page, itemUri(1));
    await settled(page);
    await openDrawer(page);

    await expect(entries(page).first()).toBeVisible();
    await entries(page).first().click();

    // The results are a view rendered into a dialog, which is how the type axis stays a lookup
    // rather than a navigation - the document being read is still there underneath.
    await expect(page.locator('div.ac-backdrop.modal').first()).toBeVisible();
});
