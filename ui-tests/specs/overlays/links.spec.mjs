// The backlinks popover: navigation that goes backwards.
//
// Every other way through the product follows a statement forwards - a value is a link, a tree
// walks down, a breadcrumb walks up. This is the only one that asks the opposite question: what
// points AT this resource. In a graph that is as much a part of the resource as its own
// statements, and it is the question a hierarchy cannot answer at all.
//
// It ships closed and empty and loads its rows on first open, resolving the resource from the
// block it is anchored to at click time. So there are two claims: the deferral (nothing is
// fetched for a popover nobody opened) and the direction (the rows are subjects pointing here,
// not objects pointed at).
//
// The taxonomy makes the direction checkable: `coffee` states `skos:broader hot-drinks`, so on
// hot-drinks' page the popover must offer coffee - a statement hot-drinks does not itself carry.
import { test, expect } from '../../lib/console.mjs';
import { goto } from '../../lib/settle.mjs';
import { concept, document, labelOf } from '../../lib/taxonomy.mjs';
import { READ_MODE, inMode } from '../../lib/mode.mjs';

const blockFor = (page, name) => page.locator(`div.block.ldh-block[about="${concept(name)}"]`);
const linksButton = block => block.locator('button.tb-links').first();
const popover = block => block.locator('.links-pop').first();

test.beforeEach(({}, testInfo) => {
    test.skip(testInfo.project.name !== 'owner', 'the taxonomy fixture is owner-owned');
});

test('ships closed, and says so on the button', async ({ page }) => {
    await goto(page, inMode(document('hot-drinks'), READ_MODE));

    const block = blockFor(page, 'hot-drinks');
    await block.hover();
    await expect(linksButton(block)).toHaveAttribute('aria-pressed', 'false');
    await expect(popover(block)).toBeHidden();
});

test('opens on its button and lists what points at the resource', async ({ page }) => {
    await goto(page, inMode(document('hot-drinks'), READ_MODE));

    const block = blockFor(page, 'hot-drinks');
    await block.hover();
    await linksButton(block).click();

    await expect(linksButton(block)).toHaveAttribute('aria-pressed', 'true');
    await expect(popover(block)).toBeVisible();

    // coffee names hot-drinks as its broader concept. hot-drinks says nothing about coffee, so a
    // popover that listed this resource's own objects would not have it.
    await expect(popover(block).locator(`a[href*="${concept('coffee')}"], a[title="${concept('coffee')}"]`).first())
        .toBeVisible({ timeout: 30_000 });
    await expect(popover(block)).toContainText(labelOf('coffee'));
});
