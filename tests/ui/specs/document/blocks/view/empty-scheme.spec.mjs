// A scheme's first concept is created from the scheme's own page.
//
// The taxonomy package attaches Concepts in scheme to a scheme as an inverse view of skos:inScheme, and that view's
// Create is how a concept is made in it: the new concept is linked to the scheme on save (the inverse view's linking
// triple goes into the new document), so its form needs no In scheme filled in. A view declared not to show when
// empty takes its Create with it, though, and a scheme with no concepts is exactly the scheme whose Concepts in scheme
// is empty: the one way in was hidden until there was something in. So this one view is declared to show when empty,
// and the others a scheme gets (Orphan concepts, the narrower counts) still keep out of the flow until they have rows.
//
// With no rows, nothing says which container the new concept's document goes in, and the modal does not guess:
// its document form, above the concept's, has the container empty for the reader to pick, and the document's
// address follows the pick.
import { test, expect } from '../../../../lib/console.mjs';
import { goto } from '../../../../lib/settle.mjs';
import { ldh } from '../../../../lib/fixtures.mjs';
import { addTriple, concept, conceptPage, document, taxonomy } from '../../../../lib/taxonomy.mjs';
import { IN_SCHEME, PREF_LABEL, createButton, rowFor, rowLabel, rows } from '../../../../lib/view.mjs';
import { fieldFor, fillText, save } from '../../../../lib/form.mjs';
import { constructorModal } from '../../../../lib/modal.mjs';

const SKOS = 'http://www.w3.org/2004/02/skos/core#';
const FOAF = 'http://xmlns.com/foaf/0.1/';
const HAS_CONTAINER = 'http://rdfs.org/sioc/ns#has_container';
const name = 'ui-empty-scheme';

const turtle = uri => ldh(['get', '--accept', 'text/turtle', uri]).then(({ stdout }) => stdout);
// the scheme's three views on skos:inScheme share the property, so Concepts in scheme is told by its title
const conceptsInScheme = page => page.locator(`div.block.ldh-block[data-property="${IN_SCHEME}"]`).filter({ hasText: 'Concepts in scheme' });

test.describe('an empty concept scheme', { tag: '@owner' }, () => {
    test.beforeEach(async ({}, testInfo) => {
        test.skip(testInfo.project.name !== 'owner', 'creating a concept needs write access to the taxonomy, which is the owner\'s');

        await ldh(['delete', document(name)], { allowFailure: true });
        await ldh(['create', 'item', '--container', taxonomy.container, '--title', 'Empty scheme', '--slug', name]);
        await addTriple(document(name), `<${document(name)}> <${FOAF}primaryTopic> <${concept(name)}>`);
        await addTriple(document(name), `<${concept(name)}> a <${SKOS}ConceptScheme>`);
        await addTriple(document(name), `<${concept(name)}> <${SKOS}prefLabel> "Empty scheme"@en`);
    });

    test.afterEach(async () => {
        await ldh(['delete', document(name)], { allowFailure: true });
    });

    test('offers to create its first concept, which lands in it', async ({ page }) => {
        await goto(page, conceptPage(name));

        const view = conceptsInScheme(page);
        // shown though empty: the button arrives behind the results, the container and the access check
        await expect(createButton(view), 'Concepts in scheme offers Create while it has no rows').toBeVisible({ timeout: 60_000 });
        await expect(rows(view)).toHaveCount(0);

        await createButton(view).click();
        const modal = constructorModal(page);
        await expect(modal).toBeVisible();

        // the document's form first, the concept's below it; nothing determined the container, so its lookup is open
        const fieldsets = modal.locator('fieldset.ldh-fieldset');
        await expect(fieldsets).toHaveCount(2);
        const container = fieldFor(fieldsets.first(), HAS_CONTAINER);
        await expect(container.locator('input.resource-combobox')).toBeVisible();
        await expect(fieldFor(fieldsets.nth(1), PREF_LABEL)).toBeVisible();

        await container.locator('input.resource-combobox').click();
        await container.locator('input.resource-combobox').pressSequentially('UI test taxonomy', { delay: 110 });
        await container.locator(`div.ac-cb-panel li[title="${taxonomy.container}"]`).first().click();

        // the pick decides where the document goes: the modal's address and the concept's follow it
        await expect(modal).toHaveAttribute('about', new RegExp(`^${taxonomy.container.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}[^/]+/$`));
        const newDocument = await modal.getAttribute('about');
        const newConcept = await modal.getAttribute('data-instance');
        expect(newConcept.startsWith(`${newDocument}#`), 'the concept is a fragment of the document').toBe(true);
        try {
            await fillText(modal, PREF_LABEL, 'First concept');
            await save(modal);

            await expect(modal).toHaveCount(0);
            await expect(rowLabel(rowFor(view, newConcept)), 'the scheme now lists it').toHaveText('First concept');
            expect(await turtle(newDocument), 'and the concept names the scheme, written on save').toContain(`<${concept(name)}>`);

            // the next concept knows where it goes: the first one decided it. Measured before, the view's Create kept
            // the container it was rendered with, none, and the second concept's form opened on an empty lookup again
            await createButton(view).click();
            await expect(modal).toBeVisible();
            await expect(fieldFor(modal.locator('fieldset.ldh-fieldset').first(), HAS_CONTAINER).locator('span.ac-cb-committed input[name="ou"]').first(),
                'the container the first concept went in, as a chip').toHaveValue(taxonomy.container);
            await modal.locator('span.ac-modal-x button').first().click();
            await expect(modal).toHaveCount(0);
        } finally {
            await ldh(['delete', newDocument], { allowFailure: true });
        }
    });
});
