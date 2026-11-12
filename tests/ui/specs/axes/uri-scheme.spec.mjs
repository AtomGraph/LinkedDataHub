// A ?uri= that is not http(s) is never opened.
//
// An external document the proxy cannot fetch is opened as a link would open it: window.open, and
// location.assign when the browser blocks the popup, as it does on a page loaded from a link, with no user
// gesture. ?uri= is anyone's to set, so https://<dataspace>/?uri=javascript:alert(document.domain) ran
// alert() on the dataspace's origin (formal/client, uri_param_navigates_any_scheme, now
// uri_param_script_refused). The server refuses the URI with 400, and the client renders that error in the
// pane instead of opening the document.
//
// Playwright switches Chromium's popup blocker off, so window.open is stubbed to return what a blocked popup
// returns: null, which is the path that ran the script. An alert() fails the page guard in lib/console.mjs.
import { test, expect } from '../../lib/console.mjs';

for (const uri of ['javascript:alert(document.domain)', 'data:text/html,<script>alert(document.domain)</script>']) {
    test(`renders the error for ?uri=${uri.split(':')[0]}: and opens nothing`, async ({ page, allowNoise }) => {
        allowNoise.push(
            { pattern: /^HTTP 400: https:\/\/[^/]+\/\?.*uri=/, reason: 'the server refuses the URI on purpose' },
            { pattern: /^console\.error: Failed to load resource: .* 400 /, reason: 'the browser\'s own line for the same refusal' });
        await page.addInitScript(() => {
            window.opened = [];
            window.open = (...args) => { window.opened.push(args); return null; };
        });

        await page.goto('/?uri=' + encodeURIComponent(uri), { waitUntil: 'domcontentloaded' });

        await expect(page.locator('#tab-content > div.ldh-pane.is-active')).toHaveAttribute('data-status', '400', { timeout: 30_000 });
        expect(await page.evaluate(() => window.opened)).toEqual([]);
        expect(new URL(page.url()).searchParams.get('uri')).toBe(uri);
    });
}
