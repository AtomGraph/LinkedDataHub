// The verdict on measure.mjs's page loads.
//
// Under the limits, a page load must lose nothing to them:
//   · no request answered 429, no request whose every attempt was, no failure alert painted - the
//     limits size a page's burst as something to queue, and a 429 a visitor's page meets is a regression;
//   · it settles about as fast as an exempt load of the same page: the summed per-page medians, limited
//     over exempt, at most MAX_SETTLE_RATIO, and no one page's at more than MAX_PAGE_SETTLE_RATIO - the
//     sum alone dilutes one slow page among quick ones. Both are measured in the same run, alternating,
//     so the runner's speed cancels out - an absolute time would flap with whichever runner the job got;
//   · it sends no more requests than the committed baseline allows (REQUEST_MARGIN): a page that grows
//     its requests is what eventually outgrows the burst, and the baseline makes the growth a reviewed
//     change. A page well under its baseline passes with a note, so the baseline can be brought down.
//     Counted without the requests refused, so it is the page's own demand, not the limiter's retries.
//
// Absolute settle times are reported, never asserted.
//
// UPDATE_BASELINE=1 writes the measured request counts to the baseline instead of comparing them.
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';

const OUT_DIR = process.env.OUT_DIR ?? '/out';
const BASELINE = process.env.BASELINE ?? new URL('./baseline.json', import.meta.url).pathname;
const MAX_SETTLE_RATIO = Number(process.env.MAX_SETTLE_RATIO ?? 1.3);
const MAX_PAGE_SETTLE_RATIO = Number(process.env.MAX_PAGE_SETTLE_RATIO ?? 1.5);
const REQUEST_MARGIN = Number(process.env.REQUEST_MARGIN ?? 0.1);

const results = JSON.parse(readFileSync(join(OUT_DIR, 'page-load.json'), 'utf8'));
const baseline = existsSync(BASELINE) ? JSON.parse(readFileSync(BASELINE, 'utf8')) : {};

const median = values => {
    const sorted = [...values].sort((a, b) => a - b);
    const mid = Math.floor(sorted.length / 2);
    return sorted.length % 2 ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2;
};
const sum = values => values.reduce((a, b) => a + b, 0);
const seconds = ms => `${(ms / 1000).toFixed(1)} s`;
// baseline keys are paths, so the file does not depend on the host the stack answers to
const pathOf = url => new URL(url).pathname + new URL(url).search;

const failures = [];
const notes = [];
const rows = [];
const measured = {};
let exemptTotal = 0, limitedTotal = 0;

for (const [url, { exempt, limited }] of Object.entries(results.pages)) {
    const path = pathOf(url);
    const refused = sum(limited.map(l => l.refused));
    const lost = sum(limited.map(l => l.lost)) + sum(exempt.map(e => e.lost));
    const painted = sum(limited.map(l => l.failures)) + sum(exempt.map(e => e.failures));
    const timedOut = [...exempt, ...limited].filter(l => l.timedOut).length;
    const requests = Math.ceil(median(limited.map(l => l.requests - l.refused)));
    const exemptSettle = median(exempt.map(e => e.settleMs));
    const limitedSettle = median(limited.map(l => l.settleMs));
    exemptTotal += exemptSettle;
    limitedTotal += limitedSettle;
    measured[path] = requests;
    const pageRatio = limitedSettle / exemptSettle;

    console.log(`DEBUG ${path}: requests ${limited.map(l => l.requests).join(',')} (baseline ${baseline[path] ?? 'none'}), `
        + `refused ${refused}, lost ${lost}, failures ${painted}, `
        + `settle exempt ${exempt.map(e => e.settleMs).join(',')} ms, limited ${limited.map(l => l.settleMs).join(',')} ms`);

    if (refused > 0) failures.push(`${path}: ${refused} requests answered 429 under the limits`);
    if (lost > 0) failures.push(`${path}: ${lost} requests never got past a 429: `
        + [...exempt, ...limited].flatMap(l => l.lostRequests).join(' | '));
    if (painted > 0) failures.push(`${path}: ${painted} failure alerts painted`);
    if (timedOut > 0) failures.push(`${path}: ${timedOut} loads did not settle within the load timeout`);
    if (pageRatio > MAX_PAGE_SETTLE_RATIO) {
        failures.push(`${path}: limited loads settle ${pageRatio.toFixed(2)}x as long as exempt ones (max ${MAX_PAGE_SETTLE_RATIO})`);
    }

    if (!process.env.UPDATE_BASELINE) {
        if (baseline[path] === undefined) {
            failures.push(`${path}: no baseline - measured ${requests} requests; run with UPDATE_BASELINE=1 to record it`);
        } else if (requests > baseline[path] * (1 + REQUEST_MARGIN)) {
            failures.push(`${path}: ${requests} requests, baseline ${baseline[path]} (+${Math.round(REQUEST_MARGIN * 100)}% allowed)`);
        } else if (requests < baseline[path] * (1 - REQUEST_MARGIN)) {
            notes.push(`${path}: ${requests} requests, well under the baseline of ${baseline[path]} - consider lowering it`);
        }
    }

    rows.push(`| \`${path}\` | ${requests} | ${baseline[path] ?? '-'} | ${refused} | ${lost} | ${seconds(exemptSettle)} | ${seconds(limitedSettle)} | ${pageRatio.toFixed(2)} |`);
}

const ratio = limitedTotal / exemptTotal;
console.log(`DEBUG settle: exempt ${exemptTotal} ms, limited ${limitedTotal} ms, ratio ${ratio.toFixed(2)} (max ${MAX_SETTLE_RATIO})`);
if (ratio > MAX_SETTLE_RATIO) {
    failures.push(`limited loads settle ${ratio.toFixed(2)}x as long as exempt ones (max ${MAX_SETTLE_RATIO})`);
}

if (process.env.UPDATE_BASELINE) {
    writeFileSync(BASELINE, JSON.stringify(measured, null, 4) + '\n');
    notes.push(`baseline written to ${BASELINE}`);
}

const report = [
    `### Page load under the rate limits`,
    ``,
    `Median of ${results.loads} loads per page, each a fresh visitor; exempt and limited loads alternate.`,
    ``,
    `| page | requests | baseline | 429s | lost | settle, exempt | settle, limited | ratio |`,
    `|---|---|---|---|---|---|---|---|`,
    ...rows,
    `| **all** | | | | | ${seconds(exemptTotal)} | ${seconds(limitedTotal)} | **${ratio.toFixed(2)}** |`,
    ``,
    ...notes.map(n => `- ${n}`),
    ...failures.map(f => `- **FAIL**: ${f}`),
    ``,
].join('\n');
writeFileSync(join(OUT_DIR, 'page-load.md'), report);
console.log(report);

for (const f of failures) console.error(`FAIL: ${f}`);
process.exit(failures.length > 0 ? 1 : 0);
