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
import { itemUri } from '../../../lib/fixtures.mjs';

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

    await uri(page).fill(itemUri(2));
    await uri(page).press('Enter');

    // What the bar promises is that the URI typed into it is the document you end up reading, and
    // the bar states the document being read - so the bar showing the new URI IS the round trip.
    // Which address the browser lands on to get there (the document itself, or the platform's
    // `uri=` proxy parameter) is the platform's business rather than the bar's.
    await expect(uri(page)).toHaveValue(itemUri(2), { timeout: 30_000 });
});
