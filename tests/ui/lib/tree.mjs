// The row vocabulary both trees are built from.
//
// The drawer's document tree and the taxonomy package's concept tree are two components - one
// the platform's, rendered in the shell, one the package's, rendered in the document's content
// column - but they are one markup: `li > div.tree-row > a`, a sibling disclosure button, and
// `is-active` on the li of the row being read. So the vocabulary is shared and the tree root is
// a parameter; neither helper knows which tree it is walking.
//
// Every locator here starts its selector at `li`, never chained after a `>`: Playwright resolves
// `locator('> ul > li:has(> div.tree-row)')` to nothing where `'> ul > li'` finds 25. At the
// start of a selector `li:has(> …)` is fine; chained after a `>` it is not.
export const rowFor = (tree, href) => tree.locator(`li:has(> div.tree-row > a[href="${href}"])`);
export const linkOf = row => row.locator('> div.tree-row > a');
export const disclosureOf = row => row.locator('> div.tree-row > button');
