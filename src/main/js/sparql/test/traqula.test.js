import assert from 'node:assert/strict';
import test from 'node:test';
import { Generator, Parser } from '../index.js';

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
  assert.ok(ast.context.some((item) => item.subType === 'prefix' && item.key === 'ex'));

  const generated = new Generator().generate(ast);
  const reparsed = new Parser().parse(generated);
  assert.equal(reparsed.subType, 'select');
  assert.equal(reparsed.where.patterns.length, 4);
  assert.equal(reparsed.solutionModifiers.limitOffset.limit, 5);
  assert.equal(reparsed.solutionModifiers.limitOffset.offset, 2);
  assert.equal(reparsed.solutionModifiers.order.orderDefs[0].descending, true);
});

test('preserves typed CONSTRUCT template terms and named graph IRIs', () => {
  const ast = new Parser().parse('CONSTRUCT { ?s <https://example.com/p> ?o } WHERE { GRAPH <https://example.com/g> { ?s ?p ?o } }');
  const triple = ast.template.triples[0];

  assert.equal(ast.subType, 'construct');
  assert.equal(triple.subject.subType, 'variable');
  assert.equal(triple.predicate.subType, 'namedNode');
  assert.equal(triple.predicate.value, 'https://example.com/p');
  assert.equal(ast.where.patterns[0].subType, 'graph');
  assert.match(new Generator().generate(ast), /CONSTRUCT/);
});

test('preserves language and datatype terms in SPARQL updates', () => {
  const ast = new Parser().parse('INSERT DATA { <https://example.com/s> <https://example.com/p> "hello"@en, "7"^^<http://www.w3.org/2001/XMLSchema#integer> }');
  const triples = ast.updates[0].operation.data[0].triples;

  assert.equal(ast.type, 'update');
  assert.equal(triples[0].object.subType, 'literal');
  assert.equal(triples[0].object.langOrIri, 'en');
  assert.equal(triples[1].object.langOrIri.value, 'http://www.w3.org/2001/XMLSchema#integer');
  assert.match(new Generator().generate(ast), /INSERT DATA/);
});
