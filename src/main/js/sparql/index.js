import { Parser as TraqulaParser } from '@traqula/parser-sparql-1-1';
import { Generator as TraqulaGenerator } from '@traqula/generator-sparql-1-1';

// The stylesheets read and rewrite Traqula's AST as JSON (json-to-xml / xml-to-json). This shim keeps that AST in
// a shape the stylesheets can compare and edit without knowing Traqula's source-tracking details:
//  - parse() expands prefixed names and BASE-relative IRIs to full IRIs, so a predicate compares as the IRI it is;
//  - parse() flattens blank-node property lists ([ ... ]) and collections (( ... )) into plain triples, and gives
//    every triple a subject and predicate of its own (Traqula marks repeats after ';' and ',' as not printed), so a
//    triple can be matched, moved or appended on its own;
//  - generate() gives every node the source location the generator needs, wraps union branches in groups, and
//    fills the members a query needs (prologue, dataset clause, solution modifiers), so a stylesheet never writes
//    them.

const AUTO = () => ({ sourceLocationType: 'autoGenerate' });

function resolveIri(value, base) {
  if (!base) return value;
  try {
    return new URL(value, base).href;
  } catch {
    return value;
  }
}

function expandIris(node, scope = { prefixes: new Map(), base: undefined }) {
  if (Array.isArray(node)) {
    node.forEach((value) => expandIris(value, scope));
    return node;
  }
  if (!node || typeof node !== 'object') return node;

  let inner = scope;
  if (Array.isArray(node.context) && node.context.length > 0) {
    inner = { prefixes: new Map(scope.prefixes), base: scope.base };
    for (const definition of node.context) {
      if (definition.subType === 'base' && definition.value?.value) {
        inner.base = resolveIri(definition.value.value, inner.base);
      }
      if (definition.subType === 'prefix' && definition.key !== undefined && definition.value?.value) {
        inner.prefixes.set(definition.key, resolveIri(definition.value.value, inner.base));
      }
    }
  }

  if (node.type === 'term' && node.subType === 'namedNode') {
    if (node.prefix !== undefined) {
      const namespace = inner.prefixes.get(node.prefix);
      if (namespace === undefined) throw new Error(`Undefined SPARQL prefix: ${node.prefix}`);
      node.value = namespace + node.value;
      delete node.prefix;
    } else {
      node.value = resolveIri(node.value, inner.base);
    }
  }

  for (const [key, value] of Object.entries(node)) {
    if (key !== 'context') expandIris(value, inner);
  }
  return node;
}

// a graph node as a plain term, emitting the triples of a blank-node property list or collection into out
function flattenNode(node, out) {
  if (node && node.type === 'tripleCollection') {
    for (const triple of node.triples) flattenTriple(triple, out);
    return materialize(node.identifier);
  }
  return materialize(node);
}

function flattenTriple(triple, out) {
  if (triple.type === 'tripleCollection') {
    flattenNode(triple, out);
    return;
  }
  const subject = flattenNode(triple.subject, out);
  const object = flattenNode(triple.object, out);
  out.push({ ...triple, subject, predicate: materialize(triple.predicate), object, loc: AUTO() });
}

function materialize(term) {
  return term && typeof term === 'object' ? { ...term, loc: AUTO() } : term;
}

function flattenBgps(node) {
  if (Array.isArray(node)) {
    node.forEach(flattenBgps);
    return node;
  }
  if (!node || typeof node !== 'object') return node;
  if (node.type === 'pattern' && node.subType === 'bgp' && Array.isArray(node.triples)) {
    const out = [];
    for (const triple of node.triples) flattenTriple(triple, out);
    node.triples = out;
  }
  for (const value of Object.values(node)) flattenBgps(value);
  return node;
}

function group(patterns) {
  return { type: 'pattern', subType: 'group', patterns, loc: AUTO() };
}

// the members the generator dereferences, filled where a stylesheet-built node lacks them
function complete(node) {
  if (node.type === 'query') {
    if (!Array.isArray(node.context)) node.context = [];
    if (!node.datasets) node.datasets = { type: 'datasetClauses', clauses: [] };
    if (!node.solutionModifiers) node.solutionModifiers = {};
    if (node.subType !== 'describe' && !node.where) node.where = group([]);
    const modifiers = node.solutionModifiers;
    const limitOffset = modifiers.limitOffset;
    if (limitOffset) {
      if (limitOffset.limit === undefined && !limitOffset.offset) delete modifiers.limitOffset;
      else Object.assign(limitOffset, { type: 'solutionModifier', subType: 'limitOffset' });
    }
    if (modifiers.order && !(modifiers.order.orderDefs?.length > 0)) delete modifiers.order;
    if (modifiers.group && !(modifiers.group.groupings?.length > 0)) delete modifiers.group;
  }
  if (node.type === 'pattern' && node.subType === 'union' && Array.isArray(node.patterns)) {
    node.patterns = node.patterns.map(pattern => pattern.type === 'pattern' && pattern.subType === 'group' ? pattern : group([ pattern ]));
  }
}

// every object the generator visits carries a source location; the rows of VALUES are keyed by variable name
// and are not nodes, so they get none (a variable named 'loc' would otherwise be clobbered)
function localize(node, rows = false) {
  if (Array.isArray(node)) {
    node.forEach(value => localize(value, rows));
    return node;
  }
  if (!node || typeof node !== 'object') return node;
  if (rows) {
    for (const value of Object.values(node)) localize(value);
    return node;
  }
  if (typeof node.type === 'string') complete(node);
  if (!node.loc) node.loc = AUTO();
  for (const [key, value] of Object.entries(node)) {
    if (key === 'loc') continue;
    localize(value, key === 'values' && node.subType === 'values');
  }
  return node;
}

export class Parser {
  constructor(options) {
    this.parser = new TraqulaParser(options);
  }

  parse(query) {
    return flattenBgps(expandIris(this.parser.parse(query)));
  }
}

export class Generator {
  constructor(options) {
    this.generator = new TraqulaGenerator(options);
  }

  generate(ast, options) {
    return this.generator.generate(localize(ast), options);
  }
}

if (typeof window !== 'undefined') {
  window.LDH_SPARQL = { Parser, Generator };
}
