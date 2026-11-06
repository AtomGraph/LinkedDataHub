// A proxied document's version history acts on that document, through the proxy.
//
// The proxy forwards the origin's Link headers as they are, so a remote document decides whether the History link
// shows (rel="timemap") and which TimeMap it opens. The history read the access modes of the page's path and restored
// into it: on a proxied page that is the dataspace's root, which the owner may write, so Restore put the remote's
// version over the root (formal/client, restore_targets_page_path, now restore_targets_pane_document). The TimeMap and
// the version were requested from the remote's origin directly.
//
// The remote is played by routes: the proxied document, its TimeMap and its version are fulfilled by the spec, and
// every write is aborted and recorded, so the spec changes nothing. Owner-only: the defect needed someone who may
// write the root.
import { test, expect } from '../../lib/console.mjs';
import { goto } from '../../lib/settle.mjs';
import { endUserBase } from '../../lib/stack.mjs';

const DOC = 'https://evil.example/doc';
const RDF = 'application/rdf+xml';
const NS = 'xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:dct="http://purl.org/dc/terms/" xmlns:prov="http://www.w3.org/ns/prov#"';
const DATETIME = 'http://www.w3.org/2001/XMLSchema#dateTime';
const document = `<rdf:RDF ${NS}><rdf:Description rdf:about="${DOC}"><dct:title>Remote document</dct:title><dct:modified rdf:datatype="${DATETIME}">2026-11-01T10:00:00Z</dct:modified></rdf:Description></rdf:RDF>`;
const memento = n => `<rdf:Description rdf:about="${DOC}?version=${n}"><prov:specializationOf rdf:resource="${DOC}"/><prov:generatedAtTime rdf:datatype="${DATETIME}">2026-11-0${n}T10:00:00Z</prov:generatedAtTime></rdf:Description>`;
const timemap = `<rdf:RDF ${NS}>${memento(1)}${memento(2)}</rdf:RDF>`;
const version = `<rdf:RDF ${NS}><rdf:Description rdf:about="${DOC}"><dct:title>The remote's version</dct:title></rdf:Description></rdf:RDF>`;
// the remote claims Write, so that Restore is offered: what it can do with it is write the remote
const links = `<${DOC}?timemap>; rel="timemap", <http://www.w3.org/ns/auth/acl#Read>; rel="http://www.w3.org/ns/auth/acl#mode", <http://www.w3.org/ns/auth/acl#Write>; rel="http://www.w3.org/ns/auth/acl#mode"`;

test('restores a proxied document\'s version into that document, through the proxy', { tag: '@owner' }, async ({ page, allowNoise }) => {
    allowNoise.push(
        { pattern: /^console\.error: Failed to load resource: net::ERR_FAILED$/, reason: 'the spec aborts the restore\'s write' });
    const writes = [];
    const direct = [];
    await page.route('**/*', route => {
        const request = route.request();
        const url = new URL(request.url());
        if (url.origin === new URL(DOC).origin) {
            direct.push(`${request.method()} ${request.url()}`);
            return route.abort();
        }
        if (['PUT', 'PATCH', 'DELETE'].includes(request.method())) {
            writes.push({ method: request.method(), url: request.url() });
            return route.abort();
        }
        const proxied = url.searchParams.get('uri');
        if (proxied === `${DOC}?timemap`) return route.fulfill({ status: 200, contentType: RDF, body: timemap });
        if (proxied?.startsWith(`${DOC}?version=`)) return route.fulfill({ status: 200, contentType: RDF, body: version });
        if (proxied === DOC && (request.headers()['accept'] ?? '').includes('rdf')) {
            return route.fulfill({ status: 200, contentType: RDF, body: document, headers: { link: links } });
        }
        return route.fallback();
    });

    await goto(page, '/?uri=' + encodeURIComponent(DOC));
    await page.locator('#tab-content > div.ldh-pane.is-active a.document-history').click();
    const restore = page.locator('#document-history-modal button.btn-restore');
    await expect(restore).toHaveCount(1);
    // answered in the page: the suite's page fixture dismisses every dialog as noise, which would cancel it
    await page.evaluate(() => { window.confirm = () => true; });
    await restore.click();

    // the route records the write after the request event, so the list is polled rather than read once
    await expect.poll(() => writes.map(({ method, url }) => `${method} ${url}`)).toEqual([`PUT ${endUserBase}?uri=${encodeURIComponent(DOC)}`]);
    expect(direct).toEqual([]);
});
