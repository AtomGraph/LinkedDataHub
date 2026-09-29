// A facet filters the rows, not just the pill.
//
// blocks/chrome.spec asserts that picking a facet value lights the pill and names the value on
// the status line. Both are true of a facet whose FILTER never reached the query. What a facet is
// for is fewer rows - the ones carrying the value - and a count that says so; and since values
// within one facet are OR-ed, a second value widens the set rather than emptying it. The fixture
// assigns kinds by index modulo three, so each count is known rather than merely smaller.
import { test, expect } from '../../../../lib/console.mjs';
import { goto } from '../../../../lib/settle.mjs';
import { fixtures, itemCount, itemTitle, kindCount, kinds } from '../../../../lib/fixtures.mjs';
import { controlToggle } from '../../../../lib/block.mjs';
import { PAGE, counting, facetFor, facetOption, fixtureView, listKinds, listRows, listTitles, pager, resultCount } from '../../../../lib/view.mjs';

const [alpha, beta] = kinds;

test.describe('filtering a view by a facet', { tag: '@owner' }, () => {
    test('a value keeps only the rows that carry it, a second widens, clearing restores', async ({ page }) => {
        await goto(page, fixtures.container);
        const block = fixtureView(page);
        await expect(listTitles(block).first()).toHaveText(itemTitle(1));
        await expect(resultCount(block)).toHaveText(counting(itemCount));
        await controlToggle(block).click();

        // The facet over ?kind, which the fixture view projects from dct:description.
        const facet = facetFor(block, 'kind');
        await facet.locator('button.facet-pill').click();
        await facetOption(facet, alpha).click();

        // Every row is of that kind, there are exactly as many as were seeded of it, and the
        // count restates it. Fewer than a page, so the pager stands down too.
        await expect(listRows(block)).toHaveCount(kindCount(alpha));
        await expect(listKinds(block)).toHaveText(Array(kindCount(alpha)).fill(alpha));
        await expect(resultCount(block)).toHaveText(counting(kindCount(alpha)));
        if (kindCount(alpha) < PAGE) await expect(pager(block)).toBeEmpty();
        await expect(facet.locator('button.facet-pill')).toHaveClass(/is-active/);

        // A second value in the same facet is an alternative, not a further restriction.
        if (!await facetOption(facet, beta).isVisible()) await facet.locator('button.facet-pill').click();
        await facetOption(facet, beta).click();
        await expect(listRows(block)).toHaveCount(Math.min(PAGE, kindCount(alpha) + kindCount(beta)));
        await expect(resultCount(block)).toHaveText(counting(kindCount(alpha) + kindCount(beta)));
        const seen = await listKinds(block).allInnerTexts();
        expect(new Set(seen)).toEqual(new Set([alpha, beta]));

        // Clear filters, and the whole set is back.
        await block.locator('.ldh-view-toolbar button.facet-clear-all').click();
        await expect(resultCount(block)).toHaveText(counting(itemCount));
        await expect(listRows(block)).toHaveCount(Math.min(PAGE, itemCount));
        await expect(listTitles(block).first()).toHaveText(itemTitle(1));
        await expect(facet.locator('button.facet-pill')).not.toHaveClass(/is-active/);
    });
});
