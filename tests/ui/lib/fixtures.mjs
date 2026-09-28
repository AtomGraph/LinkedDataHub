// The documents the specs drive, built with the same ldh CLI that tests/http uses for its
// fixtures. Seeding through the API rather than loading a TriG means the suite behaves
// identically against a virgin CI instance and a lived-in dev one, and that a broken
// create path fails here instead of halfway through a spec.
import { spawn } from 'node:child_process';
import { mkdtempSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { adminBase, endUserBase, ownerKeystore, ownerPassword, remoteAdminBase, remoteEndUserBase } from './stack.mjs';

const slug = 'ui-fixtures';
// Named once, because a pivot onto the container answers with this title and a spec asserts it.
export const containerTitle = 'UI test fixtures';

// What an anonymous reader is granted, as two authorizations rather than one, so each scope is
// legible on its own and either can be dropped without the other. Slugged because the suite
// deletes what it creates - it shares a dev stack and does not snapshot the dataset the way
// tests/http does.
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
    // The view as CONTENT, for the same reason as chartBlock below: an ldh:View is data until an
    // Object block names it. Without this wrapper the fixture view existed in the graph and rendered
    // nowhere - the only view blocks on the page were the built-in children view's, whose query knows
    // nothing of ?kind, so the facet the kinds below exist for was never on the page to be driven.
    viewBlock: `${endUserBase}${slug}/#view-block`,
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
    // The query block, in a document of its own. Seeding it into the container failed every spec on
    // that page: YASQE fetches http://prefix.cc/popular/all.file.json for prefix completion, plain
    // HTTP from an HTTPS page, and the mixed-content error it logs is exactly what lib/console.mjs
    // fails a page on. A sibling of the container, like `private`, so the container's child count
    // holds; the query it wraps is the container's, dereferenced across documents like any other.
    queryDocument: `${endUserBase}${slug}-query/`,
    queryBlock: `${endUserBase}${slug}-query/#query-block`,
    // The host of a resource embedded from ANOTHER dataspace. Every other object block on these
    // pages names a resource of this origin, which the browser fetches directly; this one names
    // remoteDocument(), which it can only reach through the Linked Data proxy - the path on which
    // the platform's own identity, not the reader's, once decided whether the block could be
    // edited. A document of its own, like queryDocument, so the container's block and child counts
    // hold; a sibling of the container, so the document tree's item count does too.
    remoteHost: `${endUserBase}${slug}-remote/`,
    remoteBlock: `${endUserBase}${slug}-remote/#remote-block`,
};

// The embedded resource itself, in the second end-user dataspace the preflight resolved. Functions
// rather than entries above because that dataspace is known only once globalSetup has run.
export const remoteDocument = () => `${remoteEndUserBase()}${slug}-remote/`;
export const remoteDocumentTitle = 'Fixture remote document';
// What lets an anonymous reader see it: a grant in the remote dataspace's OWN admin, since access to
// a document is decided by the dataspace it lives in, not by the one embedding it.
const remoteAuthSlug = `${slug}-remote-public`;
export const remoteAuthorization = () => `${remoteAdminBase()}acl/authorizations/${remoteAuthSlug}/`;

// Enough children that the default 20-row page is not the last one, so the pager has a
// second page to go to. Lowerable for a slow runner.
export const itemCount = Number(process.env.UI_TESTS_ITEMS ?? 25);

// Three repeating values so a facet over ?kind has something to filter by. A facet whose
// values are all distinct is as dead a control as one whose values are all the same.
// Assigned by index modulo three, so the count per kind is a function of itemCount - a spec
// that filters to one kind can say how many rows it expects rather than "fewer".
export const kinds = ['alpha', 'beta', 'gamma'];
export const kindCount = kind => itemNumbers().filter(n => itemKind(n) === kind).length;

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
//
// Two numeric columns, not one. The series control is a choice between value columns, and with a
// single one it can only be left as it is - so the title lengths are summed as a second measure.
// Every title is the same length, which makes ?chars a fixed multiple of ?items: a different scale
// on the value axis, and a different axis title, is what a series change has to show.
const chartQuery = `PREFIX  sioc: <http://rdfs.org/sioc/ns#>
PREFIX  dct:  <http://purl.org/dc/terms/>

SELECT  ?kind (COUNT(?item) AS ?items) (SUM(STRLEN(?title)) AS ?chars)
WHERE
  { GRAPH ?g
      { ?item  sioc:has_container  <${fixtures.container}> ;
               dct:title           ?title ;
               dct:description     ?kind
      }
  }
GROUP BY ?kind
ORDER BY ?kind`;

export async function seed() {
    const container = await ldh(['create', 'container',
        '--parent', endUserBase, '--title', containerTitle, '--slug', slug]);
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
    await ldh(['add', 'object-block', '--title', 'Fixture view block', '--uri', fixtures.viewBlock,
        '--value', fixtures.view, fixtures.container]);

    await ldh(['create', 'item',
        '--container', endUserBase,
        '--title', 'Fixture query',
        '--slug', `${slug}-query`]);
    await ldh(['add', 'object-block', '--title', 'Fixture query block', '--uri', fixtures.queryBlock,
        '--value', fixtures.query, fixtures.queryDocument]);

    // The cross-origin pair: a document in the other dataspace, created by the same owner (the root
    // owner owns every dataspace of the stack, the entrypoint sees to that), and the host here that
    // embeds it. The remote grant is what makes the embedded rendering an anonymous reader's to
    // see; the platform's own secretary is a writer of every end-user dataspace already.
    await ldh(['create', 'item', '-b', remoteEndUserBase(),
        '--container', remoteEndUserBase(),
        '--title', remoteDocumentTitle,
        '--slug', `${slug}-remote`]);
    await ldh(['admin', 'create', 'authorization', '-b', remoteAdminBase(),
        '--label', 'UI test public remote document', '--slug', remoteAuthSlug,
        '--agent-class', FOAF_AGENT,
        '--to', remoteDocument(),
        '--read']);
    await ldh(['create', 'item',
        '--container', endUserBase,
        '--title', 'Fixture remote host',
        '--slug', `${slug}-remote`]);
    await ldh(['add', 'object-block', '--title', 'Fixture remote block', '--uri', fixtures.remoteBlock,
        '--value', remoteDocument(), fixtures.remoteHost]);

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
        '--to', fixtures.remoteHost,
        '--read']);

    // Separate, because its scope is the one that cannot be narrowed. The endpoint enforces no
    // per-graph ACL: with this in place an anonymous SELECT reads EVERY graph in the dataspace,
    // including documents whose HTTP representation is 403 - fixtures.private among them. That
    // is the platform's behaviour, not this suite's (ldh admin make-public grants the same
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
    await ldh(['delete', fixtures.queryDocument], { allowFailure: true });
    await ldh(['delete', fixtures.remoteHost], { allowFailure: true });
    // Only once the preflight has resolved the remote dataspace: a teardown that runs before it
    // (UI_TESTS_SKIP_SEED, or a run that failed earlier in the preflight) has nothing to remove there.
    if (process.env.REMOTE_END_USER_BASE_URL) {
        await ldh(['delete', remoteAuthorization()], { allowFailure: true });
        await ldh(['delete', remoteDocument()], { allowFailure: true });
    }
    await ldh(['delete', fixtures.container], { allowFailure: true });
}
