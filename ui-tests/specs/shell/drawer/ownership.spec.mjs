// The drawer is owned by the pointer or by the focus, and is inert whenever it is neither.
//
// It has no button that opens it: a mousemove with clientX exactly 0 does, and the handler tests
// `$x = 0` rather than a threshold, so a move to x=2 is not a near miss - it is nothing at all.
// Closing is the interesting half. The stylesheet's own framing is that an open drawer is owned
// by the pointer OR the focus, and each of the two events that can end one ownership closes it
// only after checking the other: the pointer leaving while the search input still holds focus
// must NOT close the drawer out from under someone typing in it. Nothing is tracked between
// events, so that cross-check is the whole mechanism, and it is what these assertions pin.
//
// `inert` is the other half, and the reason a visibility assertion alone would be too weak. A
// closed drawer keeps its whole subtree in the DOM - which is how ad-hoc scripts came to assert
// against a tree nobody could reach - so the attribute is what actually takes it out of the tab
// order and away from assistive technology. It ships set, from the server.
//
// Escape is shared with the modal layer and the sharing is explicit: the drawer's handler fires
// only while no `.ac-backdrop.modal` is in the page, so a dialog opened from inside the drawer
// takes the key and the drawer stays put beneath it. The search modal is what makes that
// testable without the pointer ever leaving the drawer to reach some other affordance.
import { test, expect } from '../../../lib/console.mjs';
import { goto } from '../../../lib/settle.mjs';
import { itemUri } from '../../../lib/fixtures.mjs';
import { openDrawer } from '../../../lib/drawer.mjs';

const drawer = page => page.locator('.ldh-sidebar');
const search = page => page.locator('.ldh-sidebar input').first();

// A chrome assertion, not an authorization one: the drawer is the same for either agent, and on a
// virgin instance the fixture is not readable anonymously at all - which would measure that
// instead.
test.beforeEach(({}, testInfo) => {
    test.skip(testInfo.project.name !== 'owner',
        'a chrome assertion; the authorization axis would measure the same thing twice');
});

test('opens on a move to the very edge, and not on one merely near it', async ({ page }) => {
    await goto(page, itemUri(1));

    await page.mouse.move(200, 600);
    await page.mouse.move(2, 620);
    await expect(drawer(page), 'x=2 is not a near miss: the handler tests $x = 0').toBeHidden();

    await page.mouse.move(0, 620);
    await expect(drawer(page)).toBeVisible();
});

test('is inert while closed, its subtree being present throughout', async ({ page }) => {
    await goto(page, itemUri(1));

    // Present and unreachable, both at once - the state a visibility check alone would miss.
    await expect(drawer(page)).toBeAttached();
    await expect(drawer(page)).toHaveAttribute('inert', '');

    await openDrawer(page);
    await expect(drawer(page)).not.toHaveAttribute('inert', '');
});

test('closes when the pointer leaves it for the page', async ({ page }) => {
    await goto(page, itemUri(1));
    await openDrawer(page);

    // The drawer opens UNDER a stationary cursor, so the browser has never dispatched an
    // enter for it and a move away would fire mouseout on whatever the pointer was over
    // before - the page, whose handler is not this one. One move inside the open drawer is
    // what makes the pointer its owner, which is the state this then takes away.
    await page.mouse.move(40, 620);
    await page.mouse.move(600, 400);
    await expect(drawer(page)).toBeHidden();
    await expect(drawer(page)).toHaveAttribute('inert', '');
});

test('stays open while the focus is inside it, though the pointer has left', async ({ page }) => {
    await goto(page, itemUri(1));
    await openDrawer(page);

    // The search input is the reason the cross-check exists: closing the drawer because the
    // pointer wandered off would take the field away mid-word.
    await search(page).click();
    await search(page).pressSequentially('Fix');
    await page.mouse.move(600, 400);

    await expect(drawer(page)).toBeVisible();
    await expect(search(page)).toBeFocused();
});

test('Escape closes it', async ({ page }) => {
    await goto(page, itemUri(1));
    await openDrawer(page);

    await page.keyboard.press('Escape');
    await expect(drawer(page)).toBeHidden();
});

test('Escape leaves it alone while a dialog owns the key', async ({ page }) => {
    await goto(page, itemUri(1));
    await openDrawer(page);

    // Submitted from inside the drawer, so the pointer never leaves it to reach the dialog - the
    // drawer is still pointer-owned while the modal is up, which is the state being measured.
    await search(page).fill('Fixture');
    await search(page).press('Enter');
    const modal = page.locator('div.modal, .ac-modal').first();
    await expect(modal).toBeVisible();

    await page.keyboard.press('Escape');
    await expect(modal, 'the dialog takes the key').toBeHidden();
    await expect(drawer(page), 'and the drawer beneath it is left standing').toBeVisible();

    // With the key handed back, it closes the drawer as it did before.
    await page.keyboard.press('Escape');
    await expect(drawer(page)).toBeHidden();
});
