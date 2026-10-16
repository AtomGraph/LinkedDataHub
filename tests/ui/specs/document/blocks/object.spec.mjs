// The object block: a block whose value is another resource, rendered in place.
//
// It is how a document composes: only `ldh:Object` and `ldh:XHTML` may be values in a document's
// content list, so anything else that is to appear as content - a chart, a view, another document's
// resource - gets there by being named by an object block. The fixture's chart is exactly that,
// and this is the mechanism that makes it visible at all.
//
// The subtlety worth pinning is whose block it is. The embedded rendering is wrapped in
// `.ldh-obj-value` precisely so that block-level tools address the HOST block rather than the
// resource it happens to be showing - one card, one header, one set of controls, however deep the
// thing inside it goes.
import { randomUUID } from 'node:crypto';
import { test, expect } from '../../../lib/console.mjs';
import { goto, settled } from '../../../lib/settle.mjs';
import { fixtures, itemUri, ldh, remoteDocumentTitle } from '../../../lib/fixtures.mjs';
import { endUserBase } from '../../../lib/stack.mjs';
import { CONTENT_MODE, inMode } from '../../../lib/mode.mjs';

const objectValue = page => page.locator('.ldh-obj-value').first();

test('renders the resource its value names', async ({ page }) => {
    await goto(page, fixtures.container);
    await settled(page);

    await expect(objectValue(page)).toBeVisible();
    // Not empty: an object block that resolved nothing would leave the wrapper standing with
    // nothing in it, which is indistinguishable from a block with no value at all.
    await expect(objectValue(page)).not.toBeEmpty();
});

test('stays one block, however much is rendered inside it', async ({ page }) => {
    await goto(page, fixtures.container);
    await settled(page);

    // The host card owns the chrome. The embedded resource brings its own rendering, not its own
    // card - so the block holding an object value has exactly one header, like any other block.
    const host = page.locator('.block.ldh-block:has(.ldh-obj-value)').first();
    await expect(host).toBeVisible();
    await expect(host.locator('.ldh-block-head')).toHaveCount(1);
});

// A resource embedded from ANOTHER dataspace is fetched through the Linked Data proxy, and the
// edit affordance on its header is decided by the acl:mode the proxied response carries - the
// embedded document's own modes, read off the Link header (ldh:block-object-value-response). That
// is the right source: the reader's access to the embedded document is the remote dataspace's to
// decide, not the host page's. What it must never carry is somebody else's access. The proxy used
// to make its upstream request with the platform's own certificate whether or not the reader held
// one, so an anonymous reader was answered as the secretary - a writer of every dataspace - and
// drew a pencil on a block it could not, and must not, edit.
//
// Presence, not visibility, as in axes/anonymous-affordances: what authorization decides is whether
// the button is emitted at all.
test.describe('a resource embedded from another dataspace', () => {
    const embedded = page => page.locator(`.block.ldh-block[about="${fixtures.remoteBlock}"] .ldh-obj-value`);
    const pencil = page => embedded(page).locator('.ldh-block-head button.btn-edit');

    test('offers the owner, who may edit it there, the edit control', async ({ page }, testInfo) => {
        test.skip(testInfo.project.name !== 'owner', 'the claim is about holding the certificate');
        await goto(page, fixtures.remoteHost);

        await expect(embedded(page)).toContainText(remoteDocumentTitle);
        await expect(pencil(page)).toHaveCount(1);
    });

    test('offers an anonymous reader, who may only read it there, none', async ({ page }, testInfo) => {
        test.skip(testInfo.project.name !== 'anonymous', 'the claim is about holding no certificate');
        await goto(page, fixtures.remoteHost);

        // The embedded document did render for this reader - it is granted to everyone in its own
        // dataspace - so an absent button below is authorization's doing, not a block that failed.
        await expect(embedded(page)).toContainText(remoteDocumentTitle);
        await expect(pencil(page)).toHaveCount(0);
    });
});

// An object block whose layout mode is a canvas mode draws its object on that canvas: a chart, a map
// or a 3D graph of the resource it names, started by the same template every canvas is
// (ldh:InitCanvas). Asserted is the library's own surface inside the canvas.
test.describe('an object block in a canvas mode', { tag: '@owner' }, () => {
    const AC = 'https://w3id.org/atomgraph/client#';
    const scratch = {};

    test.beforeEach(async () => {
        scratch.container = (await ldh(['create', 'container', '--parent', endUserBase, '--title', 'Object canvas modes',
            '--slug', `object-canvas-${randomUUID().slice(0, 8)}`])).stdout;
    });

    test.afterEach(async () => {
        if (scratch.container) await ldh(['delete', scratch.container], { allowFailure: true });
    });

    for (const [mode, canvas, surface] of [['ChartMode', 'chart-canvas', 'svg, table'], ['MapMode', 'map-canvas', '.ol-viewport'], ['GraphMode', 'graph-3d-canvas', 'canvas']]) {
        test(`draws its object in ${mode}`, async ({ page }) => {
            const fragment = `${mode.toLowerCase()}-block`;
            await ldh(['add', 'object-block', '--title', `${mode} block`, '--uri', `#${fragment}`,
                '--value', itemUri(1), '--mode', AC + mode, scratch.container]);
            await goto(page, inMode(scratch.container, CONTENT_MODE));

            await expect(page.locator(`div.block[about="${scratch.container}#${fragment}"] .${canvas}`).locator(surface).first())
                .toBeVisible({ timeout: 30_000 });
        });
    }
});
