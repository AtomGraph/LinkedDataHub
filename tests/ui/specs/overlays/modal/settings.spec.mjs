// The dataspace settings dialog, and the write it performs.
//
// The settings are a document of their own (/settings), with their own entity tag, and a PATCH to
// them has to quote it (#453) the way a write to any existing document quotes that document's. The
// dialog used to quote the PAGE's tag instead, and it worked only by accident: loading the settings
// stored their tag under the page's key, replacing the page's own - so the save quoted the right
// tag, and the next write to the page quoted the wrong one and was refused 412.
//
// Both halves are asserted: the save quotes exactly the tag the settings were read with, and
// opening the dialog leaves the tag the browser holds for the page alone.
import { test, expect } from '../../../lib/console.mjs';
import { goto, settled } from '../../../lib/settle.mjs';
import { itemUri } from '../../../lib/fixtures.mjs';
import { fillText, save, textValue } from '../../../lib/form.mjs';

const TITLE = 'http://purl.org/dc/terms/title';
// Its own document, so the page tag the second test reads is not one another spec is moving.
const ITEM = 5;
const EDITED = 'Renamed by the settings spec';

test.beforeEach(({}, testInfo) => {
    test.skip(testInfo.project.name !== 'owner', 'the settings are offered to the owner only');
});

const isSettings = (response, method) =>
    response.request().method() === method && new URL(response.url()).pathname === '/settings';

// Opens the settings dialog from the header's settings menu, returning it with the response the
// settings were loaded from.
async function openSettings(page) {
    await goto(page, itemUri(ITEM));
    await settled(page);

    const loaded = page.waitForResponse(response => isSettings(response, 'GET'));
    await page.locator('div.ac-menu-anchor:has(button.btn-app-settings) > button.drop-toggle').first().click();
    await page.locator('button.btn-app-settings').first().click();
    const response = await loaded;

    const modal = page.locator('div#app-settings.modal');
    await expect(modal.locator('form')).toBeVisible({ timeout: 30_000 });
    return { modal, response };
}

// Saves the dialog with the given title, returning the PATCH's request and response. The page
// reloads on success, which is what the settings' new stylesheet composition needs.
async function saveTitle(page, modal, title) {
    const patched = page.waitForResponse(response => isSettings(response, 'PATCH'));
    await fillText(modal, TITLE, title);
    await save(modal);
    const response = await patched;
    await settled(page);
    return response;
}

test('saves quoting the tag the settings were read with', { tag: '@owner' }, async ({ page }) => {
    const { modal, response: loaded } = await openSettings(page);
    const original = await textValue(modal, TITLE).inputValue();
    const tag = loaded.headers()['etag'];
    expect(tag, 'the settings answer with an entity tag').toBeTruthy();

    try {
        const patched = await saveTitle(page, modal, EDITED);

        expect(patched.request().headers()['if-match'], 'the save quotes the settings\' tag, not the page\'s').toBe(tag);
        expect(patched.status()).toBe(204);

        const { modal: reopened } = await openSettings(page);
        await expect(textValue(reopened, TITLE)).toHaveValue(EDITED);
    } finally {
        const { modal: restore } = await openSettings(page);
        const restored = await saveTitle(page, restore, original);
        expect(restored.status()).toBe(204);
    }
});

// The tags the browser holds for conditional writes, keyed by document URI (LinkedDataHub.etags). The backticks
// ldh:set-document-etag wraps the key in only quote the dotted name for ixsl:set-property; the JS key is the bare URI.
const storedTag = (page, uri) => page.evaluate(key => window.LinkedDataHub.etags[key], uri);

test('keeps the settings\' tag under the settings, and the page\'s under the page', { tag: '@owner' }, async ({ page }) => {
    await goto(page, itemUri(ITEM));
    await settled(page);
    const pageTag = await storedTag(page, itemUri(ITEM));
    expect(pageTag, 'the page\'s tag is stored when it loads').toBeTruthy();

    const { response } = await openSettings(page);
    const settingsUri = new URL('/settings', itemUri(ITEM)).href;

    expect(await storedTag(page, settingsUri), 'the settings\' tag is kept for the save to quote').toBe(response.headers()['etag']);
    // replaced by the settings' tag, every write to the page that did not reload it first was refused 412
    expect(await storedTag(page, itemUri(ITEM)), 'the page\'s tag is as it was before the dialog opened').toBe(pageTag);
});
