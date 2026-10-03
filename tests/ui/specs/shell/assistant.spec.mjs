// The assistant: a request in words becomes a plan, and the plan runs only when the reader says so.
//
// The assistant is a block producer and lives where its blocks go: its conversation is an ephemeral
// block at the end of the content body, and its composer docks onto the create bar, opened by the
// bar's own button. The server renders only that button; the block and the composer are the
// client's, kept across renders, so a card is still there - fold-outs and all - after the write it
// reported made the page catch up. The rest is a conversation with the plan service beside the
// instance: a question gets a card that shows the plan - its operations as rows, the XML it will
// execute - behind an Execute button, and pressing that reports the steps as they happen and the
// documents the plan wrote.
//
// The second, third and fourth specs need the web-algebra service and a model key behind it: the
// plan is written by a model, so what they assert is the shape of the exchange, not the model's
// exact wording. The request is deliberately one the ldh-* family answers with a single operation.
import { randomUUID } from 'node:crypto';
import { test, expect } from '../../lib/console.mjs';
import { goto } from '../../lib/settle.mjs';
import { itemUri, ldh } from '../../lib/fixtures.mjs';
import { endUserBase } from '../../lib/stack.mjs';

// A container of this spec's own under the root, since the plan creates a document: a fixture
// item cannot parent a container, and the fixture container's child count is asserted by the
// document tree. Nothing counts the root's children, and the spec removes what it made.
const scratch = { container: null, written: [] };

test.beforeEach(async () => {
    const slug = `assistant-${randomUUID().slice(0, 8)}`;
    scratch.container = (await ldh(['create', 'container', '--parent', endUserBase, '--title', 'Assistant spec', '--slug', slug])).stdout;
    scratch.written = [];
});

test.afterEach(async () => {
    for (const uri of scratch.written) await ldh(['delete', uri], { allowFailure: true });
    if (scratch.container) await ldh(['delete', scratch.container], { allowFailure: true });
});

const dock = page => page.locator('.content-body > .ldh-create-dock');
const button = page => dock(page).locator('.ldh-chat-open');
const form = page => page.locator('form.ldh-chat-composer');
const composer = page => form(page).locator('textarea');
const block = page => page.locator('.content-body > .ldh-chat-block');
const card = page => block(page).locator('.ldh-chat-plan').last();

async function open(page) {
    await button(page).click();
    await expect(form(page)).toBeVisible();
}

test('opens from the create bar, docked above it, and closes on Escape', { tag: '@owner' }, async ({ page }) => {
    await goto(page, itemUri(1));

    // the composer is mounted on the bar but closed, and the block is there but empty, so neither shows
    await expect(form(page)).toHaveCount(1);
    await expect(form(page)).not.toBeVisible();
    await expect(block(page)).toHaveCount(1);
    await expect(block(page)).not.toBeVisible();

    await open(page);
    await expect(composer(page)).toBeFocused();

    // docked onto the bar: inside it, on a line of its own above the bar's buttons
    const box = async locator => await locator.boundingBox();
    const composerBox = await box(form(page));
    const buttonBox = await box(button(page));
    expect(composerBox.y + composerBox.height).toBeLessThanOrEqual(buttonBox.y + 1);
    expect(await dock(page).locator('form.ldh-chat-composer').count()).toBe(1);

    // and as wide as the content column, starting where it starts: the composer's box is the column's box inside its padding
    const column = await page.evaluate(() => {
        const body = document.querySelector('.ldh-pane.is-active > .document-body > .content-body');
        const rect = body.getBoundingClientRect(); const style = getComputedStyle(body);
        return { x: rect.x + parseFloat(style.paddingLeft), width: rect.width - parseFloat(style.paddingLeft) - parseFloat(style.paddingRight) };
    });
    expect(Math.abs(composerBox.x - column.x)).toBeLessThanOrEqual(1);
    expect(Math.abs(composerBox.width - column.width)).toBeLessThanOrEqual(1);

    await page.keyboard.press('Escape');
    await expect(form(page)).not.toBeVisible();

    // the button toggles it, and Escape from inside closes it too
    await open(page);
    await composer(page).press('Escape');
    await expect(form(page)).not.toBeVisible();
    await open(page);
    await button(page).click();
    await expect(form(page)).not.toBeVisible();
});

test('a question becomes a plan that waits for Execute', { tag: '@owner' }, async ({ page }) => {
    test.setTimeout(120_000);
    await goto(page, scratch.container);
    await open(page);

    await composer(page).fill('Create a child container titled Assistant test under this document');
    await composer(page).press('Enter');

    // the question is echoed as the reader's turn in the block, which shows now that it has one, and the composer waits
    await expect(block(page)).toBeVisible();
    await expect(block(page).locator('.ldh-chat-turn').last()).toHaveText('Create a child container titled Assistant test under this document');
    await expect(composer(page)).toBeDisabled();

    // the block is the last thing in the body before the bar: what the plan writes will land above it
    await expect(page.locator('.content-body > .ldh-chat-block + .ldh-create-dock')).toHaveCount(1);

    // the plan: its operations as rows that have not run, the executable XML, and the two things that can happen to it.
    // Execute by default is on, and this plan writes - a write waits for Execute whatever the checkbox says
    await expect(form(page).locator('.ldh-chat-run input')).toBeChecked();
    await expect(card(page).locator('.ldh-chat-execute')).toBeVisible({ timeout: 90_000 });
    await expect(card(page).locator('.ldh-chat-cancel')).toBeVisible();
    // the rows live under the trace, which stands open while there is nothing else to read
    await expect(card(page).locator('details.ldh-chat-trace')).toHaveAttribute('open', '');
    const first = card(page).locator('.ldh-chat-steps .ldh-chat-step.is-planned').first();
    await expect(first).toBeVisible();
    // the row is the control: it folds out its operation's XML, the first row's being the whole plan
    await expect(first.locator('pre')).toBeHidden();
    await first.locator('summary').click();
    await expect(first.locator('pre')).toBeVisible();
    await expect(first.locator('pre')).toContainText('https://w3id.org/atomgraph/web-algebra');
    await expect(composer(page)).toBeEnabled();

    // the card keeps its own plan, so Execute on it runs this plan and no other
    const id = await card(page).getAttribute('id');
    expect(await page.evaluate(id => !!window.LinkedDataHub.chat[id], id)).toBe(true);

    // nothing ran: no row has an outcome
    await expect(card(page).locator('.ldh-chat-step.is-done, .ldh-chat-step.is-failed, .ldh-chat-step.is-running')).toHaveCount(0);

    // Cancel takes the card and its plan away and asks nothing of the service
    await card(page).locator('.ldh-chat-cancel').click();
    await expect(block(page).locator('.ldh-chat-plan')).toHaveCount(0);
    expect(await page.evaluate(id => id in window.LinkedDataHub.chat, id)).toBe(false);
});

test('Clear empties the conversation and forgets its plans', { tag: '@owner' }, async ({ page }) => {
    test.setTimeout(120_000);
    await goto(page, scratch.container);
    await open(page);

    await composer(page).fill('Create a child container titled Assistant clear under this document');
    await composer(page).press('Enter');
    await expect(card(page).locator('.ldh-chat-execute')).toBeVisible({ timeout: 90_000 });
    const id = await card(page).getAttribute('id');
    expect(await page.evaluate(id => id in window.LinkedDataHub.chat, id)).toBe(true);

    // the block head's Clear takes the turn and the card away, and the plan the card held; the block hides again
    // with nothing in it, and the composer is ready
    await block(page).locator('.ldh-block-head .ldh-chat-clear').click();
    await expect(block(page).locator('.ldh-chat-plan')).toHaveCount(0);
    await expect(block(page).locator('.ldh-chat-turn')).toHaveCount(0);
    await expect(block(page)).not.toBeVisible();
    expect(await page.evaluate(id => id in window.LinkedDataHub.chat, id)).toBe(false);
    expect(await page.evaluate(id => id in window.LinkedDataHub.chatResults, id)).toBe(false);
    await expect(composer(page)).toBeEnabled();
});

test('Execute runs the plan, reports its steps and the document it wrote, and the card survives the catch-up', { tag: '@owner' }, async ({ page }) => {
    test.setTimeout(180_000);
    await goto(page, scratch.container);
    await open(page);

    await composer(page).fill('Create a child container titled Assistant run under this document');
    await composer(page).press('Enter');
    await expect(card(page).locator('.ldh-chat-execute')).toBeVisible({ timeout: 90_000 });
    const id = await card(page).getAttribute('id');
    await card(page).locator('.ldh-chat-execute').click();

    // the steps appear as the executor reports them, under a progress bar, with the composer waiting
    await expect(card(page).locator('.ldh-chat-plan-actions')).toHaveCount(0);
    await expect(card(page).locator('.ac-pbar')).toBeVisible();
    await expect(composer(page)).toBeDisabled();

    // it ends one way or the other, and the rows say which: the same rows the plan showed, now with an outcome
    const rows = card(page).locator('.ldh-chat-step');
    await expect(rows.first()).toHaveClass(/is-done|is-failed/, { timeout: 120_000 });
    await expect(card(page).locator('.ac-pbar')).toHaveCount(0);
    await expect(composer(page)).toBeEnabled();

    // a single creation under this container: every row went green, the written document is listed
    // under the container it was created in, and the card offers nothing more to run
    await expect(card(page).locator('.ldh-chat-step.is-failed')).toHaveCount(0);
    await expect(rows.first()).toHaveClass(/is-done/);
    const written = card(page).locator('.ldh-chat-docs a.iri');
    await expect(written).toHaveCount(1);
    const href = await written.getAttribute('href');
    scratch.written.push(href);
    expect(href.startsWith(scratch.container)).toBe(true);
    await expect(card(page).locator('.ldh-chat-execute')).toHaveCount(0);

    // the page reloaded the document it is on, so the new child is there without a refresh by hand - and the
    // conversation came through the render that replaced the body: the same card, by id, last before the bar,
    // its rows still folding out their XML
    await expect(page.locator(`.document-body a[href="${href}"]`).first()).toBeVisible({ timeout: 30_000 });
    await expect(page.locator('.content-body > .ldh-chat-block + .ldh-create-dock')).toHaveCount(1);
    await expect(card(page)).toHaveAttribute('id', id);
    await expect(card(page).locator('.ldh-chat-docs a.iri')).toHaveCount(1);

    // the rows name what they return by its label, looked up once the result is in: the written container by its title
    await expect(card(page).locator('table.ldh-chat-result a').first()).toHaveText('Assistant run', { timeout: 30_000 });

    // what the plan returned stays with the card: a follow-up's "them" is sent with the next question as these rows
    expect(await page.evaluate(id => id in window.LinkedDataHub.chatResults, id)).toBe(true);

    // and what it did is read back as a sentence, first on the card, with the trace folded under its count
    await expect(card(page).locator('.ldh-chat-answer')).not.toBeEmpty({ timeout: 60_000 });
    await expect(card(page).locator('> :first-child')).toHaveClass(/ldh-chat-answer/);
    const trace = card(page).locator('details.ldh-chat-trace');
    await expect(trace).not.toHaveAttribute('open', '');
    await expect(trace.locator('> summary')).toContainText(/\d+ steps/);

    // the trace opens on its line, and its rows still fold out their XML after the render that replaced the body
    await trace.locator('> summary').click();
    await expect(trace).toHaveAttribute('open', '');
    const done = card(page).locator('.ldh-chat-step.is-done').first();
    await done.locator('summary').click();
    await expect(done.locator('pre')).toBeVisible();
});
