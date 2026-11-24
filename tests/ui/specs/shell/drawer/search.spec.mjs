// The drawer's search: what it asks the dataspace, and what comes back.
//
// A search has no class to bind, so the regex it used to append ran over every label in the dataspace and the
// sort waited for every match: 30 s on a large dataspace, hit or miss. Where the dataspace's service declares a
// text index (sd:propertyFeature text:query, carried to the page as a Link header beside the endpoint's), the
// search asks the index instead: each word as a prefix, in any order. Where no index is declared - the admin
// dataspace, an instance that has not migrated - the regex stays. What is asserted is the query sent, read off
// the request, because the results alone cannot tell the two apart; except where they can: a prefix index does
// not match inside a word, which the regex did.
import { test, expect } from '../../../lib/console.mjs';
import { goto } from '../../../lib/settle.mjs';
import { fixtures, containerTitle, itemTitle } from '../../../lib/fixtures.mjs';
import { adminBase } from '../../../lib/stack.mjs';
import { openDrawer } from '../../../lib/drawer.mjs';
import { listTitles } from '../../../lib/view.mjs';

const TEXT_QUERY = 'http://jena.apache.org/text#query';
const search = page => page.locator('.ldh-sidebar input').first();
const dialog = page => page.locator('div.modal.modal-search').first();

test.beforeEach(({}, testInfo) => {
    test.skip(testInfo.project.name !== 'owner', 'the admin dataspace, searched below for the regex, is the owner\'s to open');
});

// The query the search sends: the labelled-resource lookup, told from the page's own block queries
// (which a slow runner is still issuing after goto returns) by the variable it projects. Not by the
// text:query or the regex in it - those are what the tests assert, so a search that sent neither would
// show here as a wait for its request rather than as another query captured in its place
async function searched(page, text) {
    const query = page.waitForRequest(request => request.method() === 'POST'
        && (request.headers()['content-type'] ?? '').startsWith('application/sparql-query')
        && /SELECT\s+DISTINCT\s+\?resource\b/.test(request.postData() ?? ''));
    await search(page).fill(text);
    await search(page).press('Enter');
    return (await query).postData();
}

test('asks the text index where the service declares it', { tag: '@owner' }, async ({ page }) => {
    await goto(page, fixtures.container);
    await openDrawer(page);

    const query = await searched(page, 'Fixt');

    expect(query).toContain(TEXT_QUERY);
    expect(query).not.toMatch(/regex\s*\(/i);
    await expect(dialog(page)).toBeVisible();
    await expect(listTitles(dialog(page)).filter({ hasText: itemTitle(1) }).first()).toBeVisible({ timeout: 30_000 });
});

test('matches each word as a prefix, in any order', { tag: '@owner' }, async ({ page }) => {
    await goto(page, fixtures.container);
    await openDrawer(page);

    await searched(page, 'test ui');
    await expect(listTitles(dialog(page)).filter({ hasText: containerTitle }).first()).toBeVisible({ timeout: 30_000 });

    // inside a word is not a prefix: the index does not find it, where the regex would have
    const field = dialog(page).locator('input[name="q"]').first();
    await field.fill('ixture');
    await field.press('Enter');
    await expect(dialog(page)).toContainText('No results', { timeout: 30_000 });
    await expect(listTitles(dialog(page))).toHaveCount(0);
});

test('keeps the regex where the service declares no index', { tag: '@owner' }, async ({ page }) => {
    await goto(page, adminBase);
    await openDrawer(page);

    const query = await searched(page, 'Fixt');

    expect(query).toMatch(/regex\s*\(/i);
    expect(query).not.toContain(TEXT_QUERY);
});
