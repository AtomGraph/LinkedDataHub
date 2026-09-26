// Importing an external vocabulary through the admin application's Import ontology dialog.
//
// The dialog takes a vocabulary URI and a document of this application, and the browser runs the
// whole import: it fetches the vocabulary through the same-origin proxy, appends it to the document,
// runs the constructor-deriving CONSTRUCT over that graph on the local endpoint, appends the derived
// constructors beside the vocabulary with a foaf:primaryTopic naming it, clears the ontology cache
// and navigates to the document. The CLI has a second copy of that chain, and the HTTP tests drive
// only the CLI's - which is how the two came to produce different documents for the same action.
// This is the browser half: the document the dialog leaves behind has the same shape the CLI's does.
//
// PROV-O rather than SKOS: it is bundled, so the import runs offline like the rest of the suite,
// and nothing on the instance imports it, so the closure is not reshaped for the specs that follow.
// The document is deleted afterwards and the caches cleared regardless.
import { test, expect } from '../../../lib/console.mjs';
import { goto } from '../../../lib/settle.mjs';
import { ldh } from '../../../lib/fixtures.mjs';
import { adminBase } from '../../../lib/stack.mjs';

const SOURCE = 'http://www.w3.org/ns/prov#';
const OWL = 'http://www.w3.org/2002/07/owl#';
const FOAF = 'http://xmlns.com/foaf/0.1/';
const SPIN = 'http://spinrdf.org/spin#';

const ontologies = `${adminBase}ontologies/`;

// Whether the pattern has a solution in the graph. A SELECT rather than an ASK, because the endpoint
// answers an ASK in result-set shape, with no boolean to read.
async function exists(page, graph, pattern) {
    // The nonce makes each read a different URL, past the endpoint's response cache.
    const query = `SELECT * WHERE { GRAPH <${graph}> { ${pattern} } } LIMIT 1 # ${Date.now()}`;
    const response = await page.request.get(`${adminBase}sparql?query=${encodeURIComponent(query)}`,
        { headers: { Accept: 'application/sparql-results+json' } });
    expect(response.status(), 'the admin endpoint answers the owner').toBe(200);
    return (await response.json()).results.bindings.length === 1;
}

test.describe('the Import ontology dialog', { tag: '@owner' }, () => {
    let target;

    test.beforeEach(async ({}, testInfo) => {
        test.skip(testInfo.project.name !== 'owner',
            'the ontologies container is owner-owned, and importing is a write');

        // The document the vocabulary goes into, created ahead like the CLI test does: the dialog
        // imports into a document that exists, it does not mint one.
        const created = await ldh(['create', 'item', '-b', adminBase,
            '--container', ontologies, '--title', 'UI test vocabulary',
            '--slug', `ui-import-${testInfo.testId.replace(/[^a-z0-9]/gi, '')}`]);
        target = created.stdout;
    });

    test.afterEach(async () => {
        if (target) await ldh(['delete', target], { allowFailure: true });
        // The import cleared the caches on the way through, and the deletion has to as well, or
        // the closure keeps serving the vocabulary from a document that is gone.
        await ldh(['admin', 'clear', 'ontology', '-b', adminBase], { allowFailure: true });
    });

    test('leaves the vocabulary, its derived constructors and a primary topic in the document', async ({ page }) => {
        await goto(page, ontologies);

        // The item replaces "Generate containers" in the Actions menu on the admin app's
        // containers, which is where an ontology document is created.
        // The export menu is a drop-toggle in the same bar; the Actions menu is the one holding the item.
        await page.locator('div.ldh-of-wrap:has(button.btn-add-ontology) button.drop-toggle').click();
        await page.locator('button.btn-add-ontology').click();

        const modal = page.locator('#add-data');
        await expect(modal).toBeVisible();
        await modal.locator('#remote-rdf-source').fill(SOURCE);
        // The Graph field opens committed to the document the dialog was opened on, as a chip whose
        // edit button gives the combobox back. The combobox only helps find a URI: a spec that knows
        // the document fills it, as view-create does. Not left at the default: that would append the
        // vocabulary to the ontologies CONTAINER, which is what the first run of this spec did.
        const graphField = modal.locator('div.ldh-prop-group:has(input[name="pu"][value="http://www.w3.org/ns/sparql-service-description#name"])');
        await graphField.locator('span.ac-cb-chip button').click();
        await graphField.locator('input[name="ou"][type="text"]').fill(target);
        await modal.locator('form#form-clone-data button.btn-save').click();

        // Five requests deep - fetch, append, fetch the query, construct, append - then the clear,
        // then the navigation. The dialog going is the sign the chain ran to its end.
        await expect(modal).toHaveCount(0, { timeout: 90_000 });
        await expect(page, 'the page navigates to the document it imported into')
            .toHaveURL(new RegExp(`^${target.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}`), { timeout: 30_000 });

        // The document's shape, as the CLI test pins it: the vocabulary with its own header, one
        // derived constructor at least, a primary topic naming the vocabulary - and no claim to
        // being an ontology itself, which is the conflation this replaced.
        expect(await exists(page, target, `<${SOURCE}> a <${OWL}Ontology>`), 'the vocabulary header').toBe(true);
        expect(await exists(page, target, `?class <${SPIN}constructor> ?constructor`), 'a derived constructor').toBe(true);
        expect(await exists(page, target, `<${target}> <${FOAF}primaryTopic> <${SOURCE}>`), 'the primary topic').toBe(true);
        expect(await exists(page, target, `<${target}> a <${OWL}Ontology>`), 'the document is not the ontology').toBe(false);
    });
});
