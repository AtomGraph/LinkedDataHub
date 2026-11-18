// Creating from a view makes two resources at once: the entity the view is about, and the document it is written
// into. The modal shows both as what they are - the document's form on top, with its container, title, description
// and primary topic, and the entity's form below it - so where the new document goes is on screen and the reader's
// to change, instead of a guess made from where the view's results happen to live.
//
// The scheme page's Concepts in scheme view has its rows in one container, so the container comes prefilled; the
// empty scheme's case, where nothing determines it, is view/empty-scheme's.
import { test, expect } from '../../../../lib/console.mjs';
import { goto } from '../../../../lib/settle.mjs';
import { containerTitle, fixtures, ldh } from '../../../../lib/fixtures.mjs';
import { concept, conceptPage, scheme, taxonomy } from '../../../../lib/taxonomy.mjs';
import { IN_SCHEME, PREF_LABEL, createButton, rowFor, rowLabel } from '../../../../lib/view.mjs';
import { fieldFor, fillText, save, textValue } from '../../../../lib/form.mjs';
import { constructorModal } from '../../../../lib/modal.mjs';

const DCT = 'http://purl.org/dc/terms/';
const FOAF = 'http://xmlns.com/foaf/0.1/';
const HAS_CONTAINER = 'http://rdfs.org/sioc/ns#has_container';

// N-Triples, one triple per line: a subject-predicate-object substring then matches regardless of how the store lays a graph out
const triples = uri => ldh(['get', '--accept', 'application/n-triples', uri]).then(({ stdout }) => stdout);
const escape = s => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const under = container => new RegExp(`^${escape(container)}[^/]+/$`);
const conceptsInScheme = page => page.locator(`div.block.ldh-block[data-property="${IN_SCHEME}"]`).filter({ hasText: 'Concepts in scheme' });
const fieldsets = modal => modal.locator('fieldset.ldh-fieldset');
const documentForm = modal => fieldsets(modal).first();
const entityForm = modal => fieldsets(modal).nth(1);
const chipValue = group => group.locator('span.ac-cb-committed input[name="ou"]').first();

async function openCreate(page) {
    await goto(page, conceptPage(scheme));
    const view = conceptsInScheme(page);
    await expect(createButton(view)).toBeVisible({ timeout: 60_000 });
    await createButton(view).click();
    const modal = constructorModal(page);
    await expect(modal).toBeVisible();
    await expect(fieldsets(modal)).toHaveCount(2);
    return { view, modal };
}

// Re-picking the container through its chip: the chip's edit button reopens the lookup
async function pickContainer(group, title, uri) {
    await group.locator('span.ac-cb-committed button.add-combobox').first().click();
    const input = group.locator('input.resource-combobox');
    await input.click();
    await input.pressSequentially(title, { delay: 110 });
    await group.locator(`div.ac-cb-panel li[title="${uri}"]`).first().click();
}

test.describe('creating from a view', { tag: '@owner' }, () => {
    test.beforeEach(({}, testInfo) => {
        test.skip(testInfo.project.name !== 'owner', 'creating a concept needs write access to the taxonomy, which is the owner\'s');
    });

    test('shows the document above the concept, its container determined by the view', async ({ page }) => {
        const { view, modal } = await openCreate(page);
        const doc = documentForm(modal);

        await expect(chipValue(fieldFor(doc, HAS_CONTAINER)), 'the container the rows live in, as a chip').toHaveValue(taxonomy.container);
        await expect(modal).toHaveAttribute('about', under(taxonomy.container));
        await expect(textValue(doc, `${DCT}title`)).toHaveValue('');
        await expect(textValue(doc, `${DCT}description`)).toHaveValue('');
        await expect(chipValue(fieldFor(doc, `${FOAF}primaryTopic`)), 'the topic is the concept being made').toHaveValue(await modal.getAttribute('data-instance'));
        await expect(fieldFor(entityForm(modal), PREF_LABEL)).toBeVisible();

        const newDocument = await modal.getAttribute('about');
        const newConcept = await modal.getAttribute('data-instance');
        try {
            // the label alone: the document's title is derived from it
            await fillText(modal, PREF_LABEL, 'Mocha');
            await save(modal);
            await expect(modal).toHaveCount(0);
            await expect(rowLabel(rowFor(view, newConcept))).toHaveText('Mocha');
            const stored = await triples(newDocument);
            expect(stored).toContain('"Mocha"');
            expect(stored).toContain(`<${FOAF}primaryTopic> <${newConcept}>`);
        } finally {
            await ldh(['delete', newDocument], { allowFailure: true });
        }
    });

    test('puts the document where the reader points the container', async ({ page }) => {
        const { view, modal } = await openCreate(page);
        const doc = documentForm(modal);

        await pickContainer(fieldFor(doc, HAS_CONTAINER), containerTitle, fixtures.container);

        // the address follows: the modal's, and the concept's as a fragment of it
        await expect(modal).toHaveAttribute('about', under(fixtures.container));
        const newDocument = await modal.getAttribute('about');
        const newConcept = await modal.getAttribute('data-instance');
        expect(newConcept.startsWith(`${newDocument}#`)).toBe(true);
        await expect(entityForm(modal).locator('input[name="su"]').first()).toHaveValue(newConcept);
        try {
            await fillText(modal, PREF_LABEL, 'Cortado');
            await save(modal);
            await expect(modal).toHaveCount(0);
            // listed by the scheme though written elsewhere: the inverse view's link goes into the new document
            await expect(rowLabel(rowFor(view, newConcept))).toHaveText('Cortado');
            expect(await triples(newDocument)).toContain(`<${concept(scheme)}>`);
        } finally {
            await ldh(['delete', newDocument], { allowFailure: true });
        }
    });

    // The package requires a label (:MissingPrefLabel); a save without one is refused with a 422 that describes
    // the concept alone, and the form that comes back has to be the whole form, the document's half included
    test('keeps both forms when the save is refused', async ({ page, allowNoise }) => {
        allowNoise.push(
            { pattern: /^HTTP 422: /, reason: 'the save is refused on purpose' },
            { pattern: /^console\.error: Failed to load resource: .* 422 /, reason: 'the browser\'s own line for the same refusal' });
        const { modal } = await openCreate(page);
        const newDocument = await modal.getAttribute('about');

        await fillText(documentForm(modal), `${DCT}title`, 'Kept through the refusal');
        await save(modal);

        await expect(fieldFor(modal, PREF_LABEL).first()).toHaveClass(/\bis-violation\b/, { timeout: 30_000 });
        await expect(fieldsets(modal)).toHaveCount(2);
        await expect(textValue(documentForm(modal), `${DCT}title`)).toHaveValue('Kept through the refusal');
        await expect(chipValue(fieldFor(documentForm(modal), HAS_CONTAINER))).toHaveValue(taxonomy.container);
        const { code } = await ldh(['get', '--accept', 'text/turtle', newDocument], { allowFailure: true });
        expect(code, 'nothing was written').not.toBe(0);
    });
});
