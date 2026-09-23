// Editing a class's constructors from a resource's edit form.
//
// A constructor is a CONSTRUCT template stored as sp:text in whichever document describes it, and the
// editor is a dialog of one card per constructor, one row per triple template. Two things went
// wrong here in one week, and neither is visible from the API tests, which drive the same documents
// through the CLI and never render a row:
//
//   - a template declaring rdf:langString was read as a RESOURCE, because the object kind was decided
//     by namespace and langString lives outside xsd:. The range slot came up empty, and the save path
//     keeps only rows whose slot carries a control - so opening the SKOS Concept constructor and
//     pressing Save silently deleted prefLabel, altLabel and definition from it;
//   - saving posted the constructor's host document to /clear as an ontology to reload, and a
//     package's copy of its ontology is a dh:Item ABOUT the ontology, so the reload answered 500.
//
// Driven against the taxonomy package's Concept constructor, which is where both were found: the
// class comes from an imported package, its constructor from the application's own copy of the
// package ontology, and its template carries every object kind the editor has to round-trip.
// Every write is undone from the stored text, and the ontology cache cleared, so the constructor
// every other spec renders forms from is the one they expect.
import { test, expect } from '../lib/console.mjs';
import { goto } from '../lib/settle.mjs';
import { ldh } from '../lib/fixtures.mjs';
import { adminBase } from '../lib/stack.mjs';
import { concept, document, packageOntologyDocument } from '../lib/taxonomy.mjs';

const READ_MODE = 'https://w3id.org/atomgraph/client#ReadMode';
const pageFor = name => `${document(name)}?mode=${encodeURIComponent(READ_MODE)}`;

const SKOS = 'http://www.w3.org/2004/02/skos/core#';
const SP = 'http://spinrdf.org/sp#';
const CONCEPT = `${SKOS}Concept`;

// What the package's Concept constructor templates, by property. The three literals are
// rdf:langString, which is the datatype the editor used to lose.
const TEMPLATED = ['prefLabel', 'altLabel', 'definition', 'broader', 'narrower', 'related', 'inScheme']
    .map(local => `${SKOS}${local}`);
const LANG_STRING_ROWS = 3;

const editor = page => page.locator('form.constructor-template');
const cards = form => form.locator('fieldset.ldh-ctor-card');
// The package's own constructor: the card stamped with the application's copy of the package
// ontology, and holding a template - a lived-in instance may attach further constructors to the
// class from other documents, and those are cards of their own beside this one.
const packageCard = form =>
    form.locator(`fieldset.ldh-ctor-card[data-graph="${packageOntologyDocument}"]`)
        .filter({ has: form.page().locator('div.ldh-ctor-row') });
const rowsOf = card => card.locator('div.ldh-ctor-row');
// A row is addressed by its predicate: the chip the editor renders for a known property carries it
// as the hidden ou input the save path reads.
const rowFor = (card, predicate) =>
    rowsOf(card).filter({ has: card.page().locator(`div.ctor-pred input[name="ou"][value="${predicate}"]`) });
const kindOn = row => row.locator('div.ctor-term button.object-kind.is-on');

// Open the Concept editor from the concept's own edit form. The Edit constructors button is emitted
// hidden and revealed once the gate has asked which documents the class's constructors live in and
// HEADed each for write access - two requests behind the form, which is itself a fetch behind the
// pencil.
async function openEditor(page) {
    await goto(page, pageFor('coffee'));
    const block = page.locator(`div.block.ldh-block[about="${concept('coffee')}"]`);
    await block.locator('button.btn-edit').first().click();

    const edit = page.locator(`button.btn-edit-constructors[data-resource-type="${CONCEPT}"]`);
    await expect(edit).toBeVisible({ timeout: 30_000 });
    await edit.click();

    const form = editor(page);
    await expect(form).toBeVisible({ timeout: 30_000 });
    return form;
}

// The stored template, read through the admin SPARQL endpoint with the page's own certificate. The
// Turtle the CLI prints carries the text as an escaped multi-line literal, which is not worth parsing
// when a SELECT hands it over verbatim.
async function storedText(page, graph, constructor) {
    // The nonce makes each read a different URL: the endpoint's responses are cached, and a save
    // invalidates the document it PATCHed, not every query that once read it.
    const query = `SELECT ?text WHERE { GRAPH <${graph}> { <${constructor}> <${SP}text> ?text } } # ${Date.now()}`;
    const response = await page.request.get(`${adminBase}sparql?query=${encodeURIComponent(query)}`,
        { headers: { Accept: 'application/sparql-results+json' } });
    expect(response.status(), 'the admin endpoint answers the owner').toBe(200);
    const { results } = await response.json();
    expect(results.bindings, `one sp:text on ${constructor}`).toHaveLength(1);
    return results.bindings[0].text.value;
}

// The same DELETE/INSERT the editor sends, with the text it found - the editor's save rewrites the
// text through the query builder even when nothing changed, so the fixture is restored from what
// was stored rather than trusted to survive a no-op.
function restoreText(graph, constructor, text) {
    const literal = `"""${text.replace(/\\/g, '\\\\').replace(/"""/g, '\\"\\"\\"')}"""`;
    return ldh(['patch', graph], {
        allowFailure: true,
        stdin: `PREFIX sp: <${SP}>
DELETE { <${constructor}> sp:text ?old }
INSERT { <${constructor}> sp:text ${literal} }
WHERE { OPTIONAL { <${constructor}> sp:text ?old } }`,
    });
}

// The editor's save clears the constructor's own ontology and then the application's; a restore
// through the API has to do the same, or the next form renders from whatever closure was cached.
const clearOntologies = () => ldh(['admin', 'clear', 'ontology', '-b', adminBase], { allowFailure: true });

// Which templated properties a stored text names. The package writes them as skos: prefixed
// names and the editor's builder writes them back as full URIs, so both spellings count.
const uris = text => TEMPLATED.filter(uri =>
    new RegExp(`(?:skos:|${SKOS.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')})${uri.slice(SKOS.length)}\\b`).test(text));

test.describe('the constructor editor', () => {
    test.beforeEach(({}, testInfo) => {
        test.skip(testInfo.project.name !== 'owner',
            'editing a constructor is a write to the ontology document, which only the owner may make');
    });

    test('renders each templated triple with its object kind and round-trips them through Save', async ({ page }) => {
        const form = await openEditor(page);
        const card = packageCard(form);
        // The document the save will PATCH is stamped on the card, because the constructor's URI does
        // not say which document describes it: this one is a fragment of the package ontology and
        // lives in the application's copy of it.
        await expect(card, 'the package constructor, in the application\'s copy of its ontology').toHaveCount(1);
        await expect(card, 'which the owner may edit').not.toHaveAttribute('disabled', /.*/);

        const graph = packageOntologyDocument;
        const constructor = await card.getAttribute('about');
        const original = await storedText(page, graph, constructor);
        expect(uris(original), 'the fixture templates every property').toEqual(TEMPLATED);

        try {
            await expect(rowsOf(card)).toHaveCount(TEMPLATED.length);

            // A language-tagged literal is a LITERAL whose datatype is not in xsd:. Reading it as a
            // resource left the slot empty, which is the state the save then discarded.
            const prefLabel = rowFor(card, `${SKOS}prefLabel`);
            await expect(kindOn(prefLabel)).toHaveAttribute('data-kind', 'http://www.w3.org/2000/01/rdf-schema#Literal');
            await expect(prefLabel.locator('span.ctor-range-slot select.ctor-range'))
                .toHaveValue('http://www.w3.org/1999/02/22-rdf-syntax-ns#langString');

            const broader = rowFor(card, `${SKOS}broader`);
            await expect(kindOn(broader)).toHaveAttribute('data-kind', 'http://www.w3.org/2000/01/rdf-schema#Resource');
            await expect(broader.locator(`span.ctor-range-slot input[name="ou"]`)).toHaveValue(CONCEPT);

            await form.locator('button.btn-save').click();
            await expect(form, 'the dialog closes on a successful save').toHaveCount(0, { timeout: 30_000 });

            // Not compared as a string: the builder re-serializes the query. What must survive is
            // every triple and every datatype. Polled, because the dialog closes on the FIRST card's
            // PATCH to answer, and on an instance with several cards that need not be this one's.
            await expect.poll(() => storedText(page, graph, constructor).then(text => text !== original),
                'the stored text was rewritten').toBe(true);
            const saved = await storedText(page, graph, constructor);
            expect(uris(saved), 'every templated property survived the round trip').toEqual(TEMPLATED);
            expect((saved.match(/langString/g) ?? []).length, 'and each rdf:langString stayed one')
                .toBe(LANG_STRING_ROWS);
        } finally {
            await restoreText(graph, constructor, original);
            await clearOntologies();
        }
    });

    test('removes a row from the template', async ({ page }) => {
        const removed = `${SKOS}altLabel`;
        const form = await openEditor(page);
        const card = packageCard(form);
        await expect(card).toHaveCount(1);
        const graph = packageOntologyDocument;
        const constructor = await card.getAttribute('about');
        const original = await storedText(page, graph, constructor);

        try {
            await rowFor(card, removed).locator('button.ctor-rm').click();
            await expect(rowFor(card, removed)).toHaveCount(0);
            await expect(rowsOf(card)).toHaveCount(TEMPLATED.length - 1);

            await form.locator('button.btn-save').click();
            await expect(form).toHaveCount(0, { timeout: 30_000 });

            await expect.poll(() => storedText(page, graph, constructor).then(uris),
                'the stored template lost the row and kept the rest').toEqual(TEMPLATED.filter(uri => uri !== removed));
        } finally {
            await restoreText(graph, constructor, original);
            await clearOntologies();
        }
    });
});
