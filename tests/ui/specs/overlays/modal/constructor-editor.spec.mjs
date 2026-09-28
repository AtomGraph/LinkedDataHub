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
import { test, expect } from '../../../lib/console.mjs';
import { goto } from '../../../lib/settle.mjs';
import { ldh } from '../../../lib/fixtures.mjs';
import { adminBase, endUserBase } from '../../../lib/stack.mjs';
import { concept, document, packageOntologyDocument } from '../../../lib/taxonomy.mjs';
import { READ_MODE, inMode } from '../../../lib/mode.mjs';

const pageFor = name => inMode(document(name), READ_MODE);

const SKOS = 'http://www.w3.org/2004/02/skos/core#';
const SP = 'http://spinrdf.org/sp#';
const SPIN = 'http://spinrdf.org/spin#';
const LDH = 'https://w3id.org/atomgraph/linkeddatahub#';
const CONCEPT = `${SKOS}Concept`;
const RESOURCE = 'http://www.w3.org/2000/01/rdf-schema#Resource';
const COLLECTION = `${SKOS}Collection`;
// sp:text is a multi-line literal, and a spec file cannot nest those inside a template literal
const TRIPLE_QUOTE = '"'.repeat(3);

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
        .filter({ has: form.page().locator(`div.ctor-pred input[name="ou"][value="${SKOS}prefLabel"]`) });
const rowsOf = card => card.locator('div.ldh-ctor-row');
// A row is addressed by its predicate: the chip the editor renders for a known property carries it
// as the hidden ou input the save path reads.
const rowFor = (card, predicate) =>
    rowsOf(card).filter({ has: card.page().locator(`div.ctor-pred input[name="ou"][value="${predicate}"]`) });
const kindOn = row => row.locator('div.ctor-term button.object-kind.is-on');
// The fieldset IS the constructor: one per constructor, carrying its URI and the document to PATCH.
const constructorOf = card => card.getAttribute('about');

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


// The document describing the application's own ontology - where a class's first constructor goes.
// Resolved the way the editor resolves it, from the ontology URI the page advertises to the dh:Item
// that has it as foaf:primaryTopic, rather than assembled from a path this test happens to know.
async function appOntologyDocument(page) {
    const query = `PREFIX foaf: <http://xmlns.com/foaf/0.1/>
SELECT ?graph WHERE { GRAPH ?graph { ?graph foaf:primaryTopic <${endUserBase}ns#> } } # ${Date.now()}`;
    const response = await page.request.get(`${adminBase}sparql?query=${encodeURIComponent(query)}`,
        { headers: { Accept: 'application/sparql-results+json' } });
    expect(response.status(), 'the admin endpoint answers the owner').toBe(200);
    const { results } = await response.json();
    expect(results.bindings, 'the application has exactly one ontology document').toHaveLength(1);
    return results.bindings[0].graph.value;
}

// Which constructors a document attaches to a class.
async function constructorsIn(page, graph, forClass) {
    const query = `PREFIX spin: <${SPIN}>
SELECT ?c WHERE { GRAPH <${graph}> { <${forClass}> spin:constructor ?c } } # ${Date.now()}`;
    const response = await page.request.get(`${adminBase}sparql?query=${encodeURIComponent(query)}`,
        { headers: { Accept: 'application/sparql-results+json' } });
    expect(response.status()).toBe(200);
    const { results } = await response.json();
    return results.bindings.map(binding => binding.c.value);
}

// Undo a constructor this spec created: the link that attaches it and everything it says.
const dropConstructor = (graph, forClass, constructor) => ldh(['patch', graph], {
    allowFailure: true,
    stdin: `PREFIX spin: <${SPIN}>
DELETE { <${forClass}> spin:constructor <${constructor}> . <${constructor}> ?p ?o }
WHERE { OPTIONAL { <${constructor}> ?p ?o } }`,
});

// Adds a property row and commits its predicate, the way an author does: type into the combobox and
// take the first suggestion. fill() would set the value without the keyup the lookup listens on, and
// the panel would never open. The range is left at whatever the editor defaults it to.
async function addRow(page, card, predicate) {
    await card.locator('button.ldh-ctor-addprop').click();
    const row = rowsOf(card).last();
    const input = row.locator('div.ctor-pred input.property-combobox');
    await expect(input).toBeVisible({ timeout: 15_000 });
    await input.click();
    await input.pressSequentially(predicate.slice(SKOS.length), { delay: 110 });

    const panel = page.locator('div.ac-cb-panel.property-combobox');
    await expect(panel).toBeVisible({ timeout: 20_000 });
    await panel.locator(`li[about="${predicate}"], li`).first().click();
    await expect(row.locator('div.ctor-pred input[name="ou"]')).toHaveValue(predicate, { timeout: 15_000 });
    return row;
}

// ...and then switches the object kind and picks a datatype.
async function addLiteralRow(page, card, predicate) {
    const row = await addRow(page, card, predicate);

    await row.locator('div.ctor-term button[data-kind$="Literal"]').click();
    await row.locator('span.ctor-range-slot select.ctor-range')
        .selectOption('http://www.w3.org/2001/XMLSchema#string');
    return row;
}

test.describe('the constructor editor', { tag: '@owner' }, () => {
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
        const constructor = await constructorOf(card);
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
        const constructor = await constructorOf(card);
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

    // Where a class's first property goes when the document has no constructor for it yet. The editor
    // renders a fieldset for the application's own ontology whatever it holds, and stamps the constructor
    // a new row joins on @data-target - resolved once, deterministically, so repeated adds land in the
    // same place instead of scattering across constructors that render identically anyway.
    test('adds a property to the application\'s own ontology, creating its constructor if needed', async ({ page }) => {
        const ontologyDocument = await appOntologyDocument(page);
        const form = await openEditor(page);
        const card = form.locator(`fieldset.ldh-ctor-card[data-graph="${ontologyDocument}"]`);
        await expect(card, 'the application\'s own ontology is always offered as a destination').toHaveCount(1);

        const target = await card.getAttribute('about');
        expect(target, 'the fieldset names the constructor a new property will join').toContain(ontologyDocument);
        const before = await constructorsIn(page, ontologyDocument, CONCEPT);

        try {
            await addLiteralRow(page, card, `${SKOS}notation`);

            await form.locator('button.btn-save').click();
            await expect(form, 'the dialog closes on a successful save').toHaveCount(0, { timeout: 30_000 });

            await expect.poll(() => storedText(page, ontologyDocument, target).then(text => text.includes('notation')),
                'the property reached the constructor the fieldset named').toBe(true);
            const after = await constructorsIn(page, ontologyDocument, CONCEPT);
            expect(after, 'and it is the one the fieldset targeted').toContain(target);
            expect(after.length, 'one constructor here, not one per document describing the class')
                .toBe(Math.max(before.length, 1));
        } finally {
            await dropConstructor(ontologyDocument, CONCEPT, target);
            await clearOntologies();
        }
    });

    // A resource row's range starts at rdfs:Resource - any resource - and narrowing it is an edit on
    // the committed chip, whose lookup is scoped by the @data-for-class it carries. What the save
    // writes has to be the class the author picked, not the default it replaced.
    test('narrows the default rdfs:Resource range to a class, and saves it', async ({ page }) => {
        const ontologyDocument = await appOntologyDocument(page);
        const form = await openEditor(page);
        const card = form.locator(`fieldset.ldh-ctor-card[data-graph="${ontologyDocument}"]`);
        await expect(card).toHaveCount(1);
        const target = await card.getAttribute('about');

        try {
            const row = await addRow(page, card, `${SKOS}notation`);
            const slot = row.locator('span.ctor-range-slot');
            await expect(slot.locator('input[name="ou"]'), 'a range nobody declared is any resource')
                .toHaveValue(RESOURCE);

            await slot.locator('button.add-class-combobox').click();
            const input = slot.locator('input.class-combobox');
            await expect(input).toBeVisible({ timeout: 15_000 });
            await input.click();
            await input.pressSequentially('Concept', { delay: 110 });
            const panel = page.locator('div.ac-cb-panel.class-combobox');
            await expect(panel).toBeVisible({ timeout: 20_000 });
            // a panel item carries its URI as the hidden input the commit handler reads, not as @about
            await panel.locator(`li:has(input[name="ou"][value="${CONCEPT}"])`).first().click();
            await expect(slot.locator('input[name="ou"]'), 'the picked class replaces the default')
                .toHaveValue(CONCEPT, { timeout: 15_000 });

            await form.locator('button.btn-save').click();
            await expect(form, 'the dialog closes on a successful save').toHaveCount(0, { timeout: 30_000 });

            await expect.poll(() => storedText(page, ontologyDocument, target).then(text => text.includes('notation')),
                'the row reached the constructor').toBe(true);
            const saved = await storedText(page, ontologyDocument, target);
            expect(saved, 'ranged by the class the author picked').toContain(CONCEPT);
            expect(saved, 'and not by the default it replaced').not.toContain(RESOURCE);
        } finally {
            await dropConstructor(ontologyDocument, CONCEPT, target);
            await clearOntologies();
        }
    });

    // The same narrowing, on a range that was STORED as rdfs:Resource rather than defaulted into the
    // row a moment earlier: the constructor already exists, so the save rewrites it under the
    // document's own validator instead of creating one.
    test('narrows a stored rdfs:Resource range to a class, and saves it', async ({ page }) => {
        const ontologyDocument = await appOntologyDocument(page);
        const constructor = `${ontologyDocument}#idResourceRangeFixture`;
        await ldh(['patch', ontologyDocument], { stdin: [
            `PREFIX sp: <${SP}>`, `PREFIX spin: <${SPIN}>`, `PREFIX ldh: <${LDH}>`,
            `INSERT {`,
            `  <${CONCEPT}> spin:constructor <${constructor}> .`,
            `  <${constructor}> a ldh:Constructor .`,
            `  <${constructor}> sp:text ${TRIPLE_QUOTE}CONSTRUCT { $this <${SKOS}broader> [ a <${RESOURCE}> ] . } WHERE {}${TRIPLE_QUOTE} .`,
            `} WHERE {}`,
        ].join('\n') });
        await clearOntologies();

        try {
            const form = await openEditor(page);
            const card = form.locator(`fieldset.ldh-ctor-card[about="${constructor}"]`);
            await expect(card, 'the seeded constructor has a fieldset of its own').toHaveCount(1);

            const row = rowFor(card, `${SKOS}broader`);
            const slot = row.locator('span.ctor-range-slot');
            await expect(slot.locator('input[name="ou"]'), 'the stored rdfs:Resource renders as a chip')
                .toHaveValue(RESOURCE);

            await slot.locator('button.add-class-combobox').click();
            const input = slot.locator('input.class-combobox');
            await expect(input).toBeVisible({ timeout: 15_000 });
            await input.click();
            await input.pressSequentially('Concept', { delay: 110 });
            const panel = page.locator('div.ac-cb-panel.class-combobox');
            await expect(panel).toBeVisible({ timeout: 20_000 });
            await panel.locator(`li:has(input[name="ou"][value="${CONCEPT}"])`).first().click();
            await expect(slot.locator('input[name="ou"]')).toHaveValue(CONCEPT, { timeout: 15_000 });

            await form.locator('button.btn-save').click();
            await expect(form, 'the dialog closes on a successful save').toHaveCount(0, { timeout: 30_000 });

            await expect.poll(() => storedText(page, ontologyDocument, constructor).then(text => text.includes(CONCEPT)),
                'the narrowed range was written').toBe(true);
            expect(await storedText(page, ontologyDocument, constructor), 'and the default is gone')
                .not.toContain(RESOURCE);
        } finally {
            await dropConstructor(ontologyDocument, CONCEPT, constructor);
            await clearOntologies();
        }
    });

    // Two constructors in one document are two fieldsets. Grouping by document was tried and reverted:
    // what decides whether editing is safe is the constructor's attachment, not where it is stored, and
    // a fieldset that hides which constructor it writes cannot show that.
    test('renders a fieldset per constructor, and saves each on its own', async ({ page }) => {
        const graph = packageOntologyDocument;
        const second = `${graph}#idSecondConstructorFixture`;
        await ldh(['patch', graph], { stdin: [
            `PREFIX sp: <${SP}>`, `PREFIX spin: <${SPIN}>`, `PREFIX ldh: <${LDH}>`,
            `INSERT {`,
            `  <${CONCEPT}> spin:constructor <${second}> .`,
            `  <${second}> a ldh:Constructor .`,
            `  <${second}> sp:text ${TRIPLE_QUOTE}CONSTRUCT { $this <${SKOS}notation> [ a <http://www.w3.org/2001/XMLSchema#string> ] . } WHERE {}${TRIPLE_QUOTE} .`,
            `} WHERE {}`,
        ].join('\n') });
        await clearOntologies();

        try {
            const form = await openEditor(page);
            await expect(cards(form).filter({ has: page.locator('div.ldh-ctor-row') }),
                'one fieldset per constructor, not one per document').toHaveCount(2);

            const addedCard = cards(form).filter({ has: page.locator(`div.ctor-pred input[name="ou"][value="${SKOS}notation"]`) });
            await expect(addedCard, 'each names the constructor it writes').toHaveAttribute('about', second);
            await expect(addedCard, 'and the document that holds it').toHaveAttribute('data-graph', graph);

            const packageConstructor = await constructorOf(packageCard(form));
            const packageBefore = await storedText(page, graph, packageConstructor);

            await rowFor(addedCard, `${SKOS}notation`).locator('button.ctor-rm').click();
            await form.locator('button.btn-save').click();
            await expect(form).toHaveCount(0, { timeout: 30_000 });

            // that was its only row, so the constructor goes; its neighbour in the same document, which
            // Save rewrites too, keeps every property it had
            await expect.poll(() => constructorsIn(page, graph, CONCEPT).then(uris => uris.includes(second)),
                'the emptied constructor was deleted, not stored as an empty CONSTRUCT').toBe(false);
            expect(uris(await storedText(page, graph, packageConstructor)),
                'and the constructor beside it was untouched').toEqual(uris(packageBefore));
        } finally {
            await dropConstructor(graph, CONCEPT, second);
            await clearOntologies();
        }
    });

    // A constructor several classes share is the one case where its identity reaches beyond its document:
    // rewriting it from this class's editor would change the other class's form too. With the source
    // merged into the document's list the author cannot anticipate that, so its rows are inert and Save
    // skips them.
    test('will not write a constructor that another class also uses', async ({ page }) => {
        const graph = packageOntologyDocument;
        const opened = await openEditor(page);
        const shared = await constructorOf(packageCard(opened));
        await opened.locator('button.btn-close').click();
        await expect(opened).toHaveCount(0, { timeout: 15_000 });

        await ldh(['patch', graph], { stdin:
            `PREFIX spin: <${SPIN}>\nINSERT { <${COLLECTION}> spin:constructor <${shared}> . } WHERE {}` });
        await clearOntologies();

        try {
            const before = await storedText(page, graph, shared);
            const form = await openEditor(page);
            const card = form.locator(`fieldset.ldh-ctor-card[about="${shared}"]`);

            await expect(card, 'the fieldset is inert, because another class has this constructor too')
                .toHaveAttribute('disabled', /.*/);
            await expect(card.locator('span.ctor-owners'), 'and says which class that is').toHaveCount(1);
            await expect(card.locator('button.ldh-ctor-addprop'), 'with nothing to add to it').toHaveCount(0);

            await form.locator('button.btn-save').click();
            await expect(form).toHaveCount(0, { timeout: 30_000 });

            // the builder re-serializes any text it is given, so an unchanged stored text proves the save
            // skipped this constructor rather than happening to produce the same string
            await page.waitForTimeout(3_000);
            expect(await storedText(page, graph, shared), 'and Save left it exactly as it was').toBe(before);
        } finally {
            await ldh(['patch', graph], { allowFailure: true, stdin:
                `PREFIX spin: <${SPIN}>\nDELETE { <${COLLECTION}> spin:constructor <${shared}> . } WHERE {}` });
            await clearOntologies();
        }
    });
});

