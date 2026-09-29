// The chart block, drawn in the design system's colours.
//
// Google Charts takes concrete colour strings, not `var()` references, so ac:draw-chart resolves the
// design tokens with ldh:css-token() at draw time - the series palette, the axis text and titles,
// the gridlines and the baseline. It used to look each token up in the map ixsl:style() returns,
// which Saxon-JS builds by ENUMERATING getComputedStyle, and Chromium 131 - still what Playwright
// bundled into its older releases - enumerates no custom properties at all. Every token came back
// empty, and Google Charts failed on the empty colours before drawing anything: "Cannot read
// properties of null (reading 'color')", on every chart on the page.
//
// This suite's own Chromium does enumerate them, so the spec takes the enumeration away the way
// Chromium 131 did - the properties are still there by name, just not listed - and asserts that
// the bars are the token's colour rather than merely that something drew.
import { test, expect } from '../../../../lib/console.mjs';
import { goto } from '../../../../lib/settle.mjs';
import { fixtures } from '../../../../lib/fixtures.mjs';
import { canvas, chartBlock, drawing } from '../../../../lib/chart.mjs';

// The first colour of the palette ac:draw-chart hands the chart, so the one the single series is
// drawn in.
const SERIES_TOKEN = '--ldh-blue-500';

test('draws in the design tokens where the browser does not enumerate custom properties', async ({ page }) => {
    await page.addInitScript(() => {
        const computed = window.getComputedStyle;
        window.getComputedStyle = function (...args) {
            const style = computed.apply(this, args);
            const listed = Array.from(style).filter(name => !name.startsWith('--'));
            return new Proxy(style, {
                get(target, property) {
                    if (property === 'length') return listed.length;
                    if (property === 'item') return index => listed[index] ?? '';
                    if (property === Symbol.iterator) return listed[Symbol.iterator].bind(listed);
                    if (typeof property === 'string' && /^\d+$/.test(property)) return listed[property];
                    // Bound to the declaration itself: its methods throw "Illegal invocation" on a proxy.
                    const value = Reflect.get(target, property, target);
                    return typeof value === 'function' ? value.bind(target) : value;
                },
            });
        };
    });

    await goto(page, fixtures.container);

    const block = chartBlock(page);
    await expect(drawing(block), 'the chart draws').toBeVisible({ timeout: 30_000 });

    // Both sides normalised by the browser, since the token may be declared in any colour syntax and
    // Google Charts writes the fill as hex.
    const { token, fills } = await canvas(block).evaluate((node, name) => {
        const probe = document.createElement('span');
        document.body.append(probe);
        const normalise = colour => { probe.style.color = ''; probe.style.color = colour; return getComputedStyle(probe).color; };
        const token = getComputedStyle(document.documentElement).getPropertyValue(name).trim();
        const fills = [...node.querySelectorAll('svg rect[fill]')].map(rect => normalise(rect.getAttribute('fill')));
        const result = { token: token && normalise(token), fills };
        probe.remove();
        return result;
    }, SERIES_TOKEN);

    expect(token, `${SERIES_TOKEN} resolves on this page`).toBeTruthy();
    expect(fills, `the series is drawn in ${SERIES_TOKEN}`).toContain(token);
});
