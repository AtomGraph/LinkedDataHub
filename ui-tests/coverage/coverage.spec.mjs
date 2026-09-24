// Which UI components the suite covers, which it has never touched, and which it cannot yet see.
//
// This is a report with three assertions guarding it, not a test of the product: a component with
// no spec must never fail the build - it is the report's subject. The three that DO fail are all
// about the tooling's own integrity, and each fires only on a mistake its author just made.
//
// It replaces specs/calibration.spec.mjs, whose header asked to be deleted once its findings were
// folded in. Both of its tables survive here: the anatomy counts became the `Renders on` column,
// and the retired-class list is printed below the report - printed, not asserted, because
// promoting it to a gate is a scope decision rather than something a restructure grants itself.
//
// `test` comes from @playwright/test rather than lib/console.mjs, for the reason calibration did
// the same: it walks pages that may legitimately answer 403, and the noise guard would fail the
// report for measuring them.
import { test, expect } from '@playwright/test';
import { existsSync, mkdirSync, readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { components, axes } from './components.mjs';
import { endUserBase, repoRoot } from '../lib/stack.mjs';
import { fixtures, itemUri } from '../lib/fixtures.mjs';
import { document as conceptDocument } from '../lib/taxonomy.mjs';
import { settled } from '../lib/settle.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const specsDir = join(here, '..', 'specs');
const outDir = join(here, '..', 'out');
const xslBase = join(repoRoot, 'src/main/webapp/static/com/atomgraph/linkeddatahub/xsl');

const READ_MODE = 'https://w3id.org/atomgraph/client#ReadMode';
// Self-contained, so the probe measures the page rather than the state of the store.
const probeQuery = 'SELECT ?s ?label WHERE { VALUES (?s ?label) { (<https://example.org/coverage-probe> "Coverage probe") } }';

// One page per rendering path the platform has: the dataspace root, a container (blocks, views,
// a chart, prose), an item (the statement grid), a concept in ReadMode (the package's column and
// its ontology-defined views) and a result set asked for as a document.
const probePages = [
    ['root', endUserBase],
    ['container', fixtures.container],
    ['item', itemUri(1)],
    ['concept', `${conceptDocument('coffee')}?mode=${encodeURIComponent(READ_MODE)}`],
    ['results', `${endUserBase}sparql?query=${encodeURIComponent(probeQuery)}`],
];

// Retired anatomy, inherited verbatim from calibration.spec.mjs. Every hit is either a real
// finding to report or an entry that no longer belongs on the list.
const retired = {
    '.ldh-btn': '.ldh-btn',
    '.ldh-icon-btn': '.ldh-icon-btn',
    '.tb / .rb': '.tb, .rb',
    '.ldh-nblock': '.ldh-nblock',
    'block [data-depth]': '.block[data-depth], .ldh-block[data-depth]',
    '.ldh-results-table': '.ldh-results-table',
    '.minput': '.minput',
    'bare .close': '.close',
    'role on native table': 'table[role], tr[role], td[role], th[role]',
    'grid card edit pin': '.pin-edit',
    'EditMode href in card': '.card a[href*="EditMode"], a.card[href*="EditMode"]',
    'html5 semantics': 'article, aside, section, header, footer, nav, main',
};

// State and variant tokens, which are not components and would drown the undeclared list.
const MODIFIER = /^(ldh|ac)-(is|has|va|sz|pos|sd)-/;

function flatten(nodes, parent = '') {
    return nodes.flatMap(node => {
        const path = parent ? `${parent}/${node.id}` : node.id;
        const depth = path.split('/').length - 1;
        return [{ ...node, path, depth }, ...flatten(node.children ?? [], path)];
    });
}

const declared = flatten(components);
const byPath = new Map(declared.map(component => [component.path, component]));

const specFiles = readdirSync(specsDir, { recursive: true })
    .map(entry => String(entry).split('\\').join('/'))
    .filter(entry => entry.endsWith('.spec.mjs'));

const specFolders = [...new Set(specFiles.map(file => dirname(file)).filter(dir => dir !== '.'))]
    // Every ancestor too: a folder that only nests others is still a claim about the tree.
    .flatMap(dir => dir.split('/').map((_, index, parts) => parts.slice(0, index + 1).join('/')));

// Rule 2 of the tree: a component's specs live in its folder, and a leaf component with one spec
// may BE that file. So a spec belongs to the component its stem names, and otherwise to the
// component its folder names.
function componentOf(file) {
    const stem = file.replace(/\.spec\.mjs$/, '');
    if (byPath.has(stem)) return stem;
    const dir = dirname(file);
    return byPath.has(dir) ? dir : null;
}

const specsByComponent = new Map();
const unassigned = [];
for (const file of specFiles) {
    if (axes.includes(file.split('/')[0])) continue;
    const path = componentOf(file);
    if (!path) { unassigned.push(file); continue; }
    specsByComponent.set(path, [...(specsByComponent.get(path) ?? []), file]);
}

test('every folder under specs/ is a declared component', () => {
    const orphans = [...new Set(specFolders)].filter(dir =>
        !byPath.has(dir) && !axes.includes(dir.split('/')[0]));
    expect(orphans, 'a spec folder names a component the inventory does not declare - add the '
        + 'record to coverage/components.mjs, or file the spec under an existing component').toEqual([]);
    expect(unassigned, 'a spec sits where no component claims it').toEqual([]);
});

test('the inventory is well formed', () => {
    const paths = declared.map(component => component.path);
    expect(paths, 'two components share a path').toEqual([...new Set(paths)]);

    const missing = declared
        .map(component => ({ path: component.path, xsl: component.xsl }))
        .filter(({ xsl }) => !existsSync(xsl.startsWith('packages/') ? join(repoRoot, xsl) : join(xslBase, xsl)));
    // A class styled in app.css and emitted by nothing is not a component, and this is what says so.
    expect(missing, 'a component names an XSL module that does not exist').toEqual([]);
});

test('no spec imports the inventory', () => {
    const importers = specFiles.filter(file =>
        /from\s+['"][^'"]*coverage\//.test(readFileSync(join(specsDir, file), 'utf8')));
    expect(importers, 'the inventory holds presence probes, not assertion locators - a spec that '
        + 'imports one has found a selector too specific to be declared here').toEqual([]);
});

test('reports what is covered, what is a gap, and what has never been seen', async ({ page }, testInfo) => {
    const counts = new Map(declared.map(component => [component.path, {}]));
    const undeclared = new Map();
    const retiredHits = [];
    const visited = [];

    for (const [label, url] of probePages) {
        const response = await page.goto(url, { waitUntil: 'domcontentloaded' }).catch(error => ({ error }));
        if (response?.error) { visited.push(`${label}: navigation failed - ${response.error.message}`); continue; }
        await settled(page).catch(() => {});
        visited.push(`${label}: HTTP ${response.status()} ${url}`);

        for (const component of declared) {
            if (component.appears === 'gesture') continue;
            const count = await page.locator(component.selector).count();
            if (count) counts.get(component.path)[label] = count;
        }

        for (const [name, selector] of Object.entries(retired)) {
            const count = await page.locator(selector).count().catch(() => 0);
            if (count) retiredHits.push(`${String(count).padStart(4)}  ${name}  (${label})`);
        }

        // What the page renders that nothing here claims. The inventory is hand-written, so this
        // is how it learns about a component that shipped without one.
        const tokens = await page.evaluate(() => {
            const seen = {};
            for (const element of document.querySelectorAll('[class]'))
                for (const token of element.classList)
                    if (/^(ldh|ac)-/.test(token)) seen[token] = (seen[token] ?? 0) + 1;
            return seen;
        });
        for (const [token, count] of Object.entries(tokens)) {
            if (MODIFIER.test(token)) continue;
            if (declared.some(component => component.selector.includes(`.${token}`))) continue;
            undeclared.set(token, (undeclared.get(token) ?? 0) + count);
        }
    }

    const statusOf = component => {
        if (specsByComponent.has(component.path)) return 'covered';
        const below = declared.some(other =>
            other.path.startsWith(`${component.path}/`) && specsByComponent.has(other.path));
        if (below) return 'covered-below';
        // A modal cannot be counted on a page load, so its declaration is what stands in for one.
        if (component.appears === 'gesture') return 'GAP';
        return Object.keys(counts.get(component.path)).length ? 'GAP' : 'unprobed';
    };

    const rows = declared.map(component => {
        const renders = Object.entries(counts.get(component.path))
            .map(([label, count]) => `${label}×${count}`).join(' ');
        return `| ${'&nbsp;'.repeat(component.depth * 4)}${component.name} | \`${component.path}\` `
            + `| ${component.owner ?? 'platform'}${component.base === 'admin' ? ' · admin' : ''} `
            + `| \`${component.xsl}\` | ${(specsByComponent.get(component.path) ?? []).join('<br>') || '—'} `
            + `| ${component.appears === 'gesture' ? '—' : renders || '—'} | ${statusOf(component)} |`;
    });

    const tally = declared.reduce((counts, component) => {
        const status = statusOf(component);
        return { ...counts, [status]: (counts[status] ?? 0) + 1 };
    }, {});

    const report = [
        '# UI component coverage',
        '',
        `${declared.length} declared components · `
        + Object.entries(tally).map(([status, count]) => `${count} ${status}`).join(' · '),
        '',
        '`covered` a spec in its own folder · `covered-below` only a descendant has one · '
        + '`GAP` it renders and nothing asserts it · `unprobed` it renders on no probe page, so '
        + 'coverage is unknowable until a fixture shows it.',
        '',
        '| Component | Path | Owner | XSL | Specs | Renders on | Status |',
        '| --- | --- | --- | --- | --- | --- | --- |',
        ...rows,
        '',
        '## Probe pages',
        '',
        ...visited.map(line => `- ${line}`),
        '',
        '## Retired anatomy still rendered',
        '',
        retiredHits.length ? '```\n' + retiredHits.join('\n') + '\n```' : 'None.',
        '',
        '## Undeclared anatomy',
        '',
        'Class tokens the probe pages render that no component claims. Each is either a component '
        + 'missing from the inventory or a modifier the filter should learn.',
        '',
        undeclared.size
            ? '```\n' + [...undeclared].sort((a, b) => b[1] - a[1]).slice(0, 40)
                .map(([token, count]) => `${String(count).padStart(5)}  .${token}`).join('\n') + '\n```'
            : 'None.',
        '',
    ].join('\n');

    mkdirSync(outDir, { recursive: true });
    writeFileSync(join(outDir, 'coverage.md'), report);
    await testInfo.attach('coverage', { body: report, contentType: 'text/markdown' });

    console.log(`\n${declared.length} declared components · `
        + Object.entries(tally).map(([status, count]) => `${count} ${status}`).join(' · ')
        + `\nout/coverage.md`);
});
