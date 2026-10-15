// The XHTML content block: prose, stored as RDF.
//
// The value is an `rdf:XMLLiteral` - real markup in the graph, not a string containing angle
// brackets - and the block's job is to put it in the page as markup. The failure that matters is
// the one that looks like nothing: a value escaped on the way out renders as visible tag soup, and
// a value escaped on the way IN is stored as text and can never render as anything else. Asserting
// the element the prose is made of, rather than the text it contains, is what separates them.
//
// Editing it is the RDFa editor's business and is asserted in overlays/annotation-dialog; this
// stops at the rendering, at the block being a block like any other, and at a new block surviving
// its own save.
import { test, expect } from '../../../lib/console.mjs';
import { goto, settled } from '../../../lib/settle.mjs';
import { fixtures, ldh } from '../../../lib/fixtures.mjs';

const CONTENT_MODE = 'https://w3id.org/atomgraph/linkeddatahub#ContentMode';

// The fixture's prose block: `<div xmlns="..."><p>Prose block fixture.</p></div>` as an XMLLiteral.
const prose = page => page.locator('.block.ldh-block [typeof$="#XHTML"]').first();

test('renders its literal as markup, not as text', async ({ page }) => {
    await goto(page, fixtures.container);
    await settled(page);

    await expect(prose(page)).toBeVisible();
    // The paragraph is an ELEMENT in the page. Had the literal been escaped anywhere along the
    // way, the same text would be here and this locator would find nothing.
    await expect(prose(page).locator('p').first()).toHaveText('Prose block fixture.');
});

test('is a quiet block: prose, not a card', async ({ page }) => {
    await goto(page, fixtures.container);
    await settled(page);

    const block = page.locator('.block.ldh-block:has([typeof$="#XHTML"])').first();
    await expect(block).toBeVisible();

    // No card header, unlike every other block kind. Prose IS the content, so a title bar over it
    // would be chrome around something that needs none - the block carries `is-quiet` and puts its
    // actions in a corner anchor instead, out of the reading line.
    await expect(block).toHaveClass(/is-quiet/);
    await expect(block.locator('.ldh-block-head')).toHaveCount(0);
    await expect(block.locator('.ldh-block-corner button.btn-copy-uri')).toBeAttached();
});

// A new block is saved when focus leaves its editor, and the page then redraws it from what was
// saved. The redraw waits for its values' labels, and the editor must not have taken focus back by
// then: removing a focused editor fires its focusout in Chrome, the autosave reads that as leaving
// an unchanged block and cancels it in the middle of the redraw, and the block vanishes from the
// page although it was saved. Typed, then a click outside, the way an author leaves it.
test('a new block stays on the page once its sentence is saved', { tag: '@owner' }, async ({ page }, testInfo) => {
    test.skip(testInfo.project.name !== 'owner', 'adding a block is a write');
    const { stdout: doc } = await ldh(['create', 'item', '--container', fixtures.container, '--title', 'XHTML fixture', '--slug', `xhtml-new-${testInfo.testId}`]);
    try {
        await goto(page, `${doc}?mode=${encodeURIComponent(CONTENT_MODE)}`);
        await page.locator('button.create-action.add-constructor').filter({ hasText: 'XHTML' }).first().click();
        const editable = page.locator('.rdfa-editor-content [contenteditable]').first();
        await expect(editable).toBeVisible({ timeout: 30_000 });
        await editable.click();
        await page.keyboard.type('A sentence typed into a new block.');
        await page.locator('body').click({ position: { x: 10, y: 400 } });

        // the block is back in read mode with the sentence, and stays
        const block = page.locator('.block.ldh-block').filter({ has: page.locator('[typeof$="#XHTML"]') }).first();
        await expect(block.locator('p').filter({ hasText: 'A sentence typed into a new block.' })).toBeVisible({ timeout: 30_000 });
        await expect(page.locator('.rdfa-editor-content')).toHaveCount(0);
        await page.waitForTimeout(2000);
        await expect(block.locator('p').filter({ hasText: 'A sentence typed into a new block.' })).toBeVisible();

        const { stdout: stored } = await ldh(['get', '--accept', 'application/n-triples', doc]);
        expect(stored).toContain('A sentence typed into a new block.');
    } finally {
        await ldh(['delete', doc], { allowFailure: true });
    }
});
