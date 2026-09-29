// The document tree survives a children query that never lands.
//
// It did not. An anonymous reader of a readable document whose endpoint is NOT readable got a
// modal alert() carrying raw Saxon text - "Required cardinality of first argument of
// ac:document-uri() is exactly one; supplied value is empty" - and that was the DEFAULT anonymous
// experience of any instance nobody had made public, root document included.
//
// The failure is a descent walking a row that is not a child. ldh:TreeChildrenPlaceholder appends
// an <li class="tree-loading"> carrying no anchor at all (client/tree.xsl), to be replaced when the
// children response lands. On a non-200 ldh:tree-children-response only emits a message - it
// neither replaces the placeholder nor stops the chain - and ldh:tree-children-continue invokes the
// continuation regardless, so ldh:doctree-descend-after-load ran its predicate over a list whose
// only row had no @href. ac:document-uri() of that empty sequence is a cardinality error, and
// ldh:promise-failure alerts anything that is not an ldh:HTTPError.
//
// ldh:tree-node-uri had already been made empty-tolerant for exactly this reason and says so in its
// comment; the descent never adopted the guard. So this asserts the invariant rather than the fix:
// a tree that is told nothing about its children must not raise, whatever the reason it was told
// nothing.
//
// And it must not be left half-working. The loading row used to spin for the rest of the session,
// because the failure branch only logged. The drawer is navigation, which degrades rather than
// reports: a tree whose children cannot be read cannot be used, so its section is removed - which is
// what the second half of each test asserts. (A tree in the content keeps an inline error row.)
//
// Injected rather than seeded. The condition is a refused children query, and the suite grants the
// endpoint to everyone - which is why no spec here could have caught this. Routing the query to a
// 403 reproduces it for either project without touching an authorization, and keeps the spec
// honest about what it is testing: not "anonymous", but "the children never arrived".
import { test, expect } from '../../../../lib/console.mjs';
import { goto } from '../../../../lib/settle.mjs';
import { fixtures, itemTitle, itemUri } from '../../../../lib/fixtures.mjs';

// The query the tree asks for one node's children, as ldh:TreeChildrenFetch sends it.
//
// It routes on the wire form, so it has to track the query's shape: this matched DESCRIBE
// until the children query became a bounded CONSTRUCT, and a route pattern that matches
// nothing fails open - the 403 below is never injected and every assertion here passes
// against a tree that was never refused anything.
const CHILDREN_QUERY = /\/sparql\?query=CONSTRUCT[\s\S]*has_parent/i;

// What the server really answers when the endpoint is refused: an http:Response whose subject is a
// blank node. Served verbatim so the client meets the body it would meet in production, not an
// empty one that might take a different path.
const FORBIDDEN = `<http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
[] a <http://www.w3.org/2011/http#Response> ;
   <http://purl.org/dc/terms/title> "Access not authorized for request URI" ;
   <http://www.w3.org/2011/http#statusCodeValue> "403"^^<http://www.w3.org/2001/XMLSchema#long> .`;

test('the tree survives a children query it is refused', async ({ page, allowNoise }) => {
    // The injection is the point of the test, so its own noise is declared rather than tolerated
    // globally - anything else 4xx on this page is still a failure.
    allowNoise.push({ pattern: CHILDREN_QUERY, reason: 'this spec refuses the children query on purpose' });
    allowNoise.push({
        pattern: /console\.error: Failed to load resource.*403/i,
        reason: 'the browser logs the injected 403 the route fulfils',
    });

    await page.route(CHILDREN_QUERY, route => route.fulfill({
        status: 403,
        contentType: 'text/turtle',
        body: FORBIDDEN,
    }));

    // An item rather than the root: the descent has somewhere to go, so the placeholder is appended
    // and the continuation runs - which is the code path that raised.
    await goto(page, itemUri(1));

    // No assertion needed for the alert itself: lib/console.mjs fails any test whose page raised a
    // dialog, and that is exactly what the defect did. What is asserted here is that the page is
    // still standing afterwards - a descent that died silently would otherwise satisfy "no alert".
    await expect(page.locator('body')).toContainText(itemTitle(1));
    // Counted, not seen: the tree lives in a drawer that opens at clientX exactly 0, and the descent -
    // the code that raised - runs whether it is open or not. Opening the drawer would add a moving part
    // this spec has no claim about. The refused children leave nothing to navigate, so the section goes,
    // and no alert takes its place.
    await expect(page.locator('.ldh-sidebar .document-tree')).toHaveCount(0);
    await expect(page.locator('.ldh-sidebar .ldh-failure, .ldh-sidebar .tree-error')).toHaveCount(0);
});

test('the root document survives it too', async ({ page, allowNoise }) => {
    allowNoise.push({ pattern: CHILDREN_QUERY, reason: 'this spec refuses the children query on purpose' });
    allowNoise.push({
        pattern: /console\.error: Failed to load resource.*403/i,
        reason: 'the browser logs the injected 403 the route fulfils',
    });

    await page.route(CHILDREN_QUERY, route => route.fulfill({
        status: 403,
        contentType: 'text/turtle',
        body: FORBIDDEN,
    }));

    // Where an unauthorized visitor actually lands, and where the alert was first seen.
    await goto(page, fixtures.container);

    await expect(page.locator('body')).toContainText('UI test fixtures');
    // the container is a child of the root, so the descent opens the root and is refused the same way
    await expect(page.locator('.ldh-sidebar .document-tree')).toHaveCount(0);
    await expect(page.locator('.ldh-sidebar li.tree-loading')).toHaveCount(0);
});
