// Reading a document whose graph serializes larger than MAX_CONTENT_LENGTH.
//
// The limit bounds what the Linked Data proxy and the imports pull in from origins nobody controls.
// It was applied to the responses this deployment's own store returns as well, and the write that
// creates a graph was never bounded - so a successful import could produce a document the read path
// refused for good. Measured on a real case before the fix: 40,540 triples came back from Fuseki as
// 5,250,315 bytes of RDF/XML against a 5,242,880 limit, over by 0.14%, and every GET of that
// document answered 413 with an error alert where the page should be.
//
// What is asserted is the RESPONSE the browser receives for the document, not what the statement
// grid does with it: the bug was the representation never arriving, and a page can render its title
// and chrome from the shell while the RDF pass behind it is being refused. So the claim is the pass
// Saxon-JS makes with `Accept: application/rdf+xml` - 200, and larger than the limit - which is the
// request that answered 413 before, plus the absence of the failure alert the refusal painted.
//
// Nothing here sends a body past the limit. The inbound half of the guard is not the bug and has to
// keep working - `overlays/file-drop.spec.mjs` asserts that a 6 MiB drop is still refused with 413 -
// so the graph is grown by four appends that are each ~1.8 MB.
import { test, expect } from '../../lib/console.mjs';
import { goto, settled } from '../../lib/settle.mjs';
import { fixtures, ldh } from '../../lib/fixtures.mjs';

const MAX_CONTENT_LENGTH = 5 * 1024 * 1024;

// 12 literals of 600 kB is ~7.2 MB of graph, built from a few very large literals rather than tens
// of thousands of triples: the same bytes with a fraction of the parsing and layout.
const APPENDS = 4, PER_APPEND = 3, LITERAL_BYTES = 600_000;

const DCT = 'http://purl.org/dc/terms/';
const literal = n => `large-graph-marker-${n} ${'x'.repeat(LITERAL_BYTES)}`;

const failure = page => page.locator('.content-body > .ldh-failure');

let doc;

// INSERT/WHERE, not INSERT DATA: PATCH accepts only the UpdateModify and DELETE WHERE forms and
// answers 422 to anything else (DocumentHierarchyGraphStoreImpl:534).
test.beforeEach(async ({}, testInfo) => {
    test.skip(testInfo.project.name !== 'owner', 'the fixture is written through the API as the owner');

    const created = await ldh(['create', 'container', '--parent', fixtures.container,
        '--title', 'Large graph fixture', '--slug', `large-graph-${testInfo.testId}`]);
    doc = created.stdout;

    for (let i = 0; i < APPENDS; i++) {
        const triples = Array.from({ length: PER_APPEND },
            (_, j) => `<${doc}> <${DCT}description> "${literal(i * PER_APPEND + j + 1)}"`).join(' . ');
        await ldh(['patch', doc], { stdin: `INSERT { ${triples} } WHERE {}\n` });
    }
});

test.afterEach(async () => {
    if (doc) await ldh(['delete', doc], { allowFailure: true });
});

test('a document larger than the request limit is still readable', { tag: '@owner' }, async ({ page }) => {
    // The RDF-typed pass for the document itself. Other requests the page makes carry the same
    // Accept - the ontology through the proxy, the document-tree CONSTRUCT - and are nowhere near
    // the limit, so the URL has to be matched exactly or the assertion measures the wrong response.
    const responses = [];
    page.on('response', async response => {
        if (response.url() !== doc) return;
        if (!(response.request().headers()['accept'] ?? '').includes('application/rdf+xml')) return;
        try { responses.push({ status: response.status(), bytes: (await response.body()).length }); }
        catch { /* a body that cannot be read is reported by the emptiness of `responses` */ }
    });

    await goto(page, doc);
    await settled(page);

    // No alert prepended to the content body: that is what a reader got instead of this document.
    await expect(failure(page), 'the document answered with a failure instead of its content').toHaveCount(0);

    expect(responses.length, 'the browser never fetched the document as RDF').toBeGreaterThan(0);
    for (const { status, bytes } of responses) {
        expect(status, `the read path refused the document (${bytes} bytes)`).toBe(200);
        expect(bytes, 'the fixture is not actually over the limit, so this asserts nothing')
            .toBeGreaterThan(MAX_CONTENT_LENGTH);
    }
});
