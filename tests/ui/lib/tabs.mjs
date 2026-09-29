// The dataspace tab strip, and opening a second dataspace into a pane of its own.
//
// A tab is not a page: the strip keeps one `div.ldh-pane` per open dataspace in the same document,
// the active one shown and the rest hidden, so a spec that means "the first tab's chart" means an
// element in a pane that is still in the DOM. Which is why this vocabulary is shared rather than
// written out twice - the strip's own spec reaches for the strip and the apps menu, and the pane
// isolation axis reaches for the same menu to get a second pane at all.
import { expect } from '@playwright/test';
import { settled } from './settle.mjs';

export const strip = page => page.locator('ul.ldh-tabs');
export const apps = page => page.locator('div.ac-menu-anchor:has(button.btn-apps)').first();
export const panes = page => page.locator('div.ldh-pane');

// The other dataspace this instance serves, as the apps menu offers it: any origin but this one.
export const otherDataspace = async page => {
    await apps(page).locator('button.btn-apps').click();
    const entries = apps(page).locator('.ac-menu a[href]');
    const hrefs = await entries.evaluateAll(as => as.map(a => a.getAttribute('href')));
    const other = hrefs.find(href => !href.startsWith(new URL(page.url()).origin));
    expect(other, `the apps menu offered no dataspace but this one: ${hrefs.join(', ')}`).toBeTruthy();
    return entries.filter({ has: page.locator(`[href="${other}"]`) }).first().or(entries.filter({ hasText: /./ }).nth(hrefs.indexOf(other)));
};

// Opening it from the menu adds a tab and renders the dataspace into a new pane while the first
// pane stays in the DOM, hidden.
export const openSecondTab = async page => {
    await (await otherDataspace(page)).click();
    await expect(page.locator('ul.ldh-tabs li, ul.ldh-tabs a.ldh-tab')).toHaveCount(2, { timeout: 30_000 });
    await settled(page, { selector: '.ldh-pane.is-active .ldh-block' });
};
