// A typed resource's row brings two jobs once it is on the page: its property views, and - where the dataspace has an
// executor - the actions its classes declare, in the block header's menu. Every path that draws such a row has to
// start both, however many there are: the page load does, and these are the two others. Saving an inline edit draws
// the row again from what was saved; an object block draws the resource it names inside its own card.
//
// Both used to take the jobs as at most one, which held until the actions menu became the second: the save then
// failed after replacing the row (its label query's recovery drew the row once more, into the element it had just
// replaced), and the object block failed to start what it embedded. The save showed a page error and the object block
// not even that; either way the row came back without the views and the menu it brings.
import { test, expect } from '../../../lib/console.mjs';
import { goto, settled } from '../../../lib/settle.mjs';
import { get } from '../../../lib/http.mjs';
import { ldh } from '../../../lib/fixtures.mjs';
import { endUserBase } from '../../../lib/stack.mjs';
import { fillText, save } from '../../../lib/form.mjs';
import { concept, conceptBlock, conceptPage, seedConcept } from '../../../lib/taxonomy.mjs';

const SKOS = 'http://www.w3.org/2004/02/skos/core#';
const VIEW = 'https://w3id.org/atomgraph/linkeddatahub#View';
const menu = block => block.locator('.ldh-action-menu');
// the views injected under a resource's row, by the definition each one renders
const viewsIn = row => row.locator(`div.block-row[typeof="${VIEW}"]`).evaluateAll(views => views.map(view => view.getAttribute('about')).sort());
const rowOf = (page, name) => page.locator(`div.ldh-block-row[about="${concept(name)}"]`);

async function executorAdvertised() {
    const { body } = await get(`${endUserBase}context`, { headers: { Accept: 'application/n-triples' } });
    return body.toString().includes('<https://w3id.org/atomgraph/linkeddatahub/dataspaces#assistant> "true"');
}

test.describe('a typed resource drawn again', { tag: '@owner' }, () => {
    test.beforeEach(({}, testInfo) => {
        test.skip(testInfo.project.name !== 'owner', 'an edit is offered to an agent who may write');
    });

    // Not skipped without an executor, unlike the action specs: the defect is the second job, which only the executor
    // brings, so a run without one would pass for the wrong reason. The UI-tests workflow starts it.
    test.beforeAll(async () => {
        expect(await executorAdvertised(), 'the dataspace advertises an executor (lds:assistant)').toBe(true);
    });

    let removeCortado;
    test.beforeEach(async () => {
        removeCortado = await seedConcept({ name: 'cortado', label: 'Cortado', parent: 'coffee' });
    });

    test.afterEach(async () => {
        await removeCortado?.();
    });

    test('keeps its views and its actions after an inline save', async ({ page }) => {
        await goto(page, conceptPage('cortado'));
        const block = conceptBlock(page, 'cortado');
        await expect(menu(block), 'the concept offers its actions').toHaveCount(1, { timeout: 30_000 });
        await expect.poll(() => viewsIn(rowOf(page, 'cortado')), { message: 'and shows its views', timeout: 30_000 }).not.toEqual([]);
        await settled(page);
        const views = await viewsIn(rowOf(page, 'cortado'));

        await block.locator('button.btn-edit').first().click();
        const form = block.locator('form').first();
        await expect(form).toBeVisible({ timeout: 30_000 });
        await fillText(form, `${SKOS}prefLabel`, 'Cortado doppio');
        await save(form);

        await expect(block.locator('form'), 'the save closes the form').toHaveCount(0, { timeout: 30_000 });
        await expect(block, 'and draws the row from what was saved').toContainText('Cortado doppio');
        // once each: the row is drawn new, so a job started twice would show twice
        await expect(menu(block), 'the actions are offered again, once').toHaveCount(1, { timeout: 30_000 });
        await expect.poll(() => viewsIn(rowOf(page, 'cortado')), { message: 'the same views come back, once each', timeout: 30_000 }).toEqual(views);
        await expect(block, 'and the block finishes loading').not.toHaveClass(/is-loading/);
    });

    test('is started in full inside an object block', async ({ page }) => {
        const host = `${endUserBase}ui-redraw-object/`;
        await ldh(['delete', host], { allowFailure: true });
        await ldh(['create', 'item', '--container', endUserBase, '--title', 'Fixture embedded concept', '--slug', 'ui-redraw-object']);
        await ldh(['add', 'object-block', '--title', 'Fixture concept block', '--uri', `${host}#concept-block`, '--value', concept('cortado'), host]);
        try {
            await goto(page, host);
            const value = page.locator(`.block.ldh-block[about="${host}#concept-block"] .ldh-obj-value`);
            await expect(value, 'the object block draws the concept it names').toContainText('Cortado', { timeout: 30_000 });
            // the failure was a rejected promise Saxon-JS keeps to itself, no page error: what shows it is the views
            // the concept's row never got
            await expect.poll(() => viewsIn(value), { message: 'with the views its row brings', timeout: 30_000 }).not.toEqual([]);
            await settled(page);
        } finally {
            await ldh(['delete', host], { allowFailure: true });
        }
    });
});
