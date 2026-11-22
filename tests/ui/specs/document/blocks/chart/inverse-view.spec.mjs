// A chart an ontology attaches to a property, as views are attached (ldh:view, ldh:inverseView): drawn about the resource
// whose page it is on.
//
// The block is derived, not stored: client/block.xsl injects it under the resource it is about and mints it an @about of
// its own, a fragment of the page's document that no graph holds. A view binds $about to the resource it sits in, which
// is what an inverse view's declaration promises ("?value property $about", ldh.ttl). A chart bound only $this, to its
// own @about, so a chart attached this way queried about that fragment and matched nothing: "No results. The query ran
// cleanly and matched nothing." on every page it was injected into.
//
// The chart is this spec's own fixture, written into the application's copy of the taxonomy package's ontology before
// the test and removed after it, the way the constructor editor's specs plant constructors there. It used to be part of
// the package, which put a table nobody asked for on every scheme's page. Attached to skos:inScheme, it reads the
// hierarchy of the scheme its page is about: the scheme's concepts and how many narrower concepts each has, the
// hierarchy read from both ends as the tree reads it.
import { test, expect } from '../../../../lib/console.mjs';
import { goto, settled } from '../../../../lib/settle.mjs';
import { ldh } from '../../../../lib/fixtures.mjs';
import { adminBase } from '../../../../lib/stack.mjs';
import { conceptPage, labelOf, packageOntologyDocument, scheme } from '../../../../lib/taxonomy.mjs';
import { IN_SCHEME, viewBlock } from '../../../../lib/view.mjs';
import { canvas } from '../../../../lib/chart.mjs';

const SKOS = 'http://www.w3.org/2004/02/skos/core#';
const LDH = 'https://w3id.org/atomgraph/linkeddatahub#';
const AC = 'https://w3id.org/atomgraph/client#';
const SP = 'http://spinrdf.org/sp#';
const SPIN = 'http://spinrdf.org/spin#';
const DCT = 'http://purl.org/dc/terms/';
// sp:text is a multi-line literal, and a spec file cannot nest those inside a template literal
const TRIPLE_QUOTE = '"'.repeat(3);

const CHART = `${packageOntologyDocument}#NarrowerCountsInSchemeFixture`;
const QUERY = `${packageOntologyDocument}#SelectNarrowerCountsInSchemeFixture`;
const clearOntologies = () => ldh(['admin', 'clear', 'ontology', adminBase], { allowFailure: true });

const attachChart = () => ldh(['patch', packageOntologyDocument], { stdin: [
    `PREFIX skos: <${SKOS}>`, `PREFIX ldh: <${LDH}>`, `PREFIX ac: <${AC}>`, `PREFIX sp: <${SP}>`, `PREFIX spin: <${SPIN}>`, `PREFIX dct: <${DCT}>`,
    `INSERT {`,
    `  skos:inScheme ldh:inverseView <${CHART}> .`,
    `  <${CHART}> a ldh:ResultSetChart ;`,
    `    dct:title "Narrower concepts per concept" ;`,
    `    spin:query <${QUERY}> ;`,
    `    ldh:chartType ac:Table ;`,
    `    ldh:categoryVarName "concept" ;`,
    `    ldh:seriesVarName "narrower" .`,
    `  <${QUERY}> a sp:Select ;`,
    `    dct:title "Select the narrower concept count of each concept in a scheme" ;`,
    `    sp:text ${TRIPLE_QUOTE}PREFIX skos: <${SKOS}>`,
    `SELECT ?concept (COUNT(DISTINCT ?child) AS ?narrower)`,
    `WHERE {`,
    `  GRAPH ?graph { ?node skos:inScheme $about ; skos:prefLabel ?concept }`,
    `  OPTIONAL { { GRAPH ?narrowerGraph { ?node skos:narrower ?child } } UNION { GRAPH ?broaderGraph { ?child skos:broader ?node } } }`,
    `}`,
    `GROUP BY ?concept`,
    `ORDER BY ?concept${TRIPLE_QUOTE} .`,
    `} WHERE {}`,
].join('\n') });

const detachChart = () => ldh(['patch', packageOntologyDocument], { allowFailure: true, stdin: [
    `PREFIX skos: <${SKOS}>`, `PREFIX ldh: <${LDH}>`,
    `DELETE { skos:inScheme ldh:inverseView <${CHART}> . <${CHART}> ?p ?o . <${QUERY}> ?q ?r }`,
    `WHERE { OPTIONAL { <${CHART}> ?p ?o } OPTIONAL { <${QUERY}> ?q ?r } }`,
].join('\n') });

// the injected chart, among the blocks attached to skos:inScheme: the one that draws
const chart = page => viewBlock(page, IN_SCHEME).filter({ has: page.locator('.chart-canvas') });
const row = (page, name) => canvas(chart(page)).getByRole('row').filter({ has: page.getByRole('cell', { name: labelOf(name), exact: true }) });

test.describe('a chart attached to a property', { tag: '@owner' }, () => {
    // The declaration is the fixture's and the results are the query's, and neither depends on who is reading.
    const owner = testInfo => testInfo.project.name === 'owner';
    test.beforeEach(async ({}, testInfo) => {
        test.skip(!owner(testInfo), 'what the chart declares and what its query returns are the same for either agent');
    });
    test.beforeAll(async ({}, testInfo) => {
        if (!owner(testInfo)) return;
        await attachChart();
        await clearOntologies();
    });
    test.afterAll(async ({}, testInfo) => {
        if (!owner(testInfo)) return;
        await detachChart();
        await clearOntologies();
    });

    test('queries about the resource whose page it is on, not about its own block', async ({ page }) => {
        await goto(page, conceptPage(scheme));
        await settled(page);

        await expect(chart(page)).toHaveCount(1);
        // hot drinks has coffee (which names it as broader) and tea (which it names as narrower); coffee has espresso
        // and latte; cold drinks has juice; espresso is a leaf
        await expect(row(page, 'hot-drinks').getByRole('cell', { name: '2', exact: true })).toBeVisible();
        await expect(row(page, 'coffee').getByRole('cell', { name: '2', exact: true })).toBeVisible();
        await expect(row(page, 'cold-drinks').getByRole('cell', { name: '1', exact: true })).toBeVisible();
        await expect(row(page, 'espresso').getByRole('cell', { name: '0', exact: true })).toBeVisible();
        await expect(canvas(chart(page))).not.toContainText('No results');
    });
});
