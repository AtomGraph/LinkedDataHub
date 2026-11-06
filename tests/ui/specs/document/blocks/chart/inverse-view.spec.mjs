// A chart an ontology attaches to a property, as views are attached (ldh:view, ldh:inverseView): drawn about the resource
// whose page it is on.
//
// The block is derived, not stored: client/block.xsl injects it under the resource it is about and mints it an @about of
// its own, a fragment of the page's document that no graph holds. A view binds $about to the resource it sits in, which
// is what an inverse view's declaration promises ("?value property $about", ldh.ttl). A chart bound only $this, to its
// own @about, so a chart attached this way queried about that fragment and matched nothing: "No results. The query ran
// cleanly and matched nothing." on every page it was injected into. The taxonomy package's chart reads the hierarchy of
// the scheme its page is about; on the scheme's page it lists the scheme's concepts and counts what is narrower than each.
import { test, expect } from '../../../../lib/console.mjs';
import { goto, settled } from '../../../../lib/settle.mjs';
import { conceptPage, labelOf, scheme } from '../../../../lib/taxonomy.mjs';
import { IN_SCHEME, viewBlock } from '../../../../lib/view.mjs';
import { canvas } from '../../../../lib/chart.mjs';

// the injected chart, among the blocks attached to skos:inScheme: the one that draws
const chart = page => viewBlock(page, IN_SCHEME).filter({ has: page.locator('.chart-canvas') });
const row = (page, name) => canvas(chart(page)).getByRole('row').filter({ has: page.getByRole('cell', { name: labelOf(name), exact: true }) });

test.describe('a chart attached to a property', { tag: '@owner' }, () => {
    // The declaration is the package's and the results are the query's, and neither depends on who is reading.
    test.beforeEach(async ({}, testInfo) => {
        test.skip(testInfo.project.name !== 'owner', 'what the chart declares and what its query returns are the same for either agent');
    });

    test('queries about the resource whose page it is on, not about its own block', async ({ page }) => {
        await goto(page, conceptPage(scheme));
        await settled(page);

        await expect(chart(page)).toHaveCount(1);
        // hot drinks has coffee (which names it as broader) and tea (which it names as narrower); coffee has espresso
        // and latte; cold drinks has juice; espresso is a leaf
        await expect(row(page, 'hot-drinks').getByRole('cell', { name: '2', exact: true })).toBeVisible();
        await expect(row(page, 'coffee').getByRole('cell', { name: '2', exact: true })).toBeVisible();
        await expect(row(page, 'cold-drinks').getByRole('cell', { name: '1', exact: true })).toBeVisible();
        await expect(row(page, 'espresso').getByRole('cell', { name: '0', exact: true })).toBeVisible();
        await expect(canvas(chart(page))).not.toContainText('No results');
    });
});
