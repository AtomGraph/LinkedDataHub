// Preflight. Every check that fails here fails with the command that fixes it, because
// each one has cost a session's time at least once.
import { createHash } from 'node:crypto';
import { existsSync, readFileSync } from 'node:fs';
import { delimiter, join } from 'node:path';
import { accessSync, constants } from 'node:fs';
import { get } from './lib/http.mjs';
import { endUserBase, localSef, sefPath } from './lib/stack.mjs';
import { itemCount, seed, teardown } from './lib/fixtures.mjs';

function onPath(command) {
    return (process.env.PATH ?? '').split(delimiter).some(dir => {
        try {
            accessSync(join(dir, command), constants.X_OK);
            return true;
        } catch {
            return false;
        }
    });
}

const sha256 = buffer => createHash('sha256').update(buffer).digest('hex');

// A refused dual-stack connect arrives as an AggregateError whose own message is empty -
// the reason is on .code, and the per-address attempts are in .errors.
const why = error => error.code ?? (error.message || error.name);

async function reachable() {
    try {
        // Any response at all proves the proxy is up: an unauthenticated GET may
        // legitimately be a 403, which says the application is answering.
        const { status } = await get(endUserBase);
        console.log(`  stack      ${endUserBase} -> ${status}`);
    } catch (cause) {
        throw new Error(`${endUserBase} is not answering (${why(cause)}).\n`
            + `        The nginx container fronts every port the suite uses. Start it with:\n`
            + `            make up nginx`, { cause });
    }
}

function cli() {
    if (!onPath('ldh')) {
        throw new Error(`The ldh CLI is not on $PATH, and the fixtures are built with it.\n`
            + `        Build it and put it on the path with:\n`
            + `            make cli\n`
            + `            export PATH="${join(process.cwd(), '..', 'cli/bin')}:$PATH"`);
    }
    console.log('  ldh        on $PATH');
}

// Local-only by construction. target/ROOT/... exists exactly when
// docker-compose.override.yml is bind-mounting the working tree over the image, which is
// the dev loop. CI builds the SEF into the image and mounts no override, so there is
// nothing to compare and the check stands down on its own.
async function sef() {
    if (!existsSync(localSef)) {
        console.log('  SEF        no local build to compare (image-baked SEF) - skipped');
        return;
    }
    const served = await get(new URL(sefPath, endUserBase).href);
    if (served.status !== 200) {
        throw new Error(`The client SEF is not being served: ${served.status} for ${sefPath}`);
    }
    const local = sha256(readFileSync(localSef));
    if (sha256(served.body) === local) {
        console.log(`  SEF        served copy matches the working tree`);
        return;
    }
    throw new Error(`The served client SEF does not match target/ROOT.\n`
        + `        The browser would run stale XSLT and the suite would measure the wrong build.\n`
        + `        Recompile and republish it with:\n`
        + `            make sef\n`
        + `            docker compose restart varnish-frontend varnish-end-user varnish-admin`);
}

// Fixtures are removed and rebuilt, so a run that crashed before its teardown does not
// leave the next one creating a slug that already exists.
async function fixtures() {
    if (process.env.UI_TESTS_SKIP_SEED) {
        console.log('  fixtures   reusing what is there (UI_TESTS_SKIP_SEED)');
        return;
    }
    await teardown();
    const started = Date.now();
    const { container } = await seed();
    console.log(`  fixtures   ${container} with ${itemCount} items (${Date.now() - started} ms)`);
}

export default async function globalSetup() {
    console.log('\nPreflight');
    await reachable();
    cli();
    await sef();
    await fixtures();
    console.log('');
}
