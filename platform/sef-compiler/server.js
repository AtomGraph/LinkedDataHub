/**
 * SEF compiler service.
 *
 * Saxon-JS refuses to compile XSLT in the browser (SaxonJS.compile() is gated on inBrowser()
 * and throws SXJS0006), and independently compiled per-package SEFs cannot compose, because
 * xsl:import precedence is resolved at compile time. So a dataspace that imports packages
 * needs its client stylesheet composed and compiled server-side, per import set.
 *
 * This runs out-of-process rather than inside the platform container because the compile peaks
 * around 1.5 GB of resident memory - measured 1,495,990,272 bytes for client.xsl - which would
 * be fatal next to a Tomcat heap sized at 75% of a 2 GB limit.
 *
 * The service is stateless: the caller sends the package modules inline, and the static tree
 * this image was built from supplies client.xsl and everything it imports. That tree arrives by
 * COPY --from the same Maven stage the WAR comes from, so the modules compiled here are the
 * deployed bytes by construction - no mount, no volume, and no way to drift.
 */

import { createServer } from 'node:http';
import { execFile } from 'node:child_process';
import { gzip } from 'node:zlib';
import { writeFile, unlink, readFile, access } from 'node:fs/promises';
import { join } from 'node:path';

const PORT = Number(process.env.PORT ?? 8080);
// the directory client.xsl lives in: the wrapper is written beside it so that -relocate:on
// records every module's base URI the same way the build's own SEF does
const XSL_DIR = process.env.XSL_DIR ?? '/static/com/atomgraph/linkeddatahub/xsl';
const TIMEOUT_MS = Number(process.env.COMPILE_TIMEOUT_MS ?? 120_000);
const MAX_OLD_SPACE_MB = Number(process.env.COMPILE_MAX_OLD_SPACE_MB ?? 2560);
const MAX_BODY_BYTES = Number(process.env.MAX_BODY_BYTES ?? 8 * 1024 * 1024);

const WRAPPER = 'ldh-composed.xsl';
const OUTPUT = 'ldh-composed.sef.json';

// One compile at a time. Two concurrent 1.5 GB compiles is the OOM this service exists to avoid,
// so a second request is refused rather than queued - the caller already serialises per key.
let busy = false;

const gzipAsync = (buf) => new Promise((resolve, reject) =>
    gzip(buf, (err, out) => err ? reject(err) : resolve(out)));

/** Composes the wrapper: client.xsl first, then each package, so packages take higher precedence. */
function wrapper(names)
{
    const imports = ['client.xsl', ...names].
        map((href) => `    <xsl:import href="${href}"/>`).
        join('\n');

    return `<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
${imports}
</xsl:stylesheet>
`;
}

function readBody(req)
{
    return new Promise((resolve, reject) =>
    {
        const chunks = [];
        let size = 0;

        req.on('data', (chunk) =>
        {
            size += chunk.length;
            if (size > MAX_BODY_BYTES)
            {
                reject(Object.assign(new Error('Request body too large'), { statusCode: 413 }));
                req.destroy();
                return;
            }
            chunks.push(chunk);
        });
        req.on('end', () => resolve(Buffer.concat(chunks)));
        req.on('error', reject);
    });
}

/** Package module names are used as filenames, so they must not escape the xsl directory. */
function validName(name)
{
    return typeof name === 'string' && /^[A-Za-z0-9._-]+\.xsl$/.test(name) && !name.startsWith('.');
}

function compile()
{
    return new Promise((resolve) =>
    {
        execFile('xslt3-he',
            [
                `-xsl:${join(XSL_DIR, WRAPPER)}`,
                `-export:${join(XSL_DIR, OUTPUT)}`,
                '-nogo',
                '-ns:##html5',
                '-relocate:on'
            ],
            {
                timeout: TIMEOUT_MS,
                maxBuffer: 4 * 1024 * 1024,
                env: { ...process.env, NODE_OPTIONS: `--max-old-space-size=${MAX_OLD_SPACE_MB}` }
            },
            (error, stdout, stderr) => resolve({ error, stdout, stderr }));
    });
}

async function handleCompile(req, res)
{
    if (busy)
    {
        res.writeHead(503, { 'content-type': 'application/json', 'retry-after': '30' });
        res.end(JSON.stringify({ error: 'A compilation is already in progress' }));
        return;
    }

    let body;
    try
    {
        body = JSON.parse((await readBody(req)).toString('utf-8'));
    }
    catch (ex)
    {
        res.writeHead(ex.statusCode ?? 400, { 'content-type': 'application/json' });
        res.end(JSON.stringify({ error: `Malformed request: ${ex.message}` }));
        return;
    }

    const imports = Array.isArray(body?.imports) ? body.imports : null;
    if (!imports || !imports.every((imp) => validName(imp?.name) && typeof imp?.content === 'string'))
    {
        res.writeHead(400, { 'content-type': 'application/json' });
        res.end(JSON.stringify({ error: 'Expected { imports: [ { name: "<name>.xsl", content: "..." } ] }' }));
        return;
    }

    busy = true;
    const written = [];
    try
    {
        for (const imp of imports)
        {
            const path = join(XSL_DIR, imp.name);
            await writeFile(path, imp.content, 'utf-8');
            written.push(path);
        }

        const wrapperPath = join(XSL_DIR, WRAPPER);
        await writeFile(wrapperPath, wrapper(imports.map((imp) => imp.name)), 'utf-8');
        written.push(wrapperPath);

        const started = Date.now();
        const { error, stderr } = await compile();
        const outputPath = join(XSL_DIR, OUTPUT);

        // xslt3-he reports compilation errors on stdout/stderr and may still exit 0, so the
        // export's existence is the real success test
        let exported = true;
        try { await access(outputPath); } catch { exported = false; }

        if (error || !exported)
        {
            const detail = (stderr || '').trim() || error?.message || 'Compilation produced no output';
            console.error(`compile failed after ${Date.now() - started}ms: ${detail}`);
            res.writeHead(422, { 'content-type': 'application/json' });
            res.end(JSON.stringify({ error: detail }));
            return;
        }

        written.push(outputPath);
        const sef = await readFile(outputPath);
        console.log(`compiled ${imports.length} package module(s) in ${Date.now() - started}ms, ${sef.length} bytes`);

        // 19 MB down to under 1 MB; the caller is on the same network but this is still worth it
        const accepts = (req.headers['accept-encoding'] ?? '').includes('gzip');
        const payload = accepts ? await gzipAsync(sef) : sef;

        res.writeHead(200, {
            'content-type': 'application/json',
            'content-length': String(payload.length),
            ...(accepts ? { 'content-encoding': 'gzip' } : {})
        });
        res.end(payload);
    }
    catch (ex)
    {
        console.error(`compile error: ${ex.stack ?? ex}`);
        res.writeHead(500, { 'content-type': 'application/json' });
        res.end(JSON.stringify({ error: String(ex.message ?? ex) }));
    }
    finally
    {
        // the static tree is this container's private copy, but a leftover wrapper would be
        // picked up by the next compile, so the directory is always returned to its built state
        await Promise.all(written.map((path) => unlink(path).catch(() => {})));
        busy = false;
    }
}

const server = createServer((req, res) =>
{
    if (req.method === 'GET' && req.url === '/health')
    {
        res.writeHead(busy ? 503 : 200, { 'content-type': 'application/json' });
        res.end(JSON.stringify({ status: busy ? 'busy' : 'ready' }));
        return;
    }

    if (req.method === 'POST' && req.url === '/compile')
    {
        handleCompile(req, res);
        return;
    }

    res.writeHead(404, { 'content-type': 'application/json' });
    res.end(JSON.stringify({ error: 'Not found' }));
});

server.headersTimeout = TIMEOUT_MS + 30_000;
server.requestTimeout = TIMEOUT_MS + 30_000;
server.listen(PORT, () => console.log(`SEF compiler listening on ${PORT}, stylesheets at ${XSL_DIR}`));
