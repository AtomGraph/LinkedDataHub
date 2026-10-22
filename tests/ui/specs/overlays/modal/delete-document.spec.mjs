// The delete dialog: deleting the document is asked in a dialog opened from the action bar's
// overflow menu, and a refusal is told in that dialog, never in the document's content. A container
// that still has documents is refused (409, like rmdir), and the dialog stays open saying so.
import { test, expect } from '../../../lib/console.mjs';
import { goto, settled } from '../../../lib/settle.mjs';
import { ldh } from '../../../lib/fixtures.mjs';
import { endUserBase } from '../../../lib/stack.mjs';

// Documents of their own: one spec deletes what it opens, which no shared fixture may be.
const container = `${endUserBase}ui-fixtures-delete/`;
const child = `${container}child/`;

const deleteModal = page => page.locator('div.modal.modal-delete');
const contentBody = page => page.locator('div.ldh-pane.is-active div.content-body').first();

async function openDeleteDialog(page) {
    await page.locator('div.ldh-of-wrap button.drop-toggle').first().click();
    await page.locator('div.ldh-of-menu button.btn-delete').first().click();
    await expect(deleteModal(page)).toBeVisible();
    return deleteModal(page);
}

const exists = async uri => (await ldh(['get', '--accept', 'application/n-triples', uri], { allowFailure: true })).code === 0;

test.describe.configure({ mode: 'serial' });

test.beforeEach(({}, testInfo) => {
    test.skip(testInfo.project.name !== 'owner', 'only an agent with acl:Write is offered Delete');
});

test.beforeAll(async () => {
    await ldh(['delete', child], { allowFailure: true });
    await ldh(['delete', container], { allowFailure: true });
    await ldh(['create', 'container', '--parent', endUserBase, '--title', 'Delete fixture', '--slug', 'ui-fixtures-delete']);
    await ldh(['create', 'item', '--container', container, '--title', 'Delete fixture child', '--slug', 'child']);
});

test.afterAll(async () => {
    await ldh(['delete', child], { allowFailure: true });
    await ldh(['delete', container], { allowFailure: true });
});

test('asks in a dialog, and Close leaves the document as it was', { tag: '@owner' }, async ({ page }) => {
    await goto(page, child);
    await settled(page);

    const modal = await openDeleteDialog(page);
    await expect(modal.locator('.ac-modal-title')).toHaveText('Delete this document?');
    await expect(modal.locator('.ac-modal-sub')).toHaveText(child);

    await modal.locator('button.btn-close').click();
    await expect(deleteModal(page)).toHaveCount(0);
    expect(await exists(child)).toBe(true);
});

test('a container with documents is refused in the dialog, not on the page', { tag: '@owner' }, async ({ page, allowNoise }) => {
    allowNoise.push(
        { pattern: /^HTTP 409: https:\/\/[^/]+\/ui-fixtures-delete\/$/, reason: 'the delete is refused on purpose' },
        { pattern: /^console\.error: Failed to load resource: .* 409 /, reason: 'the browser\'s own line for the same refusal' });
    await goto(page, container);
    await settled(page);

    const modal = await openDeleteDialog(page);
    const response = page.waitForResponse(r => r.request().method() === 'DELETE' && r.url().startsWith(container));
    await modal.locator('button.btn-confirm-delete').click();
    expect((await response).status()).toBe(409);

    const form = modal.locator('form.ldh-delete-form');
    await expect(form).toContainText('This container still has documents. Delete them first.');
    await expect(deleteModal(page)).toBeVisible();
    await expect(contentBody(page).locator('.ldh-failure')).toHaveCount(0);
    expect(await exists(container)).toBe(true);
});

test('an empty document is deleted, and the page moves to its container', { tag: '@owner' }, async ({ page }) => {
    await goto(page, child);
    await settled(page);

    const modal = await openDeleteDialog(page);
    const response = page.waitForResponse(r => r.request().method() === 'DELETE' && r.url().startsWith(child));
    await modal.locator('button.btn-confirm-delete').click();
    expect((await response).status()).toBe(204);

    await expect(deleteModal(page)).toHaveCount(0);
    await expect(page).toHaveURL(container);
    expect(await exists(child)).toBe(false);
});
