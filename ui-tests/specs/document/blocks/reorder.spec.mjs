// Reordering a document's content blocks by dragging one onto another.
//
// The gesture is three handlers deep and every one of them reads its subject off the element the
// POINTER is over: ondragstart resolves the row from the handle's ancestor axis, ondragenter and
// ondragover decide whether the position under the pointer would change anything, and ondrop
// resolves both the moved row and the document to PATCH the same way (client/block.xsl:542-740).
// So this spec drags with the mouse rather than dispatching drag events at chosen elements.
// Chromium delivers the HTML5 events for a real pointer drag - Playwright translates the moves over
// CDP - and dispatching instead would be the spec deciding, for each handler, the very thing the
// handler exists to work out. The stylesheet says as much at client/block.xsl:670-679, where the
// document a drop PATCHes had to stop being resolved from the drop target: a block embedding another
// resource stamps @data-base-uri on the injected subtree, so a release landing inside one resolved to
// the EMBEDDED document and sent the move through the Linked Data proxy, which answers 502. A
// dispatched event lands outside that subtree and never sees it. The last test is that case.
//
// The order on screen is not the subject. The move is written with a CONDITIONAL PATCH - the platform
// requires If-Match of every write to a document that already exists, because a write is a whole-graph
// read-modify-write - and the client moves the row optimistically, reverting only once the refusal
// comes back. So an assertion on the rows alone cannot tell a saved move from a refused one, and on
// 2026-09-28 three separate defects made every reorder in the browser refused while looking, for a
// moment, exactly like a saved one. Each is a test here:
//
//   · A page that was OPENED rather than navigated to has never fetched its own document as RDF, so
//     LinkedDataHub.contents is empty, ldh:document-etag() returns nothing and the write went out with
//     no If-Match at all - 428 Precondition Required. Hence `goto`, not a click-through, in every test.
//   · The write named no representation and went out as Accept: */*, which negotiates to HTML, while
//     the tag it quoted came from an application/rdf+xml read. The validator is per representation, so
//     the two could never agree - 412. Measured: HEAD as RDF/XML answered "..b724c67a", the PATCH
//     quoting it under */* was refused against an HTML tag.
//   · Nothing recorded the tag the 204 answered with, so the SECOND move of a page session quoted the
//     tag the first move had invalidated - 412 again, with "Could not move block". This is the one that
//     needs two moves to see, and the reason `two moves in one page session` exists below.
//
// Each test writes its own two-document fixture and removes it: the reorder is persistent, and a spec
// that reordered a shared fixture would change what every other spec's `.first()` resolves to.
import { test, expect } from '../../../lib/console.mjs';
import { goto } from '../../../lib/settle.mjs';
import { ldh } from '../../../lib/fixtures.mjs';
import { endUserBase } from '../../../lib/stack.mjs';
import { inMode, CONTENT_MODE } from '../../../lib/mode.mjs';

let doc, embedded;

// Four content members in a known order, written in one PUT rather than four `ldh add` calls: the
// sequence IS the subject here, so it is stated outright instead of being accumulated, and one
// invocation is one JVM start rather than four.
//
// The fourth is an ldh:Object naming a document of its own, because only that block kind renders
// another resource inside itself - the subtree the last test releases the pointer into.
const fixture = (uri, embeddedUri) => `@prefix dh: <https://w3id.org/atomgraph/linkeddatahub/document-hierarchy#> .
@prefix ldh: <https://w3id.org/atomgraph/linkeddatahub#> .
@prefix sioc: <http://rdfs.org/sioc/ns#> .
@prefix dct: <http://purl.org/dc/terms/> .
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .

<${uri}> a dh:Item ;
    sioc:has_container <${endUserBase}> ;
    dct:title "Reorder fixture" ;
    rdf:_1 <${uri}#a> ;
    rdf:_2 <${uri}#b> ;
    rdf:_3 <${uri}#c> ;
    rdf:_4 <${uri}#embed> .

<${uri}#a> a ldh:XHTML ;
    dct:title "Block A" ;
    rdf:value """<div xmlns="http://www.w3.org/1999/xhtml"><p>Block A</p></div>"""^^rdf:XMLLiteral .

<${uri}#b> a ldh:XHTML ;
    dct:title "Block B" ;
    rdf:value """<div xmlns="http://www.w3.org/1999/xhtml"><p>Block B</p></div>"""^^rdf:XMLLiteral .

<${uri}#c> a ldh:XHTML ;
    dct:title "Block C" ;
    rdf:value """<div xmlns="http://www.w3.org/1999/xhtml"><p>Block C</p></div>"""^^rdf:XMLLiteral .

<${uri}#embed> a ldh:Object ;
    dct:title "Embedded document" ;
    rdf:value <${embeddedUri}> .
`;

const embeddedFixture = uri => `@prefix dh: <https://w3id.org/atomgraph/linkeddatahub/document-hierarchy#> .
@prefix sioc: <http://rdfs.org/sioc/ns#> .
@prefix dct: <http://purl.org/dc/terms/> .

<${uri}> a dh:Item ;
    sioc:has_container <${endUserBase}> ;
    dct:title "Reorder embedded" ;
    dct:description "The resource the object block renders in place." .
`;

// The rows of the document's content list, in document order, named by their fragment. The rows the
// handlers act on are the children of .content-body - the same constraint every pattern in
// client/block.xsl carries - so anything a block renders inside itself is excluded by construction.
const CONTENT_ROWS = '.ldh-pane.is-active .content-body > .ldh-block-row';
const rows = page => page.locator(`${CONTENT_ROWS}[about]`);
const order = page => rows(page).evaluateAll(found => found.map(row => row.getAttribute('about').split('#')[1]));
// Addressed by the row's own @about, not by a descendant: the inner card carries the same value, so a
// `has:` filter would match through the card and quietly depend on that duplication.
const rowFor = (page, fragment) => page.locator(`${CONTENT_ROWS}[about$="#${fragment}"]`);

const marked = page => page.locator(`${CONTENT_ROWS}.drag-over`);
const dragging = page => page.locator(`${CONTENT_ROWS}.dragging`);

// The write that saves a move, so a test can say whether one was accepted rather than inferring it
// from the rows. Registered before the drop, because the response can arrive before the next await.
const savedMove = page => page.waitForResponse(response =>
    response.request().method() === 'PATCH' && response.url() === doc);

// Press the grip and cross the drag threshold, leaving the button down. The rail is hit-testable at
// opacity 0 (app.css:4287), but hovering the row first is what a person does and what makes the grip
// visible, so a screenshot of a failure shows what the reader would have seen.
async function grab(page, row) {
    await row.hover();
    const handle = row.locator('span.ldh-bh-drag').first();
    await expect(handle).toBeVisible();

    const grip = await handle.boundingBox();
    const x = grip.x + grip.width / 2, y = grip.y + grip.height / 2;
    await page.mouse.move(x, y);
    await page.mouse.down();
    // Chromium begins the drag on the first move past the threshold, not on the press: without this
    // the travel that follows is a plain mousemove and no dragstart is ever raised.
    await page.mouse.move(x + 8, y + 8);
}

// Travel to the middle of a target in steps, so the handlers receive the dragenter/dragover stream a
// real drag produces rather than one jump. The pointer decides the event target by hit-testing, which
// is the point: over a block that embeds another resource, the deepest element there belongs to the
// embedded subtree.
async function dragOver(page, target) {
    const box = await target.boundingBox();
    await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2, { steps: 16 });
}

test.beforeEach(({}, testInfo) => {
    test.skip(testInfo.project.name !== 'owner',
        'reordering is a write, and the drag handle only renders for an agent holding acl:Write');
});

test.beforeEach(async ({}, testInfo) => {
    embedded = `${endUserBase}reorder-embedded-${testInfo.testId}/`;
    doc = `${endUserBase}reorder-${testInfo.testId}/`;
    await ldh(['put', '--content-type', 'text/turtle', embedded], { stdin: embeddedFixture(embedded) });
    await ldh(['put', '--content-type', 'text/turtle', doc], { stdin: fixture(doc, embedded) });
});

test.afterEach(async () => {
    if (doc) await ldh(['delete', doc], { allowFailure: true });
    if (embedded) await ldh(['delete', embedded], { allowFailure: true });
});

test.describe('reordering blocks by dragging', { tag: '@owner' }, () => {
    test('a block dropped on another is moved after it, and the new order outlives the page', async ({ page }) => {
        await goto(page, inMode(doc, CONTENT_MODE));
        expect(await order(page)).toEqual(['a', 'b', 'c', 'embed']);

        await grab(page, rowFor(page, 'a'));
        await dragOver(page, rowFor(page, 'b'));
        // The marker names the row the block will be inserted AFTER, which is the whole of what the
        // drag tells the reader about where it would land.
        await expect(rowFor(page, 'b')).toHaveClass(/\bdrag-over\b/);

        const saved = savedMove(page);
        await page.mouse.up();

        await expect.poll(() => order(page)).toEqual(['b', 'a', 'c', 'embed']);
        expect((await saved).status(), 'the conditional PATCH that saves the new order').toBe(204);

        // The page was opened, not navigated to, so the client held no validator for it and had to
        // obtain one before writing. Asserting the reload is what separates a saved move from an
        // optimistic one the client would have reverted.
        await goto(page, inMode(doc, CONTENT_MODE));
        expect(await order(page)).toEqual(['b', 'a', 'c', 'embed']);
    });

    test('two moves in one page session are both saved', async ({ page }) => {
        await goto(page, inMode(doc, CONTENT_MODE));

        const first = savedMove(page);
        await grab(page, rowFor(page, 'a'));
        await dragOver(page, rowFor(page, 'b'));
        await page.mouse.up();
        expect((await first).status(), 'the first move').toBe(204);
        await expect.poll(() => order(page)).toEqual(['b', 'a', 'c', 'embed']);

        // The move the first one made stale. A write answers with the entity tag of the graph it just
        // produced; if the client does not record it, this PATCH quotes the tag the page loaded with,
        // the precondition fails and the reorder is silently lost - which is how a document could be
        // rearranged all afternoon with only the first drag ever landing.
        const second = savedMove(page);
        await grab(page, rowFor(page, 'c'));
        await dragOver(page, rowFor(page, 'b'));
        await page.mouse.up();
        expect((await second).status(), 'the second move, against the tag the first one returned').toBe(204);
        await expect.poll(() => order(page)).toEqual(['b', 'c', 'a', 'embed']);

        await goto(page, inMode(doc, CONTENT_MODE));
        expect(await order(page)).toEqual(['b', 'c', 'a', 'embed']);
    });

    test('the two positions that would leave the order unchanged refuse the drop', async ({ page }) => {
        await goto(page, inMode(doc, CONTENT_MODE));

        await grab(page, rowFor(page, 'b'));

        // Dropping a block on itself moves it after itself.
        await dragOver(page, rowFor(page, 'b'));
        await expect(marked(page)).toHaveCount(0);

        // Dropping it on its previous sibling moves it after the block it already follows.
        await dragOver(page, rowFor(page, 'a'));
        await expect(marked(page)).toHaveCount(0);

        // The control, and the reason the two above are a refusal rather than a drag that died: the
        // same drag still marks a position that would change something.
        await dragOver(page, rowFor(page, 'c'));
        await expect(rowFor(page, 'c')).toHaveClass(/\bdrag-over\b/);

        await page.mouse.up();
    });

    test('exactly one row is marked at a time', async ({ page }) => {
        await goto(page, inMode(doc, CONTENT_MODE));

        await grab(page, rowFor(page, 'a'));

        await dragOver(page, rowFor(page, 'b'));
        await expect(marked(page)).toHaveCount(1);
        await expect(rowFor(page, 'b')).toHaveClass(/\bdrag-over\b/);

        // The marker MOVES rather than accumulating: there is no dragleave handler, by design, so
        // nothing else would ever take it off the row the pointer has left (client/block.xsl:611).
        await dragOver(page, rowFor(page, 'c'));
        await expect(marked(page)).toHaveCount(1);
        await expect(rowFor(page, 'c')).toHaveClass(/\bdrag-over\b/);

        await page.mouse.up();
    });

    test('a drag released away from the content leaves no marker behind', async ({ page }) => {
        await goto(page, inMode(doc, CONTENT_MODE));

        await grab(page, rowFor(page, 'a'));
        await dragOver(page, rowFor(page, 'c'));
        await expect(marked(page)).toHaveCount(1);

        // Released over the action bar: not a drop target, so the drag is cancelled and ondragend is
        // the only thing that can clean up. A marker surviving here would sit on the page until the
        // next navigation, pointing at a move that never happened.
        await dragOver(page, page.locator('.ldh-pane.is-active .ldh-actionbar').first());
        await page.mouse.up();

        await expect(marked(page)).toHaveCount(0);
        await expect(dragging(page)).toHaveCount(0);
        expect(await order(page)).toEqual(['a', 'b', 'c', 'embed']);
    });

    test('a drop released inside an embedded resource still reorders the host document', async ({ page }) => {
        await goto(page, inMode(doc, CONTENT_MODE));

        const embed = rowFor(page, 'embed');
        const inside = embed.locator('.ldh-obj-value').first();
        await expect(inside).toBeVisible();

        // The precondition this test is about: the injected rendering is stamped with the EMBEDDED
        // document's URI, so ldh:base-uri() walking up from the drop target answers that document
        // rather than the one whose sequence is being reordered.
        await expect(embed.locator('[data-base-uri]').first()).toHaveAttribute('data-base-uri', embedded);

        // The embedded card's own header - a deep element of that subtree, and deliberately not the
        // middle of the value: the create dock floats over the bottom of the content body, and being
        // neither a .ldh-block-row nor .content-body itself it cancels no dragover, so a release there
        // is refused outright and nothing moves. Measured before this line named the header.
        const release = inside.locator('.ldh-block-head').first();

        await grab(page, rowFor(page, 'a'));
        await dragOver(page, release);
        // The marker lands on the host row, not on anything inside it: the handlers resolve the row by
        // walking up to the child of .content-body.
        await expect(embed).toHaveClass(/\bdrag-over\b/);

        // The host document, and no request to the embedded one. A move resolved from the drop target
        // would PATCH the embedded document through the proxy instead - and console.mjs fails the test
        // on the 502 that answers, so the URL match here and the noise guard hold it from both ends.
        const saved = savedMove(page);
        await page.mouse.up();

        await expect.poll(() => order(page)).toEqual(['b', 'c', 'embed', 'a']);
        expect((await saved).status(), 'the PATCH resolved to the host document').toBe(204);

        await goto(page, inMode(doc, CONTENT_MODE));
        expect(await order(page)).toEqual(['b', 'c', 'embed', 'a']);
    });
});
