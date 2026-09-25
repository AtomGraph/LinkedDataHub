// The address bar, which is a Linked Data address bar rather than a browser one.
//
// It states the URI of the document being read, and what you type into it is a URI to dereference
// - not a search term. That is the whole of its contract and both halves are easy to lose: a bar
// that shows the browser's location would show query strings and fragments that are not part of
// the document's identity, and a bar wired to a search would quietly turn an identifier into a
// string match.
//
// It submits as a GET to the current document with the URI as `uri=`, which is the platform's
// proxy entry point - the same parameter an external resource is dereferenced through.
import { test, expect } from '../../../lib/console.mjs';
import { goto, settled } from '../../../lib/settle.mjs';
import { fixtures, itemUri } from '../../../lib/fixtures.mjs';

const address = page => page.locator('form.ldh-address');
const uri = page => address(page).locator('input#uri');

test('states the URI of the document being read', async ({ page }) => {
    await goto(page, itemUri(1));
    await settled(page);

    await expect(address(page)).toHaveAttribute('role', 'search');
    // The document's identity, which is what the reader would copy - not the browser's location.
    await expect(uri(page)).toHaveValue(itemUri(1));
});

test('takes a URI and dereferences it', async ({ page }) => {
    await goto(page, itemUri(1));
    await settled(page);

    // The container, which the anonymous reader is granted (lib/fixtures.mjs) as this document is.
    // The bar is the same control whoever is reading, so the spec runs on both axes - but a URI
    // outside the grant would answer 403, and a 403 is page noise that fails the test whatever the
    // bar did. What that would assert is the ACL, which anonymous-affordances.spec.mjs asserts.
    await uri(page).fill(fixtures.container);
    await uri(page).press('Enter');

    // The document that ends up being read, stated by the body itself. This is the half of the
    // round trip the typed value cannot stand in for: `fill` puts the URI in the bar before Enter
    // is ever pressed, so a bar wired to nothing would satisfy an assertion on its value alone.
    // Which address the browser lands on to get there (the document itself, or the platform's
    // `uri=` proxy parameter) is the platform's business rather than the bar's, so it is not read.
    await expect(page.locator('div.document-body')).toHaveAttribute('about', fixtures.container, { timeout: 30_000 });
    // And the bar states the document being read, which is the other half.
    await expect(uri(page)).toHaveValue(fixtures.container);
});
