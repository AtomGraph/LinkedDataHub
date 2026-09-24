// The resource combobox: when its suggestion panel opens, what commits a suggestion, and what
// abandons the edit.
//
// The combobox is one input plus one panel, driven entirely by ixsl handlers in
// client/form.xsl (keyup, focusout, the panel's mousedown) and client/combobox.xsl
// (Load/Loaded/Process/Render/Show/Place/Hide, SelectionUp/SelectionDown). Everything below drives
// those handlers through the two places the control appears:
//
//   - the document edit form, a modal behind the Actions menu, whose foaf:primaryTopic row the
//     platform's own constructor gives the range [ a rdfs:Resource ] - the unscoped case;
//   - a concept's edit form, rendered inline in its block, whose skos:related row is scoped to
//     skos:Concept and whose skos:inScheme row arrives already committed as a chip.
//
// Typing is done with pressSequentially throughout, never fill(): the lookup listens on keyup and
// fill() sets the value without one, so a filled field never opens a panel at all.
import { test, expect } from '../lib/console.mjs';
import { goto, settled } from '../lib/settle.mjs';
import { fixtures, itemTitle, itemUri } from '../lib/fixtures.mjs';
import { concept, document } from '../lib/taxonomy.mjs';

const READ_MODE = 'https://w3id.org/atomgraph/client#ReadMode';
const SKOS = 'http://www.w3.org/2004/02/skos/core#';
const RELATED = `${SKOS}related`;
const IN_SCHEME = `${SKOS}inScheme`;
const PRIMARY_TOPIC = 'http://xmlns.com/foaf/0.1/primaryTopic';
// Every lookup is a DESCRIBE wrapping the labelled-resource SELECT, sent to the app's own endpoint.
const LOOKUP = /\/sparql\?query=DESCRIBE/i;

// The document's own edit form, which lives in a modal behind the Actions menu.
async function documentForm(page, url) {
    await goto(page, url);
    await settled(page);
    await page.locator('div.ldh-of-wrap button.drop-toggle').first().click();
    await page.locator('div.ldh-of-menu button.btn-edit').first().click();

    const modal = page.locator('div.modal').filter({ has: page.locator('form') }).first();
    await expect(modal).toBeVisible({ timeout: 30_000 });
    return modal;
}

// A concept's edit form, which is inline in its block because the concept is described by the
// document being viewed. Inline matters for the Escape tests: Escape inside a modal closes the
// dialog before the combobox's own handler is observable.
async function conceptForm(page, name = 'coffee') {
    await goto(page, `${document(name)}?mode=${encodeURIComponent(READ_MODE)}`);
    await settled(page);

    const block = page.locator(`div.block.ldh-block[about="${concept(name)}"]`);
    await block.locator('button.btn-edit').first().click();
    const form = block.locator('form').first();
    await expect(form).toBeVisible({ timeout: 30_000 });
    await expect(form.locator(`div.ldh-prop-group:has(input[name="pu"][value="${RELATED}"]) input.resource-combobox`))
        .toBeVisible({ timeout: 20_000 });
    return form;
}

const groupFor = (form, predicate) =>
    form.locator(`div.ldh-prop-group:has(input[name="pu"][value="${predicate}"])`);
// The three parts of one control, always scoped to the same group: a form holds several, and an
// unscoped div.ac-cb-panel matches another row's panel just as happily as this row's.
const partsOf = group => ({
    box: group.locator('div.ac-cb-box'),
    input: group.locator('input.resource-combobox'),
    panel: group.locator('div.ac-cb-panel'),
    committed: group.locator('span.ac-cb-committed input[name="ou"]'),
    editChip: group.locator('span.ac-cb-committed button.add-combobox').first(),
});
const titlesIn = panel => panel.locator('li').evaluateAll(items => items.map(li => li.getAttribute('title')));
// The debounce is 400ms and a stale scheduled load is dropped by ldh:ComboboxLoad's own
// value check, so a quiet second is enough for "and it stayed shut".
const settleLookup = page => page.waitForTimeout(1_200);

test.describe('the resource combobox', () => {
    test.beforeEach(({}, testInfo) => {
        test.skip(testInfo.project.name !== 'owner', 'an edit form is only offered to an agent who may write');
    });

    test.describe('opening the panel', () => {
        // The regression this file was started for. foaf:primaryTopic is the unscoped case, which an
        // ixsl:onfocusin handler used to answer by listing the form's own RDF/POST subjects - so
        // clicking into the field, or the focus() the chip's edit button performs, opened a panel
        // offering the document as the object of its own property.
        test('stays closed when the field is merely focused', async ({ page }) => {
            const modal = await documentForm(page, fixtures.container);
            const { input, panel } = partsOf(groupFor(modal, PRIMARY_TOPIC));
            await expect(input, 'foaf:primaryTopic renders as a lookup').toBeVisible({ timeout: 15_000 });

            await input.click();

            // The assertion is on the panel, not on its emptiness: a panel showing no items is still
            // a panel that opened, and the old handler's list was never empty.
            await expect(input, 'the click focused the field').toBeFocused();
            await settleLookup(page);
            await expect(panel, 'focus alone must not open the panel').toBeHidden();
        });

        test('opens on a typed query, ranked by label', async ({ page }) => {
            const form = await conceptForm(page);
            const { input, panel } = partsOf(groupFor(form, RELATED));

            await input.click();
            await input.pressSequentially('drinks', { delay: 110 });

            await expect(panel).toBeVisible({ timeout: 25_000 });
            // Sorted by label, so "Cold drinks" precedes "Hot drinks" - ldh:ComboboxRender sorts on
            // rdfs:label, then the other label properties, then the URI.
            await expect.poll(() => titlesIn(panel), { timeout: 20_000 })
                .toEqual([concept('cold-drinks'), concept('hot-drinks')]);
        });

        test('stays closed when the query matches nothing', async ({ page }) => {
            const form = await conceptForm(page);
            const { input, panel } = partsOf(groupFor(form, RELATED));

            await input.click();
            await input.pressSequentially('zzzqqqnothing', { delay: 80 });

            // No items is ldh:ComboboxProcess's hide branch, not an empty panel.
            await settleLookup(page);
            await expect(panel).toBeHidden();
        });

        test('stays closed when the text is a URI', async ({ page }) => {
            const form = await conceptForm(page);
            const { input, panel } = partsOf(groupFor(form, RELATED));

            // A URI is not a label, so there is nothing to look it up by: the keyup handler skips the
            // lookup once the value starts with http(s)://. Earlier keystrokes ("h", "ht", ...) are
            // ordinary queries, so the panel may open on the way; what is asserted is where it lands.
            await input.click();
            await input.pressSequentially(itemUri(7), { delay: 40 });

            await settleLookup(page);
            await expect(panel).toBeHidden();
        });

        test('narrows the lookup to the class the property accepts', async ({ page }) => {
            const form = await conceptForm(page);
            const group = groupFor(form, RELATED);
            const { box, input, panel } = partsOf(group);

            await expect(box, 'the row carries its scope for the lookup to read')
                .toHaveAttribute('data-for-class', `${SKOS}Concept`);

            await input.click();
            await input.pressSequentially('drinks', { delay: 110 });
            await expect(panel).toBeVisible({ timeout: 25_000 });

            // "Drinks" is the scheme the three concepts belong to, and its label matches the query as
            // well as theirs do. It is a skos:ConceptScheme, so the type FILTER leaves it out: this is
            // the scope doing work, in one lookup, rather than two lookups compared across tests.
            await expect.poll(() => titlesIn(panel), { timeout: 20_000 })
                .not.toContain(concept('drinks'));
            await expect.poll(() => titlesIn(panel)).toEqual([concept('cold-drinks'), concept('hot-drinks')]);
        });
    });

    test.describe('committing a suggestion', () => {
        test('a mouse pick replaces the lookup with a chip', async ({ page }) => {
            const modal = await documentForm(page, fixtures.container);
            const group = groupFor(modal, PRIMARY_TOPIC);
            const { input, panel, committed } = partsOf(group);

            await input.click();
            await input.pressSequentially(itemTitle(7), { delay: 110 });
            await expect(panel).toBeVisible({ timeout: 20_000 });

            await panel.locator(`li[title="${itemUri(7)}"]`).first().click();

            // The pick replaces the whole lookup wrapper with the committed chip, which carries the
            // RDF/POST input the save path reads.
            await expect(committed, 'the picked resource is committed').toHaveValue(itemUri(7), { timeout: 15_000 });
            await expect(group.locator('div.ac-combobox'), 'the lookup is gone with it').toHaveCount(0);
        });

        test('Enter commits the keyboard-active suggestion', async ({ page }) => {
            const form = await conceptForm(page);
            const group = groupFor(form, RELATED);
            const { input, panel, committed } = partsOf(group);

            await input.click();
            await input.pressSequentially('drinks', { delay: 110 });
            await expect(panel).toBeVisible({ timeout: 25_000 });

            // Enter commits whatever the arrows made active, not the first item: with nothing active it
            // does nothing at all, which is why ArrowDown comes first.
            await input.press('ArrowDown');
            await expect(panel.locator('li.is-active')).toHaveCount(1);
            await input.press('Enter');

            await expect(committed).toHaveValue(concept('cold-drinks'), { timeout: 15_000 });
        });

        // A form's implicit submission rides Enter's keydown, so the keyup branch that commits a
        // suggestion cannot prevent it: committing skos:related with the keyboard used to PATCH the
        // half-edited form as well, and the endpoint answered 400. client/form.xsl refuses the default
        // on keydown instead, whenever the panel has an active item.
        test('Enter commits without submitting the form', async ({ page }) => {
            const form = await conceptForm(page);
            const group = groupFor(form, RELATED);
            const { input, panel, committed } = partsOf(group);

            await input.click();
            await input.pressSequentially('drinks', { delay: 110 });
            await expect(panel).toBeVisible({ timeout: 25_000 });
            await input.press('ArrowDown');
            await expect(panel.locator('li.is-active')).toHaveCount(1);

            const writes = [];
            page.on('request', request => {
                if (request.method() !== 'GET') writes.push(`${request.method()} ${request.url()}`);
            });
            await input.press('Enter');

            await expect(committed).toHaveValue(concept('cold-drinks'), { timeout: 15_000 });
            // Nothing left the browser: committing a suggestion is not saving the form. lib/console.mjs
            // would also fail this test on the 400 the submit used to provoke, but that is the symptom -
            // the assertion is on the request never being made.
            expect(writes, 'committing a suggestion is not saving the form').toEqual([]);
        });
    });

    test.describe('keyboard navigation', () => {
        test('the arrows move the active suggestion', async ({ page }) => {
            const form = await conceptForm(page);
            const { input, panel } = partsOf(groupFor(form, RELATED));

            await input.click();
            await input.pressSequentially('drinks', { delay: 110 });
            await expect(panel).toBeVisible({ timeout: 25_000 });
            const items = panel.locator('li');
            await expect(items).toHaveCount(2);

            // Nothing is active until a key says so - the pointer's hover is a separate state, which is
            // why the class is is-active rather than a hover style.
            await expect(items.locator('.is-active')).toHaveCount(0);

            await input.press('ArrowDown');
            await expect(items.nth(0)).toHaveClass(/is-active/);
            await input.press('ArrowDown');
            await expect(items.nth(1)).toHaveClass(/is-active/);
            await expect(items.nth(0)).not.toHaveClass(/is-active/);

            await input.press('ArrowUp');
            await expect(items.nth(0)).toHaveClass(/is-active/);
            await expect(items.nth(1)).not.toHaveClass(/is-active/);
        });
    });

    test.describe('abandoning an edit', () => {
        // Two different starting states, and Escape means different things in each. A combobox that is
        // the value's own initial state has no committed chip behind it, so there is nothing to go back
        // to and the typed text stays; one that replaced a chip has the chip stashed on the element,
        // and Escape puts it back.
        test('Escape closes the panel and leaves an untouched row alone', async ({ page }) => {
            const form = await conceptForm(page);
            const group = groupFor(form, RELATED);
            const { input, panel } = partsOf(group);

            await input.click();
            await input.pressSequentially('drinks', { delay: 110 });
            await expect(panel).toBeVisible({ timeout: 25_000 });

            await input.press('Escape');

            await expect(panel).toBeHidden();
            await expect(group.locator('div.ac-combobox'), 'the lookup stays - there is no chip to go back to')
                .toHaveCount(1);
            await expect(input, 'and so does what was typed').toHaveValue('drinks');
        });

        test('Escape restores the chip an edit replaced', async ({ page }) => {
            const form = await conceptForm(page);
            const group = groupFor(form, IN_SCHEME);
            const { committed, editChip } = partsOf(group);
            await expect(committed, 'skos:inScheme arrives committed').toHaveValue(concept('drinks'));

            await editChip.click();
            const { input, panel } = partsOf(group);
            await expect(input, 'the edit button gives the lookup back').toBeVisible({ timeout: 15_000 });
            await input.pressSequentially('drinks', { delay: 110 });
            await expect(panel).toBeVisible({ timeout: 25_000 });

            await input.press('Escape');

            await expect(committed, 'the chip comes back with the value it had').toHaveValue(concept('drinks'), { timeout: 15_000 });
            await expect(group.locator('div.ac-combobox')).toHaveCount(0);
        });

        test('leaving the field empty restores the chip', async ({ page }) => {
            const form = await conceptForm(page);
            const group = groupFor(form, IN_SCHEME);
            const { committed, editChip } = partsOf(group);
            await expect(committed).toHaveValue(concept('drinks'));

            await editChip.click();
            const { input } = partsOf(group);
            await expect(input).toBeVisible({ timeout: 15_000 });

            // An edit opened and then left without a value is an edit abandoned, so focusout puts the
            // chip back. Focus goes to a literal field in the same form, which is what a user clicking
            // elsewhere in the dialog does.
            await form.locator('input[name="ol"]').first().click();

            await expect(committed, 'the chip comes back').toHaveValue(concept('drinks'), { timeout: 15_000 });
        });
    });

    test.describe('placement', () => {
        // A panel is position: fixed, so it carries no offsets of its own and would land at its static
        // position - inside the combobox's flex column, the container's origin rather than below the
        // field. ldh:ComboboxPlace measures the field and translates the panel onto it. Fixed is
        // deliberate: an absolutely positioned panel is clipped by any ancestor with a scroll box, and
        // no z-index lifts a box out of an ancestor's clip.
        //
        // The gap is asserted exactly, at 4px, and that is load-bearing: the panel's entry animation
        // used to animate TRANSFORM - the very property the correction is expressed in - so the rect
        // read mid-animation was displaced and the panel settled up to 3px off, varying run to run.
        // The keyframe fades only (see .ac-cb-panel in controls.css), which is what makes an exact
        // assertion possible here; a moving entry animation would reintroduce the drift and this is
        // where it would show up.
        const geometry = async (page, box, panel) => ({
            field: await box.boundingBox(),
            drop: await panel.boundingBox(),
            viewport: await page.evaluate(() => window.innerHeight),
        });
        const GAP = 4; // the distance ldh:ComboboxPlace leaves between the field and the panel

        const openAndType = async (page, height) => {
            await page.setViewportSize({ width: 1280, height });
            const form = await conceptForm(page);
            const parts = partsOf(groupFor(form, RELATED));
            await parts.input.click();
            await parts.input.pressSequentially('drinks', { delay: 110 });
            await expect(parts.panel).toBeVisible({ timeout: 25_000 });
            await page.waitForTimeout(400);
            return geometry(page, parts.box, parts.panel);
        };

        test('takes the field\'s width and drops below it', async ({ page }) => {
            const { field, drop, viewport } = await openAndType(page, 1200);

            // The premise, asserted rather than assumed: this test only says anything while the panel
            // fits under the field. A layout change that moves the field down turns it into the flip
            // case, and should say so here rather than as a confusing coordinate mismatch.
            expect(viewport - (field.y + field.height), 'there is room below the field')
                .toBeGreaterThan(drop.height);

            expect(drop.width, 'the panel is as wide as the field').toBeCloseTo(field.width, 0);
            expect(drop.x, 'and aligned with it').toBeCloseTo(field.x, 0);
            expect(drop.y, 'and sits one gap under it')
                .toBeCloseTo(field.y + field.height + GAP, 0);
        });

        test('flips above the field when it would run past the bottom', async ({ page }) => {
            // The project's own viewport, in which this form puts the field low enough that a two-item
            // panel does not fit under it. A panel taller than the space on either side would stay
            // below, where its own scrollbar is reachable rather than hanging off the top of the window.
            const { field, drop, viewport } = await openAndType(page, 720);

            expect(viewport - (field.y + field.height), 'there is no room below the field')
                .toBeLessThan(drop.height);

            expect(drop.width).toBeCloseTo(field.width, 0);
            expect(drop.x).toBeCloseTo(field.x, 0);
            expect(drop.y + drop.height, 'so it sits one gap above the field')
                .toBeCloseTo(field.y - GAP, 0);
        });
    });

    test.describe('a lookup that fails', () => {
        test('says so where its suggestions would have been', async ({ page, allowNoise }) => {
            allowNoise.push({ pattern: LOOKUP, reason: 'this spec refuses the lookup on purpose' });
            allowNoise.push({
                pattern: /console\.error: Failed to load resource.*500/i,
                reason: 'the browser logs the injected 500 the route fulfils',
            });

            const form = await conceptForm(page);
            // Routed after the form is open, so only the lookup is refused and not the render that
            // produced the field.
            await page.route(LOOKUP, route => route.fulfill({ status: 500, contentType: 'text/turtle', body: '' }));

            const { input, panel } = partsOf(groupFor(form, RELATED));
            await input.click();
            await input.pressSequentially('drinks', { delay: 110 });

            // A lookup that failed reports in the panel rather than looking like it found nothing,
            // which is the one case where an open panel holds no suggestions.
            await expect(panel, 'the panel opens to carry the failure').toBeVisible({ timeout: 25_000 });
            await expect(panel.locator('div.ldh-failure')).toHaveCount(1);
            await expect(panel).toContainText('500');
            await expect(panel.locator('li'), 'and offers nothing to pick').toHaveCount(0);
        });
    });

    test.describe('the type combobox', () => {
        test('picking a class rebuilds the form from that class\'s constructor', async ({ page }) => {
            const form = await conceptForm(page);
            const typeChip = form.locator('button.add-type-combobox');
            await expect(typeChip.locator('input[name="ou"]')).toHaveValue(`${SKOS}Concept`);
            const predicates = () => form.locator('div.ldh-prop-group input[name="pu"]')
                .evaluateAll(inputs => inputs.map(input => input.value));
            expect(await predicates(), 'the Concept constructor\'s properties').toContain(RELATED);

            // The type row is a committed chip like any other; its edit button opens a lookup over
            // classes rather than over instances.
            await typeChip.click();
            const typeInput = form.locator('input.type-combobox');
            await expect(typeInput).toBeVisible({ timeout: 15_000 });
            await typeInput.click();
            await typeInput.pressSequentially('Collection', { delay: 110 });

            const typePanel = page.locator('div.ac-cb-panel.type-combobox');
            await expect(typePanel).toBeVisible({ timeout: 25_000 });
            await typePanel.locator(`li[title="${SKOS}Collection"]`).first().click();

            // Picking a class is not just a value: it fetches that class's SHACL shape and SPIN
            // constructor, merges them, instantiates the result and re-renders the fieldset from it.
            // So the rows become skos:Collection's and the Concept-only ones go.
            await expect(typeChip.locator('input[name="ou"]')).toHaveValue(`${SKOS}Collection`, { timeout: 40_000 });
            await expect.poll(predicates, { timeout: 40_000 }).toContain(`${SKOS}member`);
            expect(await predicates(), 'skos:related is not a Collection property').not.toContain(RELATED);
            expect(await predicates()).not.toContain(IN_SCHEME);
        });
    });
});
