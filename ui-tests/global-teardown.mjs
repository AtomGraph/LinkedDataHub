// The suite owns one container and removes it. It deliberately does not snapshot and
// restore the whole dataset the way http-tests/run.sh does: that is right for a suite that
// owns the instance, and wrong for one sharing a dev stack with the person running it.
import { teardown } from './lib/fixtures.mjs';

export default async function globalTeardown() {
    if (process.env.UI_TESTS_KEEP_FIXTURES) {
        console.log('\nLeaving fixtures in place (UI_TESTS_KEEP_FIXTURES)');
        return;
    }
    await teardown();
}
