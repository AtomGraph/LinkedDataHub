// The breadcrumb: where the document sits in the hierarchy, and the way back up it.
//
// Every document in LDH is a node in a containment tree, and the breadcrumb is the only part of
// the chrome that says so on a page you arrived at by URL. Its crumbs are the document's
// ancestors, so the assertion is about ADDRESSES rather than labels: a trail that reads correctly
// while linking somewhere else is the failure worth catching, and a translated label would not
// see it.
//
// The trail is populated client-side on a rendered page, which is why every assertion here is an
// auto-retrying one against the finished list rather than a count taken on arrival.
import { test, expect } from '../../../lib/console.mjs';
import { goto, settled } from '../../../lib/settle.mjs';
import { fixtures, itemUri } from '../../../lib/fixtures.mjs';
import { endUserBase } from '../../../lib/stack.mjs';

const breadcrumb = page => page.locator('div.ldh-bc').first();
const crumbs = page => breadcrumb(page).locator('a[href]');

test('names the path from the dataspace root down to the document', async ({ page }) => {
    await goto(page, itemUri(1));
    await settled(page);

    // The ancestors, in order, each addressed rather than named: the dataspace root, the
    // container the fixtures live in, and then the document being read.
    await expect(crumbs(page).nth(0)).toHaveAttribute('href', endUserBase);
    await expect(crumbs(page).nth(1)).toHaveAttribute('href', fixtures.container);
});

test('climbs to the ancestor a crumb names', async ({ page }) => {
    await goto(page, itemUri(1));
    await settled(page);

    await crumbs(page).nth(1).click();
    await expect(page).toHaveURL(fixtures.container);
});
