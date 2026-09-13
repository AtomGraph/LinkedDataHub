// The RDFa annotation dialog, after the design-system regrouping.
//
// The dialog asserts one statement. Its invariant half - the subject it is about, the
// predicate it asserts - is pinned above a two-tab strip, and the tabs carry what
// elaborates it: the object (literal or resource) and the subject-side overrides.
//
// Two of the assertions are the reason the spec exists, because they would have passed
// against the old markup and still meant nothing:
//
//   - The Text|Link switch is not decoration. rdfae:apply-annotation already suppressed
//     @content/@datatype/@lang whenever @resource was set, but the reverse was unguarded:
//     an IRI left in the resource input after toggling back to Text still emitted
//     @resource and voided the literal. That is what the rdfae:form-values override fixes,
//     and only a round-trip through Annotate can show it.
//   - The subject tab's count. The imported populate-form opened a <details> to disclose
//     the overrides; with tabs there is no disclosure, so a @typeof the user cannot see is
//     a regression that rendering alone will not reveal.
//
// Each test gets its own document. The XHTML block autosaves when focus leaves the editor
// region, so tests sharing one would inherit each other's annotations - and a word that is
// already annotated opens the dialog in edit mode instead of create mode, which is a
// different code path from the one the test means to drive.
import { test, expect } from '../lib/console.mjs';
import { goto } from '../lib/settle.mjs';
import { fixtures, ldh } from '../lib/fixtures.mjs';

const XHTML_BLOCK = 'div[typeof="https://w3id.org/atomgraph/linkeddatahub#XHTML"]';
const OVERLAY = '#rdfa-editor-overlay';
const TITLE = 'http://purl.org/dc/terms/title';
// the sentinel the datatype select uses for its free-text option (rdfa-editor/overlay.xsl $rdfae:custom)
const CUSTOM = 'https://w3id.org/atomgraph/rdfa-editor#custom';
const PROSE = 'Alpha Bravo Charlie Delta.';

let doc;

test.beforeEach(async ({ page }, testInfo) => {
    const slug = `annotation-${testInfo.testId}`;
    const created = await ldh(['create', 'item',
        '--container', fixtures.container, '--title', 'Annotation fixture', '--slug', slug]);
    doc = created.stdout;
    await ldh(['add', 'xhtml-block', '--title', 'Annotation prose',
        '--value', `<div xmlns="http://www.w3.org/1999/xhtml"><p>${PROSE}</p></div>`, doc]);
    await goto(page, doc);
    await hydrated(page);
});

// The server shell renders the prose before Saxon-JS has run its initial template, so a click can land
// while no ixsl handler is bound yet - which is indistinguishable from a handler that declined to match.
//
// window.rdfaEditor, not window.LinkedDataHub: the latter is truthy from the FIRST line of the bootstrap,
// several instructions before the sub-objects it goes on to create, so waiting on it lands mid-way through.
// rdfae:init-state runs last in that template, which makes its container the signal that all of it ran.
async function hydrated(page) {
    await page.waitForFunction(() => !!window.rdfaEditor, null, { timeout: 30_000 });
}

test.afterEach(async () => {
    if (doc) await ldh(['delete', doc], { allowFailure: true });
});

// The XHTML block renders read-only until its Edit button is pressed. (Clicking the prose
// itself does the same thing, but only by proxying to that button, so the button is the
// affordance under the shortcut rather than a detour around it.)
// The generous timeout is for the first test of a run: entering edit mode re-renders the
// block through the client stylesheet, and on a cold page that pays for the Saxon-JS
// warm-up the whole suite's timeouts are already sized around. Subsequent calls take ~1s.
async function edit(page) {
    const block = page.locator('div.ldh-block').filter({ has: page.locator(XHTML_BLOCK) }).first();
    await block.locator('button.btn-edit').first().click();
    await expect(page.locator('.rdfa-editor-content')).toBeVisible({ timeout: 30_000 });
}

// Open the dialog over a selection. The handler reads the live selection and the event's
// clientX/clientY, so the selection has to exist before contextmenu fires - a Playwright
// right-click would place a caret first and collapse it.
async function selectAndOpen(page, word) {
    await page.evaluate(word => {
        const region = document.querySelector('.rdfa-editor-content');
        const walker = document.createTreeWalker(region, NodeFilter.SHOW_TEXT);
        let node;
        while ((node = walker.nextNode())) {
            const at = node.data.indexOf(word);
            if (at === -1) continue;
            const range = document.createRange();
            range.setStart(node, at);
            range.setEnd(node, at + word.length);
            const selection = getSelection();
            selection.removeAllRanges();
            selection.addRange(range);
            const { left, top } = range.getBoundingClientRect();
            node.parentElement.dispatchEvent(new MouseEvent('contextmenu', {
                bubbles: true, cancelable: true, clientX: left, clientY: top,
            }));
            return;
        }
        throw new Error(`No text node containing ${JSON.stringify(word)}`);
    }, word);
    await expect(page.locator(OVERLAY)).toBeVisible();
}

async function reopen(page, word) {
    await page.evaluate(word => {
        const span = [...document.querySelectorAll('.rdfa-editor-content [property]')]
            .find(e => e.textContent.includes(word));
        if (!span) throw new Error(`No annotation on ${JSON.stringify(word)}`);
        const { left, top } = span.getBoundingClientRect();
        span.dispatchEvent(new MouseEvent('contextmenu', {
            bubbles: true, cancelable: true, clientX: left, clientY: top,
        }));
    }, word);
    await expect(page.locator(OVERLAY)).toBeVisible();
}

const annotation = (page, word) =>
    page.locator('.rdfa-editor-content [property]').filter({ hasText: word }).first();

const annotate = page => page.locator(`${OVERLAY} button.spo-action`).click();

test.describe('RDFa annotation dialog', () => {
    test('opens on the object tab with the selection carried into the value', async ({ page }) => {
        await edit(page);
        await selectAndOpen(page, 'Alpha');

        // the statement's invariant half sits outside the tabs entirely
        await expect(page.locator(`${OVERLAY} .annotation-statement #stmt-subject`)).toBeVisible();
        await expect(page.locator(`${OVERLAY} .annotation-statement #annotation-property`)).toBeVisible();

        await expect(page.locator('#annotation-tab-object')).toHaveClass(/is-on/);
        await expect(page.locator('#annotation-panel-object')).toBeVisible();
        await expect(page.locator('#annotation-panel-subject')).toBeHidden();

        // Text leads, so the literal fields are the ones on screen
        await expect(page.locator('.ac-switch-seg[data-object-kind="literal"]')).toHaveAttribute('aria-checked', 'true');
        await expect(page.locator('#annotation-object-literal')).toBeVisible();
        await expect(page.locator('#annotation-object-resource')).toBeHidden();
        await expect(page.locator('#annotation-value')).toHaveValue('Alpha');

        // the grid the dialog used to ride reserved a 200px label track it could not afford
        await expect(page.locator(`${OVERLAY} .ldh-prop-group`)).toHaveCount(0);
    });

    test('the tabs switch panels', async ({ page }) => {
        await edit(page);
        await selectAndOpen(page, 'Alpha');

        await page.locator('#annotation-tab-subject').click();
        await expect(page.locator('#annotation-panel-subject')).toBeVisible();
        await expect(page.locator('#annotation-panel-object')).toBeHidden();
        await expect(page.locator('#annotation-subject')).toBeVisible();
        await expect(page.locator('#annotation-typeof')).toBeVisible();

        await page.locator('#annotation-tab-object').click();
        await expect(page.locator('#annotation-panel-object')).toBeVisible();
        await expect(page.locator('#annotation-panel-subject')).toBeHidden();
    });

    test('Text writes a literal object', async ({ page }) => {
        await edit(page);
        await selectAndOpen(page, 'Bravo');

        await page.locator('#annotation-property').fill(TITLE);
        await annotate(page);
        await expect(page.locator(OVERLAY)).toBeHidden();

        const span = annotation(page, 'Bravo');
        await expect(span).toHaveAttribute('property', TITLE);
        await expect(span).not.toHaveAttribute('resource', /.*/);
    });

    test('Link writes a resource object and suppresses the literal', async ({ page }) => {
        const target = `${fixtures.container}item-01/`;
        await edit(page);
        await selectAndOpen(page, 'Charlie');

        await page.locator('#annotation-property').fill(TITLE);
        // fill the literal side FIRST, then switch: the stale value is exactly what must not survive
        await page.locator('#annotation-value').fill('a literal that must not be emitted');
        await page.locator('#annotation-lang').fill('en');

        await page.locator('.ac-switch-seg[data-object-kind="resource"]').click();
        await expect(page.locator('.ac-switch-seg[data-object-kind="resource"]')).toHaveAttribute('aria-checked', 'true');
        await expect(page.locator('#annotation-object-resource')).toBeVisible();
        await expect(page.locator('#annotation-object-literal')).toBeHidden();
        await page.locator('#annotation-object').fill(target);

        await annotate(page);
        await expect(page.locator(OVERLAY)).toBeHidden();

        const span = annotation(page, 'Charlie');
        await expect(span).toHaveAttribute('resource', target);
        await expect(span).not.toHaveAttribute('content', /.*/);
        await expect(span).not.toHaveAttribute('lang', /.*/);
        await expect(span).not.toHaveAttribute('datatype', /.*/);
    });

    test('a subject-side override announces itself on the tab', async ({ page }) => {
        const type = 'http://xmlns.com/foaf/0.1/Document';
        await edit(page);
        await selectAndOpen(page, 'Delta');

        await page.locator('#annotation-property').fill(TITLE);
        await page.locator('#annotation-tab-subject').click();
        await page.locator('#annotation-typeof').fill(type);
        await annotate(page);
        await expect(page.locator(OVERLAY)).toBeHidden();

        const span = annotation(page, 'Delta');
        await expect(span).toHaveAttribute('typeof', type);

        // reopening lands on the object tab, and the override is still visible AS a count
        await reopen(page, 'Delta');
        await expect(page.locator('#annotation-tab-object')).toHaveClass(/is-on/);
        await expect(page.locator('#annotation-tab-subject .ac-tab-count')).toHaveText('1');
        await expect(page.locator(`${OVERLAY} button.remove-action`)).toBeVisible();
    });

    // rdfae:populate-form writes DOM properties; the design system carries the same states as wrapper
    // classes, and only the onchange handlers bridge the two. Setting .value from script fires no change
    // event, so before rdfae:reveal-fields synced them a prefilled field read as live while being inert.
    // Both assertions pair the property with the class deliberately: the property alone passed all along.
    test('a prefilled datatype disables the language field visibly', async ({ page }) => {
        const DATE = 'http://www.w3.org/2001/XMLSchema#date';
        await edit(page);
        await selectAndOpen(page, 'Bravo');

        await page.locator('#annotation-property').fill(TITLE);
        await page.locator('#annotation-datatype').selectOption(DATE);
        await annotate(page);
        await expect(page.locator(OVERLAY)).toBeHidden();
        await expect(annotation(page, 'Bravo')).toHaveAttribute('datatype', DATE);

        await reopen(page, 'Bravo');
        await expect(page.locator('#annotation-datatype')).toHaveValue(DATE);
        await expect(page.locator('#annotation-lang')).toBeDisabled();
        await expect(page.locator('#annotation-lang').locator('xpath=ancestor::div[contains(concat(" ", normalize-space(@class), " "), " ac-field-box ")][1]'))
            .toHaveClass(/is-disabled/);
    });

    test('a datatype outside the option list reveals the custom input holding it', async ({ page }) => {
        const ODD = 'http://example.org/vocab#Temperature';
        await edit(page);
        await selectAndOpen(page, 'Charlie');

        await page.locator('#annotation-property').fill(TITLE);
        await page.locator('#annotation-datatype').selectOption(CUSTOM);
        await page.locator('input[name="custom-datatype"]').fill(ODD);
        await annotate(page);
        await expect(page.locator(OVERLAY)).toBeHidden();
        await expect(annotation(page, 'Charlie')).toHaveAttribute('datatype', ODD);

        // the select has no option for it, so prefill routes it to the free-text input - which stayed
        // hidden until reveal-fields cleared is-hidden on its shell
        await reopen(page, 'Charlie');
        const custom = page.locator('input[name="custom-datatype"]');
        await expect(custom).toHaveValue(ODD);
        await expect(custom).toBeVisible();
        await expect(custom.locator('xpath=ancestor::div[contains(concat(" ", normalize-space(@class), " "), " ac-field ")][1]'))
            .not.toHaveClass(/is-hidden/);
    });

    // The overlay is reached by id(), so a host that re-rendered the page DOM and dropped it made
    // rdfae:populate-form a silent no-op over an empty sequence - and rdfae:show-overlay, which rebuilds it,
    // runs after. The dialog then opened blank. Removing it here reproduces exactly that state.
    test('rebuilds itself, populated, after the overlay was disposed', async ({ page }) => {
        await edit(page);
        await page.evaluate(() => document.getElementById('rdfa-editor-overlay')?.remove());
        await expect(page.locator(OVERLAY)).toHaveCount(0);

        await selectAndOpen(page, 'Delta');
        await expect(page.locator('#annotation-value')).toHaveValue('Delta');
        await expect(page.locator('#annotation-tab-object')).toHaveClass(/is-on/);
    });

    // A radiogroup is one tab stop whose arrows move AND select - that is the role's contract, not a
    // nicety, and declaring role=radio without it promises a screen reader something nothing answers.
    // Asserts the tab stop travels too: with both segments at tabindex 0 the group would be two stops,
    // and with both at -1 it would drop out of the tab order entirely.
    test('the object switch answers the arrow keys its role promises', async ({ page }) => {
        await edit(page);
        await selectAndOpen(page, 'Alpha');

        const text = page.locator('.ac-switch-seg[data-object-kind="literal"]');
        const link = page.locator('.ac-switch-seg[data-object-kind="resource"]');
        await expect(text).toHaveAttribute('tabindex', '0');
        await expect(link).toHaveAttribute('tabindex', '-1');

        await text.focus();
        await page.keyboard.press('ArrowRight');
        await expect(link).toHaveAttribute('aria-checked', 'true');
        await expect(link).toHaveAttribute('tabindex', '0');
        await expect(text).toHaveAttribute('tabindex', '-1');
        await expect(link).toBeFocused();
        await expect(page.locator('#annotation-object-resource')).toBeVisible();
        await expect(page.locator('#annotation-object-literal')).toBeHidden();

        // wrapping, so the group never dead-ends
        await page.keyboard.press('ArrowRight');
        await expect(text).toHaveAttribute('aria-checked', 'true');
        await expect(text).toBeFocused();

        await page.keyboard.press('End');
        await expect(link).toHaveAttribute('aria-checked', 'true');
        await page.keyboard.press('Home');
        await expect(text).toHaveAttribute('aria-checked', 'true');
    });

    // acl:mode() reads window.LinkedDataHub['acl-modes'] through ixsl:contains(), which THROWS on a missing
    // intermediate segment rather than returning false - and Saxon-JS swallows a throw raised inside a match
    // pattern, so the rule just does not match, silently. Until the bootstrap created that object, clicking the
    // prose did nothing whenever the click beat the first document response, while the pane's data-acl-modes
    // already said Write. Measured before the fix: LinkedDataHub undefined at click time, editor never opened.
    //
    // This drives the shortcut rather than the Edit button the other tests use, because the shortcut is the
    // only thing that exercises acl:mode() from a pattern.
    test('click-to-edit opens the editor once the modes are known', async ({ page }) => {
        // The object exists from bootstrap, which is the whole of the fix: the guard now EVALUATES
        // (to no modes, until the response Link headers arrive) instead of throwing. It does not make
        // the modes arrive any sooner - acl:mode() still reads a global that only a document response
        // fills, while the pane's data-acl-modes is correct from first paint. Collapsing those two onto
        // one source is a separate change, deliberately not made here.
        expect(await page.evaluate(() => typeof (window.LinkedDataHub || {})['acl-modes'])).toBe('object');

        await page.waitForFunction(() => {
            const m = window.LinkedDataHub['acl-modes'];
            return !!(m && m.write);
        }, null, { timeout: 30_000 });

        await page.locator(`${XHTML_BLOCK} div.main`).first().click();
        await expect(page.locator('.rdfa-editor-content')).toBeVisible({ timeout: 30_000 });
        await expect(page.locator('[contenteditable="true"]')).toHaveCount(1);
    });
});
