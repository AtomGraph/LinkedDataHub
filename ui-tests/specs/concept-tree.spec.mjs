// The taxonomy package's concept tree, and the reveal that opens it where you are.
//
// The tree roots at the concept SCHEME rather than at the document's own topic, so on a
// concept page it has to open the path down to that concept or the reader is left at the
// top of a taxonomy with no idea where they are. That path is asked for one hop at a time
// and the descent then expands one level per request, which makes every assertion here a
// statement about a finished asynchronous walk - hence auto-retrying expect() throughout
// rather than a settle-then-count.
import { test, expect } from '../lib/console.mjs';
import { goto } from '../lib/settle.mjs';
import { addBroader, concept, document, labelOf, scheme } from '../lib/taxonomy.mjs';

const READ_MODE = 'https://w3id.org/atomgraph/client#ReadMode';
const pageFor = (name, mode = READ_MODE) =>
    `${document(name)}?mode=${encodeURIComponent(mode)}`;

const tree = page => page.locator('ul.concept-tree');
const rootRow = page => tree(page).locator('> li > div.tree-row');
const rowsFor = (page, name) =>
    tree(page).locator(`li:has(> div.tree-row > a[href="${concept(name)}"])`);
const disclosureOf = (page, name) => rowsFor(page, name).locator('> div.tree-row > button');

// Every concept-tree fetch, counted: the hops up are a SELECT for ?parent, the levels down
// are the shared DESCRIBE of a node's children.
function countQueries(page) {
    const counts = { up: 0, down: 0 };
    page.on('response', response => {
        const url = decodeURIComponent(response.url());
        if (!url.includes('/sparql?')) return;
        if (/SELECT DISTINCT \?parent WHERE/.test(url)) counts.up++;
        else if (/DESCRIBE \?child/.test(url)) counts.down++;
    });
    return counts;
}

test.describe('concept tree', () => {
    // The taxonomy is owner-owned and the tree is navigation, not an authorization
    // surface; the suite's owner/anonymous axis is exercised by the specs that are about it.
    test.beforeEach(({}, testInfo) => {
        test.skip(testInfo.project.name !== 'owner',
            'the taxonomy fixtures are owner-owned; these specs are not about authorization');
    });

    test('roots at the scheme, not at the concept being read', async ({ page }) => {
        await goto(page, pageFor('espresso'));

        // Three hops below the scheme, and the root is still the scheme.
        await expect(rootRow(page).locator('a')).toHaveAttribute('href', concept(scheme));
        await expect(rootRow(page)).toContainText(labelOf(scheme));
    });

    test('opens the path down to the concept being read', async ({ page }) => {
        const queries = countQueries(page);
        await goto(page, pageFor('espresso'));

        for (const name of [scheme, 'hot-drinks', 'coffee']) {
            await expect(disclosureOf(page, name)).toHaveAttribute('aria-expanded', 'true');
        }
        await expect(rowsFor(page, 'espresso')).toHaveClass(/is-active/);
        await expect(rowsFor(page, 'espresso').locator('> div.tree-row > a'))
            .toHaveAttribute('aria-current', 'page');

        // Present, and left alone: revealing a path is not expanding a taxonomy.
        await expect(rowsFor(page, 'cold-drinks')).toHaveCount(1);
        for (const name of ['cold-drinks', 'tea']) {
            await expect(disclosureOf(page, name)).toHaveAttribute('aria-expanded', 'false');
        }

        // One hop per level and one terminating hop that finds nothing new, so the walk
        // stops itself rather than at a depth bound.
        expect(queries.up, 'one hop per ancestor plus the one that ends the climb').toBe(3);
    });

    test('opens a top concept, whose ancestor set is legitimately empty', async ({ page }) => {
        const queries = countQueries(page);
        await goto(page, pageFor('hot-drinks'));

        // A top concept's link to the scheme is topConceptOf, not broader, so the climb
        // returns nothing at all - and the root must still open to reveal it.
        await expect(disclosureOf(page, scheme)).toHaveAttribute('aria-expanded', 'true');
        await expect(rowsFor(page, 'hot-drinks')).toHaveClass(/is-active/);
        expect(queries.up).toBe(1);
    });

    test('opens a concept reached only through the link its parent asserts', async ({ page }) => {
        await goto(page, pageFor('juice'));

        // juice asserts no broader: cold-drinks names it as narrower, in cold-drinks' own
        // graph, which is why every hop is scoped to a GRAPH and unions both directions.
        await expect(disclosureOf(page, 'cold-drinks')).toHaveAttribute('aria-expanded', 'true');
        await expect(rowsFor(page, 'juice')).toHaveClass(/is-active/);
    });

    test('roots a scheme document at itself and climbs not at all', async ({ page }) => {
        const queries = countQueries(page);
        await goto(page, pageFor(scheme));

        await expect(rootRow(page).locator('a')).toHaveAttribute('href', concept(scheme));
        await expect(tree(page).locator('li:has(> div.tree-row)')).toHaveCount(1);
        await expect(disclosureOf(page, scheme)).toHaveAttribute('aria-expanded', 'false');
        expect(queries.up, 'the scheme is already the root').toBe(0);
    });

    test('renders a concept under each of its parents', async ({ page }) => {
        // Latte is reached through coffee's skos:narrower; this adds a second parent from
        // the other end, so the two chains arrive one per direction in a single hop.
        const undo = await addBroader('latte', 'hot-drinks');
        try {
            const queries = countQueries(page);
            await goto(page, pageFor('latte'));

            await expect(rowsFor(page, 'latte')).toHaveCount(2);
            const parents = await rowsFor(page, 'latte').evaluateAll(items => items.map(
                item => item.parentElement.closest('li')?.querySelector(':scope > div.tree-row > a')?.getAttribute('href')));
            expect(new Set(parents)).toEqual(new Set([concept('coffee'), concept('hot-drinks')]));

            // Both occurrences light up: the activation pass iterates every matching row,
            // which is what makes a polyhierarchy need no special case.
            await expect(rowsFor(page, 'latte')).toHaveClass([/is-active/, /is-active/]);
            expect(queries.up, 'both parents arrive in the same hop').toBe(2);
        } finally {
            await undo();
        }
    });

    test('keeps a revealed level in the DOM once it is there', async ({ page }) => {
        const queries = countQueries(page);
        await goto(page, pageFor('espresso'));
        await expect(rowsFor(page, 'espresso')).toHaveClass(/is-active/);

        const revealed = queries.down;
        const coffee = disclosureOf(page, 'coffee');
        await coffee.click();
        await expect(coffee).toHaveAttribute('aria-expanded', 'false');
        await coffee.click();
        await expect(coffee).toHaveAttribute('aria-expanded', 'true');

        await expect(rowsFor(page, 'espresso')).toHaveCount(1);
        expect(queries.down - revealed, 'the DOM is the cache').toBe(0);
    });

    test('appends its nodes in the XHTML namespace', async ({ page }) => {
        await goto(page, pageFor('espresso'));
        await expect(rowsFor(page, 'espresso')).toHaveClass(/is-active/);

        // ixsl:append-content writes into an HTML document, and a node in no namespace
        // would style and serialise as something else entirely.
        const namespaces = await tree(page).evaluate(root =>
            [...new Set([root, ...root.querySelectorAll('*')].map(node => node.namespaceURI))]);
        expect(namespaces).toEqual(['http://www.w3.org/1999/xhtml']);
    });

    for (const mode of ['EditMode', 'ContentMode']) {
        test(`renders no tree in ${mode}`, async ({ page }) => {
            await goto(page, pageFor('espresso', `https://w3id.org/atomgraph/client#${mode}`));

            // The tree is a reading aid. A document being edited, or laid out as content,
            // has its own claim on the column.
            await expect(tree(page)).toHaveCount(0);
        });
    }
});
