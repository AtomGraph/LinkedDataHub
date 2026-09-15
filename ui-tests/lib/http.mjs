// Minimal HTTPS client for the preflight and for fixture assertions.
//
// The dev stack serves a self-signed certificate, so every request here sets
// rejectUnauthorized: false - the same trust decision Playwright makes with
// ignoreHTTPSErrors. No Accept-Encoding is sent, so responses come back identity-coded
// and their bytes can be hashed directly; /static/ is Varnish-cached per encoding, and
// asking for gzip would compare a compressed copy against an uncompressed file.
import { request as httpsRequest } from 'node:https';
import { request as httpRequest } from 'node:http';

export function get(url, { headers = {}, timeout = 15000 } = {}) {
    const target = new URL(url);
    const send = target.protocol === 'https:' ? httpsRequest : httpRequest;
    return new Promise((resolve, reject) => {
        const req = send(target, { method: 'GET', headers, rejectUnauthorized: false, timeout }, res => {
            const chunks = [];
            res.on('data', chunk => chunks.push(chunk));
            res.on('end', () => resolve({
                status: res.statusCode,
                headers: res.headers,
                body: Buffer.concat(chunks),
            }));
        });
        req.on('timeout', () => req.destroy(new Error(`timed out after ${timeout} ms`)));
        req.on('error', reject);
        req.end();
    });
}
