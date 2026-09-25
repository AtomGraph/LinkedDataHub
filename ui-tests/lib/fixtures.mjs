// The documents the specs drive, built with the same ldh CLI that http-tests uses for its
// fixtures. Seeding through the API rather than loading a TriG means the suite behaves
// identically against a virgin CI instance and a lived-in dev one, and that a broken
// create path fails here instead of halfway through a spec.
import { spawn } from 'node:child_process';
import { mkdtempSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { adminBase, endUserBase, ownerKeystore, ownerPassword } from './stack.mjs';

const slug = 'ui-fixtures';

// What an anonymous reader is granted, as two authorizations rather than one, so each scope is
// legible on its own and either can be dropped without the other. Slugged because the suite
// deletes what it creates - it shares a dev stack and does not snapshot the dataset the way
// http-tests does.
const authSlugs = { documents: `${slug}-public-docs`, endpoint: `${slug}-public-sparql` };

export const publicAuthorizations =
    Object.values(authSlugs).map(name => `${adminBase}acl/authorizations/${name}/`);

export const fixtures = {
    container: `${endUserBase}${slug}/`,
    // The control. No authorization the suite creates ever targets it, so its anonymous 403
    // is what proves the instance grants nothing by default - and what an anonymous denial
    // assertion is written against. Every grant the suite makes must stay document-scoped
    // (`--to`), never class-scoped (`--to-all-in dh:Item`), or this document is caught by it.
    //
    // A sibling of the container, NOT a child of it: document-tree counts the container's
    // children against itemCount, and a 26th child fails it. Nothing counts the root's.
    private: `${endUserBase}${slug}-private/`,
    // Fragment URIs of the resources inside the container document. Passing --uri keeps
    // them addressable, so a spec can name the block it is asserting about instead of
    // fishing for the nth card on the page.
    query: `${endUserBase}${slug}/#items-query`,
    view: `${endUserBase}${slug}/#items-view`,
    // Counted by kind, because a bar chart's value axis must be numeric - see chartQuery below.
    chartQuery: `${endUserBase}${slug}/#kinds-query`,
    chart: `${endUserBase}${slug}/#items-chart`,
    // The chart as CONTENT. A ldh:ResultSetChart is data until something puts it in the
    // document's rdf:_N list, and only ldh:Object and ldh:XHTML may be values there - so a chart
    // reaches the page wrapped in an Object, exactly as the built-in children view is. Without
    // this the chart existed in the graph and rendered nowhere, which is how a spec asserting on
    // .chart-controls came to wait 30s for an element that could never appear.
    chartBlock: `${endUserBase}${slug}/#chart-block`,
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

// The one item an anonymous reader may read, paired with fixtures.private, which nobody may.
// Assigned here rather than in the literal above because it is derived from itemUri, and named
// so a spec says what it means instead of rediscovering that item 1 happens to be the granted
// one. An item and not the container: the container renders a paged view, and a view is only
// as readable as the endpoint behind it.
fixtures.readable = itemUri(1);
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

// stdin, because `ldh patch` takes its SPARQL update that way and nothing else does.
export function ldh(args, { allowFailure = false, stdin } = {}) {
    return new Promise((resolve, reject) => {
        const child = spawn('ldh', args, {
            env: ldhEnv(),
            stdio: [stdin === undefined ? 'ignore' : 'pipe', 'pipe', 'pipe'],
        });
        if (stdin !== undefined) child.stdin.end(stdin);
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

// `sioc:has_container`, not `sioc:has_parent`. An item created in a container states the former;
// the latter is the document hierarchy's predicate and no item carries it, so this query matched
// nothing for as long as it existed - and nothing noticed, because the only thing rendering it was
// a chart nobody asserted had drawn. Measured 2026-09-25 against the endpoint: 0 rows before, 25
// after.
const query = `PREFIX  sioc: <http://rdfs.org/sioc/ns#>
PREFIX  dct:  <http://purl.org/dc/terms/>

SELECT DISTINCT  ?item ?title ?kind
WHERE
  { GRAPH ?g
      { ?item  sioc:has_container  <${fixtures.container}> ;
               dct:title        ?title ;
               dct:description  ?kind
      }
  }
ORDER BY ?title`;

// The chart's own query, and the reason it is not the view's. A bar chart's value axis has to be
// numeric - Google Charts refuses a string column outright ("Data column(s) for axis #0 cannot be
// of type string") - so plotting ?title against ?kind draws nothing however many rows come back.
// What these items can be charted BY is how many of each kind there are, which is an aggregate,
// and an aggregate is the wrong shape for the view that lists them. So: two queries, one each.
const chartQuery = `PREFIX  sioc: <http://rdfs.org/sioc/ns#>
PREFIX  dct:  <http://purl.org/dc/terms/>

SELECT  ?kind (COUNT(?item) AS ?items)
WHERE
  { GRAPH ?g
      { ?item  sioc:has_container  <${fixtures.container}> ;
               dct:description     ?kind
      }
  }
GROUP BY ?kind
ORDER BY ?kind`;

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

    await ldh(['create', 'item',
        '--container', endUserBase,
        '--title', 'Never granted',
        '--slug', `${slug}-private`]);

    const queryFile = join(mkdtempSync(join(tmpdir(), 'ui-tests-')), 'items.rq');
    writeFileSync(queryFile, query);

    await ldh(['add', 'select', '--title', 'Fixture items',
        '--uri', fixtures.query, '--query-file', queryFile, fixtures.container]);
    await ldh(['add', 'view', '--title', 'Fixture items view',
        '--uri', fixtures.view, '--query', fixtures.query, fixtures.container]);
    const chartQueryFile = join(mkdtempSync(join(tmpdir(), 'ui-tests-')), 'kinds.rq');
    writeFileSync(chartQueryFile, chartQuery);
    await ldh(['add', 'select', '--title', 'Fixture item kinds',
        '--uri', fixtures.chartQuery, '--query-file', chartQueryFile, fixtures.container]);

    await ldh(['add', 'result-set-chart', '--title', 'Fixture items chart',
        '--uri', fixtures.chart, '--query', fixtures.chartQuery,
        '--chart-type', 'https://w3id.org/atomgraph/client#BarChart',
        '--category-var-name', 'kind', '--series-var-name', 'items', fixtures.container]);
    await ldh(['add', 'xhtml-block', '--title', 'Fixture prose', '--uri', fixtures.prose,
        '--value', '<div xmlns="http://www.w3.org/1999/xhtml"><p>Prose block fixture.</p></div>',
        fixtures.container]);
    await ldh(['add', 'object-block', '--title', 'Fixture object', '--uri', fixtures.object,
        '--value', itemUri(1), fixtures.container]);
    await ldh(['add', 'object-block', '--title', 'Fixture chart block', '--uri', fixtures.chartBlock,
        '--value', fixtures.chart, fixtures.container]);

    // Everything an anonymous reader needs to render fixtures.readable, measured rather than
    // guessed: the document itself, the ancestors the document tree walks on its way down, and
    // the SPARQL endpoint. Without the endpoint the page raises a Saxon-JS alert
    // ("Required cardinality of first argument of ac:document-uri()...") plus three 403s, so a
    // document-scoped grant alone does not produce a working anonymous page.
    await ldh(['admin', 'create', 'authorization', '-b', adminBase,
        '--label', 'UI test public documents', '--slug', authSlugs.documents,
        '--agent-class', FOAF_AGENT,
        '--to', endUserBase,
        '--to', fixtures.container,
        '--to', fixtures.readable,
        '--read']);

    // Separate, because its scope is the one that cannot be narrowed. The endpoint enforces no
    // per-graph ACL: with this in place an anonymous SELECT reads EVERY graph in the dataspace,
    // including documents whose HTTP representation is 403 - fixtures.private among them. That
    // is the platform's behaviour, not this suite's (admin/acl/make-public.sh grants the same
    // thing), and it is why fixtures.private proves only that no blanket DOCUMENT grant is in
    // force. Append as well as read: the client sends some queries over POST.
    await ldh(['admin', 'create', 'authorization', '-b', adminBase,
        '--label', 'UI test public SPARQL', '--slug', authSlugs.endpoint,
        '--agent-class', FOAF_AGENT,
        '--to', `${endUserBase}sparql`,
        '--read', '--append']);

    return fixtures;
}

const FOAF_AGENT = 'http://xmlns.com/foaf/0.1/Agent';

// Items are documents of their own, so the container does not take them with it.
export async function teardown() {
    await inBatches(itemNumbers(), 6, n =>
        ldh(['delete', itemUri(n)], { allowFailure: true }));
    for (const authorization of publicAuthorizations) {
        await ldh(['delete', authorization], { allowFailure: true });
    }
    await ldh(['delete', fixtures.private], { allowFailure: true });
    await ldh(['delete', fixtures.container], { allowFailure: true });
}
