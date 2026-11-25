import { execFileSync } from 'node:child_process';
import { copyFileSync, mkdtempSync, readFileSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { Generator, Parser } from '../index.js';

// Runs client/query-transforms.xsl on Saxon-JS, the engine the browser runs it on, over queries parsed by the
// Traqula bundle the browser uses. The stylesheets declare their namespace IRIs as DTD entities, which the
// Saxon-JS compiler does not expand (the Maven build expands them before compiling the SEF), so they are expanded
// here into a staging directory along with harness.xsl, and the harness is compiled from there once.

const require = createRequire(import.meta.url);
const SaxonJS = require('saxonjs-he');

const here = dirname(fileURLToPath(import.meta.url));
const xsl = join(here, '../../../webapp/static/com/atomgraph/linkeddatahub/xsl');

// the functions query-transforms.xsl calls from imports/default.xsl, which as a whole is the platform's library
const BORROWED = [ 'ldh:typed-term-node', 'ldh:triple-node' ];

// a stylesheet with its internal DTD entities expanded and the DOCTYPE dropped
function expandEntities(source) {
  const entities = new Map();
  for (const [, name, value] of source.matchAll(/<!ENTITY\s+(\S+)\s+"([^"]*)"\s*>/g)) entities.set(name, value);
  return source.replace(/<!DOCTYPE[^[]*\[[\s\S]*?\]>/, '')
    .replace(/&([A-Za-z][\w.-]*);/g, (ref, name) => entities.has(name) ? entities.get(name) : ref);
}

function borrowed() {
  const library = expandEntities(readFileSync(join(xsl, 'imports/default.xsl'), 'utf8'));
  const functions = BORROWED.map(name => {
    const match = library.match(new RegExp(`<xsl:function name="${name}"[\\s\\S]*?</xsl:function>`));
    if (!match) throw new Error(`${name} not found in imports/default.xsl`);
    return match[0];
  });
  return `<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:map="http://www.w3.org/2005/xpath-functions/map" xmlns:json="http://www.w3.org/2005/xpath-functions" xmlns:ldh="https://w3id.org/atomgraph/linkeddatahub#" exclude-result-prefixes="#all">\n${functions.join('\n')}\n</xsl:stylesheet>\n`;
}

export function compile() {
  const dir = mkdtempSync(join(tmpdir(), 'ldh-query-transforms-'));
  writeFileSync(join(dir, 'query-transforms.xsl'), expandEntities(readFileSync(join(xsl, 'client/query-transforms.xsl'), 'utf8')));
  writeFileSync(join(dir, 'borrowed.xsl'), borrowed());
  copyFileSync(join(here, 'harness.xsl'), join(dir, 'harness.xsl'));

  const sef = join(dir, 'harness.sef.json');
  execFileSync(process.execPath, [ require.resolve('xslt3-he/xslt3.js'), `-xsl:${join(dir, 'harness.xsl')}`, `-export:${sef}`, '-nogo' ], { stdio: 'pipe' });
  return sef;
}

const strip = (key, value) => key === 'loc' ? undefined : value;

export const parse = query => JSON.parse(JSON.stringify(new Parser().parse(query), strip));

// the query generated from an AST, on one line
export const generate = ast => new Generator().generate(ast).replace(/\s+/g, ' ').trim();

// the result of a rewrite, as JSON: an AST for a mode, an array of results for a function ('fn:name')
export function run(sef, op, query, params = {}) {
  const result = SaxonJS.transform({
    stylesheetFileName: sef,
    initialTemplate: 'main',
    stylesheetParams: { op, query: JSON.stringify(typeof query === 'string' ? parse(query) : query), params: JSON.stringify(params) },
    destination: 'serialized'
  }, 'sync');
  return JSON.parse(result.principalResult);
}
