// An action of the document itself, in its Actions menu: the messaging package's "Accept messages", which the
// dataspace's root offers (def:Root ldh:action). It creates the inbox, advertises it on the root with ldp:inbox and
// grants every authenticated agent acl:Append on it - three writes, the last into the admin dataspace and so flagged.
//
// As for every action, nothing is written until the reader confirms: the dialog lists the writes, Cancel leaves the
// dataspace as it was, Confirm applies them. Then the inbox can be added to and not read by anyone the grant does not
// name - an anonymous reader is refused.
//
// Needs an executor beside the instance, as delete-concept.spec.mjs does.
import { test, expect } from '../../../lib/console.mjs';
import { goto } from '../../../lib/settle.mjs';
import { get } from '../../../lib/http.mjs';
import { LDP, executorAdvertised, importMessaging, inboxClass, local, modal, openDocumentAction, teardownMessaging, triples, writes } from '../../../lib/messaging.mjs';

const ACL = 'http://www.w3.org/ns/auth/acl#';
const writeFor = (page, method, uri) => writes(page).and(page.locator(`[data-method="${method}"]`)).filter({ has: page.locator(`a[href="${uri}"]`) });

test.describe('accept messages', { tag: '@owner' }, () => {
    test.beforeEach(({}, testInfo) => {
        test.skip(testInfo.project.name !== 'owner', 'an action changes data, which the fixtures grant the owner alone');
    });

    test.beforeAll(async () => {
        test.skip(!await executorAdvertised(), 'the dataspace advertises no executor (lds:assistant), so the platform offers no actions');
        test.setTimeout(240_000); // a first import composes the package stylesheet
        await importMessaging();
    });

    test.beforeEach(async () => {
        await teardownMessaging(local);
    });

    test.afterEach(async () => {
        await teardownMessaging(local);
    });

    test('lists the inbox, the root and the grant, and changes nothing until confirmed', async ({ page }) => {
        await goto(page, local.base);
        await openDocumentAction(page, 'Accept messages');

        await expect(writes(page)).toHaveCount(3);
        await expect(writeFor(page, 'PUT', local.inbox)).toHaveCount(1);
        await expect(writeFor(page, 'PUT', local.inbox).locator('.ldh-action-verb')).toHaveText('Create');
        await expect(writeFor(page, 'PATCH', local.base)).toHaveCount(1);
        await expect(writeFor(page, 'PATCH', local.base).locator('.ldh-action-verb')).toHaveText('Update');
        // the grant is access control: flagged, and still allowed
        await expect(writeFor(page, 'PUT', local.authorization)).toHaveClass(/is-flagged/);
        await expect(modal(page).locator('li.is-danger')).toHaveCount(0);
        await expect(modal(page).locator('button.btn-action-confirm')).toBeVisible();

        await modal(page).locator('button.btn-close').click();
        await expect(modal(page)).toHaveCount(0);

        expect(await triples(local, local.base)).not.toContain(`<${LDP}inbox>`);
        const { code } = await local.ldh(['get', '--accept', 'application/n-triples', local.inbox], { allowFailure: true });
        expect(code, 'the inbox should not exist after a cancelled dry run').not.toBe(0);
    });

    test('once confirmed, the root advertises an inbox anyone authenticated may add to and nobody else may read', async ({ page }) => {
        await goto(page, local.base);
        await openDocumentAction(page, 'Accept messages');
        await modal(page).locator('button.btn-action-confirm').click();
        await expect(modal(page)).toHaveCount(0);

        expect(await triples(local, local.base)).toContain(`<${local.base}> <${LDP}inbox> <${local.inbox}>`);
        expect(await triples(local, local.inbox)).toContain(`<${local.inbox}#this> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <${inboxClass}>`);

        const grant = await triples(local, local.authorization);
        expect(grant).toContain(`<${ACL}accessTo> <${local.inbox}>`);
        expect(grant).toContain(`<${ACL}mode> <${ACL}Append>`);
        expect(grant).toContain(`<${ACL}agentClass> <${ACL}AuthenticatedAgent>`);

        // Append is not Read
        const { status } = await get(local.inbox, { headers: { Accept: 'application/n-triples' } });
        expect(status).toBe(403);
    });
});
