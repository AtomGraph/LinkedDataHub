// The assistant drawer: a request in words becomes a plan, and the plan runs only when the reader
// says so.
//
// The drawer is chrome the server renders for a signed-in reader, closed and inert; its handle
// opens it and Escape closes it, and an open drawer insets the page rather than covering it. The
// rest is a conversation with the plan service beside the instance: a question gets a card that
// shows the plan - its operations as tags, the XML it will execute - behind an Execute button, and
// pressing that reports the steps as they happen and the documents the plan wrote.
//
// The second and third specs need the web-algebra service and a model key behind it: the plan is
// written by a model, so what they assert is the shape of the exchange, not the model's exact
// wording. The request is deliberately one the ldh-* family answers with a single operation.
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

const drawer = page => page.locator('.chat-drawer');
const handle = page => page.locator('.chat-sensor .chat-open');
const composer = page => drawer(page).locator('form.chat-composer textarea');
const card = page => drawer(page).locator('.chat-plan').last();

async function open(page) {
    await handle(page).click();
    await expect(drawer(page)).toBeVisible();
}

test('opens from its edge handle, insets the page, and closes on Escape', { tag: '@owner' }, async ({ page }) => {
    await goto(page, itemUri(1));

    // present but closed: inert keeps its subtree out of the tab order while nothing shows it
    await expect(drawer(page)).toHaveCount(1);
    await expect(drawer(page)).not.toBeVisible();
    await expect(drawer(page)).toHaveAttribute('inert', '');

    const right = selector => page.evaluate(selector => document.querySelector(selector).getBoundingClientRect().right, selector);
    const before = await right('#tab-content');
    await open(page);
    await expect(drawer(page)).not.toHaveAttribute('inert', '');
    await expect(composer(page)).toBeFocused();

    // the dataspace's panes move over, so the action bar's controls stay reachable beside the drawer, while the
    // header above the drawer keeps the full width: the drawer belongs to the panel, not to the frame
    const after = await right('#tab-content');
    expect(after).toBeLessThan(before);
    expect(await right('.ldh-header')).toBe(before);

    // its head stands beside the action bar, seam to seam
    const bottom = selector => page.evaluate(selector => document.querySelector(selector).getBoundingClientRect().bottom, selector);
    expect(await bottom('.chat-drawer > .ac-drawer-head')).toBe(await bottom('.ldh-actionbar'));

    await page.keyboard.press('Escape');
    await expect(drawer(page)).not.toBeVisible();
    await expect(drawer(page)).toHaveAttribute('inert', '');
});

test('a question becomes a plan that waits for Execute', { tag: '@owner' }, async ({ page }) => {
    test.setTimeout(120_000);
    await goto(page, scratch.container);
    await open(page);

    await composer(page).fill('Create a child container titled Assistant test under this document');
    await composer(page).press('Enter');

    // the question is echoed as the reader's turn and the composer waits for the answer
    await expect(drawer(page).locator('.chat-turn').last()).toHaveText('Create a child container titled Assistant test under this document');
    await expect(composer(page)).toBeDisabled();

    // the plan: its operations as rows that have not run, the executable XML, and the two things that can happen to it.
    // Execute by default is on, and this plan writes - a write waits for Execute whatever the checkbox says
    await expect(page.locator('.chat-run input')).toBeChecked();
    await expect(card(page).locator('.chat-execute')).toBeVisible({ timeout: 90_000 });
    await expect(card(page).locator('.chat-cancel')).toBeVisible();
    const first = card(page).locator('.chat-steps .chat-step.is-planned').first();
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
    await expect(card(page).locator('.chat-step.is-done, .chat-step.is-failed, .chat-step.is-running')).toHaveCount(0);

    // Cancel takes the card and its plan away and asks nothing of the service
    await card(page).locator('.chat-cancel').click();
    await expect(drawer(page).locator('.chat-plan')).toHaveCount(0);
    expect(await page.evaluate(id => id in window.LinkedDataHub.chat, id)).toBe(false);
});

test('Clear empties the conversation and forgets its plans', { tag: '@owner' }, async ({ page }) => {
    test.setTimeout(120_000);
    await goto(page, scratch.container);
    await open(page);

    await composer(page).fill('Create a child container titled Assistant clear under this document');
    await composer(page).press('Enter');
    await expect(card(page).locator('.chat-execute')).toBeVisible({ timeout: 90_000 });
    const id = await card(page).getAttribute('id');
    expect(await page.evaluate(id => id in window.LinkedDataHub.chat, id)).toBe(true);

    // the head's Clear takes the turn and the card away, and the plan the card held; the composer is ready
    await drawer(page).locator('.ac-drawer-head .chat-clear').click();
    await expect(drawer(page).locator('.chat-plan')).toHaveCount(0);
    await expect(drawer(page).locator('.chat-turn')).toHaveCount(0);
    expect(await page.evaluate(id => id in window.LinkedDataHub.chat, id)).toBe(false);
    expect(await page.evaluate(id => id in window.LinkedDataHub.chatResults, id)).toBe(false);
    await expect(composer(page)).toBeEnabled();
});

test('Execute runs the plan, reports its steps and the document it wrote, and the page catches up', { tag: '@owner' }, async ({ page }) => {
    test.setTimeout(180_000);
    await goto(page, scratch.container);
    await open(page);

    await composer(page).fill('Create a child container titled Assistant run under this document');
    await composer(page).press('Enter');
    await expect(card(page).locator('.chat-execute')).toBeVisible({ timeout: 90_000 });
    await card(page).locator('.chat-execute').click();

    // the steps appear as the executor reports them, under a progress bar, with the composer waiting
    await expect(card(page).locator('.chat-plan-actions')).toHaveCount(0);
    await expect(card(page).locator('.ac-pbar')).toBeVisible();
    await expect(composer(page)).toBeDisabled();

    // it ends one way or the other, and the rows say which: the same rows the plan showed, now with an outcome
    const rows = card(page).locator('.chat-step');
    await expect(rows.first()).toHaveClass(/is-done|is-failed/, { timeout: 120_000 });
    await expect(card(page).locator('.ac-pbar')).toHaveCount(0);
    await expect(composer(page)).toBeEnabled();

    // a single creation under this container: every row went green, the written document is listed
    // under the container it was created in, and the card offers nothing more to run
    await expect(card(page).locator('.chat-step.is-failed')).toHaveCount(0);
    await expect(rows.first()).toHaveClass(/is-done/);
    const written = card(page).locator('.chat-docs a.iri');
    await expect(written).toHaveCount(1);
    const href = await written.getAttribute('href');
    scratch.written.push(href);
    expect(href.startsWith(scratch.container)).toBe(true);
    await expect(card(page).locator('.chat-execute')).toHaveCount(0);

    // the page reloaded the document it is on, so the new child is there without a refresh by hand
    await expect(page.locator(`.document-body a[href="${href}"]`).first()).toBeVisible({ timeout: 30_000 });

    // the rows name what they return by its label, looked up once the result is in: the written container by its title
    await expect(card(page).locator('table.chat-result a').first()).toHaveText('Assistant run', { timeout: 30_000 });

    // what the plan returned stays with the card: a follow-up's "them" is sent with the next question as these rows
    const id = await card(page).getAttribute('id');
    expect(await page.evaluate(id => id in window.LinkedDataHub.chatResults, id)).toBe(true);
});
