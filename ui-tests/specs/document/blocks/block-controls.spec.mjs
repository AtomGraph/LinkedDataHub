// A block's control chrome is not drawn until it is asked for.
//
// A view block used to spend the band between its title and its first row on two control bars
// (the facet/sort/mode toolbar and the Related results row), and a chart block on a grid of
// three labelled selects. All three are now rendered carrying `is-collapsed`, and the card
// header's `button.tb-controls` is the single affordance that clears it - the same token and
// the same gesture as the query block's editor toggle over `div.ldh-sparql`.
//
// Two things about that gesture are load-bearing and are what this spec pins:
//
//   · ONE click reveals everything the block holds. The pivot row is still a native <details>,
//     but it is emitted `open` wherever a toggle exists, so revealing the header does not then
//     leave a second disclosure between the reader and the pivots. Asserting the PILLS are
//     visible - not merely the bar - is what makes that a test rather than a restatement.
//   · The pivot row is a plain bar of pills opening with its own lead glyph, laid out on the
//     toolbar's padding so the two leads line up down the card's left edge. It stopped being a
//     <details> when the header toggle took that job, which moved its click handlers off a
//     `details` match pattern - so the pivot itself is driven here, not just looked at.
//   · What the collapsed toolbar used to state moves to a status line under the title, because
//     a row of results cannot say how many of them there are or what was filtered out. So the
//     count is asserted at rest, while the toolbar that used to carry it is hidden.
//
// The bars are present in the DOM throughout - hidden, not absent - which is the whole point of
// the design: no anatomy changed, so every facet, sort, pivot and mode handler still binds the
// same elements. `toBeHidden()` rather than `toHaveCount(0)` is therefore the assertion.
import { test, expect } from '../../../lib/console.mjs';
import { goto, settled } from '../../../lib/settle.mjs';
import { fixtures } from '../../../lib/fixtures.mjs';
import { controlToggle } from '../../../lib/block.mjs';
import { openDrawer } from '../../../lib/drawer.mjs';

// The view block the fixture container renders, addressed by the chrome it owns rather than by
// a fixture URI: the document holds several view blocks and any of them makes this point.
const viewBlock = page => page.locator('.block.ldh-block:has(.ldh-view-toolbar)').first();
const chartBlock = page => page.locator('.block.ldh-block:has(.chart-controls)').first();

// A chrome assertion, not an authorization one - and anonymously the fixture may not be
// readable at all, which would measure something else entirely.
test.beforeEach(({}, testInfo) => {
    test.skip(testInfo.project.name !== 'owner',
        'a chrome assertion; the authorization axis would measure the same thing twice');
});

test('a view block draws no control bars until its toggle is pressed', async ({ page }) => {
    await goto(page, fixtures.container);
    await settled(page);

    const block = viewBlock(page);
    const toolbar = block.locator('.ldh-view-toolbar');
    const pivotBar = block.locator('.ldh-pivot-bar');
    // A pill, not the container: .ldh-pivot-pills is display: contents, so it has no box of
    // its own for a visibility check to measure.
    const pivotPill = block.locator('.ldh-pivot-pill').first();

    // At rest: present, hidden, and the toggle says so.
    await expect(toolbar).toBeAttached();
    await expect(toolbar).toBeHidden();
    await expect(pivotBar).toBeHidden();
    await expect(controlToggle(block)).toHaveAttribute('aria-pressed', 'false');

    // The count survives the collapse, in the header rather than the toolbar.
    const status = block.locator('.ldh-view-status');
    await expect(status).toBeVisible();
    await expect(status.locator('.count')).toContainText('25');
    await expect(toolbar.locator('.count')).toHaveCount(0);

    // One press, everything. The pills, not just the bar that holds them: a pivot row that
    // arrived closed would satisfy an assertion on the bar and still cost a second gesture.
    await controlToggle(block).click();
    await expect(toolbar).toBeVisible();
    await expect(pivotBar).toBeVisible();
    await expect(pivotPill).toBeVisible();
    await expect(controlToggle(block)).toHaveAttribute('aria-pressed', 'true');

    // And it closes again.
    await controlToggle(block).click();
    await expect(toolbar).toBeHidden();
    await expect(pivotBar).toBeHidden();
    await expect(controlToggle(block)).toHaveAttribute('aria-pressed', 'false');
});

test('a chart block draws no control grid until its toggle is pressed', async ({ page }) => {
    await goto(page, fixtures.container);
    await settled(page);

    const block = chartBlock(page);
    const controls = block.locator('.chart-controls');

    await expect(controls).toBeAttached();
    await expect(controls).toBeHidden();
    await expect(controlToggle(block)).toHaveAttribute('aria-pressed', 'false');

    await controlToggle(block).click();
    await expect(controls).toBeVisible();
    // The selects are what the grid exists for; a revealed grid with no controls in it would
    // mean the results response had re-rendered it from a state this gesture never reached.
    await expect(controls.locator('select.chart-type')).toBeVisible();
    await expect(controlToggle(block)).toHaveAttribute('aria-pressed', 'true');
});

test('an applied facet is named on the status line, with the toolbar closed again', async ({ page }) => {
    await goto(page, fixtures.container);
    await settled(page);

    const block = viewBlock(page);
    const applied = block.locator('.ldh-view-status .ldh-view-applied');

    // Nothing applied, nothing said - an empty line would read as a gap, not as information.
    await expect(applied).toBeEmpty();

    await controlToggle(block).click();
    const facet = block.locator('.ldh-view-toolbar .facet').first();
    await facet.locator('button.facet-pill').click();
    const option = facet.locator('.facet-pop button.opt').first();
    await expect(option).toBeVisible();
    const value = (await option.locator('.nm').innerText()).trim();
    await option.click();

    // The pill lights, and the line under the title says the same thing in words.
    await expect(facet.locator('button.facet-pill')).toHaveClass(/is-active/);
    await expect(applied).toContainText(value);

    // Closing the chrome must not take the statement with it: that is the whole reason the
    // line exists rather than the toolbar simply being hidden.
    await controlToggle(block).click();
    await expect(block.locator('.ldh-view-toolbar')).toBeHidden();
    await expect(applied).toContainText(value);
});

test('a pivot still re-centres the view, now that the row is not a disclosure', async ({ page }) => {
    await goto(page, fixtures.container);
    await settled(page);

    const block = viewBlock(page);
    await controlToggle(block).click();

    // The row opens with a lead glyph and no label text - the pills say what each pivot is.
    await expect(block.locator('.ldh-pivot-bar .pivot-lead')).toBeVisible();
    await expect(block.locator('.ldh-pivot-bar .lbl').first()).toBeVisible();

    const pill = block.locator('.ldh-pivot-pill').first();
    await expect(pill).toBeVisible();
    const predicate = (await pill.locator('.lbl').innerText()).trim();
    await pill.click();

    // Taking a pivot leaves a removable step chip behind, and the status line names it. Both
    // would still be here if the pill's handler had stopped matching - the chip is what proves
    // the click was actually handled.
    const step = block.locator('.ldh-view-toolbar .parallax-steps button.parallax-step');
    await expect(step).toHaveCount(1);
    await expect(step).toContainText(predicate);
    await expect(block.locator('.ldh-view-status .ldh-view-applied')).toContainText(predicate);
});

test('a view with no card header keeps its chrome, having nothing that could reveal it', async ({ page }) => {
    await goto(page, fixtures.container);
    await settled(page);

    // The search results are a view rendered into a modal, and a modal-hosted view has no card
    // header - so no ldh:ControlsToggle, and nothing that could ever clear the token. Collapsing
    // it there would hide the controls permanently, which is why the token is emitted only where
    // the header slot exists. This is the assertion that keeps that conditional honest.
    await openDrawer(page);
    const search = page.locator('.ldh-sidebar input').first();
    await expect(search).toBeVisible();
    await search.fill('Fixture');
    await search.press('Enter');

    const modal = page.locator('div.modal, .ac-modal').first();
    await expect(modal).toBeVisible();
    const toolbar = modal.locator('.ldh-view-toolbar');
    await expect(toolbar).toBeVisible();
    await expect(toolbar).not.toHaveClass(/is-collapsed/);
    await expect(modal.locator('.tb-controls')).toHaveCount(0);
});
