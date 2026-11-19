// The messaging package's fixtures: its import, two instances' inboxes, and the CLI as either instance's owner.
//
// Messages cross INSTANCES, not dataspaces: a sender's dataspace writes into the recipient's inbox through its own
// Linked Data proxy, vouching for the reader with its secretary's certificate (On-Behalf-Of), and the recipient's
// server checks that delegation against the reader's WebID. Two dataspaces of one instance would never exercise it.
// So the recipient is the http-tests stack's second instance (tests/http/docker-compose.http-tests.yml,
// linkeddatahub-remote), named by its own variables - not by REMOTE_END_USER_BASE_URL, which lib/stack.mjs resolves
// to a second dataspace of THIS instance and the generic fixtures seed as this instance's owner.
//
//   REMOTE_OWNER_CERT_KEYSTORE   the second instance's owner keystore (tests/http/remote/ssl/owner/keystore.p12);
//                                unset, the federated specs skip. Its password is this instance's owner's (run.sh)
//   REMOTE_INSTANCE_BASE_URL     its end-user base, https://remote.localhost:4443/ by default
//   REMOTE_INSTANCE_ADMIN_BASE_URL  its admin base, admin. on the same host by default
import { X509Certificate } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { expect } from '@playwright/test';
import { get } from './http.mjs';
import { ldh } from './fixtures.mjs';
import { adminBase, endUserBase, ownerKeystore, ownerPassword, repoRoot } from './stack.mjs';
import { packagesBase, waitForPackageStylesheet } from './taxonomy.mjs';

export const LDP = 'http://www.w3.org/ns/ldp#';
export const AS = 'https://www.w3.org/ns/activitystreams#';
const ACL = 'http://www.w3.org/ns/auth/acl#';
const FOAF = 'http://xmlns.com/foaf/0.1/';
const RDF_TYPE = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type';

// The package under test, imported from the fixture registry tests/packages, which lib/taxonomy.mjs publishes.
export const messagingPackage = `${packagesBase}messaging/#this`;
// The class the package names an inbox, as the registry publishes its ontology (ns/#).
export const inboxClass = `${packagesBase}messaging/ns/#Inbox`;

// The authorization the Accept messages action writes, by the slug the CLI fixtures use too, so either cleans up after
// the other; and the public read of the root a sender needs to find the inbox.
const appendSlug = 'inbox-append';
const publicRootSlug = 'messaging-public-root';

// The WebID a keystore's certificate names: read from the PEM beside it, as tests/http/run.sh reads OWNER_URI.
export function webIdOf(keystore) {
    const pem = readFileSync(join(dirname(keystore), 'cert.pem'), 'utf8')
        .match(/-----BEGIN CERTIFICATE-----[\s\S]+?-----END CERTIFICATE-----/)[0];
    return new X509Certificate(pem).subjectAltName.replace(/^URI:/, '').split(',')[0].trim();
}

// One instance as the specs address it: its bases, and the CLI as its owner.
function instance({ base, admin, keystore }) {
    return {
        base,
        admin,
        keystore,
        inbox: `${base}inbox/`,
        authorization: `${admin}acl/authorizations/${appendSlug}/`,
        publicRoot: `${admin}acl/authorizations/${publicRootSlug}/`,
        owner: () => webIdOf(keystore),
        ldh: (args, options = {}) => ldh(args, {
            ...options,
            env: { LDH_CERT_FILE: keystore, LDH_CERT_PASSWORD: ownerPassword(), LDH_BASE: base },
        }),
    };
}

// A: the instance the browser drives.
export const local = instance({ base: endUserBase, admin: adminBase, keystore: ownerKeystore });

// B: the second instance, or nothing when the stack has none.
export const remoteKeystore = process.env.REMOTE_OWNER_CERT_KEYSTORE;
const remoteBase = process.env.REMOTE_INSTANCE_BASE_URL ?? 'https://remote.localhost:4443/';
const remoteAdmin = process.env.REMOTE_INSTANCE_ADMIN_BASE_URL ?? (() => {
    const url = new URL(remoteBase);
    return `${url.protocol}//admin.${url.host}/`;
})();
export const remote = remoteKeystore ? instance({ base: remoteBase, admin: remoteAdmin, keystore: remoteKeystore }) : null;

// The CLI as B's owner.
export function remoteLdh(args, options) {
    if (!remote) throw new Error('REMOTE_OWNER_CERT_KEYSTORE is not set: there is no second instance to address');
    return remote.ldh(args, options);
}

// Whether the dataspace runs an executor (lds:assistant in its public /context): without one the platform offers no
// actions, and the specs say so rather than fail.
export async function executorAdvertised() {
    const { body } = await get(`${endUserBase}context`, { headers: { Accept: 'application/n-triples' } });
    return body.toString().includes('<https://w3id.org/atomgraph/linkeddatahub/dataspaces#assistant> "true"');
}

async function packageInstalled() {
    const { stdout } = await ldh(['packages', 'list', '--registry', packagesBase]);
    return stdout.split('\n').some(line => {
        const [state, uri] = line.split('\t');
        return state === 'installed' && uri === messagingPackage;
    });
}

// Recorded so teardown removes only what this run added (lib/taxonomy.mjs does the same for its package).
let addedPackage = false;

// Imports the package into A, from the fixture registry: published, added to the settings, the ontology closure
// cleared so /ns answers with the package's actions, and the composed stylesheet waited for, since the import set
// is part of its key. Idempotent: an imported package is left as it is.
export async function importMessaging({ publish = false } = {}) {
    if (publish) {
        execFileSync(join(repoRoot, 'tests/packages/publish.sh'), [packagesBase, ownerKeystore, ownerPassword()],
            { stdio: ['ignore', 'ignore', 'inherit'] });
    }
    if (await packageInstalled()) return false;

    await ldh(['packages', 'add', '--package', messagingPackage]);
    addedPackage = true;
    await ldh(['admin', 'clear', 'ontology', adminBase]);
    await waitForPackageStylesheet();
    return true;
}

export async function removeMessaging() {
    if (!addedPackage) return;
    await ldh(['packages', 'remove', '--package', messagingPackage], { allowFailure: true });
    addedPackage = false;
}

// N-Triples of a document as an instance's owner, or '' when it cannot be read.
export async function triples(on, uri) {
    const { stdout } = await on.ldh(['get', '--accept', 'application/n-triples', uri], { allowFailure: true });
    return stdout;
}

// The documents an instance's inbox holds, read from its data: the documents whose container it is.
export async function inboxChildren(on) {
    const query = `SELECT DISTINCT ?doc WHERE { GRAPH ?doc { ?doc <http://rdfs.org/sioc/ns#has_container> <${on.inbox}> } }`;
    const { code, stdout } = await on.ldh(['get', '--accept', 'application/sparql-results+json',
        `${on.base}sparql?query=${encodeURIComponent(query)}`], { allowFailure: true });
    if (code !== 0 || !stdout) return [];
    return JSON.parse(stdout).results.bindings.map(binding => binding.doc.value);
}

// What the Accept messages action does, done by the CLI as the instance's owner: the inbox, typed as the package's
// inbox class, the root's ldp:inbox link, and acl:Append on the inbox for every authenticated agent. With `publicRoot`,
// also a read of the root for anyone, which a sender needs to find the inbox (Linked Data Notifications assume it).
export async function acceptOn(on, { publicRoot = false } = {}) {
    await on.ldh(['create', 'container', '--parent', on.base, '--title', 'Inbox', '--slug', 'inbox',
        '--primary-topic', '#this', '--if-absent']);
    await on.ldh(['patch', on.inbox], { stdin: `INSERT { <${on.inbox}#this> a <${inboxClass}> } WHERE {}` });
    await on.ldh(['patch', on.base], { stdin: `INSERT { <${on.base}> <${LDP}inbox> <${on.inbox}> } WHERE {}` });
    await on.ldh(['admin', 'create', 'authorization',
        '--label', 'Inbox: anyone authenticated may add', '--slug', appendSlug,
        '--agent-class', `${ACL}AuthenticatedAgent`,
        '--to', on.inbox,
        '--append',
        on.base]);
    if (publicRoot) {
        await on.ldh(['admin', 'create', 'authorization',
            '--label', 'Messaging: anyone may read the root, for its inbox', '--slug', publicRootSlug,
            '--agent-class', `${FOAF}Agent`,
            '--to', on.base,
            '--read',
            on.base]);
    }
}

// B accepts messages, and lets anyone read its root to find the inbox.
export function acceptOnRemote() {
    return acceptOn(remote, { publicRoot: true });
}

// Everything accepting and messaging left on an instance: the messages, the inbox, the grants and the root's link.
export async function teardownMessaging(on) {
    if (!on) return;
    for (const doc of await inboxChildren(on)) {
        await on.ldh(['delete', doc], { allowFailure: true });
    }
    await on.ldh(['delete', on.inbox], { allowFailure: true });
    await on.ldh(['delete', on.authorization], { allowFailure: true });
    await on.ldh(['delete', on.publicRoot], { allowFailure: true });
    await on.ldh(['patch', on.base], { stdin: `DELETE WHERE { <${on.base}> <${LDP}inbox> ?inbox }`, allowFailure: true });
}

// A message as it arrives, written into an instance's inbox as its owner: the copy Send message writes, with the
// inbox a reply goes to. The server stamps dct:creator with whoever writes it, so a copy seeded this way names the
// instance's own owner as its sender.
export async function seedMessage(on, { slug, subject, content, replyTo, to = on.base }) {
    const doc = `${on.inbox}${slug}/`;
    const note = `${doc}#note`;
    const now = new Date().toISOString();
    await on.ldh(['create', 'item', '--container', on.inbox, '--title', subject, '--slug', slug, '--primary-topic', '#note']);
    await on.ldh(['patch', doc], {
        stdin: `INSERT {
  <${note}> <${RDF_TYPE}> <${AS}Note> ;
    <${AS}name> ${JSON.stringify(subject)} ;
    <${AS}content> ${JSON.stringify(content)} ;
    <${AS}to> <${to}> ;
    <${AS}published> "${now}"^^<http://www.w3.org/2001/XMLSchema#dateTime> ;
    <${LDP}inbox> <${replyTo}> .
} WHERE {}`,
    });
    return { doc, note };
}

// The document's Actions menu in the active pane (ac:HeaderActions), with the actions of the document and its topic at
// its end; the action dialog and its parts.
export const documentMenu = page => page.locator('div.ldh-pane.is-active div.ldh-actions > div.ldh-of-wrap')
    .filter({ has: page.locator('button.btn-delete') });
export const modal = page => page.locator('div.modal.modal-action');
export const argument = (page, name) => modal(page).locator(`div.ldh-action-arg[data-name="${name}"]`);
export const writes = page => modal(page).locator('ul.ldh-action-writes > li');

// Clicks the named action in the open document's Actions menu and waits for its dialog.
export async function openDocumentAction(page, title) {
    const menu = documentMenu(page);
    const item = menu.locator('button.btn-action.ldh-doc-action', { hasText: title });
    // the document's actions arrive once the page has rendered, from a /ns query of their own
    await expect(item).toHaveCount(1, { timeout: 20_000 });
    await menu.locator('button.drop-toggle').click();
    await item.click();
    await expect(modal(page)).toBeVisible();
}
