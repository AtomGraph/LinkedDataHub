import { defineConfig, devices } from '@playwright/test';
import { endUserBase, ownerCertificates } from './lib/stack.mjs';

const ci = !!process.env.CI;

export default defineConfig({
    testDir: './specs',
    outputDir: './test-results',
    globalSetup: './global-setup.mjs',
    globalTeardown: './global-teardown.mjs',

    // One shared instance, and several specs write to it. Parallel workers would race on
    // the fixture container, so the suite is serial by construction rather than by luck.
    fullyParallel: false,
    workers: 1,

    // A stray test.only would silently shrink a CI run to one test and still report green.
    forbidOnly: ci,
    retries: ci ? 2 : 0,

    // Saxon-JS hydrates after the server shell arrives, and a cold container's first render
    // pays for the XSLT compile. Runners are slower than a laptop at both.
    timeout: ci ? 120_000 : 60_000,
    expect: { timeout: ci ? 20_000 : 10_000 },

    reporter: [
        ['list'],
        ['html', { outputFolder: 'out/html', open: 'never' }],
    ],

    use: {
        baseURL: endUserBase,
        ignoreHTTPSErrors: true,
        viewport: { width: 1440, height: 1000 },
        trace: 'retain-on-failure',
        screenshot: 'only-on-failure',
        video: ci ? 'retain-on-failure' : 'off',
    },

    // The two projects are the authorization axis: the same specs, run by someone who may
    // write and by someone who may not. A spec that only makes sense for one of them says
    // so itself, rather than living in a separate file.
    projects: [
        {
            name: 'owner',
            use: { ...devices['Desktop Chrome'], clientCertificates: ownerCertificates() },
        },
        {
            name: 'anonymous',
            use: { ...devices['Desktop Chrome'] },
        },
    ],
});
