// A value that links to another resource is looked up among the resources of the class it is meant to be.
//
// A constructor says what a property's objects are: `$this rdfs:seeAlso [ a foaf:Document ]` makes See also a
// link to a document, and the form's lookup for it searches documents alone and names the class beside the field.
// That has to hold however the field arrives - in the form as it opens, added from the property picker, or
// appended when a type is added and the form is fitted to the classes' models. In a dataspace of any size an
// unrestricted lookup is not a slower version of the same thing: it offers whatever happens to match the text
// typed, and the resource meant is lost among them.
import { mkdtempSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { test, expect } from '../../lib/console.mjs';
import { goto } from '../../lib/settle.mjs';
import { ldh } from '../../lib/fixtures.mjs';
import { adminBase, endUserBase } from '../../lib/stack.mjs';
import { fieldFor } from '../../lib/form.mjs';
import { namespaceDocument } from '../../lib/model.mjs';

const RDF_TYPE = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type';
const SEE_ALSO = 'http://www.w3.org/2000/01/rdf-schema#seeAlso';
const FOAF_NAME = 'http://xmlns.com/foaf/0.1/name';
const DOCUMENT = 'http://xmlns.com/foaf/0.1/Document';
const IMAGE = 'http://xmlns.com/foaf/0.1/Image';
const ns = `${endUserBase}ns#`;
// a class whose constructor makes See also a link to a document, one whose constructor makes it a link to
// something both a document and an image, and one with no model of its own
const linked = { uri: `${ns}UiLinkedThing`, label: 'UI linked thing' };
const pictured = { uri: `${ns}UiPicturedThing`, label: 'UI pictured thing' };
const plain = { uri: `${ns}UiPlainThing`, label: 'UI plain thing' };

async function addConstructed(cls, constructor, objectTypes) {
    const file = join(mkdtempSync(join(tmpdir(), 'ui-linked-')), 'construct.rq');
    writeFileSync(file, `CONSTRUCT {\n  $this <${SEE_ALSO}> [ a ${objectTypes.map(type => `<${type}>`).join(', ')} ] .\n}\nWHERE {}`);
    await ldh(['admin', 'add', 'constructor', '--uri', constructor, '--label', `${cls.label} constructor`, '--query-file', file, namespaceDocument]);
    await ldh(['admin', 'add', 'class', '--uri', cls.uri, '--label', cls.label, '--constructor', constructor, namespaceDocument]);
}

test.beforeAll(async () => {
    await addConstructed(linked, `${ns}UiLinkedThingConstructor`, [DOCUMENT]);
    await addConstructed(pictured, `${ns}UiPicturedThingConstructor`, [DOCUMENT, IMAGE]);
    await ldh(['admin', 'add', 'class', '--uri', plain.uri, '--label', plain.label, namespaceDocument]);
    await ldh(['admin', 'clear', 'ontology', adminBase]);
});

test.afterAll(async () => {
    await ldh(['patch', namespaceDocument], {
        allowFailure: true,
        stdin: `DELETE { ?s ?p ?o } WHERE { ?s ?p ?o . FILTER(?s IN (<${linked.uri}>, <${ns}UiLinkedThingConstructor>, <${pictured.uri}>, <${ns}UiPicturedThingConstructor>, <${plain.uri}>)) }`,
    });
    await ldh(['admin', 'clear', 'ontology', adminBase], { allowFailure: true });
});

test.beforeEach(({}, testInfo) => {
    test.skip(testInfo.project.name !== 'owner', 'editing is offered to an agent who may write');
});

// A document of its own whose #this has a name and the given types. Returns the document's URL.
async function seedDocument(slug, types) {
    await ldh(['delete', `${endUserBase}${slug}/`], { allowFailure: true });
    const { stdout: doc } = await ldh(['create', 'item', '--container', endUserBase, '--title', 'Fixture linked value', '--slug', slug]);
    const typing = types.map(type => ` ; <${RDF_TYPE}> <${type}>`).join('');
    await ldh(['patch', doc], { stdin: `INSERT {\n  <${doc}#this> <${FOAF_NAME}> "Fixture linked thing"${typing} .\n} WHERE {}` });
    return doc;
}

async function openForm(page, doc) {
    await goto(page, doc);
    const block = page.locator(`div.block.ldh-block[about="${doc}#this"]`);
    await block.locator('button.btn-edit').first().click();
    const form = block.locator('form').first();
    await expect(form).toBeVisible({ timeout: 30_000 });
    return form;
}

// the chain shows the busy cursor from the click until it ends
const settled = page => expect.poll(() => page.evaluate(() => document.body.style.cursor),
    { message: 'the form settles', timeout: 30_000 }).not.toBe('progress');

async function addSeeAlso(page, form) {
    const before = await fieldFor(form, SEE_ALSO).count();
    const addrow = form.locator('div.ldh-prop-addrow').last();
    await addrow.locator('select').selectOption(SEE_ALSO);
    await addrow.locator('button.add-value').click();
    await expect(fieldFor(form, SEE_ALSO)).toHaveCount(before + 1, { timeout: 15_000 });
    await expect(form.locator('.ldh-failure'), 'the field was added without error').toHaveCount(0);
}

// what the lookup searches, read where its handlers read it, and the class named beside the field
async function expectLookupOfDocuments(group) {
    await expect(group.locator('div.ac-cb-box'), 'the lookup searches documents').toHaveAttribute('data-for-class', DOCUMENT);
    await expect(group.locator('.ldh-annot'), 'and the field says so').toContainText('Document');
}

test.describe('a value linking to a resource of a class', { tag: '@owner' }, () => {
    test('is looked up among that class when the form opens', async ({ page }) => {
        const doc = await seedDocument('ui-linked-open', [linked.uri]);
        try {
            const form = await openForm(page, doc);
            await expectLookupOfDocuments(fieldFor(form, SEE_ALSO).first());
        } finally {
            await ldh(['delete', doc], { allowFailure: true });
        }
    });

    test('is looked up among that class when added from the property picker', async ({ page }) => {
        const doc = await seedDocument('ui-linked-added', [linked.uri]);
        try {
            const form = await openForm(page, doc);
            await addSeeAlso(page, form);
            await expectLookupOfDocuments(fieldFor(form, SEE_ALSO).last());
        } finally {
            await ldh(['delete', doc], { allowFailure: true });
        }
    });

    test('is looked up among that class when added to a resource of two classes', async ({ page }) => {
        const doc = await seedDocument('ui-linked-two-classes', [linked.uri, plain.uri]);
        try {
            const form = await openForm(page, doc);
            await addSeeAlso(page, form);
            await expectLookupOfDocuments(fieldFor(form, SEE_ALSO).last());
        } finally {
            await ldh(['delete', doc], { allowFailure: true });
        }
    });

    test('is looked up among that class when it arrives with a type added', async ({ page }) => {
        const doc = await seedDocument('ui-linked-type-added', [plain.uri]);
        try {
            const form = await openForm(page, doc);
            await expect(fieldFor(form, SEE_ALSO), 'the plain class has no See also').toHaveCount(0);

            const addrow = form.locator('div.ldh-prop-addrow').last();
            await addrow.locator('select').selectOption(RDF_TYPE);
            await addrow.locator('button.add-value').click();
            const group = fieldFor(form, RDF_TYPE).last();
            const input = group.locator('input.type-combobox');
            await expect(input).toBeVisible({ timeout: 15_000 });
            await input.click();
            await input.pressSequentially(linked.label, { delay: 60 });
            await group.locator(`div.ac-cb-panel li[title="${linked.uri}"]`).first().click();
            await settled(page);

            await expect(fieldFor(form, SEE_ALSO), 'the linked class brings its See also').toHaveCount(1, { timeout: 15_000 });
            await expectLookupOfDocuments(fieldFor(form, SEE_ALSO).first());
        } finally {
            await ldh(['delete', doc], { allowFailure: true });
        }
    });

    // A value may be meant to be of several classes at once, and the lookup asks for every one of them: one
    // VALUES row each, which binds the class in every branch of the lookup's UNION, rather than an IN filter
    // after it, which Jena does not push into the GRAPH branch (combobox.spec.mjs says what that costs)
    test('is looked up among every class it is meant to be', async ({ page }) => {
        const doc = await seedDocument('ui-linked-two-ranges', [pictured.uri]);
        try {
            const form = await openForm(page, doc);
            const group = fieldFor(form, SEE_ALSO).first();
            await expect(group.locator('div.ac-cb-box'), 'the lookup searches both classes')
                .toHaveAttribute('data-for-class', new RegExp(`^(?=.*${DOCUMENT})(?=.*${IMAGE})`));
            // and names each in a tag of its own: joined into one, the strip read "DocumentImage". The order is
            // the constructor's, which a CONSTRUCT does not promise, so the set is what is asserted
            const tags = group.locator('.ldh-annot .an-term');
            await expect(tags, 'one tag per class').toHaveCount(2);
            expect((await tags.allTextContents()).map(text => text.trim()).sort()).toEqual(['Document', 'Image']);

            const input = group.locator('input.resource-combobox');
            const lookup = page.waitForRequest(request => /\/sparql\?query=DESCRIBE/i.test(request.url()), { timeout: 25_000 });
            await input.click();
            await input.pressSequentially('Fixture', { delay: 110 });
            const query = new URL((await lookup).url()).searchParams.get('query');

            const block = query.match(/VALUES\s+\?Type\s*\{([^}]*)\}/i);
            expect(block, 'the classes are bound with VALUES').not.toBeNull();
            expect([...block[1].matchAll(/<([^>]+)>/g)].map(match => match[1]).sort(), 'one row per class')
                .toEqual([DOCUMENT, IMAGE].sort());
            expect(query, 'not filtered by IN after the UNION').not.toMatch(/\bIN\s*\(/i);
        } finally {
            await ldh(['delete', doc], { allowFailure: true });
        }
    });
});
