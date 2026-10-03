// The version history dialog: the TimeMap of a versioned document, opened from the action bar's
// timestamp, with Compare (a From/To pair) and Restore (a point action on one version).
//
// Restore writes a version back to the LIVE document, conditionally: the PUT quotes an entity tag
// so a restore cannot silently discard what was written since the history was read. Which tag it
// quotes is the thing asserted here, from both places the dialog can be opened - the live document,
// and a historical version (?version=<sha>) the agent navigated to by comparing or by following a
// version link. A historical version's ETag is its commit SHA, which never matches the live
// document, so a restore that quoted the page it was pressed from would be refused 412.
//
// Needs graph versioning configured for the root dataspace (lds:versioningRepository in
// config/system.trig, plus the credentials secret); without it the document has no TimeMap and
// the specs skip.
import { test, expect } from '../../../lib/console.mjs';
import { goto } from '../../../lib/settle.mjs';
import { ldh } from '../../../lib/fixtures.mjs';
import { endUserBase } from '../../../lib/stack.mjs';

// A document of its own rather than a fixture item: every write to it is a commit, and a restore
// is a write - the shared fixtures would accumulate history across runs.
const slug = 'ui-fixtures-versioned';
const doc = `${endUserBase}${slug}/`;
const titles = ['Versioned one', 'Versioned two', 'Versioned three'];

const historyModal = page => page.locator('#document-history-modal');
const versionRows = page => historyModal(page).locator('tr').filter({ has: page.locator('input[type=radio]') });

const mementoCount = async () => {
    const { code, stdout } = await ldh(['get', '--timemap', '--accept', 'application/link-format', doc], { allowFailure: true });
    return code === 0 ? (stdout.match(/rel="[^"]*\bmemento\b[^"]*"/g) ?? []).length : 0;
};

// The live document's validator, for the If-Match a restore should quote. Per representation,
// so asked for in the RDF/XML the client writes with.
const liveEtag = async () => {
    const { stdout } = await ldh(['get', '--head', '--accept', 'application/rdf+xml', doc]);
    return stdout.match(/^ETag:\s*(.+)$/mi)?.[1].trim();
};

const storedTitle = async () => {
    const { stdout } = await ldh(['get', '--accept', 'application/n-triples', doc]);
    return titles.find(t => stdout.includes(`"${t}"`));
};

test.describe.configure({ mode: 'serial' });

test.beforeAll(async () => {
    test.setTimeout(120_000);
    await ldh(['delete', doc], { allowFailure: true });
    await ldh(['create', 'item', '--container', endUserBase, '--title', titles[0], '--slug', slug]);
    for (const [previous, title] of [[titles[0], titles[1]], [titles[1], titles[2]]]) {
        const { stdout } = await ldh(['get', '--accept', 'text/turtle', doc]);
        await ldh(['put', '-t', 'text/turtle', doc], { stdin: stdout.replace(JSON.stringify(previous), JSON.stringify(title)) });
    }
    // Commits are asynchronous and chained per path, so the TimeMap fills in behind the writes.
    const deadline = Date.now() + 60_000;
    while (await mementoCount() < 3 && Date.now() < deadline) await new Promise(r => setTimeout(r, 2000));
});

test.afterAll(async () => {
    if (!process.env.UI_TESTS_KEEP_FIXTURES) await ldh(['delete', doc], { allowFailure: true });
});

test.beforeEach(async () => {
    test.skip(await mementoCount() < 3, `${doc} has no version history: graph versioning is not configured on this stack`);
});

// Opens the dialog and waits for the rows, which arrive with the TimeMap after the modal shell.
async function openHistory(page) {
    await page.locator('a.document-history').first().click();
    await expect(versionRows(page).first()).toBeVisible();
    return historyModal(page);
}

// Presses Restore on the oldest version and returns the PUT it sent. window.confirm() is answered
// in the page: the suite's page fixture dismisses every dialog as noise, which would cancel it.
async function restoreOldest(page) {
    const modal = await openHistory(page);
    await page.evaluate(() => { window.confirm = () => true; });
    const put = page.waitForResponse(r => r.request().method() === 'PUT' && r.url().startsWith(doc));
    await versionRows(page).last().locator('button.btn-restore').click();
    const response = await put;
    return { modal, response, ifMatch: await response.request().headerValue('if-match') };
}

test('restores a version from the live document', { tag: '@owner' }, async ({ page }) => {
    await goto(page, doc);
    const etag = await liveEtag();
    const { modal, response, ifMatch } = await restoreOldest(page);

    expect(ifMatch, 'the restore quotes the live document\'s ETag').toBe(etag);
    expect(response.status()).toBeLessThan(300);
    await expect(modal).toHaveCount(0);
    expect(await storedTitle()).toBe(titles[0]);
});

test('restores a version from a historical version', { tag: '@owner' }, async ({ page }) => {
    await goto(page, doc);
    // Compare oldest -> newest, which lands on the newest memento with a ?diff= alongside.
    await openHistory(page);
    await versionRows(page).last().locator('input[name=from]').check();
    await versionRows(page).first().locator('input[name=to]').check();
    await historyModal(page).locator('button').filter({ hasText: /Compare/ }).click();
    await page.waitForURL(/[?&]version=/);
    await expect(page.getByText(/read-only historical version/i)).toBeVisible();

    const etag = await liveEtag();
    const { modal, response, ifMatch } = await restoreOldest(page);

    expect(ifMatch, 'the restore quotes the live document\'s ETag, not the displayed version\'s').toBe(etag);
    expect(response.status()).toBeLessThan(300);
    await expect(modal).toHaveCount(0);
});
