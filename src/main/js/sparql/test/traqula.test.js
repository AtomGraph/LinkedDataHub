import assert from 'node:assert/strict';
import test from 'node:test';
import { Generator, Parser } from '../index.js';

// what the stylesheets do to an AST: serialise it to JSON and read it back
const roundTrip = ast => JSON.parse(JSON.stringify(ast));
const loc = () => ({ sourceLocationType: 'autoGenerate' });
const variable = value => ({ type: 'term', subType: 'variable', value });
const iri = value => ({ type: 'term', subType: 'namedNode', value });

test('parses and generates SELECT queries with the Traqula AST', () => {
  const query = 'PREFIX ex: <https://example.com/> SELECT ?s WHERE { ?s ex:p ?o OPTIONAL { ?s ex:q ?v } FILTER(?o > 2) VALUES ?v { ex:a ex:b } } ORDER BY DESC(?s) LIMIT 5 OFFSET 2';
  const ast = new Parser().parse(query);

  assert.equal(ast.type, 'query');
  assert.equal(ast.subType, 'select');
  assert.equal(ast.variables[0].type, 'term');
  assert.equal(ast.variables[0].subType, 'variable');
  assert.equal(ast.where.subType, 'group');
  assert.equal(ast.where.patterns[0].triples[0].predicate.value, 'https://example.com/p');
  assert.equal('prefix' in ast.where.patterns[0].triples[0].predicate, false);

  const generated = new Generator().generate(roundTrip(ast));
  const reparsed = new Parser().parse(generated);
  assert.equal(reparsed.subType, 'select');
  assert.equal(reparsed.where.patterns.length, 4);
  assert.equal(reparsed.solutionModifiers.limitOffset.limit, 5);
  assert.equal(reparsed.solutionModifiers.limitOffset.offset, 2);
  assert.equal(reparsed.solutionModifiers.order.orderDefs[0].descending, true);
});

test('resolves BASE-relative IRIs', () => {
  const ast = new Parser().parse('BASE <https://example.com/dir/> SELECT * { ?s <p> <../o> }');
  const [ triple ] = ast.where.patterns[0].triples;

  assert.equal(triple.predicate.value, 'https://example.com/dir/p');
  assert.equal(triple.object.value, 'https://example.com/o');
});

test('gives every triple of a predicate-object list its own subject and predicate', () => {
  const ast = roundTrip(new Parser().parse('SELECT * { ?s <https://example.com/p> ?a, ?b ; <https://example.com/q> ?c }'));
  const triples = ast.where.patterns[0].triples;

  assert.equal(triples.length, 3);
  assert.ok(triples.every(triple => triple.subject.value === 's' && triple.subject.loc.sourceLocationType === 'autoGenerate'));
  assert.ok(triples.every(triple => triple.predicate.loc.sourceLocationType === 'autoGenerate'));

  // a triple moved on its own still prints its subject
  ast.where.patterns[0].triples = [ triples[2] ];
  assert.match(new Generator().generate(ast), /\?s\s+<https:\/\/example\.com\/q>\s+\?c/);
});

test('flattens blank-node property lists and collections in CONSTRUCT templates', () => {
  const ast = new Parser().parse('PREFIX ex: <https://example.com/> CONSTRUCT { $this ex:p [ a ex:T ] ; ex:list ( 1 2 ) } WHERE {}');
  const triples = ast.template.triples;

  assert.ok(triples.every(triple => triple.type === 'triple'));
  assert.ok(triples.every(triple => [ 'variable', 'namedNode', 'blankNode', 'literal' ].includes(triple.subject.subType)));
  const link = triples.find(triple => triple.predicate.value === 'https://example.com/p');
  assert.equal(link.subject.value, 'this');
  assert.equal(link.object.subType, 'blankNode');
  assert.ok(triples.some(triple => triple.subject.label === link.object.label && triple.object.value === 'https://example.com/T'));
  assert.equal(triples.filter(triple => triple.predicate.value === 'http://www.w3.org/1999/02/22-rdf-syntax-ns#first').length, 2);

  const reparsed = new Parser().parse(new Generator().generate(roundTrip(ast)));
  assert.equal(reparsed.template.triples.length, triples.length);
});

test('generates nodes built without source locations, query members or grouped union branches', () => {
  const bgp = { type: 'pattern', subType: 'bgp', triples: [ { type: 'triple', subject: variable('s'), predicate: iri('https://example.com/p'), object: variable('o') } ] };
  const ast = {
    type: 'query',
    subType: 'select',
    variables: [ variable('s'), {
      type: 'pattern', subType: 'bind',
      expression: { type: 'expression', subType: 'aggregate', aggregation: 'count', distinct: true, expression: [ { type: 'wildcard' } ] },
      variable: variable('count'),
    } ],
    where: { type: 'pattern', subType: 'group', patterns: [
      { type: 'pattern', subType: 'union', patterns: [ bgp, { type: 'pattern', subType: 'graph', name: variable('g'), patterns: [ bgp ] } ] },
      { type: 'pattern', subType: 'filter', expression: { type: 'expression', subType: 'patternOperation', operator: 'exists', args: { type: 'pattern', subType: 'group', patterns: [ bgp ] } } },
      { type: 'pattern', subType: 'values', variables: [ variable('loc') ], values: [ { loc: iri('https://example.com/a') } ] },
    ] },
    solutionModifiers: {
      group: { type: 'solutionModifier', subType: 'group', groupings: [ variable('s') ] },
      order: { type: 'solutionModifier', subType: 'order', orderDefs: [ { expression: variable('count'), descending: true } ] },
      limitOffset: { limit: 10 },
    },
  };

  const generated = new Generator().generate(ast);
  const reparsed = new Parser().parse(generated);
  assert.equal(reparsed.where.patterns[0].subType, 'union');
  assert.equal(reparsed.where.patterns[1].expression.subType, 'patternOperation');
  assert.equal(reparsed.where.patterns[2].values[0].loc.value, 'https://example.com/a');
  assert.equal(reparsed.solutionModifiers.limitOffset.limit, 10);
  assert.equal(reparsed.solutionModifiers.order.orderDefs[0].descending, true);
});

test('drops empty solution modifiers', () => {
  const ast = roundTrip(new Parser().parse('SELECT * { ?s ?p ?o } LIMIT 5'));
  ast.solutionModifiers.limitOffset = { type: 'solutionModifier', subType: 'limitOffset', loc: loc() };

  assert.doesNotMatch(new Generator().generate(ast), /LIMIT/);
});

test('preserves language and datatype terms in SPARQL updates', () => {
  const ast = new Parser().parse('INSERT DATA { <https://example.com/s> <https://example.com/p> "hello"@en, "7"^^<http://www.w3.org/2001/XMLSchema#integer> }');
  const triples = ast.updates[0].operation.data[0].triples;

  assert.equal(ast.type, 'update');
  assert.equal(triples[0].object.subType, 'literal');
  assert.equal(triples[0].object.langOrIri, 'en');
  assert.equal(triples[1].object.langOrIri.value, 'http://www.w3.org/2001/XMLSchema#integer');
  assert.match(new Generator().generate(roundTrip(ast)), /INSERT DATA/);
});

test('generates blank nodes from their label', () => {
  const ast = {
    type: 'update',
    updates: [ { context: [], operation: {
      type: 'updateOperation', subType: 'modify', graph: undefined, delete: [], from: { type: 'datasetClauses', clauses: [] },
      insert: [ { type: 'pattern', subType: 'bgp', triples: [ { type: 'triple', subject: { type: 'term', subType: 'blankNode', label: 'b1' }, predicate: iri('https://example.com/p'), object: { type: 'term', subType: 'literal', value: 'a "quoted"\nvalue' } } ] } ],
      where: { type: 'pattern', subType: 'group', patterns: [] },
    } } ],
  };

  const generated = new Generator().generate(ast);
  assert.match(generated, /_:b1/);
  assert.equal(new Parser().parse(generated).updates[0].operation.insert[0].triples[0].object.value, 'a "quoted"\nvalue');
});
