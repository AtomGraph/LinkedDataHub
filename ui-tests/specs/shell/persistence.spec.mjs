// The shell is the part of the page that a navigation does not replace.
//
// Moving between documents swaps the pane's document body and leaves the header, the tab strip
// and the footer standing - that is what makes the tab strip a strip of dataspaces rather than a
// row of links that happens to be redrawn identically each time. Nothing in the DOM says which
// of those two happened, because a re-rendered header is indistinguishable from a surviving one
// by inspection: same markup, same text, same everything.
//
// So the elements are stamped before the navigation and read after it. An attribute set from the
// page survives only as long as the element does; a full page load, or a client-side render that
// replaces the chrome along with the content, takes it away. That makes the assertion a statement
// about identity rather than about appearance, which is the only form this claim has.
import { test, expect } from '../../lib/console.mjs';
import { goto, settled } from '../../lib/settle.mjs';
import { itemUri } from '../../lib/fixtures.mjs';
import { openDrawer } from '../../lib/drawer.mjs';
import { linkOf, rowFor } from '../../lib/tree.mjs';

const CHROME = ['.ldh-header', 'ul.ldh-tabs', '.ldh-footer'];

// A chrome assertion; on a virgin instance the fixture is not readable anonymously, which would
// measure that instead.
test.beforeEach(({}, testInfo) => {
    test.skip(testInfo.project.name !== 'owner',
        'a chrome assertion; the authorization axis would measure the same thing twice');
});

test('renders the chrome the document sits in', { tag: '@owner' }, async ({ page }) => {
    await goto(page, itemUri(1));
    await settled(page);

    await expect(page.locator('.ldh-header')).toBeVisible();
    await expect(page.locator('.ldh-footer')).toBeVisible();
    // The tab strip is the one that is present without being shown: a single dataspace is not a
    // set to choose between, so the strip stays out of the way until there is a second one. It is
    // still in the DOM, which is what the stamp below relies on.
    await expect(page.locator('ul.ldh-tabs')).toBeAttached();
    await expect(page.locator('.document-body')).toBeVisible();
});

test('survives a navigation that replaces the document body', { tag: '@owner' }, async ({ page }) => {
    await goto(page, itemUri(1));
    await settled(page);
    await openDrawer(page);

    // The stamp is the whole test: these attributes exist only on THESE elements, and only until
    // something replaces them.
    await page.evaluate(selectors => {
        for (const selector of selectors) document.querySelector(selector)?.setAttribute('data-survived', 'yes');
    }, CHROME);

    // A tree link is a client-side navigation by construction - client/navigation.xsl intercepts
    // it rather than letting the browser follow the href.
    await linkOf(rowFor(page.locator('div.document-tree'), itemUri(2))).click();
    await expect(page).toHaveURL(itemUri(2));
    await settled(page);

    for (const selector of CHROME) {
        await expect(page.locator(selector), `${selector} was replaced`)
            .toHaveAttribute('data-survived', 'yes');
    }
});
