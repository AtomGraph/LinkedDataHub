// Page loads as a visitor sees them, with and without the front door's rate limits.
//
// nginx limits each client address and exempts RFC 1918 ones as the platform's own calls, so a browser
// on the runner - which reaches nginx from the Docker bridge - is never limited, and the UI suite never
// sees the limits at all. This runs in a container attached to two networks: the stack's default one,
// whose addresses nginx exempts, and `loadgen` (100.64.0.0/24), whose addresses it limits like any
// visitor's. The pages are loaded at their public origin, https://localhost:4443/, through a relay on
// the container's own loopback that connects to nginx's address on one network or the other - so the
// two kinds of load differ in nothing but the address nginx counts them against, and they alternate,
// so cache warm-up and the runner's drift fall on both alike.
//
// Each load is a fresh visitor: a new browser context, no HTTP cache, no cookies. It is over when the
// page has had no request in flight and sent none for IDLE_MS. Recorded per load: the page's requests
// to its origin, the ones answered 429, the ones whose every attempt was answered 429 ("lost"), the
// failure alerts the page painted, and the time from navigation until the last response ("settle").
//
// Writes $OUT_DIR/page-load.json; evaluate.mjs holds the verdict.
import { chromium } from 'playwright';
import { lookup } from 'node:dns/promises';
import { createServer, connect, BlockList } from 'node:net';
import { writeFileSync, mkdirSync } from 'node:fs';
import { join } from 'node:path';

const ORIGIN = 'https://localhost:4443';
const PAGES = (process.env.PAGES ?? '').split(/\s+/).filter(Boolean);
const LOADS = Number(process.env.LOADS ?? 5);
const IDLE_MS = Number(process.env.IDLE_MS ?? 2_000);
const LOAD_TIMEOUT_MS = Number(process.env.LOAD_TIMEOUT_MS ?? 120_000);
// before each limited load: the previous one's requests have drained from the limiter's buckets, so
// every limited load is a visitor's first page, not their second within a few seconds
const COOLDOWN_MS = Number(process.env.COOLDOWN_MS ?? 5_000);
const OUT_DIR = process.env.OUT_DIR ?? '/out';
const LOADGEN_SUBNET = process.env.LOADGEN_SUBNET ?? '100.64.0.0/24';
// nginx under a network-scoped alias on each network (docker-compose.load-tests.yml): the container shares
// both, so `nginx` alone would resolve to one address only
const NGINX_EXEMPT = process.env.NGINX_EXEMPT ?? 'nginx-exempt';
const NGINX_LIMITED = process.env.NGINX_LIMITED ?? 'nginx-limited';
const NGINX_PORT = Number(process.env.NGINX_PORT ?? 8443);

if (PAGES.length === 0) throw new Error('PAGES names no page to load');

// nginx's two addresses, checked against the loadgen subnet: an exempt load from a limited address, or the
// other way round, would compare nothing with itself and pass
async function nginxAddresses() {
    const [network, prefix] = LOADGEN_SUBNET.split('/');
    const loadgen = new BlockList();
    loadgen.addSubnet(network, Number(prefix));
    const { address: exempt } = await lookup(NGINX_EXEMPT, { family: 4 });
    const { address: limited } = await lookup(NGINX_LIMITED, { family: 4 });
    if (loadgen.check(exempt) || !loadgen.check(limited)) {
        throw new Error(`${NGINX_EXEMPT} is ${exempt} and ${NGINX_LIMITED} is ${limited}: `
            + `the limited address must be in ${LOADGEN_SUBNET} and the exempt one outside it`);
    }
    return { exempt, limited };
}

// The relay: localhost:4443 to nginx, at whichever address the current load is to come from. TLS passes
// through untouched, so the certificate, SNI and Host are the public origin's.
function relay() {
    const state = { upstream: null };
    const server = createServer(client => {
        const upstream = connect(NGINX_PORT, state.upstream);
        client.pipe(upstream).pipe(client);
        client.on('error', () => upstream.destroy());
        upstream.on('error', () => client.destroy());
    });
    return new Promise(resolve => server.listen(4443, '127.0.0.1', () => resolve({ state, server })));
}

const keyOf = request => `${request.method()} ${request.url()}\n${request.postData() ?? ''}`;
const fromOrigin = url => new URL(url).origin === ORIGIN;

async function load(browser, url) {
    const context = await browser.newContext({ ignoreHTTPSErrors: true, viewport: { width: 1440, height: 900 } });
    const page = await context.newPage();
    const statuses = new Map(); // request key -> every status it was answered with, in order
    let requests = 0, refused = 0, inflight = 0, last = 0, errors = 0;
    const t0 = Date.now();

    page.on('request', request => {
        if (!fromOrigin(request.url())) return;
        requests++;
        inflight++;
        last = Date.now();
    });
    const done = request => {
        if (!fromOrigin(request.url())) return;
        inflight--;
        last = Date.now();
    };
    page.on('requestfinished', done);
    page.on('requestfailed', request => {
        done(request);
        if (fromOrigin(request.url())) statuses.set(keyOf(request), [...(statuses.get(keyOf(request)) ?? []), 0]);
    });
    page.on('response', response => {
        const request = response.request();
        if (!fromOrigin(request.url())) return;
        if (response.status() === 429) refused++;
        statuses.set(keyOf(request), [...(statuses.get(keyOf(request)) ?? []), response.status()]);
    });
    page.on('pageerror', () => errors++);

    await page.goto(url, { waitUntil: 'load', timeout: LOAD_TIMEOUT_MS });
    const deadline = t0 + LOAD_TIMEOUT_MS;
    while (Date.now() < deadline && (inflight > 0 || Date.now() - last < IDLE_MS)) {
        await page.waitForTimeout(250);
    }
    const timedOut = Date.now() >= deadline;

    const lost = [...statuses.entries()].filter(([, s]) => s.includes(429) && s.at(-1) === 429).map(([key]) => key);
    const failures = await page.locator('.ldh-failure').count();
    await context.close();
    return { requests, refused, lost: lost.length, lostRequests: lost, failures, errors, timedOut, settleMs: last - t0 };
}

const { exempt, limited } = await nginxAddresses();
console.log(`nginx: exempt at ${exempt}, limited at ${limited}`);
const { state, server } = await relay();
const browser = await chromium.launch({
    args: ['--host-resolver-rules=MAP localhost 127.0.0.1, MAP *.localhost 127.0.0.1'],
});

const results = { loads: LOADS, idleMs: IDLE_MS, cooldownMs: COOLDOWN_MS, pages: {} };
for (const url of PAGES) results.pages[url] = { exempt: [], limited: [] };

// one discarded load per page: the stack's caches and the platform's JIT start cold for both kinds alike
state.upstream = exempt;
for (const url of PAGES) await load(browser, url);

for (let i = 1; i <= LOADS; i++) {
    for (const url of PAGES) {
        state.upstream = exempt;
        const e = await load(browser, url);
        await new Promise(resolve => setTimeout(resolve, COOLDOWN_MS));
        state.upstream = limited;
        const l = await load(browser, url);
        results.pages[url].exempt.push(e);
        results.pages[url].limited.push(l);
        console.log(`load ${i}/${LOADS} ${url}`);
        console.log(`  exempt  ${e.requests} requests, ${e.refused} refused, ${e.lost} lost, ${e.failures} failures, settled ${e.settleMs} ms`);
        console.log(`  limited ${l.requests} requests, ${l.refused} refused, ${l.lost} lost, ${l.failures} failures, settled ${l.settleMs} ms`);
    }
}

await browser.close();
server.close();
mkdirSync(OUT_DIR, { recursive: true });
writeFileSync(join(OUT_DIR, 'page-load.json'), JSON.stringify(results, null, 2));
