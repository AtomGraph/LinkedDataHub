// A URI typed into a form that is not one.
//
// A resource field is a combobox whose text is submitted as the object's URI exactly as typed:
// nothing rewrites it, and the type-ahead only helps find a URI. So the save is where a malformed
// one is caught, and the server is what decides it, by the same IRI rules its parsers apply to
// every other writer. What the reader has to get back is the form as they left it - the field
// marked, the other values still there - and a document the refused write did not change.
//
// Both edit surfaces - the document's edit dialog and a block's inline form - PATCH a SPARQL update,
// and they report the refusal through different response handlers, so both are driven. Some
// malformed URIs pass the SPARQL lexer and are caught only by checking the parsed update, which
// used to let them be stored, so one of those is driven too.
//
// A bare word is a valid relative reference, which the server resolves against the document - so
// `foo` would be stored as `<document/foo>`. Only the browser knows a person typed it into a URI
// field, so that one is refused before anything is sent.
//
// The update is written as text, with each typed URI between angle brackets and each language tag
// after its literal, as typed. A `>` in a URI, or a tag that is not one, would carry on into the
// rest of the update and add statements nobody typed into a field of their own, which the server
// cannot tell from any other update. Those are refused before anything is sent as well.
import { test, expect } from '../../lib/console.mjs';
import { goto } from '../../lib/settle.mjs';
import { endUserBase } from '../../lib/stack.mjs';
import { itemUri, ldh } from '../../lib/fixtures.mjs';
import { openDocumentForm } from '../../lib/modal.mjs';
import { fieldFor, save } from '../../lib/form.mjs';

const TITLE = 'http://purl.org/dc/terms/title';
const SEE_ALSO = 'http://www.w3.org/2000/01/rdf-schema#seeAlso';
const PRIMARY_TOPIC = 'http://xmlns.com/foaf/0.1/primaryTopic';
const INVALID_URI = 'Not a valid URI';
const RELATIVE_URI = 'Enter a full URI, starting with a scheme such as https:';
const INVALID_LANGUAGE = 'Not a valid language tag, such as en or en-GB';

test.beforeEach(({}, testInfo) => {
    test.skip(testInfo.project.name !== 'owner', 'editing is offered to an agent who may write');
});

// A document of its own whose #this is described by the given predicate-object pairs. Returns the document's URL.
async function seedDocument(slug, description) {
    const { stdout: doc } = await ldh(['create', 'item', '--container', endUserBase, '--title', 'Fixture document', '--slug', slug]);
    await ldh(['patch', doc], { stdin: `INSERT {\n  <${doc}#this> ${description} .\n} WHERE {}` });
    return doc;
}

// The objects a subject has for a predicate in the stored document, read over the API rather than off the page.
async function storedObjects(doc, subject, predicate) {
    const { stdout } = await ldh(['get', '--accept', 'application/n-triples', doc]);
    return stdout.split('\n').filter(line => line.startsWith(`<${subject}> <${predicate}> `)).map(line => line.slice(`<${subject}> <${predicate}> `.length).replace(/ \.$/, ''));
}

// The refusal the server answers a malformed URI with, and the browser's own line for it.
const refused = (allowNoise, doc) => allowNoise.push(
    { pattern: new RegExp(`^HTTP 422: ${doc.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}$`), reason: 'the save is refused on purpose' },
    { pattern: /^console\.error: Failed to load resource: .* 422 /, reason: 'the browser\'s own line for the same refusal' });

// The field is marked, says why in the reader's words, and still holds what was typed.
async function expectMarked(group, typed, message) {
    await expect(group.first()).toHaveClass(/\bis-violation\b/, { timeout: 30_000 });
    await expect(group.first().locator('[role="alert"] span:not(.msi)')).toHaveText(message);
    await expect(group.first().locator('input.resource-combobox')).toHaveValue(typed);
    await expect(group.first().locator('input.resource-combobox')).toHaveAttribute('aria-invalid', 'true');
}

// The document's edit dialog, whose update the SPARQL lexer stops at the space.
test('marks a malformed URI in the document form and keeps the dialog open', { tag: '@owner' }, async ({ page, allowNoise }) => {
    const doc = await seedDocument('ui-uri-syntax-put', `<${TITLE}> "Fixture put"`);
    refused(allowNoise, doc);
    try {
        await goto(page, doc);
        const modal = await openDocumentForm(page);
        const form = modal.locator('form').first();
        const topic = fieldFor(form, PRIMARY_TOPIC);
        await topic.locator('input.resource-combobox').fill('http://ex .com/');
        await save(form);

        await expectMarked(fieldFor(modal.locator('form').first(), PRIMARY_TOPIC), 'http://ex .com/', INVALID_URI);
        await expect(modal).toBeVisible();
        expect(await storedObjects(doc, doc, PRIMARY_TOPIC), 'the refused write changed nothing').toEqual([]);
    } finally {
        await ldh(['delete', doc], { allowFailure: true });
    }
});

// A block's form. Both kinds of malformed URI are driven: one the SPARQL lexer refuses (a space),
// and one it lets through as an IRI reference that is not one (an unterminated IPv6 host), which
// without a check of the parsed update would be stored. Both have a scheme, so the browser sends them.
for (const typed of ['http://ex .com/', 'http://[::1']) {
    test(`marks ${JSON.stringify(typed)} in a block's form and keeps it open`, { tag: '@owner' }, async ({ page, allowNoise }) => {
        const slug = `ui-uri-syntax-patch-${typed.includes('[') ? 'ipv6' : 'space'}`;
        const doc = await seedDocument(slug, `<${TITLE}> "Fixture patch" ; <${SEE_ALSO}> <${itemUri(1)}>`);
        refused(allowNoise, doc);
        try {
            await goto(page, doc);
            const block = page.locator(`div.block.ldh-block[about="${doc}#this"]`);
            await block.locator('button.btn-edit').first().click();
            const form = block.locator('form').first();
            await expect(form).toBeVisible({ timeout: 30_000 });

            // The committed chip gives way to the lookup, and what is typed there is the URI submitted.
            const group = fieldFor(form, SEE_ALSO);
            await group.locator('span.ac-cb-committed button.add-combobox').first().click();
            await group.locator('input.resource-combobox').fill(typed);
            await save(form);

            await expectMarked(fieldFor(block.locator('form').first(), SEE_ALSO), typed, INVALID_URI);
            await expect(block.locator('form')).toHaveCount(1);
            expect(await storedObjects(doc, `${doc}#this`, SEE_ALSO), 'the refused write changed nothing').toEqual([`<${itemUri(1)}>`]);
        } finally {
            await ldh(['delete', doc], { allowFailure: true });
        }
    });
}

// A bare word would be stored as a URI relative to the document. It is refused before the save is
// sent, so no request reaches the server at all.
test('refuses a URI without a scheme before sending the save', { tag: '@owner' }, async ({ page }) => {
    const doc = await seedDocument('ui-uri-syntax-relative', `<${TITLE}> "Fixture relative"`);
    try {
        await goto(page, doc);
        const modal = await openDocumentForm(page);
        const form = modal.locator('form').first();
        await fieldFor(form, PRIMARY_TOPIC).locator('input.resource-combobox').fill('foo');

        const writes = [];
        page.on('request', request => { if (['PUT', 'POST', 'PATCH'].includes(request.method())) writes.push(`${request.method()} ${request.url()}`); });
        await save(form);

        await expectMarked(fieldFor(modal.locator('form').first(), PRIMARY_TOPIC), 'foo', RELATIVE_URI);
        expect(writes, 'nothing was sent').toEqual([]);
        expect(await storedObjects(doc, doc, PRIMARY_TOPIC), 'nothing was written').toEqual([]);
    } finally {
        await ldh(['delete', doc], { allowFailure: true });
    }
});

// The writes the page sends from now on.
function recordWrites(page) {
    const writes = [];
    page.on('request', request => { if (['PUT', 'POST', 'PATCH'].includes(request.method())) writes.push(`${request.method()} ${request.url()}`); });
    return writes;
}

// Opens the inline form of the document's #this block.
async function openBlockForm(page, doc) {
    const block = page.locator(`div.block.ldh-block[about="${doc}#this"]`);
    await block.locator('button.btn-edit').first().click();
    const form = block.locator('form').first();
    await expect(form).toBeVisible({ timeout: 30_000 });
    return { block, form };
}

// A URI with a `>` in it would close the IRI early: what follows is a second object the update would store.
test('refuses a URI that would end early in the update before sending the save', { tag: '@owner' }, async ({ page }) => {
    const doc = await seedDocument('ui-uri-syntax-bracket', `<${TITLE}> "Fixture bracket" ; <${SEE_ALSO}> <${itemUri(1)}>`);
    const typed = 'http://example.com/a> , <http://example.com/b';
    try {
        await goto(page, doc);
        const { block, form } = await openBlockForm(page, doc);
        const group = fieldFor(form, SEE_ALSO);
        await group.locator('span.ac-cb-committed button.add-combobox').first().click();
        await group.locator('input.resource-combobox').fill(typed);

        const writes = recordWrites(page);
        await save(form);

        await expectMarked(fieldFor(block.locator('form').first(), SEE_ALSO), typed, INVALID_URI);
        expect(writes, 'nothing was sent').toEqual([]);
        expect(await storedObjects(doc, `${doc}#this`, SEE_ALSO), 'nothing was written').toEqual([`<${itemUri(1)}>`]);
    } finally {
        await ldh(['delete', doc], { allowFailure: true });
    }
});

// A language tag is written after the literal as it is, so one that is not a tag would carry on into the update.
test('refuses a language tag that is not one before sending the save', { tag: '@owner' }, async ({ page }) => {
    const doc = await seedDocument('ui-uri-syntax-lang', `<${TITLE}> "Fixture lang"@en ; <${SEE_ALSO}> <${itemUri(1)}>`);
    const typed = `en ; <${SEE_ALSO}> <http://example.com/b>`;
    try {
        await goto(page, doc);
        const { block, form } = await openBlockForm(page, doc);
        await fieldFor(form, TITLE).locator('input[name="ll"]').fill(typed);

        const writes = recordWrites(page);
        await save(form);

        const group = fieldFor(block.locator('form').first(), TITLE);
        await expect(group.first()).toHaveClass(/\bis-violation\b/, { timeout: 30_000 });
        await expect(group.first().locator('[role="alert"] span:not(.msi)')).toHaveText(INVALID_LANGUAGE);
        await expect(group.first().locator('input[name="ll"]')).toHaveValue(typed);
        // The language field is the one at fault, not the literal beside it.
        await expect(group.first().locator('input[name="ll"]')).toHaveAttribute('aria-invalid', 'true');
        await expect(group.first().locator('input[name="ol"]')).not.toHaveAttribute('aria-invalid', 'true');
        expect(writes, 'nothing was sent').toEqual([]);
        expect(await storedObjects(doc, `${doc}#this`, SEE_ALSO), 'nothing was written').toEqual([`<${itemUri(1)}>`]);
    } finally {
        await ldh(['delete', doc], { allowFailure: true });
    }
});
