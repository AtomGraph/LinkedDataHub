// A SPARQL endpoint the page reaches, answered in the browser.
//
// The service fixture (lib/fixtures.mjs, `service`) names serviceEndpoint, an address nothing serves.
// The client sends a query to an endpoint of another origin through the Linked Data proxy -
// ldh:href() rewrites it to `?uri=<endpoint>` on the page's own origin - so the request leaves the
// browser same-origin, and page.route() answers it before it reaches the platform. The suite stays
// off the network, and what the page shows can only have come from here: none of these values is in
// the dataspace.
//
// The answer is picked by the query's form, the way an endpoint would: a SELECT gets result-set XML,
// a DESCRIBE or CONSTRUCT gets RDF/XML. Every query is recorded, so a spec can say the block went to
// this service and not to the dataspace's own.
import { serviceEndpoint } from './fixtures.mjs';

const DCT = 'http://purl.org/dc/terms/';

export const things = [
    { uri: 'https://remote.example/things/1', title: 'Remote thing one', kind: 'remote-alpha' },
    { uri: 'https://remote.example/things/2', title: 'Remote thing two', kind: 'remote-alpha' },
    { uri: 'https://remote.example/things/3', title: 'Remote thing three', kind: 'remote-beta' },
];

// How many things there are of each kind, in the order the chart query sorts them.
export const kindCounts = [...new Set(things.map(t => t.kind))].sort()
    .map(kind => ({ kind, count: things.filter(t => t.kind === kind).length }));

const escape = s => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');

const uri = value => `<uri>${escape(value)}</uri>`;
const literal = value => `<literal>${escape(value)}</literal>`;
const integer = value => `<literal datatype="http://www.w3.org/2001/XMLSchema#integer">${value}</literal>`;

function results(vars, rows) {
    return '<?xml version="1.0"?>\n<sparql xmlns="http://www.w3.org/2005/sparql-results#"><head>'
        + vars.map(name => `<variable name="${name}"/>`).join('')
        + '</head><results>'
        + rows.map(row => '<result>'
            + Object.entries(row).map(([name, value]) => `<binding name="${name}">${value}</binding>`).join('')
            + '</result>').join('')
        + '</results></sparql>';
}

function describe() {
    return '<?xml version="1.0"?>\n<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" '
        + `xmlns:dct="${DCT}">`
        + things.map(t => `<rdf:Description rdf:about="${escape(t.uri)}">`
            + `<dct:title>${escape(t.title)}</dct:title><dct:description>${escape(t.kind)}</dct:description>`
            + '</rdf:Description>').join('')
        + '</rdf:RDF>';
}

// The query's form, after its prologue.
const form = query => query.replace(/^\s*(PREFIX\s+\S*\s*<[^>]*>|BASE\s*<[^>]*>|#[^\n]*)\s*/gi, '').match(/^\s*(\w+)/)?.[1].toUpperCase();

function answer(query) {
    switch (form(query)) {
        case 'SELECT':
            // The chart's: a count per kind.
            if (/GROUP\s+BY\s+\?kind/i.test(query)) {
                return { contentType: 'application/sparql-results+xml',
                    body: results(['kind', 'things'], kindCounts.map(({ kind, count }) => ({ kind: literal(kind), things: integer(count) }))) };
            }
            return { contentType: 'application/sparql-results+xml',
                body: results(['thing', 'title', 'kind'], things.map(t => ({ thing: uri(t.uri), title: literal(t.title), kind: literal(t.kind) }))) };
        case 'DESCRIBE':
        case 'CONSTRUCT':
            return { contentType: 'application/rdf+xml', body: describe() };
        default:
            return null;
    }
}

const isServiceRequest = url => new URL(url).searchParams.get('uri') === serviceEndpoint;

// Answers the service's endpoint on this page, and returns the queries it was sent, in order. A query
// of a form it has no answer for is recorded and answered 501, so a spec sees it instead of a hang.
export async function mockService(page) {
    const queries = [];
    await page.route(isServiceRequest, route => {
        const request = route.request();
        const query = request.method() === 'POST'
            ? (/x-www-form-urlencoded/.test(request.headers()['content-type'] ?? '')
                ? new URLSearchParams(request.postData() ?? '').get('query')
                : request.postData())
            : new URL(request.url()).searchParams.get('query');
        queries.push(query ?? '');
        const response = query ? answer(query) : null;
        return response
            ? route.fulfill({ status: 200, ...response })
            : route.fulfill({ status: 501, contentType: 'text/plain', body: `No mock answer for: ${query}` });
    });
    return queries;
}
