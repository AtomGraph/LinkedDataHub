// Changing what an existing resource is: its types, edited in its block's form like any other property.
//
// A type is a value of rdf:type, so the form treats it as one - added from the property picker, removed with
// its row's remove control - but it is also what the form is built from: the classes' constructors and shapes
// decide which properties the picker offers. A resource is often of more than one class (a product model that
// is also a set, a person who is also an author), and the form has to keep working with every one of them:
// a type added has to be added to THIS resource, keeping its values and its other types, and the form of a
// resource of two classes has to offer and accept the properties of both.
//
// The two classes are lib/model.mjs's: one described by a SPIN constructor (a name and a comment), one by a
// SHACL shape alone. The second has no constructor, which is the case that broke: a resource of both was
// built two prototypes, one per class, where the form needed one, and adding a value to it failed with
// "The form could not be loaded".
import { test, expect } from '../../lib/console.mjs';
import { goto } from '../../lib/settle.mjs';
import { ldh } from '../../lib/fixtures.mjs';
import { endUserBase } from '../../lib/stack.mjs';
import { fieldFor, save } from '../../lib/form.mjs';
import { FOAF_NAME, RDFS_COMMENT, model, seedModel, teardownModel } from '../../lib/model.mjs';

const RDF_TYPE = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type';
const NAME = 'Fixture typed thing';
const spin = model.spin;
const shacl = model.shacl;

test.beforeAll(async () => {
    await seedModel();
});

test.afterAll(async () => {
    await teardownModel();
});

test.beforeEach(({}, testInfo) => {
    test.skip(testInfo.project.name !== 'owner', 'editing is offered to an agent who may write');
});

// A document of its own whose #this has a name and the given types. Returns the document's URL.
async function seedDocument(slug, types) {
    await ldh(['delete', `${endUserBase}${slug}/`], { allowFailure: true });
    const { stdout: doc } = await ldh(['create', 'item', '--container', endUserBase, '--title', 'Fixture types', '--slug', slug]);
    const typing = types.map(type => ` ; <${RDF_TYPE}> <${type}>`).join('');
    await ldh(['patch', doc], { stdin: `INSERT {\n  <${doc}#this> <${FOAF_NAME}> "${NAME}"${typing} .\n} WHERE {}` });
    return doc;
}

async function openForm(page, doc) {
    await goto(page, doc);
    const block = page.locator(`div.block.ldh-block[about="${doc}#this"]`);
    await block.locator('button.btn-edit').first().click();
    const form = block.locator('form').first();
    await expect(form).toBeVisible({ timeout: 30_000 });
    return { block, form };
}

const typeGroups = form => fieldFor(form, RDF_TYPE);
const typeGroupOf = (form, type) => typeGroups(form).filter({ has: form.page().locator(`input[name="ou"][value="${type}"]`) });

// The picker below the fields: the property is chosen by its URI, which is the option's value, and Add
// appends a control for it, once the class models it is built from have loaded. A failed load leaves an
// alert where the control would have been, so the wait is for either, and then for the control.
async function addProperty(form, property) {
    const groups = fieldFor(form, property);
    const before = await groups.count();
    const addrow = form.locator('div.ldh-prop-addrow').last();
    await addrow.locator('select').selectOption(property);
    await addrow.locator('button.add-value').click();
    const failures = form.locator('.ldh-failure');
    await expect.poll(async () => await failures.count() > 0 || await groups.count() > before,
        { message: 'Add answers with a control or an alert', timeout: 15_000 }).toBe(true);
    await expect(failures, 'the control was added without error').toHaveCount(0);
    await expect(groups).toHaveCount(before + 1);
}

// A type added from the picker arrives as a class lookup: typed into (it listens on keyup), answered from
// the ontology's classes, and committed by clicking the class.
async function addType(form, cls) {
    await addProperty(form, RDF_TYPE);

    // a new row, so an empty lookup: not a copy of a type the resource already has
    const group = typeGroups(form).last();
    const input = group.locator('input.type-combobox');
    await expect(input, 'the added type is an empty lookup').toHaveValue('');
    await input.click();
    await input.pressSequentially(cls.label, { delay: 60 });
    const choice = group.locator(`div.ac-cb-panel li[title="${cls.uri}"]`).first();
    await expect(choice, 'the class is offered as a type').toBeVisible({ timeout: 15_000 });
    await choice.click();
    await expect(typeGroupOf(form, cls.uri), 'the type is committed').toHaveCount(1, { timeout: 15_000 });
    await expect(form.locator('.ldh-failure'), 'the form took the type without error').toHaveCount(0);
}

async function removeType(form, cls) {
    await typeGroupOf(form, cls.uri).locator('button.btn-remove-property').first().click();
    await expect(typeGroupOf(form, cls.uri)).toHaveCount(0);
}

// What the document holds after the save, read through the API rather than off the page.
async function stored(doc) {
    const { stdout } = await ldh(['get', '--accept', 'application/n-triples', doc]);
    return stdout;
}

// The save has to have changed the resource being edited, and only it: the types are exactly the expected
// ones, its name is still there, and no other resource of either class was minted beside it.
async function expectTypes(doc, types) {
    const triples = await stored(doc);
    const subject = `<${doc}#this>`;
    for (const cls of [spin, shacl]) {
        const typed = triples.split('\n').filter(line => line.includes(`<${RDF_TYPE}> <${cls.uri}>`));
        if (types.includes(cls)) expect(typed, `${subject} is a ${cls.label}, and nothing else is`).toEqual([`${subject} <${RDF_TYPE}> <${cls.uri}> .`]);
        else expect(typed, `nothing is a ${cls.label}`).toEqual([]);
    }
    expect(triples, 'the resource keeps its name').toContain(`${subject} <${FOAF_NAME}> "${NAME}"`);
}

async function saved(block, form) {
    await save(form);
    await expect(block.locator('form'), 'the save went through').toHaveCount(0, { timeout: 30_000 });
}

test.describe('the types of a resource', { tag: '@owner' }, () => {
    test('a type is added to a resource that has none', async ({ page }) => {
        const doc = await seedDocument('ui-types-add', []);
        try {
            const { block, form } = await openForm(page, doc);
            await addType(form, spin);
            await saved(block, form);
            await expectTypes(doc, [spin]);
        } finally {
            await ldh(['delete', doc], { allowFailure: true });
        }
    });

    test('the only type is removed', async ({ page }) => {
        const doc = await seedDocument('ui-types-remove', [spin.uri]);
        try {
            const { block, form } = await openForm(page, doc);
            await removeType(form, spin);
            await saved(block, form);
            await expectTypes(doc, []);
        } finally {
            await ldh(['delete', doc], { allowFailure: true });
        }
    });

    test('a second type is added', async ({ page }) => {
        const doc = await seedDocument('ui-types-add-second', [spin.uri]);
        try {
            const { block, form } = await openForm(page, doc);
            await addType(form, shacl);
            await saved(block, form);
            await expectTypes(doc, [spin, shacl]);
        } finally {
            await ldh(['delete', doc], { allowFailure: true });
        }
    });

    test('the second type is removed', async ({ page }) => {
        const doc = await seedDocument('ui-types-remove-second', [spin.uri, shacl.uri]);
        try {
            const { block, form } = await openForm(page, doc);
            await removeType(form, shacl);
            await saved(block, form);
            await expectTypes(doc, [spin]);
        } finally {
            await ldh(['delete', doc], { allowFailure: true });
        }
    });

    test('a resource of two classes takes a value of a property one of them offers', async ({ page }) => {
        const doc = await seedDocument('ui-types-two-classes', [spin.uri, shacl.uri]);
        try {
            const { block, form } = await openForm(page, doc);
            await addProperty(form, RDFS_COMMENT);
            await fieldFor(form, RDFS_COMMENT).last().locator('input[name="ol"]').fill('Fixture comment');
            await saved(block, form);

            expect(await stored(doc)).toContain(`<${doc}#this> <${RDFS_COMMENT}> "Fixture comment"`);
            await expectTypes(doc, [spin, shacl]);
        } finally {
            await ldh(['delete', doc], { allowFailure: true });
        }
    });
});
