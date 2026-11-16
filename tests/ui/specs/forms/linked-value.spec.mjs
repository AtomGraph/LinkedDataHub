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
const ns = `${endUserBase}ns#`;
// a class whose constructor makes See also a link to a document, and one with no model of its own
const linked = { uri: `${ns}UiLinkedThing`, label: 'UI linked thing' };
const plain = { uri: `${ns}UiPlainThing`, label: 'UI plain thing' };

test.beforeAll(async () => {
    const file = join(mkdtempSync(join(tmpdir(), 'ui-linked-')), 'construct.rq');
    writeFileSync(file, `CONSTRUCT {\n  $this <${SEE_ALSO}> [ a <${DOCUMENT}> ] .\n}\nWHERE {}`);
    await ldh(['admin', 'add', 'constructor', '--uri', `${ns}UiLinkedThingConstructor`, '--label', 'UI linked thing constructor', '--query-file', file, namespaceDocument]);
    await ldh(['admin', 'add', 'class', '--uri', linked.uri, '--label', linked.label, '--constructor', `${ns}UiLinkedThingConstructor`, namespaceDocument]);
    await ldh(['admin', 'add', 'class', '--uri', plain.uri, '--label', plain.label, namespaceDocument]);
    await ldh(['admin', 'clear', 'ontology', adminBase]);
});

test.afterAll(async () => {
    await ldh(['patch', namespaceDocument], {
        allowFailure: true,
        stdin: `DELETE { ?s ?p ?o } WHERE { ?s ?p ?o . FILTER(?s IN (<${linked.uri}>, <${ns}UiLinkedThingConstructor>, <${plain.uri}>)) }`,
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
});
