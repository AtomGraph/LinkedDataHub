// The Create menu: what can be made here, and the dialog each choice opens.
//
// The menu is built from the classes the application's ontology declares a constructor for, so
// its items are data rather than markup - `@data-for-class` on each one names the class it would
// construct. That attribute is the thing worth asserting against, because it is also what the
// dialog is opened FOR: the modal carries the same class as its `@typeof`, and a pairing between
// the two is the difference between "a dialog opened" and "the right dialog opened".
//
// Creating something is view/create's subject and is not repeated here; this stops at the dialog - except for
// where the document goes, which the dialog now shows: the container (an item's) or the parent (a container's),
// prefilled with the page the menu was opened on and the reader's to change.
import { test, expect } from '../../../lib/console.mjs';
import { goto, settled } from '../../../lib/settle.mjs';
import { fixtures, ldh } from '../../../lib/fixtures.mjs';
import { taxonomy } from '../../../lib/taxonomy.mjs';
import { constructorModal } from '../../../lib/modal.mjs';
import { fieldFor, fillText, save } from '../../../lib/form.mjs';

const DH = 'https://w3id.org/atomgraph/linkeddatahub/document-hierarchy#';
const DCT = 'http://purl.org/dc/terms/';
const HAS_CONTAINER = 'http://rdfs.org/sioc/ns#has_container';
const HAS_PARENT = 'http://rdfs.org/sioc/ns#has_parent';

const create = page => page.locator('div.ldh-add-wrap').first();
const menu = page => create(page).locator('div.ldh-add-menu');
const choices = page => menu(page).locator('button.add-constructor[data-for-class]');
const chipValue = group => group.locator('span.ac-cb-committed input[name="ou"]').first();
const escape = s => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

async function openFor(page, forClass) {
    await goto(page, fixtures.container);
    await settled(page);
    await create(page).locator('button.drop-toggle').click();
    await choices(page).and(page.locator(`[data-for-class="${forClass}"]`)).first().click();
    const modal = constructorModal(page).first();
    await expect(modal).toBeVisible();
    return modal;
}

test.beforeEach(({}, testInfo) => {
    test.skip(testInfo.project.name !== 'owner', 'creating is offered to an agent who may write');
});

test('offers what the application knows how to construct', { tag: '@owner' }, async ({ page }) => {
    await goto(page, fixtures.container);
    await settled(page);

    await create(page).locator('button.drop-toggle').click();
    await expect(menu(page)).toBeVisible();
    // At least one, and every one of them naming the class it makes - an item with no class to
    // construct could not open a dialog at all.
    expect(await choices(page).count()).toBeGreaterThan(0);
});

test('opens a dialog for the class that was picked', { tag: '@owner' }, async ({ page }) => {
    await goto(page, fixtures.container);
    await settled(page);

    await create(page).locator('button.drop-toggle').click();
    const choice = choices(page).first();
    const forClass = await choice.getAttribute('data-for-class');
    await choice.click();

    const modal = constructorModal(page).first();
    await expect(modal).toBeVisible();
    await expect(modal, 'the dialog is typed for the class the menu item named')
        .toHaveAttribute('typeof', forClass);
});

test('an item\'s dialog names the container it goes in, prefilled with this page and changeable', { tag: '@owner' }, async ({ page }) => {
    const modal = await openFor(page, `${DH}Item`);
    const container = fieldFor(modal, HAS_CONTAINER);
    await expect(chipValue(container)).toHaveValue(fixtures.container);
    await expect(modal).toHaveAttribute('about', new RegExp(`^${escape(fixtures.container)}[^/]+/$`));

    // re-pointed through the chip: the address follows, and the save lands there
    await container.locator('span.ac-cb-committed button.add-combobox').first().click();
    const input = container.locator('input.resource-combobox');
    await input.click();
    await input.pressSequentially('UI test taxonomy', { delay: 110 });
    await container.locator(`div.ac-cb-panel li[title="${taxonomy.container}"]`).first().click();
    await expect(modal).toHaveAttribute('about', new RegExp(`^${escape(taxonomy.container)}[^/]+/$`));
    const newDocument = await modal.getAttribute('about');
    try {
        await fillText(modal, `${DCT}title`, 'Fixture item elsewhere');
        await save(modal);
        await expect(page).toHaveURL(new RegExp(`^${escape(newDocument)}`));
    } finally {
        await ldh(['delete', newDocument], { allowFailure: true });
    }
});

test('a container\'s dialog names its parent the same way', { tag: '@owner' }, async ({ page }) => {
    const modal = await openFor(page, `${DH}Container`);
    await expect(chipValue(fieldFor(modal, HAS_PARENT))).toHaveValue(fixtures.container);
    await expect(modal).toHaveAttribute('about', new RegExp(`^${escape(fixtures.container)}[^/]+/$`));
});
