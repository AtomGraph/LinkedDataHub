// A view attached to a property whose domain or range is a union of classes (owl:unionOf) shows on the pages of each
// of them.
//
// The page finds the views it gets with one query against the dataspace's ontology (client/block.xsl,
// ldh:ontology-view-query): an ldh:inverseView where the page's type is the property's range, an ldh:view where it is
// the domain. A range written as "a scheme or a collection" is a blank node, owl:unionOf a list of the two, and the
// lookup compared the page's type with the blank node itself: such a view showed on no page at all.
//
// The properties and views are this spec's own fixture, written into the application's copy of the taxonomy package's
// ontology before the test and removed after it, as the inverse-view chart spec plants its chart there. Both views show
// when empty, so what they find does not decide whether they appear.
import { test, expect } from '../../../../lib/console.mjs';
import { goto, settled } from '../../../../lib/settle.mjs';
import { ldh } from '../../../../lib/fixtures.mjs';
import { adminBase } from '../../../../lib/stack.mjs';
import { conceptPage, packageOntologyDocument, scheme } from '../../../../lib/taxonomy.mjs';
import { viewBlock } from '../../../../lib/view.mjs';

const SKOS = 'http://www.w3.org/2004/02/skos/core#';
const LDH = 'https://w3id.org/atomgraph/linkeddatahub#';
const AC = 'https://w3id.org/atomgraph/client#';
const SP = 'http://spinrdf.org/sp#';
const SPIN = 'http://spinrdf.org/spin#';
const DCT = 'http://purl.org/dc/terms/';
const RDFS = 'http://www.w3.org/2000/01/rdf-schema#';
const RDF = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#';
const OWL = 'http://www.w3.org/2002/07/owl#';

// pointed at a scheme or a collection: its inverse view belongs on a scheme's page
const INVERSE_PROPERTY = `${packageOntologyDocument}#inSchemeOrCollectionFixture`;
const INVERSE_VIEW = `${packageOntologyDocument}#UnionRangeViewFixture`;
const INVERSE_QUERY = `${packageOntologyDocument}#SelectUnionRangeViewFixture`;
// said of a concept or a collection: its view belongs on a concept's page
const FORWARD_PROPERTY = `${packageOntologyDocument}#conceptOrCollectionFixture`;
const FORWARD_VIEW = `${packageOntologyDocument}#UnionDomainViewFixture`;
const FORWARD_QUERY = `${packageOntologyDocument}#SelectUnionDomainViewFixture`;

const clearOntologies = () => ldh(['admin', 'clear', 'ontology', adminBase], { allowFailure: true });

const view = (uri, title, query, text) => [
    `  <${uri}> a ldh:View ; dct:title "${title}" ; spin:query <${query}> ; ac:mode ac:TableMode ; ldh:showWhenEmpty true .`,
    `  <${query}> a sp:Select ; dct:title "${title}" ; sp:text "${text}" .`,
];

const attach = () => ldh(['patch', packageOntologyDocument], { stdin: [
    `PREFIX skos: <${SKOS}>`, `PREFIX ldh: <${LDH}>`, `PREFIX ac: <${AC}>`, `PREFIX sp: <${SP}>`, `PREFIX spin: <${SPIN}>`,
    `PREFIX dct: <${DCT}>`, `PREFIX rdfs: <${RDFS}>`, `PREFIX owl: <${OWL}>`,
    `INSERT {`,
    `  <${INVERSE_PROPERTY}> a owl:ObjectProperty ; rdfs:label "In scheme or collection" ;`,
    `    rdfs:domain skos:Concept ; rdfs:range [ owl:unionOf ( skos:ConceptScheme skos:Collection ) ] ;`,
    `    ldh:inverseView <${INVERSE_VIEW}> .`,
    ...view(INVERSE_VIEW, 'Union range fixture', INVERSE_QUERY,
        `SELECT DISTINCT ?concept WHERE { GRAPH ?graph { ?concept <${SKOS}inScheme> $about } }`),
    `  <${FORWARD_PROPERTY}> a owl:ObjectProperty ; rdfs:label "Of concept or collection" ;`,
    `    rdfs:domain [ owl:unionOf ( skos:Concept skos:Collection ) ] ; rdfs:range skos:ConceptScheme ;`,
    `    ldh:view <${FORWARD_VIEW}> .`,
    ...view(FORWARD_VIEW, 'Union domain fixture', FORWARD_QUERY,
        `SELECT DISTINCT ?scheme WHERE { GRAPH ?graph { $about <${SKOS}inScheme> ?scheme } }`),
    `} WHERE {}`,
].join('\n') });

// the properties, the blank-node class expressions and their lists, the views and their queries
const detach = () => ldh(['patch', packageOntologyDocument], { allowFailure: true, stdin: [
    `PREFIX rdfs: <${RDFS}>`, `PREFIX rdf: <${RDF}>`, `PREFIX owl: <${OWL}>`,
    `DELETE { ?s ?p ?o }`,
    `WHERE {`,
    `  VALUES ?fixture { <${INVERSE_PROPERTY}> <${FORWARD_PROPERTY}> <${INVERSE_VIEW}> <${FORWARD_VIEW}> <${INVERSE_QUERY}> <${FORWARD_QUERY}> }`,
    `  { ?fixture ?p ?o BIND(?fixture AS ?s) }`,
    `  UNION { ?fixture rdfs:domain|rdfs:range ?s . FILTER isBlank(?s) ?s ?p ?o }`,
    `  UNION { ?fixture (rdfs:domain|rdfs:range)/owl:unionOf/rdf:rest* ?s . ?s ?p ?o }`,
    `}`,
].join('\n') });

test.describe('a view of a property with a union domain or range', { tag: '@owner' }, () => {
    // The declaration is the fixture's, and which views a type gets does not depend on who is reading.
    const owner = testInfo => testInfo.project.name === 'owner';
    test.beforeEach(async ({}, testInfo) => {
        test.skip(!owner(testInfo), 'which views a type gets is the same for either agent');
    });
    test.beforeAll(async ({}, testInfo) => {
        if (!owner(testInfo)) return;
        await attach();
        await clearOntologies();
    });
    test.afterAll(async ({}, testInfo) => {
        if (!owner(testInfo)) return;
        await detach();
        await clearOntologies();
    });

    test("an inverse view shows on the page of a class in the property's range", async ({ page }) => {
        await goto(page, conceptPage(scheme));
        await settled(page);

        await expect(viewBlock(page, INVERSE_PROPERTY)).toHaveCount(1);
        await expect(viewBlock(page, FORWARD_PROPERTY)).toHaveCount(0);
    });

    test("a view shows on the page of a class in the property's domain", async ({ page }) => {
        await goto(page, conceptPage('coffee'));
        await settled(page);

        await expect(viewBlock(page, FORWARD_PROPERTY)).toHaveCount(1);
        await expect(viewBlock(page, INVERSE_PROPERTY)).toHaveCount(0);
    });
});
