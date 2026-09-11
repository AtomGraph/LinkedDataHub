// The documents the specs drive, built with the same ldh CLI that http-tests uses for its
// fixtures. Seeding through the API rather than loading a TriG means the suite behaves
// identically against a virgin CI instance and a lived-in dev one, and that a broken
// create path fails here instead of halfway through a spec.
import { spawn } from 'node:child_process';
import { mkdtempSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { endUserBase, ownerKeystore, ownerPassword } from './stack.mjs';

const slug = 'ui-fixtures';

export const fixtures = {
    container: `${endUserBase}${slug}/`,
    // Fragment URIs of the resources inside the container document. Passing --uri keeps
    // them addressable, so a spec can name the block it is asserting about instead of
    // fishing for the nth card on the page.
    query: `${endUserBase}${slug}/#items-query`,
    view: `${endUserBase}${slug}/#items-view`,
    chart: `${endUserBase}${slug}/#items-chart`,
    prose: `${endUserBase}${slug}/#prose-block`,
    object: `${endUserBase}${slug}/#object-block`,
};

// Enough children that the default 20-row page is not the last one, so the pager has a
// second page to go to. Lowerable for a slow runner.
export const itemCount = Number(process.env.UI_TESTS_ITEMS ?? 25);

// Three repeating values so a facet over ?kind has something to filter by. A facet whose
// values are all distinct is as dead a control as one whose values are all the same.
const kinds = ['alpha', 'beta', 'gamma'];

// Every fixture URI is a pure function of the slug and the index. globalSetup runs in the
// main process and the specs run in workers, so nothing recorded during seeding survives
// to be read by a test - a URI a spec needs has to be derivable, not remembered.
export const itemSlug = n => `item-${String(n).padStart(2, '0')}`;
export const itemUri = n => `${fixtures.container}${itemSlug(n)}/`;
export const itemTitle = n => `Fixture item ${String(n).padStart(2, '0')}`;
export const itemKind = n => kinds[n % kinds.length];
export const itemNumbers = () => Array.from({ length: itemCount }, (_, i) => i + 1);

function ldhEnv() {
    return {
        ...process.env,
        LDH_CERT_FILE: ownerKeystore,
        LDH_CERT_PASSWORD: ownerPassword(),
        LDH_BASE: endUserBase,
    };
}

export function ldh(args, { allowFailure = false } = {}) {
    return new Promise((resolve, reject) => {
        const child = spawn('ldh', args, { env: ldhEnv(), stdio: ['ignore', 'pipe', 'pipe'] });
        let out = '', err = '';
        child.stdout.on('data', chunk => out += chunk);
        child.stderr.on('data', chunk => err += chunk);
        child.on('error', reject);
        child.on('close', code => {
            if (code === 0 || allowFailure) resolve({ code, stdout: out.trim(), stderr: err.trim() });
            else reject(new Error(`ldh ${args.join(' ')}\n  exit ${code}\n  ${err.trim()}`));
        });
    });
}

// ldh starts a JVM per invocation, so 25 items serially is 25 cold starts. The cap keeps
// the instance from being hit by 25 concurrent PUTs at once.
async function inBatches(inputs, limit, worker) {
    const results = [];
    for (let i = 0; i < inputs.length; i += limit) {
        results.push(...await Promise.all(inputs.slice(i, i + limit).map(worker)));
    }
    return results;
}

const query = `PREFIX  sioc: <http://rdfs.org/sioc/ns#>
PREFIX  dct:  <http://purl.org/dc/terms/>

SELECT DISTINCT  ?item ?title ?kind
WHERE
  { GRAPH ?g
      { ?item  sioc:has_parent  <${fixtures.container}> ;
               dct:title        ?title ;
               dct:description  ?kind
      }
  }
ORDER BY ?title`;

export async function seed() {
    const container = await ldh(['create', 'container',
        '--parent', endUserBase, '--title', 'UI test fixtures', '--slug', slug]);
    if (container.stdout !== fixtures.container) {
        throw new Error(`Expected the container at ${fixtures.container}, got ${container.stdout}`);
    }

    await inBatches(itemNumbers(), 6, n => ldh(['create', 'item',
        '--container', fixtures.container,
        '--title', itemTitle(n),
        '--description', itemKind(n),
        '--slug', itemSlug(n)]));

    const queryFile = join(mkdtempSync(join(tmpdir(), 'ui-tests-')), 'items.rq');
    writeFileSync(queryFile, query);

    await ldh(['add', 'select', '--title', 'Fixture items',
        '--uri', fixtures.query, '--query-file', queryFile, fixtures.container]);
    await ldh(['add', 'view', '--title', 'Fixture items view',
        '--uri', fixtures.view, '--query', fixtures.query, fixtures.container]);
    await ldh(['add', 'result-set-chart', '--title', 'Fixture items chart',
        '--uri', fixtures.chart, '--query', fixtures.query,
        '--chart-type', 'https://w3id.org/atomgraph/client#BarChart',
        '--category-var-name', 'kind', '--series-var-name', 'title', fixtures.container]);
    await ldh(['add', 'xhtml-block', '--title', 'Fixture prose', '--uri', fixtures.prose,
        '--value', '<div xmlns="http://www.w3.org/1999/xhtml"><p>Prose block fixture.</p></div>',
        fixtures.container]);
    await ldh(['add', 'object-block', '--title', 'Fixture object', '--uri', fixtures.object,
        '--value', itemUri(1), fixtures.container]);

    return fixtures;
}

// Items are documents of their own, so the container does not take them with it.
export async function teardown() {
    await inBatches(itemNumbers(), 6, n =>
        ldh(['delete', itemUri(n)], { allowFailure: true }));
    await ldh(['delete', fixtures.container], { allowFailure: true });
}
