// The map: the same documents, placed.
//
// A map is a rendering mode rather than a thing in the document - the reader asks for
// `?mode=MapMode` and the platform draws whatever of the current results has coordinates. That is
// why nothing about it appears on a page that did not ask, and why this spec addresses it through
// the URL: the mode IS the request.
//
// The fixture has no geodata, so what is asserted is the one thing that holds either way: the
// canvas is built and the tiles it is made of arrive. A map with no pins is a correct answer to
// "where are these documents" when none of them says; a map that never drew is not.
import { test, expect } from '../../../lib/console.mjs';
import { goto } from '../../../lib/settle.mjs';
import { fixtures } from '../../../lib/fixtures.mjs';
import { MAP_MODE, inMode } from '../../../lib/mode.mjs';

const canvas = page => page.locator('.map-canvas').first();

test('draws when the URL asks for it, and not before', async ({ page }) => {
    await goto(page, fixtures.container);
    // Hidden rather than absent: the host element is part of every document's shell, and the mode
    // is what brings it forward. Asserting its absence would be asserting the wrong mechanism.
    await expect(canvas(page), 'a map was drawn on a page that did not ask for one').toBeHidden();

    await goto(page, inMode(fixtures.container, MAP_MODE));
    await expect(canvas(page)).toBeVisible({ timeout: 30_000 });
});

test('is a real map surface, not an empty frame', async ({ page }) => {
    await goto(page, inMode(fixtures.container, MAP_MODE));

    // OpenLayers builds its own viewport inside the canvas element. Its presence is the difference
    // between "the map library ran" and "a div with a height was reserved for it".
    await expect(canvas(page).locator('canvas, .ol-viewport, .ol-layer').first())
        .toBeVisible({ timeout: 30_000 });
});
