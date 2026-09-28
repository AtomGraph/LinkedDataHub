// The block card itself - the shell every kind of block is rendered into, and the one control
// that shell owns. What a particular kind puts inside it belongs to that kind's own helpers
// (lib/view.mjs for the ontology-defined view), not here.

// The block an element is rendered inside.
//
// The class is matched as a TOKEN, the way contains-token() does in the stylesheet. A substring
// test lands on `.ldh-block-head`, the wrapper a header button sits in, which holds no bands and
// no body - so `[contains(@class, 'ldh-block')]` resolves the toggle's own chrome rather than the
// card it drives.
export const blockOf = locator => locator.locator(
    'xpath=ancestor::div[contains(concat(" ", normalize-space(@class), " "), " ldh-block ")][1]');

// The card header's control toggle. A block draws its control bands collapsed and this is the
// single affordance that clears them, so a spec that needs a facet, a sort, a pivot or the view
// mode switcher presses this first.
export const controlToggle = block => block.locator('.ldh-block-head .tb-controls');
