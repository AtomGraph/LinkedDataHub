import assert from 'node:assert/strict';
import { before, describe, test } from 'node:test';
import { compile, generate, parse, run } from './harness.js';

// The rewrites of client/query-transforms.xsl, each run on Saxon-JS over a query parsed by Traqula and generated
// back to SPARQL. A result is compared with the expected query as Traqula generates it, so whitespace and
// formatting are the generator's on both sides.

const XSD = 'http://www.w3.org/2001/XMLSchema#';
const LABELS = [ 'http://www.w3.org/2000/01/rdf-schema#label', 'http://purl.org/dc/elements/1.1/title', 'http://purl.org/dc/terms/title', 'http://xmlns.com/foaf/0.1/name', 'http://xmlns.com/foaf/0.1/givenName', 'http://xmlns.com/foaf/0.1/familyName', 'http://rdfs.org/sioc/ns#name', 'http://www.w3.org/2004/02/skos/core#prefLabel' ];

let sef;
before(() => { sef = compile(); });

const rewrite = (op, query, params) => generate(run(sef, op, query, params));
const call = (fn, query, params) => run(sef, `fn:${fn}`, query, params);
const assertQuery = (actual, expected) => assert.equal(actual, generate(parse(expected)));

describe('functions', () => {
  test('ldh:first-var-name reads a plain variable, an alias, and nothing from SELECT *', () => {
    assert.deepEqual(call('first-var-name', 'SELECT ?s ?o { ?s ?p ?o }'), [ 's' ]);
    assert.deepEqual(call('first-var-name', 'SELECT (?s AS ?resource) { ?s ?p ?o }'), [ 'resource' ]);
    assert.deepEqual(call('first-var-name', 'SELECT * { ?s ?p ?o }'), [ '' ]);
  });

  test('ldh:fresh-var-suffix skips the suffixes the query already uses with any stem', () => {
    assert.deepEqual(call('fresh-var-suffix', 'SELECT ?s { ?s ?p ?o }', { stems: [ 'predicate', 'inverse' ] }), [ '_ldh' ]);
    assert.deepEqual(call('fresh-var-suffix', 'SELECT ?s { ?s ?inverse_ldh ?o }', { stems: [ 'predicate', 'inverse' ] }), [ '_ldh1' ]);
    assert.deepEqual(call('fresh-var-suffix', 'SELECT ?s { { SELECT ?s ?predicate_ldh1 { ?s ?predicate_ldh ?predicate_ldh1 } } }', { stems: [ 'predicate' ] }), [ '_ldh2' ]);
  });

  test('ldh:query-limit and ldh:query-offset read the query\'s own, not a subquery\'s', () => {
    const paged = 'SELECT ?s { { SELECT ?s { ?s ?p ?o } LIMIT 3 OFFSET 1 } } LIMIT 20 OFFSET 40';
    assert.deepEqual(call('query-limit', paged), [ 20 ]);
    assert.deepEqual(call('query-offset', paged), [ 40 ]);

    const unpaged = 'SELECT ?s { { SELECT ?s { ?s ?p ?o } LIMIT 3 OFFSET 1 } }';
    assert.deepEqual(call('query-limit', unpaged), []);
    assert.deepEqual(call('query-offset', unpaged), []);
  });

  test('ldh:order-var-name and ldh:order-desc read a sort key by position, a plain variable only', () => {
    const query = 'SELECT ?a ?b { ?a ?p ?b } ORDER BY DESC(?a) ?b STR(?a)';
    assert.deepEqual(call('order-var-name', query, { pos: 1 }), [ 'a' ]);
    assert.deepEqual(call('order-desc', query, { pos: 1 }), [ true ]);
    assert.deepEqual(call('order-var-name', query, { pos: 2 }), [ 'b' ]);
    assert.deepEqual(call('order-desc', query, { pos: 2 }), [ false ]);
    assert.deepEqual(call('order-var-name', query, { pos: 3 }), []);
    assert.deepEqual(call('order-var-name', 'SELECT ?a { ?a ?p ?b }', { pos: 1 }), []);
  });

  test('ldh:subject-var-triples finds the variable\'s triples in subqueries too', () => {
    const triples = call('subject-var-triples', 'SELECT ?s { ?s <http://ex/p> ?o . ?o <http://ex/q> ?s { SELECT ?s { ?s <http://ex/r> ?x } } }', { 'var-name': 's' });
    assert.deepEqual(triples.map(triple => triple.predicate.value), [ 'http://ex/p', 'http://ex/r' ]);
  });

  test('ldh:is-filter-in recognises the variable\'s IN filter alone', () => {
    const query = 'SELECT ?s { ?s ?p ?o FILTER(?o IN (<http://ex/a>)) FILTER(?s != <http://ex/b>) }';
    assert.deepEqual(call('is-filter-in', query, { 'var-name': 'o' }), [ false, true, false ]);
    assert.deepEqual(call('is-filter-in', query, { 'var-name': 's' }), [ false, false, false ]);
  });

  test('ldh:term-node reads a token as a Traqula term', () => {
    const term = token => call('term-node', 'SELECT * {}', { token })[0];

    assert.deepEqual(term('?x'), { type: 'term', subType: 'variable', value: 'x' });
    assert.deepEqual(term('$x'), { type: 'term', subType: 'variable', value: 'x' });
    assert.deepEqual(term('_:b1'), { type: 'term', subType: 'blankNode', label: 'b1' });
    assert.deepEqual(term('<http://ex/a>'), { type: 'term', subType: 'namedNode', value: 'http://ex/a' });
    assert.deepEqual(term('http://ex/a'), { type: 'term', subType: 'namedNode', value: 'http://ex/a' });
    assert.deepEqual(term('"plain"'), { type: 'term', subType: 'literal', value: 'plain' });
    assert.deepEqual(term('"labas"@lt'), { type: 'term', subType: 'literal', value: 'labas', langOrIri: 'lt' });
    assert.deepEqual(term(`"1"^^<${XSD}integer>`), { type: 'term', subType: 'literal', value: '1', langOrIri: { type: 'term', subType: 'namedNode', value: `${XSD}integer` } });
    assert.deepEqual(term(`"1"^^${XSD}integer`), { type: 'term', subType: 'literal', value: '1', langOrIri: { type: 'term', subType: 'namedNode', value: `${XSD}integer` } });
    assert.deepEqual(term('"say "hi""'), { type: 'term', subType: 'literal', value: 'say "hi"' });
  });
});

describe('ldh:replace-variables', () => {
  test('projects the given variables in place of the query\'s, leaving a subquery\'s alone', () => {
    assertQuery(
      rewrite('replace-variables', 'SELECT ?a (STR(?b) AS ?c) { { SELECT ?a ?b { ?a ?p ?b } } }', { 'var-names': [ 'x', '?y' ] }),
      'SELECT ?x ?y { { SELECT ?a ?b { ?a ?p ?b } } }');
  });
});

describe('ldh:replace-limit and ldh:replace-offset', () => {
  const query = 'SELECT ?s { { SELECT ?s { ?s ?p ?o } LIMIT 5 OFFSET 2 } ?s ?q ?l } LIMIT 20 OFFSET 40';

  test('set the query\'s LIMIT, keeping its OFFSET and a subquery\'s slice', () => {
    assertQuery(rewrite('replace-limit', query, { limit: 10 }), 'SELECT ?s { { SELECT ?s { ?s ?p ?o } LIMIT 5 OFFSET 2 } ?s ?q ?l } LIMIT 10 OFFSET 40');
    assertQuery(rewrite('replace-limit', 'SELECT ?s { ?s ?p ?o }', { limit: 10 }), 'SELECT ?s { ?s ?p ?o } LIMIT 10');
  });

  test('remove the query\'s LIMIT when none is given', () => {
    assertQuery(rewrite('replace-limit', query), 'SELECT ?s { { SELECT ?s { ?s ?p ?o } LIMIT 5 OFFSET 2 } ?s ?q ?l } OFFSET 40');
  });

  test('set the query\'s OFFSET, keeping its LIMIT and a subquery\'s slice', () => {
    assertQuery(rewrite('replace-offset', query, { offset: 60 }), 'SELECT ?s { { SELECT ?s { ?s ?p ?o } LIMIT 5 OFFSET 2 } ?s ?q ?l } LIMIT 20 OFFSET 60');
  });

  test('remove the query\'s OFFSET when none is given', () => {
    assertQuery(rewrite('replace-offset', query), 'SELECT ?s { { SELECT ?s { ?s ?p ?o } LIMIT 5 OFFSET 2 } ?s ?q ?l } LIMIT 20');
  });

  test('page the bare page a Table chart keeps, which is a query\'s solution modifiers alone', () => {
    const page = { solutionModifiers: { limitOffset: { limit: 20, offset: 0 } } };
    assert.deepEqual(run(sef, 'replace-offset', page, { offset: 20 }), { solutionModifiers: { limitOffset: { limit: 20, offset: 20 } } });
    assert.deepEqual(run(sef, 'replace-limit', page, { limit: 50 }), { solutionModifiers: { limitOffset: { offset: 0, limit: 50 } } });
  });
});

describe('ldh:wrap-describe and ldh:strip-from', () => {
  test('DESCRIBE wraps the SELECT as a subquery and takes over its dataset clause', () => {
    assertQuery(
      rewrite('wrap-describe', 'SELECT ?s FROM <http://ex/g> FROM NAMED <http://ex/n> { ?s ?p ?o } LIMIT 5'),
      'DESCRIBE * FROM <http://ex/g> FROM NAMED <http://ex/n> { SELECT ?s { ?s ?p ?o } LIMIT 5 }');
  });

  test('strip-from drops the query\'s own dataset clause', () => {
    assertQuery(rewrite('strip-from', 'SELECT ?s FROM <http://ex/g> { ?s ?p ?o }'), 'SELECT ?s { ?s ?p ?o }');
  });
});

describe('ldh:strip-order-by', () => {
  test('drops every sort key of the query, and a subquery\'s none', () => {
    assertQuery(
      rewrite('strip-order-by', 'SELECT ?s { { SELECT ?s { ?s ?p ?o } ORDER BY ?o LIMIT 3 } } ORDER BY ?s DESC(?o) LIMIT 10'),
      'SELECT ?s { { SELECT ?s { ?s ?p ?o } ORDER BY ?o LIMIT 3 } } LIMIT 10');
  });
});

describe('ldh:link-predicates', () => {
  const graphUnion = (s, p, o, g) => `{ ${s} ${p} ${o} } UNION { GRAPH ${g} { ${s} ${p} ${o} } }`;
  const expected = (view, sfx, from = '') => `SELECT ?predicate${sfx} ?inverse${sfx} ${from} {
      { SELECT ?predicate${sfx} ("false"^^<${XSD}boolean> AS ?inverse${sfx}) {
          { ${view} }
          ${graphUnion('?s', `?predicate${sfx}`, `?object${sfx}`, `?graph${sfx}`)}
          FILTER(!isLiteral(?object${sfx}))
          FILTER EXISTS { ${graphUnion(`?object${sfx}`, `?objectPredicate${sfx}`, `?objectObject${sfx}`, `?objectGraph${sfx}`)} }
        } GROUP BY ?predicate${sfx} }
      UNION
      { SELECT ?predicate${sfx} ("true"^^<${XSD}boolean> AS ?inverse${sfx}) {
          { ${view} }
          ${graphUnion(`?subject${sfx}`, `?predicate${sfx}`, '?s', `?subjectGraph${sfx}`)}
        } GROUP BY ?predicate${sfx} }
    } LIMIT 100`;

  test('asks for the predicates linking the results, outgoing and incoming, each grouped before the UNION', () => {
    const view = 'SELECT ?s { ?s a <http://ex/C> }';
    assertQuery(rewrite('link-predicates', view), expected(view, '_ldh'));
  });

  test('keeps its variables clear of the view\'s and lifts the dataset clause out of the subquery', () => {
    const result = rewrite('link-predicates', 'SELECT ?s FROM <http://ex/g> { ?s ?predicate_ldh ?o }');
    assertQuery(result, expected('SELECT ?s { ?s ?predicate_ldh ?o }', '_ldh1', 'FROM <http://ex/g>'));
  });
});

describe('ldh:add-parallax-step', () => {
  const step = (s, o) => `{ ${s} <http://ex/p> ${o} } UNION { GRAPH ?graph_ldh { ${s} <http://ex/p> ${o} } }`;

  test('follows the predicate from the first variable to a new one, which becomes the projection', () => {
    assertQuery(
      rewrite('add-parallax-step', 'SELECT ?s { ?s a <http://ex/C> }', { predicate: 'http://ex/p' }),
      `SELECT ?subject_ldh { ?s a <http://ex/C> . ${step('?s', '?subject_ldh')} }`);
  });

  test('follows it backwards when inverse', () => {
    assertQuery(
      rewrite('add-parallax-step', 'SELECT ?s { ?s a <http://ex/C> }', { predicate: 'http://ex/p', inverse: true }),
      `SELECT ?subject_ldh { ?s a <http://ex/C> . ${step('?subject_ldh', '?s')} }`);
  });

  test('looks up the new resources\' title along with them', () => {
    assertQuery(
      rewrite('add-parallax-step', 'SELECT ?s { ?s a <http://ex/C> }', { predicate: 'http://ex/p', 'title-predicate': 'http://ex/title', 'title-new-var-name': 'title' }),
      `SELECT ?subject_ldh { ?s a <http://ex/C> .
        { ?s <http://ex/p> ?subject_ldh . ?subject_ldh <http://ex/title> ?title }
        UNION { GRAPH ?graph_ldh { ?s <http://ex/p> ?subject_ldh . ?subject_ldh <http://ex/title> ?title } } }`);
  });

  test('wraps a query whose first projection is an alias, which is unbound in its WHERE', () => {
    assertQuery(
      rewrite('add-parallax-step', 'SELECT (?x AS ?s) { ?x a <http://ex/C> }', { predicate: 'http://ex/p' }),
      `SELECT ?subject_ldh { { SELECT (?x AS ?s) { ?x a <http://ex/C> } } ${step('?s', '?subject_ldh')} }`);
  });

  test('keeps its variables clear of the query\'s', () => {
    assertQuery(
      rewrite('add-parallax-step', 'SELECT ?s { ?s ?p ?subject_ldh }', { predicate: 'http://ex/p' }),
      'SELECT ?subject_ldh1 { ?s ?p ?subject_ldh . { ?s <http://ex/p> ?subject_ldh1 } UNION { GRAPH ?graph_ldh1 { ?s <http://ex/p> ?subject_ldh1 } } }');
  });
});

describe('ldh:replace-order-by', () => {
  test('adds a sort key to a query with none', () => {
    assertQuery(rewrite('replace-order-by', 'SELECT ?a { ?a ?p ?b }', { 'var-name': 'b' }), 'SELECT ?a { ?a ?p ?b } ORDER BY ?b');
    assertQuery(rewrite('replace-order-by', 'SELECT ?a { ?a ?p ?b }'), 'SELECT ?a { ?a ?p ?b }');
  });

  test('puts a new key before the one there is, unless it is that one', () => {
    assertQuery(rewrite('replace-order-by', 'SELECT ?a { ?a ?p ?b } ORDER BY ?a', { 'var-name': 'b' }), 'SELECT ?a { ?a ?p ?b } ORDER BY ?b ?a');
    assertQuery(rewrite('replace-order-by', 'SELECT ?a { ?a ?p ?b } ORDER BY DESC(?a)', { 'var-name': 'a' }), 'SELECT ?a { ?a ?p ?b } ORDER BY DESC(?a)');
  });

  test('removes the only key when none is given', () => {
    assertQuery(rewrite('replace-order-by', 'SELECT ?a { ?a ?p ?b } ORDER BY ?a'), 'SELECT ?a { ?a ?p ?b }');
  });

  test('replaces the first of two keys, or drops it for the second', () => {
    assertQuery(rewrite('replace-order-by', 'SELECT ?a { ?a ?p ?b } ORDER BY ?a ?b', { 'var-name': 'c' }), 'SELECT ?a { ?a ?p ?b } ORDER BY ?c ?b');
    assertQuery(rewrite('replace-order-by', 'SELECT ?a { ?a ?p ?b } ORDER BY ?a ?b', { 'var-name': 'b' }), 'SELECT ?a { ?a ?p ?b } ORDER BY ?b');
    assertQuery(rewrite('replace-order-by', 'SELECT ?a { ?a ?p ?b } ORDER BY ?a ?b'), 'SELECT ?a { ?a ?p ?b } ORDER BY ?b');
  });
});

describe('ldh:toggle-desc', () => {
  test('sets the direction of the first sort key alone', () => {
    assertQuery(rewrite('toggle-desc', 'SELECT ?a { ?a ?p ?b } ORDER BY ?a ?b', { desc: true }), 'SELECT ?a { ?a ?p ?b } ORDER BY DESC(?a) ?b');
    assertQuery(rewrite('toggle-desc', 'SELECT ?a { ?a ?p ?b } ORDER BY DESC(?a) DESC(?b)', { desc: false }), 'SELECT ?a { ?a ?p ?b } ORDER BY ?a DESC(?b)');
    assertQuery(rewrite('toggle-desc', 'SELECT ?a { ?a ?p ?b } ORDER BY DESC(?a)'), 'SELECT ?a { ?a ?p ?b } ORDER BY ?a');
  });
});

describe('ldh:bgp-value-counts', () => {
  const names = { 'subject-var-name': 's', 'object-var-name': 'o', 'count-var-name': 'count', 'label-var-name': 'label', 'label-sample-var-name': 'labelSample' };
  const lookup = `OPTIONAL {
      VALUES ?labelproperty { ${LABELS.map(label => `<${label}>`).join(' ')} }
      { ?o ?labelproperty ?label } UNION { GRAPH ?labelgraph { ?o ?labelproperty ?label } }
    }`;

  test('counts the subjects per value of the facet, looks up the values\' labels, and orders by the count', () => {
    assertQuery(
      rewrite('bgp-value-counts', 'SELECT ?s { ?s <http://ex/p> ?o }', names),
      `SELECT ?o (COUNT(DISTINCT ?s) AS ?count) (SAMPLE(?label) AS ?labelSample) { ?s <http://ex/p> ?o . ${lookup} } GROUP BY ?o ORDER BY DESC(?count)`);
  });

  test('sorts by the count after the query\'s own keys, ascending if asked', () => {
    assertQuery(
      rewrite('bgp-value-counts', 'SELECT ?s { ?s <http://ex/p> ?o } ORDER BY ?s', { ...names, descending: false }),
      `SELECT ?o (COUNT(DISTINCT ?s) AS ?count) (SAMPLE(?label) AS ?labelSample) { ?s <http://ex/p> ?o . ${lookup} } GROUP BY ?o ORDER BY ?s ?count`);
  });

  test('looks up labels only next to the pattern that binds the value', () => {
    assertQuery(
      rewrite('bgp-value-counts', 'SELECT ?s { ?s <http://ex/p> ?x }', names),
      'SELECT ?o (COUNT(DISTINCT ?s) AS ?count) (SAMPLE(?label) AS ?labelSample) { ?s <http://ex/p> ?x } GROUP BY ?o ORDER BY DESC(?count)');
  });
});

describe('ldh:filter-in', () => {
  const values = [
    { type: 'uri', value: 'http://ex/a' },
    { type: 'literal', value: 'labas', lang: 'lt' },
    { type: 'literal', value: '1', datatype: `${XSD}integer` },
    { type: 'literal', value: 'plain' }
  ];

  test('appends the variable\'s IN filter with the values, each term as it is', () => {
    assertQuery(
      rewrite('filter-in', 'SELECT ?s { ?s ?p ?o }', { 'var-name': 'o', values }),
      `SELECT ?s { ?s ?p ?o FILTER(?o IN (<http://ex/a>, "labas"@lt, "1"^^<${XSD}integer>, "plain")) }`);
  });

  test('replaces the values of the variable\'s filter, and leaves another variable\'s', () => {
    assertQuery(
      rewrite('filter-in', 'SELECT ?s { ?s ?p ?o FILTER(?o IN (<http://ex/old>)) FILTER(?s IN (<http://ex/s>)) }', { 'var-name': 'o', values: values.slice(0, 1) }),
      'SELECT ?s { ?s ?p ?o FILTER(?o IN (<http://ex/a>)) FILTER(?s IN (<http://ex/s>)) }');
  });

  test('removes the variable\'s filter when there are no values', () => {
    assertQuery(
      rewrite('filter-in', 'SELECT ?s { ?s ?p ?o FILTER(?o IN (<http://ex/old>)) FILTER(?s IN (<http://ex/s>)) }', { 'var-name': 'o', values: [] }),
      'SELECT ?s { ?s ?p ?o FILTER(?s IN (<http://ex/s>)) }');
  });
});

describe('ldh:filter-contains', () => {
  const contains = (v, text) => `FILTER(isLiteral(?${v}) && CONTAINS(LCASE(STR(?${v})), LCASE(${text})))`;

  test('appends a case-insensitive substring filter, the text escaped as a literal', () => {
    assertQuery(
      rewrite('filter-contains', 'SELECT ?s { ?s ?p ?l }', { 'var-name': 'l', text: 'Fo"o\\' }),
      `SELECT ?s { ?s ?p ?l ${contains('l', '"Fo\\"o\\\\"')} }`);
  });

  test('replaces the variable\'s text filter, parsed back or just built, and leaves another variable\'s', () => {
    const built = run(sef, 'filter-contains', 'SELECT ?s { ?s ?p ?l . ?s ?q ?x }', { 'var-name': 'l', text: 'foo' });
    const withOther = run(sef, 'filter-contains', built, { 'var-name': 'x', text: 'baz' });
    const expected = `SELECT ?s { ?s ?p ?l . ?s ?q ?x ${contains('x', '"baz"')} ${contains('l', '"bar"')} }`;

    assertQuery(rewrite('filter-contains', withOther, { 'var-name': 'l', text: 'bar' }), expected);
    assertQuery(rewrite('filter-contains', generate(withOther), { 'var-name': 'l', text: 'bar' }), expected);
  });

  test('removes the variable\'s text filter when there is no text', () => {
    assertQuery(
      rewrite('filter-contains', `SELECT ?s { ?s ?p ?l ${contains('l', '"foo"')} ${contains('x', '"baz"')} }`, { 'var-name': 'l' }),
      `SELECT ?s { ?s ?p ?l ${contains('x', '"baz"')} }`);
  });

  test('leaves a nested group\'s filter alone', () => {
    const query = `SELECT ?s { ?s ?p ?l { ?s ?q ?l ${contains('l', '"foo"')} } }`;
    assertQuery(rewrite('filter-contains', query, { 'var-name': 'l' }), query);
  });
});

describe('ldh:wrap-subquery', () => {
  test('selects the first variable over the query, which keeps its projection as a subquery', () => {
    assertQuery(
      rewrite('wrap-subquery', 'SELECT (?x AS ?s) ?y FROM <http://ex/g> { ?x ?p ?y } LIMIT 5'),
      'SELECT ?s FROM <http://ex/g> { { SELECT (?x AS ?s) ?y { ?x ?p ?y } LIMIT 5 } }');
  });
});

describe('ldh:result-count', () => {
  test('counts the distinct solutions, or the distinct values of the given variable', () => {
    assertQuery(rewrite('result-count', 'SELECT ?s { ?s ?p ?o }', { 'count-var-name': 'count' }), 'SELECT (COUNT(DISTINCT *) AS ?count) { ?s ?p ?o }');
    assertQuery(rewrite('result-count', 'SELECT ?s { ?s ?p ?o }', { 'count-var-name': 'count', 'expression-var-name': 's' }), 'SELECT (COUNT(DISTINCT ?s) AS ?count) { ?s ?p ?o }');
  });

  test('counts over the query as a subquery when its first projection is an alias', () => {
    assertQuery(
      rewrite('result-count', 'SELECT (?x AS ?s) { ?x ?p ?o }', { 'count-var-name': 'count', 'expression-var-name': 's' }),
      'SELECT (COUNT(DISTINCT ?s) AS ?count) { { SELECT (?x AS ?s) { ?x ?p ?o } } }');
  });
});

describe('ldh:container-select', () => {
  const joins = (focus, sfx) => `GRAPH ?doc${sfx} { ${focus} ?p${sfx} ?o${sfx} } GRAPH ?cg${sfx} { ?doc${sfx} <http://rdfs.org/sioc/ns#has_container> ?container${sfx} }`;

  test('asks for the distinct containers of the documents describing the results, two at most', () => {
    assertQuery(
      rewrite('container-select', 'SELECT ?s { ?s a <http://ex/C> } LIMIT 20 OFFSET 40', { 'focus-var-name': 's' }),
      `SELECT DISTINCT ?container_ldh { ?s a <http://ex/C> . ${joins('?s', '_ldh')} } LIMIT 2`);
  });

  test('keeps its variables clear of the query\'s, and joins on an alias over a subquery', () => {
    assertQuery(
      rewrite('container-select', 'SELECT ?s { ?s ?p_ldh ?o }', { 'focus-var-name': 's' }),
      `SELECT DISTINCT ?container_ldh1 { ?s ?p_ldh ?o . ${joins('?s', '_ldh1')} } LIMIT 2`);
    assertQuery(
      rewrite('container-select', 'SELECT (?x AS ?s) { ?x a <http://ex/C> }', { 'focus-var-name': 's' }),
      `SELECT DISTINCT ?container_ldh { { SELECT (?x AS ?s) { ?x a <http://ex/C> } } ${joins('?s', '_ldh')} } LIMIT 2`);
  });
});

describe('ldh:add-constructor-triple', () => {
  test('adds the property with a blank node of the given type to the CONSTRUCT template', () => {
    const result = rewrite('add-constructor-triple', 'CONSTRUCT { ?this a <http://ex/C> } WHERE {}', { predicate: 'http://ex/p', 'object-type': 'http://ex/T' });
    const [ , bnode ] = result.match(/<http:\/\/ex\/p> (_:ctor\S+)/) ?? [];

    assert.ok(bnode, result);
    assertQuery(result, `CONSTRUCT { ?this a <http://ex/C> . ?this <http://ex/p> ${bnode} . ${bnode} a <http://ex/T> } WHERE {}`);
  });

  test('to the given subject', () => {
    const result = rewrite('add-constructor-triple', 'CONSTRUCT { ?s a <http://ex/C> } WHERE {}', { subject: '?s', predicate: 'http://ex/p', 'object-type': 'http://ex/T' });
    assert.match(result, /\?s <http:\/\/ex\/p> _:ctor/);
  });
});

describe('ldh:add-regex-filter', () => {
  test('appends a REGEX filter on the variable, with flags if given', () => {
    assertQuery(rewrite('add-regex-filter', 'SELECT ?s { ?s ?p ?l }', { 'var-name': 'l', pattern: '^foo', flags: 'iq' }), 'SELECT ?s { ?s ?p ?l FILTER(REGEX(?l, "^foo", "iq")) }');
    assertQuery(rewrite('add-regex-filter', 'SELECT ?s { ?s ?p ?l }', { 'var-name': 'l', pattern: 'say "hi"' }), 'SELECT ?s { ?s ?p ?l FILTER(REGEX(?l, "say \\"hi\\"")) }');
  });
});

describe('ldh:add-text-query', () => {
  test('puts the text index pattern first in WHERE, the query escaped as a literal', () => {
    assertQuery(
      rewrite('add-text-query', 'SELECT ?s { GRAPH ?g { ?s ?p ?l } }', { 'var-name': 's', query: 'foo "bar"' }),
      'SELECT ?s { ?s <http://jena.apache.org/text#query> "foo \\"bar\\"" . GRAPH ?g { ?s ?p ?l } }');
  });
});

describe('ldh:append-values', () => {
  test('appends a VALUES row per map, each value a term of its type', () => {
    assertQuery(
      rewrite('append-values', 'SELECT ?type { ?s a ?type }', { rows: [
        { type: { type: 'anyURI', value: 'http://ex/C' } },
        { type: { type: 'integer', value: 3 } },
        { type: { type: 'boolean', value: true } },
        { type: { type: 'date', value: '2026-11-24' } },
        { type: { type: 'dateTime', value: '2026-11-24T12:00:00Z' } },
        { type: { type: 'double', value: 1.5 } },
        { type: 'plain' }
      ] }),
      `SELECT ?type { ?s a ?type VALUES ?type { <http://ex/C> "3"^^<${XSD}integer> "true"^^<${XSD}boolean> "2026-11-24"^^<${XSD}date> "2026-11-24T12:00:00Z"^^<${XSD}dateTime> "1.5"^^<${XSD}double> "plain" } }`);
  });

  test('takes its variables from every row', () => {
    assertQuery(
      rewrite('append-values', 'SELECT ?a { ?a ?p ?b }', { rows: [ { a: { type: 'anyURI', value: 'http://ex/a' }, b: 'x' }, { a: { type: 'anyURI', value: 'http://ex/c' } } ] }),
      'SELECT ?a { ?a ?p ?b VALUES (?a ?b) { (<http://ex/a> "x") (<http://ex/c> UNDEF) } }');
  });
});
