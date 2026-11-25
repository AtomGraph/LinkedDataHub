import { Parser as TraqulaParser } from '@traqula/parser-sparql-1-1';
import { Generator as TraqulaGenerator } from '@traqula/generator-sparql-1-1';

function expandPrefixes(node, inheritedPrefixes = new Map()) {
  if (Array.isArray(node)) {
    node.forEach((value) => expandPrefixes(value, inheritedPrefixes));
    return node;
  }
  if (!node || typeof node !== 'object') return node;

  const prefixes = new Map(inheritedPrefixes);
  if (Array.isArray(node.context)) {
    for (const definition of node.context) {
      if (definition.subType === 'prefix' && definition.key && definition.value?.value) {
        prefixes.set(definition.key, definition.value.value);
      }
    }
  }

  if (node.type === 'term' && node.subType === 'namedNode' && node.prefix) {
    const namespace = prefixes.get(node.prefix);
    if (!namespace) throw new Error(`Undefined SPARQL prefix: ${node.prefix}`);
    node.value = namespace + node.value;
    delete node.prefix;
  }

  for (const value of Object.values(node)) expandPrefixes(value, prefixes);
  return node;
}

export class Parser {
  constructor(options) {
    this.parser = new TraqulaParser(options);
  }

  parse(query) {
    return expandPrefixes(this.parser.parse(query));
  }
}

export class Generator {
  constructor(options) {
    this.generator = new TraqulaGenerator(options);
  }

  generate(ast, options) {
    return this.generator.generate(ast, options);
  }
}

if (typeof window !== 'undefined') {
  window.LDH_SPARQL = { Parser, Generator };
}
