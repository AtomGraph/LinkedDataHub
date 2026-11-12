// An action a package declares for a class (ldh:action), carried out by the platform: the taxonomy
// package's "Delete concept", which re-parents the concept's narrower concepts and drops the links
// its broader concepts hold, across their documents, before deleting the concept's own.
//
// A click never writes at once: the plan is evaluated first and its write set shown, and only a
// confirmation applies it. Both halves are asserted here - the dialog lists exactly the documents
// the plan would touch, cancelling leaves them as they were, confirming changes them - against a
// disposable branch seeded under coffee, so the taxonomy every other spec reads is untouched.
//
// Needs an executor beside the instance (the web-algebra service, lds:assistant in /context): without
// one the platform offers no actions, and the suite says so rather than failing.
import { test, expect } from '../../../lib/console.mjs';
import { goto } from '../../../lib/settle.mjs';
import { get } from '../../../lib/http.mjs';
import { ldh } from '../../../lib/fixtures.mjs';
import { endUserBase } from '../../../lib/stack.mjs';
import { addTriple, concept, conceptBlock, conceptPage, document, removeTriple, seedConcept, taxonomy } from '../../../lib/taxonomy.mjs';

const SKOS = 'http://www.w3.org/2004/02/skos/core#';
const menu = block => block.locator('.ldh-action-menu');
const modal = page => page.locator('div.modal.modal-action');
const writes = page => modal(page).locator('ul.ldh-action-writes > li');
const writeFor = (page, method, uri) => writes(page).filter({ has: page.locator(`code:text-is("${method}")`) }).filter({ has: page.locator(`a[href="${uri}"]`) });

async function executorAdvertised() {
    const { body } = await get(`${endUserBase}context`, { headers: { Accept: 'application/n-triples' } });
    return body.toString().includes('<https://w3id.org/atomgraph/linkeddatahub/dataspaces#assistant> "true"');
}

async function triples(name) {
    const { stdout } = await ldh(['get', '--accept', 'application/n-triples', document(name)], { allowFailure: true });
    return stdout;
}

async function openDeleteDialog(page) {
    await goto(page, conceptPage('mocha'));
    const block = conceptBlock(page, 'mocha');
    await expect(menu(block)).toBeVisible();
    await menu(block).locator('button.drop-toggle').click();
    await menu(block).locator('button.btn-action', { hasText: 'Delete concept' }).click();
    await expect(modal(page)).toBeVisible();
}

test.describe('actions', { tag: '@owner' }, () => {
    test.beforeEach(({}, testInfo) => {
        test.skip(testInfo.project.name !== 'owner', 'an action changes data, which the fixtures grant the owner alone');
    });

    test.beforeAll(async () => {
        test.skip(!await executorAdvertised(), 'the dataspace advertises no executor (lds:assistant), so the platform offers no actions');
    });

    // mocha under coffee, mocha-latte under mocha; coffee names mocha as narrower, so the delete has a
    // parent document to rewrite as well as a child's
    const narrower = (parent, child) => `<${concept(parent)}> <${SKOS}narrower> <${concept(child)}>`;
    test.beforeEach(async () => {
        await seedConcept({ name: 'mocha', label: 'Mocha', parent: 'coffee' });
        await seedConcept({ name: 'mocha-latte', label: 'Mocha latte', parent: 'mocha' });
        await addTriple(document('coffee'), narrower('coffee', 'mocha'));
    });

    test.afterEach(async () => {
        await removeTriple(document('coffee'), narrower('coffee', 'mocha'));
        await removeTriple(document('coffee'), narrower('coffee', 'mocha-latte'));
        await ldh(['delete', document('mocha-latte')], { allowFailure: true });
        await ldh(['delete', document('mocha')], { allowFailure: true });
    });

    test('shows the documents a delete would change, and changes nothing until confirmed', async ({ page }) => {
        await openDeleteDialog(page);

        // the child re-parented in its own document, the parent's narrower link moved in its own,
        // the concept's document deleted: three writes, no more
        await expect(writes(page)).toHaveCount(3);
        await expect(writeFor(page, 'PATCH', document('mocha-latte'))).toHaveCount(1);
        await expect(writeFor(page, 'PATCH', document('coffee'))).toHaveCount(1);
        await expect(writeFor(page, 'DELETE', document('mocha'))).toHaveCount(1);
        // nothing leaves the dataspace, so nothing is refused and the confirmation is offered
        await expect(modal(page).locator('li.is-danger')).toHaveCount(0);
        await expect(modal(page).locator('button.btn-action-confirm')).toBeVisible();

        await modal(page).locator('button.btn-close').click();
        await expect(modal(page)).toHaveCount(0);

        // a dry run: the executor evaluated the plan against a snapshot and sent nothing
        expect(await triples('mocha')).toContain(`<${concept('mocha')}>`);
        expect(await triples('mocha-latte')).toContain(`<${SKOS}broader> <${concept('mocha')}>`);
        expect(await triples('coffee')).toContain(narrower('coffee', 'mocha'));
    });

    test('applies the writes once confirmed, and the reader lands on the container', async ({ page }) => {
        await openDeleteDialog(page);
        await modal(page).locator('button.btn-action-confirm').click();

        // the concept's document is gone, so the page moves to its container
        await expect(page).toHaveURL(new RegExp('^' + taxonomy.container.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')));
        await expect(modal(page)).toHaveCount(0);

        const { code } = await ldh(['get', '--accept', 'application/n-triples', document('mocha')], { allowFailure: true });
        expect(code, 'the concept document should be gone').not.toBe(0);

        const child = await triples('mocha-latte');
        expect(child).toContain(`<${SKOS}broader> <${concept('coffee')}>`);
        expect(child).not.toContain(`<${concept('mocha')}>`);

        const parent = await triples('coffee');
        expect(parent).toContain(narrower('coffee', 'mocha-latte'));
        expect(parent).not.toContain(narrower('coffee', 'mocha'));
    });
});
