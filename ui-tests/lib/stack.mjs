// Where the stack is, and how to authenticate against it.
//
// Environment variable names mirror http-tests/run.sh, so the two suites can be
// pointed at the same instance with one set of exports.
import { readFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { join } from 'node:path';

export const repoRoot = fileURLToPath(new URL('../..', import.meta.url));

export const endUserBase = process.env.END_USER_BASE_URL ?? 'https://localhost:4443/';
export const adminBase = process.env.ADMIN_BASE_URL ?? 'https://admin.localhost:4443/';
export const endUserEndpoint = process.env.END_USER_ENDPOINT_URL ?? 'http://localhost:3030/end-user';
export const adminEndpoint = process.env.ADMIN_ENDPOINT_URL ?? 'http://localhost:3030/admin';

// ldh reads the PKCS12 keystore; the PEM beside it is what curl -E takes. Playwright
// wants the keystore too, so the suite never touches the PEM.
export const ownerKeystore = process.env.OWNER_CERT_KEYSTORE ?? join(repoRoot, 'ssl/owner/keystore.p12');
const ownerPasswordFile = process.env.OWNER_CERT_PASSWORD_FILE ?? join(repoRoot, 'secrets/owner_cert_password.txt');

// Read, never inline. Every ad-hoc script so far hardcoded this passphrase.
export function ownerPassword() {
    if (process.env.OWNER_CERT_PWD) return process.env.OWNER_CERT_PWD;
    if (!existsSync(ownerPasswordFile)) {
        throw new Error(`No owner certificate password at ${ownerPasswordFile}. `
            + `Run 'make cert' to generate the certificates, or set OWNER_CERT_PWD.`);
    }
    return readFileSync(ownerPasswordFile, 'utf8').trim();
}

// Both origins, always. The end-user page issues XHR against the admin origin while it
// loads, so a context holding only the end-user certificate authenticates half the page.
export function ownerCertificates() {
    const cert = { pfxPath: ownerKeystore, passphrase: ownerPassword() };
    return [
        { origin: new URL(endUserBase).origin, ...cert },
        { origin: new URL(adminBase).origin, ...cert },
    ];
}

// The stock SEF `make sef` produces. Since #383 this is NOT what the browser executes on a
// dataspace that imports a package: the app composes the platform's modules with the package's
// and publishes the result under sefDir, and the page names that file in its bootstrap script.
// The stock SEF still matters, because ClientStylesheetService digests it to derive the composed
// key - so it is the fingerprint the composition is keyed on, not the artifact that runs.
export const sefPath = 'static/com/atomgraph/linkeddatahub/xsl/client.xsl.sef.json';
export const localSef = join(repoRoot, 'target/ROOT', sefPath);

// Where the app writes composed stylesheets, bind-mounted from the host (docker-compose.yml:105).
// One file per distinct (platform build × import set), named by the key the page requests.
export const sefDir = join(repoRoot, 'sef');
// The public prefix of a composed stylesheet, mirroring ClientStylesheetService.PUBLIC_PATH.
export const composedSefPrefix = 'static/xsl/sef/';
