// An action with an argument: the taxonomy package's "Move concept", which asks for the concept to move
// under before anything is evaluated (spin:constraint [ a spl:Argument ; spl:predicate :target ]), then
// shows and applies the writes as any action does - the concept's own broader link replaced, and the
// documents that named it as narrower let it go.
//
// The argument is picked with the platform's resource lookup, among the instances of its spl:valueType
// (skos:Concept). Preview with nothing picked marks the field and sends nothing.
//
// Needs an executor beside the instance, as delete-concept.spec.mjs does.
import { test, expect } from '../../../lib/console.mjs';
import { goto } from '../../../lib/settle.mjs';
import { get } from '../../../lib/http.mjs';
import { ldh } from '../../../lib/fixtures.mjs';
import { endUserBase } from '../../../lib/stack.mjs';
import { addTriple, concept, conceptBlock, conceptPage, document, removeTriple, seedConcept } from '../../../lib/taxonomy.mjs';

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

async function openAction(page, name, title) {
    await goto(page, conceptPage(name));
    const block = conceptBlock(page, name);
    await expect(menu(block)).toBeVisible();
    await menu(block).locator('button.drop-toggle').click();
    await menu(block).locator('button.btn-action', { hasText: title }).click();
    await expect(modal(page)).toBeVisible();
}

// types the concept's label into the argument's lookup and picks it by URI
async function pick(page, name, label, uri) {
    const group = argument(page, name);
    const input = group.locator('input.resource-combobox');
    await input.click();
    await input.pressSequentially(label, { delay: 110 });
    await expect(group.locator('div.ac-cb-panel')).toBeVisible({ timeout: 20_000 });
    await group.locator(`div.ac-cb-panel li[title="${uri}"]`).first().click();
    await expect(group.locator('span.ac-cb-committed input[name="ou"]')).toHaveValue(uri, { timeout: 15_000 });
}

test.describe('actions with arguments', { tag: '@owner' }, () => {
    test.beforeEach(({}, testInfo) => {
        test.skip(testInfo.project.name !== 'owner', 'an action changes data, which the fixtures grant the owner alone');
    });

    test.beforeAll(async () => {
        test.skip(!await executorAdvertised(), 'the dataspace advertises no executor (lds:assistant), so the platform offers no actions');
    });

    // mocha under coffee, which also names it as narrower: the move has the concept's document and the
    // old parent's to change
    const narrower = (parent, child) => `<${concept(parent)}> <${SKOS}narrower> <${concept(child)}>`;
    test.beforeEach(async () => {
        await seedConcept({ name: 'mocha', label: 'Mocha', parent: 'coffee' });
        await addTriple(document('coffee'), narrower('coffee', 'mocha'));
    });

    test.afterEach(async () => {
        await removeTriple(document('coffee'), narrower('coffee', 'mocha'));
        await ldh(['delete', document('mocha')], { allowFailure: true });
    });

    test('asks for the argument first, and Preview without one sends nothing', async ({ page }) => {
        await openAction(page, 'mocha', 'Move concept');

        // the argument, labelled by its predicate, looked up among concepts; no write set yet
        await expect(argument(page, 'target')).toBeVisible();
        await expect(argument(page, 'target')).toContainText('Move under');
        await expect(writes(page)).toHaveCount(0);

        await modal(page).locator('button.btn-action-preview').click();
        await expect(argument(page, 'target').locator('div.ac-combobox.st-invalid')).toHaveCount(1);
        await expect(writes(page)).toHaveCount(0);
    });

    test('moves the concept under the one picked', async ({ page }) => {
        await openAction(page, 'mocha', 'Move concept');
        await pick(page, 'target', 'Tea', concept('tea'));
        await modal(page).locator('button.btn-action-preview').click();

        // the concept's own document and the old parent's, no more
        await expect(writes(page)).toHaveCount(2);
        await expect(writeFor(page, 'PATCH', document('mocha'))).toHaveCount(1);
        await expect(writeFor(page, 'PATCH', document('coffee'))).toHaveCount(1);

        await modal(page).locator('button.btn-action-confirm').click();
        await expect(modal(page)).toHaveCount(0);

        const moved = await triples('mocha');
        expect(moved).toContain(`<${concept('mocha')}> <${SKOS}broader> <${concept('tea')}>`);
        expect(moved).not.toContain(`<${SKOS}broader> <${concept('coffee')}>`);
        expect(await triples('coffee')).not.toContain(narrower('coffee', 'mocha'));
    });
});
