// An action of a document's topic: the messaging package's "Reply", offered by a note (as:Note ldh:action) on its
// message page, where the note is the page's foaf:primaryTopic. It writes a note answering this one into the inbox the
// note names (ldp:inbox) - another instance's, through this dataspace's proxy on the reader's behalf - with the subject
// prefixed "Re: ", the answered note as its as:inReplyTo, and this dataspace's own inbox for the answer.
//
// The message replied to is seeded into A's inbox by the CLI, as Send message would have delivered it from B: a note
// whose ldp:inbox is B's. A's server stamps the copy's dct:creator with whoever writes it, so the seeded copy names
// A's owner as its sender; what this spec asserts is where the reply goes and what it answers, which that does not
// change.
//
// Needs an executor beside the instance, and the http-tests stack's second instance (lib/messaging.mjs): without
// REMOTE_OWNER_CERT_KEYSTORE the spec skips.
import { test, expect } from '../../../lib/console.mjs';
import { goto } from '../../../lib/settle.mjs';
import { AS, LDP, acceptOn, acceptOnRemote, argument, executorAdvertised, importMessaging, inboxChildren, local, modal, openDocumentAction, remote, seedMessage, teardownMessaging, triples, writes } from '../../../lib/messaging.mjs';

const subject = 'Lunch on Friday';
const answer = 'Friday works. See you at noon.';

test.describe('reply', { tag: '@owner' }, () => {
    test.beforeEach(({}, testInfo) => {
        test.skip(testInfo.project.name !== 'owner', 'an action changes data, which the fixtures grant the owner alone');
    });

    test.beforeAll(async () => {
        test.skip(!await executorAdvertised(), 'the dataspace advertises no executor (lds:assistant), so the platform offers no actions');
        test.skip(!remote, 'REMOTE_OWNER_CERT_KEYSTORE is not set, so there is no second instance to reply to');
        test.setTimeout(240_000); // a first import composes the package stylesheet
        await importMessaging();
    });

    let message;
    test.beforeEach(async () => {
        await teardownMessaging(local);
        await teardownMessaging(remote);
        // A accepts messages, so the reply can name its inbox for the answer; B accepts the reply
        await acceptOn(local);
        await acceptOnRemote();
        message = await seedMessage(local, {
            slug: 'lunch', subject, content: 'Are you free on Friday?', replyTo: remote.inbox,
        });
    });

    test.afterEach(async () => {
        await teardownMessaging(local);
        await teardownMessaging(remote);
    });

    test('writes the answer into the inbox the note names, in reply to it', async ({ page }) => {
        await goto(page, message.doc);
        await openDocumentAction(page, 'Reply');

        await expect(argument(page, 'content').locator('textarea')).toHaveCount(1);
        await argument(page, 'content').locator('textarea').fill(answer);
        await modal(page).locator('button.btn-action-preview').click();

        // one write, sent to a new document in B's inbox
        await expect(writes(page)).toHaveCount(1);
        await expect(writes(page).first().locator('.ldh-action-verb')).toHaveText('Send to');
        await expect(writes(page).first().locator('a')).toHaveAttribute('href', new RegExp('^' + remote.inbox.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')));

        await modal(page).locator('button.btn-action-confirm').click();
        await expect(modal(page)).toHaveCount(0);

        const delivered = await inboxChildren(remote);
        expect(delivered).toHaveLength(1);
        const reply = await triples(remote, delivered[0]);
        expect(reply).toContain(`<${AS}inReplyTo> <${message.note}>`);
        expect(reply).toContain(`<${AS}name> "Re: ${subject}"`);
        expect(reply).toContain(`<${AS}content> ${JSON.stringify(answer)}`);
        // where an answer to the reply goes: A's inbox
        expect(reply).toContain(`<${LDP}inbox> <${local.inbox}>`);
    });
});
