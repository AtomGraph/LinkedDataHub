// The document's timestamp, which the action bar carries and no block does.
//
// A timestamp belongs to a document, not to a thing described in one: a concept has no modified
// date, the document stating it does. So the action bar is where it is rendered, and it is
// rendered only when the document actually carries `dct:created` or `dct:modified` - a bar that
// shows an empty slot, or a fabricated "now", would be worse than one that shows nothing.
//
// It is also the entry to a versioned document's history: where a TimeMap exists the timestamp
// becomes the link to it, rather than a separate control appearing beside it. That half belongs
// to overlays/modal/memento, which drives it; here the timestamp is asserted as a date in the bar.
import { test, expect } from '../../../lib/console.mjs';
import { goto, settled } from '../../../lib/settle.mjs';
import { itemUri } from '../../../lib/fixtures.mjs';

const timestamp = page => page.locator('.ldh-ab-ts').first();

test.beforeEach(({}, testInfo) => {
    test.skip(testInfo.project.name !== 'owner',
        'a chrome assertion; on a virgin instance the fixture is not readable anonymously at all');
});

test('rides the action bar, carrying a date the document states', async ({ page }) => {
    await goto(page, itemUri(1));
    await settled(page);

    await expect(timestamp(page)).toBeVisible();
    // Inside the bar rather than merely somewhere on the page: the timestamp is document
    // metadata, and its placement is what says so.
    await expect(page.locator('.ldh-actionbar .ldh-ab-ts')).toHaveCount(1);

    // A date, not a label - the fixture was created by this run, so today's year is in it.
    await expect(timestamp(page)).toContainText(String(new Date().getFullYear()));
});

test('is the document\'s own, not repeated onto what the document describes', async ({ page }) => {
    await goto(page, itemUri(1));
    await settled(page);

    // One per page. A block rendering its subject's "modified" date would be stating something
    // about a resource that has none.
    await expect(page.locator('.ldh-ab-ts')).toHaveCount(1);
    await expect(page.locator('.ldh-block .ldh-ab-ts')).toHaveCount(0);
});
