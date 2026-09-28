// Sorting: the direction pill, the sort-key popover, and the table's column headers.
//
// All three rewrite the query's ORDER BY and re-fetch, and all three keep their own state in sync
// with each other (ldh:SortControlsState) - which is exactly the kind of machinery that can look
// right while doing nothing. So each one is asserted on the rows it produces, and the chrome is
// checked second: a pill that lights but leaves item 01 on top has not sorted anything.
//
// Order within a kind is not asserted. ORDER BY ?kind says nothing about ties, and the store is
// free to break them however it likes; what the query promises is that the kinds come grouped
// and in order, so that is what is measured.
import { test, expect } from '../../../../lib/console.mjs';
import { goto } from '../../../../lib/settle.mjs';
import { fixtures, itemCount, itemTitle, kindCount, kinds } from '../../../../lib/fixtures.mjs';
import { controlToggle } from '../../../../lib/block.mjs';
import { fixtureView, listKinds, listRows, listTitles, rowLabel, rows, switchMode } from '../../../../lib/view.mjs';

const PAGE = 20;
const firstPage = Math.min(PAGE, itemCount);

test.describe('sorting a view', { tag: '@owner' }, () => {
    test('the direction pill reverses the rows, and again restores them', async ({ page }) => {
        await goto(page, fixtures.container);
        const block = fixtureView(page);
        await expect(listTitles(block).first()).toHaveText(itemTitle(1));
        await controlToggle(block).click();

        const direction = block.locator('.ldh-view-toolbar button.sort-dir');
        await expect(direction).not.toHaveClass(/is-desc/);
        await direction.click();

        await expect(listTitles(block).first()).toHaveText(itemTitle(itemCount));
        await expect(direction).toHaveClass(/is-desc/);
        // A reversal is not a filter: still a full first page.
        await expect(listRows(block)).toHaveCount(firstPage);

        await direction.click();
        await expect(listTitles(block).first()).toHaveText(itemTitle(1));
        await expect(direction).not.toHaveClass(/is-desc/);
    });

    test('a different sort key regroups the rows by it', async ({ page }) => {
        await goto(page, fixtures.container);
        const block = fixtureView(page);
        await expect(listTitles(block).first()).toHaveText(itemTitle(1));
        await controlToggle(block).click();

        // Stored as ORDER BY ?title, so that is what the pill says it is on.
        const keyPill = block.locator('.sort-facet button.sort-key');
        const option = name => block.locator(`.sort-facet button.sort-opt[data-var-name="${name}"]`);
        await expect(option('title')).toHaveClass(/is-on/);

        await keyPill.click();
        await option('kind').click();

        // Grouped by kind, in kind order: the first kind fills the top of the page, and the
        // sequence never steps backwards.
        await expect(listKinds(block).first()).toHaveText(kinds[0]);
        const seen = await listKinds(block).allInnerTexts();
        expect(seen).toEqual([...seen].sort());
        expect(seen.filter(kind => kind === kinds[0])).toHaveLength(kindCount(kinds[0]));

        // And the controls agree with what was done: the option is on, and the pill names it.
        await expect(option('kind')).toHaveClass(/is-on/);
        await expect(option('title')).not.toHaveClass(/is-on/);
        await expect(keyPill.locator('.val')).toHaveText(await option('kind').locator('.nm').innerText());
    });

    test('in table mode a column header sorts by its column, and the toolbar follows', async ({ page }) => {
        await goto(page, fixtures.container);
        const block = fixtureView(page);
        await controlToggle(block).click();
        await switchMode(block, 'table');

        const header = block.locator('th.sortable[data-var-name="title"]');
        await expect(header).toHaveAttribute('aria-sort', 'ascending');
        await expect(rowLabel(rows(block).first())).toHaveText(itemTitle(1));

        // The column is already the sort key, so the press reverses it.
        await header.click();

        await expect(rowLabel(rows(block).first())).toHaveText(itemTitle(itemCount));
        await expect(block.locator('th.sortable[data-var-name="title"]')).toHaveAttribute('aria-sort', 'descending');
        await expect(block.locator('.ldh-view-toolbar button.sort-dir')).toHaveClass(/is-desc/);
    });
});
