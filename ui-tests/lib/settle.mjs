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

export async function settled(page, { selector = BLOCKS, quietFor = 400, timeout = 20_000 } = {}) {
    await page.waitForLoadState('domcontentloaded');

    const deadline = Date.now() + timeout;
    let previous = -1;
    while (Date.now() < deadline) {
        const count = await page.locator(selector).count();
        if (count === previous && count > 0) return count;
        previous = count;
        await page.waitForTimeout(quietFor);
    }
    // Falling through is not an error: a page may legitimately hold no blocks at all.
    return page.locator(selector).count();
}

// Navigate and wait for hydration in one step, since no spec wants the un-hydrated shell.
export async function goto(page, url, options) {
    const response = await page.goto(url, { waitUntil: 'domcontentloaded', ...options });
    await settled(page);
    return response;
}
