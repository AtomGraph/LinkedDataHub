// The footer, which closes the page and says whose software it is.
//
// Small, but it is load-bearing for one other spec: view-overflow measures whether a block's rows
// have escaped their card by asking where the footer starts, on the grounds that the footer is
// the first thing after the document body. That argument only holds while the footer really is
// last and really is in the flow, so those two facts get asserted here rather than assumed there.
import { test, expect } from '../../lib/console.mjs';
import { goto, settled } from '../../lib/settle.mjs';
import { itemUri } from '../../lib/fixtures.mjs';
import { endUserBase } from '../../lib/stack.mjs';

const footer = page => page.locator('.ldh-footer');

test.beforeEach(({}, testInfo) => {
    test.skip(testInfo.project.name !== 'owner',
        'a chrome assertion; on a virgin instance the fixture is not readable anonymously at all');
});

test('closes the page, below the document it belongs to', async ({ page }) => {
    await goto(page, itemUri(1));
    await settled(page);

    await expect(footer(page)).toBeVisible();
    await expect(footer(page)).toHaveAttribute('role', 'contentinfo');

    // In the flow and last: the geometric claim view-overflow leans on.
    const { body, foot } = await page.evaluate(() => ({
        body: document.querySelector('.document-body').getBoundingClientRect().bottom + scrollY,
        foot: document.querySelector('.ldh-footer').getBoundingClientRect().top + scrollY,
    }));
    expect(foot).toBeGreaterThanOrEqual(body - 1);
});

test('its wordmark leads back to the dataspace it belongs to', async ({ page }) => {
    await goto(page, itemUri(1));
    await settled(page);

    // The dataspace root, not linkeddatahub.com: the footer's outbound links are about the
    // software, and the wordmark is about the instance.
    await expect(footer(page).locator('a.ldh-wordmark')).toHaveAttribute('href', endUserBase);
});
