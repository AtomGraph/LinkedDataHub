// Preflight. Every check that fails here fails with the command that fixes it, because
// each one has cost a session's time at least once.
import { createHash } from 'node:crypto';
import { existsSync, readFileSync, statSync } from 'node:fs';
import { delimiter, join } from 'node:path';
import { accessSync, constants } from 'node:fs';
import { spawn } from 'node:child_process';
import { get } from './lib/http.mjs';
import { adminBase, composedSefPrefix, endUserBase, localSef, sefDir, sefPath } from './lib/stack.mjs';
import { fixtures as fixtureUris, itemCount, seed, teardown } from './lib/fixtures.mjs';
import { seedTaxonomy, taxonomyPackage, teardownTaxonomy, waitForPackageStylesheet } from './lib/taxonomy.mjs';

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

// Does the browser run the code in the working tree? Local-only by construction:
// target/ROOT/... exists exactly when docker-compose.override.yml is bind-mounting the working
// tree over the image, which is the dev loop. CI builds the SEF into the image and mounts no
// override, so there is nothing to compare and the check stands down on its own.
async function sef() {
    if (!existsSync(localSef)) {
        console.log('  SEF        no local build to compare (image-baked SEF) - skipped');
        return;
    }

    // Ask the page which stylesheet it runs rather than assuming. Comparing the stock SEF alone
    // was a false guarantee: since #383 a package-importing dataspace runs a COMPOSED SEF, so the
    // check went green while the browser executed a build hours old. That cost a session.
    //
    // A CHILD document, never the root: the root is served the stock stylesheet even on a dataspace
    // whose children get the composed one, so probing it reports "stock matches" and re-lands the
    // very false guarantee this check exists to remove. That is also why this runs after seeding -
    // there has to be a child to ask.
    const page = await get(fixtureUris.container);
    const running = /stylesheetLocation:\s*"([^"]+)"/.exec(String(page.body))?.[1];
    if (!running) {
        throw new Error(`Could not read stylesheetLocation from ${endUserBase}.\n`
            + `        The preflight cannot tell which stylesheet the browser would run, so it cannot\n`
            + `        promise the suite measures the working tree. Check the page renders at all.`);
    }

    if (!running.includes(composedSefPrefix)) {
        const served = await get(new URL(sefPath, endUserBase).href);
        if (served.status !== 200) {
            throw new Error(`The client SEF is not being served: ${served.status} for ${sefPath}`);
        }
        if (sha256(served.body) !== sha256(readFileSync(localSef))) {
            throw new Error(`The served client SEF does not match target/ROOT.\n`
                + `        The browser would run stale XSLT and the suite would measure the wrong build.\n`
                + `${republish}`);
        }
        console.log('  SEF        served stock copy matches the working tree');
        return;
    }

    // Composed. Its key is SHA-1 over the stock SEF's digest plus the import set, and the app takes
    // that digest ONCE, at startup - so after `make sef` a still-running app keeps publishing the old
    // key, and the old composition keeps being served. Every build stamps a fresh buildDateTime into
    // the SEF, so the digest (and the key, and the file) always change when the app is current:
    // a key whose file predates the stock SEF is exactly the app that has not restarted.
    const key = running.slice(running.lastIndexOf('/') + 1);
    const composed = join(sefDir, key);
    if (!existsSync(composed)) {
        throw new Error(`The page runs ${running}, which is not in ${sefDir}.\n`
            + `        Nothing local corresponds to the stylesheet the browser would execute, so the\n`
            + `        suite cannot know what it is measuring.\n${republish}`);
    }
    const builtAt = statSync(composed).mtimeMs;
    const compiledAt = statSync(localSef).mtimeMs;
    if (builtAt < compiledAt) {
        throw new Error(`The composed stylesheet the page runs is older than the working tree's build.\n`
            + `        ${key} was composed ${new Date(builtAt).toISOString()},\n`
            + `        target/ROOT was compiled ${new Date(compiledAt).toISOString()}.\n`
            + `        The app digests the stock SEF at startup, so it is still publishing the key it\n`
            + `        started with and the browser would run pre-'make sef' XSLT.\n${republish}`);
    }
    console.log(`  SEF        composed ${key.slice(0, 8)} is newer than the working tree's build`);
}

// Restarting Varnish alone cannot help when the app is publishing a stale key, and restarting the
// app changes the Varnish container IPs that nginx resolved at startup - hence the whole sequence.
const republish = `        Recompile and republish it with:\n`
    + `            make sef\n`
    + `            docker compose restart linkeddatahub\n`
    + `            docker compose restart varnish-frontend varnish-end-user varnish-admin\n`
    + `            docker compose restart nginx`;

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

// Varnish caches per URL and per Accept, and the suite reuses the same URIs every run - so a
// response cached before a grant existed outlives the grant being created, and one cached while
// it existed outlives it being deleted. Both were observed: with the document grant removed, the
// anonymous spec went green on a cached HTML variant while curl was already getting 403.
// http-tests bans the whole cache at the top of every test (run.sh); seeding happens once here,
// so once is enough. Best-effort by design - a dev pointed at a stack they do not run locally
// still gets a suite, with a line saying the caches are whatever the stack made them.
function purge() {
    const services = ['varnish-frontend', 'varnish-end-user', 'varnish-admin'];
    return Promise.all(services.map(service => new Promise(resolve => {
        const child = spawn('docker',
            ['compose', 'exec', '-T', service, 'varnishadm', 'ban', 'req.url ~ /'],
            { cwd: join(process.cwd(), '..'), stdio: 'ignore' });
        child.on('error', () => resolve(null));
        child.on('close', code => resolve(code === 0 ? service : null));
    }))).then(purged => {
        const done = purged.filter(Boolean);
        console.log(done.length
            ? `  caches     banned (${done.join(', ')})`
            : '  caches     not purged - docker compose did not answer, so cached ACL decisions may persist');
    });
}

// The suite grants access explicitly, per workflow, and asserts against what it granted. That
// only means anything on an instance where nothing is readable by default, so the baseline is
// checked rather than assumed - it is the one input the suite has always inherited from the
// environment instead of seeding, and the one that made a UI failure reproduce in CI and not
// locally. fixtures.private is never the target of any authorization the suite creates, so an
// anonymous 200 here is a blanket grant, not a fixture of the test. Runs after seeding: a 403
// on a document that does not exist proves nothing.
async function baseline() {
    const { status } = await get(fixtureUris.private);
    if (status === 403) {
        console.log(`  baseline   nothing is readable anonymously (${fixtureUris.private} -> 403)`);
        return;
    }

    throw new Error(`${fixtureUris.private} is readable anonymously (HTTP ${status}).\n`
        + `        Something is granting access to it, and every anonymous assertion in this suite\n`
        + `        would pass vacuously against that. Two usual causes:\n`
        + `          - a stray authorization from an interrupted run. List them and delete the one\n`
        + `            that does not belong: ldh get ${adminBase}acl/authorizations/\n`
        + `          - http-tests/admin/acl/make-public.sh, which fills in the shipped\n`
        + `            acl/authorizations/public/#this and has no reverse in the CLI. Undo exactly\n`
        + `            what it inserts with:\n`
        + `            ldh patch -f ssl/owner/keystore.p12 -p "$(cat secrets/owner_cert_password.txt)" \\\n`
        + `              ${adminBase}acl/authorizations/public/ <<'EOF'\n`
        + `            PREFIX acl:  <http://www.w3.org/ns/auth/acl#>\n`
        + `            PREFIX def:  <https://w3id.org/atomgraph/linkeddatahub/default#>\n`
        + `            PREFIX dh:   <https://www.w3.org/ns/ldt/document-hierarchy#>\n`
        + `            PREFIX nfo:  <http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#>\n`
        + `            PREFIX foaf: <http://xmlns.com/foaf/0.1/>\n`
        + `            DELETE DATA {\n`
        + `              <${adminBase}acl/authorizations/public/#this>\n`
        + `                  acl:accessToClass def:Root, dh:Container, dh:Item, nfo:FileDataObject ;\n`
        + `                  acl:accessTo <${endUserBase}sparql> .\n`
        + `              <${adminBase}acl/authorizations/public/#sparql-post>\n`
        + `                  a acl:Authorization ;\n`
        + `                  acl:accessTo <${endUserBase}sparql> ;\n`
        + `                  acl:mode acl:Append ;\n`
        + `                  acl:agentClass foaf:Agent, acl:AuthenticatedAgent .\n`
        + `            }\n`
        + `            EOF\n`
        + `        then purge the caches, or the ACL change is outlived by a cached 200:\n`
        + `            docker compose exec varnish-end-user varnishadm "ban req.url ~ /"\n`
        + `        A full reset - make drop && make up -- --build && make sef - also works.`);
}

// The concept tree is the taxonomy editor package's, not the platform's, so its fixtures carry the
// package import too. Kept apart from the generic fixtures because it is the one seeding
// step that changes how the whole dataspace renders, and teardown puts it back.
async function taxonomy() {
    if (process.env.UI_TESTS_SKIP_SEED) {
        console.log('  taxonomy   reusing what is there (UI_TESTS_SKIP_SEED)');
        return;
    }
    await teardownTaxonomy();
    const started = Date.now();
    const { container, addedPackage } = await seedTaxonomy();
    console.log(`  taxonomy   ${container}`
        + `${addedPackage ? ` (imported ${taxonomyPackage})` : ''} (${Date.now() - started} ms)`);

    // Importing a package is not the same as its rules reaching the browser: the composed
    // stylesheet is compiled asynchronously, and until it is published every page is
    // served the stock one. Waiting here rather than in each spec keeps the timeout in one
    // place, and out of assertions that are about the markup.
    const composing = Date.now();
    await waitForPackageStylesheet();
    console.log(`  stylesheet composed package SEF published (${Date.now() - composing} ms)`);
}

export default async function globalSetup() {
    console.log('\nPreflight');
    await reachable();
    cli();
    await fixtures();
    await purge();
    await baseline();
    await taxonomy();
    // Last: it asks a seeded child document what it runs, and the composed stylesheet it checks is
    // only published once a package-importing dataspace exists.
    await sef();
    console.log('');
}
