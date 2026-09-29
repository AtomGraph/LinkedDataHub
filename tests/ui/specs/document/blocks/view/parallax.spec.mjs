// A pivot re-centres the view on what the rows point at; removing the step brings the rows back.
//
// blocks/chrome.spec asserts that a pill press leaves a step chip and names the predicate on the
// status line - the click was handled. Handled is not the same as followed: the pivot rewrites the
// query so its focus becomes the objects of the predicate, and the rows are re-fetched from that
// query. Every fixture item names the one container through sioc:has_container, so following that
// predicate outward has exactly one right answer, and it is a different document from any row that
// was there before. Removing the chip rebuilds the query from the stored SELECT, which the rows
// prove by being the fixture items again, in their original order.
//
// What the rewind does NOT restore is the page. The view renders its first page under a default
// LIMIT it splices in when the stored query has none, and the rewind rebuilds from the stored
// SELECT string (ldh:RemoveParallaxStep) without splicing it in again - so the rows come back
// unpaged, all 25 of them, and the pager stands down as though the set fitted. Measured 2026-09-28
// on develop. The second test pins that as an expected failure: it passes the day the rewind
// pages again, and then reports the annotation as stale.
import { test, expect } from '../../../../lib/console.mjs';
import { goto } from '../../../../lib/settle.mjs';
import { containerTitle, fixtures, itemCount, itemTitle } from '../../../../lib/fixtures.mjs';
import { controlToggle } from '../../../../lib/block.mjs';
import { PAGE, counting, fixtureView, listRows, listTitles, pager, resultCount } from '../../../../lib/view.mjs';

const HAS_CONTAINER = 'http://rdfs.org/sioc/ns#has_container';

test.describe('pivoting a view', { tag: '@owner' }, () => {
    test('follows the predicate to what the rows point at, and the step chip rewinds', async ({ page }) => {
        await goto(page, fixtures.container);
        const block = fixtureView(page);
        await expect(listTitles(block).first()).toHaveText(itemTitle(1));
        await controlToggle(block).click();

        // Outward, by predicate: the pill is addressed by what it would do, not by its position.
        const pill = block.locator(`.ldh-pivot-bar button.ldh-pivot-pill[data-dir="out"][title="${HAS_CONTAINER}"]`);
        await expect(pill).toBeVisible();
        await pill.click();

        // One row, and it is the container - the document every item's predicate points at.
        await expect(listRows(block)).toHaveCount(1);
        await expect(listRows(block)).toHaveAttribute('href', fixtures.container);
        await expect(listTitles(block)).toHaveText(containerTitle);
        await expect(resultCount(block)).toHaveText(counting(1));

        // The step is a chip in the toolbar, and its x rewinds to the query as stored.
        const step = block.locator('.ldh-view-toolbar .parallax-steps button.parallax-step');
        await expect(step).toHaveCount(1);
        await step.locator('span.x').click();

        await expect(step).toHaveCount(0);
        await expect(listTitles(block).first()).toHaveText(itemTitle(1));
        await expect(resultCount(block)).toHaveText(counting(itemCount));
        // The items, not the container: whichever page the rewind lands on, the container is not
        // among its rows.
        await expect(listTitles(block).filter({ hasText: containerTitle })).toHaveCount(0);
    });

    test('rewinding brings the first page back, not the whole set', async ({ page }) => {
        test.skip(itemCount <= PAGE, `UI_TESTS_ITEMS=${itemCount} fits on one page, so there is nothing to lose`);
        test.fail(true, 'ldh:RemoveParallaxStep rebuilds from the stored SELECT without the default LIMIT the first render spliced in');

        await goto(page, fixtures.container);
        const block = fixtureView(page);
        await expect(listRows(block)).toHaveCount(PAGE);
        await controlToggle(block).click();

        await block.locator(`.ldh-pivot-bar button.ldh-pivot-pill[data-dir="out"][title="${HAS_CONTAINER}"]`).click();
        await expect(listRows(block)).toHaveCount(1);
        await block.locator('.ldh-view-toolbar .parallax-steps button.parallax-step span.x').click();

        await expect(listTitles(block).first()).toHaveText(itemTitle(1));
        await expect(listRows(block)).toHaveCount(PAGE);
        await expect(pager(block)).not.toBeEmpty();
    });
});
