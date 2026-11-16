// An action that writes to another instance: the messaging package's "Send message", offered by an inbox (its topic is
// of the package's inbox class). It reads the recipient's root through this dataspace's proxy for the inbox it
// advertises (ldp:inbox) and writes the message there as a document of its own - through the proxy again, so the
// recipient's server sees this dataspace's secretary acting on the reader's behalf (On-Behalf-Of) and records the
// reader as the document's creator.
//
// The arguments come first: the recipient as an address, the subject and the message as text areas. The dry run then
// lists the one write as "Send to" its target in the recipient's inbox, flagged as delivered on the reader's behalf -
// the platform's policy for a proxied write, read off the request URL.
//
// Needs an executor beside the instance, and the http-tests stack's second instance (lib/messaging.mjs): without
// REMOTE_OWNER_CERT_KEYSTORE the spec skips.
import { test, expect } from '../../../lib/console.mjs';
import { goto } from '../../../lib/settle.mjs';
import { AS, LDP, acceptOn, acceptOnRemote, argument, executorAdvertised, importMessaging, inboxChildren, local, modal, openDocumentAction, remote, teardownMessaging, triples, writes } from '../../../lib/messaging.mjs';

const DCT = 'http://purl.org/dc/terms/';
const subject = 'Lunch on Friday';
const content = 'Are you free on Friday?\n\nThe usual place, at noon.';

test.describe('send message', { tag: '@owner' }, () => {
    test.beforeEach(({}, testInfo) => {
        test.skip(testInfo.project.name !== 'owner', 'an action changes data, which the fixtures grant the owner alone');
    });

    test.beforeAll(async () => {
        test.skip(!await executorAdvertised(), 'the dataspace advertises no executor (lds:assistant), so the platform offers no actions');
        test.skip(!remote, 'REMOTE_OWNER_CERT_KEYSTORE is not set, so there is no second instance to send to');
        test.setTimeout(240_000); // a first import composes the package stylesheet
        await importMessaging();
    });

    // A has an inbox to send from (and for a reply to come back to); B accepts messages and lets anyone read its root
    test.beforeEach(async () => {
        await teardownMessaging(local);
        await teardownMessaging(remote);
        await acceptOn(local);
        await acceptOnRemote();
    });

    test.afterEach(async () => {
        await teardownMessaging(local);
        await teardownMessaging(remote);
    });

    test('asks for the recipient and the message, shows the one write as sent to the recipient\'s inbox, and delivers it once confirmed', async ({ page }) => {
        await goto(page, local.inbox);
        await openDocumentAction(page, 'Send message');

        // the arguments, each by its datatype: an address, and text areas for the text
        await expect(argument(page, 'to').locator('input[type="url"]')).toHaveCount(1);
        await expect(argument(page, 'subject').locator('textarea')).toHaveCount(1);
        await expect(argument(page, 'content').locator('textarea')).toHaveCount(1);
        await argument(page, 'to').locator('input[type="url"]').fill(remote.base);
        await argument(page, 'subject').locator('textarea').fill(subject);
        await argument(page, 'content').locator('textarea').fill(content);
        await modal(page).locator('button.btn-action-preview').click();

        // one write, sent to a new document in B's inbox, on the reader's behalf
        await expect(writes(page)).toHaveCount(1);
        const write = writes(page).first();
        await expect(write.locator('.ldh-action-verb')).toHaveText('Send to');
        await expect(write).toHaveClass(/is-flagged/);
        await expect(write.locator('a')).toHaveAttribute('href', new RegExp('^' + remote.inbox.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')));
        await expect(modal(page).locator('li.is-danger')).toHaveCount(0);

        // a dry run: B's inbox is still empty
        expect(await inboxChildren(remote)).toEqual([]);

        await modal(page).locator('button.btn-action-confirm').click();
        await expect(modal(page)).toHaveCount(0);

        const delivered = await inboxChildren(remote);
        expect(delivered).toHaveLength(1);
        const copy = await triples(remote, delivered[0]);
        expect(copy).toContain(`<${AS}Note>`);
        expect(copy).toContain(`<${AS}content> ${JSON.stringify(content)}`);
        // where a reply goes: A's inbox
        expect(copy).toContain(`<${LDP}inbox> <${local.inbox}>`);
        // who sent it, as B's server recorded the delegated writer
        expect(copy).toContain(`<${delivered[0]}> <${DCT}creator> <${local.owner()}>`);
    });

    test('refuses a recipient that advertises no inbox', async ({ page }) => {
        // B's root stays readable, and no longer names an inbox
        await remote.ldh(['patch', remote.base], { stdin: `DELETE WHERE { <${remote.base}> <${LDP}inbox> ?inbox }` });

        await goto(page, local.inbox);
        await openDocumentAction(page, 'Send message');
        await argument(page, 'to').locator('input[type="url"]').fill(remote.base);
        await argument(page, 'subject').locator('textarea').fill(subject);
        await argument(page, 'content').locator('textarea').fill(content);
        await modal(page).locator('button.btn-action-preview').click();

        // the plan stopped before any write: nothing to confirm
        await expect(modal(page).locator('button.btn-action-confirm')).toHaveCount(0);
        await expect(writes(page)).toHaveCount(0);
        expect(await inboxChildren(remote)).toEqual([]);
    });
});
