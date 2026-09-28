// The file drop overlay: one gesture, two outcomes, told apart by media type.
//
// A file dropped on a document is either RDF, whose triples are appended to the document's graph,
// or anything else, which is uploaded - stored under uploads/ by its content hash and described in
// the document as an nfo:FileDataObject. The RDF case is decided first, by extension or by the
// browser's type, and everything that is not RDF falls through to the upload. So the claim to make
// about the fallback is that nothing about the file needs to be recognised for it to land.
//
// The overlay itself cannot tell which of the two a drag is - a drag carries no file names - so it
// says both, one lane each, and that is asserted as anatomy rather than as a prediction.
//
// Each test drops on a document of its own: a drop writes, and the seeded fixtures are read by
// every other spec. The write is checked at the API as well as on the page, because the page is
// re-rendered from the graph after the drop and could show a triple the server never stored.
import { createHash } from 'node:crypto';
import { test, expect } from '../../lib/console.mjs';
import { goto } from '../../lib/settle.mjs';
import { fixtures, ldh } from '../../lib/fixtures.mjs';
import { endUserBase } from '../../lib/stack.mjs';
import { dragIn, dropFile, fileTransfer } from '../../lib/file-drop.mjs';

const DCT = 'http://purl.org/dc/terms/';
const NFO = 'http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#';
const MEDIA_TYPE = 'http://www.sparontologies.net/mediatype/';

// A 1x1 transparent PNG. Small enough to inline, real enough that the browser will render the
// embed the read view makes of it.
const PNG = Buffer.from(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
    'base64');
// Bytes no sniffer would recognise, under a name no map knows.
const BLOB = Buffer.from([0x00, 0x01, 0x02, 0x03, 0xfe, 0xff, 0x10, 0x20]);

// The upload URI is content-addressed, so the spec can name it before the drop is made - the same
// way tests/http/imports/create-file.sh checks `ldh add file`.
const uploadUri = bytes => `${endUserBase}uploads/${createHash('sha1').update(bytes).digest('hex')}`;

const overlay = page => page.locator('#file-drop');
const lanes = page => overlay(page).locator('.ac-dropzone-lane');
const rowFor = (page, about) => page.locator(`div.ldh-block-row[about="${about}"]`);

// The document's graph, as N-Triples lines, straight from the API.
const triples = async doc => (await ldh(['get', '--accept', 'application/n-triples', doc])).stdout;

let doc;

// Declared before the fixture hook: hooks run in declaration order, so the skip lands before the CLI
// builds a document that a reader who may not write could not drop anything on.
test.beforeEach(({}, testInfo) => {
    test.skip(testInfo.project.name !== 'owner', 'the overlay mounts only for an agent who may write');
});

test.beforeEach(async ({ page }, testInfo) => {
    const created = await ldh(['create', 'item',
        '--container', fixtures.container, '--title', 'File drop fixture', '--slug', `file-drop-${testInfo.testId}`]);
    doc = created.stdout;
    await goto(page, doc);
});

test.afterEach(async () => {
    if (doc) await ldh(['delete', doc], { allowFailure: true });
});

test('says what a drop does, both ways', { tag: '@owner' }, async ({ page }) => {
    const transfer = await fileTransfer(page, { name: 'anything.bin', bytes: BLOB });
    await expect(overlay(page)).toHaveCount(0);

    await dragIn(page, transfer);
    await expect(overlay(page)).toBeVisible();

    // Two lanes, each led by the kit's Tag naming the kind. Only the RDF lane lists extensions,
    // because only for RDF is the extension what decides.
    await expect(lanes(page)).toHaveCount(2);
    await expect(lanes(page).locator('.ac-tag')).toHaveCount(2);
    await expect(lanes(page).nth(0).locator('.ac-tag')).toHaveText('RDF');
    await expect(lanes(page).nth(0).locator('.ac-dropzone-sub')).toContainText('.ttl');
    await expect(lanes(page).nth(1).locator('.ac-tag')).toHaveText('File');
    await expect(lanes(page).nth(1).locator('.ac-dropzone-sub')).toHaveCount(0);

    // A drag that ends anywhere takes the overlay with it: a stuck overlay covers the whole page.
    await page.dispatchEvent('body', 'dragend', { dataTransfer: transfer });
    await expect(overlay(page)).toHaveCount(0);
});

test('an RDF file is imported as triples', { tag: '@owner' }, async ({ page }) => {
    // About a resource of its own rather than the document: the document's own description is
    // hidden from the read view as a system resource, so a triple about it would land unseen.
    const dropped = `${doc}#dropped`;
    const turtle = `<${dropped}> <${DCT}title> "Dropped by the file drop" .\n`;

    await dropFile(page, { name: 'drop.ttl', type: 'text/turtle', bytes: Buffer.from(turtle) });

    // The import lands the reader in ReadMode, which is where the document's resources render.
    await expect(page).toHaveURL(/mode=.*ReadMode/);
    await expect(rowFor(page, dropped)).toBeVisible();
    await expect(rowFor(page, dropped)).toContainText('Dropped by the file drop');

    const graph = await triples(doc);
    expect(graph).toContain(`<${dropped}> <${DCT}title> "Dropped by the file drop" .`);
    // Imported, not uploaded: no file was made of it.
    expect(graph).not.toContain(`${NFO}FileDataObject`);
});

test('a binary file is uploaded', { tag: '@owner' }, async ({ page }) => {
    const file = uploadUri(PNG);

    await dropFile(page, { name: 'drop.png', type: 'image/png', bytes: PNG });

    await expect(page).toHaveURL(/mode=.*ReadMode/);
    // The file is a resource of this document, at its content-addressed URI, and the read view
    // embeds it by the media type the browser sent.
    await expect(rowFor(page, file)).toBeVisible();
    await expect(rowFor(page, file)).toContainText('drop.png');
    await expect(rowFor(page, file).locator('object[type="image/png"]')).toHaveAttribute('data', file);

    const graph = await triples(doc);
    expect(graph).toContain(`<${file}> <${NFO}fileName> "drop.png" .`);
    expect(graph).toContain(`<${file}> <${DCT}format> <${MEDIA_TYPE}image/png> .`);

    // The bytes are where the URI says, served as what they are. The request context carries the
    // owner's certificate, like the page does.
    const response = await page.request.get(file, { headers: { Accept: 'image/png' } });
    expect(response.status()).toBe(200);
    expect(response.headers()['content-type']).toBe('image/png');
    expect(Buffer.compare(await response.body(), PNG)).toBe(0);
});

// The fallback proper: a name no extension map knows and no type from the browser. Nothing about
// it is recognised, and it still lands - as a file, typed as the browser types the untyped.
test('an unrecognised file still uploads', { tag: '@owner' }, async ({ page }) => {
    const file = uploadUri(BLOB);

    await dropFile(page, { name: 'drop.unknown', bytes: BLOB });

    await expect(page).toHaveURL(/mode=.*ReadMode/);
    await expect(rowFor(page, file)).toBeVisible();

    const graph = await triples(doc);
    expect(graph).toContain(`<${file}> <${NFO}fileName> "drop.unknown" .`);
    expect(graph).toContain(`<${file}> <${DCT}format> <${MEDIA_TYPE}application/octet-stream> .`);
});

// Refused at the door. nginx caps every request body at MAX_CONTENT_LENGTH (docker-compose.yml,
// `client_max_body_size`), so a file over it never reaches the app: the POST comes back 413 from the
// proxy, with an HTML body. Both paths have to report that in the page, on the document the reader
// is still looking at - the failure is prepended to the content body as the kit's InlineAlert, and
// nothing navigates. What the sentence under the title says is the second claim: a refusal for size
// should say so, rather than fall through to the sentence for a status nobody mapped.
test.describe('a file over the request size limit', () => {
    // 6 MiB of anything, against a 5 MiB limit (.env MAX_CONTENT_LENGTH). Text, not bytes: a string
    // crosses into the page as one value.
    const oversize = 'x'.repeat(6 * 1024 * 1024);
    const failure = page => page.locator('.content-body > .ldh-failure').first();

    test.beforeEach(({ allowNoise }) => {
        allowNoise.push({ pattern: /HTTP 413:/, reason: 'the spec sends a body the proxy is configured to refuse' });
        allowNoise.push({ pattern: /console\.error: Failed to load resource.*413/, reason: 'the browser logs the same refusal' });
    });

    test('is reported as an upload that could not be made', { tag: '@owner' }, async ({ page }) => {
        await dropFile(page, { name: 'big.bin', text: oversize });

        await expect(failure(page)).toBeVisible();
        await expect(failure(page).locator('.ac-alert-title')).toHaveText('The file could not be uploaded');
        await expect(failure(page).locator('.ac-alert-text')).toHaveText('The file is larger than this server accepts.');
        await expect(failure(page).locator('pre')).toContainText('HTTP 413');
        // The reader stays where they were: no navigation into ReadMode, and nothing was written.
        await expect(page).not.toHaveURL(/ReadMode/);
        expect(await triples(doc)).not.toContain(`${NFO}FileDataObject`);
    });

    test('is reported as an import that could not be made', { tag: '@owner' }, async ({ page }) => {
        await dropFile(page, { name: 'big.ttl', type: 'text/turtle', text: oversize });

        await expect(failure(page)).toBeVisible();
        await expect(failure(page).locator('.ac-alert-title')).toHaveText('The file could not be imported');
        await expect(failure(page).locator('.ac-alert-text')).toHaveText('The file is larger than this server accepts.');
        await expect(failure(page).locator('pre')).toContainText('HTTP 413');
        await expect(page).not.toHaveURL(/ReadMode/);
    });
});
