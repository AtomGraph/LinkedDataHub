// The taxonomy package's concept tree, and the reveal that opens it where you are.
//
// The tree roots at the concept SCHEME rather than at the document's own topic, so on a
// concept page it has to open the path down to that concept or the reader is left at the
// top of a taxonomy with no idea where they are. That path is asked for one hop at a time
// and the descent then expands one level per request, which makes every assertion here a
// statement about a finished asynchronous walk - hence auto-retrying expect() throughout
// rather than a settle-then-count.
import { test, expect } from '../../../lib/console.mjs';
import { goto } from '../../../lib/settle.mjs';
import { addBroader, concept, document, labelOf, scheme } from '../../../lib/taxonomy.mjs';
import { CONTENT_MODE, EDIT_MODE, READ_MODE, inMode } from '../../../lib/mode.mjs';
import { disclosureOf, linkOf, rowFor } from '../../../lib/tree.mjs';

const pageFor = (name, mode = READ_MODE) => inMode(document(name), mode);

// Every row links into ReadMode explicitly, rather than to the concept's bare URI: the tree
// only renders in ReadMode, so a row pointing at a concept document that has content blocks -
// which resolves to ContentMode by default - would be a link out of the tree itself.
const rowHref = name => `${pageFor(name)}#this`;

const tree = page => page.locator('ul.concept-tree');
const rootRow = page => tree(page).locator('> li > div.tree-row');
const rowsFor = (page, name) => rowFor(tree(page), rowHref(name));
const linkFor = (page, name) => linkOf(rowsFor(page, name));
const disclosureFor = (page, name) => disclosureOf(rowsFor(page, name));

// Every concept-tree fetch, counted: the hops up are a SELECT for ?parent, the levels down
// are the shared CONSTRUCT of a node's children.
//
// The down pattern matches the projection, not the verb: the verb stopped being distinctive
// when the children query became a CONSTRUCT, and CONSTRUCT alone would also count whatever
// else the page constructs. Matching what only this query projects is also what keeps the
// counter honest - while it matched nothing, `the DOM is the cache` compared 0 against 0 and
// passed without asserting anything.
function countQueries(page) {
    const counts = { up: 0, down: 0 };
    page.on('response', response => {
        const url = decodeURIComponent(response.url());
        if (!url.includes('/sparql?')) return;
        if (/SELECT DISTINCT \?parent WHERE/.test(url)) counts.up++;
        else if (/CONSTRUCT \{ \?child a \?Type/.test(url)) counts.down++;
    });
    return counts;
}

test.describe('concept tree', { tag: '@owner' }, () => {
    // Not ownership: nothing in a dataspace is readable without a certificate until an
    // authorization says so, and a taxonomy document is a dh:Item like any other - granting the
    // fixtures would make these run. The reason not to is the division of labour. WHETHER a
    // refusal happens is http-tests' subject, where admin/acl/ covers the modes, the classes, the
    // groups and make-public; asserting it again through a browser is the same claim in a slower
    // runner. WHAT a refusal does to the client is this suite's, and has its own spec in
    // tree-children-failure, which injects one and runs in both projects. Between those two the
    // tree renders from the hierarchy queries alone, identically for either agent, so a granted
    // taxonomy would buy fifteen re-measurements of the same markup.
    test.beforeEach(({}, testInfo) => {
        test.skip(testInfo.project.name !== 'owner',
            'the tree renders identically for either agent; whether a refusal happens is http-tests\' subject');
    });

    test('roots at the scheme, not at the concept being read', async ({ page }) => {
        await goto(page, pageFor('espresso'));

        // Three hops below the scheme, and the root is still the scheme.
        await expect(rootRow(page).locator('a')).toHaveAttribute('href', rowHref(scheme));
        await expect(rootRow(page)).toContainText(labelOf(scheme));
    });

    test('links every row into ReadMode, server-rendered root and fetched child alike', async ({ page }) => {
        await goto(page, pageFor('espresso'));

        // The root is in the server's first paint and everything below it is rendered by the
        // client out of a children fetch. The two have to agree, or navigating down the tree
        // lands in whatever mode the document defaults to and the tree disappears.
        await expect(rootRow(page).locator('a')).toHaveAttribute('href', rowHref(scheme));
        await expect(linkFor(page, 'coffee'))
            .toHaveAttribute('href', rowHref('coffee'));

        // The row still states the concept's own URI, which is what its href no longer is.
        await expect(linkFor(page, 'coffee'))
            .toHaveAttribute('title', concept('coffee'));
    });

    test('opens the path down to the concept being read', async ({ page }) => {
        const queries = countQueries(page);
        await goto(page, pageFor('espresso'));

        for (const name of [scheme, 'hot-drinks', 'coffee']) {
            await expect(disclosureFor(page, name)).toHaveAttribute('aria-expanded', 'true');
        }
        await expect(rowsFor(page, 'espresso')).toHaveClass(/is-active/);
        await expect(linkFor(page, 'espresso'))
            .toHaveAttribute('aria-current', 'page');

        // Present, and left alone: revealing a path is not expanding a taxonomy.
        await expect(rowsFor(page, 'cold-drinks')).toHaveCount(1);
        for (const name of ['cold-drinks', 'tea']) {
            await expect(disclosureFor(page, name)).toHaveAttribute('aria-expanded', 'false');
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
        await expect(disclosureFor(page, scheme)).toHaveAttribute('aria-expanded', 'true');
        await expect(rowsFor(page, 'hot-drinks')).toHaveClass(/is-active/);
        expect(queries.up).toBe(1);
    });

    test('opens a concept reached only through the link its parent asserts', async ({ page }) => {
        await goto(page, pageFor('juice'));

        // juice asserts no broader: cold-drinks names it as narrower, in cold-drinks' own
        // graph, which is why every hop is scoped to a GRAPH and unions both directions.
        await expect(disclosureFor(page, 'cold-drinks')).toHaveAttribute('aria-expanded', 'true');
        await expect(rowsFor(page, 'juice')).toHaveClass(/is-active/);
    });

    test('roots a scheme document at itself and climbs not at all', async ({ page }) => {
        const queries = countQueries(page);
        await goto(page, pageFor(scheme));

        await expect(rootRow(page).locator('a')).toHaveAttribute('href', rowHref(scheme));
        await expect(tree(page).locator('li:has(> div.tree-row)')).toHaveCount(1);
        await expect(disclosureFor(page, scheme)).toHaveAttribute('aria-expanded', 'false');
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
            expect(new Set(parents)).toEqual(new Set([rowHref('coffee'), rowHref('hot-drinks')]));

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
        const coffee = disclosureFor(page, 'coffee');
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

    test('survives client-side navigation', async ({ page }) => {
        await goto(page, pageFor('espresso'));
        await expect(rowsFor(page, 'espresso')).toHaveClass(/is-active/);

        // The first paint is the server's, composed with the package. A click re-renders the
        // body in the browser out of whichever SEF the page bootstrapped: if that is the stock
        // one, the column and every package rule go with the first navigation, and only a
        // reload brings them back.
        await linkFor(page, 'coffee').click();
        await expect(page).toHaveURL(rowHref('coffee'));

        await expect(tree(page)).toHaveCount(1);
        await expect(rowsFor(page, 'coffee')).toHaveClass(/is-active/);
        await expect(linkFor(page, 'coffee'))
            .toHaveAttribute('aria-current', 'page');
    });

    for (const [name, mode] of [['EditMode', EDIT_MODE], ['ContentMode', CONTENT_MODE]]) {
        test(`renders no tree in ${name}`, async ({ page }) => {
            await goto(page, pageFor('espresso', mode));

            // The tree is a reading aid. A document being edited, or laid out as content,
            // has its own claim on the column.
            await expect(tree(page)).toHaveCount(0);
        });
    }
});
