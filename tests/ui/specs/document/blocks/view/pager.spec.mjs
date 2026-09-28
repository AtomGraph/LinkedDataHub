// The pager moves the window over the result set, and the page size resizes it.
//
// Every earlier spec on the pager measured its box or read its text; none pressed it. Yet what a
// press does is a whole round trip - a new OFFSET spliced into the query, a new page of rows
// fetched, and the status re-rendered from the new offset - so a pager whose buttons stopped
// being handled would still render every number right and never show the 21st row. Hence the
// assertions are on the ROWS: the first title on the page is the one the query's ORDER BY puts
// at that offset, and the count of rows is what remains beyond the first page.
//
// The fixture view orders by title, and the titles are zero-padded, so item n is at row n.
import { test, expect } from '../../../../lib/console.mjs';
import { goto } from '../../../../lib/settle.mjs';
import { fixtures, itemCount, itemTitle } from '../../../../lib/fixtures.mjs';
import { PAGE, fixtureView, listRows, listTitles, pager } from '../../../../lib/view.mjs';

test.describe('the view pager', { tag: '@owner' }, () => {
    test.skip(itemCount <= PAGE, `UI_TESTS_ITEMS=${itemCount} leaves nothing beyond the first page`);

    test('Next shows the rows past the first page, and Previous brings it back', async ({ page }) => {
        await goto(page, fixtures.container);
        const block = fixtureView(page);
        await expect(listTitles(block).first()).toHaveText(itemTitle(1));
        await expect(listRows(block)).toHaveCount(PAGE);

        await pager(block).locator('button.pager-next').click();

        // Row 21 first, and only what is left: a re-render that ignored the offset would show
        // item 01 again, and one that dropped the LIMIT would show everything.
        await expect(listTitles(block).first()).toHaveText(itemTitle(PAGE + 1));
        await expect(listRows(block)).toHaveCount(itemCount - PAGE);
        // The status says the same in numbers, from the same offset.
        await expect(pager(block).locator('.ldh-pager-status b')).toHaveText(`${PAGE + 1}–${itemCount}`);
        await expect(pager(block).locator('.ldh-pager-page b')).toHaveText('2');
        // The last page has no Next - the button is rendered disabled and unclassed.
        await expect(pager(block).locator('button.pager-next')).toHaveCount(0);

        await pager(block).locator('button.pager-prev').click();

        await expect(listTitles(block).first()).toHaveText(itemTitle(1));
        await expect(listRows(block)).toHaveCount(PAGE);
        await expect(pager(block).locator('.ldh-pager-page b')).toHaveText('1');
    });

    test('a larger page size shows every row at once, and the pager stands down', async ({ page }) => {
        await goto(page, fixtures.container);
        const block = fixtureView(page);
        await expect(listRows(block)).toHaveCount(PAGE);

        await pager(block).locator('select.pager-size').selectOption('50');

        await expect(listRows(block)).toHaveCount(itemCount);
        await expect(listTitles(block).last()).toHaveText(itemTitle(itemCount));
        // A result set that fits on one page is not paged: ldh:RenderPager empties the pager
        // rather than rendering it disabled - which takes the size selector with it, so there is
        // no way back to a smaller page from here short of reloading. That is the rule as it
        // stands, asserted as such.
        await expect(pager(block)).toBeEmpty();
    });
});
