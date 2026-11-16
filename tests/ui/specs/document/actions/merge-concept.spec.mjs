// The taxonomy package's "Merge concepts": every link to the concept moves to the one picked as its argument
// (:into), which keeps the concept's preferred label as an alternative one, and the concept's document is
// deleted. One update per document that changes - each that linked to it, and the target's own.
//
// Needs an executor beside the instance, as delete-concept.spec.mjs does.
import { test, expect } from '../../../lib/console.mjs';
import { get } from '../../../lib/http.mjs';
import { goto } from '../../../lib/settle.mjs';
import { ldh } from '../../../lib/fixtures.mjs';
import { endUserBase } from '../../../lib/stack.mjs';
import { addTriple, concept, conceptBlock, conceptPage, document, removeTriple, seedConcept, taxonomy } from '../../../lib/taxonomy.mjs';

const SKOS = 'http://www.w3.org/2004/02/skos/core#';
const menu = block => block.locator('.ldh-action-menu');
const modal = page => page.locator('div.modal.modal-action');
const argument = (page, name) => modal(page).locator(`div.ldh-action-arg[data-name="${name}"]`);
const writes = page => modal(page).locator('ul.ldh-action-writes > li');
const writeFor = (page, method, uri) => writes(page).and(page.locator(`[data-method="${method}"]`)).filter({ has: page.locator(`a[href="${uri}"]`) });

async function executorAdvertised() {
    const { body } = await get(`${endUserBase}context`, { headers: { Accept: 'application/n-triples' } });
    return body.toString().includes('<https://w3id.org/atomgraph/linkeddatahub/dataspaces#assistant> "true"');
}

async function triples(name) {
    const { stdout } = await ldh(['get', '--accept', 'application/n-triples', document(name)], { allowFailure: true });
    return stdout;
}

test.describe('merging concepts', { tag: '@owner' }, () => {
    test.beforeEach(({}, testInfo) => {
        test.skip(testInfo.project.name !== 'owner', 'an action changes data, which the fixtures grant the owner alone');
    });

    test.beforeAll(async () => {
        test.skip(!await executorAdvertised(), 'the dataspace advertises no executor (lds:assistant), so the platform offers no actions');
    });

    // mocha under coffee, which names it as narrower, and mocha-latte under mocha: links to mocha in two other
    // documents, and latte, the target, in a third
    const narrower = (parent, child) => `<${concept(parent)}> <${SKOS}narrower> <${concept(child)}>`;
    const altLabel = `<${concept('latte')}> <${SKOS}altLabel> "Mocha"@en`;
    test.beforeEach(async () => {
        await seedConcept({ name: 'mocha', label: 'Mocha', parent: 'coffee' });
        await seedConcept({ name: 'mocha-latte', label: 'Mocha latte', parent: 'mocha' });
        await addTriple(document('coffee'), narrower('coffee', 'mocha'));
    });

    test.afterEach(async () => {
        await removeTriple(document('coffee'), narrower('coffee', 'mocha'));
        await removeTriple(document('coffee'), narrower('coffee', 'latte'));
        await removeTriple(document('latte'), altLabel);
        await ldh(['delete', document('mocha-latte')], { allowFailure: true });
        await ldh(['delete', document('mocha')], { allowFailure: true });
    });

    test('moves every link to the concept picked, keeps its label, deletes it', async ({ page }) => {
        await goto(page, conceptPage('mocha'));
        const block = conceptBlock(page, 'mocha');
        await expect(menu(block)).toBeVisible();
        await menu(block).locator('button.drop-toggle').click();
        await menu(block).locator('button.btn-action', { hasText: 'Merge concepts' }).click();

        const group = argument(page, 'into');
        await expect(group).toContainText('Merge into');
        const input = group.locator('input.resource-combobox');
        await input.click();
        await input.pressSequentially('Latte', { delay: 110 });
        await expect(group.locator('div.ac-cb-panel')).toBeVisible({ timeout: 20_000 });
        await group.locator(`div.ac-cb-panel li[title="${concept('latte')}"]`).first().click();
        await modal(page).locator('button.btn-action-preview').click();

        // the two documents that link to it, the target's, and its own deleted
        await expect(writes(page)).toHaveCount(4);
        await expect(writeFor(page, 'PATCH', document('mocha-latte'))).toHaveCount(1);
        await expect(writeFor(page, 'PATCH', document('coffee'))).toHaveCount(1);
        await expect(writeFor(page, 'PATCH', document('latte'))).toHaveCount(1);
        await expect(writeFor(page, 'DELETE', document('mocha'))).toHaveCount(1);

        await modal(page).locator('button.btn-action-confirm').click();
        await expect(page).toHaveURL(new RegExp('^' + taxonomy.container.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')));

        const { code } = await ldh(['get', '--accept', 'application/n-triples', document('mocha')], { allowFailure: true });
        expect(code, 'the merged concept\'s document should be gone').not.toBe(0);
        expect(await triples('mocha-latte')).toContain(`<${concept('mocha-latte')}> <${SKOS}broader> <${concept('latte')}>`);
        expect(await triples('coffee')).toContain(narrower('coffee', 'latte'));
        expect(await triples('latte')).toContain(altLabel);
    });
});
