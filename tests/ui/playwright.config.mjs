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
        // `@owner` is not collected here rather than collected and skipped. A spec that cannot run
        // without a certificate - it writes, or it is about who you are - says so with the tag, and
        // the project declines it. That leaves "skipped" meaning something again: before this, 141
        // of 153 were skipped every run, and among them sat two dozen skipping for a reason that
        // was simply false (the fixtures ARE granted to anonymous). Nobody could have spotted that
        // in a wall of skips, and the run that found it was the one where the wall came down.
        {
            name: 'anonymous',
            grepInvert: /@owner/,
            use: { ...devices['Desktop Chrome'] },
        },
        // Not a test project: it reports which components the tree covers, and runs as the owner
        // because a reader who may not read a document cannot tell an absent component from a
        // forbidden one. Its own directory keeps specs/ a pure mirror of the component tree, so
        // the "every folder is a declared component" rule needs no exemption for it. No retries -
        // a report that disagrees with itself twice is a finding, not a flake.
        {
            name: 'coverage',
            testDir: './coverage',
            retries: 0,
            use: { ...devices['Desktop Chrome'], clientCertificates: ownerCertificates() },
        },
    ],
});
