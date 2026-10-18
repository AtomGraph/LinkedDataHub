// The heading anchor: the pilcrow a heading with an id carries, linking to its own section.
//
// Emitted by the ldh:XHTMLContent override for h1-h6[@id] (imports/default.xsl), so it appears
// wherever authored prose does. Three claims:
//
//   · IT ADDRESSES THE SECTION. The href is the bare fragment, which resolves against the page the
//     reader is on - copying the link copies the section URI.
//   · IT IS RENDERING, NOT CONTENT. Only the heading's own text is the heading; the pilcrow is
//     added on the way out and never reaches the stored literal.
//   · IT STAYS OUT OF THE READING LINE. Opacity until the heading is hovered, like is-reveal.
import { test, expect } from '../../lib/console.mjs';
import { goto, loaded } from '../../lib/settle.mjs';
import { fixtures, proseSection } from '../../lib/fixtures.mjs';

const prose = page => page.locator('.block.ldh-block:has([typeof$="#XHTML"])').first();
const heading = page => prose(page).locator(`h2[id="${proseSection}"]`);
const anchor = page => heading(page).locator('> a.ldh-heading-anchor');

async function open(page) {
    await goto(page, fixtures.container);
    await loaded(page);
}

test('links the heading to its own fragment', async ({ page }) => {
    await open(page);

    await expect(anchor(page)).toHaveCount(1);
    await expect(anchor(page)).toHaveAttribute('href', `#${proseSection}`);
    await expect(anchor(page)).toHaveText('¶');
    await expect(anchor(page)).toHaveAttribute('aria-label', /.+/);

    const resolved = await anchor(page).evaluate(a => a.href);
    expect(resolved).toBe(new URL(`#${proseSection}`, page.url()).href);
});

test('stays out of the reading line until the heading is hovered', async ({ page }) => {
    await open(page);

    const opacity = () => anchor(page).evaluate(node => getComputedStyle(node).opacity);

    expect(await opacity(), 'the pilcrow was visible at rest').toBe('0');

    await heading(page).hover();
    await expect.poll(opacity, { message: 'hovering the heading did not reveal the pilcrow' }).toBe('1');
});

test('navigates to the section', async ({ page }) => {
    await open(page);

    await heading(page).hover();
    await anchor(page).click();

    await expect(page).toHaveURL(new RegExp(`#${proseSection}$`));
});
