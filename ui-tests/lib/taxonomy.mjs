// A SKOS taxonomy for the concept-tree specs.
//
// Seeded through the API like the rest of the fixtures, and for the same reason: the tree
// is built entirely out of what the hierarchy queries find, so a fixture that went in as a
// TriG would prove the rendering works against data no create path can produce.
//
// The shape is deliberate rather than illustrative. SKOS lets either end of a hierarchy
// link carry it, and the tree has to follow both, so each level here is asserted from a
// different side: coffee names its own broader concept, tea is reached only because hot
// drinks names it as narrower, and the two top concepts arrive one from each direction.
// Depth is deliberate too - espresso sits three hops below the scheme, which is what makes
// the reveal a walk rather than a single lookup.
import { ldh } from './fixtures.mjs';
import { endUserBase } from './stack.mjs';

const slug = 'ui-taxonomy';
const SKOS = 'http://www.w3.org/2004/02/skos/core#';
const FOAF = 'http://xmlns.com/foaf/0.1/';

// The package under test. Without it the tree does not exist at all: the column, the
// hierarchy queries and the reveal are all the package stylesheet's, not the platform's.
export const skosPackage = process.env.UI_TESTS_SKOS_PACKAGE
    ?? 'https://packages.linkeddatahub.com/skos/#this';

export const taxonomy = { container: `${endUserBase}${slug}/` };

export const document = name => `${taxonomy.container}${name}/`;
// A concept is the document's topic, not the document. The tree links to the topic URI,
// which is what every assertion addresses rows by.
export const concept = name => `${document(name)}#this`;

export const scheme = 'drinks';

// asserts: which end carries the link to the parent named beside it.
//   'self'   - the concept names its parent (skos:broader / skos:topConceptOf)
//   'parent' - the parent names the concept (skos:narrower / skos:hasTopConcept)
export const nodes = [
    { name: 'drinks', label: 'Drinks', scheme: true },
    { name: 'hot-drinks', label: 'Hot drinks', parent: scheme, top: true, asserts: 'self' },
    { name: 'cold-drinks', label: 'Cold drinks', parent: scheme, top: true, asserts: 'parent' },
    { name: 'coffee', label: 'Coffee', parent: 'hot-drinks', asserts: 'self' },
    { name: 'tea', label: 'Tea', parent: 'hot-drinks', asserts: 'parent' },
    { name: 'espresso', label: 'Espresso', parent: 'coffee', asserts: 'self' },
    { name: 'latte', label: 'Latte', parent: 'coffee', asserts: 'parent' },
    { name: 'juice', label: 'Juice', parent: 'cold-drinks', asserts: 'parent' },
];

export const labelOf = name => nodes.find(node => node.name === name).label;

// PATCH takes INSERT/WHERE and DELETE WHERE only, so a seeding write is one INSERT with an
// empty pattern rather than INSERT DATA.
const insert = triples => `INSERT {\n${triples.map(t => `  ${t} .`).join('\n')}\n} WHERE {}`;

function patch(uri, triples) {
    return ldh(['patch', uri], { stdin: insert(triples) });
}

// The document's own triples plus its topic's. foaf:primaryTopic is seeded here because
// ldh create does not write one, and without it the page has no topic: the tree reads
// the scheme off the topic's skos:inScheme, so it would render nothing at all.
function ownTriples(node) {
    const self = concept(node.name);
    const triples = [
        `<${document(node.name)}> <${FOAF}primaryTopic> <${self}>`,
        `<${self}> a <${SKOS}${node.scheme ? 'ConceptScheme' : 'Concept'}>`,
        `<${self}> <${SKOS}prefLabel> "${node.label}"@en`,
    ];
    // Every concept needs skos:inScheme in the same write: the package constrains it
    // (:MissingInScheme), so a concept seeded without it is refused with a 422.
    if (!node.scheme) triples.push(`<${self}> <${SKOS}inScheme> <${concept(scheme)}>`);
    if (node.asserts === 'self') {
        triples.push(node.top
            ? `<${self}> <${SKOS}topConceptOf> <${concept(node.parent)}>`
            : `<${self}> <${SKOS}broader> <${concept(node.parent)}>`);
    }
    return triples;
}

// The link the parent carries, written into the PARENT's document because that is the
// graph it belongs to - one concept per document means the two directions live in
// different graphs, which is exactly what the tree's per-hop GRAPH scoping is for.
function parentTriple(node) {
    const relation = node.top ? 'hasTopConcept' : 'narrower';
    return `<${concept(node.parent)}> <${SKOS}${relation}> <${concept(node.name)}>`;
}

async function packageInstalled() {
    const { stdout } = await ldh(['packages', 'list']);
    return stdout.split('\n').some(line => {
        const [state, uri] = line.split('\t');
        return state === 'installed' && uri === skosPackage;
    });
}

// Recorded so teardown puts the application back as it found it: importing a package
// changes how every document in the dataspace renders, which is not the suite's to leave
// behind on an instance that did not have it.
let addedPackage = false;

export async function seedTaxonomy() {
    if (!await packageInstalled()) {
        await ldh(['packages', 'add', '--package', skosPackage]);
        addedPackage = true;
    }

    const container = await ldh(['create', 'container',
        '--parent', endUserBase, '--title', 'UI test taxonomy', '--slug', slug]);
    if (container.stdout !== taxonomy.container) {
        throw new Error(`Expected the container at ${taxonomy.container}, got ${container.stdout}`);
    }

    // Serial, and in declaration order, because a link names a concept that has to exist
    // by the time the constraint checks it.
    for (const node of nodes) {
        await ldh(['create', 'item', '--container', taxonomy.container,
            '--title', node.label, '--slug', node.name]);
        await patch(document(node.name), ownTriples(node));
    }
    for (const node of nodes.filter(n => n.asserts === 'parent')) {
        await patch(document(node.parent), [parentTriple(node)]);
    }

    return { ...taxonomy, addedPackage };
}

// Adds a second parent to one concept, which is the only way to get a polyhierarchy past
// the seeding above: every node there has exactly one. Returns the undo, because a fixture
// that stays polyhierarchical changes what every other spec sees.
export async function addBroader(name, parentName) {
    const triple = `<${concept(name)}> <${SKOS}broader> <${concept(parentName)}>`;
    await patch(document(name), [triple]);
    return () => ldh(['patch', document(name)],
        { stdin: `DELETE WHERE {\n  ${triple} .\n}` , allowFailure: true });
}

export async function teardownTaxonomy() {
    for (const node of nodes) {
        await ldh(['delete', document(node.name)], { allowFailure: true });
    }
    await ldh(['delete', taxonomy.container], { allowFailure: true });
    if (addedPackage) {
        await ldh(['packages', 'remove', '--package', skosPackage], { allowFailure: true });
        addedPackage = false;
    }
}
