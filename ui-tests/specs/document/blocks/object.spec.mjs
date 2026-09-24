// The object block: a block whose value is another resource, rendered in place.
//
// It is how a document composes: only `ldh:Object` and `ldh:XHTML` may be values in a document's
// content list, so anything else that is to appear as content - a chart, a view, another document's
// resource - gets there by being named by an object block. The fixture's chart is exactly that,
// and this is the mechanism that makes it visible at all.
//
// The subtlety worth pinning is whose block it is. The embedded rendering is wrapped in
// `.ldh-obj-value` precisely so that block-level tools address the HOST block rather than the
// resource it happens to be showing - one card, one header, one set of controls, however deep the
// thing inside it goes.
import { test, expect } from '../../../lib/console.mjs';
import { goto, settled } from '../../../lib/settle.mjs';
import { fixtures } from '../../../lib/fixtures.mjs';

const objectValue = page => page.locator('.ldh-obj-value').first();

test.beforeEach(({}, testInfo) => {
    test.skip(testInfo.project.name !== 'owner', 'the fixture container is owner-owned');
});

test('renders the resource its value names', async ({ page }) => {
    await goto(page, fixtures.container);
    await settled(page);

    await expect(objectValue(page)).toBeVisible();
    // Not empty: an object block that resolved nothing would leave the wrapper standing with
    // nothing in it, which is indistinguishable from a block with no value at all.
    await expect(objectValue(page)).not.toBeEmpty();
});

test('stays one block, however much is rendered inside it', async ({ page }) => {
    await goto(page, fixtures.container);
    await settled(page);

    // The host card owns the chrome. The embedded resource brings its own rendering, not its own
    // card - so the block holding an object value has exactly one header, like any other block.
    const host = page.locator('.block.ldh-block:has(.ldh-obj-value)').first();
    await expect(host).toBeVisible();
    await expect(host.locator('.ldh-block-head')).toHaveCount(1);
});
