// The authorization axis, asserted instead of assumed.
//
// The two projects exist to run the same specs as someone who may write and someone who may not
// (README, Projects). Until this spec there was nothing for the anonymous half to assert: nothing
// in a fresh dataspace is readable without a certificate, so every spec skipped it and the three
// that did run were non-asserting probes of a 403 error page. The axis was decorative, and a
// layout spec that forgot to skip is what surfaced that - it failed in CI against a virgin
// instance and passed locally against one an earlier http-tests run had made public.
//
// A grant is what makes the axis testable. fixtures.readable is the one item seeded with public
// read; fixtures.private is granted to nobody. The claim worth asserting is not that an anonymous
// agent is refused - that is the default, and denial alone demonstrates nothing about rendering -
// but that one who IS allowed to read still gets none of the controls that write.
//
// The selectors below are measured, not guessed: both contexts were loaded against a granted
// document and their buttons diffed. The two share the chrome - apps menu, sidebar, tree - and
// the owner alone gets the six write affordances.
import { test, expect } from '../../lib/console.mjs';
import { goto } from '../../lib/settle.mjs';
import { fixtures, itemTitle } from '../../lib/fixtures.mjs';

// Everything that mutates: edit and delete the document, copy it elsewhere, change who may read
// it, add a resource to it - and the avatar, which stands for having an identity at all.
const WRITE = [
    'button.btn-edit',
    'button.btn-delete',
    'button.btn-save-as',
    'button.btn-acl',
    'button.add-constructor',
    '.ldh-avatar',
];

// Chrome that has nothing to do with authorization. Asserted so that "anonymous sees none of the
// write controls" cannot pass by the page having failed to render at all.
const READ = ['button.btn-apps', 'button.btn-expanded-tree'];

// Presence, not visibility. Every write affordance the owner gets is a menu item inside a closed
// dropdown, and btn-expanded-tree sits in a sidebar that opens on demand - so toBeVisible() fails
// for controls that are present and correct. What authorization decides is whether the markup is
// emitted at all, and that is what these assert; which menu is open belongs to another spec.
const present = (page, selector) => expect(page.locator(selector), selector).not.toHaveCount(0);
const absent = (page, selector) => expect(page.locator(selector), selector).toHaveCount(0);

test.describe('a document an anonymous reader may read', () => {
    test('renders for whoever opens it', async ({ page }) => {
        await goto(page, fixtures.readable);

        await expect(page.locator('body')).toContainText(itemTitle(1));
        for (const selector of READ) await present(page, selector);
    });

    test('offers the owner the controls that write', async ({ page }, testInfo) => {
        test.skip(testInfo.project.name !== 'owner', 'the claim is about holding the certificate');
        await goto(page, fixtures.readable);

        for (const selector of WRITE) await present(page, selector);
    });

    test('offers an anonymous reader none of them', async ({ page }, testInfo) => {
        test.skip(testInfo.project.name !== 'anonymous', 'the claim is about holding no certificate');
        await goto(page, fixtures.readable);

        // Re-asserted here rather than left to the test above: without it every toHaveCount(0)
        // below would be satisfied by an error page, which is the exact way this axis was
        // decorative before.
        await expect(page.locator('body')).toContainText(itemTitle(1));
        for (const selector of WRITE) await absent(page, selector);
    });
});

// The preflight asserts fixtures.private is 403 anonymously, but LDH answers 403 for a document
// that does not exist just as it does for one that is refused - so that check on its own cannot
// tell a locked document from a missing one. This is the half it cannot make, because it holds
// no certificate: the owner reads the control, so the 403 the preflight sees is a denial.
test('the ungranted control exists, and it is anonymity alone that hides it', async ({ page }, testInfo) => {
    test.skip(testInfo.project.name !== 'owner', 'presence is what anonymity cannot demonstrate');
    await goto(page, fixtures.private);

    await expect(page.locator('body')).toContainText('Never granted');
});
