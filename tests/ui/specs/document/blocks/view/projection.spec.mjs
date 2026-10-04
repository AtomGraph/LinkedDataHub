// What a view does with the first variable its query projects.
//
// A view lists the resources its query's first variable binds: it wraps the SELECT in a DESCRIBE
// of that variable, and counts it for the pager. The variable may be projected plain, ?resource,
// or as an expression's alias, (?s AS ?resource) - SPARQL.js gives the two in different shapes,
// and reading only the plain one left the name empty and the whole block failing to render. An
// alias is as good a variable as any. What a view cannot show is a first variable that binds
// values rather than resources, (YEAR(NOW()) AS ?year): the count finds rows where the DESCRIBE
// finds nothing, and the block says so, rather than claim that nothing matched.
import { randomUUID } from 'node:crypto';
import { mkdtempSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { test, expect } from '../../../../lib/console.mjs';
import { goto } from '../../../../lib/settle.mjs';
import { ldh } from '../../../../lib/fixtures.mjs';
import { endUserBase } from '../../../../lib/stack.mjs';
import { listTitles } from '../../../../lib/view.mjs';

const scratch = { container: null };

async function addView(name, query) {
    const file = join(mkdtempSync(join(tmpdir(), 'ui-tests-')), `${name}.rq`);
    writeFileSync(file, query);
    await ldh(['add', 'select', '--title', `${name} query`, '--uri', `#${name}-query`, '--query-file', file, scratch.container]);
    await ldh(['add', 'view', '--title', `${name} view`, '--uri', `#${name}-view`, '--query', `${scratch.container}#${name}-query`, scratch.container]);
    // a view is a resource of the document; an object block is what places it among the document's blocks
    await ldh(['add', 'object-block', '--title', `${name} block`, '--uri', `#${name}-block`, '--value', `${scratch.container}#${name}-view`, scratch.container]);
}

const viewOf = (page, name) => page.locator(`div.block.ldh-block[about="${scratch.container}#${name}-view"]`);

test.describe('a view and its first projected variable', { tag: '@owner' }, () => {
    test.beforeEach(async ({}, testInfo) => {
        test.skip(testInfo.project.name !== 'owner', 'the queries and their results are the same for either agent');
        scratch.container = (await ldh(['create', 'container', '--parent', endUserBase, '--title', 'View projection spec',
            '--slug', `view-projection-${randomUUID().slice(0, 8)}`])).stdout;
        for (const title of ['Projection alpha', 'Projection beta'])
            await ldh(['create', 'item', '--container', scratch.container, '--title', title, '--slug', title.toLowerCase().replace(' ', '-')]);
    });

    test.afterEach(async () => {
        if (scratch.container) await ldh(['delete', scratch.container], { allowFailure: true });
    });

    test('an aliased variable lists the resources it binds', async ({ page }) => {
        await addView('aliased', 'SELECT (?item AS ?resource) WHERE { GRAPH ?item { ?item <http://rdfs.org/sioc/ns#has_container> $this } }');
        await goto(page, scratch.container);

        const view = viewOf(page, 'aliased');
        await expect(listTitles(view)).toHaveText(['Projection alpha', 'Projection beta'], { useInnerText: true, timeout: 30_000 });
        await expect(view.locator('.ldh-block-error')).toHaveCount(0);
    });

    test('a computed value is said not to be resources, and nothing matched is still said as before', async ({ page }) => {
        await addView('computed', 'SELECT (YEAR(NOW()) AS ?year) WHERE { }');
        await addView('nothing', 'SELECT ?resource WHERE { GRAPH ?g { ?resource a <urn:nothing> } }');
        await goto(page, scratch.container);

        // rows, but no resources: the block says so in its results region, and still renders around it
        const computed = viewOf(page, 'computed');
        await expect(computed.locator('.container-results .ldh-block-error')).toContainText('lists no resources', { timeout: 30_000 });

        // no rows: the ordinary empty state, not the new message
        const nothing = viewOf(page, 'nothing');
        await expect(nothing.locator('.container-results')).toBeVisible({ timeout: 30_000 });
        await expect(nothing.locator('.ldh-block-error')).toHaveCount(0);
    });
});
