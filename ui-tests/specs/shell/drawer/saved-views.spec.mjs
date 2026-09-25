// The drawer's third section: the views that are neither a hierarchy nor a type.
//
// Geo and Latest are standing questions about the dataspace - what has coordinates, what changed
// most recently - and like the class list they answer into a dialog rather than navigating, so
// the document being read survives the lookup. They are the only entries in the drawer that are
// buttons rather than links, which is the markup saying the same thing: these open a result, they
// do not take you somewhere.
import { test, expect } from '../../../lib/console.mjs';
import { goto, settled } from '../../../lib/settle.mjs';
import { itemUri } from '../../../lib/fixtures.mjs';
import { openDrawer } from '../../../lib/drawer.mjs';

const other = page => page.locator('.ldh-sidebar ul.sb-other');

test('offers the standing questions as buttons, not links', async ({ page }) => {
    await goto(page, itemUri(1));
    await settled(page);
    await openDrawer(page);

    for (const view of ['button.btn-geo', 'button.btn-latest']) {
        await expect(other(page).locator(view), `${view} is not offered`).toBeVisible();
    }
});

test('answers into a dialog, leaving the document being read where it was', async ({ page }) => {
    await goto(page, itemUri(1));
    await settled(page);
    await openDrawer(page);

    await other(page).locator('button.btn-latest').click();

    // Named rather than "whichever dialog turns up": the handler builds a `.modal-latest`, and
    // its results are a query over the whole dataspace, so it is given room to answer.
    await expect(page.locator('div.modal-latest')).toBeVisible({ timeout: 30_000 });
    // The document it was asked from is still rendered underneath: the lookup is an overlay, not
    // a navigation. (Asserted on the page rather than on the address, which the dialog is free to
    // annotate for its own state.)
    await expect(page.locator('.document-body')).toBeVisible();
});
