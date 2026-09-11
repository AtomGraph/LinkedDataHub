// Every page the suite opens is watched for the four ways this application fails quietly.
//
// Saxon-JS reports a broken template as an alert() or a console error and then renders
// nothing - commit 78b9ad7ac describes every chart on a page dying that way, with no
// visible symptom beyond a missing graphic. A spec that only asserts what it came to
// assert would have called that page fine.
import { test as base, expect } from '@playwright/test';

// Noise that is not this build's fault. Excluded by pattern and listed here with its
// reason, rather than by loosening the assertion for everything.
const preexisting = [
    // The unlimited DESCRIBE over a large container 502s on the dev stack, and reproduces
    // on builds predating this suite. Tracked separately; see commit 3305741ac.
    { pattern: /sparql\?query=DESCRIBE[\s\S]*has_parent/i, reason: 'pre-existing 502 on unlimited DESCRIBE' },
];

const allowed = text => preexisting.some(({ pattern }) => pattern.test(text));

export const test = base.extend({
    page: async ({ page }, use, testInfo) => {
        const noise = [];
        const note = entry => { if (!allowed(entry)) noise.push(entry); };

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
