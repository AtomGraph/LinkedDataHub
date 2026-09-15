// Every page the suite opens is watched for the four ways this application fails quietly.
//
// Saxon-JS reports a broken template as an alert() or a console error and then renders
// nothing - commit 78b9ad7ac describes every chart on a page dying that way, with no
// visible symptom beyond a missing graphic. A spec that only asserts what it came to
// assert would have called that page fine.
import { test as base, expect } from '@playwright/test';
import { adminBase, endUserBase } from './stack.mjs';

// The welcome modal is shown to an authenticated agent once per browser, keyed on a
// cookie, and it is a centred backdrop: it intercepts every click a spec tries to make
// until it is dismissed. Seeding the cookie is what a returning reader has, and it is
// race-free where dismissing it is not - the modal appears when Saxon-JS gets to it, so
// a spec that clicks early loses. A spec about the welcome modal itself clears this.
const seen = [endUserBase, adminBase].map(base => ({
    name: 'LinkedDataHub.first-time-message',
    value: 'true',
    url: base,
}));

// Noise that is not this build's fault. Excluded by pattern and listed here with its
// reason, rather than by loosening the assertion for everything.
const preexisting = [
    // The unlimited DESCRIBE over a large container 502s on the dev stack, and reproduces
    // on builds predating this suite. Tracked separately; see commit 3305741ac.
    { pattern: /sparql\?query=DESCRIBE[\s\S]*has_parent/i, reason: 'pre-existing 502 on unlimited DESCRIBE' },
];

const allowed = (text, declared) =>
    [...preexisting, ...declared].some(({ pattern }) => pattern.test(text));

export const test = base.extend({
    // Noise a spec causes ON PURPOSE. A spec that injects a failure - a route fulfilled 403 to
    // prove the client survives it - would otherwise be failed by the very guard that makes the
    // injection worth doing. Declared per test, per pattern, with a reason, so it stays as narrow
    // as the `preexisting` list above and cannot quietly cover a defect it did not cause.
    allowNoise: async ({}, use) => {
        const declared = [];
        await use(declared);
    },

    page: async ({ page, allowNoise }, use, testInfo) => {
        await page.context().addCookies(seen);

        const noise = [];
        const note = entry => { if (!allowed(entry, allowNoise)) noise.push(entry); };

        page.on('console', message => {
            if (message.type() === 'error') note(`console.error: ${message.text()}`);
        });
        page.on('pageerror', error => note(`pageerror: ${error.message}`));
        // An alert() is how a Saxon-JS runtime error surfaces to the user. Dismissing it
        // without recording it would let the page carry on and the suite stay green.
        page.on('dialog', async dialog => {
            note(`dialog(${dialog.type()}): ${dialog.message()}`);
            await dialog.dismiss();
        });
        page.on('response', response => {
            if (response.status() >= 400) note(`HTTP ${response.status()}: ${decodeURIComponent(response.url())}`);
        });

        await use(page);

        if (noise.length) {
            await testInfo.attach('page-noise', { body: noise.join('\n'), contentType: 'text/plain' });
        }
        // Only when the test itself passed. Piling a teardown failure on top of a real
        // failure buries the assertion that actually mattered.
        if (testInfo.status === testInfo.expectedStatus) {
            expect(noise, 'the page should load without console errors, alerts or failed requests').toEqual([]);
        }
    },
});

export { expect };
