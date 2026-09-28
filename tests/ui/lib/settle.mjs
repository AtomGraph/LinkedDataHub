// Waiting for client-side rendering to finish.
//
// The server sends a pre-rendered XHTML shell and Saxon-JS then rebuilds the document in
// place, so "the page loaded" and "the page is what it will be" are different moments.
// Ontology-defined views make it worse: the injection fans out with ixsl:all, one HTTP
// chain per view, each appending on its own resolution - so the block count rises in
// steps rather than once.
//
// Every ad-hoc script solved this with waitForTimeout(4000), which is both slower than it
// needs to be and still occasionally short. Prefer an auto-retrying expect() on whatever
// the spec is about; reach for settled() only when the assertion is about how many things
// there are, where there is no single element to wait for.

const BLOCKS = '.ldh-block-row';

// The shell renders the document's content before Saxon-JS has run its initial template, so a
// gesture can land while no ixsl handler is bound yet - which is indistinguishable from a handler
// that declined to match, and unrecoverable: a click or a mousemove happens once, and no amount of
// retrying on the assertion after it will make it happen again.
//
// window.rdfaEditor, not window.LinkedDataHub: the latter is truthy from the FIRST line of the
// bootstrap, several instructions before the sub-objects it goes on to create, so waiting on it
// lands mid-way through. rdfae:init-state runs last in that template, which makes its container the
// signal that all of it ran.
export async function hydrated(page, { timeout = 30_000 } = {}) {
    await page.waitForFunction(() => !!window.rdfaEditor, null, { timeout });
}

export async function settled(page, { selector = BLOCKS, quietFor = 400, timeout = 20_000 } = {}) {
    await page.waitForLoadState('domcontentloaded');
    // A page that never hydrates is the spec's finding to report, not this helper's to throw on -
    // the coverage probe runs settled() against pages that may well be a 403.
    await hydrated(page, { timeout }).catch(() => {});

    const deadline = Date.now() + timeout;
    let previous = -1;
    while (Date.now() < deadline) {
        const count = await page.locator(selector).count();
        // A stable count of zero is a settled page too. Requiring one block used to stand in for the
        // hydration gate above, at the price of the full timeout on every page that holds no blocks.
        if (count === previous) return count;
        previous = count;
        await page.waitForTimeout(quietFor);
    }
    // Falling through is not an error: the count may still be climbing when the deadline arrives.
    return page.locator(selector).count();
}

// Navigate and wait for hydration in one step, since no spec wants the un-hydrated shell.
export async function goto(page, url, options) {
    const response = await page.goto(url, { waitUntil: 'domcontentloaded', ...options });
    await settled(page);
    return response;
}
