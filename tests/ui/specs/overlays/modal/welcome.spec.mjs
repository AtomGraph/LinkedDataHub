// The welcome dialog: shown once, to an agent who has just arrived.
//
// It is the one modal that is a moment rather than a task, and the only one whose contract is
// about NOT appearing: it greets an agent the first time their browser is here and must then stay
// out of the way forever, because a greeting that returns is an obstacle. The memory is a cookie,
// so the whole claim is observable - clear it and the dialog is back, dismiss it and it is gone
// across a reload.
//
// Every other spec in the suite depends on this working. `lib/console.mjs` seeds the cookie for
// each page it opens precisely because a centred backdrop intercepts every click a spec would
// make; this is the one spec that clears it again, which is why it is also the one that would
// notice if dismissing ever stopped being remembered.
import { test, expect } from '../../../lib/console.mjs';
import { goto, settled } from '../../../lib/settle.mjs';
import { itemUri } from '../../../lib/fixtures.mjs';

const COOKIE = 'LinkedDataHub.first-time-message';
const welcome = page => page.locator('.modal-first-time-message');

test.beforeEach(({}, testInfo) => {
    test.skip(testInfo.project.name !== 'owner', 'the greeting is for an agent who has been identified');
});

test('greets an agent whose browser has not been here before', { tag: '@owner' }, async ({ page }) => {
    // The suite's every other page arrives as a returning reader. This one arrives new.
    await page.context().clearCookies({ name: COOKIE });

    await goto(page, itemUri(1));
    await expect(welcome(page)).toBeVisible({ timeout: 30_000 });
});

test('and never again once it has been dismissed', { tag: '@owner' }, async ({ page }) => {
    await page.context().clearCookies({ name: COOKIE });
    await goto(page, itemUri(1));
    await expect(welcome(page)).toBeVisible({ timeout: 30_000 });

    await welcome(page).locator('span.ac-modal-x button, button.btn-close').first().click();
    await expect(welcome(page)).toBeHidden();

    // A reload is the test of whether it was remembered rather than merely closed: dismissing
    // writes the cookie the suite otherwise seeds by hand.
    await goto(page, itemUri(1));
    await settled(page);
    await expect(welcome(page)).toHaveCount(0);
});
