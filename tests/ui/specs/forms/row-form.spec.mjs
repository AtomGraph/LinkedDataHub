// Editing in place: the form that appears inside a block rather than over the page.
//
// Where a form is rendered is not a style choice in LDH, it is a statement about what is being
// edited. A resource described BY the document being read is edited inline, in its own block; a
// resource that lives in its own document is edited in a dialog. The reader can tell the two
// apart without being told, because one keeps the page and the other covers it.
//
// A concept page is where the distinction is visible: the concept is described by the document,
// so pressing its block's edit control has to turn that block into a form and leave the rest of
// the page - the other blocks, the tree in the content column - readable behind it. The failure
// to catch is the easy one: reaching for the dialog helper because it is there.
import { test, expect } from '../../lib/console.mjs';
import { goto } from '../../lib/settle.mjs';
import { conceptBlock, conceptPage } from '../../lib/taxonomy.mjs';
import { endUserBase } from '../../lib/stack.mjs';
import { itemTitle, itemUri, ldh } from '../../lib/fixtures.mjs';
import { fieldFor, fillText, save } from '../../lib/form.mjs';

const SEE_ALSO = 'http://www.w3.org/2000/01/rdf-schema#seeAlso';
const TITLE = 'http://purl.org/dc/terms/title';
const DESCRIPTION = 'http://purl.org/dc/terms/description';
const SD = 'http://www.w3.org/ns/sparql-service-description#';

test.beforeEach(({}, testInfo) => {
    test.skip(testInfo.project.name !== 'owner', 'editing is offered to an agent who may write');
});

test('turns the block into a form, in place', { tag: '@owner' }, async ({ page }) => {
    await goto(page, conceptPage('coffee'));

    const block = conceptBlock(page, 'coffee');
    await expect(block).toBeVisible();
    await expect(block.locator('form')).toHaveCount(0);

    await block.locator('button.btn-edit').first().click();

    // The form is INSIDE the block whose resource it edits.
    await expect(block.locator('form').first()).toBeVisible({ timeout: 30_000 });
});

test('leaves the rest of the page readable, opening no dialog', { tag: '@owner' }, async ({ page }) => {
    await goto(page, conceptPage('coffee'));

    const block = conceptBlock(page, 'coffee');
    await block.locator('button.btn-edit').first().click();
    await expect(block.locator('form').first()).toBeVisible({ timeout: 30_000 });

    // No backdrop, and the content column still there: the document is being edited in the middle
    // of itself rather than behind a sheet.
    await expect(page.locator('div.ac-backdrop.modal')).toHaveCount(0);
    await expect(page.locator('.ldh-content-aside ul.concept-tree')).toBeVisible();
});

// Saving redraws the block from the triples the form submitted, and those carry a resource value as
// its URI alone. The label is the object's own, in another document, so the redraw has to ask for it
// the way a page load does - or the link reads as the URI's last segment. A document of its own,
// because the save rewrites what the block describes.
test('labels a resource value the save has just changed', { tag: '@owner' }, async ({ page }) => {
    const doc = await seedDocument('ui-row-form-linked', `<${TITLE}> "Fixture linked" ; <${SEE_ALSO}> <${itemUri(1)}>`);
    try {
        await goto(page, doc);

        const block = page.locator(`div.block.ldh-block[about="${doc}#this"]`);
        await block.locator('button.btn-edit').first().click();
        const form = block.locator('form').first();
        await expect(form).toBeVisible({ timeout: 30_000 });

        // The committed chip gives way to the lookup, which is typed into, never filled: it listens on keyup.
        const group = form.locator(`div.ldh-prop-group:has(input[name="pu"][value="${SEE_ALSO}"])`);
        await group.locator('span.ac-cb-committed button.add-combobox').first().click();
        const input = group.locator('input.resource-combobox');
        await input.click();
        await input.pressSequentially(itemTitle(2), { delay: 110 });
        await group.locator(`div.ac-cb-panel li[title="${itemUri(2)}"]`).first().click();
        await expect(group.locator('span.ac-cb-committed input[name="ou"]')).toHaveValue(itemUri(2), { timeout: 15_000 });

        await save(form);
        await expect(block.locator('form')).toHaveCount(0, { timeout: 30_000 });

        const links = block.locator(`a[href^="${itemUri(2)}"]`);
        await expect(links.first()).toBeVisible({ timeout: 15_000 });
        for (const text of await links.allTextContents()) expect(text.trim()).toBe(itemTitle(2));
    } finally {
        await ldh(['delete', doc], { allowFailure: true });
    }
});

// A document of its own whose #this is described by the given predicate-object pairs. Returns the document's URL.
async function seedDocument(slug, description) {
    const { stdout: doc } = await ldh(['create', 'item', '--container', endUserBase, '--title', 'Fixture document', '--slug', slug]);
    await ldh(['patch', doc], { stdin: `INSERT {\n  <${doc}#this> ${description} .\n} WHERE {}` });
    return doc;
}

// The stored title of a document's #this, read over the API rather than off the page.
async function storedTitle(doc) {
    const { stdout } = await ldh(['get', '--accept', 'application/n-triples', doc]);
    return stdout.split('\n').filter(line => line.startsWith(`<${doc}#this> <${TITLE}>`)).map(line => line.match(/"(.*)"/)[1]);
}

// The block a seeded resource is rendered in, and its edit form opened.
async function openForm(page, doc) {
    await goto(page, doc);
    const block = page.locator(`div.block.ldh-block[about="${doc}#this"]`);
    await block.locator('button.btn-edit').first().click();
    const form = block.locator('form').first();
    await expect(form).toBeVisible({ timeout: 30_000 });
    return { block, form };
}

// A save the constraints refuse. sd:Service requires a dct:title (:MissingTitle), so emptying it is
// answered 422 with the violation, and the form has to come back with what was typed still in it and
// the offending field marked - not close, not lose the other values, and not leave the document changed.
// Then the same form, corrected, has to save normally: the violation render is a form like any other.
test('keeps the form open on a constraint violation, then saves once it is corrected', { tag: '@owner' }, async ({ page, allowNoise }) => {
    allowNoise.push(
        { pattern: /^HTTP 422: https:\/\/[^/]+\/ui-row-form-violation\/$/, reason: 'the save is refused on purpose' },
        { pattern: /^console\.error: Failed to load resource: .* 422 /, reason: 'the browser\'s own line for the same refusal' });
    const doc = await seedDocument('ui-row-form-violation',
        `a <${SD}Service> ; <${TITLE}> "Fixture service" ; <${DESCRIPTION}> "Kept through the violation" ; <${SD}endpoint> <${endUserBase}sparql> ; <${SD}supportedLanguage> <${SD}SPARQL11Query>`);
    try {
        const { block, form } = await openForm(page, doc);

        await fillText(form, TITLE, '');
        await save(form);

        // Still a form, with the title's group marked and the untouched value still in its field.
        const titleGroup = fieldFor(block.locator('form').first(), TITLE);
        await expect(titleGroup.first()).toHaveClass(/\bis-violation\b/, { timeout: 30_000 });
        await expect(block.locator('form')).toHaveCount(1);
        await expect(fieldFor(block.locator('form').first(), DESCRIPTION).locator('textarea, input[name="ol"]').first()).toHaveValue('Kept through the violation');
        expect(await storedTitle(doc), 'the refused write changed nothing').toEqual(['Fixture service']);

        await fillText(block.locator('form').first(), TITLE, 'Fixture service, renamed');
        await save(block.locator('form').first());
        await expect(block.locator('form')).toHaveCount(0, { timeout: 30_000 });
        await expect(block).toContainText('Fixture service, renamed');
        expect(await storedTitle(doc)).toEqual(['Fixture service, renamed']);
    } finally {
        await ldh(['delete', doc], { allowFailure: true });
    }
});

// A save over a document that changed after the form was opened. The PATCH carries the ETag the
// page loaded with, so it is refused 412, and the form has to say so and stay open - the edit
// overwriting what somebody else wrote in the meantime is exactly what If-Match is there to stop.
test('refuses to save over a document that changed after the form was opened', { tag: '@owner' }, async ({ page, allowNoise }) => {
    allowNoise.push(
        { pattern: /^HTTP 412: https:\/\/[^/]+\/ui-row-form-stale\/$/, reason: 'the save is refused on purpose' },
        { pattern: /^console\.error: Failed to load resource: .* 412 /, reason: 'the browser\'s own line for the same refusal' });
    const doc = await seedDocument('ui-row-form-stale', `<${TITLE}> "Fixture stale"`);
    try {
        const { block, form } = await openForm(page, doc);

        await ldh(['patch', doc], { stdin: `DELETE { <${doc}#this> <${TITLE}> ?t } INSERT { <${doc}#this> <${TITLE}> "Changed elsewhere" } WHERE { <${doc}#this> <${TITLE}> ?t }` });

        await fillText(form, TITLE, 'Changed here');
        await save(form);

        // Said in the form, in the words the reader is shown, rather than by a class the failure markup happens to carry.
        await expect(form).toContainText('The form could not be saved', { timeout: 30_000 });
        await expect(block.locator('form')).toHaveCount(1);
        expect(await storedTitle(doc), 'what was written elsewhere stands').toEqual(['Changed elsewhere']);
    } finally {
        await ldh(['delete', doc], { allowFailure: true });
    }
});
