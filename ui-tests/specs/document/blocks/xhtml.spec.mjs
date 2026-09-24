// The XHTML content block: prose, stored as RDF.
//
// The value is an `rdf:XMLLiteral` - real markup in the graph, not a string containing angle
// brackets - and the block's job is to put it in the page as markup. The failure that matters is
// the one that looks like nothing: a value escaped on the way out renders as visible tag soup, and
// a value escaped on the way IN is stored as text and can never render as anything else. Asserting
// the element the prose is made of, rather than the text it contains, is what separates them.
//
// Editing it is the RDFa editor's business and is asserted in overlays/annotation-dialog; this
// stops at the rendering and at the block being a block like any other.
import { test, expect } from '../../../lib/console.mjs';
import { goto, settled } from '../../../lib/settle.mjs';
import { fixtures } from '../../../lib/fixtures.mjs';

// The fixture's prose block: `<div xmlns="..."><p>Prose block fixture.</p></div>` as an XMLLiteral.
const prose = page => page.locator('.block.ldh-block [typeof$="#XHTML"]').first();

test.beforeEach(({}, testInfo) => {
    test.skip(testInfo.project.name !== 'owner', 'the fixture container is owner-owned');
});

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
