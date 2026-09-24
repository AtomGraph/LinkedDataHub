// The statement grid: a resource's properties, read.
//
// This is the most-rendered component in the product and the one with the least coverage, because
// everything else is more interesting to test. It is a definition list by construction - `dl` of
// `dt` predicate and `dd` values - which is the markup saying what the data is: a set of
// statements about one subject, grouped by predicate, with a predicate able to carry more than
// one value.
//
// The grouping is the claim worth having. A grid that emitted one row per STATEMENT rather than
// one group per PREDICATE would look almost identical with single-valued data and fall apart on a
// resource that states the same property twice - and the fixture's documents, being ordinary
// documents, have both kinds.
import { test, expect } from '../../lib/console.mjs';
import { goto, settled } from '../../lib/settle.mjs';
import { fixtures } from '../../lib/fixtures.mjs';

const grid = page => page.locator('dl.ldh-prop-form').first();
const groups = page => grid(page).locator('div.ldh-prop-group');

// The statement grid lives on the CONTAINER document, not on an item: an item renders its blocks
// and no property list at all, which is how three assertions once came to be written against a
// document that could never have satisfied them.
test.beforeEach(({}, testInfo) => {
    test.skip(testInfo.project.name !== 'owner', 'the fixture container is owner-owned');
});

test('states the resource as a list of predicates and their values', async ({ page }) => {
    await goto(page, fixtures.container);
    await settled(page);

    await expect(grid(page)).toBeVisible();
    expect(await groups(page).count(), 'the grid rendered no property at all').toBeGreaterThan(0);

    // A definition list, used as one: the predicate names the term, the values are its
    // definitions. The pair is what makes the markup a statement rather than a table row.
    const first = groups(page).first();
    await expect(first.locator('dt.label')).toHaveCount(1);
    expect(await first.locator('dd.ldh-prop-row').count()).toBeGreaterThan(0);
});

test('groups a predicate once, however many values it carries', async ({ page }) => {
    await goto(page, fixtures.container);
    await settled(page);

    // Every group names a different predicate. A repeated one would mean the grid is emitting a
    // group per statement and only looking grouped because most predicates happen to be single.
    const predicates = await groups(page).evaluateAll(nodes =>
        nodes.map(node => node.querySelector('dt.label')?.textContent?.trim() ?? ''));

    expect(predicates.length).toBeGreaterThan(0);
    expect(new Set(predicates).size, `a predicate was grouped twice: ${predicates.join(', ')}`)
        .toBe(predicates.length);
});
