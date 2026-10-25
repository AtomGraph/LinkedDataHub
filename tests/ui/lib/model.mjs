// Three classes the dataspace's own namespace ontology is taught for one spec, each describing how
// a new instance's form is built and what it is refused for:
//
//   - spin:  a SPIN constructor templates the fields and a SPIN constraint requires one of them
//   - shacl: a SHACL node shape does both - its property shapes are the fields, sh:minCount the rule
//   - both:  a constructor and a shape on the same class, each bringing a field and a rule of its own
//
// The three are the matrix the form code folds over (ldh:merge-constructors): SPIN alone, SHACL alone,
// and the two merged. The middle one is the case that broke - a class with a shape and no constructor
// has a SPIN side nonetheless, a typing-only instance, and the merge once left it beside the shape's
// prototype as a second resource of the class.
//
// Seeded into the admin dataspace's namespace document with ldh, like every other fixture, except the
// shapes: the CLI has no `admin add shape`, so those are appended as Turtle with `ldh post` - the same
// POST the admin UI's Node shape form sends. The ontology cache is cleared after seeding and after
// teardown, since the closure is what the forms are built from and it is cached per ontology URI.
import { mkdtempSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { ldh } from './fixtures.mjs';
import { adminBase, endUserBase } from './stack.mjs';

export const FOAF_NAME = 'http://xmlns.com/foaf/0.1/name';
export const RDFS_COMMENT = 'http://www.w3.org/2000/01/rdf-schema#comment';
const XSD_STRING = 'http://www.w3.org/2001/XMLSchema#string';
const SH = 'http://www.w3.org/ns/shacl#';

const ns = `${endUserBase}ns#`;
export const namespaceOntology = ns;
export const namespaceDocument = `${adminBase}ontologies/namespace/`;

// One entry per case: the class, the label the type lookup finds it by, the properties its form has
// to offer, and which of them a save is refused without. Pure data, so a spec can be a loop over it.
export const model = {
    spin: {
        uri: `${ns}UiSpinThing`,
        label: 'UI SPIN thing',
        fields: [FOAF_NAME, RDFS_COMMENT],
        required: [FOAF_NAME],
    },
    shacl: {
        uri: `${ns}UiShaclThing`,
        label: 'UI SHACL thing',
        fields: [FOAF_NAME, RDFS_COMMENT],
        required: [FOAF_NAME],
    },
    both: {
        uri: `${ns}UiBothThing`,
        label: 'UI SPIN and SHACL thing',
        // the comment is the constructor's, the name the shape's
        fields: [RDFS_COMMENT, FOAF_NAME],
        // ... and each side requires its own: the SPIN constraint the comment, sh:minCount the name
        required: [RDFS_COMMENT, FOAF_NAME],
    },
};

const term = local => `${ns}${local}`;

const constructorText = properties => `PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>

CONSTRUCT {
${properties.map(p => `  $this <${p}> [ a xsd:string ] .`).join('\n')}
}
WHERE {}`;

async function addConstructor(uri, label, properties) {
    const file = join(mkdtempSync(join(tmpdir(), 'ui-model-')), 'construct.rq');
    writeFileSync(file, constructorText(properties));
    await ldh(['admin', 'add', 'constructor', '--uri', uri, '--label', label, '--query-file', file, namespaceDocument]);
}

// A node shape targeting the class, with one property shape per field. The required ones carry
// sh:minCount 1; every one names sh:datatype, because a property shape that states no range renders
// as a resource lookup rather than a text field (ldh:Shape mode defaults to rdfs:Resource).
const shapeTurtle = (classUri, local, fields, required) => {
    const node = term(`${local}Shape`);
    const lines = [`<${node}> a <${SH}NodeShape> ; <http://www.w3.org/2000/01/rdf-schema#label> "${local} shape" ; <${SH}targetClass> <${classUri}> .`];
    for (const [i, property] of fields.entries()) {
        const shape = term(`${local}Shape-${i + 1}`);
        lines.push(`<${node}> <${SH}property> <${shape}> .`);
        lines.push(`<${shape}> a <${SH}PropertyShape> ; <${SH}path> <${property}> ; <${SH}datatype> <${XSD_STRING}> ; <${SH}name> "${property.split(/[#/]/).pop()}"${required.includes(property) ? ` ; <${SH}minCount> 1` : ''} .`);
    }
    return lines.join('\n');
};

async function appendShapes(classUri, local, fields, required) {
    const file = join(mkdtempSync(join(tmpdir(), 'ui-model-')), 'shapes.ttl');
    writeFileSync(file, shapeTurtle(classUri, local, fields, required));
    await ldh(['post', '-t', 'text/turtle', namespaceDocument, file]);
}

export async function seedModel() {
    // spin: constructor templates both fields, the constraint requires the name
    await addConstructor(term('UiSpinThingConstructor'), 'UI SPIN thing constructor', model.spin.fields);
    await ldh(['admin', 'add', 'property-constraint', '--uri', term('UiSpinThingMissingName'),
        '--label', 'UI SPIN thing: missing name', '--property', FOAF_NAME, namespaceDocument]);
    await ldh(['admin', 'add', 'class', '--uri', model.spin.uri, '--label', model.spin.label,
        '--constructor', term('UiSpinThingConstructor'), '--constraint', term('UiSpinThingMissingName'), namespaceDocument]);

    // shacl: the class and the shape, nothing else - no constructor, no SPIN constraint
    await ldh(['admin', 'add', 'class', '--uri', model.shacl.uri, '--label', model.shacl.label, namespaceDocument]);
    await appendShapes(model.shacl.uri, 'UiShaclThing', model.shacl.fields, model.shacl.required);

    // both: the constructor brings the comment and the constraint on it; the shape brings the name
    await addConstructor(term('UiBothThingConstructor'), 'UI SPIN and SHACL thing constructor', [RDFS_COMMENT]);
    await ldh(['admin', 'add', 'property-constraint', '--uri', term('UiBothThingMissingComment'),
        '--label', 'UI SPIN and SHACL thing: missing comment', '--property', RDFS_COMMENT, namespaceDocument]);
    await ldh(['admin', 'add', 'class', '--uri', model.both.uri, '--label', model.both.label,
        '--constructor', term('UiBothThingConstructor'), '--constraint', term('UiBothThingMissingComment'), namespaceDocument]);
    await appendShapes(model.both.uri, 'UiBothThing', [FOAF_NAME], [FOAF_NAME]);

    await ldh(['admin', 'clear', 'ontology', adminBase]);
}

// Everything seeded above is a resource of the namespace document whose URI starts with the ns#Ui
// prefix, so one DELETE takes the lot - classes, constructors, constraints and shapes alike.
export async function teardownModel() {
    await ldh(['patch', namespaceDocument], {
        allowFailure: true,
        stdin: `DELETE { ?s ?p ?o } WHERE { ?s ?p ?o . FILTER(STRSTARTS(STR(?s), "${ns}Ui")) }`,
    });
    await ldh(['admin', 'clear', 'ontology', adminBase], { allowFailure: true });
}
