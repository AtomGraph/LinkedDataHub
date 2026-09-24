import { expect } from '@playwright/test';

// The dataspace drawer opens on a mousemove at the left edge of the viewport and closes when the
// pointer leaves it, so there is no button to press. clientX has to be exactly 0 - the handler
// tests `$x = 0`, not a threshold - and a move to x=2 leaves it shut with its whole subtree still
// in the DOM, which is how ad-hoc scripts came to assert against a hidden tree without noticing.
// The first move is what the second one is a move *from*: a single move to the edge is not one.
export async function openDrawer(page) {
    await page.mouse.move(200, 600);
    await page.mouse.move(0, 620);
    await expect(page.locator('.ldh-sidebar')).toBeVisible();
}
