// Creating a resource from inside a view block.
//
// The Create button on an ontology-defined view mints a document URI client-side and PUTs
// the new resource into it as a fragment, letting the graph store build the containing
// dh:Item around it. That leaves two triples nobody else can supply, because only the
// client knows the document it just invented: foaf:primaryTopic, without which the
// document renders an empty body and the renderers have no topic to pair it with, and the
// dct:title it is known by everywhere a document is listed.
//
// So the assertions here are in two halves. The DOM half is that the result arrives as one
// labelled row, which says the save went through and the view re-queried itself. The data
// half reads the document back through the API, and it is the half that catches THIS bug:
// measured against the pre-fix build, the rows were identical either way, because this
// view projects the topic alone and the row's href is its document with the fragment
// stripped - so a document with no topic link renders exactly like one with it. A renderer
// that pairs them (the container listings, the tables) would show two rows where this
// shows one, which is why the link matters and why the DOM cannot be the whole assertion.
//
// Driven against the taxonomy, which is where the platform ships a view whose property has
// a URI range AND a container with results to determine it from. The behaviour under test
// is the platform's, not the package's.
import { test, expect } from '../lib/console.mjs';
import { goto } from '../lib/settle.mjs';
import { ldh } from '../lib/fixtures.mjs';
import { concept, document, removeTriple, scheme } from '../lib/taxonomy.mjs';
import {
    IN_SCHEME, NARROWER, PREF_LABEL,
    constructorModal, createButton, fillResource, fillText, rowFor, rows, save, viewBlock,
} from '../lib/blocks.mjs';

const READ_MODE = 'https://w3id.org/atomgraph/client#ReadMode';
const pageFor = name => `${document(name)}?mode=${encodeURIComponent(READ_MODE)}`;

const SKOS = 'http://www.w3.org/2004/02/skos/core#';
const FOAF = 'http://xmlns.com/foaf/0.1/';
const DCT = 'http://purl.org/dc/terms/';

const turtle = uri => ldh(['get', '--accept', 'text/turtle', uri]).then(({ stdout }) => stdout);

test.describe('creating from a view block', () => {
    test.beforeEach(({}, testInfo) => {
        // Creating needs acl:Write on the document the link is PATCHed into, and the
        // fixtures are owner-owned. The anonymous half of the axis is that no button is
        // offered at all, which belongs with the specs about authorization.
        test.skip(testInfo.project.name !== 'owner',
            'the taxonomy fixtures are owner-owned; creating needs write access to them');
    });

    test('gives the new document a primary topic and a title', async ({ page }) => {
        const label = 'Created from a view';
        await goto(page, pageFor('cold-drinks'));

        const narrower = viewBlock(page, NARROWER);
        const create = createButton(narrower);
        // The button is three chained fetches behind the block: results, then the container
        // a new solution would go in, then the access the agent has there.
        await expect(create).toBeVisible({ timeout: 60_000 });
        await expect(rows(narrower)).toHaveCount(1); // juice, seeded

        await create.click();
        const modal = constructorModal(page);
        await expect(modal).toBeVisible();

        // The modal carries the identity the client minted: @about is the document it will
        // PUT, @data-instance the fragment resource inside it. Read before saving, so the
        // teardown below can address them even if the assertions fail.
        const newDocument = await modal.getAttribute('about');
        const newConcept = await modal.getAttribute('data-instance');
        expect(newDocument, 'the modal names the document it will create').toBeTruthy();
        expect(newConcept.startsWith(newDocument), 'the instance is a fragment of it').toBe(true);

        const linkTriple = `<${concept('cold-drinks')}> <${SKOS}narrower> <${newConcept}>`;
        try {
            await fillText(modal, PREF_LABEL, label);
            // skos:inScheme is required of a concept by the package (:MissingInScheme), so
            // a save without it comes back 422 with a violation instead of a document.
            await fillResource(modal, IN_SCHEME, concept(scheme));

            await save(modal);

            // The modal closes, the linking triple is PATCHed into the document being read,
            // and the view re-queries itself.
            await expect(modal).toHaveCount(0);
            await expect(rowFor(narrower, newDocument)).toHaveCount(1);
            await expect(rowFor(narrower, newDocument).locator('span.ti')).toHaveText(label);
            // One new row, beside the one that was already there: no duplicate from the
            // document and its topic arriving as separate solutions.
            await expect(rows(narrower)).toHaveCount(2);

            const created = await turtle(newDocument);
            expect(created, 'the document says what it is about')
                .toContain(`<${FOAF}primaryTopic>`);
            expect(created).toContain(`<${newConcept}>`);
            expect(created, 'and carries the title it is listed by')
                .toMatch(new RegExp(`<${DCT}title>\\s*"${label}"`));

            const from = await turtle(document('cold-drinks'));
            expect(from, 'the concept it was created from now names it')
                .toContain(`<${SKOS}narrower>`);
            expect(from).toContain(newConcept);
        } finally {
            await ldh(['delete', newDocument], { allowFailure: true });
            // The link lives in the other document's graph, so deleting the created one
            // would otherwise leave every later spec a row pointing at nothing.
            await removeTriple(document('cold-drinks'), linkTriple);
        }
    });
});

