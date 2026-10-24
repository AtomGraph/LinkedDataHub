// The form a new instance gets from its class's model, and what that model refuses.
//
// A class describes its instances in one of two vocabularies, or both: a SPIN constructor templates
// the properties a new instance starts with and a SPIN constraint requires one; a SHACL node shape
// does both at once, its property shapes the fields and sh:minCount the rule. The form code folds
// the two into one constructor (ldh:merge-constructors), and the three ways that fold can run -
// SPIN alone, SHACL alone, both on one class - are the three cases here, each driven through the
// same gestures: Create > Instance, the class picked as the type, Save with the required fields
// empty, the refusal, the fields filled, the save.
//
// The middle case is the one that was found broken. A class with a shape and no constructor has a
// SPIN side nonetheless - ldh:construct-instance types a bare instance for every class - and the
// merge left that typing-only resource beside the shape's prototype, so picking the type found two
// resources of the class where it needed one and the form failed to render at all.
import { test, expect } from '../../lib/console.mjs';
import { goto } from '../../lib/settle.mjs';
import { ldh } from '../../lib/fixtures.mjs';
import { endUserBase } from '../../lib/stack.mjs';
import { inMode, READ_MODE } from '../../lib/mode.mjs';
import { fieldFor, fillText, save } from '../../lib/form.mjs';
import { model, seedModel, teardownModel } from '../../lib/model.mjs';

const RDF_TYPE = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type';
const NAMED_INDIVIDUAL = 'http://www.w3.org/2002/07/owl#NamedIndividual';
const slug = 'ui-instance-form';
const document = `${endUserBase}${slug}/`;

// The document the instances are created in: one of its own, so the fixture container's blocks and
// the document tree's counts hold whatever a refused or a half-finished save leaves behind.
test.beforeAll(async () => {
    await ldh(['delete', document], { allowFailure: true });
    await ldh(['create', 'item', '--container', endUserBase, '--title', 'Fixture instance form', '--slug', slug]);
    await seedModel();
});

test.afterAll(async () => {
    await ldh(['delete', document], { allowFailure: true });
    await teardownModel();
});

test.beforeEach(({}, testInfo) => {
    test.skip(testInfo.project.name !== 'owner', 'creating is offered to an agent who may write');
});

const dock = page => page.locator('div.ldh-create-dock');
const form = page => page.locator('div.ldh-pane.is-active form.ldh-edit-form').last();
const typeGroup = page => fieldFor(form(page), RDF_TYPE);

// Create > Instance from the dock: an inline form typed owl:NamedIndividual, whose Type row is a
// committed chip. Its edit control opens the class lookup, which is typed into (it listens on keyup)
// and answered from the ontology's classes - the ones with a constructor or a shape targeting them.
async function newInstanceOf(page, cls) {
    await goto(page, inMode(document, READ_MODE));
    await dock(page).locator('button.drop-toggle').click();
    await dock(page).locator(`button.add-constructor[data-for-class="${NAMED_INDIVIDUAL}"]`).click();
    await expect(form(page)).toBeVisible({ timeout: 30_000 });

    await typeGroup(page).locator('span.ac-cb-committed button.add-type-combobox').first().click();
    const input = typeGroup(page).locator('input.type-combobox');
    await input.click();
    await input.pressSequentially(cls.label, { delay: 60 });
    const choice = typeGroup(page).locator(`div.ac-cb-panel li[title="${cls.uri}"]`).first();
    await expect(choice, 'the class is offered as a type').toBeVisible({ timeout: 15_000 });
    await choice.click();

    // The fieldset is rebuilt from the class's model, asynchronously: the type chip changing hands
    // is the first sign, the fields arriving the second. A failed rebuild leaves an alert instead.
    await expect(typeGroup(page).locator('span.ac-cb-committed input[name="ou"]')).toHaveValue(cls.uri, { timeout: 15_000 });
    await expect(form(page).locator('.ldh-failure'), 'the form rebuilt without error').toHaveCount(0);
    return form(page);
}

const refused = (allowNoise) => allowNoise.push(
    { pattern: new RegExp(`^HTTP 422: ${document.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}$`), reason: 'the save is refused on purpose' },
    { pattern: /^console\.error: Failed to load resource: .* 422 /, reason: 'the browser\'s own line for the same refusal' });

// What the document holds, read through the API rather than off the page.
const stored = () => ldh(['get', '--accept', 'application/n-triples', document]).then(({ stdout }) => stdout);

for (const [kind, cls] of Object.entries(model)) {
    test.describe(`a class described by ${kind === 'both' ? 'a SPIN constructor and a SHACL shape' : kind === 'spin' ? 'a SPIN constructor' : 'a SHACL shape'}`, { tag: '@owner' }, () => {
        test.afterEach(async () => {
            // Whatever an instance of the class left in the document, so the next test starts clean.
            await ldh(['patch', document], { allowFailure: true,
                stdin: `DELETE { ?s ?p ?o } WHERE { ?s <${RDF_TYPE}> <${cls.uri}> ; ?p ?o }` });
        });

        test('builds the form from the model', async ({ page }) => {
            const f = await newInstanceOf(page, cls);
            for (const property of cls.fields) {
                await expect(fieldFor(f, property).first(), `a field for ${property}`).toBeVisible({ timeout: 15_000 });
                await expect(fieldFor(f, property).first().locator('input[name="ol"]'), 'a literal, as the model says').toHaveCount(1);
            }
        });

        test('refuses a save without the required values, keeps the form and marks them', async ({ page, allowNoise }) => {
            refused(allowNoise);
            const f = await newInstanceOf(page, cls);
            for (const property of cls.fields) await expect(fieldFor(f, property).first()).toBeVisible({ timeout: 15_000 });

            await save(f);

            // Still a form, with every required field's group marked and no other.
            for (const property of cls.required) {
                await expect(fieldFor(form(page), property).first(), `${property} is marked`).toHaveClass(/\bis-violation\b/, { timeout: 30_000 });
            }
            for (const property of cls.fields.filter(p => !cls.required.includes(p))) {
                await expect(fieldFor(form(page), property).first(), `${property} is not`).not.toHaveClass(/\bis-violation\b/);
            }
            await expect(form(page)).toHaveCount(1);
            expect(await stored(), 'the refused write changed nothing').not.toContain(`<${cls.uri}>`);
        });

        test('saves once the required values are in', async ({ page }) => {
            const f = await newInstanceOf(page, cls);
            for (const property of cls.fields) await expect(fieldFor(f, property).first()).toBeVisible({ timeout: 15_000 });

            const values = Object.fromEntries(cls.fields.map((property, i) => [property, `${cls.label} value ${i + 1}`]));
            for (const [property, value] of Object.entries(values)) await fillText(f, property, value);
            await save(f);

            await expect(form(page)).toHaveCount(0, { timeout: 30_000 });
            await expect(page.locator('div.ldh-pane.is-active')).toContainText(values[cls.fields[0]]);
            const triples = await stored();
            expect(triples).toContain(`<${RDF_TYPE}> <${cls.uri}>`);
            for (const [property, value] of Object.entries(values)) expect(triples).toContain(`<${property}> "${value}"`);
        });
    });
}
