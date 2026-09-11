// A probe, not a test. It measures what the running instance actually serves so the
// assertions in lib/ds.mjs are written against reality rather than against the READMEs
// alone. Delete it once its findings are folded in.
import { test } from '@playwright/test';
import { fixtures } from '../lib/fixtures.mjs';
import { settled } from '../lib/settle.mjs';
import { endUserBase } from '../lib/stack.mjs';

const pages = [
    ['root', endUserBase],
    ['fixture container', fixtures.container],
    ['fixture item', `${fixtures.container}item-01/`],
];

// Seeded from the DS READMEs and the commits that retired each one. Every hit is either a
// real finding to report or an entry that does not belong on the list.
const banned = {
    '.ldh-btn': '.ldh-btn',
    '.ldh-icon-btn': '.ldh-icon-btn',
    '.tb / .rb': '.tb, .rb',
    '.ldh-nblock': '.ldh-nblock',
    'block [data-depth]': '.block[data-depth], .ldh-block[data-depth]',
    '.ldh-results-table': '.ldh-results-table',
    '.minput': '.minput',
    'bare .close': '.close',
    'role on native table': 'table[role], tr[role], td[role], th[role]',
    'orphan tab roles': '[role=tablist]:not(:has(~ [role=tabpanel])) [role=tab]:not([aria-controls])',
    'grid card edit pin': '.pin-edit',
    'EditMode href in card': '.card a[href*="EditMode"], a.card[href*="EditMode"]',
    'html5 semantics': 'article, aside, section, header, footer, nav, main',
};

const anatomy = {
    'block rows': '.ldh-block-row',
    '  > .row-main': '.ldh-block-row > .row-main',
    '  > .row-main > .block.ldh-block': '.ldh-block-row > .row-main > .block.ldh-block',
    'blocks': '.block.ldh-block',
    'block heads': '.ldh-block-head',
    'block bodies (main.ldh-block-body)': 'main.ldh-block-body',
    'block bodies (any element)': '.ldh-block-body',
    'type chips': '.ldh-type-chip',
    'ac-btn': '.ac-btn',
    'ac-iconbtn': '.ac-iconbtn',
    'buttons total': 'button',
    'dl.ldh-prop-form': 'dl.ldh-prop-form',
    'div.ldh-prop-group': 'div.ldh-prop-group',
    'dt.label': 'dt.label',
    'dd.ldh-prop-row': 'dd.ldh-prop-row',
    'table.ac-table': 'table.ac-table',
    'table > caption': 'table > caption',
    'table > colgroup': 'table > colgroup',
    'ac-backdrop': '.ac-backdrop',
    'ac-modal': '.ac-modal',
    'sidebar': '.ldh-sidebar',
    'action bar': '.ldh-actionbar',
    'mode switcher': '.ldh-mode',
    'view toolbar': '.ldh-view-toolbar',
    'pager': '.ldh-pager',
    'facets': '.facet',
};

for (const [label, url] of pages) {
    test(`probe: ${label}`, async ({ page }, testInfo) => {
        const noise = [];
        page.on('console', m => m.type() === 'error' && noise.push(`console.error: ${m.text()}`));
        page.on('pageerror', e => noise.push(`pageerror: ${e.message}`));
        page.on('dialog', async d => { noise.push(`dialog: ${d.message()}`); await d.dismiss(); });
        page.on('response', r => r.status() >= 400 && noise.push(`HTTP ${r.status()}: ${decodeURIComponent(r.url())}`));

        const report = [`=== [${testInfo.project.name}] ${label} -> ${url}`];
        const response = await page.goto(url, { waitUntil: 'domcontentloaded' }).catch(e => ({ error: e }));
        if (response?.error) {
            report.push(`  navigation failed: ${response.error.message}`);
            console.log(report.join('\n'));
            return;
        }
        report.push(`  HTTP ${response.status()}  content-type ${response.headers()['content-type']}`);
        await settled(page);

        report.push(`  title "${await page.title()}"`);
        report.push(`  html  data-retro="${await page.locator('html').getAttribute('data-retro')}"`
            + ` data-theme="${await page.locator('html').getAttribute('data-theme')}"`);

        report.push('  -- anatomy --');
        for (const [name, selector] of Object.entries(anatomy)) {
            const count = await page.locator(selector).count();
            if (count) report.push(`    ${String(count).padStart(4)}  ${name}`);
        }

        report.push('  -- banned patterns present --');
        let clean = true;
        for (const [name, selector] of Object.entries(banned)) {
            const count = await page.locator(selector).count().catch(() => -1);
            if (count > 0) {
                clean = false;
                const sample = await page.locator(selector).first().evaluate(
                    el => `<${el.tagName.toLowerCase()} class="${el.className}">`).catch(() => '?');
                report.push(`    ${String(count).padStart(4)}  ${name}   eg ${sample}`);
            }
            if (count < 0) report.push(`      ??  ${name}   (selector not supported)`);
        }
        if (clean) report.push('    none');

        report.push('  -- page noise --');
        report.push(noise.length ? noise.map(n => `    ${n}`).join('\n') : '    none');

        console.log(report.join('\n'));
    });
}
