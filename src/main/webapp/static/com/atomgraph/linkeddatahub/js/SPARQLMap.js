window["SPARQLMap"] =
/******/ (function(modules) { // webpackBootstrap
/******/ 	// The module cache
/******/ 	var installedModules = {};
/******/
/******/ 	// The require function
/******/ 	function __webpack_require__(moduleId) {
/******/
/******/ 		// Check if module is in cache
/******/ 		if(installedModules[moduleId]) {
/******/ 			return installedModules[moduleId].exports;
/******/ 		}
/******/ 		// Create a new module (and put it into the cache)
/******/ 		var module = installedModules[moduleId] = {
/******/ 			i: moduleId,
/******/ 			l: false,
/******/ 			exports: {}
/******/ 		};
/******/
/******/ 		// Execute the module function
/******/ 		modules[moduleId].call(module.exports, module, module.exports, __webpack_require__);
/******/
/******/ 		// Flag the module as loaded
/******/ 		module.l = true;
/******/
/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}
/******/
/******/
/******/ 	// expose the modules object (__webpack_modules__)
/******/ 	__webpack_require__.m = modules;
/******/
/******/ 	// expose the module cache
/******/ 	__webpack_require__.c = installedModules;
/******/
/******/ 	// define getter function for harmony exports
/******/ 	__webpack_require__.d = function(exports, name, getter) {
/******/ 		if(!__webpack_require__.o(exports, name)) {
/******/ 			Object.defineProperty(exports, name, { enumerable: true, get: getter });
/******/ 		}
/******/ 	};
/******/
/******/ 	// define __esModule on exports
/******/ 	__webpack_require__.r = function(exports) {
/******/ 		if(typeof Symbol !== 'undefined' && Symbol.toStringTag) {
/******/ 			Object.defineProperty(exports, Symbol.toStringTag, { value: 'Module' });
/******/ 		}
/******/ 		Object.defineProperty(exports, '__esModule', { value: true });
/******/ 	};
/******/
/******/ 	// create a fake namespace object
/******/ 	// mode & 1: value is a module id, require it
/******/ 	// mode & 2: merge all properties of value into the ns
/******/ 	// mode & 4: return value when already ns object
/******/ 	// mode & 8|1: behave like require
/******/ 	__webpack_require__.t = function(value, mode) {
/******/ 		if(mode & 1) value = __webpack_require__(value);
/******/ 		if(mode & 8) return value;
/******/ 		if((mode & 4) && typeof value === 'object' && value && value.__esModule) return value;
/******/ 		var ns = Object.create(null);
/******/ 		__webpack_require__.r(ns);
/******/ 		Object.defineProperty(ns, 'default', { enumerable: true, value: value });
/******/ 		if(mode & 2 && typeof value != 'string') for(var key in value) __webpack_require__.d(ns, key, function(key) { return value[key]; }.bind(null, key));
/******/ 		return ns;
/******/ 	};
/******/
/******/ 	// getDefaultExport function for compatibility with non-harmony modules
/******/ 	__webpack_require__.n = function(module) {
/******/ 		var getter = module && module.__esModule ?
/******/ 			function getDefault() { return module['default']; } :
/******/ 			function getModuleExports() { return module; };
/******/ 		__webpack_require__.d(getter, 'a', getter);
/******/ 		return getter;
/******/ 	};
/******/
/******/ 	// Object.prototype.hasOwnProperty.call
/******/ 	__webpack_require__.o = function(object, property) { return Object.prototype.hasOwnProperty.call(object, property); };
/******/
/******/ 	// __webpack_public_path__
/******/ 	__webpack_require__.p = "";
/******/
/******/
/******/ 	// Load entry module and return exports
/******/ 	return __webpack_require__(__webpack_require__.s = "./src/com/atomgraph/linkeddatahub/client/Map.ts");
/******/ })
/************************************************************************/
/******/ ({

/***/ "../URLBuilder/src/com/atomgraph/linkeddatahub/util/URLBuilder.ts":
/*!************************************************************************!*\
  !*** ../URLBuilder/src/com/atomgraph/linkeddatahub/util/URLBuilder.ts ***!
  \************************************************************************/
/*! exports provided: URLBuilder */
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "URLBuilder", function() { return URLBuilder; });
/**
 *  URLBuilder class for easier composition of URLs.
 *
 *  Example usage:
 *
 *  URLBuilder.fromURL("https://atomgraph.com").path("cases").path("nxp-semiconductors").build().toString();
 *
 *  Will return:
 *
 *  "https://atomgraph.com/cases/nxp-semiconductors"
 *
 *  This implementation does not support variable templates such as {var} as of yet.
 *
 *  @author Martynas Jusevičius <martynas@atomgraph.com>
 */
class URLBuilder {
    constructor(url) {
        this.url = new URL(url.toString()); // clone the object, so we don't change the original
    }
    ;
    /**
     * Set hash (without "#")
     *
     * @param string hash
     * @returns {URLBuilder}
     */
    hash(hash) {
        if (hash == null)
            this.url.hash = "";
        else
            this.url.hash = "#" + hash;
        return this;
    }
    ;
    /**
     * Set host
     *
     * @param string host
     * @returns {URLBuilder}
     */
    host(host) {
        this.url.host = host;
        return this;
    }
    ;
    /**
     * Set hostname
     *
     * @param string hostname
     * @returns {URLBuilder}
     */
    hostname(hostname) {
        this.url.hostname = hostname;
        return this;
    }
    ;
    /**
     * Set password
     *
     * @param string password
     * @return {URLBuilder}
     */
    password(password) {
        this.url.password = password;
        return this;
    }
    ;
    /**
     * Append path
     *
     * @param string path
     * @returns {URLBuilder}
     */
    path(path) {
        if (path == null)
            this.url.pathname = "";
        else {
            if (this.url.pathname.length === 0) {
                if (!path.startsWith("/"))
                    path = "/" + path;
                this.url.pathname = path;
            }
            else {
                if (!path.startsWith("/") && !this.url.pathname.endsWith("/"))
                    path = "/" + path;
                this.url.pathname += path;
            }
        }
        return this;
    }
    ;
    /**
     * Set port
     *
     * @param string port
     * @returns {URLBuilder}
     */
    port(port) {
        if (port == null)
            this.url.port = "";
        else
            this.url.port = port;
        return this;
    }
    ;
    /**
     * Set protocol
     *
     * @param string protocol
     * @return {URLBuilder}
     */
    protocol(protocol) {
        this.url.protocol = protocol;
        return this;
    }
    ;
    /**
     * Set a query string (with leading "?")
     *
     * @param string search
     * @returns {URLBuilder}
     */
    search(search) {
        if (search == null)
            this.url.search = "";
        else
            this.url.search = search;
        return this;
    }
    ;
    /**
     * Add a query name=value pair.
     * Multiple values are allowed.
     *
     * @param string name
     * @param string value
     * @returns {URLBuilder}
     */
    searchParam(name, ...values) {
        for (let value of values)
            this.url.searchParams.append(name, value);
        return this;
    }
    ;
    /**
     * Replace a query param
     * Multiple values are allowed.
     *
     * @param string name
     * @param string value
     * @returns {URLBuilder}
     */
    replaceSearchParam(name, ...values) {
        this.url.searchParams.delete(name);
        for (let value of values)
            this.url.searchParams.append(name, value);
        return this;
    }
    ;
    /**
     * Set username
     *
     * @param string username
     * @return {URLBuilder}
     */
    username(username) {
        this.url.username = username;
        return this;
    }
    ;
    /**
     * Build URL object
     *
     * @returns {URL}
     */
    build() {
        return this.url;
    }
    ;
    /**
     * Create a new instance from an existing URL.
     *
     * @param URL url
     * @returns {URLBuilder}
     */
    static fromURL(url) {
        return new URLBuilder(url);
    }
    ;
    /**
     * Create a new instance from string and optional base.
     *
     * @param string url
     * @param string base
     * @returns {URLBuilder}
     */
    static fromString(url, base) {
        return new URLBuilder(new URL(url, base));
    }
    ;
}


/***/ }),

/***/ "../sparql-builder/node_modules/sparqljs/lib/SparqlGenerator.js":
/*!**********************************************************************!*\
  !*** ../sparql-builder/node_modules/sparqljs/lib/SparqlGenerator.js ***!
  \**********************************************************************/
/*! no static exports found */
/***/ (function(module, exports) {

var XSD_INTEGER = 'http://www.w3.org/2001/XMLSchema#integer';

function Generator(options, prefixes) {
  this._options = options = options || {};

  prefixes = prefixes || {};
  this._prefixByIri = {};
  var prefixIris = [];
  for (var prefix in prefixes) {
    var iri = prefixes[prefix];
    if (isString(iri)) {
      this._prefixByIri[iri] = prefix;
      prefixIris.push(iri);
    }
  }
  var iriList = prefixIris.join('|').replace(/[\]\/\(\)\*\+\?\.\\\$]/g, '\\$&');
  this._prefixRegex = new RegExp('^(' + iriList + ')([a-zA-Z][\\-_a-zA-Z0-9]*)$');
  this._usedPrefixes = {};
  this._indent =  isString(options.indent)  ? options.indent  : '  ';
  this._newline = isString(options.newline) ? options.newline : '\n';
}

// Converts the parsed query object into a SPARQL query
Generator.prototype.toQuery = function (q) {
  var query = '';

  if (q.queryType)
    query += q.queryType.toUpperCase() + ' ';
  if (q.reduced)
    query += 'REDUCED ';
  if (q.distinct)
    query += 'DISTINCT ';

  if (q.variables)
    query += mapJoin(q.variables, undefined, function (variable) {
      return isString(variable) ? this.toEntity(variable) :
             '(' + this.toExpression(variable.expression) + ' AS ' + variable.variable + ')';
    }, this) + ' ';
  else if (q.template)
    query += this.group(q.template, true) + this._newline;

  if (q.from)
    query += mapJoin(q.from.default || [], '', function (g) { return 'FROM ' + this.toEntity(g) + this._newline; }, this) +
             mapJoin(q.from.named || [], '', function (g) { return 'FROM NAMED ' + this.toEntity(g) + this._newline; }, this);
  if (q.where)
    query += 'WHERE ' + this.group(q.where, true) + this._newline;

  if (q.updates)
    query += mapJoin(q.updates, ';' + this._newline, this.toUpdate, this);

  if (q.group)
    query += 'GROUP BY ' + mapJoin(q.group, undefined, function (it) {
      var result = isString(it.expression) ? it.expression : '(' + this.toExpression(it.expression) + ')';
      return it.variable ? '(' + result + ' AS ' + it.variable + ')' : result;
    }, this) + this._newline;
  if (q.having)
    query += 'HAVING (' + mapJoin(q.having, undefined, this.toExpression, this) + ')' + this._newline;
  if (q.order)
    query += 'ORDER BY ' + mapJoin(q.order, undefined, function (it) {
      var expr = '(' + this.toExpression(it.expression) + ')';
      return !it.descending ? expr : 'DESC ' + expr;
    }, this) + this._newline;

  if (q.offset)
    query += 'OFFSET ' + q.offset + this._newline;
  if (q.limit)
    query += 'LIMIT ' + q.limit + this._newline;

  if (q.values)
    query += this.values(q);

  // stringify prefixes at the end to mark used ones
  query = this.baseAndPrefixes(q) + query;
  return query.trim();
};

Generator.prototype.baseAndPrefixes = function (q) {
  var base = q.base ? ('BASE <' + q.base + '>' + this._newline) : '';
  var prefixes = '';
  for (var key in q.prefixes) {
    if (this._options.allPrefixes || this._usedPrefixes[key])
      prefixes += 'PREFIX ' + key + ': <' + q.prefixes[key] + '>' + this._newline;
  }
  return base + prefixes;
};

// Converts the parsed SPARQL pattern into a SPARQL pattern
Generator.prototype.toPattern = function (pattern) {
  var type = pattern.type || (pattern instanceof Array) && 'array' ||
             (pattern.subject && pattern.predicate && pattern.object ? 'triple' : '');
  if (!(type in this))
    throw new Error('Unknown entry type: ' + type);
  return this[type](pattern);
};

Generator.prototype.triple = function (t) {
  return this.toEntity(t.subject) + ' ' + this.toEntity(t.predicate) + ' ' + this.toEntity(t.object) + '.';
};

Generator.prototype.array = function (items) {
  return mapJoin(items, this._newline, this.toPattern, this);
};

Generator.prototype.bgp = function (bgp) {
  return this.encodeTriples(bgp.triples);
};

Generator.prototype.encodeTriples = function (triples) {
  if (!triples.length)
    return '';

  var parts = [], subject = '', predicate = '';
  for (var i = 0; i < triples.length; i++) {
    var triple = triples[i];
    // Triple with different subject
    if (triple.subject !== subject) {
      // Terminate previous triple
      if (subject)
        parts.push('.' + this._newline);
      subject = triple.subject;
      predicate = triple.predicate;
      parts.push(this.toEntity(subject), ' ', this.toEntity(predicate));
    }
    // Triple with same subject but different predicate
    else if (triple.predicate !== predicate) {
      predicate = triple.predicate;
      parts.push(';' + this._newline, this._indent, this.toEntity(predicate));
    }
    // Triple with same subject and predicate
    else {
      parts.push(',');
    }
    parts.push(' ', this.toEntity(triple.object));
  }
  parts.push('.');

  return parts.join('');
}

Generator.prototype.graph = function (graph) {
  return 'GRAPH ' + this.toEntity(graph.name) + ' ' + this.group(graph);
};

Generator.prototype.group = function (group, inline) {
  group = inline !== true ? this.array(group.patterns || group.triples)
                          : this.toPattern(group.type !== 'group' ? group : group.patterns);
  return group.indexOf(this._newline) === -1 ? '{ ' + group + ' }' : '{' + this._newline + this.indent(group) + this._newline + '}';
};

Generator.prototype.query = function (query) {
  return this.toQuery(query);
};

Generator.prototype.filter = function (filter) {
  return 'FILTER(' + this.toExpression(filter.expression) + ')';
};

Generator.prototype.bind = function (bind) {
  return 'BIND(' + this.toExpression(bind.expression) + ' AS ' + bind.variable + ')';
};

Generator.prototype.optional = function (optional) {
  return 'OPTIONAL ' + this.group(optional);
};

Generator.prototype.union = function (union) {
  return mapJoin(union.patterns, this._newline + 'UNION' + this._newline, function (p) { return this.group(p, true); }, this);
};

Generator.prototype.minus = function (minus) {
  return 'MINUS ' + this.group(minus);
};

Generator.prototype.values = function (valuesList) {
  // Gather unique keys
  var keys = Object.keys(valuesList.values.reduce(function (keyHash, values) {
    for (var key in values) keyHash[key] = true;
    return keyHash;
  }, {}));
  // Check whether simple syntax can be used
  var lparen, rparen;
  if (keys.length === 1) {
    lparen = rparen = '';
  } else {
    lparen = '(';
    rparen = ')';
  }
  // Create value rows
  return 'VALUES ' + lparen + keys.join(' ') + rparen + ' {' + this._newline +
    mapJoin(valuesList.values, this._newline, function (values) {
      return '  ' + lparen + mapJoin(keys, undefined, function (key) {
        return values[key] !== undefined ? this.toEntity(values[key]) : 'UNDEF';
      }, this) + rparen;
    }, this) + this._newline + '}';
};

Generator.prototype.service = function (service) {
  return 'SERVICE ' + (service.silent ? 'SILENT ' : '') + this.toEntity(service.name) + ' ' +
         this.group(service);
};

// Converts the parsed expression object into a SPARQL expression
Generator.prototype.toExpression = function (expr) {
  if (isString(expr))
    return this.toEntity(expr);

  switch (expr.type.toLowerCase()) {
    case 'aggregate':
      return expr.aggregation.toUpperCase() +
             '(' + (expr.distinct ? 'DISTINCT ' : '') + this.toExpression(expr.expression) +
             (expr.separator ? '; SEPARATOR = ' + this.toEntity('"' + expr.separator + '"') : '') + ')';
    case 'functioncall':
      return this.toEntity(expr.function) + '(' + mapJoin(expr.args, ', ', this.toExpression, this) + ')';
    case 'operation':
      var operator = expr.operator.toUpperCase(), args = expr.args || [];
      switch (expr.operator.toLowerCase()) {
      // Infix operators
      case '<':
      case '>':
      case '>=':
      case '<=':
      case '&&':
      case '||':
      case '=':
      case '!=':
      case '+':
      case '-':
      case '*':
      case '/':
          return (isString(args[0]) ? this.toEntity(args[0]) : '(' + this.toExpression(args[0]) + ')') +
                 ' ' + operator + ' ' +
                 (isString(args[1]) ? this.toEntity(args[1]) : '(' + this.toExpression(args[1]) + ')');
      // Unary operators
      case '!':
        return '!(' + this.toExpression(args[0]) + ')';
      // IN and NOT IN
      case 'notin':
        operator = 'NOT IN';
      case 'in':
        return this.toExpression(args[0]) + ' ' + operator +
               '(' + (isString(args[1]) ? args[1] : mapJoin(args[1], ', ', this.toExpression, this)) + ')';
      // EXISTS and NOT EXISTS
      case 'notexists':
        operator = 'NOT EXISTS';
      case 'exists':
        return operator + ' ' + this.group(args[0], true);
      // Other expressions
      default:
        return operator + '(' + mapJoin(args, ', ', this.toExpression, this) + ')';
      }
    default:
      throw new Error('Unknown expression type: ' + expr.type);
  }
};

// Converts the parsed entity (or property path) into a SPARQL entity
Generator.prototype.toEntity = function (value) {
  // regular entity
  if (isString(value)) {
    switch (value[0]) {
    // variable, * selector, or blank node
    case '?':
    case '$':
    case '*':
    case '_':
      return value;
    // literal
    case '"':
      var match = value.match(/^"([^]*)"(?:(@.+)|\^\^(.+))?$/) || {},
          lexical = match[1] || '', language = match[2] || '', datatype = match[3];
      value = '"' + lexical.replace(escape, escapeReplacer) + '"' + language;
      if (datatype) {
        if (datatype === XSD_INTEGER && /^\d+$/.test(lexical))
          // Add space to avoid confusion with decimals in broken parsers
          return lexical + ' ';
        value += '^^' + this.encodeIRI(datatype);
      }
      return value;
    // IRI
    default:
      return this.encodeIRI(value);
    }
  }
  // property path
  else {
    var items = value.items.map(this.toEntity, this), path = value.pathType;
    switch (path) {
    // prefix operator
    case '^':
    case '!':
      return path + items[0];
    // postfix operator
    case '*':
    case '+':
    case '?':
      return '(' + items[0] + path + ')';
    // infix operator
    default:
      return '(' + items.join(path) + ')';
    }
  }
};
var escape = /["\\\t\n\r\b\f]/g,
    escapeReplacer = function (c) { return escapeReplacements[c]; },
    escapeReplacements = { '\\': '\\\\', '"': '\\"', '\t': '\\t',
                           '\n': '\\n', '\r': '\\r', '\b': '\\b', '\f': '\\f' };

// Represent the IRI, as a prefixed name when possible
Generator.prototype.encodeIRI = function (iri) {
  var prefixMatch = this._prefixRegex.exec(iri);
  if (prefixMatch) {
    var prefix = this._prefixByIri[prefixMatch[1]];
    this._usedPrefixes[prefix] = true;
    return prefix + ':' + prefixMatch[2];
  }
  return '<' + iri + '>';
};

// Converts the parsed update object into a SPARQL update clause
Generator.prototype.toUpdate = function (update) {
  switch (update.type || update.updateType) {
  case 'load':
    return 'LOAD' + (update.source ? ' ' + this.toEntity(update.source) : '') +
           (update.destination ? ' INTO GRAPH ' + this.toEntity(update.destination) : '');
  case 'insert':
    return 'INSERT DATA '  + this.group(update.insert, true);
  case 'delete':
    return 'DELETE DATA '  + this.group(update.delete, true);
  case 'deletewhere':
    return 'DELETE WHERE ' + this.group(update.delete, true);
  case 'insertdelete':
    return (update.graph ? 'WITH ' + this.toEntity(update.graph) + this._newline : '') +
           (update.delete.length ? 'DELETE ' + this.group(update.delete, true) + this._newline : '') +
           (update.insert.length ? 'INSERT ' + this.group(update.insert, true) + this._newline : '') +
           'WHERE ' + this.group(update.where, true);
  case 'add':
  case 'copy':
  case 'move':
    return update.type.toUpperCase() + (update.source.default ? ' DEFAULT ' : ' ') +
           'TO ' + this.toEntity(update.destination.name);
  case 'create':
  case 'clear':
  case 'drop':
    return update.type.toUpperCase() + (update.silent ? ' SILENT ' : ' ') + (
      update.graph.default ? 'DEFAULT' :
      update.graph.named ? 'NAMED' :
      update.graph.all ? 'ALL' :
      ('GRAPH ' + this.toEntity(update.graph.name))
    );
  default:
    throw new Error('Unknown update query type: ' + update.type);
  }
};

// Indents each line of the string
Generator.prototype.indent = function(text) { return text.replace(/^/gm, this._indent); }

// Checks whether the object is a string
function isString(object) { return typeof object === 'string'; }

// Maps the array with the given function, and joins the results using the separator
function mapJoin(array, sep, func, self) {
  return array.map(func, self).join(isString(sep) ? sep : ' ');
}

/**
 * @param options {
 *   allPrefixes: boolean,
 *   indentation: string,
 *   newline: string
 * }
 */
module.exports = function SparqlGenerator(options) {
  return {
    stringify: function (q) { return new Generator(options, q.prefixes).toQuery(q); }
  };
};


/***/ }),

/***/ "../sparql-builder/node_modules/sparqljs/lib/SparqlParser.js":
/*!*******************************************************************!*\
  !*** ../sparql-builder/node_modules/sparqljs/lib/SparqlParser.js ***!
  \*******************************************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

/* WEBPACK VAR INJECTION */(function(process, module) {/* parser generated by jison 0.4.18 */
/*
  Returns a Parser object of the following structure:

  Parser: {
    yy: {}
  }

  Parser.prototype: {
    yy: {},
    trace: function(),
    symbols_: {associative list: name ==> number},
    terminals_: {associative list: number ==> name},
    productions_: [...],
    performAction: function anonymous(yytext, yyleng, yylineno, yy, yystate, $$, _$),
    table: [...],
    defaultActions: {...},
    parseError: function(str, hash),
    parse: function(input),

    lexer: {
        EOF: 1,
        parseError: function(str, hash),
        setInput: function(input),
        input: function(),
        unput: function(str),
        more: function(),
        less: function(n),
        pastInput: function(),
        upcomingInput: function(),
        showPosition: function(),
        test_match: function(regex_match_array, rule_index),
        next: function(),
        lex: function(),
        begin: function(condition),
        popState: function(),
        _currentRules: function(),
        topState: function(),
        pushState: function(condition),

        options: {
            ranges: boolean           (optional: true ==> token location info will include a .range[] member)
            flex: boolean             (optional: true ==> flex-like lexing behaviour where the rules are tested exhaustively to find the longest match)
            backtrack_lexer: boolean  (optional: true ==> lexer regexes are tested in order and for each matching regex the action code is invoked; the lexer terminates the scan when a token is returned by the action code)
        },

        performAction: function(yy, yy_, $avoiding_name_collisions, YY_START),
        rules: [...],
        conditions: {associative list: name ==> set},
    }
  }


  token location info (@$, _$, etc.): {
    first_line: n,
    last_line: n,
    first_column: n,
    last_column: n,
    range: [start_number, end_number]       (where the numbers are indexes into the input string, regular zero-based)
  }


  the parseError function receives a 'hash' object with these members for lexer and parser errors: {
    text:        (matched text)
    token:       (the produced terminal token, if any)
    line:        (yylineno)
  }
  while parser (grammar) errors will also provide these members, i.e. parser errors deliver a superset of attributes: {
    loc:         (yylloc)
    expected:    (string describing the set of expected tokens)
    recoverable: (boolean: TRUE when the parser has a error recovery rule available for this particular error)
  }
*/
var SparqlParser = (function(){
var o=function(k,v,o,l){for(o=o||{},l=k.length;l--;o[k[l]]=v);return o},$V0=[6,12,15,24,34,43,48,99,109,112,114,115,124,125,130,298,299,300,301,302],$V1=[2,196],$V2=[99,109,112,114,115,124,125,130,298,299,300,301,302],$V3=[1,18],$V4=[1,27],$V5=[6,83],$V6=[38,39,51],$V7=[38,51],$V8=[1,55],$V9=[1,57],$Va=[1,53],$Vb=[1,56],$Vc=[28,29,293],$Vd=[13,16,286],$Ve=[111,133,296,303],$Vf=[13,16,111,133,286],$Vg=[1,80],$Vh=[1,84],$Vi=[1,86],$Vj=[111,133,296,297,303],$Vk=[13,16,111,133,286,297],$Vl=[1,92],$Vm=[2,236],$Vn=[1,91],$Vo=[13,16,28,29,80,86,215,218,219,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286],$Vp=[6,38,39,51,61,68,71,79,81,83],$Vq=[6,13,16,28,38,39,51,61,68,71,79,81,83,286],$Vr=[6,13,16,28,29,31,32,38,39,41,51,61,68,71,79,80,81,83,86,92,108,111,124,125,127,132,159,160,162,165,166,183,187,208,213,215,216,218,219,223,227,231,246,251,268,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,293,304,306,307,309,310,311,312,313,314,315,316],$Vs=[1,107],$Vt=[1,108],$Vu=[6,13,16,28,29,39,41,80,83,86,111,159,160,162,165,166,215,218,219,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,304],$Vv=[2,295],$Vw=[1,125],$Vx=[1,123],$Vy=[6,183],$Vz=[2,312],$VA=[2,300],$VB=[38,127],$VC=[6,41,68,71,79,81,83],$VD=[2,238],$VE=[1,139],$VF=[1,141],$VG=[1,151],$VH=[1,157],$VI=[1,160],$VJ=[1,156],$VK=[1,158],$VL=[1,154],$VM=[1,155],$VN=[1,161],$VO=[1,162],$VP=[1,165],$VQ=[1,166],$VR=[1,167],$VS=[1,168],$VT=[1,169],$VU=[1,170],$VV=[1,171],$VW=[1,172],$VX=[1,173],$VY=[1,174],$VZ=[1,175],$V_=[1,176],$V$=[6,61,68,71,79,81,83],$V01=[28,29,38,39,51],$V11=[13,16,28,29,80,248,249,250,252,254,255,257,258,261,263,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,316,317,318,319,320,321],$V21=[2,409],$V31=[1,189],$V41=[1,190],$V51=[1,191],$V61=[13,16,41,80,92,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286],$V71=[41,86],$V81=[28,32],$V91=[6,108,183],$Va1=[41,111],$Vb1=[6,41,71,79,81,83],$Vc1=[2,324],$Vd1=[2,316],$Ve1=[1,226],$Vf1=[1,228],$Vg1=[41,111,304],$Vh1=[13,16,28,29,32,39,41,80,83,86,111,159,160,162,165,166,183,187,208,213,215,216,218,219,251,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,304],$Vi1=[13,16,28,29,31,32,39,41,80,83,86,92,111,159,160,162,165,166,183,187,208,213,215,216,218,219,223,227,231,246,251,268,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,293,304,307,310,311,312,313,314,315,316],$Vj1=[13,16,28,29,31,32,39,41,80,83,86,92,111,159,160,162,165,166,183,187,208,213,215,216,218,219,223,227,231,246,251,268,270,271,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,293,304,307,310,311,312,313,314,315,316],$Vk1=[31,32,183,223,251],$Vl1=[31,32,183,223,227,251],$Vm1=[31,32,183,223,227,231,246,251,268,280,281,282,283,284,285,310,311,312,313,314,315,316],$Vn1=[31,32,183,223,227,231,246,251,268,280,281,282,283,284,285,293,307,310,311,312,313,314,315,316],$Vo1=[1,260],$Vp1=[1,261],$Vq1=[1,263],$Vr1=[1,264],$Vs1=[1,265],$Vt1=[1,266],$Vu1=[1,268],$Vv1=[1,269],$Vw1=[2,416],$Vx1=[1,271],$Vy1=[1,272],$Vz1=[1,273],$VA1=[1,279],$VB1=[1,274],$VC1=[1,275],$VD1=[1,276],$VE1=[1,277],$VF1=[1,278],$VG1=[1,286],$VH1=[1,299],$VI1=[6,41,79,81,83],$VJ1=[1,316],$VK1=[1,315],$VL1=[39,41,83,111,159,160,162,165,166],$VM1=[1,324],$VN1=[1,325],$VO1=[41,111,183,216,304],$VP1=[2,354],$VQ1=[13,16,28,29,32,80,86,215,218,219,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286],$VR1=[13,16,28,29,32,39,41,80,83,86,111,159,160,162,165,166,183,215,216,218,219,251,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,304],$VS1=[13,16,28,29,80,208,246,248,249,250,252,254,255,257,258,261,263,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,310,316,317,318,319,320,321],$VT1=[1,349],$VU1=[1,350],$VV1=[1,352],$VW1=[1,351],$VX1=[6,13,16,28,29,31,32,39,41,68,71,74,76,79,80,81,83,86,111,159,160,162,165,166,183,215,218,219,223,227,231,246,248,249,250,251,252,254,255,257,258,261,263,268,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,293,304,307,310,311,312,313,314,315,316,317,318,319,320,321],$VY1=[1,360],$VZ1=[1,359],$V_1=[29,86],$V$1=[13,16,32,41,80,92,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286],$V02=[29,41],$V12=[2,315],$V22=[6,41,83],$V32=[6,13,16,29,41,71,79,81,83,248,249,250,252,254,255,257,258,261,263,286,316,317,318,319,320,321],$V42=[6,13,16,28,29,39,41,71,74,76,79,80,81,83,86,111,159,160,162,165,166,215,218,219,248,249,250,252,254,255,257,258,261,263,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,304,316,317,318,319,320,321],$V52=[6,13,16,28,29,41,68,71,79,81,83,248,249,250,252,254,255,257,258,261,263,286,316,317,318,319,320,321],$V62=[6,13,16,28,29,31,32,39,41,61,68,71,74,76,79,80,81,83,86,111,159,160,162,165,166,183,215,218,219,223,227,231,246,248,249,250,251,252,254,255,257,258,261,263,268,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,293,304,305,307,310,311,312,313,314,315,316,317,318,319,320,321],$V72=[13,16,29,187,208,213,286],$V82=[2,366],$V92=[1,401],$Va2=[39,41,83,111,159,160,162,165,166,304],$Vb2=[13,16,28,29,32,39,41,80,83,86,111,159,160,162,165,166,183,187,215,216,218,219,251,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,304],$Vc2=[13,16,28,29,80,208,246,248,249,250,252,254,255,257,258,261,263,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,293,310,316,317,318,319,320,321],$Vd2=[1,450],$Ve2=[1,447],$Vf2=[1,448],$Vg2=[13,16,28,29,39,41,80,83,86,111,159,160,162,165,166,215,218,219,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286],$Vh2=[13,16,28,286],$Vi2=[13,16,28,29,39,41,80,83,86,111,159,160,162,165,166,215,218,219,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,304],$Vj2=[2,327],$Vk2=[39,41,83,111,159,160,162,165,166,183,216,304],$Vl2=[6,13,16,28,29,41,74,76,79,81,83,248,249,250,252,254,255,257,258,261,263,286,316,317,318,319,320,321],$Vm2=[2,322],$Vn2=[13,16,29,187,208,286],$Vo2=[13,16,32,80,92,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286],$Vp2=[13,16,28,29,41,80,86,111,215,218,219,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286],$Vq2=[13,16,28,29,32,80,86,215,218,219,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,306,307],$Vr2=[13,16,28,29,32,80,86,215,218,219,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,293,306,307,309,310],$Vs2=[1,561],$Vt2=[1,562],$Vu2=[2,310],$Vv2=[13,16,32,187,213,286];
var parser = {trace: function trace () { },
yy: {},
symbols_: {"error":2,"QueryOrUpdate":3,"Prologue":4,"QueryOrUpdate_group0":5,"EOF":6,"Prologue_repetition0":7,"Query":8,"Query_group0":9,"Query_option0":10,"BaseDecl":11,"BASE":12,"IRIREF":13,"PrefixDecl":14,"PREFIX":15,"PNAME_NS":16,"SelectQuery":17,"SelectClause":18,"SelectQuery_repetition0":19,"WhereClause":20,"SolutionModifier":21,"SubSelect":22,"SubSelect_option0":23,"SELECT":24,"SelectClause_option0":25,"SelectClause_group0":26,"SelectClauseItem":27,"VAR":28,"(":29,"Expression":30,"AS":31,")":32,"ConstructQuery":33,"CONSTRUCT":34,"ConstructTemplate":35,"ConstructQuery_repetition0":36,"ConstructQuery_repetition1":37,"WHERE":38,"{":39,"ConstructQuery_option0":40,"}":41,"DescribeQuery":42,"DESCRIBE":43,"DescribeQuery_group0":44,"DescribeQuery_repetition0":45,"DescribeQuery_option0":46,"AskQuery":47,"ASK":48,"AskQuery_repetition0":49,"DatasetClause":50,"FROM":51,"DatasetClause_option0":52,"iri":53,"WhereClause_option0":54,"GroupGraphPattern":55,"SolutionModifier_option0":56,"SolutionModifier_option1":57,"SolutionModifier_option2":58,"SolutionModifier_option3":59,"GroupClause":60,"GROUP":61,"BY":62,"GroupClause_repetition_plus0":63,"GroupCondition":64,"BuiltInCall":65,"FunctionCall":66,"HavingClause":67,"HAVING":68,"HavingClause_repetition_plus0":69,"OrderClause":70,"ORDER":71,"OrderClause_repetition_plus0":72,"OrderCondition":73,"ASC":74,"BrackettedExpression":75,"DESC":76,"Constraint":77,"LimitOffsetClauses":78,"LIMIT":79,"INTEGER":80,"OFFSET":81,"ValuesClause":82,"VALUES":83,"InlineData":84,"InlineData_repetition0":85,"NIL":86,"InlineData_repetition1":87,"InlineData_repetition_plus2":88,"InlineData_repetition3":89,"DataBlockValue":90,"Literal":91,"UNDEF":92,"DataBlockValueList":93,"DataBlockValueList_repetition_plus0":94,"Update":95,"Update_repetition0":96,"Update1":97,"Update_option0":98,"LOAD":99,"Update1_option0":100,"Update1_option1":101,"Update1_group0":102,"Update1_option2":103,"GraphRefAll":104,"Update1_group1":105,"Update1_option3":106,"GraphOrDefault":107,"TO":108,"CREATE":109,"Update1_option4":110,"GRAPH":111,"INSERTDATA":112,"QuadPattern":113,"DELETEDATA":114,"DELETEWHERE":115,"Update1_option5":116,"InsertClause":117,"Update1_option6":118,"Update1_repetition0":119,"Update1_option7":120,"DeleteClause":121,"Update1_option8":122,"Update1_repetition1":123,"DELETE":124,"INSERT":125,"UsingClause":126,"USING":127,"UsingClause_option0":128,"WithClause":129,"WITH":130,"IntoGraphClause":131,"INTO":132,"DEFAULT":133,"GraphOrDefault_option0":134,"GraphRefAll_group0":135,"QuadPattern_option0":136,"QuadPattern_repetition0":137,"QuadsNotTriples":138,"QuadsNotTriples_group0":139,"QuadsNotTriples_option0":140,"QuadsNotTriples_option1":141,"QuadsNotTriples_option2":142,"TriplesTemplate":143,"TriplesTemplate_repetition0":144,"TriplesSameSubject":145,"TriplesTemplate_option0":146,"GroupGraphPatternSub":147,"GroupGraphPatternSub_option0":148,"GroupGraphPatternSub_repetition0":149,"GroupGraphPatternSubTail":150,"GraphPatternNotTriples":151,"GroupGraphPatternSubTail_option0":152,"GroupGraphPatternSubTail_option1":153,"TriplesBlock":154,"TriplesBlock_repetition0":155,"TriplesSameSubjectPath":156,"TriplesBlock_option0":157,"GraphPatternNotTriples_repetition0":158,"OPTIONAL":159,"MINUS":160,"GraphPatternNotTriples_group0":161,"SERVICE":162,"GraphPatternNotTriples_option0":163,"GraphPatternNotTriples_group1":164,"FILTER":165,"BIND":166,"FunctionCall_option0":167,"FunctionCall_repetition0":168,"ExpressionList":169,"ExpressionList_repetition0":170,"ConstructTemplate_option0":171,"ConstructTriples":172,"ConstructTriples_repetition0":173,"ConstructTriples_option0":174,"VarOrTerm":175,"PropertyListNotEmpty":176,"TriplesNode":177,"PropertyList":178,"PropertyList_option0":179,"VerbObjectList":180,"PropertyListNotEmpty_repetition0":181,"SemiOptionalVerbObjectList":182,";":183,"SemiOptionalVerbObjectList_option0":184,"Verb":185,"ObjectList":186,"a":187,"ObjectList_repetition0":188,"GraphNode":189,"PropertyListPathNotEmpty":190,"TriplesNodePath":191,"TriplesSameSubjectPath_option0":192,"PropertyListPathNotEmpty_group0":193,"PropertyListPathNotEmpty_repetition0":194,"GraphNodePath":195,"PropertyListPathNotEmpty_repetition1":196,"PropertyListPathNotEmptyTail":197,"PropertyListPathNotEmptyTail_group0":198,"Path":199,"Path_repetition0":200,"PathSequence":201,"PathSequence_repetition0":202,"PathEltOrInverse":203,"PathElt":204,"PathPrimary":205,"PathElt_option0":206,"PathEltOrInverse_option0":207,"!":208,"PathNegatedPropertySet":209,"PathOneInPropertySet":210,"PathNegatedPropertySet_repetition0":211,"PathNegatedPropertySet_option0":212,"^":213,"TriplesNode_repetition_plus0":214,"[":215,"]":216,"TriplesNodePath_repetition_plus0":217,"BLANK_NODE_LABEL":218,"ANON":219,"ConditionalAndExpression":220,"Expression_repetition0":221,"ExpressionTail":222,"||":223,"RelationalExpression":224,"ConditionalAndExpression_repetition0":225,"ConditionalAndExpressionTail":226,"&&":227,"AdditiveExpression":228,"RelationalExpression_group0":229,"RelationalExpression_option0":230,"IN":231,"MultiplicativeExpression":232,"AdditiveExpression_repetition0":233,"AdditiveExpressionTail":234,"AdditiveExpressionTail_group0":235,"NumericLiteralPositive":236,"AdditiveExpressionTail_repetition0":237,"NumericLiteralNegative":238,"AdditiveExpressionTail_repetition1":239,"UnaryExpression":240,"MultiplicativeExpression_repetition0":241,"MultiplicativeExpressionTail":242,"MultiplicativeExpressionTail_group0":243,"UnaryExpression_option0":244,"PrimaryExpression":245,"-":246,"Aggregate":247,"FUNC_ARITY0":248,"FUNC_ARITY1":249,"FUNC_ARITY2":250,",":251,"IF":252,"BuiltInCall_group0":253,"BOUND":254,"BNODE":255,"BuiltInCall_option0":256,"EXISTS":257,"COUNT":258,"Aggregate_option0":259,"Aggregate_group0":260,"FUNC_AGGREGATE":261,"Aggregate_option1":262,"GROUP_CONCAT":263,"Aggregate_option2":264,"Aggregate_option3":265,"GroupConcatSeparator":266,"SEPARATOR":267,"=":268,"String":269,"LANGTAG":270,"^^":271,"DECIMAL":272,"DOUBLE":273,"true":274,"false":275,"STRING_LITERAL1":276,"STRING_LITERAL2":277,"STRING_LITERAL_LONG1":278,"STRING_LITERAL_LONG2":279,"INTEGER_POSITIVE":280,"DECIMAL_POSITIVE":281,"DOUBLE_POSITIVE":282,"INTEGER_NEGATIVE":283,"DECIMAL_NEGATIVE":284,"DOUBLE_NEGATIVE":285,"PNAME_LN":286,"QueryOrUpdate_group0_option0":287,"Prologue_repetition0_group0":288,"SelectClause_option0_group0":289,"DISTINCT":290,"REDUCED":291,"SelectClause_group0_repetition_plus0":292,"*":293,"DescribeQuery_group0_repetition_plus0_group0":294,"DescribeQuery_group0_repetition_plus0":295,"NAMED":296,"SILENT":297,"CLEAR":298,"DROP":299,"ADD":300,"MOVE":301,"COPY":302,"ALL":303,".":304,"UNION":305,"|":306,"/":307,"PathElt_option0_group0":308,"?":309,"+":310,"!=":311,"<":312,">":313,"<=":314,">=":315,"NOT":316,"CONCAT":317,"COALESCE":318,"SUBSTR":319,"REGEX":320,"REPLACE":321,"$accept":0,"$end":1},
terminals_: {2:"error",6:"EOF",12:"BASE",13:"IRIREF",15:"PREFIX",16:"PNAME_NS",24:"SELECT",28:"VAR",29:"(",31:"AS",32:")",34:"CONSTRUCT",38:"WHERE",39:"{",41:"}",43:"DESCRIBE",48:"ASK",51:"FROM",61:"GROUP",62:"BY",68:"HAVING",71:"ORDER",74:"ASC",76:"DESC",79:"LIMIT",80:"INTEGER",81:"OFFSET",83:"VALUES",86:"NIL",92:"UNDEF",99:"LOAD",108:"TO",109:"CREATE",111:"GRAPH",112:"INSERTDATA",114:"DELETEDATA",115:"DELETEWHERE",124:"DELETE",125:"INSERT",127:"USING",130:"WITH",132:"INTO",133:"DEFAULT",159:"OPTIONAL",160:"MINUS",162:"SERVICE",165:"FILTER",166:"BIND",183:";",187:"a",208:"!",213:"^",215:"[",216:"]",218:"BLANK_NODE_LABEL",219:"ANON",223:"||",227:"&&",231:"IN",246:"-",248:"FUNC_ARITY0",249:"FUNC_ARITY1",250:"FUNC_ARITY2",251:",",252:"IF",254:"BOUND",255:"BNODE",257:"EXISTS",258:"COUNT",261:"FUNC_AGGREGATE",263:"GROUP_CONCAT",267:"SEPARATOR",268:"=",270:"LANGTAG",271:"^^",272:"DECIMAL",273:"DOUBLE",274:"true",275:"false",276:"STRING_LITERAL1",277:"STRING_LITERAL2",278:"STRING_LITERAL_LONG1",279:"STRING_LITERAL_LONG2",280:"INTEGER_POSITIVE",281:"DECIMAL_POSITIVE",282:"DOUBLE_POSITIVE",283:"INTEGER_NEGATIVE",284:"DECIMAL_NEGATIVE",285:"DOUBLE_NEGATIVE",286:"PNAME_LN",290:"DISTINCT",291:"REDUCED",293:"*",296:"NAMED",297:"SILENT",298:"CLEAR",299:"DROP",300:"ADD",301:"MOVE",302:"COPY",303:"ALL",304:".",305:"UNION",306:"|",307:"/",309:"?",310:"+",311:"!=",312:"<",313:">",314:"<=",315:">=",316:"NOT",317:"CONCAT",318:"COALESCE",319:"SUBSTR",320:"REGEX",321:"REPLACE"},
productions_: [0,[3,3],[4,1],[8,2],[11,2],[14,3],[17,4],[22,4],[18,3],[27,1],[27,5],[33,5],[33,7],[42,5],[47,4],[50,3],[20,2],[21,4],[60,3],[64,1],[64,1],[64,3],[64,5],[64,1],[67,2],[70,3],[73,2],[73,2],[73,1],[73,1],[78,2],[78,2],[78,4],[78,4],[82,2],[84,4],[84,4],[84,6],[90,1],[90,1],[90,1],[93,3],[95,3],[97,4],[97,3],[97,5],[97,4],[97,2],[97,2],[97,2],[97,6],[97,6],[121,2],[117,2],[126,3],[129,2],[131,3],[107,1],[107,2],[104,2],[104,1],[113,4],[138,7],[143,3],[55,3],[55,3],[147,2],[150,3],[154,3],[151,2],[151,2],[151,2],[151,3],[151,4],[151,2],[151,6],[151,1],[77,1],[77,1],[77,1],[66,2],[66,6],[169,1],[169,4],[35,3],[172,3],[145,2],[145,2],[178,1],[176,2],[182,2],[180,2],[185,1],[185,1],[185,1],[186,2],[156,2],[156,2],[190,4],[197,1],[197,3],[199,2],[201,2],[204,2],[203,2],[205,1],[205,1],[205,2],[205,3],[209,1],[209,1],[209,4],[210,1],[210,1],[210,2],[210,2],[177,3],[177,3],[191,3],[191,3],[189,1],[189,1],[195,1],[195,1],[175,1],[175,1],[175,1],[175,1],[175,1],[175,1],[30,2],[222,2],[220,2],[226,2],[224,1],[224,3],[224,4],[228,2],[234,2],[234,2],[234,2],[232,2],[242,2],[240,2],[240,2],[240,2],[245,1],[245,1],[245,1],[245,1],[245,1],[245,1],[75,3],[65,1],[65,2],[65,4],[65,6],[65,8],[65,2],[65,4],[65,2],[65,4],[65,3],[247,5],[247,5],[247,6],[266,4],[91,1],[91,2],[91,3],[91,1],[91,1],[91,1],[91,1],[91,1],[91,1],[91,1],[269,1],[269,1],[269,1],[269,1],[236,1],[236,1],[236,1],[238,1],[238,1],[238,1],[53,1],[53,1],[53,1],[287,0],[287,1],[5,1],[5,1],[288,1],[288,1],[7,0],[7,2],[9,1],[9,1],[9,1],[9,1],[10,0],[10,1],[19,0],[19,2],[23,0],[23,1],[289,1],[289,1],[25,0],[25,1],[292,1],[292,2],[26,1],[26,1],[36,0],[36,2],[37,0],[37,2],[40,0],[40,1],[294,1],[294,1],[295,1],[295,2],[44,1],[44,1],[45,0],[45,2],[46,0],[46,1],[49,0],[49,2],[52,0],[52,1],[54,0],[54,1],[56,0],[56,1],[57,0],[57,1],[58,0],[58,1],[59,0],[59,1],[63,1],[63,2],[69,1],[69,2],[72,1],[72,2],[85,0],[85,2],[87,0],[87,2],[88,1],[88,2],[89,0],[89,2],[94,1],[94,2],[96,0],[96,4],[98,0],[98,2],[100,0],[100,1],[101,0],[101,1],[102,1],[102,1],[103,0],[103,1],[105,1],[105,1],[105,1],[106,0],[106,1],[110,0],[110,1],[116,0],[116,1],[118,0],[118,1],[119,0],[119,2],[120,0],[120,1],[122,0],[122,1],[123,0],[123,2],[128,0],[128,1],[134,0],[134,1],[135,1],[135,1],[135,1],[136,0],[136,1],[137,0],[137,2],[139,1],[139,1],[140,0],[140,1],[141,0],[141,1],[142,0],[142,1],[144,0],[144,3],[146,0],[146,1],[148,0],[148,1],[149,0],[149,2],[152,0],[152,1],[153,0],[153,1],[155,0],[155,3],[157,0],[157,1],[158,0],[158,3],[161,1],[161,1],[163,0],[163,1],[164,1],[164,1],[167,0],[167,1],[168,0],[168,3],[170,0],[170,3],[171,0],[171,1],[173,0],[173,3],[174,0],[174,1],[179,0],[179,1],[181,0],[181,2],[184,0],[184,1],[188,0],[188,3],[192,0],[192,1],[193,1],[193,1],[194,0],[194,3],[196,0],[196,2],[198,1],[198,1],[200,0],[200,3],[202,0],[202,3],[308,1],[308,1],[308,1],[206,0],[206,1],[207,0],[207,1],[211,0],[211,3],[212,0],[212,1],[214,1],[214,2],[217,1],[217,2],[221,0],[221,2],[225,0],[225,2],[229,1],[229,1],[229,1],[229,1],[229,1],[229,1],[230,0],[230,1],[233,0],[233,2],[235,1],[235,1],[237,0],[237,2],[239,0],[239,2],[241,0],[241,2],[243,1],[243,1],[244,0],[244,1],[253,1],[253,1],[253,1],[253,1],[253,1],[256,0],[256,1],[259,0],[259,1],[260,1],[260,1],[262,0],[262,1],[264,0],[264,1],[265,0],[265,1]],
performAction: function anonymous(yytext, yyleng, yylineno, yy, yystate /* action[1] */, $$ /* vstack */, _$ /* lstack */) {
/* this == yyval */

var $0 = $$.length - 1;
switch (yystate) {
case 1:

      $$[$0-1] = $$[$0-1] || {};
      if (Parser.base)
        $$[$0-1].base = Parser.base;
      Parser.base = base = basePath = baseRoot = '';
      $$[$0-1].prefixes = Parser.prefixes;
      Parser.prefixes = null;
      return $$[$0-1];
    
break;
case 3:
this.$ = extend($$[$0-1], $$[$0], { type: 'query' });
break;
case 4:

      Parser.base = resolveIRI($$[$0])
      base = basePath = baseRoot = '';
    
break;
case 5:

      if (!Parser.prefixes) Parser.prefixes = {};
      $$[$0-1] = $$[$0-1].substr(0, $$[$0-1].length - 1);
      $$[$0] = resolveIRI($$[$0]);
      Parser.prefixes[$$[$0-1]] = $$[$0];
    
break;
case 6:
this.$ = extend($$[$0-3], groupDatasets($$[$0-2]), $$[$0-1], $$[$0]);
break;
case 7:
this.$ = extend($$[$0-3], $$[$0-2], $$[$0-1], $$[$0], { type: 'query' });
break;
case 8:
this.$ = extend({ queryType: 'SELECT', variables: $$[$0] === '*' ? ['*'] : $$[$0] }, $$[$0-1] && ($$[$0-2] = lowercase($$[$0-1]), $$[$0-1] = {}, $$[$0-1][$$[$0-2]] = true, $$[$0-1]));
break;
case 9: case 92: case 124: case 151:
this.$ = toVar($$[$0]);
break;
case 10: case 22:
this.$ = expression($$[$0-3], { variable: toVar($$[$0-1]) });
break;
case 11:
this.$ = extend({ queryType: 'CONSTRUCT', template: $$[$0-3] }, groupDatasets($$[$0-2]), $$[$0-1], $$[$0]);
break;
case 12:
this.$ = extend({ queryType: 'CONSTRUCT', template: $$[$0-2] = ($$[$0-2] ? $$[$0-2].triples : []) }, groupDatasets($$[$0-5]), { where: [ { type: 'bgp', triples: appendAllTo([], $$[$0-2]) } ] }, $$[$0]);
break;
case 13:
this.$ = extend({ queryType: 'DESCRIBE', variables: $$[$0-3] === '*' ? ['*'] : $$[$0-3].map(toVar) }, groupDatasets($$[$0-2]), $$[$0-1], $$[$0]);
break;
case 14:
this.$ = extend({ queryType: 'ASK' }, groupDatasets($$[$0-2]), $$[$0-1], $$[$0]);
break;
case 15: case 54:
this.$ = { iri: $$[$0], named: !!$$[$0-1] };
break;
case 16:
this.$ = { where: $$[$0].patterns };
break;
case 17:
this.$ = extend($$[$0-3], $$[$0-2], $$[$0-1], $$[$0]);
break;
case 18:
this.$ = { group: $$[$0] };
break;
case 19: case 20: case 26: case 28:
this.$ = expression($$[$0]);
break;
case 21:
this.$ = expression($$[$0-1]);
break;
case 23: case 29:
this.$ = expression(toVar($$[$0]));
break;
case 24:
this.$ = { having: $$[$0] };
break;
case 25:
this.$ = { order: $$[$0] };
break;
case 27:
this.$ = expression($$[$0], { descending: true });
break;
case 30:
this.$ = { limit:  toInt($$[$0]) };
break;
case 31:
this.$ = { offset: toInt($$[$0]) };
break;
case 32:
this.$ = { limit: toInt($$[$0-2]), offset: toInt($$[$0]) };
break;
case 33:
this.$ = { limit: toInt($$[$0]), offset: toInt($$[$0-2]) };
break;
case 34:
this.$ = { type: 'values', values: $$[$0] };
break;
case 35:

      $$[$0-3] = toVar($$[$0-3]);
      this.$ = $$[$0-1].map(function(v) { var o = {}; o[$$[$0-3]] = v; return o; })
    
break;
case 36:

      this.$ = $$[$0-1].map(function() { return {}; })
    
break;
case 37:

      var length = $$[$0-4].length;
      $$[$0-4] = $$[$0-4].map(toVar);
      this.$ = $$[$0-1].map(function (values) {
        if (values.length !== length)
          throw Error('Inconsistent VALUES length');
        var valuesObject = {};
        for(var i = 0; i<length; i++)
          valuesObject[$$[$0-4][i]] = values[i];
        return valuesObject;
      });
    
break;
case 40:
this.$ = undefined;
break;
case 41: case 84: case 108: case 152:
this.$ = $$[$0-1];
break;
case 42:
this.$ = { type: 'update', updates: appendTo($$[$0-2], $$[$0-1]) };
break;
case 43:
this.$ = extend({ type: 'load', silent: !!$$[$0-2], source: $$[$0-1] }, $$[$0] && { destination: $$[$0] });
break;
case 44:
this.$ = { type: lowercase($$[$0-2]), silent: !!$$[$0-1], graph: $$[$0] };
break;
case 45:
this.$ = { type: lowercase($$[$0-4]), silent: !!$$[$0-3], source: $$[$0-2], destination: $$[$0] };
break;
case 46:
this.$ = { type: 'create', silent: !!$$[$0-2], graph: { type: 'graph', name: $$[$0] } };
break;
case 47:
this.$ = { updateType: 'insert',      insert: $$[$0] };
break;
case 48:
this.$ = { updateType: 'delete',      delete: $$[$0] };
break;
case 49:
this.$ = { updateType: 'deletewhere', delete: $$[$0] };
break;
case 50:
this.$ = extend({ updateType: 'insertdelete' }, $$[$0-5], { insert: $$[$0-4] || [] }, { delete: $$[$0-3] || [] }, groupDatasets($$[$0-2]), { where: $$[$0].patterns });
break;
case 51:
this.$ = extend({ updateType: 'insertdelete' }, $$[$0-5], { delete: $$[$0-4] || [] }, { insert: $$[$0-3] || [] }, groupDatasets($$[$0-2]), { where: $$[$0].patterns });
break;
case 52: case 53: case 56: case 143:
this.$ = $$[$0];
break;
case 55:
this.$ = { graph: $$[$0] };
break;
case 57:
this.$ = { type: 'graph', default: true };
break;
case 58: case 59:
this.$ = { type: 'graph', name: $$[$0] };
break;
case 60:
 this.$ = {}; this.$[lowercase($$[$0])] = true; 
break;
case 61:
this.$ = $$[$0-2] ? unionAll($$[$0-1], [$$[$0-2]]) : unionAll($$[$0-1]);
break;
case 62:

      var graph = extend($$[$0-3] || { triples: [] }, { type: 'graph', name: toVar($$[$0-5]) });
      this.$ = $$[$0] ? [graph, $$[$0]] : [graph];
    
break;
case 63: case 68:
this.$ = { type: 'bgp', triples: unionAll($$[$0-2], [$$[$0-1]]) };
break;
case 64:
this.$ = { type: 'group', patterns: [ $$[$0-1] ] };
break;
case 65:
this.$ = { type: 'group', patterns: $$[$0-1] };
break;
case 66:
this.$ = $$[$0-1] ? unionAll([$$[$0-1]], $$[$0]) : unionAll($$[$0]);
break;
case 67:
this.$ = $$[$0] ? [$$[$0-2], $$[$0]] : $$[$0-2];
break;
case 69:

      if ($$[$0-1].length)
        this.$ = { type: 'union', patterns: unionAll($$[$0-1].map(degroupSingle), [degroupSingle($$[$0])]) };
      else
        this.$ = $$[$0];
    
break;
case 70:
this.$ = extend($$[$0], { type: 'optional' });
break;
case 71:
this.$ = extend($$[$0], { type: 'minus' });
break;
case 72:
this.$ = extend($$[$0], { type: 'graph', name: toVar($$[$0-1]) });
break;
case 73:
this.$ = extend($$[$0], { type: 'service', name: toVar($$[$0-1]), silent: !!$$[$0-2] });
break;
case 74:
this.$ = { type: 'filter', expression: $$[$0] };
break;
case 75:
this.$ = { type: 'bind', variable: toVar($$[$0-1]), expression: $$[$0-3] };
break;
case 80:
this.$ = { type: 'functionCall', function: $$[$0-1], args: [] };
break;
case 81:
this.$ = { type: 'functionCall', function: $$[$0-5], args: appendTo($$[$0-2], $$[$0-1]), distinct: !!$$[$0-3] };
break;
case 82: case 99: case 110: case 196: case 204: case 216: case 218: case 228: case 232: case 252: case 254: case 258: case 262: case 285: case 291: case 302: case 312: case 318: case 324: case 328: case 338: case 340: case 344: case 350: case 354: case 360: case 362: case 366: case 368: case 377: case 385: case 387: case 397: case 401: case 403: case 405:
this.$ = [];
break;
case 83:
this.$ = appendTo($$[$0-2], $$[$0-1]);
break;
case 85:
this.$ = unionAll($$[$0-2], [$$[$0-1]]);
break;
case 86: case 96:
this.$ = $$[$0].map(function (t) { return extend(triple($$[$0-1]), t); });
break;
case 87:
this.$ = appendAllTo($$[$0].map(function (t) { return extend(triple($$[$0-1].entity), t); }), $$[$0-1].triples) /* the subject is a blank node, possibly with more triples */;
break;
case 89:
this.$ = unionAll([$$[$0-1]], $$[$0]);
break;
case 90:
this.$ = unionAll($$[$0]);
break;
case 91:
this.$ = objectListToTriples($$[$0-1], $$[$0]);
break;
case 94: case 106: case 113:
this.$ = RDF_TYPE;
break;
case 95:
this.$ = appendTo($$[$0-1], $$[$0]);
break;
case 97:
this.$ = !$$[$0] ? $$[$0-1].triples : appendAllTo($$[$0].map(function (t) { return extend(triple($$[$0-1].entity), t); }), $$[$0-1].triples) /* the subject is a blank node, possibly with more triples */;
break;
case 98:
this.$ = objectListToTriples(toVar($$[$0-3]), appendTo($$[$0-2], $$[$0-1]), $$[$0]);
break;
case 100:
this.$ = objectListToTriples(toVar($$[$0-1]), $$[$0]);
break;
case 101:
this.$ = $$[$0-1].length ? path('|',appendTo($$[$0-1], $$[$0])) : $$[$0];
break;
case 102:
this.$ = $$[$0-1].length ? path('/', appendTo($$[$0-1], $$[$0])) : $$[$0];
break;
case 103:
this.$ = $$[$0] ? path($$[$0], [$$[$0-1]]) : $$[$0-1];
break;
case 104:
this.$ = $$[$0-1] ? path($$[$0-1], [$$[$0]]) : $$[$0];;
break;
case 107: case 114:
this.$ = path($$[$0-1], [$$[$0]]);
break;
case 111:
this.$ = path('|', appendTo($$[$0-2], $$[$0-1]));
break;
case 115:
this.$ = path($$[$0-1], [RDF_TYPE]);
break;
case 116: case 118:
this.$ = createList($$[$0-1]);
break;
case 117: case 119:
this.$ = createAnonymousObject($$[$0-1]);
break;
case 120:
this.$ = { entity: $$[$0], triples: [] } /* for consistency with TriplesNode */;
break;
case 122:
this.$ = { entity: $$[$0], triples: [] } /* for consistency with TriplesNodePath */;
break;
case 128:
this.$ = blank();
break;
case 129:
this.$ = RDF_NIL;
break;
case 130: case 132: case 137: case 141:
this.$ = createOperationTree($$[$0-1], $$[$0]);
break;
case 131:
this.$ = ['||', $$[$0]];
break;
case 133:
this.$ = ['&&', $$[$0]];
break;
case 135:
this.$ = operation($$[$0-1], [$$[$0-2], $$[$0]]);
break;
case 136:
this.$ = operation($$[$0-2] ? 'notin' : 'in', [$$[$0-3], $$[$0]]);
break;
case 138: case 142:
this.$ = [$$[$0-1], $$[$0]];
break;
case 139:
this.$ = ['+', createOperationTree($$[$0-1], $$[$0])];
break;
case 140:
this.$ = ['-', createOperationTree($$[$0-1].replace('-', ''), $$[$0])];
break;
case 144:
this.$ = operation($$[$0-1], [$$[$0]]);
break;
case 145:
this.$ = operation('UMINUS', [$$[$0]]);
break;
case 154:
this.$ = operation(lowercase($$[$0-1]));
break;
case 155:
this.$ = operation(lowercase($$[$0-3]), [$$[$0-1]]);
break;
case 156:
this.$ = operation(lowercase($$[$0-5]), [$$[$0-3], $$[$0-1]]);
break;
case 157:
this.$ = operation(lowercase($$[$0-7]), [$$[$0-5], $$[$0-3], $$[$0-1]]);
break;
case 158:
this.$ = operation(lowercase($$[$0-1]), $$[$0]);
break;
case 159:
this.$ = operation('bound', [toVar($$[$0-1])]);
break;
case 160:
this.$ = operation($$[$0-1], []);
break;
case 161:
this.$ = operation($$[$0-3], [$$[$0-1]]);
break;
case 162:
this.$ = operation($$[$0-2] ? 'notexists' :'exists', [degroupSingle($$[$0])]);
break;
case 163: case 164:
this.$ = expression($$[$0-1], { type: 'aggregate', aggregation: lowercase($$[$0-4]), distinct: !!$$[$0-2] });
break;
case 165:
this.$ = expression($$[$0-2], { type: 'aggregate', aggregation: lowercase($$[$0-5]), distinct: !!$$[$0-3], separator: $$[$0-1] || ' ' });
break;
case 166:
this.$ = $$[$0].substr(1, $$[$0].length - 2);
break;
case 168:
this.$ = $$[$0-1] + lowercase($$[$0]);
break;
case 169:
this.$ = $$[$0-2] + '^^' + $$[$0];
break;
case 170: case 184:
this.$ = createLiteral($$[$0], XSD_INTEGER);
break;
case 171: case 185:
this.$ = createLiteral($$[$0], XSD_DECIMAL);
break;
case 172: case 186:
this.$ = createLiteral(lowercase($$[$0]), XSD_DOUBLE);
break;
case 175:
this.$ = XSD_TRUE;
break;
case 176:
this.$ = XSD_FALSE;
break;
case 177: case 178:
this.$ = unescapeString($$[$0], 1);
break;
case 179: case 180:
this.$ = unescapeString($$[$0], 3);
break;
case 181:
this.$ = createLiteral($$[$0].substr(1), XSD_INTEGER);
break;
case 182:
this.$ = createLiteral($$[$0].substr(1), XSD_DECIMAL);
break;
case 183:
this.$ = createLiteral($$[$0].substr(1).toLowerCase(), XSD_DOUBLE);
break;
case 187:
this.$ = resolveIRI($$[$0]);
break;
case 188:

      var namePos = $$[$0].indexOf(':'),
          prefix = $$[$0].substr(0, namePos),
          expansion = Parser.prefixes[prefix];
      if (!expansion) throw new Error('Unknown prefix: ' + prefix);
      this.$ = resolveIRI(expansion + $$[$0].substr(namePos + 1));
    
break;
case 189:

      $$[$0] = $$[$0].substr(0, $$[$0].length - 1);
      if (!($$[$0] in Parser.prefixes)) throw new Error('Unknown prefix: ' + $$[$0]);
      this.$ = resolveIRI(Parser.prefixes[$$[$0]]);
    
break;
case 197: case 205: case 213: case 217: case 219: case 225: case 229: case 233: case 247: case 249: case 251: case 253: case 255: case 257: case 259: case 261: case 286: case 292: case 303: case 319: case 351: case 363: case 382: case 384: case 386: case 388: case 398: case 402: case 404: case 406:
$$[$0-1].push($$[$0]);
break;
case 212: case 224: case 246: case 248: case 250: case 256: case 260: case 381: case 383:
this.$ = [$$[$0]];
break;
case 263:
$$[$0-3].push($$[$0-2]);
break;
case 313: case 325: case 329: case 339: case 341: case 345: case 355: case 361: case 367: case 369: case 378:
$$[$0-2].push($$[$0-1]);
break;
}
},
table: [o($V0,$V1,{3:1,4:2,7:3}),{1:[3]},o($V2,[2,262],{5:4,8:5,287:6,9:7,95:8,17:9,33:10,42:11,47:12,96:13,18:14,6:[2,190],24:$V3,34:[1,15],43:[1,16],48:[1,17]}),o([6,24,34,43,48,99,109,112,114,115,124,125,130,298,299,300,301,302],[2,2],{288:19,11:20,14:21,12:[1,22],15:[1,23]}),{6:[1,24]},{6:[2,192]},{6:[2,193]},{6:[2,202],10:25,82:26,83:$V4},{6:[2,191]},o($V5,[2,198]),o($V5,[2,199]),o($V5,[2,200]),o($V5,[2,201]),{97:28,99:[1,29],102:30,105:31,109:[1,32],112:[1,33],114:[1,34],115:[1,35],116:36,120:37,124:[2,287],125:[2,281],129:43,130:[1,44],298:[1,38],299:[1,39],300:[1,40],301:[1,41],302:[1,42]},o($V6,[2,204],{19:45}),o($V7,[2,218],{35:46,37:47,39:[1,48]}),{13:$V8,16:$V9,28:$Va,44:49,53:54,286:$Vb,293:[1,51],294:52,295:50},o($V6,[2,232],{49:58}),o($Vc,[2,210],{25:59,289:60,290:[1,61],291:[1,62]}),o($V0,[2,197]),o($V0,[2,194]),o($V0,[2,195]),{13:[1,63]},{16:[1,64]},{1:[2,1]},{6:[2,3]},{6:[2,203]},{28:[1,66],29:[1,68],84:65,86:[1,67]},{6:[2,264],98:69,183:[1,70]},o($Vd,[2,266],{100:71,297:[1,72]}),o($Ve,[2,272],{103:73,297:[1,74]}),o($Vf,[2,277],{106:75,297:[1,76]}),{110:77,111:[2,279],297:[1,78]},{39:$Vg,113:79},{39:$Vg,113:81},{39:$Vg,113:82},{117:83,125:$Vh},{121:85,124:$Vi},o($Vj,[2,270]),o($Vj,[2,271]),o($Vk,[2,274]),o($Vk,[2,275]),o($Vk,[2,276]),{124:[2,288],125:[2,282]},{13:$V8,16:$V9,53:87,286:$Vb},{20:88,38:$Vl,39:$Vm,50:89,51:$Vn,54:90},o($V6,[2,216],{36:93}),{38:[1,94],50:95,51:$Vn},o($Vo,[2,344],{171:96,172:97,173:98,41:[2,342]}),o($Vp,[2,228],{45:99}),o($Vp,[2,226],{53:54,294:100,13:$V8,16:$V9,28:$Va,286:$Vb}),o($Vp,[2,227]),o($Vq,[2,224]),o($Vq,[2,222]),o($Vq,[2,223]),o($Vr,[2,187]),o($Vr,[2,188]),o($Vr,[2,189]),{20:101,38:$Vl,39:$Vm,50:102,51:$Vn,54:90},{26:103,27:106,28:$Vs,29:$Vt,292:104,293:[1,105]},o($Vc,[2,211]),o($Vc,[2,208]),o($Vc,[2,209]),o($V0,[2,4]),{13:[1,109]},o($Vu,[2,34]),{39:[1,110]},{39:[1,111]},{28:[1,113],88:112},{6:[2,42]},o($V0,$V1,{7:3,4:114}),{13:$V8,16:$V9,53:115,286:$Vb},o($Vd,[2,267]),{104:116,111:[1,117],133:[1,119],135:118,296:[1,120],303:[1,121]},o($Ve,[2,273]),o($Vd,$Vv,{107:122,134:124,111:$Vw,133:$Vx}),o($Vf,[2,278]),{111:[1,126]},{111:[2,280]},o($Vy,[2,47]),o($Vo,$Vz,{136:127,143:128,144:129,41:$VA,111:$VA}),o($Vy,[2,48]),o($Vy,[2,49]),o($VB,[2,283],{118:130,121:131,124:$Vi}),{39:$Vg,113:132},o($VB,[2,289],{122:133,117:134,125:$Vh}),{39:$Vg,113:135},o([124,125],[2,55]),o($VC,$VD,{21:136,56:137,60:138,61:$VE}),o($V6,[2,205]),{39:$VF,55:140},o($Vd,[2,234],{52:142,296:[1,143]}),{39:[2,237]},{20:144,38:$Vl,39:$Vm,50:145,51:$Vn,54:90},{39:[1,146]},o($V7,[2,219]),{41:[1,147]},{41:[2,343]},{13:$V8,16:$V9,28:$VG,29:$VH,53:152,80:$VI,86:$VJ,91:153,145:148,175:149,177:150,215:$VK,218:$VL,219:$VM,236:163,238:164,269:159,272:$VN,273:$VO,274:$VP,275:$VQ,276:$VR,277:$VS,278:$VT,279:$VU,280:$VV,281:$VW,282:$VX,283:$VY,284:$VZ,285:$V_,286:$Vb},o($V$,[2,230],{54:90,46:177,50:178,20:179,38:$Vl,39:$Vm,51:$Vn}),o($Vq,[2,225]),o($VC,$VD,{56:137,60:138,21:180,61:$VE}),o($V6,[2,233]),o($V6,[2,8]),o($V6,[2,214],{27:181,28:$Vs,29:$Vt}),o($V6,[2,215]),o($V01,[2,212]),o($V01,[2,9]),o($V11,$V21,{30:182,220:183,224:184,228:185,232:186,240:187,244:188,208:$V31,246:$V41,310:$V51}),o($V0,[2,5]),o($V61,[2,252],{85:192}),o($V71,[2,254],{87:193}),{28:[1,195],32:[1,194]},o($V81,[2,256]),o($V2,[2,263],{6:[2,265]}),o($Vy,[2,268],{101:196,131:197,132:[1,198]}),o($Vy,[2,44]),{13:$V8,16:$V9,53:199,286:$Vb},o($Vy,[2,60]),o($Vy,[2,297]),o($Vy,[2,298]),o($Vy,[2,299]),{108:[1,200]},o($V91,[2,57]),{13:$V8,16:$V9,53:201,286:$Vb},o($Vd,[2,296]),{13:$V8,16:$V9,53:202,286:$Vb},o($Va1,[2,302],{137:203}),o($Va1,[2,301]),{13:$V8,16:$V9,28:$VG,29:$VH,53:152,80:$VI,86:$VJ,91:153,145:204,175:149,177:150,215:$VK,218:$VL,219:$VM,236:163,238:164,269:159,272:$VN,273:$VO,274:$VP,275:$VQ,276:$VR,277:$VS,278:$VT,279:$VU,280:$VV,281:$VW,282:$VX,283:$VY,284:$VZ,285:$V_,286:$Vb},o($VB,[2,285],{119:205}),o($VB,[2,284]),o([38,124,127],[2,53]),o($VB,[2,291],{123:206}),o($VB,[2,290]),o([38,125,127],[2,52]),o($V5,[2,6]),o($Vb1,[2,240],{57:207,67:208,68:[1,209]}),o($VC,[2,239]),{62:[1,210]},o([6,41,61,68,71,79,81,83],[2,16]),o($Vo,$Vc1,{22:211,147:212,18:213,148:214,154:215,155:216,24:$V3,39:$Vd1,41:$Vd1,83:$Vd1,111:$Vd1,159:$Vd1,160:$Vd1,162:$Vd1,165:$Vd1,166:$Vd1}),{13:$V8,16:$V9,53:217,286:$Vb},o($Vd,[2,235]),o($VC,$VD,{56:137,60:138,21:218,61:$VE}),o($V6,[2,217]),o($Vo,$Vz,{144:129,40:219,143:220,41:[2,220]}),o($V6,[2,84]),{41:[2,346],174:221,304:[1,222]},{13:$V8,16:$V9,28:$Ve1,53:227,176:223,180:224,185:225,187:$Vf1,286:$Vb},o($Vg1,[2,348],{180:224,185:225,53:227,178:229,179:230,176:231,13:$V8,16:$V9,28:$Ve1,187:$Vf1,286:$Vb}),o($Vh1,[2,124]),o($Vh1,[2,125]),o($Vh1,[2,126]),o($Vh1,[2,127]),o($Vh1,[2,128]),o($Vh1,[2,129]),{13:$V8,16:$V9,28:$VG,29:$VH,53:152,80:$VI,86:$VJ,91:153,175:234,177:235,189:233,214:232,215:$VK,218:$VL,219:$VM,236:163,238:164,269:159,272:$VN,273:$VO,274:$VP,275:$VQ,276:$VR,277:$VS,278:$VT,279:$VU,280:$VV,281:$VW,282:$VX,283:$VY,284:$VZ,285:$V_,286:$Vb},{13:$V8,16:$V9,28:$Ve1,53:227,176:236,180:224,185:225,187:$Vf1,286:$Vb},o($Vi1,[2,167],{270:[1,237],271:[1,238]}),o($Vi1,[2,170]),o($Vi1,[2,171]),o($Vi1,[2,172]),o($Vi1,[2,173]),o($Vi1,[2,174]),o($Vi1,[2,175]),o($Vi1,[2,176]),o($Vj1,[2,177]),o($Vj1,[2,178]),o($Vj1,[2,179]),o($Vj1,[2,180]),o($Vi1,[2,181]),o($Vi1,[2,182]),o($Vi1,[2,183]),o($Vi1,[2,184]),o($Vi1,[2,185]),o($Vi1,[2,186]),o($VC,$VD,{56:137,60:138,21:239,61:$VE}),o($Vp,[2,229]),o($V$,[2,231]),o($V5,[2,14]),o($V01,[2,213]),{31:[1,240]},o($Vk1,[2,385],{221:241}),o($Vl1,[2,387],{225:242}),o($Vl1,[2,134],{229:243,230:244,231:[2,395],268:[1,245],311:[1,246],312:[1,247],313:[1,248],314:[1,249],315:[1,250],316:[1,251]}),o($Vm1,[2,397],{233:252}),o($Vn1,[2,405],{241:253}),{13:$V8,16:$V9,28:$Vo1,29:$Vp1,53:257,65:256,66:258,75:255,80:$VI,91:259,236:163,238:164,245:254,247:262,248:$Vq1,249:$Vr1,250:$Vs1,252:$Vt1,253:267,254:$Vu1,255:$Vv1,256:270,257:$Vw1,258:$Vx1,261:$Vy1,263:$Vz1,269:159,272:$VN,273:$VO,274:$VP,275:$VQ,276:$VR,277:$VS,278:$VT,279:$VU,280:$VV,281:$VW,282:$VX,283:$VY,284:$VZ,285:$V_,286:$Vb,316:$VA1,317:$VB1,318:$VC1,319:$VD1,320:$VE1,321:$VF1},{13:$V8,16:$V9,28:$Vo1,29:$Vp1,53:257,65:256,66:258,75:255,80:$VI,91:259,236:163,238:164,245:280,247:262,248:$Vq1,249:$Vr1,250:$Vs1,252:$Vt1,253:267,254:$Vu1,255:$Vv1,256:270,257:$Vw1,258:$Vx1,261:$Vy1,263:$Vz1,269:159,272:$VN,273:$VO,274:$VP,275:$VQ,276:$VR,277:$VS,278:$VT,279:$VU,280:$VV,281:$VW,282:$VX,283:$VY,284:$VZ,285:$V_,286:$Vb,316:$VA1,317:$VB1,318:$VC1,319:$VD1,320:$VE1,321:$VF1},{13:$V8,16:$V9,28:$Vo1,29:$Vp1,53:257,65:256,66:258,75:255,80:$VI,91:259,236:163,238:164,245:281,247:262,248:$Vq1,249:$Vr1,250:$Vs1,252:$Vt1,253:267,254:$Vu1,255:$Vv1,256:270,257:$Vw1,258:$Vx1,261:$Vy1,263:$Vz1,269:159,272:$VN,273:$VO,274:$VP,275:$VQ,276:$VR,277:$VS,278:$VT,279:$VU,280:$VV,281:$VW,282:$VX,283:$VY,284:$VZ,285:$V_,286:$Vb,316:$VA1,317:$VB1,318:$VC1,319:$VD1,320:$VE1,321:$VF1},o($V11,[2,410]),{13:$V8,16:$V9,41:[1,282],53:284,80:$VI,90:283,91:285,92:$VG1,236:163,238:164,269:159,272:$VN,273:$VO,274:$VP,275:$VQ,276:$VR,277:$VS,278:$VT,279:$VU,280:$VV,281:$VW,282:$VX,283:$VY,284:$VZ,285:$V_,286:$Vb},{41:[1,287],86:[1,288]},{39:[1,289]},o($V81,[2,257]),o($Vy,[2,43]),o($Vy,[2,269]),{111:[1,290]},o($Vy,[2,59]),o($Vd,$Vv,{134:124,107:291,111:$Vw,133:$Vx}),o($V91,[2,58]),o($Vy,[2,46]),{41:[1,292],111:[1,294],138:293},o($Va1,[2,314],{146:295,304:[1,296]}),{38:[1,297],126:298,127:$VH1},{38:[1,300],126:301,127:$VH1},o($VI1,[2,242],{58:302,70:303,71:[1,304]}),o($Vb1,[2,241]),{13:$V8,16:$V9,29:$Vp1,53:310,65:308,66:309,69:305,75:307,77:306,247:262,248:$Vq1,249:$Vr1,250:$Vs1,252:$Vt1,253:267,254:$Vu1,255:$Vv1,256:270,257:$Vw1,258:$Vx1,261:$Vy1,263:$Vz1,286:$Vb,316:$VA1,317:$VB1,318:$VC1,319:$VD1,320:$VE1,321:$VF1},{13:$V8,16:$V9,28:$VJ1,29:$VK1,53:310,63:311,64:312,65:313,66:314,247:262,248:$Vq1,249:$Vr1,250:$Vs1,252:$Vt1,253:267,254:$Vu1,255:$Vv1,256:270,257:$Vw1,258:$Vx1,261:$Vy1,263:$Vz1,286:$Vb,316:$VA1,317:$VB1,318:$VC1,319:$VD1,320:$VE1,321:$VF1},{41:[1,317]},{41:[1,318]},{20:319,38:$Vl,39:$Vm,54:90},o($VL1,[2,318],{149:320}),o($VL1,[2,317]),{13:$V8,16:$V9,28:$VG,29:$VM1,53:152,80:$VI,86:$VJ,91:153,156:321,175:322,191:323,215:$VN1,218:$VL,219:$VM,236:163,238:164,269:159,272:$VN,273:$VO,274:$VP,275:$VQ,276:$VR,277:$VS,278:$VT,279:$VU,280:$VV,281:$VW,282:$VX,283:$VY,284:$VZ,285:$V_,286:$Vb},o($Vp,[2,15]),o($V5,[2,11]),{41:[1,326]},{41:[2,221]},{41:[2,85]},o($Vo,[2,345],{41:[2,347]}),o($Vg1,[2,86]),o($VO1,[2,350],{181:327}),o($Vo,$VP1,{186:328,188:329}),o($Vo,[2,92]),o($Vo,[2,93]),o($Vo,[2,94]),o($Vg1,[2,87]),o($Vg1,[2,88]),o($Vg1,[2,349]),{13:$V8,16:$V9,28:$VG,29:$VH,32:[1,330],53:152,80:$VI,86:$VJ,91:153,175:234,177:235,189:331,215:$VK,218:$VL,219:$VM,236:163,238:164,269:159,272:$VN,273:$VO,274:$VP,275:$VQ,276:$VR,277:$VS,278:$VT,279:$VU,280:$VV,281:$VW,282:$VX,283:$VY,284:$VZ,285:$V_,286:$Vb},o($VQ1,[2,381]),o($VR1,[2,120]),o($VR1,[2,121]),{216:[1,332]},o($Vi1,[2,168]),{13:$V8,16:$V9,53:333,286:$Vb},o($V5,[2,13]),{28:[1,334]},o([31,32,183,251],[2,130],{222:335,223:[1,336]}),o($Vk1,[2,132],{226:337,227:[1,338]}),o($V11,$V21,{232:186,240:187,244:188,228:339,208:$V31,246:$V41,310:$V51}),{231:[1,340]},o($VS1,[2,389]),o($VS1,[2,390]),o($VS1,[2,391]),o($VS1,[2,392]),o($VS1,[2,393]),o($VS1,[2,394]),{231:[2,396]},o([31,32,183,223,227,231,251,268,311,312,313,314,315,316],[2,137],{234:341,235:342,236:343,238:344,246:[1,346],280:$VV,281:$VW,282:$VX,283:$VY,284:$VZ,285:$V_,310:[1,345]}),o($Vm1,[2,141],{242:347,243:348,293:$VT1,307:$VU1}),o($Vn1,[2,143]),o($Vn1,[2,146]),o($Vn1,[2,147]),o($Vn1,[2,148],{29:$VV1,86:$VW1}),o($Vn1,[2,149]),o($Vn1,[2,150]),o($Vn1,[2,151]),o($V11,$V21,{220:183,224:184,228:185,232:186,240:187,244:188,30:353,208:$V31,246:$V41,310:$V51}),o($VX1,[2,153]),{86:[1,354]},{29:[1,355]},{29:[1,356]},{29:[1,357]},{29:$VY1,86:$VZ1,169:358},{29:[1,361]},{29:[1,363],86:[1,362]},{257:[1,364]},{29:[1,365]},{29:[1,366]},{29:[1,367]},o($V_1,[2,411]),o($V_1,[2,412]),o($V_1,[2,413]),o($V_1,[2,414]),o($V_1,[2,415]),{257:[2,417]},o($Vn1,[2,144]),o($Vn1,[2,145]),o($Vu,[2,35]),o($V61,[2,253]),o($V$1,[2,38]),o($V$1,[2,39]),o($V$1,[2,40]),o($Vu,[2,36]),o($V71,[2,255]),o($V02,[2,258],{89:368}),{13:$V8,16:$V9,53:369,286:$Vb},o($Vy,[2,45]),o([6,38,124,125,127,183],[2,61]),o($Va1,[2,303]),{13:$V8,16:$V9,28:[1,371],53:372,139:370,286:$Vb},o($Va1,[2,63]),o($Vo,[2,313],{41:$V12,111:$V12}),{39:$VF,55:373},o($VB,[2,286]),o($Vd,[2,293],{128:374,296:[1,375]}),{39:$VF,55:376},o($VB,[2,292]),o($V22,[2,244],{59:377,78:378,79:[1,379],81:[1,380]}),o($VI1,[2,243]),{62:[1,381]},o($Vb1,[2,24],{247:262,253:267,256:270,75:307,65:308,66:309,53:310,77:382,13:$V8,16:$V9,29:$Vp1,248:$Vq1,249:$Vr1,250:$Vs1,252:$Vt1,254:$Vu1,255:$Vv1,257:$Vw1,258:$Vx1,261:$Vy1,263:$Vz1,286:$Vb,316:$VA1,317:$VB1,318:$VC1,319:$VD1,320:$VE1,321:$VF1}),o($V32,[2,248]),o($V42,[2,77]),o($V42,[2,78]),o($V42,[2,79]),{29:$VV1,86:$VW1},o($VC,[2,18],{247:262,253:267,256:270,53:310,65:313,66:314,64:383,13:$V8,16:$V9,28:$VJ1,29:$VK1,248:$Vq1,249:$Vr1,250:$Vs1,252:$Vt1,254:$Vu1,255:$Vv1,257:$Vw1,258:$Vx1,261:$Vy1,263:$Vz1,286:$Vb,316:$VA1,317:$VB1,318:$VC1,319:$VD1,320:$VE1,321:$VF1}),o($V52,[2,246]),o($V52,[2,19]),o($V52,[2,20]),o($V11,$V21,{220:183,224:184,228:185,232:186,240:187,244:188,30:384,208:$V31,246:$V41,310:$V51}),o($V52,[2,23]),o($V62,[2,64]),o($V62,[2,65]),o($VC,$VD,{56:137,60:138,21:385,61:$VE}),{39:[2,328],41:[2,66],82:395,83:$V4,111:[1,391],150:386,151:387,158:388,159:[1,389],160:[1,390],162:[1,392],165:[1,393],166:[1,394]},o($VL1,[2,326],{157:396,304:[1,397]}),o($V72,$V82,{190:398,193:399,199:400,200:402,28:$V92}),o($Va2,[2,356],{193:399,199:400,200:402,192:403,190:404,13:$V82,16:$V82,29:$V82,187:$V82,208:$V82,213:$V82,286:$V82,28:$V92}),{13:$V8,16:$V9,28:$VG,29:$VM1,53:152,80:$VI,86:$VJ,91:153,175:407,191:408,195:406,215:$VN1,217:405,218:$VL,219:$VM,236:163,238:164,269:159,272:$VN,273:$VO,274:$VP,275:$VQ,276:$VR,277:$VS,278:$VT,279:$VU,280:$VV,281:$VW,282:$VX,283:$VY,284:$VZ,285:$V_,286:$Vb},o($V72,$V82,{193:399,199:400,200:402,190:409,28:$V92}),o($VC,$VD,{56:137,60:138,21:410,61:$VE}),o([41,111,216,304],[2,89],{182:411,183:[1,412]}),o($VO1,[2,91]),{13:$V8,16:$V9,28:$VG,29:$VH,53:152,80:$VI,86:$VJ,91:153,175:234,177:235,189:413,215:$VK,218:$VL,219:$VM,236:163,238:164,269:159,272:$VN,273:$VO,274:$VP,275:$VQ,276:$VR,277:$VS,278:$VT,279:$VU,280:$VV,281:$VW,282:$VX,283:$VY,284:$VZ,285:$V_,286:$Vb},o($Vb2,[2,116]),o($VQ1,[2,382]),o($Vb2,[2,117]),o($Vi1,[2,169]),{32:[1,414]},o($Vk1,[2,386]),o($V11,$V21,{224:184,228:185,232:186,240:187,244:188,220:415,208:$V31,246:$V41,310:$V51}),o($Vl1,[2,388]),o($V11,$V21,{228:185,232:186,240:187,244:188,224:416,208:$V31,246:$V41,310:$V51}),o($Vl1,[2,135]),{29:$VY1,86:$VZ1,169:417},o($Vm1,[2,398]),o($V11,$V21,{240:187,244:188,232:418,208:$V31,246:$V41,310:$V51}),o($Vn1,[2,401],{237:419}),o($Vn1,[2,403],{239:420}),o($VS1,[2,399]),o($VS1,[2,400]),o($Vn1,[2,406]),o($V11,$V21,{244:188,240:421,208:$V31,246:$V41,310:$V51}),o($VS1,[2,407]),o($VS1,[2,408]),o($VX1,[2,80]),o($VS1,[2,336],{167:422,290:[1,423]}),{32:[1,424]},o($VX1,[2,154]),o($V11,$V21,{220:183,224:184,228:185,232:186,240:187,244:188,30:425,208:$V31,246:$V41,310:$V51}),o($V11,$V21,{220:183,224:184,228:185,232:186,240:187,244:188,30:426,208:$V31,246:$V41,310:$V51}),o($V11,$V21,{220:183,224:184,228:185,232:186,240:187,244:188,30:427,208:$V31,246:$V41,310:$V51}),o($VX1,[2,158]),o($VX1,[2,82]),o($VS1,[2,340],{170:428}),{28:[1,429]},o($VX1,[2,160]),o($V11,$V21,{220:183,224:184,228:185,232:186,240:187,244:188,30:430,208:$V31,246:$V41,310:$V51}),{39:$VF,55:431},o($Vc2,[2,418],{259:432,290:[1,433]}),o($VS1,[2,422],{262:434,290:[1,435]}),o($VS1,[2,424],{264:436,290:[1,437]}),{29:[1,440],41:[1,438],93:439},o($Vy,[2,56]),{39:[1,441]},{39:[2,304]},{39:[2,305]},o($Vy,[2,50]),{13:$V8,16:$V9,53:442,286:$Vb},o($Vd,[2,294]),o($Vy,[2,51]),o($V22,[2,17]),o($V22,[2,245]),{80:[1,443]},{80:[1,444]},{13:$V8,16:$V9,28:$Vd2,29:$Vp1,53:310,65:308,66:309,72:445,73:446,74:$Ve2,75:307,76:$Vf2,77:449,247:262,248:$Vq1,249:$Vr1,250:$Vs1,252:$Vt1,253:267,254:$Vu1,255:$Vv1,256:270,257:$Vw1,258:$Vx1,261:$Vy1,263:$Vz1,286:$Vb,316:$VA1,317:$VB1,318:$VC1,319:$VD1,320:$VE1,321:$VF1},o($V32,[2,249]),o($V52,[2,247]),{31:[1,452],32:[1,451]},{23:453,41:[2,206],82:454,83:$V4},o($VL1,[2,319]),o($Vg2,[2,320],{152:455,304:[1,456]}),{39:$VF,55:457},{39:$VF,55:458},{39:$VF,55:459},{13:$V8,16:$V9,28:[1,461],53:462,161:460,286:$Vb},o($Vh2,[2,332],{163:463,297:[1,464]}),{13:$V8,16:$V9,29:$Vp1,53:310,65:308,66:309,75:307,77:465,247:262,248:$Vq1,249:$Vr1,250:$Vs1,252:$Vt1,253:267,254:$Vu1,255:$Vv1,256:270,257:$Vw1,258:$Vx1,261:$Vy1,263:$Vz1,286:$Vb,316:$VA1,317:$VB1,318:$VC1,319:$VD1,320:$VE1,321:$VF1},{29:[1,466]},o($Vi2,[2,76]),o($VL1,[2,68]),o($Vo,[2,325],{39:$Vj2,41:$Vj2,83:$Vj2,111:$Vj2,159:$Vj2,160:$Vj2,162:$Vj2,165:$Vj2,166:$Vj2}),o($Va2,[2,96]),o($Vo,[2,360],{194:467}),o($Vo,[2,358]),o($Vo,[2,359]),o($V72,[2,368],{201:468,202:469}),o($Va2,[2,97]),o($Va2,[2,357]),{13:$V8,16:$V9,28:$VG,29:$VM1,32:[1,470],53:152,80:$VI,86:$VJ,91:153,175:407,191:408,195:471,215:$VN1,218:$VL,219:$VM,236:163,238:164,269:159,272:$VN,273:$VO,274:$VP,275:$VQ,276:$VR,277:$VS,278:$VT,279:$VU,280:$VV,281:$VW,282:$VX,283:$VY,284:$VZ,285:$V_,286:$Vb},o($VQ1,[2,383]),o($VR1,[2,122]),o($VR1,[2,123]),{216:[1,472]},o($V5,[2,12]),o($VO1,[2,351]),o($VO1,[2,352],{185:225,53:227,184:473,180:474,13:$V8,16:$V9,28:$Ve1,187:$Vf1,286:$Vb}),o($Vk2,[2,95],{251:[1,475]}),o($V01,[2,10]),o($Vk1,[2,131]),o($Vl1,[2,133]),o($Vl1,[2,136]),o($Vm1,[2,138]),o($Vm1,[2,139],{243:348,242:476,293:$VT1,307:$VU1}),o($Vm1,[2,140],{243:348,242:477,293:$VT1,307:$VU1}),o($Vn1,[2,142]),o($VS1,[2,338],{168:478}),o($VS1,[2,337]),o([6,13,16,28,29,31,32,39,41,71,74,76,79,80,81,83,86,111,159,160,162,165,166,183,215,218,219,223,227,231,246,248,249,250,251,252,254,255,257,258,261,263,268,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,293,304,307,310,311,312,313,314,315,316,317,318,319,320,321],[2,152]),{32:[1,479]},{251:[1,480]},{251:[1,481]},o($V11,$V21,{220:183,224:184,228:185,232:186,240:187,244:188,30:482,208:$V31,246:$V41,310:$V51}),{32:[1,483]},{32:[1,484]},o($VX1,[2,162]),o($V11,$V21,{220:183,224:184,228:185,232:186,240:187,244:188,260:485,30:487,208:$V31,246:$V41,293:[1,486],310:$V51}),o($Vc2,[2,419]),o($V11,$V21,{220:183,224:184,228:185,232:186,240:187,244:188,30:488,208:$V31,246:$V41,310:$V51}),o($VS1,[2,423]),o($V11,$V21,{220:183,224:184,228:185,232:186,240:187,244:188,30:489,208:$V31,246:$V41,310:$V51}),o($VS1,[2,425]),o($Vu,[2,37]),o($V02,[2,259]),{13:$V8,16:$V9,53:284,80:$VI,90:491,91:285,92:$VG1,94:490,236:163,238:164,269:159,272:$VN,273:$VO,274:$VP,275:$VQ,276:$VR,277:$VS,278:$VT,279:$VU,280:$VV,281:$VW,282:$VX,283:$VY,284:$VZ,285:$V_,286:$Vb},o($Vo,$Vz,{144:129,140:492,143:493,41:[2,306]}),o($VB,[2,54]),o($V22,[2,30],{81:[1,494]}),o($V22,[2,31],{79:[1,495]}),o($VI1,[2,25],{247:262,253:267,256:270,75:307,65:308,66:309,53:310,77:449,73:496,13:$V8,16:$V9,28:$Vd2,29:$Vp1,74:$Ve2,76:$Vf2,248:$Vq1,249:$Vr1,250:$Vs1,252:$Vt1,254:$Vu1,255:$Vv1,257:$Vw1,258:$Vx1,261:$Vy1,263:$Vz1,286:$Vb,316:$VA1,317:$VB1,318:$VC1,319:$VD1,320:$VE1,321:$VF1}),o($Vl2,[2,250]),{29:$Vp1,75:497},{29:$Vp1,75:498},o($Vl2,[2,28]),o($Vl2,[2,29]),o($V52,[2,21]),{28:[1,499]},{41:[2,7]},{41:[2,207]},o($Vo,$Vc1,{155:216,153:500,154:501,39:$Vm2,41:$Vm2,83:$Vm2,111:$Vm2,159:$Vm2,160:$Vm2,162:$Vm2,165:$Vm2,166:$Vm2}),o($Vg2,[2,321]),o($Vi2,[2,69],{305:[1,502]}),o($Vi2,[2,70]),o($Vi2,[2,71]),{39:$VF,55:503},{39:[2,330]},{39:[2,331]},{13:$V8,16:$V9,28:[1,505],53:506,164:504,286:$Vb},o($Vh2,[2,333]),o($Vi2,[2,74]),o($V11,$V21,{220:183,224:184,228:185,232:186,240:187,244:188,30:507,208:$V31,246:$V41,310:$V51}),{13:$V8,16:$V9,28:$VG,29:$VM1,53:152,80:$VI,86:$VJ,91:153,175:407,191:408,195:508,215:$VN1,218:$VL,219:$VM,236:163,238:164,269:159,272:$VN,273:$VO,274:$VP,275:$VQ,276:$VR,277:$VS,278:$VT,279:$VU,280:$VV,281:$VW,282:$VX,283:$VY,284:$VZ,285:$V_,286:$Vb},o($VQ1,[2,101],{306:[1,509]}),o($Vn2,[2,375],{203:510,207:511,213:[1,512]}),o($Vh1,[2,118]),o($VQ1,[2,384]),o($Vh1,[2,119]),o($VO1,[2,90]),o($VO1,[2,353]),o($Vo,[2,355]),o($Vn1,[2,402]),o($Vn1,[2,404]),o($V11,$V21,{220:183,224:184,228:185,232:186,240:187,244:188,30:513,208:$V31,246:$V41,310:$V51}),o($VX1,[2,155]),o($V11,$V21,{220:183,224:184,228:185,232:186,240:187,244:188,30:514,208:$V31,246:$V41,310:$V51}),o($V11,$V21,{220:183,224:184,228:185,232:186,240:187,244:188,30:515,208:$V31,246:$V41,310:$V51}),{32:[1,516],251:[1,517]},o($VX1,[2,159]),o($VX1,[2,161]),{32:[1,518]},{32:[2,420]},{32:[2,421]},{32:[1,519]},{32:[2,426],183:[1,522],265:520,266:521},{13:$V8,16:$V9,32:[1,523],53:284,80:$VI,90:524,91:285,92:$VG1,236:163,238:164,269:159,272:$VN,273:$VO,274:$VP,275:$VQ,276:$VR,277:$VS,278:$VT,279:$VU,280:$VV,281:$VW,282:$VX,283:$VY,284:$VZ,285:$V_,286:$Vb},o($Vo2,[2,260]),{41:[1,525]},{41:[2,307]},{80:[1,526]},{80:[1,527]},o($Vl2,[2,251]),o($Vl2,[2,26]),o($Vl2,[2,27]),{32:[1,528]},o($VL1,[2,67]),o($VL1,[2,323]),{39:[2,329]},o($Vi2,[2,72]),{39:$VF,55:529},{39:[2,334]},{39:[2,335]},{31:[1,530]},o($Vk2,[2,362],{196:531,251:[1,532]}),o($V72,[2,367]),o([13,16,28,29,32,80,86,215,218,219,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,306],[2,102],{307:[1,533]}),{13:$V8,16:$V9,29:[1,539],53:536,187:[1,537],204:534,205:535,208:[1,538],286:$Vb},o($Vn2,[2,376]),{32:[1,540],251:[1,541]},{32:[1,542]},{251:[1,543]},o($VX1,[2,83]),o($VS1,[2,341]),o($VX1,[2,163]),o($VX1,[2,164]),{32:[1,544]},{32:[2,427]},{267:[1,545]},o($V02,[2,41]),o($Vo2,[2,261]),o($Vp2,[2,308],{141:546,304:[1,547]}),o($V22,[2,32]),o($V22,[2,33]),o($V52,[2,22]),o($Vi2,[2,73]),{28:[1,548]},o([39,41,83,111,159,160,162,165,166,216,304],[2,98],{197:549,183:[1,550]}),o($Vo,[2,361]),o($V72,[2,369]),o($Vq2,[2,104]),o($Vq2,[2,373],{206:551,308:552,293:[1,554],309:[1,553],310:[1,555]}),o($Vr2,[2,105]),o($Vr2,[2,106]),{13:$V8,16:$V9,29:[1,559],53:560,86:[1,558],187:$Vs2,209:556,210:557,213:$Vt2,286:$Vb},o($V72,$V82,{200:402,199:563}),o($VX1,[2,81]),o($VS1,[2,339]),o($VX1,[2,156]),o($V11,$V21,{220:183,224:184,228:185,232:186,240:187,244:188,30:564,208:$V31,246:$V41,310:$V51}),o($VX1,[2,165]),{268:[1,565]},o($Vo,$Vz,{144:129,142:566,143:567,41:$Vu2,111:$Vu2}),o($Vp2,[2,309]),{32:[1,568]},o($Vk2,[2,363]),o($Vk2,[2,99],{200:402,198:569,199:570,13:$V82,16:$V82,29:$V82,187:$V82,208:$V82,213:$V82,286:$V82,28:[1,571]}),o($Vq2,[2,103]),o($Vq2,[2,374]),o($Vq2,[2,370]),o($Vq2,[2,371]),o($Vq2,[2,372]),o($Vr2,[2,107]),o($Vr2,[2,109]),o($Vr2,[2,110]),o($Vv2,[2,377],{211:572}),o($Vr2,[2,112]),o($Vr2,[2,113]),{13:$V8,16:$V9,53:573,187:[1,574],286:$Vb},{32:[1,575]},{32:[1,576]},{269:577,276:$VR,277:$VS,278:$VT,279:$VU},o($Va1,[2,62]),o($Va1,[2,311]),o($Vi2,[2,75]),o($Vo,$VP1,{188:329,186:578}),o($Vo,[2,364]),o($Vo,[2,365]),{13:$V8,16:$V9,32:[2,379],53:560,187:$Vs2,210:580,212:579,213:$Vt2,286:$Vb},o($Vr2,[2,114]),o($Vr2,[2,115]),o($Vr2,[2,108]),o($VX1,[2,157]),{32:[2,166]},o($Vk2,[2,100]),{32:[1,581]},{32:[2,380],306:[1,582]},o($Vr2,[2,111]),o($Vv2,[2,378])],
defaultActions: {5:[2,192],6:[2,193],8:[2,191],24:[2,1],25:[2,3],26:[2,203],69:[2,42],78:[2,280],92:[2,237],97:[2,343],220:[2,221],221:[2,85],251:[2,396],279:[2,417],371:[2,304],372:[2,305],453:[2,7],454:[2,207],461:[2,330],462:[2,331],486:[2,420],487:[2,421],493:[2,307],502:[2,329],505:[2,334],506:[2,335],521:[2,427],577:[2,166]},
parseError: function parseError (str, hash) {
    if (hash.recoverable) {
        this.trace(str);
    } else {
        var error = new Error(str);
        error.hash = hash;
        throw error;
    }
},
parse: function parse(input) {
    var self = this, stack = [0], tstack = [], vstack = [null], lstack = [], table = this.table, yytext = '', yylineno = 0, yyleng = 0, recovering = 0, TERROR = 2, EOF = 1;
    var args = lstack.slice.call(arguments, 1);
    var lexer = Object.create(this.lexer);
    var sharedState = { yy: {} };
    for (var k in this.yy) {
        if (Object.prototype.hasOwnProperty.call(this.yy, k)) {
            sharedState.yy[k] = this.yy[k];
        }
    }
    lexer.setInput(input, sharedState.yy);
    sharedState.yy.lexer = lexer;
    sharedState.yy.parser = this;
    if (typeof lexer.yylloc == 'undefined') {
        lexer.yylloc = {};
    }
    var yyloc = lexer.yylloc;
    lstack.push(yyloc);
    var ranges = lexer.options && lexer.options.ranges;
    if (typeof sharedState.yy.parseError === 'function') {
        this.parseError = sharedState.yy.parseError;
    } else {
        this.parseError = Object.getPrototypeOf(this).parseError;
    }
    function popStack(n) {
        stack.length = stack.length - 2 * n;
        vstack.length = vstack.length - n;
        lstack.length = lstack.length - n;
    }
    _token_stack:
        var lex = function () {
            var token;
            token = lexer.lex() || EOF;
            if (typeof token !== 'number') {
                token = self.symbols_[token] || token;
            }
            return token;
        };
    var symbol, preErrorSymbol, state, action, a, r, yyval = {}, p, len, newState, expected;
    while (true) {
        state = stack[stack.length - 1];
        if (this.defaultActions[state]) {
            action = this.defaultActions[state];
        } else {
            if (symbol === null || typeof symbol == 'undefined') {
                symbol = lex();
            }
            action = table[state] && table[state][symbol];
        }
                    if (typeof action === 'undefined' || !action.length || !action[0]) {
                var errStr = '';
                expected = [];
                for (p in table[state]) {
                    if (this.terminals_[p] && p > TERROR) {
                        expected.push('\'' + this.terminals_[p] + '\'');
                    }
                }
                if (lexer.showPosition) {
                    errStr = 'Parse error on line ' + (yylineno + 1) + ':\n' + lexer.showPosition() + '\nExpecting ' + expected.join(', ') + ', got \'' + (this.terminals_[symbol] || symbol) + '\'';
                } else {
                    errStr = 'Parse error on line ' + (yylineno + 1) + ': Unexpected ' + (symbol == EOF ? 'end of input' : '\'' + (this.terminals_[symbol] || symbol) + '\'');
                }
                this.parseError(errStr, {
                    text: lexer.match,
                    token: this.terminals_[symbol] || symbol,
                    line: lexer.yylineno,
                    loc: yyloc,
                    expected: expected
                });
            }
        if (action[0] instanceof Array && action.length > 1) {
            throw new Error('Parse Error: multiple actions possible at state: ' + state + ', token: ' + symbol);
        }
        switch (action[0]) {
        case 1:
            stack.push(symbol);
            vstack.push(lexer.yytext);
            lstack.push(lexer.yylloc);
            stack.push(action[1]);
            symbol = null;
            if (!preErrorSymbol) {
                yyleng = lexer.yyleng;
                yytext = lexer.yytext;
                yylineno = lexer.yylineno;
                yyloc = lexer.yylloc;
                if (recovering > 0) {
                    recovering--;
                }
            } else {
                symbol = preErrorSymbol;
                preErrorSymbol = null;
            }
            break;
        case 2:
            len = this.productions_[action[1]][1];
            yyval.$ = vstack[vstack.length - len];
            yyval._$ = {
                first_line: lstack[lstack.length - (len || 1)].first_line,
                last_line: lstack[lstack.length - 1].last_line,
                first_column: lstack[lstack.length - (len || 1)].first_column,
                last_column: lstack[lstack.length - 1].last_column
            };
            if (ranges) {
                yyval._$.range = [
                    lstack[lstack.length - (len || 1)].range[0],
                    lstack[lstack.length - 1].range[1]
                ];
            }
            r = this.performAction.apply(yyval, [
                yytext,
                yyleng,
                yylineno,
                sharedState.yy,
                action[1],
                vstack,
                lstack
            ].concat(args));
            if (typeof r !== 'undefined') {
                return r;
            }
            if (len) {
                stack = stack.slice(0, -1 * len * 2);
                vstack = vstack.slice(0, -1 * len);
                lstack = lstack.slice(0, -1 * len);
            }
            stack.push(this.productions_[action[1]][0]);
            vstack.push(yyval.$);
            lstack.push(yyval._$);
            newState = table[stack[stack.length - 2]][stack[stack.length - 1]];
            stack.push(newState);
            break;
        case 3:
            return true;
        }
    }
    return true;
}};

  /*
    SPARQL parser in the Jison parser generator format.
  */

  // Common namespaces and entities
  var RDF = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
      RDF_TYPE  = RDF + 'type',
      RDF_FIRST = RDF + 'first',
      RDF_REST  = RDF + 'rest',
      RDF_NIL   = RDF + 'nil',
      XSD = 'http://www.w3.org/2001/XMLSchema#',
      XSD_INTEGER  = XSD + 'integer',
      XSD_DECIMAL  = XSD + 'decimal',
      XSD_DOUBLE   = XSD + 'double',
      XSD_BOOLEAN  = XSD + 'boolean',
      XSD_TRUE =  '"true"^^'  + XSD_BOOLEAN,
      XSD_FALSE = '"false"^^' + XSD_BOOLEAN;

  var base = '', basePath = '', baseRoot = '';

  // Returns a lowercase version of the given string
  function lowercase(string) {
    return string.toLowerCase();
  }

  // Appends the item to the array and returns the array
  function appendTo(array, item) {
    return array.push(item), array;
  }

  // Appends the items to the array and returns the array
  function appendAllTo(array, items) {
    return array.push.apply(array, items), array;
  }

  // Extends a base object with properties of other objects
  function extend(base) {
    if (!base) base = {};
    for (var i = 1, l = arguments.length, arg; i < l && (arg = arguments[i] || {}); i++)
      for (var name in arg)
        base[name] = arg[name];
    return base;
  }

  // Creates an array that contains all items of the given arrays
  function unionAll() {
    var union = [];
    for (var i = 0, l = arguments.length; i < l; i++)
      union = union.concat.apply(union, arguments[i]);
    return union;
  }

  // Resolves an IRI against a base path
  function resolveIRI(iri) {
    // Strip off possible angular brackets
    if (iri[0] === '<')
      iri = iri.substring(1, iri.length - 1);
    // Return absolute IRIs unmodified
    if (/^[a-z]+:/.test(iri))
      return iri;
    if (!Parser.base)
      throw new Error('Cannot resolve relative IRI ' + iri + ' because no base IRI was set.');
    if (!base) {
      base = Parser.base;
      basePath = base.replace(/[^\/:]*$/, '');
      baseRoot = base.match(/^(?:[a-z]+:\/*)?[^\/]*/)[0];
    }
    switch (iri[0]) {
    // An empty relative IRI indicates the base IRI
    case undefined:
      return base;
    // Resolve relative fragment IRIs against the base IRI
    case '#':
      return base + iri;
    // Resolve relative query string IRIs by replacing the query string
    case '?':
      return base.replace(/(?:\?.*)?$/, iri);
    // Resolve root relative IRIs at the root of the base IRI
    case '/':
      return baseRoot + iri;
    // Resolve all other IRIs at the base IRI's path
    default:
      return basePath + iri;
    }
  }

  // If the item is a variable, ensures it starts with a question mark
  function toVar(variable) {
    if (variable) {
      var first = variable[0];
      if (first === '?') return variable;
      if (first === '$') return '?' + variable.substr(1);
    }
    return variable;
  }

  // Creates an operation with the given name and arguments
  function operation(operatorName, args) {
    return { type: 'operation', operator: operatorName, args: args || [] };
  }

  // Creates an expression with the given type and attributes
  function expression(expr, attr) {
    var expression = { expression: expr };
    if (attr)
      for (var a in attr)
        expression[a] = attr[a];
    return expression;
  }

  // Creates a path with the given type and items
  function path(type, items) {
    return { type: 'path', pathType: type, items: items };
  }

  // Transforms a list of operations types and arguments into a tree of operations
  function createOperationTree(initialExpression, operationList) {
    for (var i = 0, l = operationList.length, item; i < l && (item = operationList[i]); i++)
      initialExpression = operation(item[0], [initialExpression, item[1]]);
    return initialExpression;
  }

  // Group datasets by default and named
  function groupDatasets(fromClauses) {
    var defaults = [], named = [], l = fromClauses.length, fromClause;
    for (var i = 0; i < l && (fromClause = fromClauses[i]); i++)
      (fromClause.named ? named : defaults).push(fromClause.iri);
    return l ? { from: { default: defaults, named: named } } : null;
  }

  // Converts the number to a string
  function toInt(string) {
    return parseInt(string, 10);
  }

  // Transforms a possibly single group into its patterns
  function degroupSingle(group) {
    return group.type === 'group' && group.patterns.length === 1 ? group.patterns[0] : group;
  }

  // Creates a literal with the given value and type
  function createLiteral(value, type) {
    return '"' + value + '"^^' + type;
  }

  // Creates a triple with the given subject, predicate, and object
  function triple(subject, predicate, object) {
    var triple = {};
    if (subject   != null) triple.subject   = subject;
    if (predicate != null) triple.predicate = predicate;
    if (object    != null) triple.object    = object;
    return triple;
  }

  // Creates a new blank node identifier
  function blank() {
    return '_:b' + blankId++;
  };
  var blankId = 0;
  Parser._resetBlanks = function () { blankId = 0; }

  // Regular expression and replacement strings to escape strings
  var escapeSequence = /\\u([a-fA-F0-9]{4})|\\U([a-fA-F0-9]{8})|\\(.)/g,
      escapeReplacements = { '\\': '\\', "'": "'", '"': '"',
                             't': '\t', 'b': '\b', 'n': '\n', 'r': '\r', 'f': '\f' },
      fromCharCode = String.fromCharCode;

  // Translates escape codes in the string into their textual equivalent
  function unescapeString(string, trimLength) {
    string = string.substring(trimLength, string.length - trimLength);
    try {
      string = string.replace(escapeSequence, function (sequence, unicode4, unicode8, escapedChar) {
        var charCode;
        if (unicode4) {
          charCode = parseInt(unicode4, 16);
          if (isNaN(charCode)) throw new Error(); // can never happen (regex), but helps performance
          return fromCharCode(charCode);
        }
        else if (unicode8) {
          charCode = parseInt(unicode8, 16);
          if (isNaN(charCode)) throw new Error(); // can never happen (regex), but helps performance
          if (charCode < 0xFFFF) return fromCharCode(charCode);
          return fromCharCode(0xD800 + ((charCode -= 0x10000) >> 10), 0xDC00 + (charCode & 0x3FF));
        }
        else {
          var replacement = escapeReplacements[escapedChar];
          if (!replacement) throw new Error();
          return replacement;
        }
      });
    }
    catch (error) { return ''; }
    return '"' + string + '"';
  }

  // Creates a list, collecting its (possibly blank) items and triples associated with those items
  function createList(objects) {
    var list = blank(), head = list, listItems = [], listTriples, triples = [];
    objects.forEach(function (o) { listItems.push(o.entity); appendAllTo(triples, o.triples); });

    // Build an RDF list out of the items
    for (var i = 0, j = 0, l = listItems.length, listTriples = Array(l * 2); i < l;)
      listTriples[j++] = triple(head, RDF_FIRST, listItems[i]),
      listTriples[j++] = triple(head, RDF_REST,  head = ++i < l ? blank() : RDF_NIL);

    // Return the list's identifier, its triples, and the triples associated with its items
    return { entity: list, triples: appendAllTo(listTriples, triples) };
  }

  // Creates a blank node identifier, collecting triples with that blank node as subject
  function createAnonymousObject(propertyList) {
    var entity = blank();
    return {
      entity: entity,
      triples: propertyList.map(function (t) { return extend(triple(entity), t); })
    };
  }

  // Collects all (possibly blank) objects, and triples that have them as subject
  function objectListToTriples(predicate, objectList, otherTriples) {
    var objects = [], triples = [];
    objectList.forEach(function (l) {
      objects.push(triple(null, predicate, l.entity));
      appendAllTo(triples, l.triples);
    });
    return unionAll(objects, otherTriples || [], triples);
  }

  // Simplifies groups by merging adjacent BGPs
  function mergeAdjacentBGPs(groups) {
    var merged = [], currentBgp;
    for (var i = 0, group; group = groups[i]; i++) {
      switch (group.type) {
        // Add a BGP's triples to the current BGP
        case 'bgp':
          if (group.triples.length) {
            if (!currentBgp)
              appendTo(merged, currentBgp = group);
            else
              appendAllTo(currentBgp.triples, group.triples);
          }
          break;
        // All other groups break up a BGP
        default:
          // Only add the group if its pattern is non-empty
          if (!group.patterns || group.patterns.length > 0) {
            appendTo(merged, group);
            currentBgp = null;
          }
      }
    }
    return merged;
  }
/* generated by jison-lex 0.3.4 */
var lexer = (function(){
var lexer = ({

EOF:1,

parseError:function parseError(str, hash) {
        if (this.yy.parser) {
            this.yy.parser.parseError(str, hash);
        } else {
            throw new Error(str);
        }
    },

// resets the lexer, sets new input
setInput:function (input, yy) {
        this.yy = yy || this.yy || {};
        this._input = input;
        this._more = this._backtrack = this.done = false;
        this.yylineno = this.yyleng = 0;
        this.yytext = this.matched = this.match = '';
        this.conditionStack = ['INITIAL'];
        this.yylloc = {
            first_line: 1,
            first_column: 0,
            last_line: 1,
            last_column: 0
        };
        if (this.options.ranges) {
            this.yylloc.range = [0,0];
        }
        this.offset = 0;
        return this;
    },

// consumes and returns one char from the input
input:function () {
        var ch = this._input[0];
        this.yytext += ch;
        this.yyleng++;
        this.offset++;
        this.match += ch;
        this.matched += ch;
        var lines = ch.match(/(?:\r\n?|\n).*/g);
        if (lines) {
            this.yylineno++;
            this.yylloc.last_line++;
        } else {
            this.yylloc.last_column++;
        }
        if (this.options.ranges) {
            this.yylloc.range[1]++;
        }

        this._input = this._input.slice(1);
        return ch;
    },

// unshifts one char (or a string) into the input
unput:function (ch) {
        var len = ch.length;
        var lines = ch.split(/(?:\r\n?|\n)/g);

        this._input = ch + this._input;
        this.yytext = this.yytext.substr(0, this.yytext.length - len);
        //this.yyleng -= len;
        this.offset -= len;
        var oldLines = this.match.split(/(?:\r\n?|\n)/g);
        this.match = this.match.substr(0, this.match.length - 1);
        this.matched = this.matched.substr(0, this.matched.length - 1);

        if (lines.length - 1) {
            this.yylineno -= lines.length - 1;
        }
        var r = this.yylloc.range;

        this.yylloc = {
            first_line: this.yylloc.first_line,
            last_line: this.yylineno + 1,
            first_column: this.yylloc.first_column,
            last_column: lines ?
                (lines.length === oldLines.length ? this.yylloc.first_column : 0)
                 + oldLines[oldLines.length - lines.length].length - lines[0].length :
              this.yylloc.first_column - len
        };

        if (this.options.ranges) {
            this.yylloc.range = [r[0], r[0] + this.yyleng - len];
        }
        this.yyleng = this.yytext.length;
        return this;
    },

// When called from action, caches matched text and appends it on next action
more:function () {
        this._more = true;
        return this;
    },

// When called from action, signals the lexer that this rule fails to match the input, so the next matching rule (regex) should be tested instead.
reject:function () {
        if (this.options.backtrack_lexer) {
            this._backtrack = true;
        } else {
            return this.parseError('Lexical error on line ' + (this.yylineno + 1) + '. You can only invoke reject() in the lexer when the lexer is of the backtracking persuasion (options.backtrack_lexer = true).\n' + this.showPosition(), {
                text: "",
                token: null,
                line: this.yylineno
            });

        }
        return this;
    },

// retain first n characters of the match
less:function (n) {
        this.unput(this.match.slice(n));
    },

// displays already matched input, i.e. for error messages
pastInput:function () {
        var past = this.matched.substr(0, this.matched.length - this.match.length);
        return (past.length > 20 ? '...':'') + past.substr(-20).replace(/\n/g, "");
    },

// displays upcoming input, i.e. for error messages
upcomingInput:function () {
        var next = this.match;
        if (next.length < 20) {
            next += this._input.substr(0, 20-next.length);
        }
        return (next.substr(0,20) + (next.length > 20 ? '...' : '')).replace(/\n/g, "");
    },

// displays the character position where the lexing error occurred, i.e. for error messages
showPosition:function () {
        var pre = this.pastInput();
        var c = new Array(pre.length + 1).join("-");
        return pre + this.upcomingInput() + "\n" + c + "^";
    },

// test the lexed token: return FALSE when not a match, otherwise return token
test_match:function(match, indexed_rule) {
        var token,
            lines,
            backup;

        if (this.options.backtrack_lexer) {
            // save context
            backup = {
                yylineno: this.yylineno,
                yylloc: {
                    first_line: this.yylloc.first_line,
                    last_line: this.last_line,
                    first_column: this.yylloc.first_column,
                    last_column: this.yylloc.last_column
                },
                yytext: this.yytext,
                match: this.match,
                matches: this.matches,
                matched: this.matched,
                yyleng: this.yyleng,
                offset: this.offset,
                _more: this._more,
                _input: this._input,
                yy: this.yy,
                conditionStack: this.conditionStack.slice(0),
                done: this.done
            };
            if (this.options.ranges) {
                backup.yylloc.range = this.yylloc.range.slice(0);
            }
        }

        lines = match[0].match(/(?:\r\n?|\n).*/g);
        if (lines) {
            this.yylineno += lines.length;
        }
        this.yylloc = {
            first_line: this.yylloc.last_line,
            last_line: this.yylineno + 1,
            first_column: this.yylloc.last_column,
            last_column: lines ?
                         lines[lines.length - 1].length - lines[lines.length - 1].match(/\r?\n?/)[0].length :
                         this.yylloc.last_column + match[0].length
        };
        this.yytext += match[0];
        this.match += match[0];
        this.matches = match;
        this.yyleng = this.yytext.length;
        if (this.options.ranges) {
            this.yylloc.range = [this.offset, this.offset += this.yyleng];
        }
        this._more = false;
        this._backtrack = false;
        this._input = this._input.slice(match[0].length);
        this.matched += match[0];
        token = this.performAction.call(this, this.yy, this, indexed_rule, this.conditionStack[this.conditionStack.length - 1]);
        if (this.done && this._input) {
            this.done = false;
        }
        if (token) {
            return token;
        } else if (this._backtrack) {
            // recover context
            for (var k in backup) {
                this[k] = backup[k];
            }
            return false; // rule action called reject() implying the next rule should be tested instead.
        }
        return false;
    },

// return next match in input
next:function () {
        if (this.done) {
            return this.EOF;
        }
        if (!this._input) {
            this.done = true;
        }

        var token,
            match,
            tempMatch,
            index;
        if (!this._more) {
            this.yytext = '';
            this.match = '';
        }
        var rules = this._currentRules();
        for (var i = 0; i < rules.length; i++) {
            tempMatch = this._input.match(this.rules[rules[i]]);
            if (tempMatch && (!match || tempMatch[0].length > match[0].length)) {
                match = tempMatch;
                index = i;
                if (this.options.backtrack_lexer) {
                    token = this.test_match(tempMatch, rules[i]);
                    if (token !== false) {
                        return token;
                    } else if (this._backtrack) {
                        match = false;
                        continue; // rule action called reject() implying a rule MISmatch.
                    } else {
                        // else: this is a lexer rule which consumes input without producing a token (e.g. whitespace)
                        return false;
                    }
                } else if (!this.options.flex) {
                    break;
                }
            }
        }
        if (match) {
            token = this.test_match(match, rules[index]);
            if (token !== false) {
                return token;
            }
            // else: this is a lexer rule which consumes input without producing a token (e.g. whitespace)
            return false;
        }
        if (this._input === "") {
            return this.EOF;
        } else {
            return this.parseError('Lexical error on line ' + (this.yylineno + 1) + '. Unrecognized text.\n' + this.showPosition(), {
                text: "",
                token: null,
                line: this.yylineno
            });
        }
    },

// return next match that has a token
lex:function lex () {
        var r = this.next();
        if (r) {
            return r;
        } else {
            return this.lex();
        }
    },

// activates a new lexer condition state (pushes the new lexer condition state onto the condition stack)
begin:function begin (condition) {
        this.conditionStack.push(condition);
    },

// pop the previously active lexer condition state off the condition stack
popState:function popState () {
        var n = this.conditionStack.length - 1;
        if (n > 0) {
            return this.conditionStack.pop();
        } else {
            return this.conditionStack[0];
        }
    },

// produce the lexer rule set which is active for the currently active lexer condition state
_currentRules:function _currentRules () {
        if (this.conditionStack.length && this.conditionStack[this.conditionStack.length - 1]) {
            return this.conditions[this.conditionStack[this.conditionStack.length - 1]].rules;
        } else {
            return this.conditions["INITIAL"].rules;
        }
    },

// return the currently active lexer condition state; when an index argument is provided it produces the N-th previous condition state, if available
topState:function topState (n) {
        n = this.conditionStack.length - 1 - Math.abs(n || 0);
        if (n >= 0) {
            return this.conditionStack[n];
        } else {
            return "INITIAL";
        }
    },

// alias for begin(condition)
pushState:function pushState (condition) {
        this.begin(condition);
    },

// return the number of states currently on the stack
stateStackSize:function stateStackSize() {
        return this.conditionStack.length;
    },
options: {"flex":true,"case-insensitive":true},
performAction: function anonymous(yy,yy_,$avoiding_name_collisions,YY_START) {
var YYSTATE=YY_START;
switch($avoiding_name_collisions) {
case 0:/* ignore */
break;
case 1:return 12
break;
case 2:return 15
break;
case 3:return 24
break;
case 4:return 290
break;
case 5:return 291
break;
case 6:return 29
break;
case 7:return 31
break;
case 8:return 32
break;
case 9:return 293
break;
case 10:return 34
break;
case 11:return 38
break;
case 12:return 39
break;
case 13:return 41
break;
case 14:return 43
break;
case 15:return 48
break;
case 16:return 51
break;
case 17:return 296
break;
case 18:return 61
break;
case 19:return 62
break;
case 20:return 68
break;
case 21:return 71
break;
case 22:return 74
break;
case 23:return 76
break;
case 24:return 79
break;
case 25:return 81
break;
case 26:return 83
break;
case 27:return 183
break;
case 28:return 99
break;
case 29:return 297
break;
case 30:return 132
break;
case 31:return 298
break;
case 32:return 299
break;
case 33:return 109
break;
case 34:return 300
break;
case 35:return 108
break;
case 36:return 301
break;
case 37:return 302
break;
case 38:return 112
break;
case 39:return 114
break;
case 40:return 115
break;
case 41:return 130
break;
case 42:return 124
break;
case 43:return 125
break;
case 44:return 127
break;
case 45:return 133
break;
case 46:return 111
break;
case 47:return 303
break;
case 48:return 304
break;
case 49:return 159
break;
case 50:return 162
break;
case 51:return 166
break;
case 52:return 92
break;
case 53:return 160
break;
case 54:return 305
break;
case 55:return 165
break;
case 56:return 251
break;
case 57:return 187
break;
case 58:return 306
break;
case 59:return 307
break;
case 60:return 213
break;
case 61:return 309
break;
case 62:return 310
break;
case 63:return 208
break;
case 64:return 215
break;
case 65:return 216
break;
case 66:return 223
break;
case 67:return 227
break;
case 68:return 268
break;
case 69:return 311
break;
case 70:return 312
break;
case 71:return 313
break;
case 72:return 314
break;
case 73:return 315
break;
case 74:return 231
break;
case 75:return 316
break;
case 76:return 246
break;
case 77:return 254
break;
case 78:return 255
break;
case 79:return 248
break;
case 80:return 249
break;
case 81:return 250
break;
case 82:return 317
break;
case 83:return 318
break;
case 84:return 252
break;
case 85:return 320
break;
case 86:return 319
break;
case 87:return 321
break;
case 88:return 257
break;
case 89:return 258
break;
case 90:return 261
break;
case 91:return 263
break;
case 92:return 267
break;
case 93:return 271
break;
case 94:return 274
break;
case 95:return 275
break;
case 96:return 13
break;
case 97:return 16
break;
case 98:return 286
break;
case 99:return 218
break;
case 100:return 28
break;
case 101:return 270
break;
case 102:return 80
break;
case 103:return 272
break;
case 104:return 273
break;
case 105:return 280
break;
case 106:return 281
break;
case 107:return 282
break;
case 108:return 283
break;
case 109:return 284
break;
case 110:return 285
break;
case 111:return 'EXPONENT'
break;
case 112:return 276
break;
case 113:return 277
break;
case 114:return 278
break;
case 115:return 279
break;
case 116:return 86
break;
case 117:return 219
break;
case 118:return 6
break;
case 119:return 'INVALID'
break;
case 120:console.log(yy_.yytext);
break;
}
},
rules: [/^(?:\s+|#[^\n\r]*)/i,/^(?:BASE)/i,/^(?:PREFIX)/i,/^(?:SELECT)/i,/^(?:DISTINCT)/i,/^(?:REDUCED)/i,/^(?:\()/i,/^(?:AS)/i,/^(?:\))/i,/^(?:\*)/i,/^(?:CONSTRUCT)/i,/^(?:WHERE)/i,/^(?:\{)/i,/^(?:\})/i,/^(?:DESCRIBE)/i,/^(?:ASK)/i,/^(?:FROM)/i,/^(?:NAMED)/i,/^(?:GROUP)/i,/^(?:BY)/i,/^(?:HAVING)/i,/^(?:ORDER)/i,/^(?:ASC)/i,/^(?:DESC)/i,/^(?:LIMIT)/i,/^(?:OFFSET)/i,/^(?:VALUES)/i,/^(?:;)/i,/^(?:LOAD)/i,/^(?:SILENT)/i,/^(?:INTO)/i,/^(?:CLEAR)/i,/^(?:DROP)/i,/^(?:CREATE)/i,/^(?:ADD)/i,/^(?:TO)/i,/^(?:MOVE)/i,/^(?:COPY)/i,/^(?:INSERT\s+DATA)/i,/^(?:DELETE\s+DATA)/i,/^(?:DELETE\s+WHERE)/i,/^(?:WITH)/i,/^(?:DELETE)/i,/^(?:INSERT)/i,/^(?:USING)/i,/^(?:DEFAULT)/i,/^(?:GRAPH)/i,/^(?:ALL)/i,/^(?:\.)/i,/^(?:OPTIONAL)/i,/^(?:SERVICE)/i,/^(?:BIND)/i,/^(?:UNDEF)/i,/^(?:MINUS)/i,/^(?:UNION)/i,/^(?:FILTER)/i,/^(?:,)/i,/^(?:a)/i,/^(?:\|)/i,/^(?:\/)/i,/^(?:\^)/i,/^(?:\?)/i,/^(?:\+)/i,/^(?:!)/i,/^(?:\[)/i,/^(?:\])/i,/^(?:\|\|)/i,/^(?:&&)/i,/^(?:=)/i,/^(?:!=)/i,/^(?:<)/i,/^(?:>)/i,/^(?:<=)/i,/^(?:>=)/i,/^(?:IN)/i,/^(?:NOT)/i,/^(?:-)/i,/^(?:BOUND)/i,/^(?:BNODE)/i,/^(?:(RAND|NOW|UUID|STRUUID))/i,/^(?:(LANG|DATATYPE|IRI|URI|ABS|CEIL|FLOOR|ROUND|STRLEN|STR|UCASE|LCASE|ENCODE_FOR_URI|YEAR|MONTH|DAY|HOURS|MINUTES|SECONDS|TIMEZONE|TZ|MD5|SHA1|SHA256|SHA384|SHA512|isIRI|isURI|isBLANK|isLITERAL|isNUMERIC))/i,/^(?:(LANGMATCHES|CONTAINS|STRSTARTS|STRENDS|STRBEFORE|STRAFTER|STRLANG|STRDT|sameTerm))/i,/^(?:CONCAT)/i,/^(?:COALESCE)/i,/^(?:IF)/i,/^(?:REGEX)/i,/^(?:SUBSTR)/i,/^(?:REPLACE)/i,/^(?:EXISTS)/i,/^(?:COUNT)/i,/^(?:SUM|MIN|MAX|AVG|SAMPLE)/i,/^(?:GROUP_CONCAT)/i,/^(?:SEPARATOR)/i,/^(?:\^\^)/i,/^(?:true)/i,/^(?:false)/i,/^(?:(<([^<>\"\{\}\|\^`\\\u0000-\u0020])*>))/i,/^(?:((([A-Z]|[a-z]|[\u00C0-\u00D6]|[\u00D8-\u00F6]|[\u00F8-\u02FF]|[\u0370-\u037D]|[\u037F-\u1FFF]|[\u200C-\u200D]|[\u2070-\u218F]|[\u2C00-\u2FEF]|[\u3001-\uD7FF]|[\uF900-\uFDCF]|[\uFDF0-\uFFFD]|[\uD800-\uDB7F][\uDC00-\uDFFF])(((((?:([A-Z]|[a-z]|[\u00C0-\u00D6]|[\u00D8-\u00F6]|[\u00F8-\u02FF]|[\u0370-\u037D]|[\u037F-\u1FFF]|[\u200C-\u200D]|[\u2070-\u218F]|[\u2C00-\u2FEF]|[\u3001-\uD7FF]|[\uF900-\uFDCF]|[\uFDF0-\uFFFD]|[\uD800-\uDB7F][\uDC00-\uDFFF])|_))|-|[0-9]|\u00B7|[\u0300-\u036F]|[\u203F-\u2040])|\.)*(((?:([A-Z]|[a-z]|[\u00C0-\u00D6]|[\u00D8-\u00F6]|[\u00F8-\u02FF]|[\u0370-\u037D]|[\u037F-\u1FFF]|[\u200C-\u200D]|[\u2070-\u218F]|[\u2C00-\u2FEF]|[\u3001-\uD7FF]|[\uF900-\uFDCF]|[\uFDF0-\uFFFD]|[\uD800-\uDB7F][\uDC00-\uDFFF])|_))|-|[0-9]|\u00B7|[\u0300-\u036F]|[\u203F-\u2040]))?)?:))/i,/^(?:(((([A-Z]|[a-z]|[\u00C0-\u00D6]|[\u00D8-\u00F6]|[\u00F8-\u02FF]|[\u0370-\u037D]|[\u037F-\u1FFF]|[\u200C-\u200D]|[\u2070-\u218F]|[\u2C00-\u2FEF]|[\u3001-\uD7FF]|[\uF900-\uFDCF]|[\uFDF0-\uFFFD]|[\uD800-\uDB7F][\uDC00-\uDFFF])(((((?:([A-Z]|[a-z]|[\u00C0-\u00D6]|[\u00D8-\u00F6]|[\u00F8-\u02FF]|[\u0370-\u037D]|[\u037F-\u1FFF]|[\u200C-\u200D]|[\u2070-\u218F]|[\u2C00-\u2FEF]|[\u3001-\uD7FF]|[\uF900-\uFDCF]|[\uFDF0-\uFFFD]|[\uD800-\uDB7F][\uDC00-\uDFFF])|_))|-|[0-9]|\u00B7|[\u0300-\u036F]|[\u203F-\u2040])|\.)*(((?:([A-Z]|[a-z]|[\u00C0-\u00D6]|[\u00D8-\u00F6]|[\u00F8-\u02FF]|[\u0370-\u037D]|[\u037F-\u1FFF]|[\u200C-\u200D]|[\u2070-\u218F]|[\u2C00-\u2FEF]|[\u3001-\uD7FF]|[\uF900-\uFDCF]|[\uFDF0-\uFFFD]|[\uD800-\uDB7F][\uDC00-\uDFFF])|_))|-|[0-9]|\u00B7|[\u0300-\u036F]|[\u203F-\u2040]))?)?:)((((?:([A-Z]|[a-z]|[\u00C0-\u00D6]|[\u00D8-\u00F6]|[\u00F8-\u02FF]|[\u0370-\u037D]|[\u037F-\u1FFF]|[\u200C-\u200D]|[\u2070-\u218F]|[\u2C00-\u2FEF]|[\u3001-\uD7FF]|[\uF900-\uFDCF]|[\uFDF0-\uFFFD]|[\uD800-\uDB7F][\uDC00-\uDFFF])|_))|:|[0-9]|((%([0-9]|[A-F]|[a-f])([0-9]|[A-F]|[a-f]))|(\\(_|~|\.|-|!|\$|&|'|\(|\)|\*|\+|,|;|=|\/|\?|#|@|%))))(((((?:([A-Z]|[a-z]|[\u00C0-\u00D6]|[\u00D8-\u00F6]|[\u00F8-\u02FF]|[\u0370-\u037D]|[\u037F-\u1FFF]|[\u200C-\u200D]|[\u2070-\u218F]|[\u2C00-\u2FEF]|[\u3001-\uD7FF]|[\uF900-\uFDCF]|[\uFDF0-\uFFFD]|[\uD800-\uDB7F][\uDC00-\uDFFF])|_))|-|[0-9]|\u00B7|[\u0300-\u036F]|[\u203F-\u2040])|\.|:|((%([0-9]|[A-F]|[a-f])([0-9]|[A-F]|[a-f]))|(\\(_|~|\.|-|!|\$|&|'|\(|\)|\*|\+|,|;|=|\/|\?|#|@|%))))*((((?:([A-Z]|[a-z]|[\u00C0-\u00D6]|[\u00D8-\u00F6]|[\u00F8-\u02FF]|[\u0370-\u037D]|[\u037F-\u1FFF]|[\u200C-\u200D]|[\u2070-\u218F]|[\u2C00-\u2FEF]|[\u3001-\uD7FF]|[\uF900-\uFDCF]|[\uFDF0-\uFFFD]|[\uD800-\uDB7F][\uDC00-\uDFFF])|_))|-|[0-9]|\u00B7|[\u0300-\u036F]|[\u203F-\u2040])|:|((%([0-9]|[A-F]|[a-f])([0-9]|[A-F]|[a-f]))|(\\(_|~|\.|-|!|\$|&|'|\(|\)|\*|\+|,|;|=|\/|\?|#|@|%)))))?)))/i,/^(?:(_:(((?:([A-Z]|[a-z]|[\u00C0-\u00D6]|[\u00D8-\u00F6]|[\u00F8-\u02FF]|[\u0370-\u037D]|[\u037F-\u1FFF]|[\u200C-\u200D]|[\u2070-\u218F]|[\u2C00-\u2FEF]|[\u3001-\uD7FF]|[\uF900-\uFDCF]|[\uFDF0-\uFFFD]|[\uD800-\uDB7F][\uDC00-\uDFFF])|_))|[0-9])(((((?:([A-Z]|[a-z]|[\u00C0-\u00D6]|[\u00D8-\u00F6]|[\u00F8-\u02FF]|[\u0370-\u037D]|[\u037F-\u1FFF]|[\u200C-\u200D]|[\u2070-\u218F]|[\u2C00-\u2FEF]|[\u3001-\uD7FF]|[\uF900-\uFDCF]|[\uFDF0-\uFFFD]|[\uD800-\uDB7F][\uDC00-\uDFFF])|_))|-|[0-9]|\u00B7|[\u0300-\u036F]|[\u203F-\u2040])|\.)*(((?:([A-Z]|[a-z]|[\u00C0-\u00D6]|[\u00D8-\u00F6]|[\u00F8-\u02FF]|[\u0370-\u037D]|[\u037F-\u1FFF]|[\u200C-\u200D]|[\u2070-\u218F]|[\u2C00-\u2FEF]|[\u3001-\uD7FF]|[\uF900-\uFDCF]|[\uFDF0-\uFFFD]|[\uD800-\uDB7F][\uDC00-\uDFFF])|_))|-|[0-9]|\u00B7|[\u0300-\u036F]|[\u203F-\u2040]))?))/i,/^(?:([\?\$]((((?:([A-Z]|[a-z]|[\u00C0-\u00D6]|[\u00D8-\u00F6]|[\u00F8-\u02FF]|[\u0370-\u037D]|[\u037F-\u1FFF]|[\u200C-\u200D]|[\u2070-\u218F]|[\u2C00-\u2FEF]|[\u3001-\uD7FF]|[\uF900-\uFDCF]|[\uFDF0-\uFFFD]|[\uD800-\uDB7F][\uDC00-\uDFFF])|_))|[0-9])(((?:([A-Z]|[a-z]|[\u00C0-\u00D6]|[\u00D8-\u00F6]|[\u00F8-\u02FF]|[\u0370-\u037D]|[\u037F-\u1FFF]|[\u200C-\u200D]|[\u2070-\u218F]|[\u2C00-\u2FEF]|[\u3001-\uD7FF]|[\uF900-\uFDCF]|[\uFDF0-\uFFFD]|[\uD800-\uDB7F][\uDC00-\uDFFF])|_))|[0-9]|\u00B7|[\u0300-\u036F]|[\u203F-\u2040])*)))/i,/^(?:(@[a-zA-Z]+(-[a-zA-Z0-9]+)*))/i,/^(?:([0-9]+))/i,/^(?:([0-9]*\.[0-9]+))/i,/^(?:([0-9]+\.[0-9]*([eE][+-]?[0-9]+)|\.([0-9])+([eE][+-]?[0-9]+)|([0-9])+([eE][+-]?[0-9]+)))/i,/^(?:(\+([0-9]+)))/i,/^(?:(\+([0-9]*\.[0-9]+)))/i,/^(?:(\+([0-9]+\.[0-9]*([eE][+-]?[0-9]+)|\.([0-9])+([eE][+-]?[0-9]+)|([0-9])+([eE][+-]?[0-9]+))))/i,/^(?:(-([0-9]+)))/i,/^(?:(-([0-9]*\.[0-9]+)))/i,/^(?:(-([0-9]+\.[0-9]*([eE][+-]?[0-9]+)|\.([0-9])+([eE][+-]?[0-9]+)|([0-9])+([eE][+-]?[0-9]+))))/i,/^(?:([eE][+-]?[0-9]+))/i,/^(?:('(([^\u0027\u005C\u000A\u000D])|(\\[tbnrf\\\"']|\\u([0-9]|[A-F]|[a-f])([0-9]|[A-F]|[a-f])([0-9]|[A-F]|[a-f])([0-9]|[A-F]|[a-f])|\\U([0-9]|[A-F]|[a-f])([0-9]|[A-F]|[a-f])([0-9]|[A-F]|[a-f])([0-9]|[A-F]|[a-f])([0-9]|[A-F]|[a-f])([0-9]|[A-F]|[a-f])([0-9]|[A-F]|[a-f])([0-9]|[A-F]|[a-f])))*'))/i,/^(?:("(([^\u0022\u005C\u000A\u000D])|(\\[tbnrf\\\"']|\\u([0-9]|[A-F]|[a-f])([0-9]|[A-F]|[a-f])([0-9]|[A-F]|[a-f])([0-9]|[A-F]|[a-f])|\\U([0-9]|[A-F]|[a-f])([0-9]|[A-F]|[a-f])([0-9]|[A-F]|[a-f])([0-9]|[A-F]|[a-f])([0-9]|[A-F]|[a-f])([0-9]|[A-F]|[a-f])([0-9]|[A-F]|[a-f])([0-9]|[A-F]|[a-f])))*"))/i,/^(?:('''(('|'')?([^'\\]|(\\[tbnrf\\\"']|\\u([0-9]|[A-F]|[a-f])([0-9]|[A-F]|[a-f])([0-9]|[A-F]|[a-f])([0-9]|[A-F]|[a-f])|\\U([0-9]|[A-F]|[a-f])([0-9]|[A-F]|[a-f])([0-9]|[A-F]|[a-f])([0-9]|[A-F]|[a-f])([0-9]|[A-F]|[a-f])([0-9]|[A-F]|[a-f])([0-9]|[A-F]|[a-f])([0-9]|[A-F]|[a-f]))))*'''))/i,/^(?:("""(("|"")?([^\"\\]|(\\[tbnrf\\\"']|\\u([0-9]|[A-F]|[a-f])([0-9]|[A-F]|[a-f])([0-9]|[A-F]|[a-f])([0-9]|[A-F]|[a-f])|\\U([0-9]|[A-F]|[a-f])([0-9]|[A-F]|[a-f])([0-9]|[A-F]|[a-f])([0-9]|[A-F]|[a-f])([0-9]|[A-F]|[a-f])([0-9]|[A-F]|[a-f])([0-9]|[A-F]|[a-f])([0-9]|[A-F]|[a-f]))))*"""))/i,/^(?:(\((\u0020|\u0009|\u000D|\u000A)*\)))/i,/^(?:(\[(\u0020|\u0009|\u000D|\u000A)*\]))/i,/^(?:$)/i,/^(?:.)/i,/^(?:.)/i],
conditions: {"INITIAL":{"rules":[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120],"inclusive":true}}
});
return lexer;
})();
parser.lexer = lexer;
function Parser () {
  this.yy = {};
}
Parser.prototype = parser;parser.Parser = Parser;
return new Parser;
})();


if (true) {
exports.parser = SparqlParser;
exports.Parser = SparqlParser.Parser;
exports.parse = function () { return SparqlParser.parse.apply(SparqlParser, arguments); };
exports.main = function commonjsMain (args) {
    if (!args[1]) {
        console.log('Usage: '+args[0]+' FILE');
        process.exit(1);
    }
    var source = __webpack_require__(/*! fs */ 0).readFileSync(__webpack_require__(/*! path */ 1).normalize(args[1]), "utf8");
    return exports.parser.parse(source);
};
if ( true && __webpack_require__.c[__webpack_require__.s] === module) {
  exports.main(process.argv.slice(1));
}
}
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(/*! ./../../../../SPARQLMap/node_modules/process/browser.js */ "./node_modules/process/browser.js"), __webpack_require__(/*! ./../../../../SPARQLMap/node_modules/webpack/buildin/module.js */ "./node_modules/webpack/buildin/module.js")(module)))

/***/ }),

/***/ "../sparql-builder/node_modules/sparqljs/sparql.js":
/*!*********************************************************!*\
  !*** ../sparql-builder/node_modules/sparqljs/sparql.js ***!
  \*********************************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

var Parser = __webpack_require__(/*! ./lib/SparqlParser */ "../sparql-builder/node_modules/sparqljs/lib/SparqlParser.js").Parser;
var Generator = __webpack_require__(/*! ./lib/SparqlGenerator */ "../sparql-builder/node_modules/sparqljs/lib/SparqlGenerator.js");

module.exports = {
  /**
   * Creates a SPARQL parser with the given pre-defined prefixes and base IRI
   * @param prefixes { [prefix: string]: string }
   * @param baseIRI string
   */
  Parser: function (prefixes, baseIRI) {
    // Create a copy of the prefixes
    var prefixesCopy = {};
    for (var prefix in prefixes || {})
      prefixesCopy[prefix] = prefixes[prefix];

    // Create a new parser with the given prefixes
    // (Workaround for https://github.com/zaach/jison/issues/241)
    var parser = new Parser();
    parser.parse = function () {
      Parser.base = baseIRI || '';
      Parser.prefixes = Object.create(prefixesCopy);
      return Parser.prototype.parse.apply(parser, arguments);
    };
    parser._resetBlanks = Parser._resetBlanks;
    return parser;
  },
  Generator: Generator,
};


/***/ }),

/***/ "../sparql-builder/src/com/atomgraph/linkeddatahub/query/DescribeBuilder.ts":
/*!**********************************************************************************!*\
  !*** ../sparql-builder/src/com/atomgraph/linkeddatahub/query/DescribeBuilder.ts ***!
  \**********************************************************************************/
/*! exports provided: DescribeBuilder */
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "DescribeBuilder", function() { return DescribeBuilder; });
/* harmony import */ var sparqljs__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! sparqljs */ "../sparql-builder/node_modules/sparqljs/sparql.js");
/* harmony import */ var sparqljs__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(sparqljs__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var _QueryBuilder__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ./QueryBuilder */ "../sparql-builder/src/com/atomgraph/linkeddatahub/query/QueryBuilder.ts");


class DescribeBuilder extends _QueryBuilder__WEBPACK_IMPORTED_MODULE_1__["QueryBuilder"] {
    constructor(describe) {
        super(describe);
    }
    static fromString(queryString, prefixes, baseIRI) {
        let query = new sparqljs__WEBPACK_IMPORTED_MODULE_0__["Parser"](prefixes, baseIRI).parse(queryString);
        if (!query)
            throw new Error("Only DESCIBE is supported");
        return new DescribeBuilder(query);
    }
    static fromQuery(query) {
        return new DescribeBuilder(query);
    }
    static new() {
        return new DescribeBuilder({
            "queryType": "DESCRIBE",
            "variables": [
                "*"
            ],
            "type": "query",
            "prefixes": {}
        });
    }
    variablesAll() {
        this.getQuery().variables = ["*"];
        return this;
    }
    variables(variables) {
        this.getQuery().variables = variables;
        return this;
    }
    variable(term) {
        this.getQuery().variables.push(term);
        return this;
    }
    isVariable(term) {
        return this.getQuery().variables.includes(term);
    }
    getQuery() {
        return super.getQuery();
    }
    build() {
        return super.build();
    }
}


/***/ }),

/***/ "../sparql-builder/src/com/atomgraph/linkeddatahub/query/QueryBuilder.ts":
/*!*******************************************************************************!*\
  !*** ../sparql-builder/src/com/atomgraph/linkeddatahub/query/QueryBuilder.ts ***!
  \*******************************************************************************/
/*! exports provided: QueryBuilder */
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "QueryBuilder", function() { return QueryBuilder; });
/* harmony import */ var sparqljs__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! sparqljs */ "../sparql-builder/node_modules/sparqljs/sparql.js");
/* harmony import */ var sparqljs__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(sparqljs__WEBPACK_IMPORTED_MODULE_0__);

class QueryBuilder {
    constructor(query) {
        this.query = query;
        this.generator = new sparqljs__WEBPACK_IMPORTED_MODULE_0__["Generator"]();
        if (!this.query.prefixes)
            this.query.prefixes = {};
    }
    static fromQuery(query) {
        return new QueryBuilder(query);
    }
    static fromString(queryString, prefixes, baseIRI) {
        let query = new sparqljs__WEBPACK_IMPORTED_MODULE_0__["Parser"](prefixes, baseIRI).parse(queryString);
        if (!query)
            throw new Error("Only SPARQL queries are supported, not updates");
        return new QueryBuilder(query);
    }
    where(pattern) {
        this.getQuery().where = pattern;
        return this;
    }
    wherePattern(pattern) {
        if (!this.getQuery().where)
            this.where([]);
        this.getQuery().where.push(pattern);
        return this;
    }
    bgpTriples(triples) {
        // if the last pattern is BGP, append triples to it instead of adding new BGP
        if (this.getQuery().where) {
            let lastPattern = this.getQuery().where[this.getQuery().where.length - 1];
            if (lastPattern.type === "bgp") {
                lastPattern.triples = lastPattern.triples.concat(triples);
                return this;
            }
        }
        return this.wherePattern(QueryBuilder.bgp(triples));
    }
    bgpTriple(triple) {
        return this.bgpTriples([triple]);
    }
    getQuery() {
        return this.query;
    }
    getGenerator() {
        return this.generator;
    }
    build() {
        return this.getQuery();
    }
    toString() {
        return this.getGenerator().stringify(this.getQuery());
    }
    static term(value) {
        return value;
    }
    static var(varName) {
        return ("?" + varName);
    }
    static literal(value) {
        return ("\"" + value + "\"");
    }
    static typedLiteral(value, datatype) {
        return ("\"" + value + "\"^^" + datatype);
    }
    static uri(value) {
        return value;
    }
    static triple(subject, predicate, object) {
        return {
            "subject": subject,
            "predicate": predicate,
            "object": object
        };
    }
    static bgp(triples) {
        return {
            "type": "bgp",
            "triples": triples
        };
    }
    static graph(name, patterns) {
        return {
            "type": "graph",
            "name": name,
            "patterns": patterns
        };
    }
    static group(patterns) {
        return {
            "type": "group",
            "patterns": patterns
        };
    }
    static union(patterns) {
        return {
            "type": "union",
            "patterns": patterns
        };
    }
    static filter(expression) {
        return {
            "type": "filter",
            "expression": expression
        };
    }
    static operation(operator, args) {
        return {
            "type": "operation",
            "operator": operator,
            "args": args
        };
    }
    static in(term, list) {
        return QueryBuilder.operation("in", [term, list]);
    }
    static regex(term, pattern, caseInsensitive) {
        let expression = {
            "type": "operation",
            "operator": "regex",
            "args": [term, ("\"" + pattern + "\"")]
        };
        if (caseInsensitive)
            expression.args.push("\"i\"");
        return expression;
    }
    static eq(arg1, arg2) {
        return QueryBuilder.operation("=", [arg1, arg2]);
    }
    static str(arg) {
        return QueryBuilder.operation("str", [arg]);
    }
}


/***/ }),

/***/ "../sparql-builder/src/com/atomgraph/linkeddatahub/query/SelectBuilder.ts":
/*!********************************************************************************!*\
  !*** ../sparql-builder/src/com/atomgraph/linkeddatahub/query/SelectBuilder.ts ***!
  \********************************************************************************/
/*! exports provided: SelectBuilder */
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "SelectBuilder", function() { return SelectBuilder; });
/* harmony import */ var sparqljs__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! sparqljs */ "../sparql-builder/node_modules/sparqljs/sparql.js");
/* harmony import */ var sparqljs__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(sparqljs__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var _QueryBuilder__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ./QueryBuilder */ "../sparql-builder/src/com/atomgraph/linkeddatahub/query/QueryBuilder.ts");


class SelectBuilder extends _QueryBuilder__WEBPACK_IMPORTED_MODULE_1__["QueryBuilder"] {
    constructor(select) {
        super(select);
    }
    static fromString(queryString, prefixes, baseIRI) {
        let query = new sparqljs__WEBPACK_IMPORTED_MODULE_0__["Parser"](prefixes, baseIRI).parse(queryString);
        if (!query)
            throw new Error("Only SELECT is supported");
        return new SelectBuilder(query);
    }
    static fromQuery(query) {
        return new SelectBuilder(query);
    }
    variablesAll() {
        this.getQuery().variables = ["*"];
        return this;
    }
    variables(variables) {
        this.getQuery().variables = variables;
        return this;
    }
    variable(term) {
        this.getQuery().variables.push(term);
        return this;
    }
    isVariable(term) {
        return this.getQuery().variables.includes(term);
    }
    orderBy(ordering) {
        if (!this.getQuery().order)
            this.getQuery().order = [];
        this.getQuery().order.push(ordering);
        return this;
    }
    offset(offset) {
        this.getQuery().offset = offset;
        return this;
    }
    limit(limit) {
        this.getQuery().limit = limit;
        return this;
    }
    getQuery() {
        return super.getQuery();
    }
    build() {
        return super.build();
    }
    static ordering(expr, desc) {
        let ordering = {
            "expression": expr,
        };
        if (desc !== undefined && desc == true)
            ordering.descending = desc;
        return ordering;
    }
}


/***/ }),

/***/ "./node_modules/process/browser.js":
/*!*****************************************!*\
  !*** ./node_modules/process/browser.js ***!
  \*****************************************/
/*! no static exports found */
/***/ (function(module, exports) {

// shim for using process in browser
var process = module.exports = {};

// cached from whatever global is present so that test runners that stub it
// don't break things.  But we need to wrap it in a try catch in case it is
// wrapped in strict mode code which doesn't define any globals.  It's inside a
// function because try/catches deoptimize in certain engines.

var cachedSetTimeout;
var cachedClearTimeout;

function defaultSetTimout() {
    throw new Error('setTimeout has not been defined');
}
function defaultClearTimeout () {
    throw new Error('clearTimeout has not been defined');
}
(function () {
    try {
        if (typeof setTimeout === 'function') {
            cachedSetTimeout = setTimeout;
        } else {
            cachedSetTimeout = defaultSetTimout;
        }
    } catch (e) {
        cachedSetTimeout = defaultSetTimout;
    }
    try {
        if (typeof clearTimeout === 'function') {
            cachedClearTimeout = clearTimeout;
        } else {
            cachedClearTimeout = defaultClearTimeout;
        }
    } catch (e) {
        cachedClearTimeout = defaultClearTimeout;
    }
} ())
function runTimeout(fun) {
    if (cachedSetTimeout === setTimeout) {
        //normal enviroments in sane situations
        return setTimeout(fun, 0);
    }
    // if setTimeout wasn't available but was latter defined
    if ((cachedSetTimeout === defaultSetTimout || !cachedSetTimeout) && setTimeout) {
        cachedSetTimeout = setTimeout;
        return setTimeout(fun, 0);
    }
    try {
        // when when somebody has screwed with setTimeout but no I.E. maddness
        return cachedSetTimeout(fun, 0);
    } catch(e){
        try {
            // When we are in I.E. but the script has been evaled so I.E. doesn't trust the global object when called normally
            return cachedSetTimeout.call(null, fun, 0);
        } catch(e){
            // same as above but when it's a version of I.E. that must have the global object for 'this', hopfully our context correct otherwise it will throw a global error
            return cachedSetTimeout.call(this, fun, 0);
        }
    }


}
function runClearTimeout(marker) {
    if (cachedClearTimeout === clearTimeout) {
        //normal enviroments in sane situations
        return clearTimeout(marker);
    }
    // if clearTimeout wasn't available but was latter defined
    if ((cachedClearTimeout === defaultClearTimeout || !cachedClearTimeout) && clearTimeout) {
        cachedClearTimeout = clearTimeout;
        return clearTimeout(marker);
    }
    try {
        // when when somebody has screwed with setTimeout but no I.E. maddness
        return cachedClearTimeout(marker);
    } catch (e){
        try {
            // When we are in I.E. but the script has been evaled so I.E. doesn't  trust the global object when called normally
            return cachedClearTimeout.call(null, marker);
        } catch (e){
            // same as above but when it's a version of I.E. that must have the global object for 'this', hopfully our context correct otherwise it will throw a global error.
            // Some versions of I.E. have different rules for clearTimeout vs setTimeout
            return cachedClearTimeout.call(this, marker);
        }
    }



}
var queue = [];
var draining = false;
var currentQueue;
var queueIndex = -1;

function cleanUpNextTick() {
    if (!draining || !currentQueue) {
        return;
    }
    draining = false;
    if (currentQueue.length) {
        queue = currentQueue.concat(queue);
    } else {
        queueIndex = -1;
    }
    if (queue.length) {
        drainQueue();
    }
}

function drainQueue() {
    if (draining) {
        return;
    }
    var timeout = runTimeout(cleanUpNextTick);
    draining = true;

    var len = queue.length;
    while(len) {
        currentQueue = queue;
        queue = [];
        while (++queueIndex < len) {
            if (currentQueue) {
                currentQueue[queueIndex].run();
            }
        }
        queueIndex = -1;
        len = queue.length;
    }
    currentQueue = null;
    draining = false;
    runClearTimeout(timeout);
}

process.nextTick = function (fun) {
    var args = new Array(arguments.length - 1);
    if (arguments.length > 1) {
        for (var i = 1; i < arguments.length; i++) {
            args[i - 1] = arguments[i];
        }
    }
    queue.push(new Item(fun, args));
    if (queue.length === 1 && !draining) {
        runTimeout(drainQueue);
    }
};

// v8 likes predictible objects
function Item(fun, array) {
    this.fun = fun;
    this.array = array;
}
Item.prototype.run = function () {
    this.fun.apply(null, this.array);
};
process.title = 'browser';
process.browser = true;
process.env = {};
process.argv = [];
process.version = ''; // empty string to avoid regexp issues
process.versions = {};

function noop() {}

process.on = noop;
process.addListener = noop;
process.once = noop;
process.off = noop;
process.removeListener = noop;
process.removeAllListeners = noop;
process.emit = noop;
process.prependListener = noop;
process.prependOnceListener = noop;

process.listeners = function (name) { return [] }

process.binding = function (name) {
    throw new Error('process.binding is not supported');
};

process.cwd = function () { return '/' };
process.chdir = function (dir) {
    throw new Error('process.chdir is not supported');
};
process.umask = function() { return 0; };


/***/ }),

/***/ "./node_modules/webpack/buildin/module.js":
/*!***********************************!*\
  !*** (webpack)/buildin/module.js ***!
  \***********************************/
/*! no static exports found */
/***/ (function(module, exports) {

module.exports = function(module) {
	if (!module.webpackPolyfill) {
		module.deprecate = function() {};
		module.paths = [];
		// module.parent = undefined by default
		if (!module.children) module.children = [];
		Object.defineProperty(module, "loaded", {
			enumerable: true,
			get: function() {
				return module.l;
			}
		});
		Object.defineProperty(module, "id", {
			enumerable: true,
			get: function() {
				return module.i;
			}
		});
		module.webpackPolyfill = 1;
	}
	return module;
};


/***/ }),

/***/ "./src/com/atomgraph/linkeddatahub/client/Map.ts":
/*!*******************************************************!*\
  !*** ./src/com/atomgraph/linkeddatahub/client/Map.ts ***!
  \*******************************************************/
/*! exports provided: Geo */
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "Geo", function() { return Geo; });
/* harmony import */ var _map_MapOverlay__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./map/MapOverlay */ "./src/com/atomgraph/linkeddatahub/client/map/MapOverlay.ts");
/* harmony import */ var _atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_SelectBuilder__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! @atomgraph/SPARQLBuilder/com/atomgraph/linkeddatahub/query/SelectBuilder */ "../sparql-builder/src/com/atomgraph/linkeddatahub/query/SelectBuilder.ts");
/* harmony import */ var _atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_DescribeBuilder__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! @atomgraph/SPARQLBuilder/com/atomgraph/linkeddatahub/query/DescribeBuilder */ "../sparql-builder/src/com/atomgraph/linkeddatahub/query/DescribeBuilder.ts");
/* harmony import */ var _atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_QueryBuilder__WEBPACK_IMPORTED_MODULE_3__ = __webpack_require__(/*! @atomgraph/SPARQLBuilder/com/atomgraph/linkeddatahub/query/QueryBuilder */ "../sparql-builder/src/com/atomgraph/linkeddatahub/query/QueryBuilder.ts");
/* harmony import */ var _atomgraph_URLBuilder_com_atomgraph_linkeddatahub_util_URLBuilder__WEBPACK_IMPORTED_MODULE_4__ = __webpack_require__(/*! @atomgraph/URLBuilder/com/atomgraph/linkeddatahub/util/URLBuilder */ "../URLBuilder/src/com/atomgraph/linkeddatahub/util/URLBuilder.ts");





class Geo {
    constructor(map, endpoint, select, focusVarName, graphVarName) {
        this.addMarkers = (rdfXml) => {
            let descriptions = rdfXml.getElementsByTagNameNS(Geo.RDF_NS, "Description");
            for (let description of descriptions) {
                if (description.hasAttributeNS(Geo.RDF_NS, "about") || description.hasAttributeNS(Geo.RDF_NS, "nodeID")) {
                    let uri = description.getAttributeNS(Geo.RDF_NS, "about");
                    let bnode = description.getAttributeNS(Geo.RDF_NS, "nodeID");
                    let key = null;
                    if (bnode !== null)
                        key = rdfXml.documentURI + "#" + bnode;
                    else
                        key = uri;
                    if (!this.getLoadedResources().has(key)) {
                        let latElems = description.getElementsByTagNameNS(Geo.GEO_NS, "lat");
                        let longElems = description.getElementsByTagNameNS(Geo.GEO_NS, "long");
                        if (latElems.length > 0 && longElems.length > 0) {
                            this.getLoadedResources().set(key, true); // mark resource as loaded
                            let icon = null;
                            let type = null;
                            let typeElems = description.getElementsByTagNameNS(Geo.RDF_NS, "type");
                            if (typeElems.length > 0) {
                                type = typeElems[0].getAttributeNS(Geo.RDF_NS, "resource");
                                if (!this.getTypeIcons().has(type)) {
                                    // icons get recycled when # of different types in response > # of icons
                                    let iconIndex = this.getTypeIcons().size % this.getIcons().length;
                                    icon = this.getIcons()[iconIndex];
                                    this.getTypeIcons().set(type, icon);
                                }
                                else
                                    icon = this.getTypeIcons().get(type);
                            }
                            let latLng = new google.maps.LatLng(latElems[0].textContent, longElems[0].textContent);
                            this.getMarkerBounds().extend(latLng);
                            let markerConfig = {
                                "position": latLng,
                                // "label": label,
                                "map": this.getMap()
                            };
                            let titleElems = description.getElementsByTagNameNS("http://purl.org/dc/terms/", "title"); // TO-DO: call ac:label() via SaxonJS.XPath.evaluate()?
                            if (titleElems.length > 0)
                                markerConfig.title = titleElems[0].textContent;
                            let marker = new google.maps.Marker(markerConfig);
                            if (icon != null)
                                marker.setIcon(icon);
                            // popout InfoWindow for the topic of current document (same as on click)
                            let docs = description.getElementsByTagNameNS(Geo.FOAF_NS, "isPrimaryTopicOf"); // try to get foaf:isPrimaryTopicOf value first
                            if (docs.length === 0)
                                docs = description.getElementsByTagNameNS(Geo.FOAF_NS, "page"); // fallback to foaf:page as a second option
                            if (docs.length > 0 && docs[0].hasAttributeNS(Geo.RDF_NS, "resource")) {
                                let docUri = docs[0].getAttributeNS(Geo.RDF_NS, "resource");
                                this.bindMarkerClick(marker, docUri); // bind loadInfoWindowHTML() to marker onclick
                            }
                        }
                    }
                }
            }
        };
        this.buildQuery = (selectQuery) => {
            return this.buildGeoBoundedQuery(selectQuery, this.getMap().getBounds().getNorthEast().lng(), this.getMap().getBounds().getNorthEast().lat(), this.getMap().getBounds().getSouthWest().lat(), this.getMap().getBounds().getSouthWest().lng()).
                toString();
        };
        this.buildQueryURL = (queryString) => {
            return _atomgraph_URLBuilder_com_atomgraph_linkeddatahub_util_URLBuilder__WEBPACK_IMPORTED_MODULE_4__["URLBuilder"].fromURL(this.getEndpoint()).
                searchParam("query", queryString).
                build();
        };
        this.requestRDFXML = (url) => {
            return fetch(new Request(url, { "headers": { "Accept": "application/rdf+xml" } }));
        };
        this.requestHTML = (url) => {
            return fetch(new Request(url, { "headers": { "Accept": "text/html,*/*;q=0.8" } }));
        };
        this.map = map;
        this.endpoint = endpoint;
        this.select = select;
        this.focusVarName = focusVarName;
        this.graphVarName = graphVarName;
        this.markerBounds = new google.maps.LatLngBounds();
        this.fitBounds = true;
        this.loadedResources = new Map();
        this.icons = ["https://maps.google.com/mapfiles/ms/icons/blue-dot.png",
            "https://maps.google.com/mapfiles/ms/icons/red-dot.png",
            "https://maps.google.com/mapfiles/ms/icons/purple-dot.png",
            "https://maps.google.com/mapfiles/ms/icons/yellow-dot.png",
            "https://maps.google.com/mapfiles/ms/icons/green-dot.png"];
        this.typeIcons = new Map();
    }
    getMap() {
        return this.map;
    }
    ;
    getEndpoint() {
        return this.endpoint;
    }
    getSelect() {
        return this.select;
    }
    getFocusVarName() {
        return this.focusVarName;
    }
    ;
    getGraphVarName() {
        return this.graphVarName;
    }
    ;
    getLoadedResources() {
        return this.loadedResources;
    }
    getLoadedBounds() {
        return this.loadedBounds;
    }
    setLoadedBounds(bounds) {
        this.loadedBounds = bounds;
    }
    getMarkerBounds() {
        return this.markerBounds;
    }
    isFitBounds() {
        return this.fitBounds;
    }
    setFitBounds(fitBounds) {
        this.fitBounds = fitBounds;
    }
    getIcons() {
        return this.icons;
    }
    getTypeIcons() {
        return this.typeIcons;
    }
    loadMarkers(promise) {
        if (this.getMap().getBounds() == null)
            throw Error("Map bounds are null or undefined");
        // do not load markers if the new bounds are within already loaded bounds
        if (this.getLoadedBounds() != null &&
            this.getLoadedBounds().contains(this.getMap().getBounds().getNorthEast()) &&
            this.getLoadedBounds().contains(this.getMap().getBounds().getSouthWest()))
            return;
        let markerOverlay = new _map_MapOverlay__WEBPACK_IMPORTED_MODULE_0__["MapOverlay"](this.getMap(), "marker-progress");
        markerOverlay.show();
        Promise.resolve(_atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_SelectBuilder__WEBPACK_IMPORTED_MODULE_1__["SelectBuilder"].fromString(this.getSelect()).build()).
            then(this.buildQuery).
            then(this.buildQueryURL).
            then(url => url.toString()).
            then(this.requestRDFXML).
            then(response => {
            if (response.ok)
                return response.text();
            throw new Error("Could not load RDF/XML response from '" + response.url + "'");
        }).
            then(this.parseXML).
            then(promise).
            then(() => {
            this.setLoadedBounds(this.getMap().getBounds());
            if (this.isFitBounds() && !this.getMarkerBounds().isEmpty()) {
                this.getMap().fitBounds(this.getMarkerBounds());
                this.setFitBounds(false); // do not fit bounds after the first load
            }
            markerOverlay.hide();
        }).
            catch(error => {
            console.log('HTTP request failed: ', error.message);
        });
    }
    bindMarkerClick(marker, url) {
        let renderInfoWindow = (event) => {
            let overlay = new _map_MapOverlay__WEBPACK_IMPORTED_MODULE_0__["MapOverlay"](this.getMap(), "infowindow-progress");
            overlay.show();
            Promise.resolve(url).
                then(this.buildInfoURL).
                then(url => url.toString()).
                then(this.requestHTML).
                then(response => {
                if (response.ok)
                    return response.text();
                throw new Error("Could not load HTML response from '" + response.url + "'");
            }).
                then(this.parseHTML).
                then(html => {
                // render first child of <body> as InfoWindow content
                let infoContent = html.getElementsByTagNameNS("http://www.w3.org/1999/xhtml", "body")[0].children[0];
                let infoWindow = new google.maps.InfoWindow({ "content": infoContent });
                overlay.hide();
                infoWindow.open(this.getMap(), marker);
            }).
                catch(error => {
                console.log('HTTP request failed: ', error.message);
            });
        };
        marker.addListener("click", renderInfoWindow);
    }
    buildGeoBoundedQuery(selectQuery, east, north, south, west) {
        let boundsPattern = [
            _atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_QueryBuilder__WEBPACK_IMPORTED_MODULE_3__["QueryBuilder"].bgp([
                _atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_QueryBuilder__WEBPACK_IMPORTED_MODULE_3__["QueryBuilder"].triple(_atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_QueryBuilder__WEBPACK_IMPORTED_MODULE_3__["QueryBuilder"].var(this.getFocusVarName()), _atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_QueryBuilder__WEBPACK_IMPORTED_MODULE_3__["QueryBuilder"].uri(Geo.GEO_NS + "lat"), _atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_QueryBuilder__WEBPACK_IMPORTED_MODULE_3__["QueryBuilder"].var("lat")),
                _atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_QueryBuilder__WEBPACK_IMPORTED_MODULE_3__["QueryBuilder"].triple(_atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_QueryBuilder__WEBPACK_IMPORTED_MODULE_3__["QueryBuilder"].var(this.getFocusVarName()), _atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_QueryBuilder__WEBPACK_IMPORTED_MODULE_3__["QueryBuilder"].uri(Geo.GEO_NS + "long"), _atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_QueryBuilder__WEBPACK_IMPORTED_MODULE_3__["QueryBuilder"].var("long"))
            ]),
            _atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_QueryBuilder__WEBPACK_IMPORTED_MODULE_3__["QueryBuilder"].filter(_atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_QueryBuilder__WEBPACK_IMPORTED_MODULE_3__["QueryBuilder"].operation("<", [_atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_QueryBuilder__WEBPACK_IMPORTED_MODULE_3__["QueryBuilder"].var("long"), _atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_QueryBuilder__WEBPACK_IMPORTED_MODULE_3__["QueryBuilder"].typedLiteral(east.toString(), Geo.XSD_NS + "decimal")])),
            _atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_QueryBuilder__WEBPACK_IMPORTED_MODULE_3__["QueryBuilder"].filter(_atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_QueryBuilder__WEBPACK_IMPORTED_MODULE_3__["QueryBuilder"].operation("<", [_atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_QueryBuilder__WEBPACK_IMPORTED_MODULE_3__["QueryBuilder"].var("lat"), _atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_QueryBuilder__WEBPACK_IMPORTED_MODULE_3__["QueryBuilder"].typedLiteral(north.toString(), Geo.XSD_NS + "decimal")])),
            _atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_QueryBuilder__WEBPACK_IMPORTED_MODULE_3__["QueryBuilder"].filter(_atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_QueryBuilder__WEBPACK_IMPORTED_MODULE_3__["QueryBuilder"].operation(">", [_atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_QueryBuilder__WEBPACK_IMPORTED_MODULE_3__["QueryBuilder"].var("lat"), _atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_QueryBuilder__WEBPACK_IMPORTED_MODULE_3__["QueryBuilder"].typedLiteral(south.toString(), Geo.XSD_NS + "decimal")])),
            _atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_QueryBuilder__WEBPACK_IMPORTED_MODULE_3__["QueryBuilder"].filter(_atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_QueryBuilder__WEBPACK_IMPORTED_MODULE_3__["QueryBuilder"].operation(">", [_atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_QueryBuilder__WEBPACK_IMPORTED_MODULE_3__["QueryBuilder"].var("long"), _atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_QueryBuilder__WEBPACK_IMPORTED_MODULE_3__["QueryBuilder"].typedLiteral(west.toString(), Geo.XSD_NS + "decimal")]))
        ];
        let builder = _atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_DescribeBuilder__WEBPACK_IMPORTED_MODULE_2__["DescribeBuilder"].new().
            variables([_atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_QueryBuilder__WEBPACK_IMPORTED_MODULE_3__["QueryBuilder"].var(this.getFocusVarName())]).
            wherePattern(_atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_QueryBuilder__WEBPACK_IMPORTED_MODULE_3__["QueryBuilder"].group([selectQuery]));
        if (this.getGraphVarName() !== undefined)
            return builder.wherePattern(_atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_QueryBuilder__WEBPACK_IMPORTED_MODULE_3__["QueryBuilder"].union([_atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_QueryBuilder__WEBPACK_IMPORTED_MODULE_3__["QueryBuilder"].group(boundsPattern), _atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_QueryBuilder__WEBPACK_IMPORTED_MODULE_3__["QueryBuilder"].graph(_atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_QueryBuilder__WEBPACK_IMPORTED_MODULE_3__["QueryBuilder"].var(this.getGraphVarName()), boundsPattern)]));
        else
            return builder.wherePattern(_atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_QueryBuilder__WEBPACK_IMPORTED_MODULE_3__["QueryBuilder"].group(boundsPattern));
    }
    buildInfoURL(url) {
        return _atomgraph_URLBuilder_com_atomgraph_linkeddatahub_util_URLBuilder__WEBPACK_IMPORTED_MODULE_4__["URLBuilder"].fromString(url).
            searchParam("mode", Geo.APLT_NS + "InfoWindowMode").
            hash(null).
            build();
    }
    parseXML(str) {
        return (new DOMParser()).parseFromString(str, "text/xml");
    }
    parseHTML(str) {
        return (new DOMParser()).parseFromString(str, "text/html");
    }
}
Geo.RDF_NS = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
Geo.XSD_NS = "http://www.w3.org/2001/XMLSchema#";
Geo.APLT_NS = "https://w3id.org/atomgraph/linkeddatahub/templates#";
Geo.GEO_NS = "http://www.w3.org/2003/01/geo/wgs84_pos#";
Geo.FOAF_NS = "http://xmlns.com/foaf/0.1/";


/***/ }),

/***/ "./src/com/atomgraph/linkeddatahub/client/map/MapOverlay.ts":
/*!******************************************************************!*\
  !*** ./src/com/atomgraph/linkeddatahub/client/map/MapOverlay.ts ***!
  \******************************************************************/
/*! exports provided: MapOverlay */
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "MapOverlay", function() { return MapOverlay; });
class MapOverlay {
    constructor(map, id) {
        let div = map.getDiv().ownerDocument.getElementById(id);
        if (div !== null)
            this.div = div;
        else {
            this.div = map.getDiv().ownerDocument.createElement("div");
            this.div.id = id;
            this.div.className = "progress progress-striped active";
            // need to set CSS properties programmatically
            this.div.style.position = "absolute";
            this.div.style.top = "17em";
            this.div.style.zIndex = "2";
            this.div.style.width = "24%";
            this.div.style.left = "38%";
            this.div.style.right = "38%";
            this.div.style.padding = "10px";
            this.div.style.visibility = "hidden";
            var barDiv = map.getDiv().ownerDocument.createElement("div");
            barDiv.className = "bar";
            barDiv.style.width = "100%";
            this.div.appendChild(barDiv);
            map.getDiv().appendChild(this.div);
        }
    }
    show() {
        this.div.style.visibility = "visible";
    }
    ;
    hide() {
        this.div.style.visibility = "hidden";
    }
    ;
}


/***/ }),

/***/ 0:
/*!********************!*\
  !*** fs (ignored) ***!
  \********************/
/*! no static exports found */
/***/ (function(module, exports) {

/* (ignored) */

/***/ }),

/***/ 1:
/*!**********************!*\
  !*** path (ignored) ***!
  \**********************/
/*! no static exports found */
/***/ (function(module, exports) {

/* (ignored) */

/***/ })

/******/ });
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIndlYnBhY2s6Ly9TUEFSUUxNYXAvd2VicGFjay9ib290c3RyYXAiLCJ3ZWJwYWNrOi8vU1BBUlFMTWFwLy4uL1VSTEJ1aWxkZXIvc3JjL2NvbS9hdG9tZ3JhcGgvbGlua2VkZGF0YWh1Yi91dGlsL1VSTEJ1aWxkZXIudHMiLCJ3ZWJwYWNrOi8vU1BBUlFMTWFwLy4uL3NwYXJxbC1idWlsZGVyL25vZGVfbW9kdWxlcy9zcGFycWxqcy9saWIvU3BhcnFsR2VuZXJhdG9yLmpzIiwid2VicGFjazovL1NQQVJRTE1hcC8uLi9zcGFycWwtYnVpbGRlci9ub2RlX21vZHVsZXMvc3BhcnFsanMvbGliL1NwYXJxbFBhcnNlci5qcyIsIndlYnBhY2s6Ly9TUEFSUUxNYXAvLi4vc3BhcnFsLWJ1aWxkZXIvbm9kZV9tb2R1bGVzL3NwYXJxbGpzL3NwYXJxbC5qcyIsIndlYnBhY2s6Ly9TUEFSUUxNYXAvLi4vc3BhcnFsLWJ1aWxkZXIvc3JjL2NvbS9hdG9tZ3JhcGgvbGlua2VkZGF0YWh1Yi9xdWVyeS9EZXNjcmliZUJ1aWxkZXIudHMiLCJ3ZWJwYWNrOi8vU1BBUlFMTWFwLy4uL3NwYXJxbC1idWlsZGVyL3NyYy9jb20vYXRvbWdyYXBoL2xpbmtlZGRhdGFodWIvcXVlcnkvUXVlcnlCdWlsZGVyLnRzIiwid2VicGFjazovL1NQQVJRTE1hcC8uLi9zcGFycWwtYnVpbGRlci9zcmMvY29tL2F0b21ncmFwaC9saW5rZWRkYXRhaHViL3F1ZXJ5L1NlbGVjdEJ1aWxkZXIudHMiLCJ3ZWJwYWNrOi8vU1BBUlFMTWFwLy4vbm9kZV9tb2R1bGVzL3Byb2Nlc3MvYnJvd3Nlci5qcyIsIndlYnBhY2s6Ly9TUEFSUUxNYXAvKHdlYnBhY2spL2J1aWxkaW4vbW9kdWxlLmpzIiwid2VicGFjazovL1NQQVJRTE1hcC8uL3NyYy9jb20vYXRvbWdyYXBoL2xpbmtlZGRhdGFodWIvY2xpZW50L01hcC50cyIsIndlYnBhY2s6Ly9TUEFSUUxNYXAvLi9zcmMvY29tL2F0b21ncmFwaC9saW5rZWRkYXRhaHViL2NsaWVudC9tYXAvTWFwT3ZlcmxheS50cyIsIndlYnBhY2s6Ly9TUEFSUUxNYXAvZnMgKGlnbm9yZWQpIiwid2VicGFjazovL1NQQVJRTE1hcC9wYXRoIChpZ25vcmVkKSJdLCJuYW1lcyI6W10sIm1hcHBpbmdzIjoiOztRQUFBO1FBQ0E7O1FBRUE7UUFDQTs7UUFFQTtRQUNBO1FBQ0E7UUFDQTtRQUNBO1FBQ0E7UUFDQTtRQUNBO1FBQ0E7UUFDQTs7UUFFQTtRQUNBOztRQUVBO1FBQ0E7O1FBRUE7UUFDQTtRQUNBOzs7UUFHQTtRQUNBOztRQUVBO1FBQ0E7O1FBRUE7UUFDQTtRQUNBO1FBQ0EsMENBQTBDLGdDQUFnQztRQUMxRTtRQUNBOztRQUVBO1FBQ0E7UUFDQTtRQUNBLHdEQUF3RCxrQkFBa0I7UUFDMUU7UUFDQSxpREFBaUQsY0FBYztRQUMvRDs7UUFFQTtRQUNBO1FBQ0E7UUFDQTtRQUNBO1FBQ0E7UUFDQTtRQUNBO1FBQ0E7UUFDQTtRQUNBO1FBQ0EseUNBQXlDLGlDQUFpQztRQUMxRSxnSEFBZ0gsbUJBQW1CLEVBQUU7UUFDckk7UUFDQTs7UUFFQTtRQUNBO1FBQ0E7UUFDQSwyQkFBMkIsMEJBQTBCLEVBQUU7UUFDdkQsaUNBQWlDLGVBQWU7UUFDaEQ7UUFDQTtRQUNBOztRQUVBO1FBQ0Esc0RBQXNELCtEQUErRDs7UUFFckg7UUFDQTs7O1FBR0E7UUFDQTs7Ozs7Ozs7Ozs7OztBQ2xGQTtBQUFBO0FBQUE7Ozs7Ozs7Ozs7Ozs7O0dBY0c7QUFFSSxNQUFNLFVBQVU7SUFLbkIsWUFBc0IsR0FBUTtRQUUxQixJQUFJLENBQUMsR0FBRyxHQUFHLElBQUksR0FBRyxDQUFDLEdBQUcsQ0FBQyxRQUFRLEVBQUUsQ0FBQyxDQUFDLENBQUMsb0RBQW9EO0lBQzVGLENBQUM7SUFBQSxDQUFDO0lBRUY7Ozs7O09BS0c7SUFDSSxJQUFJLENBQUMsSUFBbUI7UUFFM0IsSUFBSSxJQUFJLElBQUksSUFBSTtZQUFFLElBQUksQ0FBQyxHQUFHLENBQUMsSUFBSSxHQUFHLEVBQUUsQ0FBQzs7WUFD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QUNBO0FBQ0E7QUFDQSxDQUFDO0FBQ0Q7QUFDQTtBQUNBO0FBQ0E7QUFDQSx1QkFBdUIsT0FBTztBQUM5QjtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBLEtBQUs7QUFDTDtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBLCtEQUErRDtBQUMvRDtBQUNBO0FBQ0E7QUFDQTtBQUNBLFNBQVM7QUFDVDtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQSxpQkFBaUI7QUFDakI7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBLGlCQUFpQjtBQUNqQjtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBLGFBQWE7QUFDYjtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7O0FBRUE7QUFDQTtBQUNBOztBQUVBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOztBQUVBOztBQUVBO0FBQ0E7QUFDQTtBQUNBOztBQUVBO0FBQ0E7QUFDQTtBQUNBOztBQUVBO0FBQ0E7QUFD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Q2I7QUFDQSxLQUFLOztBQUVMO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQSxTQUFTO0FBQ1Q7QUFDQTtBQUNBLEtBQUs7O0FBRUw7QUFDQTtBQUNBO0FBQ0EsS0FBSzs7QUFFTDtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0EsU0FBUztBQUNUO0FBQ0E7QUFDQSxLQUFLOztBQUVMO0FBQ0E7QUFDQTtBQUNBO0FBQ0EsU0FBUztBQUNUO0FBQ0E7QUFDQSxLQUFLOztBQUVMLHFEQUFxRDtBQUNyRDtBQUNBO0FBQ0E7QUFDQTtBQUNBLFNBQVM7QUFDVDtBQUNBO0FBQ0EsS0FBSzs7QUFFTDtBQUNBO0FBQ0E7QUFDQSxLQUFLOztBQUVMO0FBQ0E7QUFDQTtBQUNBLEtBQUs7QUFDTCxVQUFVLG9DQUFvQztBQUM5QztBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQSxDQUFDO0FBQ0QsNkxBQTZMLFdBQVcsNkxBQTZMLCt0Q0FBK3RDLEVBQUUscTVEQUFxNUQsK1hBQStYLDRYQUE0WDtBQUN0dkksYUFBYSxXQUFXO0FBQ3hCLENBQUM7QUFDRDtBQUNBLENBQUM7QUFDRDtBQUNBO0FBQ0E7QUFDQTtBQUNBLDBCQUEwQjtBQUMxQjtBQUNBLENBQUM7OztBQUdELElBQUksSUFBZ0U7QUFDcEU7QUFDQTtBQUNBLDZCQUE2QiwwREFBMEQ7QUFDdkY7QUFDQTtBQUNBO0FBQ0E7QUFD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QUMsS0FBSyxDQUFDLFVBQVUsR0FBRyxRQUFRLENBQUM7SUFDekMsQ0FBQztJQUFBLENBQUM7Q0FFTDs7Ozs7Ozs7Ozs7O0FDN0NELGU7Ozs7Ozs7Ozs7O0FDQUEsZSIsImZpbGUiOiJTUEFSUUxNYXAuanMiLCJzb3VyY2VzQ29udGVudCI6WyIgXHQvLyBUaGUgbW9kdWxlIGNhY2hlXG4gXHR2YXIgaW5zdGFsbGVkTW9kdWxlcyA9IHt9O1xuXG4gXHQvLyBUaGUgcmVxdWlyZSBmdW5jdGlvblxuIFx0ZnVuY3Rpb24gX193ZWJwYWNrX3JlcXVpcmVfXyhtb2R1bGVJZCkge1xuXG4gXHRcdC8vIENoZWNrIGlmIG1vZHVsZSBpcyBpbiBjYWNoZVxuIFx0XHRpZihpbnN0YWxsZWRNb2R1bGVzW21vZHVsZUlkXSkge1xuIFx0XHRcdHJldHVybiBpbnN0YWxsZWRNb2R1bGVzW21vZHVsZUlkXS5leHBvcnRzO1xuIFx0XHR9XG4gXHRcdC8vIENyZWF0ZSBhIG5ldyBtb2R1bGUgKGFuZCBwdXQgaXQgaW50byB0aGUgY2FjaGUpXG4gXHRcdHZhciBtb2R1bGUgPSBpbnN0YWxsZWRNb2R1bGVzW21vZHVsZUlkXSA9IHtcbiBcdFx0XHRpOiBtb2R1bGVJZCxcbiBcdFx0XHRsOiBmYWxzZSxcbiBcdFx0XHRleHBvcnRzOiB7fVxuIFx0XHR9O1xuXG4gXHRcdC8vIEV4ZWN1dGUgdGhlIG1vZHVsZSBmdW5jdGlvblxuIFx0XHRtb2R1bGVzW21vZHVsZUlkXS5jYWxsKG1vZHVsZS5leHBvcnRzLCBtb2R1bGUsIG1vZHVsZS5leHBvcnRzLCBfX3dlYnBhY2tfcmVxdWlyZV9fKTtcblxuIFx0XHQvLyBGbGFnIHRoZSBtb2R1bGUgYXMgbG9hZGVkXG4gXHRcdG1vZHVsZS5sID0gdHJ1ZTtcblxuIFx0XHQvLyBSZXR1cm4gdGhlIGV4cG9ydHMgb2YgdGhlIG1vZHVsZVxuIFx0XHRyZXR1cm4gbW9kdWxlLmV4cG9ydHM7XG4gXHR9XG5cblxuIFx0Ly8gZXhwb3NlIHRoZSBtb2R1bGVzIG9iamVjdCAoX193ZWJwYWNrX21vZHVsZXNfXylcbiBcdF9fd2VicGFja19yZXF1aXJlX18ubSA9IG1vZHVsZXM7XG5cbiBcdC8vIGV4cG9zZSB0aGUgbW9kdWxlIGNhY2hlXG4gXHRfX3dlYnBhY2tfcmVxdWlyZV9fLmMgPSBpbnN0YWxsZWRNb2R1bGVzO1xuXG4gXHQvLyBkZWZpbmUgZ2V0dGVyIGZ1bmN0aW9uIGZvciBoYXJtb255IGV4cG9ydHNcbiBcdF9fd2VicGFja19yZXF1aXJlX18uZCA9IGZ1bmN0aW9uKGV4cG9ydHMsIG5hbWUsIGdldHRlcikge1xuIFx0XHRpZighX193ZWJwYWNrX3JlcXVpcmVfXy5vKGV4cG9ydHMsIG5hbWUpKSB7XG4gXHRcdFx0T2JqZWN0LmRlZmluZVByb3BlcnR5KGV4cG9ydHMsIG5hbWUsIHsgZW51bWVyYWJsZTogdHJ1ZSwgZ2V0OiBnZXR0ZXIgfSk7XG4gXHRcdH1cbiBcdH07XG5cbiBcdC8vIGRlZmluZSBfX2VzTW9kdWxlIG9uIGV4cG9ydHNcbiBcdF9fd2VicGFja19yZXF1aXJlX18uciA9IGZ1bmN0aW9uKGV4cG9ydHMpIHtcbiBcdFx0aWYodHlwZW9mIFN5bWJvbCAhPT0gJ3VuZGVmaW5lZCcgJiYgU3ltYm9sLnRvU3RyaW5nVGFnKSB7XG4gXHRcdFx0T2JqZWN0LmRlZmluZVByb3BlcnR5KGV4cG9ydHMsIFN5bWJvbC50b1N0cmluZ1RhZywgeyB2YWx1ZTogJ01vZHVsZScgfSk7XG4gXHRcdH1cbiBcdFx0T2JqZWN0LmRlZmluZVByb3BlcnR5KGV4cG9ydHMsICdfX2VzTW9kdWxlJywgeyB2YWx1ZTogdHJ1ZSB9KTtcbiBcdH07XG5cbiBcdC8vIGNyZWF0ZSBhIGZha2UgbmFtZXNwYWNlIG9iamVjdFxuIFx0Ly8gbW9kZSAmIDE6IHZhbHVlIGlzIGEgbW9kdWxlIGlkLCByZXF1aXJlIGl0XG4gXHQvLyBtb2RlICYgMjogbWVyZ2UgYWxsIHByb3BlcnRpZXMgb2YgdmFsdWUgaW50byB0aGUgbnNcbiBcdC8vIG1vZGUgJiA0OiByZXR1cm4gdmFsdWUgd2hlbiBhbHJlYWR5IG5zIG9iamVjdFxuIFx0Ly8gbW9kZSAmIDh8MTogYmVoYXZlIGxpa2UgcmVxdWlyZVxuIFx0X193ZWJwYWNrX3JlcXVpcmVfXy50ID0gZnVuY3Rpb24odmFsdWUsIG1vZGUpIHtcbiBcdFx0aWYobW9kZSAmIDEpIHZhbHVlID0gX193ZWJwYWNrX3JlcXVpcmVfXyh2YWx1ZSk7XG4gXHRcdGlmKG1vZGUgJiA4KSByZXR1cm4gdmFsdWU7XG4gXHRcdGlmKChtb2RlICYgNCkgJiYgdHlwZW9mIHZhbHVlID09PSAnb2JqZWN0JyAmJiB2YWx1ZSAmJiB2YWx1ZS5fX2VzTW9kdWxlKSByZXR1cm4gdmFsdWU7XG4gXHRcdHZhciBucyA9IE9iamVjdC5jcmVhdGUobnVsbCk7XG4gXHRcdF9fd2VicGFja19yZXF1aXJlX18ucihucyk7XG4gXHRcdE9iamVjdC5kZWZpbmVQcm9wZXJ0eShucywgJ2RlZmF1bHQnLCB7IGVudW1lcmFibGU6IHRydWUsIHZhbHVlOiB2YWx1ZSB9KTtcbiBcdFx0aWYobW9kZSAmIDIgJiYgdHlwZW9mIHZhbHVlICE9ICdzdHJpbmcnKSBmb3IodmFyIGtleSBpbiB2YWx1ZSkgX193ZWJwYWNrX3JlcXVpcmVfXy5kKG5zLCBrZXksIGZ1bmN0aW9uKGtleSkgeyByZXR1cm4gdmFsdWVba2V5XTsgfS5iaW5kKG51bGwsIGtleSkpO1xuIFx0XHRyZXR1cm4gbnM7XG4gXHR9O1xuXG4gXHQvLyBnZXREZWZhdWx0RXhwb3J0IGZ1bmN0aW9uIGZvciBjb21wYXRpYmlsaXR5IHdpdGggbm9uLWhhcm1vbnkgbW9kdWxlc1xuIFx0X193ZWJwYWNrX3JlcXVpcmVfXy5uID0gZnVuY3Rpb24obW9kdWxlKSB7XG4gXHRcdHZhciBnZXR0ZXIgPSBtb2R1bGUgJiYgbW9kdWxlLl9fZXNNb2R1bGUgP1xuIFx0XHRcdGZ1bmN0aW9uIGdldERlZmF1bHQoKSB7IHJldHVybiBtb2R1bGVbJ2RlZmF1bHQnXTsgfSA6XG4gXHRcdFx0ZnVuY3Rpb24gZ2V0TW9kdWxlRXhwb3J0cygpIHsgcmV0dXJuIG1vZHVsZTsgfTtcbiBcdFx0X193ZWJwYWNrX3JlcXVpcmVfXy5kKGdldHRlciwgJ2EnLCBnZXR0ZXIpO1xuIFx0XHRyZXR1cm4gZ2V0dGVyO1xuIFx0fTtcblxuIFx0Ly8gT2JqZWN0LnByb3RvdHlwZS5oYXNPd25Qcm9wZXJ0eS5jYWxsXG4gXHRfX3dlYnBhY2tfcmVxdWlyZV9fLm8gPSBmdW5jdGlvbihvYmplY3QsIHByb3BlcnR5KSB7IHJldHVybiBPYmplY3QucHJvdG90eXBlLmhhc093blByb3BlcnR5LmNhbGwob2JqZWN0LCBwcm9wZXJ0eSk7IH07XG5cbiBcdC8vIF9fd2VicGFja19wdWJsaWNfcGF0aF9fXG4gXHRfX3dlYnBhY2tfcmVxdWlyZV9fLnAgPSBcIlwiO1xuXG5cbiBcdC8vIExvYWQgZW50cnkgbW9kdWxlIGFuZCByZXR1cm4gZXhwb3J0c1xuIFx0cmV0dXJuIF9fd2VicGFja19yZXF1aXJlX18oX193ZWJwYWNrX3JlcXVpcmVfXy5zID0gXCIuL3NyYy9jb20vYXRvbWdyYXBoL2xpbmtlZGRhdGFodWIvY2xpZW50L01hcC50c1wiKTtcbiIsIi8qKlxuICogIFVSTEJ1aWxkZXIgY2xhc3MgZm9yIGVhc2llciBjb21wb3NpdGlvbiBvZiBVUkxzLlxuICogIFxuICogIEV4YW1wbGUgdXNhZ2U6XG4gKiAgXG4gKiAgVVJMQnVpbGRlci5mcm9tVVJMKFwiaHR0cHM6Ly9hdG9tZ3JhcGguY29tXCIpLnBhdGgoXCJjYXNlc1wiKS5wYXRoKFwibnhwLXNlbWljb25kdWN0b3JzXCIpLmJ1aWxkKCkudG9TdHJpbmcoKTtcbiAqICBcbiAqICBXaWxsIHJldHVybjpcbiAqICBcbiAqICBcImh0dHBzOi8vYXRvbWdyYXBoLmNvbS9jYXNlcy9ueHAtc2VtaWNvbmR1Y3RvcnNcIlxuICogIFxuICogIFRoaXMgaW1wbGVtZW50YXRpb24gZG9lcyBub3Qgc3VwcG9ydCB2YXJpYWJsZSB0ZW1wbGF0ZXMgc3VjaCBhcyB7dmFyfSBhcyBvZiB5ZXQuXG4gKiAgXG4gKiAgQGF1dGhvciBNYXJ0eW5hcyBKdXNldmnEjWl1cyA8bWFydHluYXNAYXRvbWdyYXBoLmNvbT5cbiAqL1xuXG5leHBvcnQgY2xhc3MgVVJMQnVpbGRlclxue1xuXG4gICAgcHJpdmF0ZSByZWFkb25seSB1cmw6IFVSTDtcblxuICAgIHByb3RlY3RlZCBjb25zdHJ1Y3Rvcih1cmw6IFVSTClcbiAgICB7XG4gICAgICAgIHRoaXMudXJsID0gbmV3IFVSTCh1cmwudG9TdHJpbmcoKSk7IC8vIGNsb25lIHRoZSBvYmplY3QsIHNvIHdlIGRvbid0IGNoYW5nZSB0aGUgb3JpZ2luYWxcbiAgICB9O1xuXG4gICAgLyoqXG4gICAgICogU2V0IGhhc2ggKHdpdGhvdXQgXCIjXCIpXG4gICAgICogXG4gICAgICogQHBhcmFtIHN0cmluZyBoYXNoXG4gICAgICogQHJldHVybnMge1VSTEJ1aWxkZXJ9XG4gICAgICovXG4gICAgcHVibGljIGhhc2goaGFzaDogc3RyaW5nIHwgbnVsbCk6IFVSTEJ1aWxkZXJcbiAgICB7XG4gICAgICAgIGlmIChoYXNoID09IG51bGwpIHRoaXMudXJsLmhhc2ggPSBcIlwiO1xuICAgICAgICBlbHNlIHRoaXMudXJsLmhhc2ggPSBcIiNcIiArIGhhc2g7XG5cbiAgICAgICAgcmV0dXJuIHRoaXM7XG4gICAgfTtcblxuICAgIC8qKlxuICAgICAqIFNldCBob3N0XG4gICAgICogXG4gICAgICogQHBhcmFtIHN0cmluZyBob3N0XG4gICAgICogQHJldHVybnMge1VSTEJ1aWxkZXJ9XG4gICAgICovXG4gICAgcHVibGljIGhvc3QoaG9zdDogc3RyaW5nKTogVVJMQnVpbGRlclxuICAgIHtcbiAgICAgICAgdGhpcy51cmwuaG9zdCA9IGhvc3Q7XG5cbiAgICAgICAgcmV0dXJuIHRoaXM7XG4gICAgfTtcblxuICAgIC8qKlxuICAgICAqIFNldCBob3N0bmFtZVxuICAgICAqIFxuICAgICAqIEBwYXJhbSBzdHJpbmcgaG9zdG5hbWVcbiAgICAgKiBAcmV0dXJucyB7VVJMQnVpbGRlcn1cbiAgICAgKi9cbiAgICBwdWJsaWMgaG9zdG5hbWUoaG9zdG5hbWU6IHN0cmluZyk6IFVSTEJ1aWxkZXJcbiAgICB7XG4gICAgICAgIHRoaXMudXJsLmhvc3RuYW1lID0gaG9zdG5hbWU7XG5cbiAgICAgICAgcmV0dXJuIHRoaXM7XG4gICAgfTtcblxuICAgIC8qKlxuICAgICAqIFNldCBwYXNzd29yZFxuICAgICAqIFxuICAgICAqIEBwYXJhbSBzdHJpbmcgcGFzc3dvcmRcbiAgICAgKiBAcmV0dXJuIHtVUkxCdWlsZGVyfVxuICAgICAqL1xuICAgIHB1YmxpYyBwYXNzd29yZChwYXNzd29yZDogc3RyaW5nKTogVVJMQnVpbGRlclxuICAgIHtcbiAgICAgICAgdGhpcy51cmwucGFzc3dvcmQgPSBwYXNzd29yZDtcblxuICAgICAgICByZXR1cm4gdGhpcztcbiAgICB9O1xuXG4gICAgLyoqXG4gICAgICogQXBwZW5kIHBhdGggXG4gICAgICogXG4gICAgICogQHBhcmFtIHN0cmluZyBwYXRoXG4gICAgICogQHJldHVybnMge1VSTEJ1aWxkZXJ9XG4gICAgICovXG4gICAgcHVibGljIHBhdGgocGF0aDogc3RyaW5nIHwgbnVsbCk6IFVSTEJ1aWxkZXJcbiAgICB7XG4gICAgICAgIGlmIChwYXRoID09IG51bGwpIHRoaXMudXJsLnBhdGhuYW1lID0gXCJcIjtcbiAgICAgICAgZWxzZVxuICAgICAgICB7XG4gICAgICAgICAgICBpZiAodGhpcy51cmwucGF0aG5hbWUubGVuZ3RoID09PSAwKVxuICAgICAgICAgICAge1xuICAgICAgICAgICAgICAgIGlmICghcGF0aC5zdGFydHNXaXRoKFwiL1wiKSkgcGF0aCA9IFwiL1wiICsgcGF0aDtcbiAgICAgICAgICAgICAgICB0aGlzLnVybC5wYXRobmFtZSA9IHBhdGg7XG4gICAgICAgICAgICB9XG4gICAgICAgICAgICBlbHNlXG4gICAgICAgICAgICB7XG4gICAgICAgICAgICAgICAgaWYgKCFwYXRoLnN0YXJ0c1dpdGgoXCIvXCIpICYmICF0aGlzLnVybC5wYXRobmFtZS5lbmRzV2l0aChcIi9cIikpIHBhdGggPSBcIi9cIiArIHBhdGg7XG4gICAgICAgICAgICAgICAgdGhpcy51cmwucGF0aG5hbWUgKz0gcGF0aDtcbiAgICAgICAgICAgIH1cbiAgICAgICAgfVxuXG4gICAgICAgIHJldHVybiB0aGlzO1xuICAgIH07XG5cbiAgICAvKipcbiAgICAgKiBTZXQgcG9ydFxuICAgICAqIFxuICAgICAqIEBwYXJhbSBzdHJpbmcgcG9ydFxuICAgICAqIEByZXR1cm5zIHtVUkxCdWlsZGVyfVxuICAgICAqL1xuICAgIHB1YmxpYyBwb3J0KHBvcnQ6IHN0cmluZyB8IG51bGwpOiBVUkxCdWlsZGVyXG4gICAge1xuICAgICAgICBpZiAocG9ydCA9PSBudWxsKSB0aGlzLnVybC5wb3J0ID0gXCJcIjtcbiAgICAgICAgZWxzZSB0aGlzLnVybC5wb3J0ID0gcG9ydDtcblxuICAgICAgICByZXR1cm4gdGhpcztcbiAgICB9O1xuXG4gICAgLyoqXG4gICAgICogU2V0IHByb3RvY29sXG4gICAgICogXG4gICAgICogQHBhcmFtIHN0cmluZyBwcm90b2NvbFxuICAgICAqIEByZXR1cm4ge1VSTEJ1aWxkZXJ9XG4gICAgICovXG4gICAgcHVibGljIHByb3RvY29sKHByb3RvY29sOiBzdHJpbmcpOiBVUkxCdWlsZGVyXG4gICAge1xuICAgICAgICB0aGlzLnVybC5wcm90b2NvbCA9IHByb3RvY29sO1xuXG4gICAgICAgIHJldHVybiB0aGlzO1xuICAgIH07XG5cbiAgICAvKipcbiAgICAgKiBTZXQgYSBxdWVyeSBzdHJpbmcgKHdpdGggbGVhZGluZyBcIj9cIilcbiAgICAgKiBcbiAgICAgKiBAcGFyYW0gc3RyaW5nIHNlYXJjaFxuICAgICAqIEByZXR1cm5zIHtVUkxCdWlsZGVyfVxuICAgICAqL1xuICAgIHB1YmxpYyBzZWFyY2goc2VhcmNoOiBzdHJpbmcgfCBudWxsKTogVVJMQnVpbGRlclxuICAgIHtcbiAgICAgICAgaWYgKHNlYXJjaCA9PSBudWxsKSB0aGlzLnVybC5zZWFyY2ggPSBcIlwiO1xuICAgICAgICBlbHNlIHRoaXMudXJsLnNlYXJjaCA9IHNlYXJjaDtcblxuICAgICAgICByZXR1cm4gdGhpcztcbiAgICB9O1xuXG4gICAgLyoqXG4gICAgICogQWRkIGEgcXVlcnkgbmFtZT12YWx1ZSBwYWlyLlxuICAgICAqIE11bHRpcGxlIHZhbHVlcyBhcmUgYWxsb3dlZC5cbiAgICAgKiBcbiAgICAgKiBAcGFyYW0gc3RyaW5nIG5hbWVcbiAgICAgKiBAcGFyYW0gc3RyaW5nIHZhbHVlXG4gICAgICogQHJldHVybnMge1VSTEJ1aWxkZXJ9XG4gICAgICovXG4gICAgcHVibGljIHNlYXJjaFBhcmFtKG5hbWU6IHN0cmluZywgLi4udmFsdWVzOiBzdHJpbmdbXSk6IFVSTEJ1aWxkZXJcbiAgICB7XG4gICAgICAgIGZvciAobGV0IHZhbHVlIG9mIHZhbHVlcylcbiAgICAgICAgICAgIHRoaXMudXJsLnNlYXJjaFBhcmFtcy5hcHBlbmQobmFtZSwgdmFsdWUpO1xuXG4gICAgICAgIHJldHVybiB0aGlzO1xuICAgIH07XG5cbiAgICAvKipcbiAgICAgKiBSZXBsYWNlIGEgcXVlcnkgcGFyYW1cbiAgICAgKiBNdWx0aXBsZSB2YWx1ZXMgYXJlIGFsbG93ZWQuXG4gICAgICpcbiAgICAgKiBAcGFyYW0gc3RyaW5nIG5hbWVcbiAgICAgKiBAcGFyYW0gc3RyaW5nIHZhbHVlXG4gICAgICogQHJldHVybnMge1VSTEJ1aWxkZXJ9XG4gICAgICovXG4gICAgcHVibGljIHJlcGxhY2VTZWFyY2hQYXJhbShuYW1lOiBzdHJpbmcsIC4uLnZhbHVlczogc3RyaW5nW10pOiBVUkxCdWlsZGVyXG4gICAge1xuICAgICAgICB0aGlzLnVybC5zZWFyY2hQYXJhbXMuZGVsZXRlKG5hbWUpO1xuXG4gICAgICAgIGZvciAobGV0IHZhbHVlIG9mIHZhbHVlcylcbiAgICAgICAgICAgIHRoaXMudXJsLnNlYXJjaFBhcmFtcy5hcHBlbmQobmFtZSwgdmFsdWUpO1xuXG4gICAgICAgIHJldHVybiB0aGlzO1xuICAgIH07XG5cbiAgICAvKipcbiAgICAgKiBTZXQgdXNlcm5hbWVcbiAgICAgKiBcbiAgICAgKiBAcGFyYW0gc3RyaW5nIHVzZXJuYW1lXG4gICAgICogQHJldHVybiB7VVJMQnVpbGRlcn1cbiAgICAgKi9cbiAgICBwdWJsaWMgdXNlcm5hbWUodXNlcm5hbWU6IHN0cmluZyk6IFVSTEJ1aWxkZXJcbiAgICB7XG4gICAgICAgIHRoaXMudXJsLnVzZXJuYW1lID0gdXNlcm5hbWU7XG5cbiAgICAgICAgcmV0dXJuIHRoaXM7XG4gICAgfTtcblxuICAgIC8qKlxuICAgICAqIEJ1aWxkIFVSTCBvYmplY3RcbiAgICAgKiBcbiAgICAgKiBAcmV0dXJucyB7VVJMfVxuICAgICAqL1xuICAgIHB1YmxpYyBidWlsZCgpOiBVUkxcbiAgICB7XG4gICAgICAgIHJldHVybiB0aGlzLnVybDtcbiAgICB9O1xuXG4gICAgLyoqXG4gICAgICogQ3JlYXRlIGEgbmV3IGluc3RhbmNlIGZyb20gYW4gZXhpc3RpbmcgVVJMLlxuICAgICAqIFxuICAgICAqIEBwYXJhbSBVUkwgdXJsXG4gICAgICogQHJldHVybnMge1VSTEJ1aWxkZXJ9XG4gICAgICovXG4gICAgcHVibGljIHN0YXRpYyBmcm9tVVJMKHVybDogVVJMKTogVVJMQnVpbGRlclxuICAgIHtcbiAgICAgICAgcmV0dXJuIG5ldyBVUkxCdWlsZGVyKHVybCk7XG4gICAgfTtcblxuICAgIC8qKlxuICAgICAqIENyZWF0ZSBhIG5ldyBpbnN0YW5jZSBmcm9tIHN0cmluZyBhbmQgb3B0aW9uYWwgYmFzZS5cbiAgICAgKiBcbiAgICAgKiBAcGFyYW0gc3RyaW5nIHVybFxuICAgICAqIEBwYXJhbSBzdHJpbmcgYmFzZVxuICAgICAqIEByZXR1cm5zIHtVUkxCdWlsZGVyfVxuICAgICAqL1xuICAgIHB1YmxpYyBzdGF0aWMgZnJvbVN0cmluZyh1cmw6IHN0cmluZywgYmFzZT86IHN0cmluZyk6IFVSTEJ1aWxkZXJcbiAgICB7XG4gICAgICAgIHJldHVybiBuZXcgVVJMQnVpbGRlcihuZXcgVVJMKHVybCwgYmFzZSkpO1xuICAgIH07XG5cbn0iLCJ2YXIgWFNEX0lOVEVHRVIgPSAnaHR0cDovL3d3dy53My5vcmcvMjAwMS9YTUxTY2hlbWEjaW50ZWdlcic7XG5cbmZ1bmN0aW9uIEdlbmVyYXRvcihvcHRpb25zLCBwcmVmaXhlcykge1xuICB0aGlzLl9vcHRpb25zID0gb3B0aW9ucyA9IG9wdGlvbnMgfHwge307XG5cbiAgcHJlZml4ZXMgPSBwcmVmaXhlcyB8fCB7fTtcbiAgdGhpcy5fcHJlZml4QnlJcmkgPSB7fTtcbiAgdmFyIHByZWZpeElyaXMgPSBbXTtcbiAgZm9yICh2YXIgcHJlZml4IGluIHByZWZpeGVzKSB7XG4gICAgdmFyIGlyaSA9IHByZWZpeGVzW3ByZWZpeF07XG4gICAgaWYgKGlzU3RyaW5nKGlyaSkpIHtcbiAgICAgIHRoaXMuX3ByZWZpeEJ5SXJpW2lyaV0gPSBwcmVmaXg7XG4gICAgICBwcmVmaXhJcmlzLnB1c2goaXJpKTtcbiAgICB9XG4gIH1cbiAgdmFyIGlyaUxpc3QgPSBwcmVmaXhJcmlzLmpvaW4oJ3wnKS5yZXBsYWNlKC9bXFxdXFwvXFwoXFwpXFwqXFwrXFw/XFwuXFxcXFxcJF0vZywgJ1xcXFwkJicpO1xuICB0aGlzLl9wcmVmaXhSZWdleCA9IG5ldyBSZWdFeHAoJ14oJyArIGlyaUxpc3QgKyAnKShbYS16QS1aXVtcXFxcLV9hLXpBLVowLTldKikkJyk7XG4gIHRoaXMuX3VzZWRQcmVmaXhlcyA9IHt9O1xuICB0aGlzLl9pbmRlbnQgPSAgaXNTdHJpbmcob3B0aW9ucy5pbmRlbnQpICA/IG9wdGlvbnMuaW5kZW50ICA6ICcgICc7XG4gIHRoaXMuX25ld2xpbmUgPSBpc1N0cmluZyhvcHRpb25zLm5ld2xpbmUpID8gb3B0aW9ucy5uZXdsaW5lIDogJ1xcbic7XG59XG5cbi8vIENvbnZlcnRzIHRoZSBwYXJzZWQgcXVlcnkgb2JqZWN0IGludG8gYSBTUEFSUUwgcXVlcnlcbkdlbmVyYXRvci5wcm90b3R5cGUudG9RdWVyeSA9IGZ1bmN0aW9uIChxKSB7XG4gIHZhciBxdWVyeSA9ICcnO1xuXG4gIGlmIChxLnF1ZXJ5VHlwZSlcbiAgICBxdWVyeSArPSBxLnF1ZXJ5VHlwZS50b1VwcGVyQ2FzZSgpICsgJyAnO1xuICBpZiAocS5yZWR1Y2VkKVxuICAgIHF1ZXJ5ICs9ICdSRURVQ0VEICc7XG4gIGlmIChxLmRpc3RpbmN0KVxuICAgIHF1ZXJ5ICs9ICdESVNUSU5DVCAnO1xuXG4gIGlmIChxLnZhcmlhYmxlcylcbiAgICBxdWVyeSArPSBtYXBKb2luKHEudmFyaWFibGVzLCB1bmRlZmluZWQsIGZ1bmN0aW9uICh2YXJpYWJsZSkge1xuICAgICAgcmV0dXJuIGlzU3RyaW5nKHZhcmlhYmxlKSA/IHRoaXMudG9FbnRpdHkodmFyaWFibGUpIDpcbiAgICAgICAgICAgICAnKCcgKyB0aGlzLnRvRXhwcmVzc2lvbih2YXJpYWJsZS5leHByZXNzaW9uKSArICcgQVMgJyArIHZhcmlhYmxlLnZhcmlhYmxlICsgJyknO1xuICAgIH0sIHRoaXMpICsgJyAnO1xuICBlbHNlIGlmIChxLnRlbXBsYXRlKVxuICAgIHF1ZXJ5ICs9IHRoaXMuZ3JvdXAocS50ZW1wbGF0ZSwgdHJ1ZSkgKyB0aGlzLl9uZXdsaW5lO1xuXG4gIGlmIChxLmZyb20pXG4gICAgcXVlcnkgKz0gbWFwSm9pbihxLmZyb20uZGVmYXVsdCB8fCBbXSwgJycsIGZ1bmN0aW9uIChnKSB7IHJldHVybiAnRlJPTSAnICsgdGhpcy50b0VudGl0eShnKSArIHRoaXMuX25ld2xpbmU7IH0sIHRoaXMpICtcbiAgICAgICAgICAgICBtYXBKb2luKHEuZnJvbS5uYW1lZCB8fCBbXSwgJycsIGZ1bmN0aW9uIChnKSB7IHJldHVybiAnRlJPTSBOQU1FRCAnICsgdGhpcy50b0VudGl0eShnKSArIHRoaXMuX25ld2xpbmU7IH0sIHRoaXMpO1xuICBpZiAocS53aGVyZSlcbiAgICBxdWVyeSArPSAnV0hFUkUgJyArIHRoaXMuZ3JvdXAocS53aGVyZSwgdHJ1ZSkgKyB0aGlzLl9uZXdsaW5lO1xuXG4gIGlmIChxLnVwZGF0ZXMpXG4gICAgcXVlcnkgKz0gbWFwSm9pbihxLnVwZGF0ZXMsICc7JyArIHRoaXMuX25ld2xpbmUsIHRoaXMudG9VcGRhdGUsIHRoaXMpO1xuXG4gIGlmIChxLmdyb3VwKVxuICAgIHF1ZXJ5ICs9ICdHUk9VUCBCWSAnICsgbWFwSm9pbihxLmdyb3VwLCB1bmRlZmluZWQsIGZ1bmN0aW9uIChpdCkge1xuICAgICAgdmFyIHJlc3VsdCA9IGlzU3RyaW5nKGl0LmV4cHJlc3Npb24pID8gaXQuZXhwcmVzc2lvbiA6ICcoJyArIHRoaXMudG9FeHByZXNzaW9uKGl0LmV4cHJlc3Npb24pICsgJyknO1xuICAgICAgcmV0dXJuIGl0LnZhcmlhYmxlID8gJygnICsgcmVzdWx0ICsgJyBBUyAnICsgaXQudmFyaWFibGUgKyAnKScgOiByZXN1bHQ7XG4gICAgfSwgdGhpcykgKyB0aGlzLl9uZXdsaW5lO1xuICBpZiAocS5oYXZpbmcpXG4gICAgcXVlcnkgKz0gJ0hBVklORyAoJyArIG1hcEpvaW4ocS5oYXZpbmcsIHVuZGVmaW5lZCwgdGhpcy50b0V4cHJlc3Npb24sIHRoaXMpICsgJyknICsgdGhpcy5fbmV3bGluZTtcbiAgaWYgKHEub3JkZXIpXG4gICAgcXVlcnkgKz0gJ09SREVSIEJZICcgKyBtYXBKb2luKHEub3JkZXIsIHVuZGVmaW5lZCwgZnVuY3Rpb24gKGl0KSB7XG4gICAgICB2YXIgZXhwciA9ICcoJyArIHRoaXMudG9FeHByZXNzaW9uKGl0LmV4cHJlc3Npb24pICsgJyknO1xuICAgICAgcmV0dXJuICFpdC5kZXNjZW5kaW5nID8gZXhwciA6ICdERVNDICcgKyBleHByO1xuICAgIH0sIHRoaXMpICsgdGhpcy5fbmV3bGluZTtcblxuICBpZiAocS5vZmZzZXQpXG4gICAgcXVlcnkgKz0gJ09GRlNFVCAnICsgcS5vZmZzZXQgKyB0aGlzLl9uZXdsaW5lO1xuICBpZiAocS5saW1pdClcbiAgICBxdWVyeSArPSAnTElNSVQgJyArIHEubGltaXQgKyB0aGlzLl9uZXdsaW5lO1xuXG4gIGlmIChxLnZhbHVlcylcbiAgICBxdWVyeSArPSB0aGlzLnZhbHVlcyhxKTtcblxuICAvLyBzdHJpbmdpZnkgcHJlZml4ZXMgYXQgdGhlIGVuZCB0byBtYXJrIHVzZWQgb25lc1xuICBxdWVyeSA9IHRoaXMuYmFzZUFuZFByZWZpeGVzKHEpICsgcXVlcnk7XG4gIHJldHVybiBxdWVyeS50cmltKCk7XG59O1xuXG5HZW5lcmF0b3IucHJvdG90eXBlLmJhc2VBbmRQcmVmaXhlcyA9IGZ1bmN0aW9uIChxKSB7XG4gIHZhciBiYXNlID0gcS5iYXNlID8gKCdCQVNFIDwnICsgcS5iYXNlICsgJz4nICsgdGhpcy5fbmV3bGluZSkgOiAnJztcbiAgdmFyIHByZWZpeGVzID0gJyc7XG4gIGZvciAodmFyIGtleSBpbiBxLnByZWZpeGVzKSB7XG4gICAgaWYgKHRoaXMuX29wdGlvbnMuYWxsUHJlZml4ZXMgfHwgdGhpcy5fdXNlZFByZWZpeGVzW2tleV0pXG4gICAgICBwcmVmaXhlcyArPSAnUFJFRklYICcgKyBrZXkgKyAnOiA8JyArIHEucHJlZml4ZXNba2V5XSArICc+JyArIHRoaXMuX25ld2xpbmU7XG4gIH1cbiAgcmV0dXJuIGJhc2UgKyBwcmVmaXhlcztcbn07XG5cbi8vIENvbnZlcnRzIHRoZSBwYXJzZWQgU1BBUlFMIHBhdHRlcm4gaW50byBhIFNQQVJRTCBwYXR0ZXJuXG5HZW5lcmF0b3IucHJvdG90eXBlLnRvUGF0dGVybiA9IGZ1bmN0aW9uIChwYXR0ZXJuKSB7XG4gIHZhciB0eXBlID0gcGF0dGVybi50eXBlIHx8IChwYXR0ZXJuIGluc3RhbmNlb2YgQXJyYXkpICYmICdhcnJheScgfHxcbiAgICAgICAgICAgICAocGF0dGVybi5zdWJqZWN0ICYmIHBhdHRlcm4ucHJlZGljYXRlICYmIHBhdHRlcm4ub2JqZWN0ID8gJ3RyaXBsZScgOiAnJyk7XG4gIGlmICghKHR5cGUgaW4gdGhpcykpXG4gICAgdGhyb3cgbmV3IEVycm9yKCdVbmtub3duIGVudHJ5IHR5cGU6ICcgKyB0eXBlKTtcbiAgcmV0dXJuIHRoaXNbdHlwZV0ocGF0dGVybik7XG59O1xuXG5HZW5lcmF0b3IucHJvdG90eXBlLnRyaXBsZSA9IGZ1bmN0aW9uICh0KSB7XG4gIHJldHVybiB0aGlzLnRvRW50aXR5KHQuc3ViamVjdCkgKyAnICcgKyB0aGlzLnRvRW50aXR5KHQucHJlZGljYXRlKSArICcgJyArIHRoaXMudG9FbnRpdHkodC5vYmplY3QpICsgJy4nO1xufTtcblxuR2VuZXJhdG9yLnByb3RvdHlwZS5hcnJheSA9IGZ1bmN0aW9uIChpdGVtcykge1xuICByZXR1cm4gbWFwSm9pbihpdGVtcywgdGhpcy5fbmV3bGluZSwgdGhpcy50b1BhdHRlcm4sIHRoaXMpO1xufTtcblxuR2VuZXJhdG9yLnByb3RvdHlwZS5iZ3AgPSBmdW5jdGlvbiAoYmdwKSB7XG4gIHJldHVybiB0aGlzLmVuY29kZVRyaXBsZXMoYmdwLnRyaXBsZXMpO1xufTtcblxuR2VuZXJhdG9yLnByb3RvdHlwZS5lbmNvZGVUcmlwbGVzID0gZnVuY3Rpb24gKHRyaXBsZXMpIHtcbiAgaWYgKCF0cmlwbGVzLmxlbmd0aClcbiAgICByZXR1cm4gJyc7XG5cbiAgdmFyIHBhcnRzID0gW10sIHN1YmplY3QgPSAnJywgcHJlZGljYXRlID0gJyc7XG4gIGZvciAodmFyIGkgPSAwOyBpIDwgdHJpcGxlcy5sZW5ndGg7IGkrKykge1xuICAgIHZhciB0cmlwbGUgPSB0cmlwbGVzW2ldO1xuICAgIC8vIFRyaXBsZSB3aXRoIGRpZmZlcmVudCBzdWJqZWN0XG4gICAgaWYgKHRyaXBsZS5zdWJqZWN0ICE9PSBzdWJqZWN0KSB7XG4gICAgICAvLyBUZXJtaW5hdGUgcHJldmlvdXMgdHJpcGxlXG4gICAgICBpZiAoc3ViamVjdClcbiAgICAgICAgcGFydHMucHVzaCgnLicgKyB0aGlzLl9uZXdsaW5lKTtcbiAgICAgIHN1YmplY3QgPSB0cmlwbGUuc3ViamVjdDtcbiAgICAgIHByZWRpY2F0ZSA9IHRyaXBsZS5wcmVkaWNhdGU7XG4gICAgICBwYXJ0cy5wdXNoKHRoaXMudG9FbnRpdHkoc3ViamVjdCksICcgJywgdGhpcy50b0VudGl0eShwcmVkaWNhdGUpKTtcbiAgICB9XG4gICAgLy8gVHJpcGxlIHdpdGggc2FtZSBzdWJqZWN0IGJ1dCBkaWZmZXJlbnQgcHJlZGljYXRlXG4gICAgZWxzZSBpZiAodHJpcGxlLnByZWRpY2F0ZSAhPT0gcHJlZGljYXRlKSB7XG4gICAgICBwcmVkaWNhdGUgPSB0cmlwbGUucHJlZGljYXRlO1xuICAgICAgcGFydHMucHVzaCgnOycgKyB0aGlzLl9uZXdsaW5lLCB0aGlzLl9pbmRlbnQsIHRoaXMudG9FbnRpdHkocHJlZGljYXRlKSk7XG4gICAgfVxuICAgIC8vIFRyaXBsZSB3aXRoIHNhbWUgc3ViamVjdCBhbmQgcHJlZGljYXRlXG4gICAgZWxzZSB7XG4gICAgICBwYXJ0cy5wdXNoKCcsJyk7XG4gICAgfVxuICAgIHBhcnRzLnB1c2goJyAnLCB0aGlzLnRvRW50aXR5KHRyaXBsZS5vYmplY3QpKTtcbiAgfVxuICBwYXJ0cy5wdXNoKCcuJyk7XG5cbiAgcmV0dXJuIHBhcnRzLmpvaW4oJycpO1xufVxuXG5HZW5lcmF0b3IucHJvdG90eXBlLmdyYXBoID0gZnVuY3Rpb24gKGdyYXBoKSB7XG4gIHJldHVybiAnR1JBUEggJyArIHRoaXMudG9FbnRpdHkoZ3JhcGgubmFtZSkgKyAnICcgKyB0aGlzLmdyb3VwKGdyYXBoKTtcbn07XG5cbkdlbmVyYXRvci5wcm90b3R5cGUuZ3JvdXAgPSBmdW5jdGlvbiAoZ3JvdXAsIGlubGluZSkge1xuICBncm91cCA9IGlubGluZSAhPT0gdHJ1ZSA/IHRoaXMuYXJyYXkoZ3JvdXAucGF0dGVybnMgfHwgZ3JvdXAudHJpcGxlcylcbiAgICAgICAgICAgICAgICAgICAgICAgICAgOiB0aGlzLnRvUGF0dGVybihncm91cC50eXBlICE9PSAnZ3JvdXAnID8gZ3JvdXAgOiBncm91cC5wYXR0ZXJucyk7XG4gIHJldHVybiBncm91cC5pbmRleE9mKHRoaXMuX25ld2xpbmUpID09PSAtMSA/ICd7ICcgKyBncm91cCArICcgfScgOiAneycgKyB0aGlzLl9uZXdsaW5lICsgdGhpcy5pbmRlbnQoZ3JvdXApICsgdGhpcy5fbmV3bGluZSArICd9Jztcbn07XG5cbkdlbmVyYXRvci5wcm90b3R5cGUucXVlcnkgPSBmdW5jdGlvbiAocXVlcnkpIHtcbiAgcmV0dXJuIHRoaXMudG9RdWVyeShxdWVyeSk7XG59O1xuXG5HZW5lcmF0b3IucHJvdG90eXBlLmZpbHRlciA9IGZ1bmN0aW9uIChmaWx0ZXIpIHtcbiAgcmV0dXJuICdGSUxURVIoJyArIHRoaXMudG9FeHByZXNzaW9uKGZpbHRlci5leHByZXNzaW9uKSArICcpJztcbn07XG5cbkdlbmVyYXRvci5wcm90b3R5cGUuYmluZCA9IGZ1bmN0aW9uIChiaW5kKSB7XG4gIHJldHVybiAnQklORCgnICsgdGhpcy50b0V4cHJlc3Npb24oYmluZC5leHByZXNzaW9uKSArICcgQVMgJyArIGJpbmQudmFyaWFibGUgKyAnKSc7XG59O1xuXG5HZW5lcmF0b3IucHJvdG90eXBlLm9wdGlvbmFsID0gZnVuY3Rpb24gKG9wdGlvbmFsKSB7XG4gIHJldHVybiAnT1BUSU9OQUwgJyArIHRoaXMuZ3JvdXAob3B0aW9uYWwpO1xufTtcblxuR2VuZXJhdG9yLnByb3RvdHlwZS51bmlvbiA9IGZ1bmN0aW9uICh1bmlvbikge1xuICByZXR1cm4gbWFwSm9pbih1bmlvbi5wYXR0ZXJucywgdGhpcy5fbmV3bGluZSArICdVTklPTicgKyB0aGlzLl9uZXdsaW5lLCBmdW5jdGlvbiAocCkgeyByZXR1cm4gdGhpcy5ncm91cChwLCB0cnVlKTsgfSwgdGhpcyk7XG59O1xuXG5HZW5lcmF0b3IucHJvdG90eXBlLm1pbnVzID0gZnVuY3Rpb24gKG1pbnVzKSB7XG4gIHJldHVybiAnTUlOVVMgJyArIHRoaXMuZ3JvdXAobWludXMpO1xufTtcblxuR2VuZXJhdG9yLnByb3RvdHlwZS52YWx1ZXMgPSBmdW5jdGlvbiAodmFsdWVzTGlzdCkge1xuICAvLyBHYXRoZXIgdW5pcXVlIGtleXNcbiAgdmFyIGtleXMgPSBPYmplY3Qua2V5cyh2YWx1ZXNMaXN0LnZhbHVlcy5yZWR1Y2UoZnVuY3Rpb24gKGtleUhhc2gsIHZhbHVlcykge1xuICAgIGZvciAodmFyIGtleSBpbiB2YWx1ZXMpIGtleUhhc2hba2V5XSA9IHRydWU7XG4gICAgcmV0dXJuIGtleUhhc2g7XG4gIH0sIHt9KSk7XG4gIC8vIENoZWNrIHdoZXRoZXIgc2ltcGxlIHN5bnRheCBjYW4gYmUgdXNlZFxuICB2YXIgbHBhcmVuLCBycGFyZW47XG4gIGlmIChrZXlzLmxlbmd0aCA9PT0gMSkge1xuICAgIGxwYXJlbiA9IHJwYXJlbiA9ICcnO1xuICB9IGVsc2Uge1xuICAgIGxwYXJlbiA9ICcoJztcbiAgICBycGFyZW4gPSAnKSc7XG4gIH1cbiAgLy8gQ3JlYXRlIHZhbHVlIHJvd3NcbiAgcmV0dXJuICdWQUxVRVMgJyArIGxwYXJlbiArIGtleXMuam9pbignICcpICsgcnBhcmVuICsgJyB7JyArIHRoaXMuX25ld2xpbmUgK1xuICAgIG1hcEpvaW4odmFsdWVzTGlzdC52YWx1ZXMsIHRoaXMuX25ld2xpbmUsIGZ1bmN0aW9uICh2YWx1ZXMpIHtcbiAgICAgIHJldHVybiAnICAnICsgbHBhcmVuICsgbWFwSm9pbihrZXlzLCB1bmRlZmluZWQsIGZ1bmN0aW9uIChrZXkpIHtcbiAgICAgICAgcmV0dXJuIHZhbHVlc1trZXldICE9PSB1bmRlZmluZWQgPyB0aGlzLnRvRW50aXR5KHZhbHVlc1trZXldKSA6ICdVTkRFRic7XG4gICAgICB9LCB0aGlzKSArIHJwYXJlbjtcbiAgICB9LCB0aGlzKSArIHRoaXMuX25ld2xpbmUgKyAnfSc7XG59O1xuXG5HZW5lcmF0b3IucHJvdG90eXBlLnNlcnZpY2UgPSBmdW5jdGlvbiAoc2VydmljZSkge1xuICByZXR1cm4gJ1NFUlZJQ0UgJyArIChzZXJ2aWNlLnNpbGVudCA/ICdTSUxFTlQgJyA6ICcnKSArIHRoaXMudG9FbnRpdHkoc2VydmljZS5uYW1lKSArICcgJyArXG4gICAgICAgICB0aGlzLmdyb3VwKHNlcnZpY2UpO1xufTtcblxuLy8gQ29udmVydHMgdGhlIHBhcnNlZCBleHByZXNzaW9uIG9iamVjdCBpbnRvIGEgU1BBUlFMIGV4cHJlc3Npb25cbkdlbmVyYXRvci5wcm90b3R5cGUudG9FeHByZXNzaW9uID0gZnVuY3Rpb24gKGV4cHIpIHtcbiAgaWYgKGlzU3RyaW5nKGV4cHIpKVxuICAgIHJldHVybiB0aGlzLnRvRW50aXR5KGV4cHIpO1xuXG4gIHN3aXRjaCAoZXhwci50eXBlLnRvTG93ZXJDYXNlKCkpIHtcbiAgICBjYXNlICdhZ2dyZWdhdGUnOlxuICAgICAgcmV0dXJuIGV4cHIuYWdncmVnYXRpb24udG9VcHBlckNhc2UoKSArXG4gICAgICAgICAgICAgJygnICsgKGV4cHIuZGlzdGluY3QgPyAnRElTVElOQ1QgJyA6ICcnKSArIHRoaXMudG9FeHByZXNzaW9uKGV4cHIuZXhwcmVzc2lvbikgK1xuICAgICAgICAgICAgIChleHByLnNlcGFyYXRvciA/ICc7IFNFUEFSQVRPUiA9ICcgKyB0aGlzLnRvRW50aXR5KCdcIicgKyBleHByLnNlcGFyYXRvciArICdcIicpIDogJycpICsgJyknO1xuICAgIGNhc2UgJ2Z1bmN0aW9uY2FsbCc6XG4gICAgICByZXR1cm4gdGhpcy50b0VudGl0eShleHByLmZ1bmN0aW9uKSArICcoJyArIG1hcEpvaW4oZXhwci5hcmdzLCAnLCAnLCB0aGlzLnRvRXhwcmVzc2lvbiwgdGhpcykgKyAnKSc7XG4gICAgY2FzZSAnb3BlcmF0aW9uJzpcbiAgICAgIHZhciBvcGVyYXRvciA9IGV4cHIub3BlcmF0b3IudG9VcHBlckNhc2UoKSwgYXJncyA9IGV4cHIuYXJncyB8fCBbXTtcbiAgICAgIHN3aXRjaCAoZXhwci5vcGVyYXRvci50b0xvd2VyQ2FzZSgpKSB7XG4gICAgICAvLyBJbmZpeCBvcGVyYXRvcnNcbiAgICAgIGNhc2UgJzwnOlxuICAgICAgY2FzZSAnPic6XG4gICAgICBjYXNlICc+PSc6XG4gICAgICBjYXNlICc8PSc6XG4gICAgICBjYXNlICcmJic6XG4gICAgICBjYXNlICd8fCc6XG4gICAgICBjYXNlICc9JzpcbiAgICAgIGNhc2UgJyE9JzpcbiAgICAgIGNhc2UgJysnOlxuICAgICAgY2FzZSAnLSc6XG4gICAgICBjYXNlICcqJzpcbiAgICAgIGNhc2UgJy8nOlxuICAgICAgICAgIHJldHVybiAoaXNTdHJpbmcoYXJnc1swXSkgPyB0aGlzLnRvRW50aXR5KGFyZ3NbMF0pIDogJygnICsgdGhpcy50b0V4cHJlc3Npb24oYXJnc1swXSkgKyAnKScpICtcbiAgICAgICAgICAgICAgICAgJyAnICsgb3BlcmF0b3IgKyAnICcgK1xuICAgICAgICAgICAgICAgICAoaXNTdHJpbmcoYXJnc1sxXSkgPyB0aGlzLnRvRW50aXR5KGFyZ3NbMV0pIDogJygnICsgdGhpcy50b0V4cHJlc3Npb24oYXJnc1sxXSkgKyAnKScpO1xuICAgICAgLy8gVW5hcnkgb3BlcmF0b3JzXG4gICAgICBjYXNlICchJzpcbiAgICAgICAgcmV0dXJuICchKCcgKyB0aGlzLnRvRXhwcmVzc2lvbihhcmdzWzBdKSArICcpJztcbiAgICAgIC8vIElOIGFuZCBOT1QgSU5cbiAgICAgIGNhc2UgJ25vdGluJzpcbiAgICAgICAgb3BlcmF0b3IgPSAnTk9UIElOJztcbiAgICAgIGNhc2UgJ2luJzpcbiAgICAgICAgcmV0dXJuIHRoaXMudG9FeHByZXNzaW9uKGFyZ3NbMF0pICsgJyAnICsgb3BlcmF0b3IgK1xuICAgICAgICAgICAgICAgJygnICsgKGlzU3RyaW5nKGFyZ3NbMV0pID8gYXJnc1sxXSA6IG1hcEpvaW4oYXJnc1sxXSwgJywgJywgdGhpcy50b0V4cHJlc3Npb24sIHRoaXMpKSArICcpJztcbiAgICAgIC8vIEVYSVNUUyBhbmQgTk9UIEVYSVNUU1xuICAgICAgY2FzZSAnbm90ZXhpc3RzJzpcbiAgICAgICAgb3BlcmF0b3IgPSAnTk9UIEVYSVNUUyc7XG4gICAgICBjYXNlICdleGlzdHMnOlxuICAgICAgICByZXR1cm4gb3BlcmF0b3IgKyAnICcgKyB0aGlzLmdyb3VwKGFyZ3NbMF0sIHRydWUpO1xuICAgICAgLy8gT3RoZXIgZXhwcmVzc2lvbnNcbiAgICAgIGRlZmF1bHQ6XG4gICAgICAgIHJldHVybiBvcGVyYXRvciArICcoJyArIG1hcEpvaW4oYXJncywgJywgJywgdGhpcy50b0V4cHJlc3Npb24sIHRoaXMpICsgJyknO1xuICAgICAgfVxuICAgIGRlZmF1bHQ6XG4gICAgICB0aHJvdyBuZXcgRXJyb3IoJ1Vua25vd24gZXhwcmVzc2lvbiB0eXBlOiAnICsgZXhwci50eXBlKTtcbiAgfVxufTtcblxuLy8gQ29udmVydHMgdGhlIHBhcnNlZCBlbnRpdHkgKG9yIHByb3BlcnR5IHBhdGgpIGludG8gYSBTUEFSUUwgZW50aXR5XG5HZW5lcmF0b3IucHJvdG90eXBlLnRvRW50aXR5ID0gZnVuY3Rpb24gKHZhbHVlKSB7XG4gIC8vIHJlZ3VsYXIgZW50aXR5XG4gIGlmIChpc1N0cmluZyh2YWx1ZSkpIHtcbiAgICBzd2l0Y2ggKHZhbHVlWzBdKSB7XG4gICAgLy8gdmFyaWFibGUsICogc2VsZWN0b3IsIG9yIGJsYW5rIG5vZGVcbiAgICBjYXNlICc/JzpcbiAgICBjYXNlICckJzpcbiAgICBjYXNlICcqJzpcbiAgICBjYXNlICdfJzpcbiAgICAgIHJldHVybiB2YWx1ZTtcbiAgICAvLyBsaXRlcmFsXG4gICAgY2FzZSAnXCInOlxuICAgICAgdmFyIG1hdGNoID0gdmFsdWUubWF0Y2goL15cIihbXl0qKVwiKD86KEAuKyl8XFxeXFxeKC4rKSk/JC8pIHx8IHt9LFxuICAgICAgICAgIGxleGljYWwgPSBtYXRjaFsxXSB8fCAnJywgbGFuZ3VhZ2UgPSBtYXRjaFsyXSB8fCAnJywgZGF0YXR5cGUgPSBtYXRjaFszXTtcbiAgICAgIHZhbHVlID0gJ1wiJyArIGxleGljYWwucmVwbGFjZShlc2NhcGUsIGVzY2FwZVJlcGxhY2VyKSArICdcIicgKyBsYW5ndWFnZTtcbiAgICAgIGlmIChkYXRhdHlwZSkge1xuICAgICAgICBpZiAoZGF0YXR5cGUgPT09IFhTRF9JTlRFR0VSICYmIC9eXFxkKyQvLnRlc3QobGV4aWNhbCkpXG4gICAgICAgICAgLy8gQWRkIHNwYWNlIHRvIGF2b2lkIGNvbmZ1c2lvbiB3aXRoIGRlY2ltYWxzIGluIGJyb2tlbiBwYXJzZXJzXG4gICAgICAgICAgcmV0dXJuIGxleGljYWwgKyAnICc7XG4gICAgICAgIHZhbHVlICs9ICdeXicgKyB0aGlzLmVuY29kZUlSSShkYXRhdHlwZSk7XG4gICAgICB9XG4gICAgICByZXR1cm4gdmFsdWU7XG4gICAgLy8gSVJJXG4gICAgZGVmYXVsdDpcbiAgICAgIHJldHVybiB0aGlzLmVuY29kZUlSSSh2YWx1ZSk7XG4gICAgfVxuICB9XG4gIC8vIHByb3BlcnR5IHBhdGhcbiAgZWxzZSB7XG4gICAgdmFyIGl0ZW1zID0gdmFsdWUuaXRlbXMubWFwKHRoaXMudG9FbnRpdHksIHRoaXMpLCBwYXRoID0gdmFsdWUucGF0aFR5cGU7XG4gICAgc3dpdGNoIChwYXRoKSB7XG4gICAgLy8gcHJlZml4IG9wZXJhdG9yXG4gICAgY2FzZSAnXic6XG4gICAgY2FzZSAnISc6XG4gICAgICByZXR1cm4gcGF0aCArIGl0ZW1zWzBdO1xuICAgIC8vIHBvc3RmaXggb3BlcmF0b3JcbiAgICBjYXNlICcqJzpcbiAgICBjYXNlICcrJzpcbiAgICBjYXNlICc/JzpcbiAgICAgIHJldHVybiAnKCcgKyBpdGVtc1swXSArIHBhdGggKyAnKSc7XG4gICAgLy8gaW5maXggb3BlcmF0b3JcbiAgICBkZWZhdWx0OlxuICAgICAgcmV0dXJuICcoJyArIGl0ZW1zLmpvaW4ocGF0aCkgKyAnKSc7XG4gICAgfVxuICB9XG59O1xudmFyIGVzY2FwZSA9IC9bXCJcXFxcXFx0XFxuXFxyXFxiXFxmXS9nLFxuICAgIGVzY2FwZVJlcGxhY2VyID0gZnVuY3Rpb24gKGMpIHsgcmV0dXJuIGVzY2FwZVJlcGxhY2VtZW50c1tjXTsgfSxcbiAgICBlc2NhcGVSZXBsYWNlbWVudHMgPSB7ICdcXFxcJzogJ1xcXFxcXFxcJywgJ1wiJzogJ1xcXFxcIicsICdcXHQnOiAnXFxcXHQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgJ1xcbic6ICdcXFxcbicsICdcXHInOiAnXFxcXHInLCAnXFxiJzogJ1xcXFxiJywgJ1xcZic6ICdcXFxcZicgfTtcblxuLy8gUmVwcmVzZW50IHRoZSBJUkksIGFzIGEgcHJlZml4ZWQgbmFtZSB3aGVuIHBvc3NpYmxlXG5HZW5lcmF0b3IucHJvdG90eXBlLmVuY29kZUlSSSA9IGZ1bmN0aW9uIChpcmkpIHtcbiAgdmFyIHByZWZpeE1hdGNoID0gdGhpcy5fcHJlZml4UmVnZXguZXhlYyhpcmkpO1xuICBpZiAocHJlZml4TWF0Y2gpIHtcbiAgICB2YXIgcHJlZml4ID0gdGhpcy5fcHJlZml4QnlJcmlbcHJlZml4TWF0Y2hbMV1dO1xuICAgIHRoaXMuX3VzZWRQcmVmaXhlc1twcmVmaXhdID0gdHJ1ZTtcbiAgICByZXR1cm4gcHJlZml4ICsgJzonICsgcHJlZml4TWF0Y2hbMl07XG4gIH1cbiAgcmV0dXJuICc8JyArIGlyaSArICc+Jztcbn07XG5cbi8vIENvbnZlcnRzIHRoZSBwYXJzZWQgdXBkYXRlIG9iamVjdCBpbnRvIGEgU1BBUlFMIHVwZGF0ZSBjbGF1c2VcbkdlbmVyYXRvci5wcm90b3R5cGUudG9VcGRhdGUgPSBmdW5jdGlvbiAodXBkYXRlKSB7XG4gIHN3aXRjaCAodXBkYXRlLnR5cGUgfHwgdXBkYXRlLnVwZGF0ZVR5cGUpIHtcbiAgY2FzZSAnbG9hZCc6XG4gICAgcmV0dXJuICdMT0FEJyArICh1cGRhdGUuc291cmNlID8gJyAnICsgdGhpcy50b0VudGl0eSh1cGRhdGUuc291cmNlKSA6ICcnKSArXG4gICAgICAgICAgICh1cGRhdGUuZGVzdGluYXRpb24gPyAnIElOVE8gR1JBUEggJyArIHRoaXMudG9FbnRpdHkodXBkYXRlLmRlc3RpbmF0aW9uKSA6ICcnKTtcbiAgY2FzZSAnaW5zZXJ0JzpcbiAgICByZXR1cm4gJ0lOU0VSVCBEQVRBICcgICsgdGhpcy5ncm91cCh1cGRhdGUuaW5zZXJ0LCB0cnVlKTtcbiAgY2FzZSAnZGVsZXRlJzpcbiAgICByZXR1cm4gJ0RFTEVURSBEQVRBICcgICsgdGhpcy5ncm91cCh1cGRhdGUuZGVsZXRlLCB0cnVlKTtcbiAgY2FzZSAnZGVsZXRld2hlcmUnOlxuICAgIHJldHVybiAnREVMRVRFIFdIRVJFICcgKyB0aGlzLmdyb3VwKHVwZGF0ZS5kZWxldGUsIHRydWUpO1xuICBjYXNlICdpbnNlcnRkZWxldGUnOlxuICAgIHJldHVybiAodXBkYXRlLmdyYXBoID8gJ1dJVEggJyArIHRoaXMudG9FbnRpdHkodXBkYXRlLmdyYXBoKSArIHRoaXMuX25ld2xpbmUgOiAnJykgK1xuICAgICAgICAgICAodXBkYXRlLmRlbGV0ZS5sZW5ndGggPyAnREVMRVRFICcgKyB0aGlzLmdyb3VwKHVwZGF0ZS5kZWxldGUsIHRydWUpICsgdGhpcy5fbmV3bGluZSA6ICcnKSArXG4gICAgICAgICAgICh1cGRhdGUuaW5zZXJ0Lmxlbmd0aCA/ICdJTlNFUlQgJyArIHRoaXMuZ3JvdXAodXBkYXRlLmluc2VydCwgdHJ1ZSkgKyB0aGlzLl9uZXdsaW5lIDogJycpICtcbiAgICAgICAgICAgJ1dIRVJFICcgKyB0aGlzLmdyb3VwKHVwZGF0ZS53aGVyZSwgdHJ1ZSk7XG4gIGNhc2UgJ2FkZCc6XG4gIGNhc2UgJ2NvcHknOlxuICBjYXNlICdtb3ZlJzpcbiAgICByZXR1cm4gdXBkYXRlLnR5cGUudG9VcHBlckNhc2UoKSArICh1cGRhdGUuc291cmNlLmRlZmF1bHQgPyAnIERFRkFVTFQgJyA6ICcgJykgK1xuICAgICAgICAgICAnVE8gJyArIHRoaXMudG9FbnRpdHkodXBkYXRlLmRlc3RpbmF0aW9uLm5hbWUpO1xuICBjYXNlICdjcmVhdGUnOlxuICBjYXNlICdjbGVhcic6XG4gIGNhc2UgJ2Ryb3AnOlxuICAgIHJldHVybiB1cGRhdGUudHlwZS50b1VwcGVyQ2FzZSgpICsgKHVwZGF0ZS5zaWxlbnQgPyAnIFNJTEVOVCAnIDogJyAnKSArIChcbiAgICAgIHVwZGF0ZS5ncmFwaC5kZWZhdWx0ID8gJ0RFRkFVTFQnIDpcbiAgICAgIHVwZGF0ZS5ncmFwaC5uYW1lZCA/ICdOQU1FRCcgOlxuICAgICAgdXBkYXRlLmdyYXBoLmFsbCA/ICdBTEwnIDpcbiAgICAgICgnR1JBUEggJyArIHRoaXMudG9FbnRpdHkodXBkYXRlLmdyYXBoLm5hbWUpKVxuICAgICk7XG4gIGRlZmF1bHQ6XG4gICAgdGhyb3cgbmV3IEVycm9yKCdVbmtub3duIHVwZGF0ZSBxdWVyeSB0eXBlOiAnICsgdXBkYXRlLnR5cGUpO1xuICB9XG59O1xuXG4vLyBJbmRlbnRzIGVhY2ggbGluZSBvZiB0aGUgc3RyaW5nXG5HZW5lcmF0b3IucHJvdG90eXBlLmluZGVudCA9IGZ1bmN0aW9uKHRleHQpIHsgcmV0dXJuIHRleHQucmVwbGFjZSgvXi9nbSwgdGhpcy5faW5kZW50KTsgfVxuXG4vLyBDaGVja3Mgd2hldGhlciB0aGUgb2JqZWN0IGlzIGEgc3RyaW5nXG5mdW5jdGlvbiBpc1N0cmluZyhvYmplY3QpIHsgcmV0dXJuIHR5cGVvZiBvYmplY3QgPT09ICdzdHJpbmcnOyB9XG5cbi8vIE1hcHMgdGhlIGFycmF5IHdpdGggdGhlIGdpdmVuIGZ1bmN0aW9uLCBhbmQgam9pbnMgdGhlIHJlc3VsdHMgdXNpbmcgdGhlIHNlcGFyYXRvclxuZnVuY3Rpb24gbWFwSm9pbihhcnJheSwgc2VwLCBmdW5jLCBzZWxmKSB7XG4gIHJldHVybiBhcnJheS5tYXAoZnVuYywgc2VsZikuam9pbihpc1N0cmluZyhzZXApID8gc2VwIDogJyAnKTtcbn1cblxuLyoqXG4gKiBAcGFyYW0gb3B0aW9ucyB7XG4gKiAgIGFsbFByZWZpeGVzOiBib29sZWFuLFxuICogICBpbmRlbnRhdGlvbjogc3RyaW5nLFxuICogICBuZXdsaW5lOiBzdHJpbmdcbiAqIH1cbiAqL1xubW9kdWxlLmV4cG9ydHMgPSBmdW5jdGlvbiBTcGFycWxHZW5lcmF0b3Iob3B0aW9ucykge1xuICByZXR1cm4ge1xuICAgIHN0cmluZ2lmeTogZnVuY3Rpb24gKHEpIHsgcmV0dXJuIG5ldyBHZW5lcmF0b3Iob3B0aW9ucywgcS5wcmVmaXhlcykudG9RdWVyeShxKTsgfVxuICB9O1xufTtcbiIsIi8qIHBhcnNlciBnZW5lcmF0ZWQgYnkgamlzb24gMC40LjE4ICovXG4vKlxuICBSZXR1cm5zIGEgUGFyc2VyIG9iamVjdCBvZiB0aGUgZm9sbG93aW5nIHN0cnVjdHVyZTpcblxuICBQYXJzZXI6IHtcbiAgICB5eToge31cbiAgfVxuXG4gIFBhcnNlci5wcm90b3R5cGU6IHtcbiAgICB5eToge30sXG4gICAgdHJhY2U6IGZ1bmN0aW9uKCksXG4gICAgc3ltYm9sc186IHthc3NvY2lhdGl2ZSBsaXN0OiBuYW1lID09PiBudW1iZXJ9LFxuICAgIHRlcm1pbmFsc186IHthc3NvY2lhdGl2ZSBsaXN0OiBudW1iZXIgPT0+IG5hbWV9LFxuICAgIHByb2R1Y3Rpb25zXzogWy4uLl0sXG4gICAgcGVyZm9ybUFjdGlvbjogZnVuY3Rpb24gYW5vbnltb3VzKHl5dGV4dCwgeXlsZW5nLCB5eWxpbmVubywgeXksIHl5c3RhdGUsICQkLCBfJCksXG4gICAgdGFibGU6IFsuLi5dLFxuICAgIGRlZmF1bHRBY3Rpb25zOiB7Li4ufSxcbiAgICBwYXJzZUVycm9yOiBmdW5jdGlvbihzdHIsIGhhc2gpLFxuICAgIHBhcnNlOiBmdW5jdGlvbihpbnB1dCksXG5cbiAgICBsZXhlcjoge1xuICAgICAgICBFT0Y6IDEsXG4gICAgICAgIHBhcnNlRXJyb3I6IGZ1bmN0aW9uKHN0ciwgaGFzaCksXG4gICAgICAgIHNldElucHV0OiBmdW5jdGlvbihpbnB1dCksXG4gICAgICAgIGlucHV0OiBmdW5jdGlvbigpLFxuICAgICAgICB1bnB1dDogZnVuY3Rpb24oc3RyKSxcbiAgICAgICAgbW9yZTogZnVuY3Rpb24oKSxcbiAgICAgICAgbGVzczogZnVuY3Rpb24obiksXG4gICAgICAgIHBhc3RJbnB1dDogZnVuY3Rpb24oKSxcbiAgICAgICAgdXBjb21pbmdJbnB1dDogZnVuY3Rpb24oKSxcbiAgICAgICAgc2hvd1Bvc2l0aW9uOiBmdW5jdGlvbigpLFxuICAgICAgICB0ZXN0X21hdGNoOiBmdW5jdGlvbihyZWdleF9tYXRjaF9hcnJheSwgcnVsZV9pbmRleCksXG4gICAgICAgIG5leHQ6IGZ1bmN0aW9uKCksXG4gICAgICAgIGxleDogZnVuY3Rpb24oKSxcbiAgICAgICAgYmVnaW46IGZ1bmN0aW9uKGNvbmRpdGlvbiksXG4gICAgICAgIHBvcFN0YXRlOiBmdW5jdGlvbigpLFxuICAgICAgICBfY3VycmVudFJ1bGVzOiBmdW5jdGlvbigpLFxuICAgICAgICB0b3BTdGF0ZTogZnVuY3Rpb24oKSxcbiAgICAgICAgcHVzaFN0YXRlOiBmdW5jdGlvbihjb25kaXRpb24pLFxuXG4gICAgICAgIG9wdGlvbnM6IHtcbiAgICAgICAgICAgIHJhbmdlczogYm9vbGVhbiAgICAgICAgICAgKG9wdGlvbmFsOiB0cnVlID09PiB0b2tlbiBsb2NhdGlvbiBpbmZvIHdpbGwgaW5jbHVkZSBhIC5yYW5nZVtdIG1lbWJlcilcbiAgICAgICAgICAgIGZsZXg6IGJvb2xlYW4gICAgICAgICAgICAgKG9wdGlvbmFsOiB0cnVlID09PiBmbGV4LWxpa2UgbGV4aW5nIGJlaGF2aW91ciB3aGVyZSB0aGUgcnVsZXMgYXJlIHRlc3RlZCBleGhhdXN0aXZlbHkgdG8gZmluZCB0aGUgbG9uZ2VzdCBtYXRjaClcbiAgICAgICAgICAgIGJhY2t0cmFja19sZXhlcjogYm9vbGVhbiAgKG9wdGlvbmFsOiB0cnVlID09PiBsZXhlciByZWdleGVzIGFyZSB0ZXN0ZWQgaW4gb3JkZXIgYW5kIGZvciBlYWNoIG1hdGNoaW5nIHJlZ2V4IHRoZSBhY3Rpb24gY29kZSBpcyBpbnZva2VkOyB0aGUgbGV4ZXIgdGVybWluYXRlcyB0aGUgc2NhbiB3aGVuIGEgdG9rZW4gaXMgcmV0dXJuZWQgYnkgdGhlIGFjdGlvbiBjb2RlKVxuICAgICAgICB9LFxuXG4gICAgICAgIHBlcmZvcm1BY3Rpb246IGZ1bmN0aW9uKHl5LCB5eV8sICRhdm9pZGluZ19uYW1lX2NvbGxpc2lvbnMsIFlZX1NUQVJUKSxcbiAgICAgICAgcnVsZXM6IFsuLi5dLFxuICAgICAgICBjb25kaXRpb25zOiB7YXNzb2NpYXRpdmUgbGlzdDogbmFtZSA9PT4gc2V0fSxcbiAgICB9XG4gIH1cblxuXG4gIHRva2VuIGxvY2F0aW9uIGluZm8gKEAkLCBfJCwgZXRjLik6IHtcbiAgICBmaXJzdF9saW5lOiBuLFxuICAgIGxhc3RfbGluZTogbixcbiAgICBmaXJzdF9jb2x1bW46IG4sXG4gICAgbGFzdF9jb2x1bW46IG4sXG4gICAgcmFuZ2U6IFtzdGFydF9udW1iZXIsIGVuZF9udW1iZXJdICAgICAgICh3aGVyZSB0aGUgbnVtYmVycyBhcmUgaW5kZXhlcyBpbnRvIHRoZSBpbnB1dCBzdHJpbmcsIHJlZ3VsYXIgemVyby1iYXNlZClcbiAgfVxuXG5cbiAgdGhlIHBhcnNlRXJyb3IgZnVuY3Rpb24gcmVjZWl2ZXMgYSAnaGFzaCcgb2JqZWN0IHdpdGggdGhlc2UgbWVtYmVycyBmb3IgbGV4ZXIgYW5kIHBhcnNlciBlcnJvcnM6IHtcbiAgICB0ZXh0OiAgICAgICAgKG1hdGNoZWQgdGV4dClcbiAgICB0b2tlbjogICAgICAgKHRoZSBwcm9kdWNlZCB0ZXJtaW5hbCB0b2tlbiwgaWYgYW55KVxuICAgIGxpbmU6ICAgICAgICAoeXlsaW5lbm8pXG4gIH1cbiAgd2hpbGUgcGFyc2VyIChncmFtbWFyKSBlcnJvcnMgd2lsbCBhbHNvIHByb3ZpZGUgdGhlc2UgbWVtYmVycywgaS5lLiBwYXJzZXIgZXJyb3JzIGRlbGl2ZXIgYSBzdXBlcnNldCBvZiBhdHRyaWJ1dGVzOiB7XG4gICAgbG9jOiAgICAgICAgICh5eWxsb2MpXG4gICAgZXhwZWN0ZWQ6ICAgIChzdHJpbmcgZGVzY3JpYmluZyB0aGUgc2V0IG9mIGV4cGVjdGVkIHRva2VucylcbiAgICByZWNvdmVyYWJsZTogKGJvb2xlYW46IFRSVUUgd2hlbiB0aGUgcGFyc2VyIGhhcyBhIGVycm9yIHJlY292ZXJ5IHJ1bGUgYXZhaWxhYmxlIGZvciB0aGlzIHBhcnRpY3VsYXIgZXJyb3IpXG4gIH1cbiovXG52YXIgU3BhcnFsUGFyc2VyID0gKGZ1bmN0aW9uKCl7XG52YXIgbz1mdW5jdGlvbihrLHYsbyxsKXtmb3Iobz1vfHx7fSxsPWsubGVuZ3RoO2wtLTtvW2tbbF1dPXYpO3JldHVybiBvfSwkVjA9WzYsMTIsMTUsMjQsMzQsNDMsNDgsOTksMTA5LDExMiwxMTQsMTE1LDEyNCwxMjUsMTMwLDI5OCwyOTksMzAwLDMwMSwzMDJdLCRWMT1bMiwxOTZdLCRWMj1bOTksMTA5LDExMiwxMTQsMTE1LDEyNCwxMjUsMTMwLDI5OCwyOTksMzAwLDMwMSwzMDJdLCRWMz1bMSwxOF0sJFY0PVsxLDI3XSwkVjU9WzYsODNdLCRWNj1bMzgsMzksNTFdLCRWNz1bMzgsNTFdLCRWOD1bMSw1NV0sJFY5PVsxLDU3XSwkVmE9WzEsNTNdLCRWYj1bMSw1Nl0sJFZjPVsyOCwyOSwyOTNdLCRWZD1bMTMsMTYsMjg2XSwkVmU9WzExMSwxMzMsMjk2LDMwM10sJFZmPVsxMywxNiwxMTEsMTMzLDI4Nl0sJFZnPVsxLDgwXSwkVmg9WzEsODRdLCRWaT1bMSw4Nl0sJFZqPVsxMTEsMTMzLDI5NiwyOTcsMzAzXSwkVms9WzEzLDE2LDExMSwxMzMsMjg2LDI5N10sJFZsPVsxLDkyXSwkVm09WzIsMjM2XSwkVm49WzEsOTFdLCRWbz1bMTMsMTYsMjgsMjksODAsODYsMjE1LDIxOCwyMTksMjcyLDI3MywyNzQsMjc1LDI3NiwyNzcsMjc4LDI3OSwyODAsMjgxLDI4MiwyODMsMjg0LDI4NSwyODZdLCRWcD1bNiwzOCwzOSw1MSw2MSw2OCw3MSw3OSw4MSw4M10sJFZxPVs2LDEzLDE2LDI4LDM4LDM5LDUxLDYxLDY4LDcxLDc5LDgxLDgzLDI4Nl0sJFZyPVs2LDEzLDE2LDI4LDI5LDMxLDMyLDM4LDM5LDQxLDUxLDYxLDY4LDcxLDc5LDgwLDgxLDgzLDg2LDkyLDEwOCwxMTEsMTI0LDEyNSwxMjcsMTMyLDE1OSwxNjAsMTYyLDE2NSwxNjYsMTgzLDE4NywyMDgsMjEzLDIxNSwyMTYsMjE4LDIxOSwyMjMsMjI3LDIzMSwyNDYsMjUxLDI2OCwyNzIsMjczLDI3NCwyNzUsMjc2LDI3NywyNzgsMjc5LDI4MCwyODEsMjgyLDI4MywyODQsMjg1LDI4NiwyOTMsMzA0LDMwNiwzMDcsMzA5LDMxMCwzMTEsMzEyLDMxMywzMTQsMzE1LDMxNl0sJFZzPVsxLDEwN10sJFZ0PVsxLDEwOF0sJFZ1PVs2LDEzLDE2LDI4LDI5LDM5LDQxLDgwLDgzLDg2LDExMSwxNTksMTYwLDE2MiwxNjUsMTY2LDIxNSwyMTgsMjE5LDI3MiwyNzMsMjc0LDI3NSwyNzYsMjc3LDI3OCwyNzksMjgwLDI4MSwyODIsMjgzLDI4NCwyODUsMjg2LDMwNF0sJFZ2PVsyLDI5NV0sJFZ3PVsxLDEyNV0sJFZ4PVsxLDEyM10sJFZ5PVs2LDE4M10sJFZ6PVsyLDMxMl0sJFZBPVsyLDMwMF0sJFZCPVszOCwxMjddLCRWQz1bNiw0MSw2OCw3MSw3OSw4MSw4M10sJFZEPVsyLDIzOF0sJFZFPVsxLDEzOV0sJFZGPVsxLDE0MV0sJFZHPVsxLDE1MV0sJFZIPVsxLDE1N10sJFZJPVsxLDE2MF0sJFZKPVsxLDE1Nl0sJFZLPVsxLDE1OF0sJFZMPVsxLDE1NF0sJFZNPVsxLDE1NV0sJFZOPVsxLDE2MV0sJFZPPVsxLDE2Ml0sJFZQPVsxLDE2NV0sJFZRPVsxLDE2Nl0sJFZSPVsxLDE2N10sJFZTPVsxLDE2OF0sJFZUPVsxLDE2OV0sJFZVPVsxLDE3MF0sJFZWPVsxLDE3MV0sJFZXPVsxLDE3Ml0sJFZYPVsxLDE3M10sJFZZPVsxLDE3NF0sJFZaPVsxLDE3NV0sJFZfPVsxLDE3Nl0sJFYkPVs2LDYxLDY4LDcxLDc5LDgxLDgzXSwkVjAxPVsyOCwyOSwzOCwzOSw1MV0sJFYxMT1bMTMsMTYsMjgsMjksODAsMjQ4LDI0OSwyNTAsMjUyLDI1NCwyNTUsMjU3LDI1OCwyNjEsMjYzLDI3MiwyNzMsMjc0LDI3NSwyNzYsMjc3LDI3OCwyNzksMjgwLDI4MSwyODIsMjgzLDI4NCwyODUsMjg2LDMxNiwzMTcsMzE4LDMxOSwzMjAsMzIxXSwkVjIxPVsyLDQwOV0sJFYzMT1bMSwxODldLCRWNDE9WzEsMTkwXSwkVjUxPVsxLDE5MV0sJFY2MT1bMTMsMTYsNDEsODAsOTIsMjcyLDI3MywyNzQsMjc1LDI3NiwyNzcsMjc4LDI3OSwyODAsMjgxLDI4MiwyODMsMjg0LDI4NSwyODZdLCRWNzE9WzQxLDg2XSwkVjgxPVsyOCwzMl0sJFY5MT1bNiwxMDgsMTgzXSwkVmExPVs0MSwxMTFdLCRWYjE9WzYsNDEsNzEsNzksODEsODNdLCRWYzE9WzIsMzI0XSwkVmQxPVsyLDMxNl0sJFZlMT1bMSwyMjZdLCRWZjE9WzEsMjI4XSwkVmcxPVs0MSwxMTEsMzA0XSwkVmgxPVsxMywxNiwyOCwyOSwzMiwzOSw0MSw4MCw4Myw4NiwxMTEsMTU5LDE2MCwxNjIsMTY1LDE2NiwxODMsMTg3LDIwOCwyMTMsMjE1LDIxNiwyMTgsMjE5LDI1MSwyNzIsMjczLDI3NCwyNzUsMjc2LDI3NywyNzgsMjc5LDI4MCwyODEsMjgyLDI4MywyODQsMjg1LDI4NiwzMDRdLCRWaTE9WzEzLDE2LDI4LDI5LDMxLDMyLDM5LDQxLDgwLDgzLDg2LDkyLDExMSwxNTksMTYwLDE2MiwxNjUsMTY2LDE4MywxODcsMjA4LDIxMywyMTUsMjE2LDIxOCwyMTksMjIzLDIyNywyMzEsMjQ2LDI1MSwyNjgsMjcyLDI3MywyNzQsMjc1LDI3NiwyNzcsMjc4LDI3OSwyODAsMjgxLDI4MiwyODMsMjg0LDI4NSwyODYsMjkzLDMwNCwzMDcsMzEwLDMxMSwzMTIsMzEzLDMxNCwzMTUsMzE2XSwkVmoxPVsxMywxNiwyOCwyOSwzMSwzMiwzOSw0MSw4MCw4Myw4Niw5MiwxMTEsMTU5LDE2MCwxNjIsMTY1LDE2NiwxODMsMTg3LDIwOCwyMTMsMjE1LDIxNiwyMTgsMjE5LDIyMywyMjcsMjMxLDI0NiwyNTEsMjY4LDI3MCwyNzEsMjcyLDI3MywyNzQsMjc1LDI3NiwyNzcsMjc4LDI3OSwyODAsMjgxLDI4MiwyODMsMjg0LDI4NSwyODYsMjkzLDMwNCwzMDcsMzEwLDMxMSwzMTIsMzEzLDMxNCwzMTUsMzE2XSwkVmsxPVszMSwzMiwxODMsMjIzLDI1MV0sJFZsMT1bMzEsMzIsMTgzLDIyMywyMjcsMjUxXSwkVm0xPVszMSwzMiwxODMsMjIzLDIyNywyMzEsMjQ2LDI1MSwyNjgsMjgwLDI4MSwyODIsMjgzLDI4NCwyODUsMzEwLDMxMSwzMTIsMzEzLDMxNCwzMTUsMzE2XSwkVm4xPVszMSwzMiwxODMsMjIzLDIyNywyMzEsMjQ2LDI1MSwyNjgsMjgwLDI4MSwyODIsMjgzLDI4NCwyODUsMjkzLDMwNywzMTAsMzExLDMxMiwzMTMsMzE0LDMxNSwzMTZdLCRWbzE9WzEsMjYwXSwkVnAxPVsxLDI2MV0sJFZxMT1bMSwyNjNdLCRWcjE9WzEsMjY0XSwkVnMxPVsxLDI2NV0sJFZ0MT1bMSwyNjZdLCRWdTE9WzEsMjY4XSwkVnYxPVsxLDI2OV0sJFZ3MT1bMiw0MTZdLCRWeDE9WzEsMjcxXSwkVnkxPVsxLDI3Ml0sJFZ6MT1bMSwyNzNdLCRWQTE9WzEsMjc5XSwkVkIxPVsxLDI3NF0sJFZDMT1bMSwyNzVdLCRWRDE9WzEsMjc2XSwkVkUxPVsxLDI3N10sJFZGMT1bMSwyNzhdLCRWRzE9WzEsMjg2XSwkVkgxPVsxLDI5OV0sJFZJMT1bNiw0MSw3OSw4MSw4M10sJFZKMT1bMSwzMTZdLCRWSzE9WzEsMzE1XSwkVkwxPVszOSw0MSw4MywxMTEsMTU5LDE2MCwxNjIsMTY1LDE2Nl0sJFZNMT1bMSwzMjRdLCRWTjE9WzEsMzI1XSwkVk8xPVs0MSwxMTEsMTgzLDIxNiwzMDRdLCRWUDE9WzIsMzU0XSwkVlExPVsxMywxNiwyOCwyOSwzMiw4MCw4NiwyMTUsMjE4LDIxOSwyNzIsMjczLDI3NCwyNzUsMjc2LDI3NywyNzgsMjc5LDI4MCwyODEsMjgyLDI4MywyODQsMjg1LDI4Nl0sJFZSMT1bMTMsMTYsMjgsMjksMzIsMzksNDEsODAsODMsODYsMTExLDE1OSwxNjAsMTYyLDE2NSwxNjYsMTgzLDIxNSwyMTYsMjE4LDIxOSwyNTEsMjcyLDI3MywyNzQsMjc1LDI3NiwyNzcsMjc4LDI3OSwyODAsMjgxLDI4MiwyODMsMjg0LDI4NSwyODYsMzA0XSwkVlMxPVsxMywxNiwyOCwyOSw4MCwyMDgsMjQ2LDI0OCwyNDksMjUwLDI1MiwyNTQsMjU1LDI1NywyNTgsMjYxLDI2MywyNzIsMjczLDI3NCwyNzUsMjc2LDI3NywyNzgsMjc5LDI4MCwyODEsMjgyLDI4MywyODQsMjg1LDI4NiwzMTAsMzE2LDMxNywzMTgsMzE5LDMyMCwzMjFdLCRWVDE9WzEsMzQ5XSwkVlUxPVsxLDM1MF0sJFZWMT1bMSwzNTJdLCRWVzE9WzEsMzUxXSwkVlgxPVs2LDEzLDE2LDI4LDI5LDMxLDMyLDM5LDQxLDY4LDcxLDc0LDc2LDc5LDgwLDgxLDgzLDg2LDExMSwxNTksMTYwLDE2MiwxNjUsMTY2LDE4MywyMTUsMjE4LDIxOSwyMjMsMjI3LDIzMSwyNDYsMjQ4LDI0OSwyNTAsMjUxLDI1MiwyNTQsMjU1LDI1NywyNTgsMjYxLDI2MywyNjgsMjcyLDI3MywyNzQsMjc1LDI3NiwyNzcsMjc4LDI3OSwyODAsMjgxLDI4MiwyODMsMjg0LDI4NSwyODYsMjkzLDMwNCwzMDcsMzEwLDMxMSwzMTIsMzEzLDMxNCwzMTUsMzE2LDMxNywzMTgsMzE5LDMyMCwzMjFdLCRWWTE9WzEsMzYwXSwkVloxPVsxLDM1OV0sJFZfMT1bMjksODZdLCRWJDE9WzEzLDE2LDMyLDQxLDgwLDkyLDI3MiwyNzMsMjc0LDI3NSwyNzYsMjc3LDI3OCwyNzksMjgwLDI4MSwyODIsMjgzLDI4NCwyODUsMjg2XSwkVjAyPVsyOSw0MV0sJFYxMj1bMiwzMTVdLCRWMjI9WzYsNDEsODNdLCRWMzI9WzYsMTMsMTYsMjksNDEsNzEsNzksODEsODMsMjQ4LDI0OSwyNTAsMjUyLDI1NCwyNTUsMjU3LDI1OCwyNjEsMjYzLDI4NiwzMTYsMzE3LDMxOCwzMTksMzIwLDMyMV0sJFY0Mj1bNiwxMywxNiwyOCwyOSwzOSw0MSw3MSw3NCw3Niw3OSw4MCw4MSw4Myw4NiwxMTEsMTU5LDE2MCwxNjIsMTY1LDE2NiwyMTUsMjE4LDIxOSwyNDgsMjQ5LDI1MCwyNTIsMjU0LDI1NSwyNTcsMjU4LDI2MSwyNjMsMjcyLDI3MywyNzQsMjc1LDI3NiwyNzcsMjc4LDI3OSwyODAsMjgxLDI4MiwyODMsMjg0LDI4NSwyODYsMzA0LDMxNiwzMTcsMzE4LDMxOSwzMjAsMzIxXSwkVjUyPVs2LDEzLDE2LDI4LDI5LDQxLDY4LDcxLDc5LDgxLDgzLDI0OCwyNDksMjUwLDI1MiwyNTQsMjU1LDI1NywyNTgsMjYxLDI2MywyODYsMzE2LDMxNywzMTgsMzE5LDMyMCwzMjFdLCRWNjI9WzYsMTMsMTYsMjgsMjksMzEsMzIsMzksNDEsNjEsNjgsNzEsNzQsNzYsNzksODAsODEsODMsODYsMTExLDE1OSwxNjAsMTYyLDE2NSwxNjYsMTgzLDIxNSwyMTgsMjE5LDIyMywyMjcsMjMxLDI0NiwyNDgsMjQ5LDI1MCwyNTEsMjUyLDI1NCwyNTUsMjU3LDI1OCwyNjEsMjYzLDI2OCwyNzIsMjczLDI3NCwyNzUsMjc2LDI3NywyNzgsMjc5LDI4MCwyODEsMjgyLDI4MywyODQsMjg1LDI4NiwyOTMsMzA0LDMwNSwzMDcsMzEwLDMxMSwzMTIsMzEzLDMxNCwzMTUsMzE2LDMxNywzMTgsMzE5LDMyMCwzMjFdLCRWNzI9WzEzLDE2LDI5LDE4NywyMDgsMjEzLDI4Nl0sJFY4Mj1bMiwzNjZdLCRWOTI9WzEsNDAxXSwkVmEyPVszOSw0MSw4MywxMTEsMTU5LDE2MCwxNjIsMTY1LDE2NiwzMDRdLCRWYjI9WzEzLDE2LDI4LDI5LDMyLDM5LDQxLDgwLDgzLDg2LDExMSwxNTksMTYwLDE2MiwxNjUsMTY2LDE4MywxODcsMjE1LDIxNiwyMTgsMjE5LDI1MSwyNzIsMjczLDI3NCwyNzUsMjc2LDI3NywyNzgsMjc5LDI4MCwyODEsMjgyLDI4MywyODQsMjg1LDI4NiwzMDRdLCRWYzI9WzEzLDE2LDI4LDI5LDgwLDIwOCwyNDYsMjQ4LDI0OSwyNTAsMjUyLDI1NCwyNTUsMjU3LDI1OCwyNjEsMjYzLDI3MiwyNzMsMjc0LDI3NSwyNzYsMjc3LDI3OCwyNzksMjgwLDI4MSwyODIsMjgzLDI4NCwyODUsMjg2LDI5MywzMTAsMzE2LDMxNywzMTgsMzE5LDMyMCwzMjFdLCRWZDI9WzEsNDUwXSwkVmUyPVsxLDQ0N10sJFZmMj1bMSw0NDhdLCRWZzI9WzEzLDE2LDI4LDI5LDM5LDQxLDgwLDgzLDg2LDExMSwxNTksMTYwLDE2MiwxNjUsMTY2LDIxNSwyMTgsMjE5LDI3MiwyNzMsMjc0LDI3NSwyNzYsMjc3LDI3OCwyNzksMjgwLDI4MSwyODIsMjgzLDI4NCwyODUsMjg2XSwkVmgyPVsxMywxNiwyOCwyODZdLCRWaTI9WzEzLDE2LDI4LDI5LDM5LDQxLDgwLDgzLDg2LDExMSwxNTksMTYwLDE2MiwxNjUsMTY2LDIxNSwyMTgsMjE5LDI3MiwyNzMsMjc0LDI3NSwyNzYsMjc3LDI3OCwyNzksMjgwLDI4MSwyODIsMjgzLDI4NCwyODUsMjg2LDMwNF0sJFZqMj1bMiwzMjddLCRWazI9WzM5LDQxLDgzLDExMSwxNTksMTYwLDE2MiwxNjUsMTY2LDE4MywyMTYsMzA0XSwkVmwyPVs2LDEzLDE2LDI4LDI5LDQxLDc0LDc2LDc5LDgxLDgzLDI0OCwyNDksMjUwLDI1MiwyNTQsMjU1LDI1NywyNTgsMjYxLDI2MywyODYsMzE2LDMxNywzMTgsMzE5LDMyMCwzMjFdLCRWbTI9WzIsMzIyXSwkVm4yPVsxMywxNiwyOSwxODcsMjA4LDI4Nl0sJFZvMj1bMTMsMTYsMzIsODAsOTIsMjcyLDI3MywyNzQsMjc1LDI3NiwyNzcsMjc4LDI3OSwyODAsMjgxLDI4MiwyODMsMjg0LDI4NSwyODZdLCRWcDI9WzEzLDE2LDI4LDI5LDQxLDgwLDg2LDExMSwyMTUsMjE4LDIxOSwyNzIsMjczLDI3NCwyNzUsMjc2LDI3NywyNzgsMjc5LDI4MCwyODEsMjgyLDI4MywyODQsMjg1LDI4Nl0sJFZxMj1bMTMsMTYsMjgsMjksMzIsODAsODYsMjE1LDIxOCwyMTksMjcyLDI3MywyNzQsMjc1LDI3NiwyNzcsMjc4LDI3OSwyODAsMjgxLDI4MiwyODMsMjg0LDI4NSwyODYsMzA2LDMwN10sJFZyMj1bMTMsMTYsMjgsMjksMzIsODAsODYsMjE1LDIxOCwyMTksMjcyLDI3MywyNzQsMjc1LDI3NiwyNzcsMjc4LDI3OSwyODAsMjgxLDI4MiwyODMsMjg0LDI4NSwyODYsMjkzLDMwNiwzMDcsMzA5LDMxMF0sJFZzMj1bMSw1NjFdLCRWdDI9WzEsNTYyXSwkVnUyPVsyLDMxMF0sJFZ2Mj1bMTMsMTYsMzIsMTg3LDIxMywyODZdO1xudmFyIHBhcnNlciA9IHt0cmFjZTogZnVuY3Rpb24gdHJhY2UgKCkgeyB9LFxueXk6IHt9LFxuc3ltYm9sc186IHtcImVycm9yXCI6MixcIlF1ZXJ5T3JVcGRhdGVcIjozLFwiUHJvbG9ndWVcIjo0LFwiUXVlcnlPclVwZGF0ZV9ncm91cDBcIjo1LFwiRU9GXCI6NixcIlByb2xvZ3VlX3JlcGV0aXRpb24wXCI6NyxcIlF1ZXJ5XCI6OCxcIlF1ZXJ5X2dyb3VwMFwiOjksXCJRdWVyeV9vcHRpb24wXCI6MTAsXCJCYXNlRGVjbFwiOjExLFwiQkFTRVwiOjEyLFwiSVJJUkVGXCI6MTMsXCJQcmVmaXhEZWNsXCI6MTQsXCJQUkVGSVhcIjoxNSxcIlBOQU1FX05TXCI6MTYsXCJTZWxlY3RRdWVyeVwiOjE3LFwiU2VsZWN0Q2xhdXNlXCI6MTgsXCJTZWxlY3RRdWVyeV9yZXBldGl0aW9uMFwiOjE5LFwiV2hlcmVDbGF1c2VcIjoyMCxcIlNvbHV0aW9uTW9kaWZpZXJcIjoyMSxcIlN1YlNlbGVjdFwiOjIyLFwiU3ViU2VsZWN0X29wdGlvbjBcIjoyMyxcIlNFTEVDVFwiOjI0LFwiU2VsZWN0Q2xhdXNlX29wdGlvbjBcIjoyNSxcIlNlbGVjdENsYXVzZV9ncm91cDBcIjoyNixcIlNlbGVjdENsYXVzZUl0ZW1cIjoyNyxcIlZBUlwiOjI4LFwiKFwiOjI5LFwiRXhwcmVzc2lvblwiOjMwLFwiQVNcIjozMSxcIilcIjozMixcIkNvbnN0cnVjdFF1ZXJ5XCI6MzMsXCJDT05TVFJVQ1RcIjozNCxcIkNvbnN0cnVjdFRlbXBsYXRlXCI6MzUsXCJDb25zdHJ1Y3RRdWVyeV9yZXBldGl0aW9uMFwiOjM2LFwiQ29uc3RydWN0UXVlcnlfcmVwZXRpdGlvbjFcIjozNyxcIldIRVJFXCI6MzgsXCJ7XCI6MzksXCJDb25zdHJ1Y3RRdWVyeV9vcHRpb24wXCI6NDAsXCJ9XCI6NDEsXCJEZXNjcmliZVF1ZXJ5XCI6NDIsXCJERVNDUklCRVwiOjQzLFwiRGVzY3JpYmVRdWVyeV9ncm91cDBcIjo0NCxcIkRlc2NyaWJlUXVlcnlfcmVwZXRpdGlvbjBcIjo0NSxcIkRlc2NyaWJlUXVlcnlfb3B0aW9uMFwiOjQ2LFwiQXNrUXVlcnlcIjo0NyxcIkFTS1wiOjQ4LFwiQXNrUXVlcnlfcmVwZXRpdGlvbjBcIjo0OSxcIkRhdGFzZXRDbGF1c2VcIjo1MCxcIkZST01cIjo1MSxcIkRhdGFzZXRDbGF1c2Vfb3B0aW9uMFwiOjUyLFwiaXJpXCI6NTMsXCJXaGVyZUNsYXVzZV9vcHRpb24wXCI6NTQsXCJHcm91cEdyYXBoUGF0dGVyblwiOjU1LFwiU29sdXRpb25Nb2RpZmllcl9vcHRpb24wXCI6NTYsXCJTb2x1dGlvbk1vZGlmaWVyX29wdGlvbjFcIjo1NyxcIlNvbHV0aW9uTW9kaWZpZXJfb3B0aW9uMlwiOjU4LFwiU29sdXRpb25Nb2RpZmllcl9vcHRpb24zXCI6NTksXCJHcm91cENsYXVzZVwiOjYwLFwiR1JPVVBcIjo2MSxcIkJZXCI6NjIsXCJHcm91cENsYXVzZV9yZXBldGl0aW9uX3BsdXMwXCI6NjMsXCJHcm91cENvbmRpdGlvblwiOjY0LFwiQnVpbHRJbkNhbGxcIjo2NSxcIkZ1bmN0aW9uQ2FsbFwiOjY2LFwiSGF2aW5nQ2xhdXNlXCI6NjcsXCJIQVZJTkdcIjo2OCxcIkhhdmluZ0NsYXVzZV9yZXBldGl0aW9uX3BsdXMwXCI6NjksXCJPcmRlckNsYXVzZVwiOjcwLFwiT1JERVJcIjo3MSxcIk9yZGVyQ2xhdXNlX3JlcGV0aXRpb25fcGx1czBcIjo3MixcIk9yZGVyQ29uZGl0aW9uXCI6NzMsXCJBU0NcIjo3NCxcIkJyYWNrZXR0ZWRFeHByZXNzaW9uXCI6NzUsXCJERVNDXCI6NzYsXCJDb25zdHJhaW50XCI6NzcsXCJMaW1pdE9mZnNldENsYXVzZXNcIjo3OCxcIkxJTUlUXCI6NzksXCJJTlRFR0VSXCI6ODAsXCJPRkZTRVRcIjo4MSxcIlZhbHVlc0NsYXVzZVwiOjgyLFwiVkFMVUVTXCI6ODMsXCJJbmxpbmVEYXRhXCI6ODQsXCJJbmxpbmVEYXRhX3JlcGV0aXRpb24wXCI6ODUsXCJOSUxcIjo4NixcIklubGluZURhdGFfcmVwZXRpdGlvbjFcIjo4NyxcIklubGluZURhdGFfcmVwZXRpdGlvbl9wbHVzMlwiOjg4LFwiSW5saW5lRGF0YV9yZXBldGl0aW9uM1wiOjg5LFwiRGF0YUJsb2NrVmFsdWVcIjo5MCxcIkxpdGVyYWxcIjo5MSxcIlVOREVGXCI6OTIsXCJEYXRhQmxvY2tWYWx1ZUxpc3RcIjo5MyxcIkRhdGFCbG9ja1ZhbHVlTGlzdF9yZXBldGl0aW9uX3BsdXMwXCI6OTQsXCJVcGRhdGVcIjo5NSxcIlVwZGF0ZV9yZXBldGl0aW9uMFwiOjk2LFwiVXBkYXRlMVwiOjk3LFwiVXBkYXRlX29wdGlvbjBcIjo5OCxcIkxPQURcIjo5OSxcIlVwZGF0ZTFfb3B0aW9uMFwiOjEwMCxcIlVwZGF0ZTFfb3B0aW9uMVwiOjEwMSxcIlVwZGF0ZTFfZ3JvdXAwXCI6MTAyLFwiVXBkYXRlMV9vcHRpb24yXCI6MTAzLFwiR3JhcGhSZWZBbGxcIjoxMDQsXCJVcGRhdGUxX2dyb3VwMVwiOjEwNSxcIlVwZGF0ZTFfb3B0aW9uM1wiOjEwNixcIkdyYXBoT3JEZWZhdWx0XCI6MTA3LFwiVE9cIjoxMDgsXCJDUkVBVEVcIjoxMDksXCJVcGRhdGUxX29wdGlvbjRcIjoxMTAsXCJHUkFQSFwiOjExMSxcIklOU0VSVERBVEFcIjoxMTIsXCJRdWFkUGF0dGVyblwiOjExMyxcIkRFTEVURURBVEFcIjoxMTQsXCJERUxFVEVXSEVSRVwiOjExNSxcIlVwZGF0ZTFfb3B0aW9uNVwiOjExNixcIkluc2VydENsYXVzZVwiOjExNyxcIlVwZGF0ZTFfb3B0aW9uNlwiOjExOCxcIlVwZGF0ZTFfcmVwZXRpdGlvbjBcIjoxMTksXCJVcGRhdGUxX29wdGlvbjdcIjoxMjAsXCJEZWxldGVDbGF1c2VcIjoxMjEsXCJVcGRhdGUxX29wdGlvbjhcIjoxMjIsXCJVcGRhdGUxX3JlcGV0aXRpb24xXCI6MTIzLFwiREVMRVRFXCI6MTI0LFwiSU5TRVJUXCI6MTI1LFwiVXNpbmdDbGF1c2VcIjoxMjYsXCJVU0lOR1wiOjEyNyxcIlVzaW5nQ2xhdXNlX29wdGlvbjBcIjoxMjgsXCJXaXRoQ2xhdXNlXCI6MTI5LFwiV0lUSFwiOjEzMCxcIkludG9HcmFwaENsYXVzZVwiOjEzMSxcIklOVE9cIjoxMzIsXCJERUZBVUxUXCI6MTMzLFwiR3JhcGhPckRlZmF1bHRfb3B0aW9uMFwiOjEzNCxcIkdyYXBoUmVmQWxsX2dyb3VwMFwiOjEzNSxcIlF1YWRQYXR0ZXJuX29wdGlvbjBcIjoxMzYsXCJRdWFkUGF0dGVybl9yZXBldGl0aW9uMFwiOjEzNyxcIlF1YWRzTm90VHJpcGxlc1wiOjEzOCxcIlF1YWRzTm90VHJpcGxlc19ncm91cDBcIjoxMzksXCJRdWFkc05vdFRyaXBsZXNfb3B0aW9uMFwiOjE0MCxcIlF1YWRzTm90VHJpcGxlc19vcHRpb24xXCI6MTQxLFwiUXVhZHNOb3RUcmlwbGVzX29wdGlvbjJcIjoxNDIsXCJUcmlwbGVzVGVtcGxhdGVcIjoxNDMsXCJUcmlwbGVzVGVtcGxhdGVfcmVwZXRpdGlvbjBcIjoxNDQsXCJUcmlwbGVzU2FtZVN1YmplY3RcIjoxNDUsXCJUcmlwbGVzVGVtcGxhdGVfb3B0aW9uMFwiOjE0NixcIkdyb3VwR3JhcGhQYXR0ZXJuU3ViXCI6MTQ3LFwiR3JvdXBHcmFwaFBhdHRlcm5TdWJfb3B0aW9uMFwiOjE0OCxcIkdyb3VwR3JhcGhQYXR0ZXJuU3ViX3JlcGV0aXRpb24wXCI6MTQ5LFwiR3JvdXBHcmFwaFBhdHRlcm5TdWJUYWlsXCI6MTUwLFwiR3JhcGhQYXR0ZXJuTm90VHJpcGxlc1wiOjE1MSxcIkdyb3VwR3JhcGhQYXR0ZXJuU3ViVGFpbF9vcHRpb24wXCI6MTUyLFwiR3JvdXBHcmFwaFBhdHRlcm5TdWJUYWlsX29wdGlvbjFcIjoxNTMsXCJUcmlwbGVzQmxvY2tcIjoxNTQsXCJUcmlwbGVzQmxvY2tfcmVwZXRpdGlvbjBcIjoxNTUsXCJUcmlwbGVzU2FtZVN1YmplY3RQYXRoXCI6MTU2LFwiVHJpcGxlc0Jsb2NrX29wdGlvbjBcIjoxNTcsXCJHcmFwaFBhdHRlcm5Ob3RUcmlwbGVzX3JlcGV0aXRpb24wXCI6MTU4LFwiT1BUSU9OQUxcIjoxNTksXCJNSU5VU1wiOjE2MCxcIkdyYXBoUGF0dGVybk5vdFRyaXBsZXNfZ3JvdXAwXCI6MTYxLFwiU0VSVklDRVwiOjE2MixcIkdyYXBoUGF0dGVybk5vdFRyaXBsZXNfb3B0aW9uMFwiOjE2MyxcIkdyYXBoUGF0dGVybk5vdFRyaXBsZXNfZ3JvdXAxXCI6MTY0LFwiRklMVEVSXCI6MTY1LFwiQklORFwiOjE2NixcIkZ1bmN0aW9uQ2FsbF9vcHRpb24wXCI6MTY3LFwiRnVuY3Rpb25DYWxsX3JlcGV0aXRpb24wXCI6MTY4LFwiRXhwcmVzc2lvbkxpc3RcIjoxNjksXCJFeHByZXNzaW9uTGlzdF9yZXBldGl0aW9uMFwiOjE3MCxcIkNvbnN0cnVjdFRlbXBsYXRlX29wdGlvbjBcIjoxNzEsXCJDb25zdHJ1Y3RUcmlwbGVzXCI6MTcyLFwiQ29uc3RydWN0VHJpcGxlc19yZXBldGl0aW9uMFwiOjE3MyxcIkNvbnN0cnVjdFRyaXBsZXNfb3B0aW9uMFwiOjE3NCxcIlZhck9yVGVybVwiOjE3NSxcIlByb3BlcnR5TGlzdE5vdEVtcHR5XCI6MTc2LFwiVHJpcGxlc05vZGVcIjoxNzcsXCJQcm9wZXJ0eUxpc3RcIjoxNzgsXCJQcm9wZXJ0eUxpc3Rfb3B0aW9uMFwiOjE3OSxcIlZlcmJPYmplY3RMaXN0XCI6MTgwLFwiUHJvcGVydHlMaXN0Tm90RW1wdHlfcmVwZXRpdGlvbjBcIjoxODEsXCJTZW1pT3B0aW9uYWxWZXJiT2JqZWN0TGlzdFwiOjE4MixcIjtcIjoxODMsXCJTZW1pT3B0aW9uYWxWZXJiT2JqZWN0TGlzdF9vcHRpb24wXCI6MTg0LFwiVmVyYlwiOjE4NSxcIk9iamVjdExpc3RcIjoxODYsXCJhXCI6MTg3LFwiT2JqZWN0TGlzdF9yZXBldGl0aW9uMFwiOjE4OCxcIkdyYXBoTm9kZVwiOjE4OSxcIlByb3BlcnR5TGlzdFBhdGhOb3RFbXB0eVwiOjE5MCxcIlRyaXBsZXNOb2RlUGF0aFwiOjE5MSxcIlRyaXBsZXNTYW1lU3ViamVjdFBhdGhfb3B0aW9uMFwiOjE5MixcIlByb3BlcnR5TGlzdFBhdGhOb3RFbXB0eV9ncm91cDBcIjoxOTMsXCJQcm9wZXJ0eUxpc3RQYXRoTm90RW1wdHlfcmVwZXRpdGlvbjBcIjoxOTQsXCJHcmFwaE5vZGVQYXRoXCI6MTk1LFwiUHJvcGVydHlMaXN0UGF0aE5vdEVtcHR5X3JlcGV0aXRpb24xXCI6MTk2LFwiUHJvcGVydHlMaXN0UGF0aE5vdEVtcHR5VGFpbFwiOjE5NyxcIlByb3BlcnR5TGlzdFBhdGhOb3RFbXB0eVRhaWxfZ3JvdXAwXCI6MTk4LFwiUGF0aFwiOjE5OSxcIlBhdGhfcmVwZXRpdGlvbjBcIjoyMDAsXCJQYXRoU2VxdWVuY2VcIjoyMDEsXCJQYXRoU2VxdWVuY2VfcmVwZXRpdGlvbjBcIjoyMDIsXCJQYXRoRWx0T3JJbnZlcnNlXCI6MjAzLFwiUGF0aEVsdFwiOjIwNCxcIlBhdGhQcmltYXJ5XCI6MjA1LFwiUGF0aEVsdF9vcHRpb24wXCI6MjA2LFwiUGF0aEVsdE9ySW52ZXJzZV9vcHRpb24wXCI6MjA3LFwiIVwiOjIwOCxcIlBhdGhOZWdhdGVkUHJvcGVydHlTZXRcIjoyMDksXCJQYXRoT25lSW5Qcm9wZXJ0eVNldFwiOjIxMCxcIlBhdGhOZWdhdGVkUHJvcGVydHlTZXRfcmVwZXRpdGlvbjBcIjoyMTEsXCJQYXRoTmVnYXRlZFByb3BlcnR5U2V0X29wdGlvbjBcIjoyMTIsXCJeXCI6MjEzLFwiVHJpcGxlc05vZGVfcmVwZXRpdGlvbl9wbHVzMFwiOjIxNCxcIltcIjoyMTUsXCJdXCI6MjE2LFwiVHJpcGxlc05vZGVQYXRoX3JlcGV0aXRpb25fcGx1czBcIjoyMTcsXCJCTEFOS19OT0RFX0xBQkVMXCI6MjE4LFwiQU5PTlwiOjIxOSxcIkNvbmRpdGlvbmFsQW5kRXhwcmVzc2lvblwiOjIyMCxcIkV4cHJlc3Npb25fcmVwZXRpdGlvbjBcIjoyMjEsXCJFeHByZXNzaW9uVGFpbFwiOjIyMixcInx8XCI6MjIzLFwiUmVsYXRpb25hbEV4cHJlc3Npb25cIjoyMjQsXCJDb25kaXRpb25hbEFuZEV4cHJlc3Npb25fcmVwZXRpdGlvbjBcIjoyMjUsXCJDb25kaXRpb25hbEFuZEV4cHJlc3Npb25UYWlsXCI6MjI2LFwiJiZcIjoyMjcsXCJBZGRpdGl2ZUV4cHJlc3Npb25cIjoyMjgsXCJSZWxhdGlvbmFsRXhwcmVzc2lvbl9ncm91cDBcIjoyMjksXCJSZWxhdGlvbmFsRXhwcmVzc2lvbl9vcHRpb24wXCI6MjMwLFwiSU5cIjoyMzEsXCJNdWx0aXBsaWNhdGl2ZUV4cHJlc3Npb25cIjoyMzIsXCJBZGRpdGl2ZUV4cHJlc3Npb25fcmVwZXRpdGlvbjBcIjoyMzMsXCJBZGRpdGl2ZUV4cHJlc3Npb25UYWlsXCI6MjM0LFwiQWRkaXRpdmVFeHByZXNzaW9uVGFpbF9ncm91cDBcIjoyMzUsXCJOdW1lcmljTGl0ZXJhbFBvc2l0aXZlXCI6MjM2LFwiQWRkaXRpdmVFeHByZXNzaW9uVGFpbF9yZXBldGl0aW9uMFwiOjIzNyxcIk51bWVyaWNMaXRlcmFsTmVnYXRpdmVcIjoyMzgsXCJBZGRpdGl2ZUV4cHJlc3Npb25UYWlsX3JlcGV0aXRpb24xXCI6MjM5LFwiVW5hcnlFeHByZXNzaW9uXCI6MjQwLFwiTXVsdGlwbGljYXRpdmVFeHByZXNzaW9uX3JlcGV0aXRpb24wXCI6MjQxLFwiTXVsdGlwbGljYXRpdmVFeHByZXNzaW9uVGFpbFwiOjI0MixcIk11bHRpcGxpY2F0aXZlRXhwcmVzc2lvblRhaWxfZ3JvdXAwXCI6MjQzLFwiVW5hcnlFeHByZXNzaW9uX29wdGlvbjBcIjoyNDQsXCJQcmltYXJ5RXhwcmVzc2lvblwiOjI0NSxcIi1cIjoyNDYsXCJBZ2dyZWdhdGVcIjoyNDcsXCJGVU5DX0FSSVRZMFwiOjI0OCxcIkZVTkNfQVJJVFkxXCI6MjQ5LFwiRlVOQ19BUklUWTJcIjoyNTAsXCIsXCI6MjUxLFwiSUZcIjoyNTIsXCJCdWlsdEluQ2FsbF9ncm91cDBcIjoyNTMsXCJCT1VORFwiOjI1NCxcIkJOT0RFXCI6MjU1LFwiQnVpbHRJbkNhbGxfb3B0aW9uMFwiOjI1NixcIkVYSVNUU1wiOjI1NyxcIkNPVU5UXCI6MjU4LFwiQWdncmVnYXRlX29wdGlvbjBcIjoyNTksXCJBZ2dyZWdhdGVfZ3JvdXAwXCI6MjYwLFwiRlVOQ19BR0dSRUdBVEVcIjoyNjEsXCJBZ2dyZWdhdGVfb3B0aW9uMVwiOjI2MixcIkdST1VQX0NPTkNBVFwiOjI2MyxcIkFnZ3JlZ2F0ZV9vcHRpb24yXCI6MjY0LFwiQWdncmVnYXRlX29wdGlvbjNcIjoyNjUsXCJHcm91cENvbmNhdFNlcGFyYXRvclwiOjI2NixcIlNFUEFSQVRPUlwiOjI2NyxcIj1cIjoyNjgsXCJTdHJpbmdcIjoyNjksXCJMQU5HVEFHXCI6MjcwLFwiXl5cIjoyNzEsXCJERUNJTUFMXCI6MjcyLFwiRE9VQkxFXCI6MjczLFwidHJ1ZVwiOjI3NCxcImZhbHNlXCI6Mjc1LFwiU1RSSU5HX0xJVEVSQUwxXCI6Mjc2LFwiU1RSSU5HX0xJVEVSQUwyXCI6Mjc3LFwiU1RSSU5HX0xJVEVSQUxfTE9ORzFcIjoyNzgsXCJTVFJJTkdfTElURVJBTF9MT05HMlwiOjI3OSxcIklOVEVHRVJfUE9TSVRJVkVcIjoyODAsXCJERUNJTUFMX1BPU0lUSVZFXCI6MjgxLFwiRE9VQkxFX1BPU0lUSVZFXCI6MjgyLFwiSU5URUdFUl9ORUdBVElWRVwiOjI4MyxcIkRFQ0lNQUxfTkVHQVRJVkVcIjoyODQsXCJET1VCTEVfTkVHQVRJVkVcIjoyODUsXCJQTkFNRV9MTlwiOjI4NixcIlF1ZXJ5T3JVcGRhdGVfZ3JvdXAwX29wdGlvbjBcIjoyODcsXCJQcm9sb2d1ZV9yZXBldGl0aW9uMF9ncm91cDBcIjoyODgsXCJTZWxlY3RDbGF1c2Vfb3B0aW9uMF9ncm91cDBcIjoyODksXCJESVNUSU5DVFwiOjI5MCxcIlJFRFVDRURcIjoyOTEsXCJTZWxlY3RDbGF1c2VfZ3JvdXAwX3JlcGV0aXRpb25fcGx1czBcIjoyOTIsXCIqXCI6MjkzLFwiRGVzY3JpYmVRdWVyeV9ncm91cDBfcmVwZXRpdGlvbl9wbHVzMF9ncm91cDBcIjoyOTQsXCJEZXNjcmliZVF1ZXJ5X2dyb3VwMF9yZXBldGl0aW9uX3BsdXMwXCI6Mjk1LFwiTkFNRURcIjoyOTYsXCJTSUxFTlRcIjoyOTcsXCJDTEVBUlwiOjI5OCxcIkRST1BcIjoyOTksXCJBRERcIjozMDAsXCJNT1ZFXCI6MzAxLFwiQ09QWVwiOjMwMixcIkFMTFwiOjMwMyxcIi5cIjozMDQsXCJVTklPTlwiOjMwNSxcInxcIjozMDYsXCIvXCI6MzA3LFwiUGF0aEVsdF9vcHRpb24wX2dyb3VwMFwiOjMwOCxcIj9cIjozMDksXCIrXCI6MzEwLFwiIT1cIjozMTEsXCI8XCI6MzEyLFwiPlwiOjMxMyxcIjw9XCI6MzE0LFwiPj1cIjozMTUsXCJOT1RcIjozMTYsXCJDT05DQVRcIjozMTcsXCJDT0FMRVNDRVwiOjMxOCxcIlNVQlNUUlwiOjMxOSxcIlJFR0VYXCI6MzIwLFwiUkVQTEFDRVwiOjMyMSxcIiRhY2NlcHRcIjowLFwiJGVuZFwiOjF9LFxudGVybWluYWxzXzogezI6XCJlcnJvclwiLDY6XCJFT0ZcIiwxMjpcIkJBU0VcIiwxMzpcIklSSVJFRlwiLDE1OlwiUFJFRklYXCIsMTY6XCJQTkFNRV9OU1wiLDI0OlwiU0VMRUNUXCIsMjg6XCJWQVJcIiwyOTpcIihcIiwzMTpcIkFTXCIsMzI6XCIpXCIsMzQ6XCJDT05TVFJVQ1RcIiwzODpcIldIRVJFXCIsMzk6XCJ7XCIsNDE6XCJ9XCIsNDM6XCJERVNDUklCRVwiLDQ4OlwiQVNLXCIsNTE6XCJGUk9NXCIsNjE6XCJHUk9VUFwiLDYyOlwiQllcIiw2ODpcIkhBVklOR1wiLDcxOlwiT1JERVJcIiw3NDpcIkFTQ1wiLDc2OlwiREVTQ1wiLDc5OlwiTElNSVRcIiw4MDpcIklOVEVHRVJcIiw4MTpcIk9GRlNFVFwiLDgzOlwiVkFMVUVTXCIsODY6XCJOSUxcIiw5MjpcIlVOREVGXCIsOTk6XCJMT0FEXCIsMTA4OlwiVE9cIiwxMDk6XCJDUkVBVEVcIiwxMTE6XCJHUkFQSFwiLDExMjpcIklOU0VSVERBVEFcIiwxMTQ6XCJERUxFVEVEQVRBXCIsMTE1OlwiREVMRVRFV0hFUkVcIiwxMjQ6XCJERUxFVEVcIiwxMjU6XCJJTlNFUlRcIiwxMjc6XCJVU0lOR1wiLDEzMDpcIldJVEhcIiwxMzI6XCJJTlRPXCIsMTMzOlwiREVGQVVMVFwiLDE1OTpcIk9QVElPTkFMXCIsMTYwOlwiTUlOVVNcIiwxNjI6XCJTRVJWSUNFXCIsMTY1OlwiRklMVEVSXCIsMTY2OlwiQklORFwiLDE4MzpcIjtcIiwxODc6XCJhXCIsMjA4OlwiIVwiLDIxMzpcIl5cIiwyMTU6XCJbXCIsMjE2OlwiXVwiLDIxODpcIkJMQU5LX05PREVfTEFCRUxcIiwyMTk6XCJBTk9OXCIsMjIzOlwifHxcIiwyMjc6XCImJlwiLDIzMTpcIklOXCIsMjQ2OlwiLVwiLDI0ODpcIkZVTkNfQVJJVFkwXCIsMjQ5OlwiRlVOQ19BUklUWTFcIiwyNTA6XCJGVU5DX0FSSVRZMlwiLDI1MTpcIixcIiwyNTI6XCJJRlwiLDI1NDpcIkJPVU5EXCIsMjU1OlwiQk5PREVcIiwyNTc6XCJFWElTVFNcIiwyNTg6XCJDT1VOVFwiLDI2MTpcIkZVTkNfQUdHUkVHQVRFXCIsMjYzOlwiR1JPVVBfQ09OQ0FUXCIsMjY3OlwiU0VQQVJBVE9SXCIsMjY4OlwiPVwiLDI3MDpcIkxBTkdUQUdcIiwyNzE6XCJeXlwiLDI3MjpcIkRFQ0lNQUxcIiwyNzM6XCJET1VCTEVcIiwyNzQ6XCJ0cnVlXCIsMjc1OlwiZmFsc2VcIiwyNzY6XCJTVFJJTkdfTElURVJBTDFcIiwyNzc6XCJTVFJJTkdfTElURVJBTDJcIiwyNzg6XCJTVFJJTkdfTElURVJBTF9MT05HMVwiLDI3OTpcIlNUUklOR19MSVRFUkFMX0xPTkcyXCIsMjgwOlwiSU5URUdFUl9QT1NJVElWRVwiLDI4MTpcIkRFQ0lNQUxfUE9TSVRJVkVcIiwyODI6XCJET1VCTEVfUE9TSVRJVkVcIiwyODM6XCJJTlRFR0VSX05FR0FUSVZFXCIsMjg0OlwiREVDSU1BTF9ORUdBVElWRVwiLDI4NTpcIkRPVUJMRV9ORUdBVElWRVwiLDI4NjpcIlBOQU1FX0xOXCIsMjkwOlwiRElTVElOQ1RcIiwyOTE6XCJSRURVQ0VEXCIsMjkzOlwiKlwiLDI5NjpcIk5BTUVEXCIsMjk3OlwiU0lMRU5UXCIsMjk4OlwiQ0xFQVJcIiwyOTk6XCJEUk9QXCIsMzAwOlwiQUREXCIsMzAxOlwiTU9WRVwiLDMwMjpcIkNPUFlcIiwzMDM6XCJBTExcIiwzMDQ6XCIuXCIsMzA1OlwiVU5JT05cIiwzMDY6XCJ8XCIsMzA3OlwiL1wiLDMwOTpcIj9cIiwzMTA6XCIrXCIsMzExOlwiIT1cIiwzMTI6XCI8XCIsMzEzOlwiPlwiLDMxNDpcIjw9XCIsMzE1OlwiPj1cIiwzMTY6XCJOT1RcIiwzMTc6XCJDT05DQVRcIiwzMTg6XCJDT0FMRVNDRVwiLDMxOTpcIlNVQlNUUlwiLDMyMDpcIlJFR0VYXCIsMzIxOlwiUkVQTEFDRVwifSxcbnByb2R1Y3Rpb25zXzogWzAsWzMsM10sWzQsMV0sWzgsMl0sWzExLDJdLFsxNCwzXSxbMTcsNF0sWzIyLDRdLFsxOCwzXSxbMjcsMV0sWzI3LDVdLFszMyw1XSxbMzMsN10sWzQyLDVdLFs0Nyw0XSxbNTAsM10sWzIwLDJdLFsyMSw0XSxbNjAsM10sWzY0LDFdLFs2NCwxXSxbNjQsM10sWzY0LDVdLFs2NCwxXSxbNjcsMl0sWzcwLDNdLFs3MywyXSxbNzMsMl0sWzczLDFdLFs3MywxXSxbNzgsMl0sWzc4LDJdLFs3OCw0XSxbNzgsNF0sWzgyLDJdLFs4NCw0XSxbODQsNF0sWzg0LDZdLFs5MCwxXSxbOTAsMV0sWzkwLDFdLFs5MywzXSxbOTUsM10sWzk3LDRdLFs5NywzXSxbOTcsNV0sWzk3LDRdLFs5NywyXSxbOTcsMl0sWzk3LDJdLFs5Nyw2XSxbOTcsNl0sWzEyMSwyXSxbMTE3LDJdLFsxMjYsM10sWzEyOSwyXSxbMTMxLDNdLFsxMDcsMV0sWzEwNywyXSxbMTA0LDJdLFsxMDQsMV0sWzExMyw0XSxbMTM4LDddLFsxNDMsM10sWzU1LDNdLFs1NSwzXSxbMTQ3LDJdLFsxNTAsM10sWzE1NCwzXSxbMTUxLDJdLFsxNTEsMl0sWzE1MSwyXSxbMTUxLDNdLFsxNTEsNF0sWzE1MSwyXSxbMTUxLDZdLFsxNTEsMV0sWzc3LDFdLFs3NywxXSxbNzcsMV0sWzY2LDJdLFs2Niw2XSxbMTY5LDFdLFsxNjksNF0sWzM1LDNdLFsxNzIsM10sWzE0NSwyXSxbMTQ1LDJdLFsxNzgsMV0sWzE3NiwyXSxbMTgyLDJdLFsxODAsMl0sWzE4NSwxXSxbMTg1LDFdLFsxODUsMV0sWzE4NiwyXSxbMTU2LDJdLFsxNTYsMl0sWzE5MCw0XSxbMTk3LDFdLFsxOTcsM10sWzE5OSwyXSxbMjAxLDJdLFsyMDQsMl0sWzIwMywyXSxbMjA1LDFdLFsyMDUsMV0sWzIwNSwyXSxbMjA1LDNdLFsyMDksMV0sWzIwOSwxXSxbMjA5LDRdLFsyMTAsMV0sWzIxMCwxXSxbMjEwLDJdLFsyMTAsMl0sWzE3NywzXSxbMTc3LDNdLFsxOTEsM10sWzE5MSwzXSxbMTg5LDFdLFsxODksMV0sWzE5NSwxXSxbMTk1LDFdLFsxNzUsMV0sWzE3NSwxXSxbMTc1LDFdLFsxNzUsMV0sWzE3NSwxXSxbMTc1LDFdLFszMCwyXSxbMjIyLDJdLFsyMjAsMl0sWzIyNiwyXSxbMjI0LDFdLFsyMjQsM10sWzIyNCw0XSxbMjI4LDJdLFsyMzQsMl0sWzIzNCwyXSxbMjM0LDJdLFsyMzIsMl0sWzI0MiwyXSxbMjQwLDJdLFsyNDAsMl0sWzI0MCwyXSxbMjQ1LDFdLFsyNDUsMV0sWzI0NSwxXSxbMjQ1LDFdLFsyNDUsMV0sWzI0NSwxXSxbNzUsM10sWzY1LDFdLFs2NSwyXSxbNjUsNF0sWzY1LDZdLFs2NSw4XSxbNjUsMl0sWzY1LDRdLFs2NSwyXSxbNjUsNF0sWzY1LDNdLFsyNDcsNV0sWzI0Nyw1XSxbMjQ3LDZdLFsyNjYsNF0sWzkxLDFdLFs5MSwyXSxbOTEsM10sWzkxLDFdLFs5MSwxXSxbOTEsMV0sWzkxLDFdLFs5MSwxXSxbOTEsMV0sWzkxLDFdLFsyNjksMV0sWzI2OSwxXSxbMjY5LDFdLFsyNjksMV0sWzIzNiwxXSxbMjM2LDFdLFsyMzYsMV0sWzIzOCwxXSxbMjM4LDFdLFsyMzgsMV0sWzUzLDFdLFs1MywxXSxbNTMsMV0sWzI4NywwXSxbMjg3LDFdLFs1LDFdLFs1LDFdLFsyODgsMV0sWzI4OCwxXSxbNywwXSxbNywyXSxbOSwxXSxbOSwxXSxbOSwxXSxbOSwxXSxbMTAsMF0sWzEwLDFdLFsxOSwwXSxbMTksMl0sWzIzLDBdLFsyMywxXSxbMjg5LDFdLFsyODksMV0sWzI1LDBdLFsyNSwxXSxbMjkyLDFdLFsyOTIsMl0sWzI2LDFdLFsyNiwxXSxbMzYsMF0sWzM2LDJdLFszNywwXSxbMzcsMl0sWzQwLDBdLFs0MCwxXSxbMjk0LDFdLFsyOTQsMV0sWzI5NSwxXSxbMjk1LDJdLFs0NCwxXSxbNDQsMV0sWzQ1LDBdLFs0NSwyXSxbNDYsMF0sWzQ2LDFdLFs0OSwwXSxbNDksMl0sWzUyLDBdLFs1MiwxXSxbNTQsMF0sWzU0LDFdLFs1NiwwXSxbNTYsMV0sWzU3LDBdLFs1NywxXSxbNTgsMF0sWzU4LDFdLFs1OSwwXSxbNTksMV0sWzYzLDFdLFs2MywyXSxbNjksMV0sWzY5LDJdLFs3MiwxXSxbNzIsMl0sWzg1LDBdLFs4NSwyXSxbODcsMF0sWzg3LDJdLFs4OCwxXSxbODgsMl0sWzg5LDBdLFs4OSwyXSxbOTQsMV0sWzk0LDJdLFs5NiwwXSxbOTYsNF0sWzk4LDBdLFs5OCwyXSxbMTAwLDBdLFsxMDAsMV0sWzEwMSwwXSxbMTAxLDFdLFsxMDIsMV0sWzEwMiwxXSxbMTAzLDBdLFsxMDMsMV0sWzEwNSwxXSxbMTA1LDFdLFsxMDUsMV0sWzEwNiwwXSxbMTA2LDFdLFsxMTAsMF0sWzExMCwxXSxbMTE2LDBdLFsxMTYsMV0sWzExOCwwXSxbMTE4LDFdLFsxMTksMF0sWzExOSwyXSxbMTIwLDBdLFsxMjAsMV0sWzEyMiwwXSxbMTIyLDFdLFsxMjMsMF0sWzEyMywyXSxbMTI4LDBdLFsxMjgsMV0sWzEzNCwwXSxbMTM0LDFdLFsxMzUsMV0sWzEzNSwxXSxbMTM1LDFdLFsxMzYsMF0sWzEzNiwxXSxbMTM3LDBdLFsxMzcsMl0sWzEzOSwxXSxbMTM5LDFdLFsxNDAsMF0sWzE0MCwxXSxbMTQxLDBdLFsxNDEsMV0sWzE0MiwwXSxbMTQyLDFdLFsxNDQsMF0sWzE0NCwzXSxbMTQ2LDBdLFsxNDYsMV0sWzE0OCwwXSxbMTQ4LDFdLFsxNDksMF0sWzE0OSwyXSxbMTUyLDBdLFsxNTIsMV0sWzE1MywwXSxbMTUzLDFdLFsxNTUsMF0sWzE1NSwzXSxbMTU3LDBdLFsxNTcsMV0sWzE1OCwwXSxbMTU4LDNdLFsxNjEsMV0sWzE2MSwxXSxbMTYzLDBdLFsxNjMsMV0sWzE2NCwxXSxbMTY0LDFdLFsxNjcsMF0sWzE2NywxXSxbMTY4LDBdLFsxNjgsM10sWzE3MCwwXSxbMTcwLDNdLFsxNzEsMF0sWzE3MSwxXSxbMTczLDBdLFsxNzMsM10sWzE3NCwwXSxbMTc0LDFdLFsxNzksMF0sWzE3OSwxXSxbMTgxLDBdLFsxODEsMl0sWzE4NCwwXSxbMTg0LDFdLFsxODgsMF0sWzE4OCwzXSxbMTkyLDBdLFsxOTIsMV0sWzE5MywxXSxbMTkzLDFdLFsxOTQsMF0sWzE5NCwzXSxbMTk2LDBdLFsxOTYsMl0sWzE5OCwxXSxbMTk4LDFdLFsyMDAsMF0sWzIwMCwzXSxbMjAyLDBdLFsyMDIsM10sWzMwOCwxXSxbMzA4LDFdLFszMDgsMV0sWzIwNiwwXSxbMjA2LDFdLFsyMDcsMF0sWzIwNywxXSxbMjExLDBdLFsyMTEsM10sWzIxMiwwXSxbMjEyLDFdLFsyMTQsMV0sWzIxNCwyXSxbMjE3LDFdLFsyMTcsMl0sWzIyMSwwXSxbMjIxLDJdLFsyMjUsMF0sWzIyNSwyXSxbMjI5LDFdLFsyMjksMV0sWzIyOSwxXSxbMjI5LDFdLFsyMjksMV0sWzIyOSwxXSxbMjMwLDBdLFsyMzAsMV0sWzIzMywwXSxbMjMzLDJdLFsyMzUsMV0sWzIzNSwxXSxbMjM3LDBdLFsyMzcsMl0sWzIzOSwwXSxbMjM5LDJdLFsyNDEsMF0sWzI0MSwyXSxbMjQzLDFdLFsyNDMsMV0sWzI0NCwwXSxbMjQ0LDFdLFsyNTMsMV0sWzI1MywxXSxbMjUzLDFdLFsyNTMsMV0sWzI1MywxXSxbMjU2LDBdLFsyNTYsMV0sWzI1OSwwXSxbMjU5LDFdLFsyNjAsMV0sWzI2MCwxXSxbMjYyLDBdLFsyNjIsMV0sWzI2NCwwXSxbMjY0LDFdLFsyNjUsMF0sWzI2NSwxXV0sXG5wZXJmb3JtQWN0aW9uOiBmdW5jdGlvbiBhbm9ueW1vdXMoeXl0ZXh0LCB5eWxlbmcsIHl5bGluZW5vLCB5eSwgeXlzdGF0ZSAvKiBhY3Rpb25bMV0gKi8sICQkIC8qIHZzdGFjayAqLywgXyQgLyogbHN0YWNrICovKSB7XG4vKiB0aGlzID09IHl5dmFsICovXG5cbnZhciAkMCA9ICQkLmxlbmd0aCAtIDE7XG5zd2l0Y2ggKHl5c3RhdGUpIHtcbmNhc2UgMTpcblxuICAgICAgJCRbJDAtMV0gPSAkJFskMC0xXSB8fCB7fTtcbiAgICAgIGlmIChQYXJzZXIuYmFzZSlcbiAgICAgICAgJCRbJDAtMV0uYmFzZSA9IFBhcnNlci5iYXNlO1xuICAgICAgUGFyc2VyLmJhc2UgPSBiYXNlID0gYmFzZVBhdGggPSBiYXNlUm9vdCA9ICcnO1xuICAgICAgJCRbJDAtMV0ucHJlZml4ZXMgPSBQYXJzZXIucHJlZml4ZXM7XG4gICAgICBQYXJzZXIucHJlZml4ZXMgPSBudWxsO1xuICAgICAgcmV0dXJuICQkWyQwLTFdO1xuICAgIFxuYnJlYWs7XG5jYXNlIDM6XG50aGlzLiQgPSBleHRlbmQoJCRbJDAtMV0sICQkWyQwXSwgeyB0eXBlOiAncXVlcnknIH0pO1xuYnJlYWs7XG5jYXNlIDQ6XG5cbiAgICAgIFBhcnNlci5iYXNlID0gcmVzb2x2ZUlSSSgkJFskMF0pXG4gICAgICBiYXNlID0gYmFzZVBhdGggPSBiYXNlUm9vdCA9ICcnO1xuICAgIFxuYnJlYWs7XG5jYXNlIDU6XG5cbiAgICAgIGlmICghUGFyc2VyLnByZWZpeGVzKSBQYXJzZXIucHJlZml4ZXMgPSB7fTtcbiAgICAgICQkWyQwLTFdID0gJCRbJDAtMV0uc3Vic3RyKDAsICQkWyQwLTFdLmxlbmd0aCAtIDEpO1xuICAgICAgJCRbJDBdID0gcmVzb2x2ZUlSSSgkJFskMF0pO1xuICAgICAgUGFyc2VyLnByZWZpeGVzWyQkWyQwLTFdXSA9ICQkWyQwXTtcbiAgICBcbmJyZWFrO1xuY2FzZSA2OlxudGhpcy4kID0gZXh0ZW5kKCQkWyQwLTNdLCBncm91cERhdGFzZXRzKCQkWyQwLTJdKSwgJCRbJDAtMV0sICQkWyQwXSk7XG5icmVhaztcbmNhc2UgNzpcbnRoaXMuJCA9IGV4dGVuZCgkJFskMC0zXSwgJCRbJDAtMl0sICQkWyQwLTFdLCAkJFskMF0sIHsgdHlwZTogJ3F1ZXJ5JyB9KTtcbmJyZWFrO1xuY2FzZSA4OlxudGhpcy4kID0gZXh0ZW5kKHsgcXVlcnlUeXBlOiAnU0VMRUNUJywgdmFyaWFibGVzOiAkJFskMF0gPT09ICcqJyA/IFsnKiddIDogJCRbJDBdIH0sICQkWyQwLTFdICYmICgkJFskMC0yXSA9IGxvd2VyY2FzZSgkJFskMC0xXSksICQkWyQwLTFdID0ge30sICQkWyQwLTFdWyQkWyQwLTJdXSA9IHRydWUsICQkWyQwLTFdKSk7XG5icmVhaztcbmNhc2UgOTogY2FzZSA5MjogY2FzZSAxMjQ6IGNhc2UgMTUxOlxudGhpcy4kID0gdG9WYXIoJCRbJDBdKTtcbmJyZWFrO1xuY2FzZSAxMDogY2FzZSAyMjpcbnRoaXMuJCA9IGV4cHJlc3Npb24oJCRbJDAtM10sIHsgdmFyaWFibGU6IHRvVmFyKCQkWyQwLTFdKSB9KTtcbmJyZWFrO1xuY2FzZSAxMTpcbnRoaXMuJCA9IGV4dGVuZCh7IHF1ZXJ5VHlwZTogJ0NPTlNUUlVDVCcsIHRlbXBsYXRlOiAkJFskMC0zXSB9LCBncm91cERhdGFzZXRzKCQkWyQwLTJdKSwgJCRbJDAtMV0sICQkWyQwXSk7XG5icmVhaztcbmNhc2UgMTI6XG50aGlzLiQgPSBleHRlbmQoeyBxdWVyeVR5cGU6ICdDT05TVFJVQ1QnLCB0ZW1wbGF0ZTogJCRbJDAtMl0gPSAoJCRbJDAtMl0gPyAkJFskMC0yXS50cmlwbGVzIDogW10pIH0sIGdyb3VwRGF0YXNldHMoJCRbJDAtNV0pLCB7IHdoZXJlOiBbIHsgdHlwZTogJ2JncCcsIHRyaXBsZXM6IGFwcGVuZEFsbFRvKFtdLCAkJFskMC0yXSkgfSBdIH0sICQkWyQwXSk7XG5icmVhaztcbmNhc2UgMTM6XG50aGlzLiQgPSBleHRlbmQoeyBxdWVyeVR5cGU6ICdERVNDUklCRScsIHZhcmlhYmxlczogJCRbJDAtM10gPT09ICcqJyA/IFsnKiddIDogJCRbJDAtM10ubWFwKHRvVmFyKSB9LCBncm91cERhdGFzZXRzKCQkWyQwLTJdKSwgJCRbJDAtMV0sICQkWyQwXSk7XG5icmVhaztcbmNhc2UgMTQ6XG50aGlzLiQgPSBleHRlbmQoeyBxdWVyeVR5cGU6ICdBU0snIH0sIGdyb3VwRGF0YXNldHMoJCRbJDAtMl0pLCAkJFskMC0xXSwgJCRbJDBdKTtcbmJyZWFrO1xuY2FzZSAxNTogY2FzZSA1NDpcbnRoaXMuJCA9IHsgaXJpOiAkJFskMF0sIG5hbWVkOiAhISQkWyQwLTFdIH07XG5icmVhaztcbmNhc2UgMTY6XG50aGlzLiQgPSB7IHdoZXJlOiAkJFskMF0ucGF0dGVybnMgfTtcbmJyZWFrO1xuY2FzZSAxNzpcbnRoaXMuJCA9IGV4dGVuZCgkJFskMC0zXSwgJCRbJDAtMl0sICQkWyQwLTFdLCAkJFskMF0pO1xuYnJlYWs7XG5jYXNlIDE4OlxudGhpcy4kID0geyBncm91cDogJCRbJDBdIH07XG5icmVhaztcbmNhc2UgMTk6IGNhc2UgMjA6IGNhc2UgMjY6IGNhc2UgMjg6XG50aGlzLiQgPSBleHByZXNzaW9uKCQkWyQwXSk7XG5icmVhaztcbmNhc2UgMjE6XG50aGlzLiQgPSBleHByZXNzaW9uKCQkWyQwLTFdKTtcbmJyZWFrO1xuY2FzZSAyMzogY2FzZSAyOTpcbnRoaXMuJCA9IGV4cHJlc3Npb24odG9WYXIoJCRbJDBdKSk7XG5icmVhaztcbmNhc2UgMjQ6XG50aGlzLiQgPSB7IGhhdmluZzogJCRbJDBdIH07XG5icmVhaztcbmNhc2UgMjU6XG50aGlzLiQgPSB7IG9yZGVyOiAkJFskMF0gfTtcbmJyZWFrO1xuY2FzZSAyNzpcbnRoaXMuJCA9IGV4cHJlc3Npb24oJCRbJDBdLCB7IGRlc2NlbmRpbmc6IHRydWUgfSk7XG5icmVhaztcbmNhc2UgMzA6XG50aGlzLiQgPSB7IGxpbWl0OiAgdG9JbnQoJCRbJDBdKSB9O1xuYnJlYWs7XG5jYXNlIDMxOlxudGhpcy4kID0geyBvZmZzZXQ6IHRvSW50KCQkWyQwXSkgfTtcbmJyZWFrO1xuY2FzZSAzMjpcbnRoaXMuJCA9IHsgbGltaXQ6IHRvSW50KCQkWyQwLTJdKSwgb2Zmc2V0OiB0b0ludCgkJFskMF0pIH07XG5icmVhaztcbmNhc2UgMzM6XG50aGlzLiQgPSB7IGxpbWl0OiB0b0ludCgkJFskMF0pLCBvZmZzZXQ6IHRvSW50KCQkWyQwLTJdKSB9O1xuYnJlYWs7XG5jYXNlIDM0OlxudGhpcy4kID0geyB0eXBlOiAndmFsdWVzJywgdmFsdWVzOiAkJFskMF0gfTtcbmJyZWFrO1xuY2FzZSAzNTpcblxuICAgICAgJCRbJDAtM10gPSB0b1ZhcigkJFskMC0zXSk7XG4gICAgICB0aGlzLiQgPSAkJFskMC0xXS5tYXAoZnVuY3Rpb24odikgeyB2YXIgbyA9IHt9OyBvWyQkWyQwLTNdXSA9IHY7IHJldHVybiBvOyB9KVxuICAgIFxuYnJlYWs7XG5jYXNlIDM2OlxuXG4gICAgICB0aGlzLiQgPSAkJFskMC0xXS5tYXAoZnVuY3Rpb24oKSB7IHJldHVybiB7fTsgfSlcbiAgICBcbmJyZWFrO1xuY2FzZSAzNzpcblxuICAgICAgdmFyIGxlbmd0aCA9ICQkWyQwLTRdLmxlbmd0aDtcbiAgICAgICQkWyQwLTRdID0gJCRbJDAtNF0ubWFwKHRvVmFyKTtcbiAgICAgIHRoaXMuJCA9ICQkWyQwLTFdLm1hcChmdW5jdGlvbiAodmFsdWVzKSB7XG4gICAgICAgIGlmICh2YWx1ZXMubGVuZ3RoICE9PSBsZW5ndGgpXG4gICAgICAgICAgdGhyb3cgRXJyb3IoJ0luY29uc2lzdGVudCBWQUxVRVMgbGVuZ3RoJyk7XG4gICAgICAgIHZhciB2YWx1ZXNPYmplY3QgPSB7fTtcbiAgICAgICAgZm9yKHZhciBpID0gMDsgaTxsZW5ndGg7IGkrKylcbiAgICAgICAgICB2YWx1ZXNPYmplY3RbJCRbJDAtNF1baV1dID0gdmFsdWVzW2ldO1xuICAgICAgICByZXR1cm4gdmFsdWVzT2JqZWN0O1xuICAgICAgfSk7XG4gICAgXG5icmVhaztcbmNhc2UgNDA6XG50aGlzLiQgPSB1bmRlZmluZWQ7XG5icmVhaztcbmNhc2UgNDE6IGNhc2UgODQ6IGNhc2UgMTA4OiBjYXNlIDE1MjpcbnRoaXMuJCA9ICQkWyQwLTFdO1xuYnJlYWs7XG5jYXNlIDQyOlxudGhpcy4kID0geyB0eXBlOiAndXBkYXRlJywgdXBkYXRlczogYXBwZW5kVG8oJCRbJDAtMl0sICQkWyQwLTFdKSB9O1xuYnJlYWs7XG5jYXNlIDQzOlxudGhpcy4kID0gZXh0ZW5kKHsgdHlwZTogJ2xvYWQnLCBzaWxlbnQ6ICEhJCRbJDAtMl0sIHNvdXJjZTogJCRbJDAtMV0gfSwgJCRbJDBdICYmIHsgZGVzdGluYXRpb246ICQkWyQwXSB9KTtcbmJyZWFrO1xuY2FzZSA0NDpcbnRoaXMuJCA9IHsgdHlwZTogbG93ZXJjYXNlKCQkWyQwLTJdKSwgc2lsZW50OiAhISQkWyQwLTFdLCBncmFwaDogJCRbJDBdIH07XG5icmVhaztcbmNhc2UgNDU6XG50aGlzLiQgPSB7IHR5cGU6IGxvd2VyY2FzZSgkJFskMC00XSksIHNpbGVudDogISEkJFskMC0zXSwgc291cmNlOiAkJFskMC0yXSwgZGVzdGluYXRpb246ICQkWyQwXSB9O1xuYnJlYWs7XG5jYXNlIDQ2OlxudGhpcy4kID0geyB0eXBlOiAnY3JlYXRlJywgc2lsZW50OiAhISQkWyQwLTJdLCBncmFwaDogeyB0eXBlOiAnZ3JhcGgnLCBuYW1lOiAkJFskMF0gfSB9O1xuYnJlYWs7XG5jYXNlIDQ3OlxudGhpcy4kID0geyB1cGRhdGVUeXBlOiAnaW5zZXJ0JywgICAgICBpbnNlcnQ6ICQkWyQwXSB9O1xuYnJlYWs7XG5jYXNlIDQ4OlxudGhpcy4kID0geyB1cGRhdGVUeXBlOiAnZGVsZXRlJywgICAgICBkZWxldGU6ICQkWyQwXSB9O1xuYnJlYWs7XG5jYXNlIDQ5OlxudGhpcy4kID0geyB1cGRhdGVUeXBlOiAnZGVsZXRld2hlcmUnLCBkZWxldGU6ICQkWyQwXSB9O1xuYnJlYWs7XG5jYXNlIDUwOlxudGhpcy4kID0gZXh0ZW5kKHsgdXBkYXRlVHlwZTogJ2luc2VydGRlbGV0ZScgfSwgJCRbJDAtNV0sIHsgaW5zZXJ0OiAkJFskMC00XSB8fCBbXSB9LCB7IGRlbGV0ZTogJCRbJDAtM10gfHwgW10gfSwgZ3JvdXBEYXRhc2V0cygkJFskMC0yXSksIHsgd2hlcmU6ICQkWyQwXS5wYXR0ZXJucyB9KTtcbmJyZWFrO1xuY2FzZSA1MTpcbnRoaXMuJCA9IGV4dGVuZCh7IHVwZGF0ZVR5cGU6ICdpbnNlcnRkZWxldGUnIH0sICQkWyQwLTVdLCB7IGRlbGV0ZTogJCRbJDAtNF0gfHwgW10gfSwgeyBpbnNlcnQ6ICQkWyQwLTNdIHx8IFtdIH0sIGdyb3VwRGF0YXNldHMoJCRbJDAtMl0pLCB7IHdoZXJlOiAkJFskMF0ucGF0dGVybnMgfSk7XG5icmVhaztcbmNhc2UgNTI6IGNhc2UgNTM6IGNhc2UgNTY6IGNhc2UgMTQzOlxudGhpcy4kID0gJCRbJDBdO1xuYnJlYWs7XG5jYXNlIDU1OlxudGhpcy4kID0geyBncmFwaDogJCRbJDBdIH07XG5icmVhaztcbmNhc2UgNTc6XG50aGlzLiQgPSB7IHR5cGU6ICdncmFwaCcsIGRlZmF1bHQ6IHRydWUgfTtcbmJyZWFrO1xuY2FzZSA1ODogY2FzZSA1OTpcbnRoaXMuJCA9IHsgdHlwZTogJ2dyYXBoJywgbmFtZTogJCRbJDBdIH07XG5icmVhaztcbmNhc2UgNjA6XG4gdGhpcy4kID0ge307IHRoaXMuJFtsb3dlcmNhc2UoJCRbJDBdKV0gPSB0cnVlOyBcbmJyZWFrO1xuY2FzZSA2MTpcbnRoaXMuJCA9ICQkWyQwLTJdID8gdW5pb25BbGwoJCRbJDAtMV0sIFskJFskMC0yXV0pIDogdW5pb25BbGwoJCRbJDAtMV0pO1xuYnJlYWs7XG5jYXNlIDYyOlxuXG4gICAgICB2YXIgZ3JhcGggPSBleHRlbmQoJCRbJDAtM10gfHwgeyB0cmlwbGVzOiBbXSB9LCB7IHR5cGU6ICdncmFwaCcsIG5hbWU6IHRvVmFyKCQkWyQwLTVdKSB9KTtcbiAgICAgIHRoaXMuJCA9ICQkWyQwXSA/IFtncmFwaCwgJCRbJDBdXSA6IFtncmFwaF07XG4gICAgXG5icmVhaztcbmNhc2UgNjM6IGNhc2UgNjg6XG50aGlzLiQgPSB7IHR5cGU6ICdiZ3AnLCB0cmlwbGVzOiB1bmlvbkFsbCgkJFskMC0yXSwgWyQkWyQwLTFdXSkgfTtcbmJyZWFrO1xuY2FzZSA2NDpcbnRoaXMuJCA9IHsgdHlwZTogJ2dyb3VwJywgcGF0dGVybnM6IFsgJCRbJDAtMV0gXSB9O1xuYnJlYWs7XG5jYXNlIDY1OlxudGhpcy4kID0geyB0eXBlOiAnZ3JvdXAnLCBwYXR0ZXJuczogJCRbJDAtMV0gfTtcbmJyZWFrO1xuY2FzZSA2NjpcbnRoaXMuJCA9ICQkWyQwLTFdID8gdW5pb25BbGwoWyQkWyQwLTFdXSwgJCRbJDBdKSA6IHVuaW9uQWxsKCQkWyQwXSk7XG5icmVhaztcbmNhc2UgNjc6XG50aGlzLiQgPSAkJFskMF0gPyBbJCRbJDAtMl0sICQkWyQwXV0gOiAkJFskMC0yXTtcbmJyZWFrO1xuY2FzZSA2OTpcblxuICAgICAgaWYgKCQkWyQwLTFdLmxlbmd0aClcbiAgICAgICAgdGhpcy4kID0geyB0eXBlOiAndW5pb24nLCBwYXR0ZXJuczogdW5pb25BbGwoJCRbJDAtMV0ubWFwKGRlZ3JvdXBTaW5nbGUpLCBbZGVncm91cFNpbmdsZSgkJFskMF0pXSkgfTtcbiAgICAgIGVsc2VcbiAgICAgICAgdGhpcy4kID0gJCRbJDBdO1xuICAgIFxuYnJlYWs7XG5jYXNlIDcwOlxudGhpcy4kID0gZXh0ZW5kKCQkWyQwXSwgeyB0eXBlOiAnb3B0aW9uYWwnIH0pO1xuYnJlYWs7XG5jYXNlIDcxOlxudGhpcy4kID0gZXh0ZW5kKCQkWyQwXSwgeyB0eXBlOiAnbWludXMnIH0pO1xuYnJlYWs7XG5jYXNlIDcyOlxudGhpcy4kID0gZXh0ZW5kKCQkWyQwXSwgeyB0eXBlOiAnZ3JhcGgnLCBuYW1lOiB0b1ZhcigkJFskMC0xXSkgfSk7XG5icmVhaztcbmNhc2UgNzM6XG50aGlzLiQgPSBleHRlbmQoJCRbJDBdLCB7IHR5cGU6ICdzZXJ2aWNlJywgbmFtZTogdG9WYXIoJCRbJDAtMV0pLCBzaWxlbnQ6ICEhJCRbJDAtMl0gfSk7XG5icmVhaztcbmNhc2UgNzQ6XG50aGlzLiQgPSB7IHR5cGU6ICdmaWx0ZXInLCBleHByZXNzaW9uOiAkJFskMF0gfTtcbmJyZWFrO1xuY2FzZSA3NTpcbnRoaXMuJCA9IHsgdHlwZTogJ2JpbmQnLCB2YXJpYWJsZTogdG9WYXIoJCRbJDAtMV0pLCBleHByZXNzaW9uOiAkJFskMC0zXSB9O1xuYnJlYWs7XG5jYXNlIDgwOlxudGhpcy4kID0geyB0eXBlOiAnZnVuY3Rpb25DYWxsJywgZnVuY3Rpb246ICQkWyQwLTFdLCBhcmdzOiBbXSB9O1xuYnJlYWs7XG5jYXNlIDgxOlxudGhpcy4kID0geyB0eXBlOiAnZnVuY3Rpb25DYWxsJywgZnVuY3Rpb246ICQkWyQwLTVdLCBhcmdzOiBhcHBlbmRUbygkJFskMC0yXSwgJCRbJDAtMV0pLCBkaXN0aW5jdDogISEkJFskMC0zXSB9O1xuYnJlYWs7XG5jYXNlIDgyOiBjYXNlIDk5OiBjYXNlIDExMDogY2FzZSAxOTY6IGNhc2UgMjA0OiBjYXNlIDIxNjogY2FzZSAyMTg6IGNhc2UgMjI4OiBjYXNlIDIzMjogY2FzZSAyNTI6IGNhc2UgMjU0OiBjYXNlIDI1ODogY2FzZSAyNjI6IGNhc2UgMjg1OiBjYXNlIDI5MTogY2FzZSAzMDI6IGNhc2UgMzEyOiBjYXNlIDMxODogY2FzZSAzMjQ6IGNhc2UgMzI4OiBjYXNlIDMzODogY2FzZSAzNDA6IGNhc2UgMzQ0OiBjYXNlIDM1MDogY2FzZSAzNTQ6IGNhc2UgMzYwOiBjYXNlIDM2MjogY2FzZSAzNjY6IGNhc2UgMzY4OiBjYXNlIDM3NzogY2FzZSAzODU6IGNhc2UgMzg3OiBjYXNlIDM5NzogY2FzZSA0MDE6IGNhc2UgNDAzOiBjYXNlIDQwNTpcbnRoaXMuJCA9IFtdO1xuYnJlYWs7XG5jYXNlIDgzOlxudGhpcy4kID0gYXBwZW5kVG8oJCRbJDAtMl0sICQkWyQwLTFdKTtcbmJyZWFrO1xuY2FzZSA4NTpcbnRoaXMuJCA9IHVuaW9uQWxsKCQkWyQwLTJdLCBbJCRbJDAtMV1dKTtcbmJyZWFrO1xuY2FzZSA4NjogY2FzZSA5NjpcbnRoaXMuJCA9ICQkWyQwXS5tYXAoZnVuY3Rpb24gKHQpIHsgcmV0dXJuIGV4dGVuZCh0cmlwbGUoJCRbJDAtMV0pLCB0KTsgfSk7XG5icmVhaztcbmNhc2UgODc6XG50aGlzLiQgPSBhcHBlbmRBbGxUbygkJFskMF0ubWFwKGZ1bmN0aW9uICh0KSB7IHJldHVybiBleHRlbmQodHJpcGxlKCQkWyQwLTFdLmVudGl0eSksIHQpOyB9KSwgJCRbJDAtMV0udHJpcGxlcykgLyogdGhlIHN1YmplY3QgaXMgYSBibGFuayBub2RlLCBwb3NzaWJseSB3aXRoIG1vcmUgdHJpcGxlcyAqLztcbmJyZWFrO1xuY2FzZSA4OTpcbnRoaXMuJCA9IHVuaW9uQWxsKFskJFskMC0xXV0sICQkWyQwXSk7XG5icmVhaztcbmNhc2UgOTA6XG50aGlzLiQgPSB1bmlvbkFsbCgkJFskMF0pO1xuYnJlYWs7XG5jYXNlIDkxOlxudGhpcy4kID0gb2JqZWN0TGlzdFRvVHJpcGxlcygkJFskMC0xXSwgJCRbJDBdKTtcbmJyZWFrO1xuY2FzZSA5NDogY2FzZSAxMDY6IGNhc2UgMTEzOlxudGhpcy4kID0gUkRGX1RZUEU7XG5icmVhaztcbmNhc2UgOTU6XG50aGlzLiQgPSBhcHBlbmRUbygkJFskMC0xXSwgJCRbJDBdKTtcbmJyZWFrO1xuY2FzZSA5NzpcbnRoaXMuJCA9ICEkJFskMF0gPyAkJFskMC0xXS50cmlwbGVzIDogYXBwZW5kQWxsVG8oJCRbJDBdLm1hcChmdW5jdGlvbiAodCkgeyByZXR1cm4gZXh0ZW5kKHRyaXBsZSgkJFskMC0xXS5lbnRpdHkpLCB0KTsgfSksICQkWyQwLTFdLnRyaXBsZXMpIC8qIHRoZSBzdWJqZWN0IGlzIGEgYmxhbmsgbm9kZSwgcG9zc2libHkgd2l0aCBtb3JlIHRyaXBsZXMgKi87XG5icmVhaztcbmNhc2UgOTg6XG50aGlzLiQgPSBvYmplY3RMaXN0VG9UcmlwbGVzKHRvVmFyKCQkWyQwLTNdKSwgYXBwZW5kVG8oJCRbJDAtMl0sICQkWyQwLTFdKSwgJCRbJDBdKTtcbmJyZWFrO1xuY2FzZSAxMDA6XG50aGlzLiQgPSBvYmplY3RMaXN0VG9UcmlwbGVzKHRvVmFyKCQkWyQwLTFdKSwgJCRbJDBdKTtcbmJyZWFrO1xuY2FzZSAxMDE6XG50aGlzLiQgPSAkJFskMC0xXS5sZW5ndGggPyBwYXRoKCd8JyxhcHBlbmRUbygkJFskMC0xXSwgJCRbJDBdKSkgOiAkJFskMF07XG5icmVhaztcbmNhc2UgMTAyOlxudGhpcy4kID0gJCRbJDAtMV0ubGVuZ3RoID8gcGF0aCgnLycsIGFwcGVuZFRvKCQkWyQwLTFdLCAkJFskMF0pKSA6ICQkWyQwXTtcbmJyZWFrO1xuY2FzZSAxMDM6XG50aGlzLiQgPSAkJFskMF0gPyBwYXRoKCQkWyQwXSwgWyQkWyQwLTFdXSkgOiAkJFskMC0xXTtcbmJyZWFrO1xuY2FzZSAxMDQ6XG50aGlzLiQgPSAkJFskMC0xXSA/IHBhdGgoJCRbJDAtMV0sIFskJFskMF1dKSA6ICQkWyQwXTs7XG5icmVhaztcbmNhc2UgMTA3OiBjYXNlIDExNDpcbnRoaXMuJCA9IHBhdGgoJCRbJDAtMV0sIFskJFskMF1dKTtcbmJyZWFrO1xuY2FzZSAxMTE6XG50aGlzLiQgPSBwYXRoKCd8JywgYXBwZW5kVG8oJCRbJDAtMl0sICQkWyQwLTFdKSk7XG5icmVhaztcbmNhc2UgMTE1OlxudGhpcy4kID0gcGF0aCgkJFskMC0xXSwgW1JERl9UWVBFXSk7XG5icmVhaztcbmNhc2UgMTE2OiBjYXNlIDExODpcbnRoaXMuJCA9IGNyZWF0ZUxpc3QoJCRbJDAtMV0pO1xuYnJlYWs7XG5jYXNlIDExNzogY2FzZSAxMTk6XG50aGlzLiQgPSBjcmVhdGVBbm9ueW1vdXNPYmplY3QoJCRbJDAtMV0pO1xuYnJlYWs7XG5jYXNlIDEyMDpcbnRoaXMuJCA9IHsgZW50aXR5OiAkJFskMF0sIHRyaXBsZXM6IFtdIH0gLyogZm9yIGNvbnNpc3RlbmN5IHdpdGggVHJpcGxlc05vZGUgKi87XG5icmVhaztcbmNhc2UgMTIyOlxudGhpcy4kID0geyBlbnRpdHk6ICQkWyQwXSwgdHJpcGxlczogW10gfSAvKiBmb3IgY29uc2lzdGVuY3kgd2l0aCBUcmlwbGVzTm9kZVBhdGggKi87XG5icmVhaztcbmNhc2UgMTI4OlxudGhpcy4kID0gYmxhbmsoKTtcbmJyZWFrO1xuY2FzZSAxMjk6XG50aGlzLiQgPSBSREZfTklMO1xuYnJlYWs7XG5jYXNlIDEzMDogY2FzZSAxMzI6IGNhc2UgMTM3OiBjYXNlIDE0MTpcbnRoaXMuJCA9IGNyZWF0ZU9wZXJhdGlvblRyZWUoJCRbJDAtMV0sICQkWyQwXSk7XG5icmVhaztcbmNhc2UgMTMxOlxudGhpcy4kID0gWyd8fCcsICQkWyQwXV07XG5icmVhaztcbmNhc2UgMTMzOlxudGhpcy4kID0gWycmJicsICQkWyQwXV07XG5icmVhaztcbmNhc2UgMTM1OlxudGhpcy4kID0gb3BlcmF0aW9uKCQkWyQwLTFdLCBbJCRbJDAtMl0sICQkWyQwXV0pO1xuYnJlYWs7XG5jYXNlIDEzNjpcbnRoaXMuJCA9IG9wZXJhdGlvbigkJFskMC0yXSA/ICdub3RpbicgOiAnaW4nLCBbJCRbJDAtM10sICQkWyQwXV0pO1xuYnJlYWs7XG5jYXNlIDEzODogY2FzZSAxNDI6XG50aGlzLiQgPSBbJCRbJDAtMV0sICQkWyQwXV07XG5icmVhaztcbmNhc2UgMTM5OlxudGhpcy4kID0gWycrJywgY3JlYXRlT3BlcmF0aW9uVHJlZSgkJFskMC0xXSwgJCRbJDBdKV07XG5icmVhaztcbmNhc2UgMTQwOlxudGhpcy4kID0gWyctJywgY3JlYXRlT3BlcmF0aW9uVHJlZSgkJFskMC0xXS5yZXBsYWNlKCctJywgJycpLCAkJFskMF0pXTtcbmJyZWFrO1xuY2FzZSAxNDQ6XG50aGlzLiQgPSBvcGVyYXRpb24oJCRbJDAtMV0sIFskJFskMF1dKTtcbmJyZWFrO1xuY2FzZSAxNDU6XG50aGlzLiQgPSBvcGVyYXRpb24oJ1VNSU5VUycsIFskJFskMF1dKTtcbmJyZWFrO1xuY2FzZSAxNTQ6XG50aGlzLiQgPSBvcGVyYXRpb24obG93ZXJjYXNlKCQkWyQwLTFdKSk7XG5icmVhaztcbmNhc2UgMTU1OlxudGhpcy4kID0gb3BlcmF0aW9uKGxvd2VyY2FzZSgkJFskMC0zXSksIFskJFskMC0xXV0pO1xuYnJlYWs7XG5jYXNlIDE1NjpcbnRoaXMuJCA9IG9wZXJhdGlvbihsb3dlcmNhc2UoJCRbJDAtNV0pLCBbJCRbJDAtM10sICQkWyQwLTFdXSk7XG5icmVhaztcbmNhc2UgMTU3OlxudGhpcy4kID0gb3BlcmF0aW9uKGxvd2VyY2FzZSgkJFskMC03XSksIFskJFskMC01XSwgJCRbJDAtM10sICQkWyQwLTFdXSk7XG5icmVhaztcbmNhc2UgMTU4OlxudGhpcy4kID0gb3BlcmF0aW9uKGxvd2VyY2FzZSgkJFskMC0xXSksICQkWyQwXSk7XG5icmVhaztcbmNhc2UgMTU5OlxudGhpcy4kID0gb3BlcmF0aW9uKCdib3VuZCcsIFt0b1ZhcigkJFskMC0xXSldKTtcbmJyZWFrO1xuY2FzZSAxNjA6XG50aGlzLiQgPSBvcGVyYXRpb24oJCRbJDAtMV0sIFtdKTtcbmJyZWFrO1xuY2FzZSAxNjE6XG50aGlzLiQgPSBvcGVyYXRpb24oJCRbJDAtM10sIFskJFskMC0xXV0pO1xuYnJlYWs7XG5jYXNlIDE2MjpcbnRoaXMuJCA9IG9wZXJhdGlvbigkJFskMC0yXSA/ICdub3RleGlzdHMnIDonZXhpc3RzJywgW2RlZ3JvdXBTaW5nbGUoJCRbJDBdKV0pO1xuYnJlYWs7XG5jYXNlIDE2MzogY2FzZSAxNjQ6XG50aGlzLiQgPSBleHByZXNzaW9uKCQkWyQwLTFdLCB7IHR5cGU6ICdhZ2dyZWdhdGUnLCBhZ2dyZWdhdGlvbjogbG93ZXJjYXNlKCQkWyQwLTRdKSwgZGlzdGluY3Q6ICEhJCRbJDAtMl0gfSk7XG5icmVhaztcbmNhc2UgMTY1OlxudGhpcy4kID0gZXhwcmVzc2lvbigkJFskMC0yXSwgeyB0eXBlOiAnYWdncmVnYXRlJywgYWdncmVnYXRpb246IGxvd2VyY2FzZSgkJFskMC01XSksIGRpc3RpbmN0OiAhISQkWyQwLTNdLCBzZXBhcmF0b3I6ICQkWyQwLTFdIHx8ICcgJyB9KTtcbmJyZWFrO1xuY2FzZSAxNjY6XG50aGlzLiQgPSAkJFskMF0uc3Vic3RyKDEsICQkWyQwXS5sZW5ndGggLSAyKTtcbmJyZWFrO1xuY2FzZSAxNjg6XG50aGlzLiQgPSAkJFskMC0xXSArIGxvd2VyY2FzZSgkJFskMF0pO1xuYnJlYWs7XG5jYXNlIDE2OTpcbnRoaXMuJCA9ICQkWyQwLTJdICsgJ15eJyArICQkWyQwXTtcbmJyZWFrO1xuY2FzZSAxNzA6IGNhc2UgMTg0OlxudGhpcy4kID0gY3JlYXRlTGl0ZXJhbCgkJFskMF0sIFhTRF9JTlRFR0VSKTtcbmJyZWFrO1xuY2FzZSAxNzE6IGNhc2UgMTg1OlxudGhpcy4kID0gY3JlYXRlTGl0ZXJhbCgkJFskMF0sIFhTRF9ERUNJTUFMKTtcbmJyZWFrO1xuY2FzZSAxNzI6IGNhc2UgMTg2OlxudGhpcy4kID0gY3JlYXRlTGl0ZXJhbChsb3dlcmNhc2UoJCRbJDBdKSwgWFNEX0RPVUJMRSk7XG5icmVhaztcbmNhc2UgMTc1OlxudGhpcy4kID0gWFNEX1RSVUU7XG5icmVhaztcbmNhc2UgMTc2OlxudGhpcy4kID0gWFNEX0ZBTFNFO1xuYnJlYWs7XG5jYXNlIDE3NzogY2FzZSAxNzg6XG50aGlzLiQgPSB1bmVzY2FwZVN0cmluZygkJFskMF0sIDEpO1xuYnJlYWs7XG5jYXNlIDE3OTogY2FzZSAxODA6XG50aGlzLiQgPSB1bmVzY2FwZVN0cmluZygkJFskMF0sIDMpO1xuYnJlYWs7XG5jYXNlIDE4MTpcbnRoaXMuJCA9IGNyZWF0ZUxpdGVyYWwoJCRbJDBdLnN1YnN0cigxKSwgWFNEX0lOVEVHRVIpO1xuYnJlYWs7XG5jYXNlIDE4MjpcbnRoaXMuJCA9IGNyZWF0ZUxpdGVyYWwoJCRbJDBdLnN1YnN0cigxKSwgWFNEX0RFQ0lNQUwpO1xuYnJlYWs7XG5jYXNlIDE4MzpcbnRoaXMuJCA9IGNyZWF0ZUxpdGVyYWwoJCRbJDBdLnN1YnN0cigxKS50b0xvd2VyQ2FzZSgpLCBYU0RfRE9VQkxFKTtcbmJyZWFrO1xuY2FzZSAxODc6XG50aGlzLiQgPSByZXNvbHZlSVJJKCQkWyQwXSk7XG5icmVhaztcbmNhc2UgMTg4OlxuXG4gICAgICB2YXIgbmFtZVBvcyA9ICQkWyQwXS5pbmRleE9mKCc6JyksXG4gICAgICAgICAgcHJlZml4ID0gJCRbJDBdLnN1YnN0cigwLCBuYW1lUG9zKSxcbiAgICAgICAgICBleHBhbnNpb24gPSBQYXJzZXIucHJlZml4ZXNbcHJlZml4XTtcbiAgICAgIGlmICghZXhwYW5zaW9uKSB0aHJvdyBuZXcgRXJyb3IoJ1Vua25vd24gcHJlZml4OiAnICsgcHJlZml4KTtcbiAgICAgIHRoaXMuJCA9IHJlc29sdmVJUkkoZXhwYW5zaW9uICsgJCRbJDBdLnN1YnN0cihuYW1lUG9zICsgMSkpO1xuICAgIFxuYnJlYWs7XG5jYXNlIDE4OTpcblxuICAgICAgJCRbJDBdID0gJCRbJDBdLnN1YnN0cigwLCAkJFskMF0ubGVuZ3RoIC0gMSk7XG4gICAgICBpZiAoISgkJFskMF0gaW4gUGFyc2VyLnByZWZpeGVzKSkgdGhyb3cgbmV3IEVycm9yKCdVbmtub3duIHByZWZpeDogJyArICQkWyQwXSk7XG4gICAgICB0aGlzLiQgPSByZXNvbHZlSVJJKFBhcnNlci5wcmVmaXhlc1skJFskMF1dKTtcbiAgICBcbmJyZWFrO1xuY2FzZSAxOTc6IGNhc2UgMjA1OiBjYXNlIDIxMzogY2FzZSAyMTc6IGNhc2UgMjE5OiBjYXNlIDIyNTogY2FzZSAyMjk6IGNhc2UgMjMzOiBjYXNlIDI0NzogY2FzZSAyNDk6IGNhc2UgMjUxOiBjYXNlIDI1MzogY2FzZSAyNTU6IGNhc2UgMjU3OiBjYXNlIDI1OTogY2FzZSAyNjE6IGNhc2UgMjg2OiBjYXNlIDI5MjogY2FzZSAzMDM6IGNhc2UgMzE5OiBjYXNlIDM1MTogY2FzZSAzNjM6IGNhc2UgMzgyOiBjYXNlIDM4NDogY2FzZSAzODY6IGNhc2UgMzg4OiBjYXNlIDM5ODogY2FzZSA0MDI6IGNhc2UgNDA0OiBjYXNlIDQwNjpcbiQkWyQwLTFdLnB1c2goJCRbJDBdKTtcbmJyZWFrO1xuY2FzZSAyMTI6IGNhc2UgMjI0OiBjYXNlIDI0NjogY2FzZSAyNDg6IGNhc2UgMjUwOiBjYXNlIDI1NjogY2FzZSAyNjA6IGNhc2UgMzgxOiBjYXNlIDM4MzpcbnRoaXMuJCA9IFskJFskMF1dO1xuYnJlYWs7XG5jYXNlIDI2MzpcbiQkWyQwLTNdLnB1c2goJCRbJDAtMl0pO1xuYnJlYWs7XG5jYXNlIDMxMzogY2FzZSAzMjU6IGNhc2UgMzI5OiBjYXNlIDMzOTogY2FzZSAzNDE6IGNhc2UgMzQ1OiBjYXNlIDM1NTogY2FzZSAzNjE6IGNhc2UgMzY3OiBjYXNlIDM2OTogY2FzZSAzNzg6XG4kJFskMC0yXS5wdXNoKCQkWyQwLTFdKTtcbmJyZWFrO1xufVxufSxcbnRhYmxlOiBbbygkVjAsJFYxLHszOjEsNDoyLDc6M30pLHsxOlszXX0sbygkVjIsWzIsMjYyXSx7NTo0LDg6NSwyODc6Niw5OjcsOTU6OCwxNzo5LDMzOjEwLDQyOjExLDQ3OjEyLDk2OjEzLDE4OjE0LDY6WzIsMTkwXSwyNDokVjMsMzQ6WzEsMTVdLDQzOlsxLDE2XSw0ODpbMSwxN119KSxvKFs2LDI0LDM0LDQzLDQ4LDk5LDEwOSwxMTIsMTE0LDExNSwxMjQsMTI1LDEzMCwyOTgsMjk5LDMwMCwzMDEsMzAyXSxbMiwyXSx7Mjg4OjE5LDExOjIwLDE0OjIxLDEyOlsxLDIyXSwxNTpbMSwyM119KSx7NjpbMSwyNF19LHs2OlsyLDE5Ml19LHs2OlsyLDE5M119LHs2OlsyLDIwMl0sMTA6MjUsODI6MjYsODM6JFY0fSx7NjpbMiwxOTFdfSxvKCRWNSxbMiwxOThdKSxvKCRWNSxbMiwxOTldKSxvKCRWNSxbMiwyMDBdKSxvKCRWNSxbMiwyMDFdKSx7OTc6MjgsOTk6WzEsMjldLDEwMjozMCwxMDU6MzEsMTA5OlsxLDMyXSwxMTI6WzEsMzNdLDExNDpbMSwzNF0sMTE1OlsxLDM1XSwxMTY6MzYsMTIwOjM3LDEyNDpbMiwyODddLDEyNTpbMiwyODFdLDEyOTo0MywxMzA6WzEsNDRdLDI5ODpbMSwzOF0sMjk5OlsxLDM5XSwzMDA6WzEsNDBdLDMwMTpbMSw0MV0sMzAyOlsxLDQyXX0sbygkVjYsWzIsMjA0XSx7MTk6NDV9KSxvKCRWNyxbMiwyMThdLHszNTo0NiwzNzo0NywzOTpbMSw0OF19KSx7MTM6JFY4LDE2OiRWOSwyODokVmEsNDQ6NDksNTM6NTQsMjg2OiRWYiwyOTM6WzEsNTFdLDI5NDo1MiwyOTU6NTB9LG8oJFY2LFsyLDIzMl0sezQ5OjU4fSksbygkVmMsWzIsMjEwXSx7MjU6NTksMjg5OjYwLDI5MDpbMSw2MV0sMjkxOlsxLDYyXX0pLG8oJFYwLFsyLDE5N10pLG8oJFYwLFsyLDE5NF0pLG8oJFYwLFsyLDE5NV0pLHsxMzpbMSw2M119LHsxNjpbMSw2NF19LHsxOlsyLDFdfSx7NjpbMiwzXX0sezY6WzIsMjAzXX0sezI4OlsxLDY2XSwyOTpbMSw2OF0sODQ6NjUsODY6WzEsNjddfSx7NjpbMiwyNjRdLDk4OjY5LDE4MzpbMSw3MF19LG8oJFZkLFsyLDI2Nl0sezEwMDo3MSwyOTc6WzEsNzJdfSksbygkVmUsWzIsMjcyXSx7MTAzOjczLDI5NzpbMSw3NF19KSxvKCRWZixbMiwyNzddLHsxMDY6NzUsMjk3OlsxLDc2XX0pLHsxMTA6NzcsMTExOlsyLDI3OV0sMjk3OlsxLDc4XX0sezM5OiRWZywxMTM6Nzl9LHszOTokVmcsMTEzOjgxfSx7Mzk6JFZnLDExMzo4Mn0sezExNzo4MywxMjU6JFZofSx7MTIxOjg1LDEyNDokVml9LG8oJFZqLFsyLDI3MF0pLG8oJFZqLFsyLDI3MV0pLG8oJFZrLFsyLDI3NF0pLG8oJFZrLFsyLDI3NV0pLG8oJFZrLFsyLDI3Nl0pLHsxMjQ6WzIsMjg4XSwxMjU6WzIsMjgyXX0sezEzOiRWOCwxNjokVjksNTM6ODcsMjg2OiRWYn0sezIwOjg4LDM4OiRWbCwzOTokVm0sNTA6ODksNTE6JFZuLDU0OjkwfSxvKCRWNixbMiwyMTZdLHszNjo5M30pLHszODpbMSw5NF0sNTA6OTUsNTE6JFZufSxvKCRWbyxbMiwzNDRdLHsxNzE6OTYsMTcyOjk3LDE3Mzo5OCw0MTpbMiwzNDJdfSksbygkVnAsWzIsMjI4XSx7NDU6OTl9KSxvKCRWcCxbMiwyMjZdLHs1Mzo1NCwyOTQ6MTAwLDEzOiRWOCwxNjokVjksMjg6JFZhLDI4NjokVmJ9KSxvKCRWcCxbMiwyMjddKSxvKCRWcSxbMiwyMjRdKSxvKCRWcSxbMiwyMjJdKSxvKCRWcSxbMiwyMjNdKSxvKCRWcixbMiwxODddKSxvKCRWcixbMiwxODhdKSxvKCRWcixbMiwxODldKSx7MjA6MTAxLDM4OiRWbCwzOTokVm0sNTA6MTAyLDUxOiRWbiw1NDo5MH0sezI2OjEwMywyNzoxMDYsMjg6JFZzLDI5OiRWdCwyOTI6MTA0LDI5MzpbMSwxMDVdfSxvKCRWYyxbMiwyMTFdKSxvKCRWYyxbMiwyMDhdKSxvKCRWYyxbMiwyMDldKSxvKCRWMCxbMiw0XSksezEzOlsxLDEwOV19LG8oJFZ1LFsyLDM0XSksezM5OlsxLDExMF19LHszOTpbMSwxMTFdfSx7Mjg6WzEsMTEzXSw4ODoxMTJ9LHs2OlsyLDQyXX0sbygkVjAsJFYxLHs3OjMsNDoxMTR9KSx7MTM6JFY4LDE2OiRWOSw1MzoxMTUsMjg2OiRWYn0sbygkVmQsWzIsMjY3XSksezEwNDoxMTYsMTExOlsxLDExN10sMTMzOlsxLDExOV0sMTM1OjExOCwyOTY6WzEsMTIwXSwzMDM6WzEsMTIxXX0sbygkVmUsWzIsMjczXSksbygkVmQsJFZ2LHsxMDc6MTIyLDEzNDoxMjQsMTExOiRWdywxMzM6JFZ4fSksbygkVmYsWzIsMjc4XSksezExMTpbMSwxMjZdfSx7MTExOlsyLDI4MF19LG8oJFZ5LFsyLDQ3XSksbygkVm8sJFZ6LHsxMzY6MTI3LDE0MzoxMjgsMTQ0OjEyOSw0MTokVkEsMTExOiRWQX0pLG8oJFZ5LFsyLDQ4XSksbygkVnksWzIsNDldKSxvKCRWQixbMiwyODNdLHsxMTg6MTMwLDEyMToxMzEsMTI0OiRWaX0pLHszOTokVmcsMTEzOjEzMn0sbygkVkIsWzIsMjg5XSx7MTIyOjEzMywxMTc6MTM0LDEyNTokVmh9KSx7Mzk6JFZnLDExMzoxMzV9LG8oWzEyNCwxMjVdLFsyLDU1XSksbygkVkMsJFZELHsyMToxMzYsNTY6MTM3LDYwOjEzOCw2MTokVkV9KSxvKCRWNixbMiwyMDVdKSx7Mzk6JFZGLDU1OjE0MH0sbygkVmQsWzIsMjM0XSx7NTI6MTQyLDI5NjpbMSwxNDNdfSksezM5OlsyLDIzN119LHsyMDoxNDQsMzg6JFZsLDM5OiRWbSw1MDoxNDUsNTE6JFZuLDU0OjkwfSx7Mzk6WzEsMTQ2XX0sbygkVjcsWzIsMjE5XSksezQxOlsxLDE0N119LHs0MTpbMiwzNDNdfSx7MTM6JFY4LDE2OiRWOSwyODokVkcsMjk6JFZILDUzOjE1Miw4MDokVkksODY6JFZKLDkxOjE1MywxNDU6MTQ4LDE3NToxNDksMTc3OjE1MCwyMTU6JFZLLDIxODokVkwsMjE5OiRWTSwyMzY6MTYzLDIzODoxNjQsMjY5OjE1OSwyNzI6JFZOLDI3MzokVk8sMjc0OiRWUCwyNzU6JFZRLDI3NjokVlIsMjc3OiRWUywyNzg6JFZULDI3OTokVlUsMjgwOiRWViwyODE6JFZXLDI4MjokVlgsMjgzOiRWWSwyODQ6JFZaLDI4NTokVl8sMjg2OiRWYn0sbygkViQsWzIsMjMwXSx7NTQ6OTAsNDY6MTc3LDUwOjE3OCwyMDoxNzksMzg6JFZsLDM5OiRWbSw1MTokVm59KSxvKCRWcSxbMiwyMjVdKSxvKCRWQywkVkQsezU2OjEzNyw2MDoxMzgsMjE6MTgwLDYxOiRWRX0pLG8oJFY2LFsyLDIzM10pLG8oJFY2LFsyLDhdKSxvKCRWNixbMiwyMTRdLHsyNzoxODEsMjg6JFZzLDI5OiRWdH0pLG8oJFY2LFsyLDIxNV0pLG8oJFYwMSxbMiwyMTJdKSxvKCRWMDEsWzIsOV0pLG8oJFYxMSwkVjIxLHszMDoxODIsMjIwOjE4MywyMjQ6MTg0LDIyODoxODUsMjMyOjE4NiwyNDA6MTg3LDI0NDoxODgsMjA4OiRWMzEsMjQ2OiRWNDEsMzEwOiRWNTF9KSxvKCRWMCxbMiw1XSksbygkVjYxLFsyLDI1Ml0sezg1OjE5Mn0pLG8oJFY3MSxbMiwyNTRdLHs4NzoxOTN9KSx7Mjg6WzEsMTk1XSwzMjpbMSwxOTRdfSxvKCRWODEsWzIsMjU2XSksbygkVjIsWzIsMjYzXSx7NjpbMiwyNjVdfSksbygkVnksWzIsMjY4XSx7MTAxOjE5NiwxMzE6MTk3LDEzMjpbMSwxOThdfSksbygkVnksWzIsNDRdKSx7MTM6JFY4LDE2OiRWOSw1MzoxOTksMjg2OiRWYn0sbygkVnksWzIsNjBdKSxvKCRWeSxbMiwyOTddKSxvKCRWeSxbMiwyOThdKSxvKCRWeSxbMiwyOTldKSx7MTA4OlsxLDIwMF19LG8oJFY5MSxbMiw1N10pLHsxMzokVjgsMTY6JFY5LDUzOjIwMSwyODY6JFZifSxvKCRWZCxbMiwyOTZdKSx7MTM6JFY4LDE2OiRWOSw1MzoyMDIsMjg2OiRWYn0sbygkVmExLFsyLDMwMl0sezEzNzoyMDN9KSxvKCRWYTEsWzIsMzAxXSksezEzOiRWOCwxNjokVjksMjg6JFZHLDI5OiRWSCw1MzoxNTIsODA6JFZJLDg2OiRWSiw5MToxNTMsMTQ1OjIwNCwxNzU6MTQ5LDE3NzoxNTAsMjE1OiRWSywyMTg6JFZMLDIxOTokVk0sMjM2OjE2MywyMzg6MTY0LDI2OToxNTksMjcyOiRWTiwyNzM6JFZPLDI3NDokVlAsMjc1OiRWUSwyNzY6JFZSLDI3NzokVlMsMjc4OiRWVCwyNzk6JFZVLDI4MDokVlYsMjgxOiRWVywyODI6JFZYLDI4MzokVlksMjg0OiRWWiwyODU6JFZfLDI4NjokVmJ9LG8oJFZCLFsyLDI4NV0sezExOToyMDV9KSxvKCRWQixbMiwyODRdKSxvKFszOCwxMjQsMTI3XSxbMiw1M10pLG8oJFZCLFsyLDI5MV0sezEyMzoyMDZ9KSxvKCRWQixbMiwyOTBdKSxvKFszOCwxMjUsMTI3XSxbMiw1Ml0pLG8oJFY1LFsyLDZdKSxvKCRWYjEsWzIsMjQwXSx7NTc6MjA3LDY3OjIwOCw2ODpbMSwyMDldfSksbygkVkMsWzIsMjM5XSksezYyOlsxLDIxMF19LG8oWzYsNDEsNjEsNjgsNzEsNzksODEsODNdLFsyLDE2XSksbygkVm8sJFZjMSx7MjI6MjExLDE0NzoyMTIsMTg6MjEzLDE0ODoyMTQsMTU0OjIxNSwxNTU6MjE2LDI0OiRWMywzOTokVmQxLDQxOiRWZDEsODM6JFZkMSwxMTE6JFZkMSwxNTk6JFZkMSwxNjA6JFZkMSwxNjI6JFZkMSwxNjU6JFZkMSwxNjY6JFZkMX0pLHsxMzokVjgsMTY6JFY5LDUzOjIxNywyODY6JFZifSxvKCRWZCxbMiwyMzVdKSxvKCRWQywkVkQsezU2OjEzNyw2MDoxMzgsMjE6MjE4LDYxOiRWRX0pLG8oJFY2LFsyLDIxN10pLG8oJFZvLCRWeix7MTQ0OjEyOSw0MDoyMTksMTQzOjIyMCw0MTpbMiwyMjBdfSksbygkVjYsWzIsODRdKSx7NDE6WzIsMzQ2XSwxNzQ6MjIxLDMwNDpbMSwyMjJdfSx7MTM6JFY4LDE2OiRWOSwyODokVmUxLDUzOjIyNywxNzY6MjIzLDE4MDoyMjQsMTg1OjIyNSwxODc6JFZmMSwyODY6JFZifSxvKCRWZzEsWzIsMzQ4XSx7MTgwOjIyNCwxODU6MjI1LDUzOjIyNywxNzg6MjI5LDE3OToyMzAsMTc2OjIzMSwxMzokVjgsMTY6JFY5LDI4OiRWZTEsMTg3OiRWZjEsMjg2OiRWYn0pLG8oJFZoMSxbMiwxMjRdKSxvKCRWaDEsWzIsMTI1XSksbygkVmgxLFsyLDEyNl0pLG8oJFZoMSxbMiwxMjddKSxvKCRWaDEsWzIsMTI4XSksbygkVmgxLFsyLDEyOV0pLHsxMzokVjgsMTY6JFY5LDI4OiRWRywyOTokVkgsNTM6MTUyLDgwOiRWSSw4NjokVkosOTE6MTUzLDE3NToyMzQsMTc3OjIzNSwxODk6MjMzLDIxNDoyMzIsMjE1OiRWSywyMTg6JFZMLDIxOTokVk0sMjM2OjE2MywyMzg6MTY0LDI2OToxNTksMjcyOiRWTiwyNzM6JFZPLDI3NDokVlAsMjc1OiRWUSwyNzY6JFZSLDI3NzokVlMsMjc4OiRWVCwyNzk6JFZVLDI4MDokVlYsMjgxOiRWVywyODI6JFZYLDI4MzokVlksMjg0OiRWWiwyODU6JFZfLDI4NjokVmJ9LHsxMzokVjgsMTY6JFY5LDI4OiRWZTEsNTM6MjI3LDE3NjoyMzYsMTgwOjIyNCwxODU6MjI1LDE4NzokVmYxLDI4NjokVmJ9LG8oJFZpMSxbMiwxNjddLHsyNzA6WzEsMjM3XSwyNzE6WzEsMjM4XX0pLG8oJFZpMSxbMiwxNzBdKSxvKCRWaTEsWzIsMTcxXSksbygkVmkxLFsyLDE3Ml0pLG8oJFZpMSxbMiwxNzNdKSxvKCRWaTEsWzIsMTc0XSksbygkVmkxLFsyLDE3NV0pLG8oJFZpMSxbMiwxNzZdKSxvKCRWajEsWzIsMTc3XSksbygkVmoxLFsyLDE3OF0pLG8oJFZqMSxbMiwxNzldKSxvKCRWajEsWzIsMTgwXSksbygkVmkxLFsyLDE4MV0pLG8oJFZpMSxbMiwxODJdKSxvKCRWaTEsWzIsMTgzXSksbygkVmkxLFsyLDE4NF0pLG8oJFZpMSxbMiwxODVdKSxvKCRWaTEsWzIsMTg2XSksbygkVkMsJFZELHs1NjoxMzcsNjA6MTM4LDIxOjIzOSw2MTokVkV9KSxvKCRWcCxbMiwyMjldKSxvKCRWJCxbMiwyMzFdKSxvKCRWNSxbMiwxNF0pLG8oJFYwMSxbMiwyMTNdKSx7MzE6WzEsMjQwXX0sbygkVmsxLFsyLDM4NV0sezIyMToyNDF9KSxvKCRWbDEsWzIsMzg3XSx7MjI1OjI0Mn0pLG8oJFZsMSxbMiwxMzRdLHsyMjk6MjQzLDIzMDoyNDQsMjMxOlsyLDM5NV0sMjY4OlsxLDI0NV0sMzExOlsxLDI0Nl0sMzEyOlsxLDI0N10sMzEzOlsxLDI0OF0sMzE0OlsxLDI0OV0sMzE1OlsxLDI1MF0sMzE2OlsxLDI1MV19KSxvKCRWbTEsWzIsMzk3XSx7MjMzOjI1Mn0pLG8oJFZuMSxbMiw0MDVdLHsyNDE6MjUzfSksezEzOiRWOCwxNjokVjksMjg6JFZvMSwyOTokVnAxLDUzOjI1Nyw2NToyNTYsNjY6MjU4LDc1OjI1NSw4MDokVkksOTE6MjU5LDIzNjoxNjMsMjM4OjE2NCwyNDU6MjU0LDI0NzoyNjIsMjQ4OiRWcTEsMjQ5OiRWcjEsMjUwOiRWczEsMjUyOiRWdDEsMjUzOjI2NywyNTQ6JFZ1MSwyNTU6JFZ2MSwyNTY6MjcwLDI1NzokVncxLDI1ODokVngxLDI2MTokVnkxLDI2MzokVnoxLDI2OToxNTksMjcyOiRWTiwyNzM6JFZPLDI3NDokVlAsMjc1OiRWUSwyNzY6JFZSLDI3NzokVlMsMjc4OiRWVCwyNzk6JFZVLDI4MDokVlYsMjgxOiRWVywyODI6JFZYLDI4MzokVlksMjg0OiRWWiwyODU6JFZfLDI4NjokVmIsMzE2OiRWQTEsMzE3OiRWQjEsMzE4OiRWQzEsMzE5OiRWRDEsMzIwOiRWRTEsMzIxOiRWRjF9LHsxMzokVjgsMTY6JFY5LDI4OiRWbzEsMjk6JFZwMSw1MzoyNTcsNjU6MjU2LDY2OjI1OCw3NToyNTUsODA6JFZJLDkxOjI1OSwyMzY6MTYzLDIzODoxNjQsMjQ1OjI4MCwyNDc6MjYyLDI0ODokVnExLDI0OTokVnIxLDI1MDokVnMxLDI1MjokVnQxLDI1MzoyNjcsMjU0OiRWdTEsMjU1OiRWdjEsMjU2OjI3MCwyNTc6JFZ3MSwyNTg6JFZ4MSwyNjE6JFZ5MSwyNjM6JFZ6MSwyNjk6MTU5LDI3MjokVk4sMjczOiRWTywyNzQ6JFZQLDI3NTokVlEsMjc2OiRWUiwyNzc6JFZTLDI3ODokVlQsMjc5OiRWVSwyODA6JFZWLDI4MTokVlcsMjgyOiRWWCwyODM6JFZZLDI4NDokVlosMjg1OiRWXywyODY6JFZiLDMxNjokVkExLDMxNzokVkIxLDMxODokVkMxLDMxOTokVkQxLDMyMDokVkUxLDMyMTokVkYxfSx7MTM6JFY4LDE2OiRWOSwyODokVm8xLDI5OiRWcDEsNTM6MjU3LDY1OjI1Niw2NjoyNTgsNzU6MjU1LDgwOiRWSSw5MToyNTksMjM2OjE2MywyMzg6MTY0LDI0NToyODEsMjQ3OjI2MiwyNDg6JFZxMSwyNDk6JFZyMSwyNTA6JFZzMSwyNTI6JFZ0MSwyNTM6MjY3LDI1NDokVnUxLDI1NTokVnYxLDI1NjoyNzAsMjU3OiRWdzEsMjU4OiRWeDEsMjYxOiRWeTEsMjYzOiRWejEsMjY5OjE1OSwyNzI6JFZOLDI3MzokVk8sMjc0OiRWUCwyNzU6JFZRLDI3NjokVlIsMjc3OiRWUywyNzg6JFZULDI3OTokVlUsMjgwOiRWViwyODE6JFZXLDI4MjokVlgsMjgzOiRWWSwyODQ6JFZaLDI4NTokVl8sMjg2OiRWYiwzMTY6JFZBMSwzMTc6JFZCMSwzMTg6JFZDMSwzMTk6JFZEMSwzMjA6JFZFMSwzMjE6JFZGMX0sbygkVjExLFsyLDQxMF0pLHsxMzokVjgsMTY6JFY5LDQxOlsxLDI4Ml0sNTM6Mjg0LDgwOiRWSSw5MDoyODMsOTE6Mjg1LDkyOiRWRzEsMjM2OjE2MywyMzg6MTY0LDI2OToxNTksMjcyOiRWTiwyNzM6JFZPLDI3NDokVlAsMjc1OiRWUSwyNzY6JFZSLDI3NzokVlMsMjc4OiRWVCwyNzk6JFZVLDI4MDokVlYsMjgxOiRWVywyODI6JFZYLDI4MzokVlksMjg0OiRWWiwyODU6JFZfLDI4NjokVmJ9LHs0MTpbMSwyODddLDg2OlsxLDI4OF19LHszOTpbMSwyODldfSxvKCRWODEsWzIsMjU3XSksbygkVnksWzIsNDNdKSxvKCRWeSxbMiwyNjldKSx7MTExOlsxLDI5MF19LG8oJFZ5LFsyLDU5XSksbygkVmQsJFZ2LHsxMzQ6MTI0LDEwNzoyOTEsMTExOiRWdywxMzM6JFZ4fSksbygkVjkxLFsyLDU4XSksbygkVnksWzIsNDZdKSx7NDE6WzEsMjkyXSwxMTE6WzEsMjk0XSwxMzg6MjkzfSxvKCRWYTEsWzIsMzE0XSx7MTQ2OjI5NSwzMDQ6WzEsMjk2XX0pLHszODpbMSwyOTddLDEyNjoyOTgsMTI3OiRWSDF9LHszODpbMSwzMDBdLDEyNjozMDEsMTI3OiRWSDF9LG8oJFZJMSxbMiwyNDJdLHs1ODozMDIsNzA6MzAzLDcxOlsxLDMwNF19KSxvKCRWYjEsWzIsMjQxXSksezEzOiRWOCwxNjokVjksMjk6JFZwMSw1MzozMTAsNjU6MzA4LDY2OjMwOSw2OTozMDUsNzU6MzA3LDc3OjMwNiwyNDc6MjYyLDI0ODokVnExLDI0OTokVnIxLDI1MDokVnMxLDI1MjokVnQxLDI1MzoyNjcsMjU0OiRWdTEsMjU1OiRWdjEsMjU2OjI3MCwyNTc6JFZ3MSwyNTg6JFZ4MSwyNjE6JFZ5MSwyNjM6JFZ6MSwyODY6JFZiLDMxNjokVkExLDMxNzokVkIxLDMxODokVkMxLDMxOTokVkQxLDMyMDokVkUxLDMyMTokVkYxfSx7MTM6JFY4LDE2OiRWOSwyODokVkoxLDI5OiRWSzEsNTM6MzEwLDYzOjMxMSw2NDozMTIsNjU6MzEzLDY2OjMxNCwyNDc6MjYyLDI0ODokVnExLDI0OTokVnIxLDI1MDokVnMxLDI1MjokVnQxLDI1MzoyNjcsMjU0OiRWdTEsMjU1OiRWdjEsMjU2OjI3MCwyNTc6JFZ3MSwyNTg6JFZ4MSwyNjE6JFZ5MSwyNjM6JFZ6MSwyODY6JFZiLDMxNjokVkExLDMxNzokVkIxLDMxODokVkMxLDMxOTokVkQxLDMyMDokVkUxLDMyMTokVkYxfSx7NDE6WzEsMzE3XX0sezQxOlsxLDMxOF19LHsyMDozMTksMzg6JFZsLDM5OiRWbSw1NDo5MH0sbygkVkwxLFsyLDMxOF0sezE0OTozMjB9KSxvKCRWTDEsWzIsMzE3XSksezEzOiRWOCwxNjokVjksMjg6JFZHLDI5OiRWTTEsNTM6MTUyLDgwOiRWSSw4NjokVkosOTE6MTUzLDE1NjozMjEsMTc1OjMyMiwxOTE6MzIzLDIxNTokVk4xLDIxODokVkwsMjE5OiRWTSwyMzY6MTYzLDIzODoxNjQsMjY5OjE1OSwyNzI6JFZOLDI3MzokVk8sMjc0OiRWUCwyNzU6JFZRLDI3NjokVlIsMjc3OiRWUywyNzg6JFZULDI3OTokVlUsMjgwOiRWViwyODE6JFZXLDI4MjokVlgsMjgzOiRWWSwyODQ6JFZaLDI4NTokVl8sMjg2OiRWYn0sbygkVnAsWzIsMTVdKSxvKCRWNSxbMiwxMV0pLHs0MTpbMSwzMjZdfSx7NDE6WzIsMjIxXX0sezQxOlsyLDg1XX0sbygkVm8sWzIsMzQ1XSx7NDE6WzIsMzQ3XX0pLG8oJFZnMSxbMiw4Nl0pLG8oJFZPMSxbMiwzNTBdLHsxODE6MzI3fSksbygkVm8sJFZQMSx7MTg2OjMyOCwxODg6MzI5fSksbygkVm8sWzIsOTJdKSxvKCRWbyxbMiw5M10pLG8oJFZvLFsyLDk0XSksbygkVmcxLFsyLDg3XSksbygkVmcxLFsyLDg4XSksbygkVmcxLFsyLDM0OV0pLHsxMzokVjgsMTY6JFY5LDI4OiRWRywyOTokVkgsMzI6WzEsMzMwXSw1MzoxNTIsODA6JFZJLDg2OiRWSiw5MToxNTMsMTc1OjIzNCwxNzc6MjM1LDE4OTozMzEsMjE1OiRWSywyMTg6JFZMLDIxOTokVk0sMjM2OjE2MywyMzg6MTY0LDI2OToxNTksMjcyOiRWTiwyNzM6JFZPLDI3NDokVlAsMjc1OiRWUSwyNzY6JFZSLDI3NzokVlMsMjc4OiRWVCwyNzk6JFZVLDI4MDokVlYsMjgxOiRWVywyODI6JFZYLDI4MzokVlksMjg0OiRWWiwyODU6JFZfLDI4NjokVmJ9LG8oJFZRMSxbMiwzODFdKSxvKCRWUjEsWzIsMTIwXSksbygkVlIxLFsyLDEyMV0pLHsyMTY6WzEsMzMyXX0sbygkVmkxLFsyLDE2OF0pLHsxMzokVjgsMTY6JFY5LDUzOjMzMywyODY6JFZifSxvKCRWNSxbMiwxM10pLHsyODpbMSwzMzRdfSxvKFszMSwzMiwxODMsMjUxXSxbMiwxMzBdLHsyMjI6MzM1LDIyMzpbMSwzMzZdfSksbygkVmsxLFsyLDEzMl0sezIyNjozMzcsMjI3OlsxLDMzOF19KSxvKCRWMTEsJFYyMSx7MjMyOjE4NiwyNDA6MTg3LDI0NDoxODgsMjI4OjMzOSwyMDg6JFYzMSwyNDY6JFY0MSwzMTA6JFY1MX0pLHsyMzE6WzEsMzQwXX0sbygkVlMxLFsyLDM4OV0pLG8oJFZTMSxbMiwzOTBdKSxvKCRWUzEsWzIsMzkxXSksbygkVlMxLFsyLDM5Ml0pLG8oJFZTMSxbMiwzOTNdKSxvKCRWUzEsWzIsMzk0XSksezIzMTpbMiwzOTZdfSxvKFszMSwzMiwxODMsMjIzLDIyNywyMzEsMjUxLDI2OCwzMTEsMzEyLDMxMywzMTQsMzE1LDMxNl0sWzIsMTM3XSx7MjM0OjM0MSwyMzU6MzQyLDIzNjozNDMsMjM4OjM0NCwyNDY6WzEsMzQ2XSwyODA6JFZWLDI4MTokVlcsMjgyOiRWWCwyODM6JFZZLDI4NDokVlosMjg1OiRWXywzMTA6WzEsMzQ1XX0pLG8oJFZtMSxbMiwxNDFdLHsyNDI6MzQ3LDI0MzozNDgsMjkzOiRWVDEsMzA3OiRWVTF9KSxvKCRWbjEsWzIsMTQzXSksbygkVm4xLFsyLDE0Nl0pLG8oJFZuMSxbMiwxNDddKSxvKCRWbjEsWzIsMTQ4XSx7Mjk6JFZWMSw4NjokVlcxfSksbygkVm4xLFsyLDE0OV0pLG8oJFZuMSxbMiwxNTBdKSxvKCRWbjEsWzIsMTUxXSksbygkVjExLCRWMjEsezIyMDoxODMsMjI0OjE4NCwyMjg6MTg1LDIzMjoxODYsMjQwOjE4NywyNDQ6MTg4LDMwOjM1MywyMDg6JFYzMSwyNDY6JFY0MSwzMTA6JFY1MX0pLG8oJFZYMSxbMiwxNTNdKSx7ODY6WzEsMzU0XX0sezI5OlsxLDM1NV19LHsyOTpbMSwzNTZdfSx7Mjk6WzEsMzU3XX0sezI5OiRWWTEsODY6JFZaMSwxNjk6MzU4fSx7Mjk6WzEsMzYxXX0sezI5OlsxLDM2M10sODY6WzEsMzYyXX0sezI1NzpbMSwzNjRdfSx7Mjk6WzEsMzY1XX0sezI5OlsxLDM2Nl19LHsyOTpbMSwzNjddfSxvKCRWXzEsWzIsNDExXSksbygkVl8xLFsyLDQxMl0pLG8oJFZfMSxbMiw0MTNdKSxvKCRWXzEsWzIsNDE0XSksbygkVl8xLFsyLDQxNV0pLHsyNTc6WzIsNDE3XX0sbygkVm4xLFsyLDE0NF0pLG8oJFZuMSxbMiwxNDVdKSxvKCRWdSxbMiwzNV0pLG8oJFY2MSxbMiwyNTNdKSxvKCRWJDEsWzIsMzhdKSxvKCRWJDEsWzIsMzldKSxvKCRWJDEsWzIsNDBdKSxvKCRWdSxbMiwzNl0pLG8oJFY3MSxbMiwyNTVdKSxvKCRWMDIsWzIsMjU4XSx7ODk6MzY4fSksezEzOiRWOCwxNjokVjksNTM6MzY5LDI4NjokVmJ9LG8oJFZ5LFsyLDQ1XSksbyhbNiwzOCwxMjQsMTI1LDEyNywxODNdLFsyLDYxXSksbygkVmExLFsyLDMwM10pLHsxMzokVjgsMTY6JFY5LDI4OlsxLDM3MV0sNTM6MzcyLDEzOTozNzAsMjg2OiRWYn0sbygkVmExLFsyLDYzXSksbygkVm8sWzIsMzEzXSx7NDE6JFYxMiwxMTE6JFYxMn0pLHszOTokVkYsNTU6MzczfSxvKCRWQixbMiwyODZdKSxvKCRWZCxbMiwyOTNdLHsxMjg6Mzc0LDI5NjpbMSwzNzVdfSksezM5OiRWRiw1NTozNzZ9LG8oJFZCLFsyLDI5Ml0pLG8oJFYyMixbMiwyNDRdLHs1OTozNzcsNzg6Mzc4LDc5OlsxLDM3OV0sODE6WzEsMzgwXX0pLG8oJFZJMSxbMiwyNDNdKSx7NjI6WzEsMzgxXX0sbygkVmIxLFsyLDI0XSx7MjQ3OjI2MiwyNTM6MjY3LDI1NjoyNzAsNzU6MzA3LDY1OjMwOCw2NjozMDksNTM6MzEwLDc3OjM4MiwxMzokVjgsMTY6JFY5LDI5OiRWcDEsMjQ4OiRWcTEsMjQ5OiRWcjEsMjUwOiRWczEsMjUyOiRWdDEsMjU0OiRWdTEsMjU1OiRWdjEsMjU3OiRWdzEsMjU4OiRWeDEsMjYxOiRWeTEsMjYzOiRWejEsMjg2OiRWYiwzMTY6JFZBMSwzMTc6JFZCMSwzMTg6JFZDMSwzMTk6JFZEMSwzMjA6JFZFMSwzMjE6JFZGMX0pLG8oJFYzMixbMiwyNDhdKSxvKCRWNDIsWzIsNzddKSxvKCRWNDIsWzIsNzhdKSxvKCRWNDIsWzIsNzldKSx7Mjk6JFZWMSw4NjokVlcxfSxvKCRWQyxbMiwxOF0sezI0NzoyNjIsMjUzOjI2NywyNTY6MjcwLDUzOjMxMCw2NTozMTMsNjY6MzE0LDY0OjM4MywxMzokVjgsMTY6JFY5LDI4OiRWSjEsMjk6JFZLMSwyNDg6JFZxMSwyNDk6JFZyMSwyNTA6JFZzMSwyNTI6JFZ0MSwyNTQ6JFZ1MSwyNTU6JFZ2MSwyNTc6JFZ3MSwyNTg6JFZ4MSwyNjE6JFZ5MSwyNjM6JFZ6MSwyODY6JFZiLDMxNjokVkExLDMxNzokVkIxLDMxODokVkMxLDMxOTokVkQxLDMyMDokVkUxLDMyMTokVkYxfSksbygkVjUyLFsyLDI0Nl0pLG8oJFY1MixbMiwxOV0pLG8oJFY1MixbMiwyMF0pLG8oJFYxMSwkVjIxLHsyMjA6MTgzLDIyNDoxODQsMjI4OjE4NSwyMzI6MTg2LDI0MDoxODcsMjQ0OjE4OCwzMDozODQsMjA4OiRWMzEsMjQ2OiRWNDEsMzEwOiRWNTF9KSxvKCRWNTIsWzIsMjNdKSxvKCRWNjIsWzIsNjRdKSxvKCRWNjIsWzIsNjVdKSxvKCRWQywkVkQsezU2OjEzNyw2MDoxMzgsMjE6Mzg1LDYxOiRWRX0pLHszOTpbMiwzMjhdLDQxOlsyLDY2XSw4MjozOTUsODM6JFY0LDExMTpbMSwzOTFdLDE1MDozODYsMTUxOjM4NywxNTg6Mzg4LDE1OTpbMSwzODldLDE2MDpbMSwzOTBdLDE2MjpbMSwzOTJdLDE2NTpbMSwzOTNdLDE2NjpbMSwzOTRdfSxvKCRWTDEsWzIsMzI2XSx7MTU3OjM5NiwzMDQ6WzEsMzk3XX0pLG8oJFY3MiwkVjgyLHsxOTA6Mzk4LDE5MzozOTksMTk5OjQwMCwyMDA6NDAyLDI4OiRWOTJ9KSxvKCRWYTIsWzIsMzU2XSx7MTkzOjM5OSwxOTk6NDAwLDIwMDo0MDIsMTkyOjQwMywxOTA6NDA0LDEzOiRWODIsMTY6JFY4MiwyOTokVjgyLDE4NzokVjgyLDIwODokVjgyLDIxMzokVjgyLDI4NjokVjgyLDI4OiRWOTJ9KSx7MTM6JFY4LDE2OiRWOSwyODokVkcsMjk6JFZNMSw1MzoxNTIsODA6JFZJLDg2OiRWSiw5MToxNTMsMTc1OjQwNywxOTE6NDA4LDE5NTo0MDYsMjE1OiRWTjEsMjE3OjQwNSwyMTg6JFZMLDIxOTokVk0sMjM2OjE2MywyMzg6MTY0LDI2OToxNTksMjcyOiRWTiwyNzM6JFZPLDI3NDokVlAsMjc1OiRWUSwyNzY6JFZSLDI3NzokVlMsMjc4OiRWVCwyNzk6JFZVLDI4MDokVlYsMjgxOiRWVywyODI6JFZYLDI4MzokVlksMjg0OiRWWiwyODU6JFZfLDI4NjokVmJ9LG8oJFY3MiwkVjgyLHsxOTM6Mzk5LDE5OTo0MDAsMjAwOjQwMiwxOTA6NDA5LDI4OiRWOTJ9KSxvKCRWQywkVkQsezU2OjEzNyw2MDoxMzgsMjE6NDEwLDYxOiRWRX0pLG8oWzQxLDExMSwyMTYsMzA0XSxbMiw4OV0sezE4Mjo0MTEsMTgzOlsxLDQxMl19KSxvKCRWTzEsWzIsOTFdKSx7MTM6JFY4LDE2OiRWOSwyODokVkcsMjk6JFZILDUzOjE1Miw4MDokVkksODY6JFZKLDkxOjE1MywxNzU6MjM0LDE3NzoyMzUsMTg5OjQxMywyMTU6JFZLLDIxODokVkwsMjE5OiRWTSwyMzY6MTYzLDIzODoxNjQsMjY5OjE1OSwyNzI6JFZOLDI3MzokVk8sMjc0OiRWUCwyNzU6JFZRLDI3NjokVlIsMjc3OiRWUywyNzg6JFZULDI3OTokVlUsMjgwOiRWViwyODE6JFZXLDI4MjokVlgsMjgzOiRWWSwyODQ6JFZaLDI4NTokVl8sMjg2OiRWYn0sbygkVmIyLFsyLDExNl0pLG8oJFZRMSxbMiwzODJdKSxvKCRWYjIsWzIsMTE3XSksbygkVmkxLFsyLDE2OV0pLHszMjpbMSw0MTRdfSxvKCRWazEsWzIsMzg2XSksbygkVjExLCRWMjEsezIyNDoxODQsMjI4OjE4NSwyMzI6MTg2LDI0MDoxODcsMjQ0OjE4OCwyMjA6NDE1LDIwODokVjMxLDI0NjokVjQxLDMxMDokVjUxfSksbygkVmwxLFsyLDM4OF0pLG8oJFYxMSwkVjIxLHsyMjg6MTg1LDIzMjoxODYsMjQwOjE4NywyNDQ6MTg4LDIyNDo0MTYsMjA4OiRWMzEsMjQ2OiRWNDEsMzEwOiRWNTF9KSxvKCRWbDEsWzIsMTM1XSksezI5OiRWWTEsODY6JFZaMSwxNjk6NDE3fSxvKCRWbTEsWzIsMzk4XSksbygkVjExLCRWMjEsezI0MDoxODcsMjQ0OjE4OCwyMzI6NDE4LDIwODokVjMxLDI0NjokVjQxLDMxMDokVjUxfSksbygkVm4xLFsyLDQwMV0sezIzNzo0MTl9KSxvKCRWbjEsWzIsNDAzXSx7MjM5OjQyMH0pLG8oJFZTMSxbMiwzOTldKSxvKCRWUzEsWzIsNDAwXSksbygkVm4xLFsyLDQwNl0pLG8oJFYxMSwkVjIxLHsyNDQ6MTg4LDI0MDo0MjEsMjA4OiRWMzEsMjQ2OiRWNDEsMzEwOiRWNTF9KSxvKCRWUzEsWzIsNDA3XSksbygkVlMxLFsyLDQwOF0pLG8oJFZYMSxbMiw4MF0pLG8oJFZTMSxbMiwzMzZdLHsxNjc6NDIyLDI5MDpbMSw0MjNdfSksezMyOlsxLDQyNF19LG8oJFZYMSxbMiwxNTRdKSxvKCRWMTEsJFYyMSx7MjIwOjE4MywyMjQ6MTg0LDIyODoxODUsMjMyOjE4NiwyNDA6MTg3LDI0NDoxODgsMzA6NDI1LDIwODokVjMxLDI0NjokVjQxLDMxMDokVjUxfSksbygkVjExLCRWMjEsezIyMDoxODMsMjI0OjE4NCwyMjg6MTg1LDIzMjoxODYsMjQwOjE4NywyNDQ6MTg4LDMwOjQyNiwyMDg6JFYzMSwyNDY6JFY0MSwzMTA6JFY1MX0pLG8oJFYxMSwkVjIxLHsyMjA6MTgzLDIyNDoxODQsMjI4OjE4NSwyMzI6MTg2LDI0MDoxODcsMjQ0OjE4OCwzMDo0MjcsMjA4OiRWMzEsMjQ2OiRWNDEsMzEwOiRWNTF9KSxvKCRWWDEsWzIsMTU4XSksbygkVlgxLFsyLDgyXSksbygkVlMxLFsyLDM0MF0sezE3MDo0Mjh9KSx7Mjg6WzEsNDI5XX0sbygkVlgxLFsyLDE2MF0pLG8oJFYxMSwkVjIxLHsyMjA6MTgzLDIyNDoxODQsMjI4OjE4NSwyMzI6MTg2LDI0MDoxODcsMjQ0OjE4OCwzMDo0MzAsMjA4OiRWMzEsMjQ2OiRWNDEsMzEwOiRWNTF9KSx7Mzk6JFZGLDU1OjQzMX0sbygkVmMyLFsyLDQxOF0sezI1OTo0MzIsMjkwOlsxLDQzM119KSxvKCRWUzEsWzIsNDIyXSx7MjYyOjQzNCwyOTA6WzEsNDM1XX0pLG8oJFZTMSxbMiw0MjRdLHsyNjQ6NDM2LDI5MDpbMSw0MzddfSksezI5OlsxLDQ0MF0sNDE6WzEsNDM4XSw5Mzo0Mzl9LG8oJFZ5LFsyLDU2XSksezM5OlsxLDQ0MV19LHszOTpbMiwzMDRdfSx7Mzk6WzIsMzA1XX0sbygkVnksWzIsNTBdKSx7MTM6JFY4LDE2OiRWOSw1Mzo0NDIsMjg2OiRWYn0sbygkVmQsWzIsMjk0XSksbygkVnksWzIsNTFdKSxvKCRWMjIsWzIsMTddKSxvKCRWMjIsWzIsMjQ1XSksezgwOlsxLDQ0M119LHs4MDpbMSw0NDRdfSx7MTM6JFY4LDE2OiRWOSwyODokVmQyLDI5OiRWcDEsNTM6MzEwLDY1OjMwOCw2NjozMDksNzI6NDQ1LDczOjQ0Niw3NDokVmUyLDc1OjMwNyw3NjokVmYyLDc3OjQ0OSwyNDc6MjYyLDI0ODokVnExLDI0OTokVnIxLDI1MDokVnMxLDI1MjokVnQxLDI1MzoyNjcsMjU0OiRWdTEsMjU1OiRWdjEsMjU2OjI3MCwyNTc6JFZ3MSwyNTg6JFZ4MSwyNjE6JFZ5MSwyNjM6JFZ6MSwyODY6JFZiLDMxNjokVkExLDMxNzokVkIxLDMxODokVkMxLDMxOTokVkQxLDMyMDokVkUxLDMyMTokVkYxfSxvKCRWMzIsWzIsMjQ5XSksbygkVjUyLFsyLDI0N10pLHszMTpbMSw0NTJdLDMyOlsxLDQ1MV19LHsyMzo0NTMsNDE6WzIsMjA2XSw4Mjo0NTQsODM6JFY0fSxvKCRWTDEsWzIsMzE5XSksbygkVmcyLFsyLDMyMF0sezE1Mjo0NTUsMzA0OlsxLDQ1Nl19KSx7Mzk6JFZGLDU1OjQ1N30sezM5OiRWRiw1NTo0NTh9LHszOTokVkYsNTU6NDU5fSx7MTM6JFY4LDE2OiRWOSwyODpbMSw0NjFdLDUzOjQ2MiwxNjE6NDYwLDI4NjokVmJ9LG8oJFZoMixbMiwzMzJdLHsxNjM6NDYzLDI5NzpbMSw0NjRdfSksezEzOiRWOCwxNjokVjksMjk6JFZwMSw1MzozMTAsNjU6MzA4LDY2OjMwOSw3NTozMDcsNzc6NDY1LDI0NzoyNjIsMjQ4OiRWcTEsMjQ5OiRWcjEsMjUwOiRWczEsMjUyOiRWdDEsMjUzOjI2NywyNTQ6JFZ1MSwyNTU6JFZ2MSwyNTY6MjcwLDI1NzokVncxLDI1ODokVngxLDI2MTokVnkxLDI2MzokVnoxLDI4NjokVmIsMzE2OiRWQTEsMzE3OiRWQjEsMzE4OiRWQzEsMzE5OiRWRDEsMzIwOiRWRTEsMzIxOiRWRjF9LHsyOTpbMSw0NjZdfSxvKCRWaTIsWzIsNzZdKSxvKCRWTDEsWzIsNjhdKSxvKCRWbyxbMiwzMjVdLHszOTokVmoyLDQxOiRWajIsODM6JFZqMiwxMTE6JFZqMiwxNTk6JFZqMiwxNjA6JFZqMiwxNjI6JFZqMiwxNjU6JFZqMiwxNjY6JFZqMn0pLG8oJFZhMixbMiw5Nl0pLG8oJFZvLFsyLDM2MF0sezE5NDo0Njd9KSxvKCRWbyxbMiwzNThdKSxvKCRWbyxbMiwzNTldKSxvKCRWNzIsWzIsMzY4XSx7MjAxOjQ2OCwyMDI6NDY5fSksbygkVmEyLFsyLDk3XSksbygkVmEyLFsyLDM1N10pLHsxMzokVjgsMTY6JFY5LDI4OiRWRywyOTokVk0xLDMyOlsxLDQ3MF0sNTM6MTUyLDgwOiRWSSw4NjokVkosOTE6MTUzLDE3NTo0MDcsMTkxOjQwOCwxOTU6NDcxLDIxNTokVk4xLDIxODokVkwsMjE5OiRWTSwyMzY6MTYzLDIzODoxNjQsMjY5OjE1OSwyNzI6JFZOLDI3MzokVk8sMjc0OiRWUCwyNzU6JFZRLDI3NjokVlIsMjc3OiRWUywyNzg6JFZULDI3OTokVlUsMjgwOiRWViwyODE6JFZXLDI4MjokVlgsMjgzOiRWWSwyODQ6JFZaLDI4NTokVl8sMjg2OiRWYn0sbygkVlExLFsyLDM4M10pLG8oJFZSMSxbMiwxMjJdKSxvKCRWUjEsWzIsMTIzXSksezIxNjpbMSw0NzJdfSxvKCRWNSxbMiwxMl0pLG8oJFZPMSxbMiwzNTFdKSxvKCRWTzEsWzIsMzUyXSx7MTg1OjIyNSw1MzoyMjcsMTg0OjQ3MywxODA6NDc0LDEzOiRWOCwxNjokVjksMjg6JFZlMSwxODc6JFZmMSwyODY6JFZifSksbygkVmsyLFsyLDk1XSx7MjUxOlsxLDQ3NV19KSxvKCRWMDEsWzIsMTBdKSxvKCRWazEsWzIsMTMxXSksbygkVmwxLFsyLDEzM10pLG8oJFZsMSxbMiwxMzZdKSxvKCRWbTEsWzIsMTM4XSksbygkVm0xLFsyLDEzOV0sezI0MzozNDgsMjQyOjQ3NiwyOTM6JFZUMSwzMDc6JFZVMX0pLG8oJFZtMSxbMiwxNDBdLHsyNDM6MzQ4LDI0Mjo0NzcsMjkzOiRWVDEsMzA3OiRWVTF9KSxvKCRWbjEsWzIsMTQyXSksbygkVlMxLFsyLDMzOF0sezE2ODo0Nzh9KSxvKCRWUzEsWzIsMzM3XSksbyhbNiwxMywxNiwyOCwyOSwzMSwzMiwzOSw0MSw3MSw3NCw3Niw3OSw4MCw4MSw4Myw4NiwxMTEsMTU5LDE2MCwxNjIsMTY1LDE2NiwxODMsMjE1LDIxOCwyMTksMjIzLDIyNywyMzEsMjQ2LDI0OCwyNDksMjUwLDI1MSwyNTIsMjU0LDI1NSwyNTcsMjU4LDI2MSwyNjMsMjY4LDI3MiwyNzMsMjc0LDI3NSwyNzYsMjc3LDI3OCwyNzksMjgwLDI4MSwyODIsMjgzLDI4NCwyODUsMjg2LDI5MywzMDQsMzA3LDMxMCwzMTEsMzEyLDMxMywzMTQsMzE1LDMxNiwzMTcsMzE4LDMxOSwzMjAsMzIxXSxbMiwxNTJdKSx7MzI6WzEsNDc5XX0sezI1MTpbMSw0ODBdfSx7MjUxOlsxLDQ4MV19LG8oJFYxMSwkVjIxLHsyMjA6MTgzLDIyNDoxODQsMjI4OjE4NSwyMzI6MTg2LDI0MDoxODcsMjQ0OjE4OCwzMDo0ODIsMjA4OiRWMzEsMjQ2OiRWNDEsMzEwOiRWNTF9KSx7MzI6WzEsNDgzXX0sezMyOlsxLDQ4NF19LG8oJFZYMSxbMiwxNjJdKSxvKCRWMTEsJFYyMSx7MjIwOjE4MywyMjQ6MTg0LDIyODoxODUsMjMyOjE4NiwyNDA6MTg3LDI0NDoxODgsMjYwOjQ4NSwzMDo0ODcsMjA4OiRWMzEsMjQ2OiRWNDEsMjkzOlsxLDQ4Nl0sMzEwOiRWNTF9KSxvKCRWYzIsWzIsNDE5XSksbygkVjExLCRWMjEsezIyMDoxODMsMjI0OjE4NCwyMjg6MTg1LDIzMjoxODYsMjQwOjE4NywyNDQ6MTg4LDMwOjQ4OCwyMDg6JFYzMSwyNDY6JFY0MSwzMTA6JFY1MX0pLG8oJFZTMSxbMiw0MjNdKSxvKCRWMTEsJFYyMSx7MjIwOjE4MywyMjQ6MTg0LDIyODoxODUsMjMyOjE4NiwyNDA6MTg3LDI0NDoxODgsMzA6NDg5LDIwODokVjMxLDI0NjokVjQxLDMxMDokVjUxfSksbygkVlMxLFsyLDQyNV0pLG8oJFZ1LFsyLDM3XSksbygkVjAyLFsyLDI1OV0pLHsxMzokVjgsMTY6JFY5LDUzOjI4NCw4MDokVkksOTA6NDkxLDkxOjI4NSw5MjokVkcxLDk0OjQ5MCwyMzY6MTYzLDIzODoxNjQsMjY5OjE1OSwyNzI6JFZOLDI3MzokVk8sMjc0OiRWUCwyNzU6JFZRLDI3NjokVlIsMjc3OiRWUywyNzg6JFZULDI3OTokVlUsMjgwOiRWViwyODE6JFZXLDI4MjokVlgsMjgzOiRWWSwyODQ6JFZaLDI4NTokVl8sMjg2OiRWYn0sbygkVm8sJFZ6LHsxNDQ6MTI5LDE0MDo0OTIsMTQzOjQ5Myw0MTpbMiwzMDZdfSksbygkVkIsWzIsNTRdKSxvKCRWMjIsWzIsMzBdLHs4MTpbMSw0OTRdfSksbygkVjIyLFsyLDMxXSx7Nzk6WzEsNDk1XX0pLG8oJFZJMSxbMiwyNV0sezI0NzoyNjIsMjUzOjI2NywyNTY6MjcwLDc1OjMwNyw2NTozMDgsNjY6MzA5LDUzOjMxMCw3Nzo0NDksNzM6NDk2LDEzOiRWOCwxNjokVjksMjg6JFZkMiwyOTokVnAxLDc0OiRWZTIsNzY6JFZmMiwyNDg6JFZxMSwyNDk6JFZyMSwyNTA6JFZzMSwyNTI6JFZ0MSwyNTQ6JFZ1MSwyNTU6JFZ2MSwyNTc6JFZ3MSwyNTg6JFZ4MSwyNjE6JFZ5MSwyNjM6JFZ6MSwyODY6JFZiLDMxNjokVkExLDMxNzokVkIxLDMxODokVkMxLDMxOTokVkQxLDMyMDokVkUxLDMyMTokVkYxfSksbygkVmwyLFsyLDI1MF0pLHsyOTokVnAxLDc1OjQ5N30sezI5OiRWcDEsNzU6NDk4fSxvKCRWbDIsWzIsMjhdKSxvKCRWbDIsWzIsMjldKSxvKCRWNTIsWzIsMjFdKSx7Mjg6WzEsNDk5XX0sezQxOlsyLDddfSx7NDE6WzIsMjA3XX0sbygkVm8sJFZjMSx7MTU1OjIxNiwxNTM6NTAwLDE1NDo1MDEsMzk6JFZtMiw0MTokVm0yLDgzOiRWbTIsMTExOiRWbTIsMTU5OiRWbTIsMTYwOiRWbTIsMTYyOiRWbTIsMTY1OiRWbTIsMTY2OiRWbTJ9KSxvKCRWZzIsWzIsMzIxXSksbygkVmkyLFsyLDY5XSx7MzA1OlsxLDUwMl19KSxvKCRWaTIsWzIsNzBdKSxvKCRWaTIsWzIsNzFdKSx7Mzk6JFZGLDU1OjUwM30sezM5OlsyLDMzMF19LHszOTpbMiwzMzFdfSx7MTM6JFY4LDE2OiRWOSwyODpbMSw1MDVdLDUzOjUwNiwxNjQ6NTA0LDI4NjokVmJ9LG8oJFZoMixbMiwzMzNdKSxvKCRWaTIsWzIsNzRdKSxvKCRWMTEsJFYyMSx7MjIwOjE4MywyMjQ6MTg0LDIyODoxODUsMjMyOjE4NiwyNDA6MTg3LDI0NDoxODgsMzA6NTA3LDIwODokVjMxLDI0NjokVjQxLDMxMDokVjUxfSksezEzOiRWOCwxNjokVjksMjg6JFZHLDI5OiRWTTEsNTM6MTUyLDgwOiRWSSw4NjokVkosOTE6MTUzLDE3NTo0MDcsMTkxOjQwOCwxOTU6NTA4LDIxNTokVk4xLDIxODokVkwsMjE5OiRWTSwyMzY6MTYzLDIzODoxNjQsMjY5OjE1OSwyNzI6JFZOLDI3MzokVk8sMjc0OiRWUCwyNzU6JFZRLDI3NjokVlIsMjc3OiRWUywyNzg6JFZULDI3OTokVlUsMjgwOiRWViwyODE6JFZXLDI4MjokVlgsMjgzOiRWWSwyODQ6JFZaLDI4NTokVl8sMjg2OiRWYn0sbygkVlExLFsyLDEwMV0sezMwNjpbMSw1MDldfSksbygkVm4yLFsyLDM3NV0sezIwMzo1MTAsMjA3OjUxMSwyMTM6WzEsNTEyXX0pLG8oJFZoMSxbMiwxMThdKSxvKCRWUTEsWzIsMzg0XSksbygkVmgxLFsyLDExOV0pLG8oJFZPMSxbMiw5MF0pLG8oJFZPMSxbMiwzNTNdKSxvKCRWbyxbMiwzNTVdKSxvKCRWbjEsWzIsNDAyXSksbygkVm4xLFsyLDQwNF0pLG8oJFYxMSwkVjIxLHsyMjA6MTgzLDIyNDoxODQsMjI4OjE4NSwyMzI6MTg2LDI0MDoxODcsMjQ0OjE4OCwzMDo1MTMsMjA4OiRWMzEsMjQ2OiRWNDEsMzEwOiRWNTF9KSxvKCRWWDEsWzIsMTU1XSksbygkVjExLCRWMjEsezIyMDoxODMsMjI0OjE4NCwyMjg6MTg1LDIzMjoxODYsMjQwOjE4NywyNDQ6MTg4LDMwOjUxNCwyMDg6JFYzMSwyNDY6JFY0MSwzMTA6JFY1MX0pLG8oJFYxMSwkVjIxLHsyMjA6MTgzLDIyNDoxODQsMjI4OjE4NSwyMzI6MTg2LDI0MDoxODcsMjQ0OjE4OCwzMDo1MTUsMjA4OiRWMzEsMjQ2OiRWNDEsMzEwOiRWNTF9KSx7MzI6WzEsNTE2XSwyNTE6WzEsNTE3XX0sbygkVlgxLFsyLDE1OV0pLG8oJFZYMSxbMiwxNjFdKSx7MzI6WzEsNTE4XX0sezMyOlsyLDQyMF19LHszMjpbMiw0MjFdfSx7MzI6WzEsNTE5XX0sezMyOlsyLDQyNl0sMTgzOlsxLDUyMl0sMjY1OjUyMCwyNjY6NTIxfSx7MTM6JFY4LDE2OiRWOSwzMjpbMSw1MjNdLDUzOjI4NCw4MDokVkksOTA6NTI0LDkxOjI4NSw5MjokVkcxLDIzNjoxNjMsMjM4OjE2NCwyNjk6MTU5LDI3MjokVk4sMjczOiRWTywyNzQ6JFZQLDI3NTokVlEsMjc2OiRWUiwyNzc6JFZTLDI3ODokVlQsMjc5OiRWVSwyODA6JFZWLDI4MTokVlcsMjgyOiRWWCwyODM6JFZZLDI4NDokVlosMjg1OiRWXywyODY6JFZifSxvKCRWbzIsWzIsMjYwXSksezQxOlsxLDUyNV19LHs0MTpbMiwzMDddfSx7ODA6WzEsNTI2XX0sezgwOlsxLDUyN119LG8oJFZsMixbMiwyNTFdKSxvKCRWbDIsWzIsMjZdKSxvKCRWbDIsWzIsMjddKSx7MzI6WzEsNTI4XX0sbygkVkwxLFsyLDY3XSksbygkVkwxLFsyLDMyM10pLHszOTpbMiwzMjldfSxvKCRWaTIsWzIsNzJdKSx7Mzk6JFZGLDU1OjUyOX0sezM5OlsyLDMzNF19LHszOTpbMiwzMzVdfSx7MzE6WzEsNTMwXX0sbygkVmsyLFsyLDM2Ml0sezE5Njo1MzEsMjUxOlsxLDUzMl19KSxvKCRWNzIsWzIsMzY3XSksbyhbMTMsMTYsMjgsMjksMzIsODAsODYsMjE1LDIxOCwyMTksMjcyLDI3MywyNzQsMjc1LDI3NiwyNzcsMjc4LDI3OSwyODAsMjgxLDI4MiwyODMsMjg0LDI4NSwyODYsMzA2XSxbMiwxMDJdLHszMDc6WzEsNTMzXX0pLHsxMzokVjgsMTY6JFY5LDI5OlsxLDUzOV0sNTM6NTM2LDE4NzpbMSw1MzddLDIwNDo1MzQsMjA1OjUzNSwyMDg6WzEsNTM4XSwyODY6JFZifSxvKCRWbjIsWzIsMzc2XSksezMyOlsxLDU0MF0sMjUxOlsxLDU0MV19LHszMjpbMSw1NDJdfSx7MjUxOlsxLDU0M119LG8oJFZYMSxbMiw4M10pLG8oJFZTMSxbMiwzNDFdKSxvKCRWWDEsWzIsMTYzXSksbygkVlgxLFsyLDE2NF0pLHszMjpbMSw1NDRdfSx7MzI6WzIsNDI3XX0sezI2NzpbMSw1NDVdfSxvKCRWMDIsWzIsNDFdKSxvKCRWbzIsWzIsMjYxXSksbygkVnAyLFsyLDMwOF0sezE0MTo1NDYsMzA0OlsxLDU0N119KSxvKCRWMjIsWzIsMzJdKSxvKCRWMjIsWzIsMzNdKSxvKCRWNTIsWzIsMjJdKSxvKCRWaTIsWzIsNzNdKSx7Mjg6WzEsNTQ4XX0sbyhbMzksNDEsODMsMTExLDE1OSwxNjAsMTYyLDE2NSwxNjYsMjE2LDMwNF0sWzIsOThdLHsxOTc6NTQ5LDE4MzpbMSw1NTBdfSksbygkVm8sWzIsMzYxXSksbygkVjcyLFsyLDM2OV0pLG8oJFZxMixbMiwxMDRdKSxvKCRWcTIsWzIsMzczXSx7MjA2OjU1MSwzMDg6NTUyLDI5MzpbMSw1NTRdLDMwOTpbMSw1NTNdLDMxMDpbMSw1NTVdfSksbygkVnIyLFsyLDEwNV0pLG8oJFZyMixbMiwxMDZdKSx7MTM6JFY4LDE2OiRWOSwyOTpbMSw1NTldLDUzOjU2MCw4NjpbMSw1NThdLDE4NzokVnMyLDIwOTo1NTYsMjEwOjU1NywyMTM6JFZ0MiwyODY6JFZifSxvKCRWNzIsJFY4Mix7MjAwOjQwMiwxOTk6NTYzfSksbygkVlgxLFsyLDgxXSksbygkVlMxLFsyLDMzOV0pLG8oJFZYMSxbMiwxNTZdKSxvKCRWMTEsJFYyMSx7MjIwOjE4MywyMjQ6MTg0LDIyODoxODUsMjMyOjE4NiwyNDA6MTg3LDI0NDoxODgsMzA6NTY0LDIwODokVjMxLDI0NjokVjQxLDMxMDokVjUxfSksbygkVlgxLFsyLDE2NV0pLHsyNjg6WzEsNTY1XX0sbygkVm8sJFZ6LHsxNDQ6MTI5LDE0Mjo1NjYsMTQzOjU2Nyw0MTokVnUyLDExMTokVnUyfSksbygkVnAyLFsyLDMwOV0pLHszMjpbMSw1NjhdfSxvKCRWazIsWzIsMzYzXSksbygkVmsyLFsyLDk5XSx7MjAwOjQwMiwxOTg6NTY5LDE5OTo1NzAsMTM6JFY4MiwxNjokVjgyLDI5OiRWODIsMTg3OiRWODIsMjA4OiRWODIsMjEzOiRWODIsMjg2OiRWODIsMjg6WzEsNTcxXX0pLG8oJFZxMixbMiwxMDNdKSxvKCRWcTIsWzIsMzc0XSksbygkVnEyLFsyLDM3MF0pLG8oJFZxMixbMiwzNzFdKSxvKCRWcTIsWzIsMzcyXSksbygkVnIyLFsyLDEwN10pLG8oJFZyMixbMiwxMDldKSxvKCRWcjIsWzIsMTEwXSksbygkVnYyLFsyLDM3N10sezIxMTo1NzJ9KSxvKCRWcjIsWzIsMTEyXSksbygkVnIyLFsyLDExM10pLHsxMzokVjgsMTY6JFY5LDUzOjU3MywxODc6WzEsNTc0XSwyODY6JFZifSx7MzI6WzEsNTc1XX0sezMyOlsxLDU3Nl19LHsyNjk6NTc3LDI3NjokVlIsMjc3OiRWUywyNzg6JFZULDI3OTokVlV9LG8oJFZhMSxbMiw2Ml0pLG8oJFZhMSxbMiwzMTFdKSxvKCRWaTIsWzIsNzVdKSxvKCRWbywkVlAxLHsxODg6MzI5LDE4Njo1Nzh9KSxvKCRWbyxbMiwzNjRdKSxvKCRWbyxbMiwzNjVdKSx7MTM6JFY4LDE2OiRWOSwzMjpbMiwzNzldLDUzOjU2MCwxODc6JFZzMiwyMTA6NTgwLDIxMjo1NzksMjEzOiRWdDIsMjg2OiRWYn0sbygkVnIyLFsyLDExNF0pLG8oJFZyMixbMiwxMTVdKSxvKCRWcjIsWzIsMTA4XSksbygkVlgxLFsyLDE1N10pLHszMjpbMiwxNjZdfSxvKCRWazIsWzIsMTAwXSksezMyOlsxLDU4MV19LHszMjpbMiwzODBdLDMwNjpbMSw1ODJdfSxvKCRWcjIsWzIsMTExXSksbygkVnYyLFsyLDM3OF0pXSxcbmRlZmF1bHRBY3Rpb25zOiB7NTpbMiwxOTJdLDY6WzIsMTkzXSw4OlsyLDE5MV0sMjQ6WzIsMV0sMjU6WzIsM10sMjY6WzIsMjAzXSw2OTpbMiw0Ml0sNzg6WzIsMjgwXSw5MjpbMiwyMzddLDk3OlsyLDM0M10sMjIwOlsyLDIyMV0sMjIxOlsyLDg1XSwyNTE6WzIsMzk2XSwyNzk6WzIsNDE3XSwzNzE6WzIsMzA0XSwzNzI6WzIsMzA1XSw0NTM6WzIsN10sNDU0OlsyLDIwN10sNDYxOlsyLDMzMF0sNDYyOlsyLDMzMV0sNDg2OlsyLDQyMF0sNDg3OlsyLDQyMV0sNDkzOlsyLDMwN10sNTAyOlsyLDMyOV0sNTA1OlsyLDMzNF0sNTA2OlsyLDMzNV0sNTIxOlsyLDQyN10sNTc3OlsyLDE2Nl19LFxucGFyc2VFcnJvcjogZnVuY3Rpb24gcGFyc2VFcnJvciAoc3RyLCBoYXNoKSB7XG4gICAgaWYgKGhhc2gucmVjb3ZlcmFibGUpIHtcbiAgICAgICAgdGhpcy50cmFjZShzdHIpO1xuICAgIH0gZWxzZSB7XG4gICAgICAgIHZhciBlcnJvciA9IG5ldyBFcnJvcihzdHIpO1xuICAgICAgICBlcnJvci5oYXNoID0gaGFzaDtcbiAgICAgICAgdGhyb3cgZXJyb3I7XG4gICAgfVxufSxcbnBhcnNlOiBmdW5jdGlvbiBwYXJzZShpbnB1dCkge1xuICAgIHZhciBzZWxmID0gdGhpcywgc3RhY2sgPSBbMF0sIHRzdGFjayA9IFtdLCB2c3RhY2sgPSBbbnVsbF0sIGxzdGFjayA9IFtdLCB0YWJsZSA9IHRoaXMudGFibGUsIHl5dGV4dCA9ICcnLCB5eWxpbmVubyA9IDAsIHl5bGVuZyA9IDAsIHJlY292ZXJpbmcgPSAwLCBURVJST1IgPSAyLCBFT0YgPSAxO1xuICAgIHZhciBhcmdzID0gbHN0YWNrLnNsaWNlLmNhbGwoYXJndW1lbnRzLCAxKTtcbiAgICB2YXIgbGV4ZXIgPSBPYmplY3QuY3JlYXRlKHRoaXMubGV4ZXIpO1xuICAgIHZhciBzaGFyZWRTdGF0ZSA9IHsgeXk6IHt9IH07XG4gICAgZm9yICh2YXIgayBpbiB0aGlzLnl5KSB7XG4gICAgICAgIGlmIChPYmplY3QucHJvdG90eXBlLmhhc093blByb3BlcnR5LmNhbGwodGhpcy55eSwgaykpIHtcbiAgICAgICAgICAgIHNoYXJlZFN0YXRlLnl5W2tdID0gdGhpcy55eVtrXTtcbiAgICAgICAgfVxuICAgIH1cbiAgICBsZXhlci5zZXRJbnB1dChpbnB1dCwgc2hhcmVkU3RhdGUueXkpO1xuICAgIHNoYXJlZFN0YXRlLnl5LmxleGVyID0gbGV4ZXI7XG4gICAgc2hhcmVkU3RhdGUueXkucGFyc2VyID0gdGhpcztcbiAgICBpZiAodHlwZW9mIGxleGVyLnl5bGxvYyA9PSAndW5kZWZpbmVkJykge1xuICAgICAgICBsZXhlci55eWxsb2MgPSB7fTtcbiAgICB9XG4gICAgdmFyIHl5bG9jID0gbGV4ZXIueXlsbG9jO1xuICAgIGxzdGFjay5wdXNoKHl5bG9jKTtcbiAgICB2YXIgcmFuZ2VzID0gbGV4ZXIub3B0aW9ucyAmJiBsZXhlci5vcHRpb25zLnJhbmdlcztcbiAgICBpZiAodHlwZW9mIHNoYXJlZFN0YXRlLnl5LnBhcnNlRXJyb3IgPT09ICdmdW5jdGlvbicpIHtcbiAgICAgICAgdGhpcy5wYXJzZUVycm9yID0gc2hhcmVkU3RhdGUueXkucGFyc2VFcnJvcjtcbiAgICB9IGVsc2Uge1xuICAgICAgICB0aGlzLnBhcnNlRXJyb3IgPSBPYmplY3QuZ2V0UHJvdG90eXBlT2YodGhpcykucGFyc2VFcnJvcjtcbiAgICB9XG4gICAgZnVuY3Rpb24gcG9wU3RhY2sobikge1xuICAgICAgICBzdGFjay5sZW5ndGggPSBzdGFjay5sZW5ndGggLSAyICogbjtcbiAgICAgICAgdnN0YWNrLmxlbmd0aCA9IHZzdGFjay5sZW5ndGggLSBuO1xuICAgICAgICBsc3RhY2subGVuZ3RoID0gbHN0YWNrLmxlbmd0aCAtIG47XG4gICAgfVxuICAgIF90b2tlbl9zdGFjazpcbiAgICAgICAgdmFyIGxleCA9IGZ1bmN0aW9uICgpIHtcbiAgICAgICAgICAgIHZhciB0b2tlbjtcbiAgICAgICAgICAgIHRva2VuID0gbGV4ZXIubGV4KCkgfHwgRU9GO1xuICAgICAgICAgICAgaWYgKHR5cGVvZiB0b2tlbiAhPT0gJ251bWJlcicpIHtcbiAgICAgICAgICAgICAgICB0b2tlbiA9IHNlbGYuc3ltYm9sc19bdG9rZW5dIHx8IHRva2VuO1xuICAgICAgICAgICAgfVxuICAgICAgICAgICAgcmV0dXJuIHRva2VuO1xuICAgICAgICB9O1xuICAgIHZhciBzeW1ib2wsIHByZUVycm9yU3ltYm9sLCBzdGF0ZSwgYWN0aW9uLCBhLCByLCB5eXZhbCA9IHt9LCBwLCBsZW4sIG5ld1N0YXRlLCBleHBlY3RlZDtcbiAgICB3aGlsZSAodHJ1ZSkge1xuICAgICAgICBzdGF0ZSA9IHN0YWNrW3N0YWNrLmxlbmd0aCAtIDFdO1xuICAgICAgICBpZiAodGhpcy5kZWZhdWx0QWN0aW9uc1tzdGF0ZV0pIHtcbiAgICAgICAgICAgIGFjdGlvbiA9IHRoaXMuZGVmYXVsdEFjdGlvbnNbc3RhdGVdO1xuICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgaWYgKHN5bWJvbCA9PT0gbnVsbCB8fCB0eXBlb2Ygc3ltYm9sID09ICd1bmRlZmluZWQnKSB7XG4gICAgICAgICAgICAgICAgc3ltYm9sID0gbGV4KCk7XG4gICAgICAgICAgICB9XG4gICAgICAgICAgICBhY3Rpb24gPSB0YWJsZVtzdGF0ZV0gJiYgdGFibGVbc3RhdGVdW3N5bWJvbF07XG4gICAgICAgIH1cbiAgICAgICAgICAgICAgICAgICAgaWYgKHR5cGVvZiBhY3Rpb24gPT09ICd1bmRlZmluZWQnIHx8ICFhY3Rpb24ubGVuZ3RoIHx8ICFhY3Rpb25bMF0pIHtcbiAgICAgICAgICAgICAgICB2YXIgZXJyU3RyID0gJyc7XG4gICAgICAgICAgICAgICAgZXhwZWN0ZWQgPSBbXTtcbiAgICAgICAgICAgICAgICBmb3IgKHAgaW4gdGFibGVbc3RhdGVdKSB7XG4gICAgICAgICAgICAgICAgICAgIGlmICh0aGlzLnRlcm1pbmFsc19bcF0gJiYgcCA+IFRFUlJPUikge1xuICAgICAgICAgICAgICAgICAgICAgICAgZXhwZWN0ZWQucHVzaCgnXFwnJyArIHRoaXMudGVybWluYWxzX1twXSArICdcXCcnKTtcbiAgICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICBpZiAobGV4ZXIuc2hvd1Bvc2l0aW9uKSB7XG4gICAgICAgICAgICAgICAgICAgIGVyclN0ciA9ICdQYXJzZSBlcnJvciBvbiBsaW5lICcgKyAoeXlsaW5lbm8gKyAxKSArICc6XFxuJyArIGxleGVyLnNob3dQb3NpdGlvbigpICsgJ1xcbkV4cGVjdGluZyAnICsgZXhwZWN0ZWQuam9pbignLCAnKSArICcsIGdvdCBcXCcnICsgKHRoaXMudGVybWluYWxzX1tzeW1ib2xdIHx8IHN5bWJvbCkgKyAnXFwnJztcbiAgICAgICAgICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgICAgICAgICBlcnJTdHIgPSAnUGFyc2UgZXJyb3Igb24gbGluZSAnICsgKHl5bGluZW5vICsgMSkgKyAnOiBVbmV4cGVjdGVkICcgKyAoc3ltYm9sID09IEVPRiA/ICdlbmQgb2YgaW5wdXQnIDogJ1xcJycgKyAodGhpcy50ZXJtaW5hbHNfW3N5bWJvbF0gfHwgc3ltYm9sKSArICdcXCcnKTtcbiAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgICAgdGhpcy5wYXJzZUVycm9yKGVyclN0ciwge1xuICAgICAgICAgICAgICAgICAgICB0ZXh0OiBsZXhlci5tYXRjaCxcbiAgICAgICAgICAgICAgICAgICAgdG9rZW46IHRoaXMudGVybWluYWxzX1tzeW1ib2xdIHx8IHN5bWJvbCxcbiAgICAgICAgICAgICAgICAgICAgbGluZTogbGV4ZXIueXlsaW5lbm8sXG4gICAgICAgICAgICAgICAgICAgIGxvYzogeXlsb2MsXG4gICAgICAgICAgICAgICAgICAgIGV4cGVjdGVkOiBleHBlY3RlZFxuICAgICAgICAgICAgICAgIH0pO1xuICAgICAgICAgICAgfVxuICAgICAgICBpZiAoYWN0aW9uWzBdIGluc3RhbmNlb2YgQXJyYXkgJiYgYWN0aW9uLmxlbmd0aCA+IDEpIHtcbiAgICAgICAgICAgIHRocm93IG5ldyBFcnJvcignUGFyc2UgRXJyb3I6IG11bHRpcGxlIGFjdGlvbnMgcG9zc2libGUgYXQgc3RhdGU6ICcgKyBzdGF0ZSArICcsIHRva2VuOiAnICsgc3ltYm9sKTtcbiAgICAgICAgfVxuICAgICAgICBzd2l0Y2ggKGFjdGlvblswXSkge1xuICAgICAgICBjYXNlIDE6XG4gICAgICAgICAgICBzdGFjay5wdXNoKHN5bWJvbCk7XG4gICAgICAgICAgICB2c3RhY2sucHVzaChsZXhlci55eXRleHQpO1xuICAgICAgICAgICAgbHN0YWNrLnB1c2gobGV4ZXIueXlsbG9jKTtcbiAgICAgICAgICAgIHN0YWNrLnB1c2goYWN0aW9uWzFdKTtcbiAgICAgICAgICAgIHN5bWJvbCA9IG51bGw7XG4gICAgICAgICAgICBpZiAoIXByZUVycm9yU3ltYm9sKSB7XG4gICAgICAgICAgICAgICAgeXlsZW5nID0gbGV4ZXIueXlsZW5nO1xuICAgICAgICAgICAgICAgIHl5dGV4dCA9IGxleGVyLnl5dGV4dDtcbiAgICAgICAgICAgICAgICB5eWxpbmVubyA9IGxleGVyLnl5bGluZW5vO1xuICAgICAgICAgICAgICAgIHl5bG9jID0gbGV4ZXIueXlsbG9jO1xuICAgICAgICAgICAgICAgIGlmIChyZWNvdmVyaW5nID4gMCkge1xuICAgICAgICAgICAgICAgICAgICByZWNvdmVyaW5nLS07XG4gICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgICAgICBzeW1ib2wgPSBwcmVFcnJvclN5bWJvbDtcbiAgICAgICAgICAgICAgICBwcmVFcnJvclN5bWJvbCA9IG51bGw7XG4gICAgICAgICAgICB9XG4gICAgICAgICAgICBicmVhaztcbiAgICAgICAgY2FzZSAyOlxuICAgICAgICAgICAgbGVuID0gdGhpcy5wcm9kdWN0aW9uc19bYWN0aW9uWzFdXVsxXTtcbiAgICAgICAgICAgIHl5dmFsLiQgPSB2c3RhY2tbdnN0YWNrLmxlbmd0aCAtIGxlbl07XG4gICAgICAgICAgICB5eXZhbC5fJCA9IHtcbiAgICAgICAgICAgICAgICBmaXJzdF9saW5lOiBsc3RhY2tbbHN0YWNrLmxlbmd0aCAtIChsZW4gfHwgMSldLmZpcnN0X2xpbmUsXG4gICAgICAgICAgICAgICAgbGFzdF9saW5lOiBsc3RhY2tbbHN0YWNrLmxlbmd0aCAtIDFdLmxhc3RfbGluZSxcbiAgICAgICAgICAgICAgICBmaXJzdF9jb2x1bW46IGxzdGFja1tsc3RhY2subGVuZ3RoIC0gKGxlbiB8fCAxKV0uZmlyc3RfY29sdW1uLFxuICAgICAgICAgICAgICAgIGxhc3RfY29sdW1uOiBsc3RhY2tbbHN0YWNrLmxlbmd0aCAtIDFdLmxhc3RfY29sdW1uXG4gICAgICAgICAgICB9O1xuICAgICAgICAgICAgaWYgKHJhbmdlcykge1xuICAgICAgICAgICAgICAgIHl5dmFsLl8kLnJhbmdlID0gW1xuICAgICAgICAgICAgICAgICAgICBsc3RhY2tbbHN0YWNrLmxlbmd0aCAtIChsZW4gfHwgMSldLnJhbmdlWzBdLFxuICAgICAgICAgICAgICAgICAgICBsc3RhY2tbbHN0YWNrLmxlbmd0aCAtIDFdLnJhbmdlWzFdXG4gICAgICAgICAgICAgICAgXTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgICAgIHIgPSB0aGlzLnBlcmZvcm1BY3Rpb24uYXBwbHkoeXl2YWwsIFtcbiAgICAgICAgICAgICAgICB5eXRleHQsXG4gICAgICAgICAgICAgICAgeXlsZW5nLFxuICAgICAgICAgICAgICAgIHl5bGluZW5vLFxuICAgICAgICAgICAgICAgIHNoYXJlZFN0YXRlLnl5LFxuICAgICAgICAgICAgICAgIGFjdGlvblsxXSxcbiAgICAgICAgICAgICAgICB2c3RhY2ssXG4gICAgICAgICAgICAgICAgbHN0YWNrXG4gICAgICAgICAgICBdLmNvbmNhdChhcmdzKSk7XG4gICAgICAgICAgICBpZiAodHlwZW9mIHIgIT09ICd1bmRlZmluZWQnKSB7XG4gICAgICAgICAgICAgICAgcmV0dXJuIHI7XG4gICAgICAgICAgICB9XG4gICAgICAgICAgICBpZiAobGVuKSB7XG4gICAgICAgICAgICAgICAgc3RhY2sgPSBzdGFjay5zbGljZSgwLCAtMSAqIGxlbiAqIDIpO1xuICAgICAgICAgICAgICAgIHZzdGFjayA9IHZzdGFjay5zbGljZSgwLCAtMSAqIGxlbik7XG4gICAgICAgICAgICAgICAgbHN0YWNrID0gbHN0YWNrLnNsaWNlKDAsIC0xICogbGVuKTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgICAgIHN0YWNrLnB1c2godGhpcy5wcm9kdWN0aW9uc19bYWN0aW9uWzFdXVswXSk7XG4gICAgICAgICAgICB2c3RhY2sucHVzaCh5eXZhbC4kKTtcbiAgICAgICAgICAgIGxzdGFjay5wdXNoKHl5dmFsLl8kKTtcbiAgICAgICAgICAgIG5ld1N0YXRlID0gdGFibGVbc3RhY2tbc3RhY2subGVuZ3RoIC0gMl1dW3N0YWNrW3N0YWNrLmxlbmd0aCAtIDFdXTtcbiAgICAgICAgICAgIHN0YWNrLnB1c2gobmV3U3RhdGUpO1xuICAgICAgICAgICAgYnJlYWs7XG4gICAgICAgIGNhc2UgMzpcbiAgICAgICAgICAgIHJldHVybiB0cnVlO1xuICAgICAgICB9XG4gICAgfVxuICAgIHJldHVybiB0cnVlO1xufX07XG5cbiAgLypcbiAgICBTUEFSUUwgcGFyc2VyIGluIHRoZSBKaXNvbiBwYXJzZXIgZ2VuZXJhdG9yIGZvcm1hdC5cbiAgKi9cblxuICAvLyBDb21tb24gbmFtZXNwYWNlcyBhbmQgZW50aXRpZXNcbiAgdmFyIFJERiA9ICdodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjJyxcbiAgICAgIFJERl9UWVBFICA9IFJERiArICd0eXBlJyxcbiAgICAgIFJERl9GSVJTVCA9IFJERiArICdmaXJzdCcsXG4gICAgICBSREZfUkVTVCAgPSBSREYgKyAncmVzdCcsXG4gICAgICBSREZfTklMICAgPSBSREYgKyAnbmlsJyxcbiAgICAgIFhTRCA9ICdodHRwOi8vd3d3LnczLm9yZy8yMDAxL1hNTFNjaGVtYSMnLFxuICAgICAgWFNEX0lOVEVHRVIgID0gWFNEICsgJ2ludGVnZXInLFxuICAgICAgWFNEX0RFQ0lNQUwgID0gWFNEICsgJ2RlY2ltYWwnLFxuICAgICAgWFNEX0RPVUJMRSAgID0gWFNEICsgJ2RvdWJsZScsXG4gICAgICBYU0RfQk9PTEVBTiAgPSBYU0QgKyAnYm9vbGVhbicsXG4gICAgICBYU0RfVFJVRSA9ICAnXCJ0cnVlXCJeXicgICsgWFNEX0JPT0xFQU4sXG4gICAgICBYU0RfRkFMU0UgPSAnXCJmYWxzZVwiXl4nICsgWFNEX0JPT0xFQU47XG5cbiAgdmFyIGJhc2UgPSAnJywgYmFzZVBhdGggPSAnJywgYmFzZVJvb3QgPSAnJztcblxuICAvLyBSZXR1cm5zIGEgbG93ZXJjYXNlIHZlcnNpb24gb2YgdGhlIGdpdmVuIHN0cmluZ1xuICBmdW5jdGlvbiBsb3dlcmNhc2Uoc3RyaW5nKSB7XG4gICAgcmV0dXJuIHN0cmluZy50b0xvd2VyQ2FzZSgpO1xuICB9XG5cbiAgLy8gQXBwZW5kcyB0aGUgaXRlbSB0byB0aGUgYXJyYXkgYW5kIHJldHVybnMgdGhlIGFycmF5XG4gIGZ1bmN0aW9uIGFwcGVuZFRvKGFycmF5LCBpdGVtKSB7XG4gICAgcmV0dXJuIGFycmF5LnB1c2goaXRlbSksIGFycmF5O1xuICB9XG5cbiAgLy8gQXBwZW5kcyB0aGUgaXRlbXMgdG8gdGhlIGFycmF5IGFuZCByZXR1cm5zIHRoZSBhcnJheVxuICBmdW5jdGlvbiBhcHBlbmRBbGxUbyhhcnJheSwgaXRlbXMpIHtcbiAgICByZXR1cm4gYXJyYXkucHVzaC5hcHBseShhcnJheSwgaXRlbXMpLCBhcnJheTtcbiAgfVxuXG4gIC8vIEV4dGVuZHMgYSBiYXNlIG9iamVjdCB3aXRoIHByb3BlcnRpZXMgb2Ygb3RoZXIgb2JqZWN0c1xuICBmdW5jdGlvbiBleHRlbmQoYmFzZSkge1xuICAgIGlmICghYmFzZSkgYmFzZSA9IHt9O1xuICAgIGZvciAodmFyIGkgPSAxLCBsID0gYXJndW1lbnRzLmxlbmd0aCwgYXJnOyBpIDwgbCAmJiAoYXJnID0gYXJndW1lbnRzW2ldIHx8IHt9KTsgaSsrKVxuICAgICAgZm9yICh2YXIgbmFtZSBpbiBhcmcpXG4gICAgICAgIGJhc2VbbmFtZV0gPSBhcmdbbmFtZV07XG4gICAgcmV0dXJuIGJhc2U7XG4gIH1cblxuICAvLyBDcmVhdGVzIGFuIGFycmF5IHRoYXQgY29udGFpbnMgYWxsIGl0ZW1zIG9mIHRoZSBnaXZlbiBhcnJheXNcbiAgZnVuY3Rpb24gdW5pb25BbGwoKSB7XG4gICAgdmFyIHVuaW9uID0gW107XG4gICAgZm9yICh2YXIgaSA9IDAsIGwgPSBhcmd1bWVudHMubGVuZ3RoOyBpIDwgbDsgaSsrKVxuICAgICAgdW5pb24gPSB1bmlvbi5jb25jYXQuYXBwbHkodW5pb24sIGFyZ3VtZW50c1tpXSk7XG4gICAgcmV0dXJuIHVuaW9uO1xuICB9XG5cbiAgLy8gUmVzb2x2ZXMgYW4gSVJJIGFnYWluc3QgYSBiYXNlIHBhdGhcbiAgZnVuY3Rpb24gcmVzb2x2ZUlSSShpcmkpIHtcbiAgICAvLyBTdHJpcCBvZmYgcG9zc2libGUgYW5ndWxhciBicmFja2V0c1xuICAgIGlmIChpcmlbMF0gPT09ICc8JylcbiAgICAgIGlyaSA9IGlyaS5zdWJzdHJpbmcoMSwgaXJpLmxlbmd0aCAtIDEpO1xuICAgIC8vIFJldHVybiBhYnNvbHV0ZSBJUklzIHVubW9kaWZpZWRcbiAgICBpZiAoL15bYS16XSs6Ly50ZXN0KGlyaSkpXG4gICAgICByZXR1cm4gaXJpO1xuICAgIGlmICghUGFyc2VyLmJhc2UpXG4gICAgICB0aHJvdyBuZXcgRXJyb3IoJ0Nhbm5vdCByZXNvbHZlIHJlbGF0aXZlIElSSSAnICsgaXJpICsgJyBiZWNhdXNlIG5vIGJhc2UgSVJJIHdhcyBzZXQuJyk7XG4gICAgaWYgKCFiYXNlKSB7XG4gICAgICBiYXNlID0gUGFyc2VyLmJhc2U7XG4gICAgICBiYXNlUGF0aCA9IGJhc2UucmVwbGFjZSgvW15cXC86XSokLywgJycpO1xuICAgICAgYmFzZVJvb3QgPSBiYXNlLm1hdGNoKC9eKD86W2Etel0rOlxcLyopP1teXFwvXSovKVswXTtcbiAgICB9XG4gICAgc3dpdGNoIChpcmlbMF0pIHtcbiAgICAvLyBBbiBlbXB0eSByZWxhdGl2ZSBJUkkgaW5kaWNhdGVzIHRoZSBiYXNlIElSSVxuICAgIGNhc2UgdW5kZWZpbmVkOlxuICAgICAgcmV0dXJuIGJhc2U7XG4gICAgLy8gUmVzb2x2ZSByZWxhdGl2ZSBmcmFnbWVudCBJUklzIGFnYWluc3QgdGhlIGJhc2UgSVJJXG4gICAgY2FzZSAnIyc6XG4gICAgICByZXR1cm4gYmFzZSArIGlyaTtcbiAgICAvLyBSZXNvbHZlIHJlbGF0aXZlIHF1ZXJ5IHN0cmluZyBJUklzIGJ5IHJlcGxhY2luZyB0aGUgcXVlcnkgc3RyaW5nXG4gICAgY2FzZSAnPyc6XG4gICAgICByZXR1cm4gYmFzZS5yZXBsYWNlKC8oPzpcXD8uKik/JC8sIGlyaSk7XG4gICAgLy8gUmVzb2x2ZSByb290IHJlbGF0aXZlIElSSXMgYXQgdGhlIHJvb3Qgb2YgdGhlIGJhc2UgSVJJXG4gICAgY2FzZSAnLyc6XG4gICAgICByZXR1cm4gYmFzZVJvb3QgKyBpcmk7XG4gICAgLy8gUmVzb2x2ZSBhbGwgb3RoZXIgSVJJcyBhdCB0aGUgYmFzZSBJUkkncyBwYXRoXG4gICAgZGVmYXVsdDpcbiAgICAgIHJldHVybiBiYXNlUGF0aCArIGlyaTtcbiAgICB9XG4gIH1cblxuICAvLyBJZiB0aGUgaXRlbSBpcyBhIHZhcmlhYmxlLCBlbnN1cmVzIGl0IHN0YXJ0cyB3aXRoIGEgcXVlc3Rpb24gbWFya1xuICBmdW5jdGlvbiB0b1Zhcih2YXJpYWJsZSkge1xuICAgIGlmICh2YXJpYWJsZSkge1xuICAgICAgdmFyIGZpcnN0ID0gdmFyaWFibGVbMF07XG4gICAgICBpZiAoZmlyc3QgPT09ICc/JykgcmV0dXJuIHZhcmlhYmxlO1xuICAgICAgaWYgKGZpcnN0ID09PSAnJCcpIHJldHVybiAnPycgKyB2YXJpYWJsZS5zdWJzdHIoMSk7XG4gICAgfVxuICAgIHJldHVybiB2YXJpYWJsZTtcbiAgfVxuXG4gIC8vIENyZWF0ZXMgYW4gb3BlcmF0aW9uIHdpdGggdGhlIGdpdmVuIG5hbWUgYW5kIGFyZ3VtZW50c1xuICBmdW5jdGlvbiBvcGVyYXRpb24ob3BlcmF0b3JOYW1lLCBhcmdzKSB7XG4gICAgcmV0dXJuIHsgdHlwZTogJ29wZXJhdGlvbicsIG9wZXJhdG9yOiBvcGVyYXRvck5hbWUsIGFyZ3M6IGFyZ3MgfHwgW10gfTtcbiAgfVxuXG4gIC8vIENyZWF0ZXMgYW4gZXhwcmVzc2lvbiB3aXRoIHRoZSBnaXZlbiB0eXBlIGFuZCBhdHRyaWJ1dGVzXG4gIGZ1bmN0aW9uIGV4cHJlc3Npb24oZXhwciwgYXR0cikge1xuICAgIHZhciBleHByZXNzaW9uID0geyBleHByZXNzaW9uOiBleHByIH07XG4gICAgaWYgKGF0dHIpXG4gICAgICBmb3IgKHZhciBhIGluIGF0dHIpXG4gICAgICAgIGV4cHJlc3Npb25bYV0gPSBhdHRyW2FdO1xuICAgIHJldHVybiBleHByZXNzaW9uO1xuICB9XG5cbiAgLy8gQ3JlYXRlcyBhIHBhdGggd2l0aCB0aGUgZ2l2ZW4gdHlwZSBhbmQgaXRlbXNcbiAgZnVuY3Rpb24gcGF0aCh0eXBlLCBpdGVtcykge1xuICAgIHJldHVybiB7IHR5cGU6ICdwYXRoJywgcGF0aFR5cGU6IHR5cGUsIGl0ZW1zOiBpdGVtcyB9O1xuICB9XG5cbiAgLy8gVHJhbnNmb3JtcyBhIGxpc3Qgb2Ygb3BlcmF0aW9ucyB0eXBlcyBhbmQgYXJndW1lbnRzIGludG8gYSB0cmVlIG9mIG9wZXJhdGlvbnNcbiAgZnVuY3Rpb24gY3JlYXRlT3BlcmF0aW9uVHJlZShpbml0aWFsRXhwcmVzc2lvbiwgb3BlcmF0aW9uTGlzdCkge1xuICAgIGZvciAodmFyIGkgPSAwLCBsID0gb3BlcmF0aW9uTGlzdC5sZW5ndGgsIGl0ZW07IGkgPCBsICYmIChpdGVtID0gb3BlcmF0aW9uTGlzdFtpXSk7IGkrKylcbiAgICAgIGluaXRpYWxFeHByZXNzaW9uID0gb3BlcmF0aW9uKGl0ZW1bMF0sIFtpbml0aWFsRXhwcmVzc2lvbiwgaXRlbVsxXV0pO1xuICAgIHJldHVybiBpbml0aWFsRXhwcmVzc2lvbjtcbiAgfVxuXG4gIC8vIEdyb3VwIGRhdGFzZXRzIGJ5IGRlZmF1bHQgYW5kIG5hbWVkXG4gIGZ1bmN0aW9uIGdyb3VwRGF0YXNldHMoZnJvbUNsYXVzZXMpIHtcbiAgICB2YXIgZGVmYXVsdHMgPSBbXSwgbmFtZWQgPSBbXSwgbCA9IGZyb21DbGF1c2VzLmxlbmd0aCwgZnJvbUNsYXVzZTtcbiAgICBmb3IgKHZhciBpID0gMDsgaSA8IGwgJiYgKGZyb21DbGF1c2UgPSBmcm9tQ2xhdXNlc1tpXSk7IGkrKylcbiAgICAgIChmcm9tQ2xhdXNlLm5hbWVkID8gbmFtZWQgOiBkZWZhdWx0cykucHVzaChmcm9tQ2xhdXNlLmlyaSk7XG4gICAgcmV0dXJuIGwgPyB7IGZyb206IHsgZGVmYXVsdDogZGVmYXVsdHMsIG5hbWVkOiBuYW1lZCB9IH0gOiBudWxsO1xuICB9XG5cbiAgLy8gQ29udmVydHMgdGhlIG51bWJlciB0byBhIHN0cmluZ1xuICBmdW5jdGlvbiB0b0ludChzdHJpbmcpIHtcbiAgICByZXR1cm4gcGFyc2VJbnQoc3RyaW5nLCAxMCk7XG4gIH1cblxuICAvLyBUcmFuc2Zvcm1zIGEgcG9zc2libHkgc2luZ2xlIGdyb3VwIGludG8gaXRzIHBhdHRlcm5zXG4gIGZ1bmN0aW9uIGRlZ3JvdXBTaW5nbGUoZ3JvdXApIHtcbiAgICByZXR1cm4gZ3JvdXAudHlwZSA9PT0gJ2dyb3VwJyAmJiBncm91cC5wYXR0ZXJucy5sZW5ndGggPT09IDEgPyBncm91cC5wYXR0ZXJuc1swXSA6IGdyb3VwO1xuICB9XG5cbiAgLy8gQ3JlYXRlcyBhIGxpdGVyYWwgd2l0aCB0aGUgZ2l2ZW4gdmFsdWUgYW5kIHR5cGVcbiAgZnVuY3Rpb24gY3JlYXRlTGl0ZXJhbCh2YWx1ZSwgdHlwZSkge1xuICAgIHJldHVybiAnXCInICsgdmFsdWUgKyAnXCJeXicgKyB0eXBlO1xuICB9XG5cbiAgLy8gQ3JlYXRlcyBhIHRyaXBsZSB3aXRoIHRoZSBnaXZlbiBzdWJqZWN0LCBwcmVkaWNhdGUsIGFuZCBvYmplY3RcbiAgZnVuY3Rpb24gdHJpcGxlKHN1YmplY3QsIHByZWRpY2F0ZSwgb2JqZWN0KSB7XG4gICAgdmFyIHRyaXBsZSA9IHt9O1xuICAgIGlmIChzdWJqZWN0ICAgIT0gbnVsbCkgdHJpcGxlLnN1YmplY3QgICA9IHN1YmplY3Q7XG4gICAgaWYgKHByZWRpY2F0ZSAhPSBudWxsKSB0cmlwbGUucHJlZGljYXRlID0gcHJlZGljYXRlO1xuICAgIGlmIChvYmplY3QgICAgIT0gbnVsbCkgdHJpcGxlLm9iamVjdCAgICA9IG9iamVjdDtcbiAgICByZXR1cm4gdHJpcGxlO1xuICB9XG5cbiAgLy8gQ3JlYXRlcyBhIG5ldyBibGFuayBub2RlIGlkZW50aWZpZXJcbiAgZnVuY3Rpb24gYmxhbmsoKSB7XG4gICAgcmV0dXJuICdfOmInICsgYmxhbmtJZCsrO1xuICB9O1xuICB2YXIgYmxhbmtJZCA9IDA7XG4gIFBhcnNlci5fcmVzZXRCbGFua3MgPSBmdW5jdGlvbiAoKSB7IGJsYW5rSWQgPSAwOyB9XG5cbiAgLy8gUmVndWxhciBleHByZXNzaW9uIGFuZCByZXBsYWNlbWVudCBzdHJpbmdzIHRvIGVzY2FwZSBzdHJpbmdzXG4gIHZhciBlc2NhcGVTZXF1ZW5jZSA9IC9cXFxcdShbYS1mQS1GMC05XXs0fSl8XFxcXFUoW2EtZkEtRjAtOV17OH0pfFxcXFwoLikvZyxcbiAgICAgIGVzY2FwZVJlcGxhY2VtZW50cyA9IHsgJ1xcXFwnOiAnXFxcXCcsIFwiJ1wiOiBcIidcIiwgJ1wiJzogJ1wiJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgJ3QnOiAnXFx0JywgJ2InOiAnXFxiJywgJ24nOiAnXFxuJywgJ3InOiAnXFxyJywgJ2YnOiAnXFxmJyB9LFxuICAgICAgZnJvbUNoYXJDb2RlID0gU3RyaW5nLmZyb21DaGFyQ29kZTtcblxuICAvLyBUcmFuc2xhdGVzIGVzY2FwZSBjb2RlcyBpbiB0aGUgc3RyaW5nIGludG8gdGhlaXIgdGV4dHVhbCBlcXVpdmFsZW50XG4gIGZ1bmN0aW9uIHVuZXNjYXBlU3RyaW5nKHN0cmluZywgdHJpbUxlbmd0aCkge1xuICAgIHN0cmluZyA9IHN0cmluZy5zdWJzdHJpbmcodHJpbUxlbmd0aCwgc3RyaW5nLmxlbmd0aCAtIHRyaW1MZW5ndGgpO1xuICAgIHRyeSB7XG4gICAgICBzdHJpbmcgPSBzdHJpbmcucmVwbGFjZShlc2NhcGVTZXF1ZW5jZSwgZnVuY3Rpb24gKHNlcXVlbmNlLCB1bmljb2RlNCwgdW5pY29kZTgsIGVzY2FwZWRDaGFyKSB7XG4gICAgICAgIHZhciBjaGFyQ29kZTtcbiAgICAgICAgaWYgKHVuaWNvZGU0KSB7XG4gICAgICAgICAgY2hhckNvZGUgPSBwYXJzZUludCh1bmljb2RlNCwgMTYpO1xuICAgICAgICAgIGlmIChpc05hTihjaGFyQ29kZSkpIHRocm93IG5ldyBFcnJvcigpOyAvLyBjYW4gbmV2ZXIgaGFwcGVuIChyZWdleCksIGJ1dCBoZWxwcyBwZXJmb3JtYW5jZVxuICAgICAgICAgIHJldHVybiBmcm9tQ2hhckNvZGUoY2hhckNvZGUpO1xuICAgICAgICB9XG4gICAgICAgIGVsc2UgaWYgKHVuaWNvZGU4KSB7XG4gICAgICAgICAgY2hhckNvZGUgPSBwYXJzZUludCh1bmljb2RlOCwgMTYpO1xuICAgICAgICAgIGlmIChpc05hTihjaGFyQ29kZSkpIHRocm93IG5ldyBFcnJvcigpOyAvLyBjYW4gbmV2ZXIgaGFwcGVuIChyZWdleCksIGJ1dCBoZWxwcyBwZXJmb3JtYW5jZVxuICAgICAgICAgIGlmIChjaGFyQ29kZSA8IDB4RkZGRikgcmV0dXJuIGZyb21DaGFyQ29kZShjaGFyQ29kZSk7XG4gICAgICAgICAgcmV0dXJuIGZyb21DaGFyQ29kZSgweEQ4MDAgKyAoKGNoYXJDb2RlIC09IDB4MTAwMDApID4+IDEwKSwgMHhEQzAwICsgKGNoYXJDb2RlICYgMHgzRkYpKTtcbiAgICAgICAgfVxuICAgICAgICBlbHNlIHtcbiAgICAgICAgICB2YXIgcmVwbGFjZW1lbnQgPSBlc2NhcGVSZXBsYWNlbWVudHNbZXNjYXBlZENoYXJdO1xuICAgICAgICAgIGlmICghcmVwbGFjZW1lbnQpIHRocm93IG5ldyBFcnJvcigpO1xuICAgICAgICAgIHJldHVybiByZXBsYWNlbWVudDtcbiAgICAgICAgfVxuICAgICAgfSk7XG4gICAgfVxuICAgIGNhdGNoIChlcnJvcikgeyByZXR1cm4gJyc7IH1cbiAgICByZXR1cm4gJ1wiJyArIHN0cmluZyArICdcIic7XG4gIH1cblxuICAvLyBDcmVhdGVzIGEgbGlzdCwgY29sbGVjdGluZyBpdHMgKHBvc3NpYmx5IGJsYW5rKSBpdGVtcyBhbmQgdHJpcGxlcyBhc3NvY2lhdGVkIHdpdGggdGhvc2UgaXRlbXNcbiAgZnVuY3Rpb24gY3JlYXRlTGlzdChvYmplY3RzKSB7XG4gICAgdmFyIGxpc3QgPSBibGFuaygpLCBoZWFkID0gbGlzdCwgbGlzdEl0ZW1zID0gW10sIGxpc3RUcmlwbGVzLCB0cmlwbGVzID0gW107XG4gICAgb2JqZWN0cy5mb3JFYWNoKGZ1bmN0aW9uIChvKSB7IGxpc3RJdGVtcy5wdXNoKG8uZW50aXR5KTsgYXBwZW5kQWxsVG8odHJpcGxlcywgby50cmlwbGVzKTsgfSk7XG5cbiAgICAvLyBCdWlsZCBhbiBSREYgbGlzdCBvdXQgb2YgdGhlIGl0ZW1zXG4gICAgZm9yICh2YXIgaSA9IDAsIGogPSAwLCBsID0gbGlzdEl0ZW1zLmxlbmd0aCwgbGlzdFRyaXBsZXMgPSBBcnJheShsICogMik7IGkgPCBsOylcbiAgICAgIGxpc3RUcmlwbGVzW2orK10gPSB0cmlwbGUoaGVhZCwgUkRGX0ZJUlNULCBsaXN0SXRlbXNbaV0pLFxuICAgICAgbGlzdFRyaXBsZXNbaisrXSA9IHRyaXBsZShoZWFkLCBSREZfUkVTVCwgIGhlYWQgPSArK2kgPCBsID8gYmxhbmsoKSA6IFJERl9OSUwpO1xuXG4gICAgLy8gUmV0dXJuIHRoZSBsaXN0J3MgaWRlbnRpZmllciwgaXRzIHRyaXBsZXMsIGFuZCB0aGUgdHJpcGxlcyBhc3NvY2lhdGVkIHdpdGggaXRzIGl0ZW1zXG4gICAgcmV0dXJuIHsgZW50aXR5OiBsaXN0LCB0cmlwbGVzOiBhcHBlbmRBbGxUbyhsaXN0VHJpcGxlcywgdHJpcGxlcykgfTtcbiAgfVxuXG4gIC8vIENyZWF0ZXMgYSBibGFuayBub2RlIGlkZW50aWZpZXIsIGNvbGxlY3RpbmcgdHJpcGxlcyB3aXRoIHRoYXQgYmxhbmsgbm9kZSBhcyBzdWJqZWN0XG4gIGZ1bmN0aW9uIGNyZWF0ZUFub255bW91c09iamVjdChwcm9wZXJ0eUxpc3QpIHtcbiAgICB2YXIgZW50aXR5ID0gYmxhbmsoKTtcbiAgICByZXR1cm4ge1xuICAgICAgZW50aXR5OiBlbnRpdHksXG4gICAgICB0cmlwbGVzOiBwcm9wZXJ0eUxpc3QubWFwKGZ1bmN0aW9uICh0KSB7IHJldHVybiBleHRlbmQodHJpcGxlKGVudGl0eSksIHQpOyB9KVxuICAgIH07XG4gIH1cblxuICAvLyBDb2xsZWN0cyBhbGwgKHBvc3NpYmx5IGJsYW5rKSBvYmplY3RzLCBhbmQgdHJpcGxlcyB0aGF0IGhhdmUgdGhlbSBhcyBzdWJqZWN0XG4gIGZ1bmN0aW9uIG9iamVjdExpc3RUb1RyaXBsZXMocHJlZGljYXRlLCBvYmplY3RMaXN0LCBvdGhlclRyaXBsZXMpIHtcbiAgICB2YXIgb2JqZWN0cyA9IFtdLCB0cmlwbGVzID0gW107XG4gICAgb2JqZWN0TGlzdC5mb3JFYWNoKGZ1bmN0aW9uIChsKSB7XG4gICAgICBvYmplY3RzLnB1c2godHJpcGxlKG51bGwsIHByZWRpY2F0ZSwgbC5lbnRpdHkpKTtcbiAgICAgIGFwcGVuZEFsbFRvKHRyaXBsZXMsIGwudHJpcGxlcyk7XG4gICAgfSk7XG4gICAgcmV0dXJuIHVuaW9uQWxsKG9iamVjdHMsIG90aGVyVHJpcGxlcyB8fCBbXSwgdHJpcGxlcyk7XG4gIH1cblxuICAvLyBTaW1wbGlmaWVzIGdyb3VwcyBieSBtZXJnaW5nIGFkamFjZW50IEJHUHNcbiAgZnVuY3Rpb24gbWVyZ2VBZGphY2VudEJHUHMoZ3JvdXBzKSB7XG4gICAgdmFyIG1lcmdlZCA9IFtdLCBjdXJyZW50QmdwO1xuICAgIGZvciAodmFyIGkgPSAwLCBncm91cDsgZ3JvdXAgPSBncm91cHNbaV07IGkrKykge1xuICAgICAgc3dpdGNoIChncm91cC50eXBlKSB7XG4gICAgICAgIC8vIEFkZCBhIEJHUCdzIHRyaXBsZXMgdG8gdGhlIGN1cnJlbnQgQkdQXG4gICAgICAgIGNhc2UgJ2JncCc6XG4gICAgICAgICAgaWYgKGdyb3VwLnRyaXBsZXMubGVuZ3RoKSB7XG4gICAgICAgICAgICBpZiAoIWN1cnJlbnRCZ3ApXG4gICAgICAgICAgICAgIGFwcGVuZFRvKG1lcmdlZCwgY3VycmVudEJncCA9IGdyb3VwKTtcbiAgICAgICAgICAgIGVsc2VcbiAgICAgICAgICAgICAgYXBwZW5kQWxsVG8oY3VycmVudEJncC50cmlwbGVzLCBncm91cC50cmlwbGVzKTtcbiAgICAgICAgICB9XG4gICAgICAgICAgYnJlYWs7XG4gICAgICAgIC8vIEFsbCBvdGhlciBncm91cHMgYnJlYWsgdXAgYSBCR1BcbiAgICAgICAgZGVmYXVsdDpcbiAgICAgICAgICAvLyBPbmx5IGFkZCB0aGUgZ3JvdXAgaWYgaXRzIHBhdHRlcm4gaXMgbm9uLWVtcHR5XG4gICAgICAgICAgaWYgKCFncm91cC5wYXR0ZXJucyB8fCBncm91cC5wYXR0ZXJucy5sZW5ndGggPiAwKSB7XG4gICAgICAgICAgICBhcHBlbmRUbyhtZXJnZWQsIGdyb3VwKTtcbiAgICAgICAgICAgIGN1cnJlbnRCZ3AgPSBudWxsO1xuICAgICAgICAgIH1cbiAgICAgIH1cbiAgICB9XG4gICAgcmV0dXJuIG1lcmdlZDtcbiAgfVxuLyogZ2VuZXJhdGVkIGJ5IGppc29uLWxleCAwLjMuNCAqL1xudmFyIGxleGVyID0gKGZ1bmN0aW9uKCl7XG52YXIgbGV4ZXIgPSAoe1xuXG5FT0Y6MSxcblxucGFyc2VFcnJvcjpmdW5jdGlvbiBwYXJzZUVycm9yKHN0ciwgaGFzaCkge1xuICAgICAgICBpZiAodGhpcy55eS5wYXJzZXIpIHtcbiAgICAgICAgICAgIHRoaXMueXkucGFyc2VyLnBhcnNlRXJyb3Ioc3RyLCBoYXNoKTtcbiAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgIHRocm93IG5ldyBFcnJvcihzdHIpO1xuICAgICAgICB9XG4gICAgfSxcblxuLy8gcmVzZXRzIHRoZSBsZXhlciwgc2V0cyBuZXcgaW5wdXRcbnNldElucHV0OmZ1bmN0aW9uIChpbnB1dCwgeXkpIHtcbiAgICAgICAgdGhpcy55eSA9IHl5IHx8IHRoaXMueXkgfHwge307XG4gICAgICAgIHRoaXMuX2lucHV0ID0gaW5wdXQ7XG4gICAgICAgIHRoaXMuX21vcmUgPSB0aGlzLl9iYWNrdHJhY2sgPSB0aGlzLmRvbmUgPSBmYWxzZTtcbiAgICAgICAgdGhpcy55eWxpbmVubyA9IHRoaXMueXlsZW5nID0gMDtcbiAgICAgICAgdGhpcy55eXRleHQgPSB0aGlzLm1hdGNoZWQgPSB0aGlzLm1hdGNoID0gJyc7XG4gICAgICAgIHRoaXMuY29uZGl0aW9uU3RhY2sgPSBbJ0lOSVRJQUwnXTtcbiAgICAgICAgdGhpcy55eWxsb2MgPSB7XG4gICAgICAgICAgICBmaXJzdF9saW5lOiAxLFxuICAgICAgICAgICAgZmlyc3RfY29sdW1uOiAwLFxuICAgICAgICAgICAgbGFzdF9saW5lOiAxLFxuICAgICAgICAgICAgbGFzdF9jb2x1bW46IDBcbiAgICAgICAgfTtcbiAgICAgICAgaWYgKHRoaXMub3B0aW9ucy5yYW5nZXMpIHtcbiAgICAgICAgICAgIHRoaXMueXlsbG9jLnJhbmdlID0gWzAsMF07XG4gICAgICAgIH1cbiAgICAgICAgdGhpcy5vZmZzZXQgPSAwO1xuICAgICAgICByZXR1cm4gdGhpcztcbiAgICB9LFxuXG4vLyBjb25zdW1lcyBhbmQgcmV0dXJucyBvbmUgY2hhciBmcm9tIHRoZSBpbnB1dFxuaW5wdXQ6ZnVuY3Rpb24gKCkge1xuICAgICAgICB2YXIgY2ggPSB0aGlzLl9pbnB1dFswXTtcbiAgICAgICAgdGhpcy55eXRleHQgKz0gY2g7XG4gICAgICAgIHRoaXMueXlsZW5nKys7XG4gICAgICAgIHRoaXMub2Zmc2V0Kys7XG4gICAgICAgIHRoaXMubWF0Y2ggKz0gY2g7XG4gICAgICAgIHRoaXMubWF0Y2hlZCArPSBjaDtcbiAgICAgICAgdmFyIGxpbmVzID0gY2gubWF0Y2goLyg/Olxcclxcbj98XFxuKS4qL2cpO1xuICAgICAgICBpZiAobGluZXMpIHtcbiAgICAgICAgICAgIHRoaXMueXlsaW5lbm8rKztcbiAgICAgICAgICAgIHRoaXMueXlsbG9jLmxhc3RfbGluZSsrO1xuICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgdGhpcy55eWxsb2MubGFzdF9jb2x1bW4rKztcbiAgICAgICAgfVxuICAgICAgICBpZiAodGhpcy5vcHRpb25zLnJhbmdlcykge1xuICAgICAgICAgICAgdGhpcy55eWxsb2MucmFuZ2VbMV0rKztcbiAgICAgICAgfVxuXG4gICAgICAgIHRoaXMuX2lucHV0ID0gdGhpcy5faW5wdXQuc2xpY2UoMSk7XG4gICAgICAgIHJldHVybiBjaDtcbiAgICB9LFxuXG4vLyB1bnNoaWZ0cyBvbmUgY2hhciAob3IgYSBzdHJpbmcpIGludG8gdGhlIGlucHV0XG51bnB1dDpmdW5jdGlvbiAoY2gpIHtcbiAgICAgICAgdmFyIGxlbiA9IGNoLmxlbmd0aDtcbiAgICAgICAgdmFyIGxpbmVzID0gY2guc3BsaXQoLyg/Olxcclxcbj98XFxuKS9nKTtcblxuICAgICAgICB0aGlzLl9pbnB1dCA9IGNoICsgdGhpcy5faW5wdXQ7XG4gICAgICAgIHRoaXMueXl0ZXh0ID0gdGhpcy55eXRleHQuc3Vic3RyKDAsIHRoaXMueXl0ZXh0Lmxlbmd0aCAtIGxlbik7XG4gICAgICAgIC8vdGhpcy55eWxlbmcgLT0gbGVuO1xuICAgICAgICB0aGlzLm9mZnNldCAtPSBsZW47XG4gICAgICAgIHZhciBvbGRMaW5lcyA9IHRoaXMubWF0Y2guc3BsaXQoLyg/Olxcclxcbj98XFxuKS9nKTtcbiAgICAgICAgdGhpcy5tYXRjaCA9IHRoaXMubWF0Y2guc3Vic3RyKDAsIHRoaXMubWF0Y2gubGVuZ3RoIC0gMSk7XG4gICAgICAgIHRoaXMubWF0Y2hlZCA9IHRoaXMubWF0Y2hlZC5zdWJzdHIoMCwgdGhpcy5tYXRjaGVkLmxlbmd0aCAtIDEpO1xuXG4gICAgICAgIGlmIChsaW5lcy5sZW5ndGggLSAxKSB7XG4gICAgICAgICAgICB0aGlzLnl5bGluZW5vIC09IGxpbmVzLmxlbmd0aCAtIDE7XG4gICAgICAgIH1cbiAgICAgICAgdmFyIHIgPSB0aGlzLnl5bGxvYy5yYW5nZTtcblxuICAgICAgICB0aGlzLnl5bGxvYyA9IHtcbiAgICAgICAgICAgIGZpcnN0X2xpbmU6IHRoaXMueXlsbG9jLmZpcnN0X2xpbmUsXG4gICAgICAgICAgICBsYXN0X2xpbmU6IHRoaXMueXlsaW5lbm8gKyAxLFxuICAgICAgICAgICAgZmlyc3RfY29sdW1uOiB0aGlzLnl5bGxvYy5maXJzdF9jb2x1bW4sXG4gICAgICAgICAgICBsYXN0X2NvbHVtbjogbGluZXMgP1xuICAgICAgICAgICAgICAgIChsaW5lcy5sZW5ndGggPT09IG9sZExpbmVzLmxlbmd0aCA/IHRoaXMueXlsbG9jLmZpcnN0X2NvbHVtbiA6IDApXG4gICAgICAgICAgICAgICAgICsgb2xkTGluZXNbb2xkTGluZXMubGVuZ3RoIC0gbGluZXMubGVuZ3RoXS5sZW5ndGggLSBsaW5lc1swXS5sZW5ndGggOlxuICAgICAgICAgICAgICB0aGlzLnl5bGxvYy5maXJzdF9jb2x1bW4gLSBsZW5cbiAgICAgICAgfTtcblxuICAgICAgICBpZiAodGhpcy5vcHRpb25zLnJhbmdlcykge1xuICAgICAgICAgICAgdGhpcy55eWxsb2MucmFuZ2UgPSBbclswXSwgclswXSArIHRoaXMueXlsZW5nIC0gbGVuXTtcbiAgICAgICAgfVxuICAgICAgICB0aGlzLnl5bGVuZyA9IHRoaXMueXl0ZXh0Lmxlbmd0aDtcbiAgICAgICAgcmV0dXJuIHRoaXM7XG4gICAgfSxcblxuLy8gV2hlbiBjYWxsZWQgZnJvbSBhY3Rpb24sIGNhY2hlcyBtYXRjaGVkIHRleHQgYW5kIGFwcGVuZHMgaXQgb24gbmV4dCBhY3Rpb25cbm1vcmU6ZnVuY3Rpb24gKCkge1xuICAgICAgICB0aGlzLl9tb3JlID0gdHJ1ZTtcbiAgICAgICAgcmV0dXJuIHRoaXM7XG4gICAgfSxcblxuLy8gV2hlbiBjYWxsZWQgZnJvbSBhY3Rpb24sIHNpZ25hbHMgdGhlIGxleGVyIHRoYXQgdGhpcyBydWxlIGZhaWxzIHRvIG1hdGNoIHRoZSBpbnB1dCwgc28gdGhlIG5leHQgbWF0Y2hpbmcgcnVsZSAocmVnZXgpIHNob3VsZCBiZSB0ZXN0ZWQgaW5zdGVhZC5cbnJlamVjdDpmdW5jdGlvbiAoKSB7XG4gICAgICAgIGlmICh0aGlzLm9wdGlvbnMuYmFja3RyYWNrX2xleGVyKSB7XG4gICAgICAgICAgICB0aGlzLl9iYWNrdHJhY2sgPSB0cnVlO1xuICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgcmV0dXJuIHRoaXMucGFyc2VFcnJvcignTGV4aWNhbCBlcnJvciBvbiBsaW5lICcgKyAodGhpcy55eWxpbmVubyArIDEpICsgJy4gWW91IGNhbiBvbmx5IGludm9rZSByZWplY3QoKSBpbiB0aGUgbGV4ZXIgd2hlbiB0aGUgbGV4ZXIgaXMgb2YgdGhlIGJhY2t0cmFja2luZyBwZXJzdWFzaW9uIChvcHRpb25zLmJhY2t0cmFja19sZXhlciA9IHRydWUpLlxcbicgKyB0aGlzLnNob3dQb3NpdGlvbigpLCB7XG4gICAgICAgICAgICAgICAgdGV4dDogXCJcIixcbiAgICAgICAgICAgICAgICB0b2tlbjogbnVsbCxcbiAgICAgICAgICAgICAgICBsaW5lOiB0aGlzLnl5bGluZW5vXG4gICAgICAgICAgICB9KTtcblxuICAgICAgICB9XG4gICAgICAgIHJldHVybiB0aGlzO1xuICAgIH0sXG5cbi8vIHJldGFpbiBmaXJzdCBuIGNoYXJhY3RlcnMgb2YgdGhlIG1hdGNoXG5sZXNzOmZ1bmN0aW9uIChuKSB7XG4gICAgICAgIHRoaXMudW5wdXQodGhpcy5tYXRjaC5zbGljZShuKSk7XG4gICAgfSxcblxuLy8gZGlzcGxheXMgYWxyZWFkeSBtYXRjaGVkIGlucHV0LCBpLmUuIGZvciBlcnJvciBtZXNzYWdlc1xucGFzdElucHV0OmZ1bmN0aW9uICgpIHtcbiAgICAgICAgdmFyIHBhc3QgPSB0aGlzLm1hdGNoZWQuc3Vic3RyKDAsIHRoaXMubWF0Y2hlZC5sZW5ndGggLSB0aGlzLm1hdGNoLmxlbmd0aCk7XG4gICAgICAgIHJldHVybiAocGFzdC5sZW5ndGggPiAyMCA/ICcuLi4nOicnKSArIHBhc3Quc3Vic3RyKC0yMCkucmVwbGFjZSgvXFxuL2csIFwiXCIpO1xuICAgIH0sXG5cbi8vIGRpc3BsYXlzIHVwY29taW5nIGlucHV0LCBpLmUuIGZvciBlcnJvciBtZXNzYWdlc1xudXBjb21pbmdJbnB1dDpmdW5jdGlvbiAoKSB7XG4gICAgICAgIHZhciBuZXh0ID0gdGhpcy5tYXRjaDtcbiAgICAgICAgaWYgKG5leHQubGVuZ3RoIDwgMjApIHtcbiAgICAgICAgICAgIG5leHQgKz0gdGhpcy5faW5wdXQuc3Vic3RyKDAsIDIwLW5leHQubGVuZ3RoKTtcbiAgICAgICAgfVxuICAgICAgICByZXR1cm4gKG5leHQuc3Vic3RyKDAsMjApICsgKG5leHQubGVuZ3RoID4gMjAgPyAnLi4uJyA6ICcnKSkucmVwbGFjZSgvXFxuL2csIFwiXCIpO1xuICAgIH0sXG5cbi8vIGRpc3BsYXlzIHRoZSBjaGFyYWN0ZXIgcG9zaXRpb24gd2hlcmUgdGhlIGxleGluZyBlcnJvciBvY2N1cnJlZCwgaS5lLiBmb3IgZXJyb3IgbWVzc2FnZXNcbnNob3dQb3NpdGlvbjpmdW5jdGlvbiAoKSB7XG4gICAgICAgIHZhciBwcmUgPSB0aGlzLnBhc3RJbnB1dCgpO1xuICAgICAgICB2YXIgYyA9IG5ldyBBcnJheShwcmUubGVuZ3RoICsgMSkuam9pbihcIi1cIik7XG4gICAgICAgIHJldHVybiBwcmUgKyB0aGlzLnVwY29taW5nSW5wdXQoKSArIFwiXFxuXCIgKyBjICsgXCJeXCI7XG4gICAgfSxcblxuLy8gdGVzdCB0aGUgbGV4ZWQgdG9rZW46IHJldHVybiBGQUxTRSB3aGVuIG5vdCBhIG1hdGNoLCBvdGhlcndpc2UgcmV0dXJuIHRva2VuXG50ZXN0X21hdGNoOmZ1bmN0aW9uKG1hdGNoLCBpbmRleGVkX3J1bGUpIHtcbiAgICAgICAgdmFyIHRva2VuLFxuICAgICAgICAgICAgbGluZXMsXG4gICAgICAgICAgICBiYWNrdXA7XG5cbiAgICAgICAgaWYgKHRoaXMub3B0aW9ucy5iYWNrdHJhY2tfbGV4ZXIpIHtcbiAgICAgICAgICAgIC8vIHNhdmUgY29udGV4dFxuICAgICAgICAgICAgYmFja3VwID0ge1xuICAgICAgICAgICAgICAgIHl5bGluZW5vOiB0aGlzLnl5bGluZW5vLFxuICAgICAgICAgICAgICAgIHl5bGxvYzoge1xuICAgICAgICAgICAgICAgICAgICBmaXJzdF9saW5lOiB0aGlzLnl5bGxvYy5maXJzdF9saW5lLFxuICAgICAgICAgICAgICAgICAgICBsYXN0X2xpbmU6IHRoaXMubGFzdF9saW5lLFxuICAgICAgICAgICAgICAgICAgICBmaXJzdF9jb2x1bW46IHRoaXMueXlsbG9jLmZpcnN0X2NvbHVtbixcbiAgICAgICAgICAgICAgICAgICAgbGFzdF9jb2x1bW46IHRoaXMueXlsbG9jLmxhc3RfY29sdW1uXG4gICAgICAgICAgICAgICAgfSxcbiAgICAgICAgICAgICAgICB5eXRleHQ6IHRoaXMueXl0ZXh0LFxuICAgICAgICAgICAgICAgIG1hdGNoOiB0aGlzLm1hdGNoLFxuICAgICAgICAgICAgICAgIG1hdGNoZXM6IHRoaXMubWF0Y2hlcyxcbiAgICAgICAgICAgICAgICBtYXRjaGVkOiB0aGlzLm1hdGNoZWQsXG4gICAgICAgICAgICAgICAgeXlsZW5nOiB0aGlzLnl5bGVuZyxcbiAgICAgICAgICAgICAgICBvZmZzZXQ6IHRoaXMub2Zmc2V0LFxuICAgICAgICAgICAgICAgIF9tb3JlOiB0aGlzLl9tb3JlLFxuICAgICAgICAgICAgICAgIF9pbnB1dDogdGhpcy5faW5wdXQsXG4gICAgICAgICAgICAgICAgeXk6IHRoaXMueXksXG4gICAgICAgICAgICAgICAgY29uZGl0aW9uU3RhY2s6IHRoaXMuY29uZGl0aW9uU3RhY2suc2xpY2UoMCksXG4gICAgICAgICAgICAgICAgZG9uZTogdGhpcy5kb25lXG4gICAgICAgICAgICB9O1xuICAgICAgICAgICAgaWYgKHRoaXMub3B0aW9ucy5yYW5nZXMpIHtcbiAgICAgICAgICAgICAgICBiYWNrdXAueXlsbG9jLnJhbmdlID0gdGhpcy55eWxsb2MucmFuZ2Uuc2xpY2UoMCk7XG4gICAgICAgICAgICB9XG4gICAgICAgIH1cblxuICAgICAgICBsaW5lcyA9IG1hdGNoWzBdLm1hdGNoKC8oPzpcXHJcXG4/fFxcbikuKi9nKTtcbiAgICAgICAgaWYgKGxpbmVzKSB7XG4gICAgICAgICAgICB0aGlzLnl5bGluZW5vICs9IGxpbmVzLmxlbmd0aDtcbiAgICAgICAgfVxuICAgICAgICB0aGlzLnl5bGxvYyA9IHtcbiAgICAgICAgICAgIGZpcnN0X2xpbmU6IHRoaXMueXlsbG9jLmxhc3RfbGluZSxcbiAgICAgICAgICAgIGxhc3RfbGluZTogdGhpcy55eWxpbmVubyArIDEsXG4gICAgICAgICAgICBmaXJzdF9jb2x1bW46IHRoaXMueXlsbG9jLmxhc3RfY29sdW1uLFxuICAgICAgICAgICAgbGFzdF9jb2x1bW46IGxpbmVzID9cbiAgICAgICAgICAgICAgICAgICAgICAgICBsaW5lc1tsaW5lcy5sZW5ndGggLSAxXS5sZW5ndGggLSBsaW5lc1tsaW5lcy5sZW5ndGggLSAxXS5tYXRjaCgvXFxyP1xcbj8vKVswXS5sZW5ndGggOlxuICAgICAgICAgICAgICAgICAgICAgICAgIHRoaXMueXlsbG9jLmxhc3RfY29sdW1uICsgbWF0Y2hbMF0ubGVuZ3RoXG4gICAgICAgIH07XG4gICAgICAgIHRoaXMueXl0ZXh0ICs9IG1hdGNoWzBdO1xuICAgICAgICB0aGlzLm1hdGNoICs9IG1hdGNoWzBdO1xuICAgICAgICB0aGlzLm1hdGNoZXMgPSBtYXRjaDtcbiAgICAgICAgdGhpcy55eWxlbmcgPSB0aGlzLnl5dGV4dC5sZW5ndGg7XG4gICAgICAgIGlmICh0aGlzLm9wdGlvbnMucmFuZ2VzKSB7XG4gICAgICAgICAgICB0aGlzLnl5bGxvYy5yYW5nZSA9IFt0aGlzLm9mZnNldCwgdGhpcy5vZmZzZXQgKz0gdGhpcy55eWxlbmddO1xuICAgICAgICB9XG4gICAgICAgIHRoaXMuX21vcmUgPSBmYWxzZTtcbiAgICAgICAgdGhpcy5fYmFja3RyYWNrID0gZmFsc2U7XG4gICAgICAgIHRoaXMuX2lucHV0ID0gdGhpcy5faW5wdXQuc2xpY2UobWF0Y2hbMF0ubGVuZ3RoKTtcbiAgICAgICAgdGhpcy5tYXRjaGVkICs9IG1hdGNoWzBdO1xuICAgICAgICB0b2tlbiA9IHRoaXMucGVyZm9ybUFjdGlvbi5jYWxsKHRoaXMsIHRoaXMueXksIHRoaXMsIGluZGV4ZWRfcnVsZSwgdGhpcy5jb25kaXRpb25TdGFja1t0aGlzLmNvbmRpdGlvblN0YWNrLmxlbmd0aCAtIDFdKTtcbiAgICAgICAgaWYgKHRoaXMuZG9uZSAmJiB0aGlzLl9pbnB1dCkge1xuICAgICAgICAgICAgdGhpcy5kb25lID0gZmFsc2U7XG4gICAgICAgIH1cbiAgICAgICAgaWYgKHRva2VuKSB7XG4gICAgICAgICAgICByZXR1cm4gdG9rZW47XG4gICAgICAgIH0gZWxzZSBpZiAodGhpcy5fYmFja3RyYWNrKSB7XG4gICAgICAgICAgICAvLyByZWNvdmVyIGNvbnRleHRcbiAgICAgICAgICAgIGZvciAodmFyIGsgaW4gYmFja3VwKSB7XG4gICAgICAgICAgICAgICAgdGhpc1trXSA9IGJhY2t1cFtrXTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgICAgIHJldHVybiBmYWxzZTsgLy8gcnVsZSBhY3Rpb24gY2FsbGVkIHJlamVjdCgpIGltcGx5aW5nIHRoZSBuZXh0IHJ1bGUgc2hvdWxkIGJlIHRlc3RlZCBpbnN0ZWFkLlxuICAgICAgICB9XG4gICAgICAgIHJldHVybiBmYWxzZTtcbiAgICB9LFxuXG4vLyByZXR1cm4gbmV4dCBtYXRjaCBpbiBpbnB1dFxubmV4dDpmdW5jdGlvbiAoKSB7XG4gICAgICAgIGlmICh0aGlzLmRvbmUpIHtcbiAgICAgICAgICAgIHJldHVybiB0aGlzLkVPRjtcbiAgICAgICAgfVxuICAgICAgICBpZiAoIXRoaXMuX2lucHV0KSB7XG4gICAgICAgICAgICB0aGlzLmRvbmUgPSB0cnVlO1xuICAgICAgICB9XG5cbiAgICAgICAgdmFyIHRva2VuLFxuICAgICAgICAgICAgbWF0Y2gsXG4gICAgICAgICAgICB0ZW1wTWF0Y2gsXG4gICAgICAgICAgICBpbmRleDtcbiAgICAgICAgaWYgKCF0aGlzLl9tb3JlKSB7XG4gICAgICAgICAgICB0aGlzLnl5dGV4dCA9ICcnO1xuICAgICAgICAgICAgdGhpcy5tYXRjaCA9ICcnO1xuICAgICAgICB9XG4gICAgICAgIHZhciBydWxlcyA9IHRoaXMuX2N1cnJlbnRSdWxlcygpO1xuICAgICAgICBmb3IgKHZhciBpID0gMDsgaSA8IHJ1bGVzLmxlbmd0aDsgaSsrKSB7XG4gICAgICAgICAgICB0ZW1wTWF0Y2ggPSB0aGlzLl9pbnB1dC5tYXRjaCh0aGlzLnJ1bGVzW3J1bGVzW2ldXSk7XG4gICAgICAgICAgICBpZiAodGVtcE1hdGNoICYmICghbWF0Y2ggfHwgdGVtcE1hdGNoWzBdLmxlbmd0aCA+IG1hdGNoWzBdLmxlbmd0aCkpIHtcbiAgICAgICAgICAgICAgICBtYXRjaCA9IHRlbXBNYXRjaDtcbiAgICAgICAgICAgICAgICBpbmRleCA9IGk7XG4gICAgICAgICAgICAgICAgaWYgKHRoaXMub3B0aW9ucy5iYWNrdHJhY2tfbGV4ZXIpIHtcbiAgICAgICAgICAgICAgICAgICAgdG9rZW4gPSB0aGlzLnRlc3RfbWF0Y2godGVtcE1hdGNoLCBydWxlc1tpXSk7XG4gICAgICAgICAgICAgICAgICAgIGlmICh0b2tlbiAhPT0gZmFsc2UpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIHJldHVybiB0b2tlbjtcbiAgICAgICAgICAgICAgICAgICAgfSBlbHNlIGlmICh0aGlzLl9iYWNrdHJhY2spIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIG1hdGNoID0gZmFsc2U7XG4gICAgICAgICAgICAgICAgICAgICAgICBjb250aW51ZTsgLy8gcnVsZSBhY3Rpb24gY2FsbGVkIHJlamVjdCgpIGltcGx5aW5nIGEgcnVsZSBNSVNtYXRjaC5cbiAgICAgICAgICAgICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIC8vIGVsc2U6IHRoaXMgaXMgYSBsZXhlciBydWxlIHdoaWNoIGNvbnN1bWVzIGlucHV0IHdpdGhvdXQgcHJvZHVjaW5nIGEgdG9rZW4gKGUuZy4gd2hpdGVzcGFjZSlcbiAgICAgICAgICAgICAgICAgICAgICAgIHJldHVybiBmYWxzZTtcbiAgICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgIH0gZWxzZSBpZiAoIXRoaXMub3B0aW9ucy5mbGV4KSB7XG4gICAgICAgICAgICAgICAgICAgIGJyZWFrO1xuICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgIH1cbiAgICAgICAgfVxuICAgICAgICBpZiAobWF0Y2gpIHtcbiAgICAgICAgICAgIHRva2VuID0gdGhpcy50ZXN0X21hdGNoKG1hdGNoLCBydWxlc1tpbmRleF0pO1xuICAgICAgICAgICAgaWYgKHRva2VuICE9PSBmYWxzZSkge1xuICAgICAgICAgICAgICAgIHJldHVybiB0b2tlbjtcbiAgICAgICAgICAgIH1cbiAgICAgICAgICAgIC8vIGVsc2U6IHRoaXMgaXMgYSBsZXhlciBydWxlIHdoaWNoIGNvbnN1bWVzIGlucHV0IHdpdGhvdXQgcHJvZHVjaW5nIGEgdG9rZW4gKGUuZy4gd2hpdGVzcGFjZSlcbiAgICAgICAgICAgIHJldHVybiBmYWxzZTtcbiAgICAgICAgfVxuICAgICAgICBpZiAodGhpcy5faW5wdXQgPT09IFwiXCIpIHtcbiAgICAgICAgICAgIHJldHVybiB0aGlzLkVPRjtcbiAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgIHJldHVybiB0aGlzLnBhcnNlRXJyb3IoJ0xleGljYWwgZXJyb3Igb24gbGluZSAnICsgKHRoaXMueXlsaW5lbm8gKyAxKSArICcuIFVucmVjb2duaXplZCB0ZXh0LlxcbicgKyB0aGlzLnNob3dQb3NpdGlvbigpLCB7XG4gICAgICAgICAgICAgICAgdGV4dDogXCJcIixcbiAgICAgICAgICAgICAgICB0b2tlbjogbnVsbCxcbiAgICAgICAgICAgICAgICBsaW5lOiB0aGlzLnl5bGluZW5vXG4gICAgICAgICAgICB9KTtcbiAgICAgICAgfVxuICAgIH0sXG5cbi8vIHJldHVybiBuZXh0IG1hdGNoIHRoYXQgaGFzIGEgdG9rZW5cbmxleDpmdW5jdGlvbiBsZXggKCkge1xuICAgICAgICB2YXIgciA9IHRoaXMubmV4dCgpO1xuICAgICAgICBpZiAocikge1xuICAgICAgICAgICAgcmV0dXJuIHI7XG4gICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICByZXR1cm4gdGhpcy5sZXgoKTtcbiAgICAgICAgfVxuICAgIH0sXG5cbi8vIGFjdGl2YXRlcyBhIG5ldyBsZXhlciBjb25kaXRpb24gc3RhdGUgKHB1c2hlcyB0aGUgbmV3IGxleGVyIGNvbmRpdGlvbiBzdGF0ZSBvbnRvIHRoZSBjb25kaXRpb24gc3RhY2spXG5iZWdpbjpmdW5jdGlvbiBiZWdpbiAoY29uZGl0aW9uKSB7XG4gICAgICAgIHRoaXMuY29uZGl0aW9uU3RhY2sucHVzaChjb25kaXRpb24pO1xuICAgIH0sXG5cbi8vIHBvcCB0aGUgcHJldmlvdXNseSBhY3RpdmUgbGV4ZXIgY29uZGl0aW9uIHN0YXRlIG9mZiB0aGUgY29uZGl0aW9uIHN0YWNrXG5wb3BTdGF0ZTpmdW5jdGlvbiBwb3BTdGF0ZSAoKSB7XG4gICAgICAgIHZhciBuID0gdGhpcy5jb25kaXRpb25TdGFjay5sZW5ndGggLSAxO1xuICAgICAgICBpZiAobiA+IDApIHtcbiAgICAgICAgICAgIHJldHVybiB0aGlzLmNvbmRpdGlvblN0YWNrLnBvcCgpO1xuICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgcmV0dXJuIHRoaXMuY29uZGl0aW9uU3RhY2tbMF07XG4gICAgICAgIH1cbiAgICB9LFxuXG4vLyBwcm9kdWNlIHRoZSBsZXhlciBydWxlIHNldCB3aGljaCBpcyBhY3RpdmUgZm9yIHRoZSBjdXJyZW50bHkgYWN0aXZlIGxleGVyIGNvbmRpdGlvbiBzdGF0ZVxuX2N1cnJlbnRSdWxlczpmdW5jdGlvbiBfY3VycmVudFJ1bGVzICgpIHtcbiAgICAgICAgaWYgKHRoaXMuY29uZGl0aW9uU3RhY2subGVuZ3RoICYmIHRoaXMuY29uZGl0aW9uU3RhY2tbdGhpcy5jb25kaXRpb25TdGFjay5sZW5ndGggLSAxXSkge1xuICAgICAgICAgICAgcmV0dXJuIHRoaXMuY29uZGl0aW9uc1t0aGlzLmNvbmRpdGlvblN0YWNrW3RoaXMuY29uZGl0aW9uU3RhY2subGVuZ3RoIC0gMV1dLnJ1bGVzO1xuICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgcmV0dXJuIHRoaXMuY29uZGl0aW9uc1tcIklOSVRJQUxcIl0ucnVsZXM7XG4gICAgICAgIH1cbiAgICB9LFxuXG4vLyByZXR1cm4gdGhlIGN1cnJlbnRseSBhY3RpdmUgbGV4ZXIgY29uZGl0aW9uIHN0YXRlOyB3aGVuIGFuIGluZGV4IGFyZ3VtZW50IGlzIHByb3ZpZGVkIGl0IHByb2R1Y2VzIHRoZSBOLXRoIHByZXZpb3VzIGNvbmRpdGlvbiBzdGF0ZSwgaWYgYXZhaWxhYmxlXG50b3BTdGF0ZTpmdW5jdGlvbiB0b3BTdGF0ZSAobikge1xuICAgICAgICBuID0gdGhpcy5jb25kaXRpb25TdGFjay5sZW5ndGggLSAxIC0gTWF0aC5hYnMobiB8fCAwKTtcbiAgICAgICAgaWYgKG4gPj0gMCkge1xuICAgICAgICAgICAgcmV0dXJuIHRoaXMuY29uZGl0aW9uU3RhY2tbbl07XG4gICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICByZXR1cm4gXCJJTklUSUFMXCI7XG4gICAgICAgIH1cbiAgICB9LFxuXG4vLyBhbGlhcyBmb3IgYmVnaW4oY29uZGl0aW9uKVxucHVzaFN0YXRlOmZ1bmN0aW9uIHB1c2hTdGF0ZSAoY29uZGl0aW9uKSB7XG4gICAgICAgIHRoaXMuYmVnaW4oY29uZGl0aW9uKTtcbiAgICB9LFxuXG4vLyByZXR1cm4gdGhlIG51bWJlciBvZiBzdGF0ZXMgY3VycmVudGx5IG9uIHRoZSBzdGFja1xuc3RhdGVTdGFja1NpemU6ZnVuY3Rpb24gc3RhdGVTdGFja1NpemUoKSB7XG4gICAgICAgIHJldHVybiB0aGlzLmNvbmRpdGlvblN0YWNrLmxlbmd0aDtcbiAgICB9LFxub3B0aW9uczoge1wiZmxleFwiOnRydWUsXCJjYXNlLWluc2Vuc2l0aXZlXCI6dHJ1ZX0sXG5wZXJmb3JtQWN0aW9uOiBmdW5jdGlvbiBhbm9ueW1vdXMoeXkseXlfLCRhdm9pZGluZ19uYW1lX2NvbGxpc2lvbnMsWVlfU1RBUlQpIHtcbnZhciBZWVNUQVRFPVlZX1NUQVJUO1xuc3dpdGNoKCRhdm9pZGluZ19uYW1lX2NvbGxpc2lvbnMpIHtcbmNhc2UgMDovKiBpZ25vcmUgKi9cbmJyZWFrO1xuY2FzZSAxOnJldHVybiAxMlxuYnJlYWs7XG5jYXNlIDI6cmV0dXJuIDE1XG5icmVhaztcbmNhc2UgMzpyZXR1cm4gMjRcbmJyZWFrO1xuY2FzZSA0OnJldHVybiAyOTBcbmJyZWFrO1xuY2FzZSA1OnJldHVybiAyOTFcbmJyZWFrO1xuY2FzZSA2OnJldHVybiAyOVxuYnJlYWs7XG5jYXNlIDc6cmV0dXJuIDMxXG5icmVhaztcbmNhc2UgODpyZXR1cm4gMzJcbmJyZWFrO1xuY2FzZSA5OnJldHVybiAyOTNcbmJyZWFrO1xuY2FzZSAxMDpyZXR1cm4gMzRcbmJyZWFrO1xuY2FzZSAxMTpyZXR1cm4gMzhcbmJyZWFrO1xuY2FzZSAxMjpyZXR1cm4gMzlcbmJyZWFrO1xuY2FzZSAxMzpyZXR1cm4gNDFcbmJyZWFrO1xuY2FzZSAxNDpyZXR1cm4gNDNcbmJyZWFrO1xuY2FzZSAxNTpyZXR1cm4gNDhcbmJyZWFrO1xuY2FzZSAxNjpyZXR1cm4gNTFcbmJyZWFrO1xuY2FzZSAxNzpyZXR1cm4gMjk2XG5icmVhaztcbmNhc2UgMTg6cmV0dXJuIDYxXG5icmVhaztcbmNhc2UgMTk6cmV0dXJuIDYyXG5icmVhaztcbmNhc2UgMjA6cmV0dXJuIDY4XG5icmVhaztcbmNhc2UgMjE6cmV0dXJuIDcxXG5icmVhaztcbmNhc2UgMjI6cmV0dXJuIDc0XG5icmVhaztcbmNhc2UgMjM6cmV0dXJuIDc2XG5icmVhaztcbmNhc2UgMjQ6cmV0dXJuIDc5XG5icmVhaztcbmNhc2UgMjU6cmV0dXJuIDgxXG5icmVhaztcbmNhc2UgMjY6cmV0dXJuIDgzXG5icmVhaztcbmNhc2UgMjc6cmV0dXJuIDE4M1xuYnJlYWs7XG5jYXNlIDI4OnJldHVybiA5OVxuYnJlYWs7XG5jYXNlIDI5OnJldHVybiAyOTdcbmJyZWFrO1xuY2FzZSAzMDpyZXR1cm4gMTMyXG5icmVhaztcbmNhc2UgMzE6cmV0dXJuIDI5OFxuYnJlYWs7XG5jYXNlIDMyOnJldHVybiAyOTlcbmJyZWFrO1xuY2FzZSAzMzpyZXR1cm4gMTA5XG5icmVhaztcbmNhc2UgMzQ6cmV0dXJuIDMwMFxuYnJlYWs7XG5jYXNlIDM1OnJldHVybiAxMDhcbmJyZWFrO1xuY2FzZSAzNjpyZXR1cm4gMzAxXG5icmVhaztcbmNhc2UgMzc6cmV0dXJuIDMwMlxuYnJlYWs7XG5jYXNlIDM4OnJldHVybiAxMTJcbmJyZWFrO1xuY2FzZSAzOTpyZXR1cm4gMTE0XG5icmVhaztcbmNhc2UgNDA6cmV0dXJuIDExNVxuYnJlYWs7XG5jYXNlIDQxOnJldHVybiAxMzBcbmJyZWFrO1xuY2FzZSA0MjpyZXR1cm4gMTI0XG5icmVhaztcbmNhc2UgNDM6cmV0dXJuIDEyNVxuYnJlYWs7XG5jYXNlIDQ0OnJldHVybiAxMjdcbmJyZWFrO1xuY2FzZSA0NTpyZXR1cm4gMTMzXG5icmVhaztcbmNhc2UgNDY6cmV0dXJuIDExMVxuYnJlYWs7XG5jYXNlIDQ3OnJldHVybiAzMDNcbmJyZWFrO1xuY2FzZSA0ODpyZXR1cm4gMzA0XG5icmVhaztcbmNhc2UgNDk6cmV0dXJuIDE1OVxuYnJlYWs7XG5jYXNlIDUwOnJldHVybiAxNjJcbmJyZWFrO1xuY2FzZSA1MTpyZXR1cm4gMTY2XG5icmVhaztcbmNhc2UgNTI6cmV0dXJuIDkyXG5icmVhaztcbmNhc2UgNTM6cmV0dXJuIDE2MFxuYnJlYWs7XG5jYXNlIDU0OnJldHVybiAzMDVcbmJyZWFrO1xuY2FzZSA1NTpyZXR1cm4gMTY1XG5icmVhaztcbmNhc2UgNTY6cmV0dXJuIDI1MVxuYnJlYWs7XG5jYXNlIDU3OnJldHVybiAxODdcbmJyZWFrO1xuY2FzZSA1ODpyZXR1cm4gMzA2XG5icmVhaztcbmNhc2UgNTk6cmV0dXJuIDMwN1xuYnJlYWs7XG5jYXNlIDYwOnJldHVybiAyMTNcbmJyZWFrO1xuY2FzZSA2MTpyZXR1cm4gMzA5XG5icmVhaztcbmNhc2UgNjI6cmV0dXJuIDMxMFxuYnJlYWs7XG5jYXNlIDYzOnJldHVybiAyMDhcbmJyZWFrO1xuY2FzZSA2NDpyZXR1cm4gMjE1XG5icmVhaztcbmNhc2UgNjU6cmV0dXJuIDIxNlxuYnJlYWs7XG5jYXNlIDY2OnJldHVybiAyMjNcbmJyZWFrO1xuY2FzZSA2NzpyZXR1cm4gMjI3XG5icmVhaztcbmNhc2UgNjg6cmV0dXJuIDI2OFxuYnJlYWs7XG5jYXNlIDY5OnJldHVybiAzMTFcbmJyZWFrO1xuY2FzZSA3MDpyZXR1cm4gMzEyXG5icmVhaztcbmNhc2UgNzE6cmV0dXJuIDMxM1xuYnJlYWs7XG5jYXNlIDcyOnJldHVybiAzMTRcbmJyZWFrO1xuY2FzZSA3MzpyZXR1cm4gMzE1XG5icmVhaztcbmNhc2UgNzQ6cmV0dXJuIDIzMVxuYnJlYWs7XG5jYXNlIDc1OnJldHVybiAzMTZcbmJyZWFrO1xuY2FzZSA3NjpyZXR1cm4gMjQ2XG5icmVhaztcbmNhc2UgNzc6cmV0dXJuIDI1NFxuYnJlYWs7XG5jYXNlIDc4OnJldHVybiAyNTVcbmJyZWFrO1xuY2FzZSA3OTpyZXR1cm4gMjQ4XG5icmVhaztcbmNhc2UgODA6cmV0dXJuIDI0OVxuYnJlYWs7XG5jYXNlIDgxOnJldHVybiAyNTBcbmJyZWFrO1xuY2FzZSA4MjpyZXR1cm4gMzE3XG5icmVhaztcbmNhc2UgODM6cmV0dXJuIDMxOFxuYnJlYWs7XG5jYXNlIDg0OnJldHVybiAyNTJcbmJyZWFrO1xuY2FzZSA4NTpyZXR1cm4gMzIwXG5icmVhaztcbmNhc2UgODY6cmV0dXJuIDMxOVxuYnJlYWs7XG5jYXNlIDg3OnJldHVybiAzMjFcbmJyZWFrO1xuY2FzZSA4ODpyZXR1cm4gMjU3XG5icmVhaztcbmNhc2UgODk6cmV0dXJuIDI1OFxuYnJlYWs7XG5jYXNlIDkwOnJldHVybiAyNjFcbmJyZWFrO1xuY2FzZSA5MTpyZXR1cm4gMjYzXG5icmVhaztcbmNhc2UgOTI6cmV0dXJuIDI2N1xuYnJlYWs7XG5jYXNlIDkzOnJldHVybiAyNzFcbmJyZWFrO1xuY2FzZSA5NDpyZXR1cm4gMjc0XG5icmVhaztcbmNhc2UgOTU6cmV0dXJuIDI3NVxuYnJlYWs7XG5jYXNlIDk2OnJldHVybiAxM1xuYnJlYWs7XG5jYXNlIDk3OnJldHVybiAxNlxuYnJlYWs7XG5jYXNlIDk4OnJldHVybiAyODZcbmJyZWFrO1xuY2FzZSA5OTpyZXR1cm4gMjE4XG5icmVhaztcbmNhc2UgMTAwOnJldHVybiAyOFxuYnJlYWs7XG5jYXNlIDEwMTpyZXR1cm4gMjcwXG5icmVhaztcbmNhc2UgMTAyOnJldHVybiA4MFxuYnJlYWs7XG5jYXNlIDEwMzpyZXR1cm4gMjcyXG5icmVhaztcbmNhc2UgMTA0OnJldHVybiAyNzNcbmJyZWFrO1xuY2FzZSAxMDU6cmV0dXJuIDI4MFxuYnJlYWs7XG5jYXNlIDEwNjpyZXR1cm4gMjgxXG5icmVhaztcbmNhc2UgMTA3OnJldHVybiAyODJcbmJyZWFrO1xuY2FzZSAxMDg6cmV0dXJuIDI4M1xuYnJlYWs7XG5jYXNlIDEwOTpyZXR1cm4gMjg0XG5icmVhaztcbmNhc2UgMTEwOnJldHVybiAyODVcbmJyZWFrO1xuY2FzZSAxMTE6cmV0dXJuICdFWFBPTkVOVCdcbmJyZWFrO1xuY2FzZSAxMTI6cmV0dXJuIDI3NlxuYnJlYWs7XG5jYXNlIDExMzpyZXR1cm4gMjc3XG5icmVhaztcbmNhc2UgMTE0OnJldHVybiAyNzhcbmJyZWFrO1xuY2FzZSAxMTU6cmV0dXJuIDI3OVxuYnJlYWs7XG5jYXNlIDExNjpyZXR1cm4gODZcbmJyZWFrO1xuY2FzZSAxMTc6cmV0dXJuIDIxOVxuYnJlYWs7XG5jYXNlIDExODpyZXR1cm4gNlxuYnJlYWs7XG5jYXNlIDExOTpyZXR1cm4gJ0lOVkFMSUQnXG5icmVhaztcbmNhc2UgMTIwOmNvbnNvbGUubG9nKHl5Xy55eXRleHQpO1xuYnJlYWs7XG59XG59LFxucnVsZXM6IFsvXig/Olxccyt8I1teXFxuXFxyXSopL2ksL14oPzpCQVNFKS9pLC9eKD86UFJFRklYKS9pLC9eKD86U0VMRUNUKS9pLC9eKD86RElTVElOQ1QpL2ksL14oPzpSRURVQ0VEKS9pLC9eKD86XFwoKS9pLC9eKD86QVMpL2ksL14oPzpcXCkpL2ksL14oPzpcXCopL2ksL14oPzpDT05TVFJVQ1QpL2ksL14oPzpXSEVSRSkvaSwvXig/OlxceykvaSwvXig/OlxcfSkvaSwvXig/OkRFU0NSSUJFKS9pLC9eKD86QVNLKS9pLC9eKD86RlJPTSkvaSwvXig/Ok5BTUVEKS9pLC9eKD86R1JPVVApL2ksL14oPzpCWSkvaSwvXig/OkhBVklORykvaSwvXig/Ok9SREVSKS9pLC9eKD86QVNDKS9pLC9eKD86REVTQykvaSwvXig/OkxJTUlUKS9pLC9eKD86T0ZGU0VUKS9pLC9eKD86VkFMVUVTKS9pLC9eKD86OykvaSwvXig/OkxPQUQpL2ksL14oPzpTSUxFTlQpL2ksL14oPzpJTlRPKS9pLC9eKD86Q0xFQVIpL2ksL14oPzpEUk9QKS9pLC9eKD86Q1JFQVRFKS9pLC9eKD86QUREKS9pLC9eKD86VE8pL2ksL14oPzpNT1ZFKS9pLC9eKD86Q09QWSkvaSwvXig/OklOU0VSVFxccytEQVRBKS9pLC9eKD86REVMRVRFXFxzK0RBVEEpL2ksL14oPzpERUxFVEVcXHMrV0hFUkUpL2ksL14oPzpXSVRIKS9pLC9eKD86REVMRVRFKS9pLC9eKD86SU5TRVJUKS9pLC9eKD86VVNJTkcpL2ksL14oPzpERUZBVUxUKS9pLC9eKD86R1JBUEgpL2ksL14oPzpBTEwpL2ksL14oPzpcXC4pL2ksL14oPzpPUFRJT05BTCkvaSwvXig/OlNFUlZJQ0UpL2ksL14oPzpCSU5EKS9pLC9eKD86VU5ERUYpL2ksL14oPzpNSU5VUykvaSwvXig/OlVOSU9OKS9pLC9eKD86RklMVEVSKS9pLC9eKD86LCkvaSwvXig/OmEpL2ksL14oPzpcXHwpL2ksL14oPzpcXC8pL2ksL14oPzpcXF4pL2ksL14oPzpcXD8pL2ksL14oPzpcXCspL2ksL14oPzohKS9pLC9eKD86XFxbKS9pLC9eKD86XFxdKS9pLC9eKD86XFx8XFx8KS9pLC9eKD86JiYpL2ksL14oPzo9KS9pLC9eKD86IT0pL2ksL14oPzo8KS9pLC9eKD86PikvaSwvXig/Ojw9KS9pLC9eKD86Pj0pL2ksL14oPzpJTikvaSwvXig/Ok5PVCkvaSwvXig/Oi0pL2ksL14oPzpCT1VORCkvaSwvXig/OkJOT0RFKS9pLC9eKD86KFJBTkR8Tk9XfFVVSUR8U1RSVVVJRCkpL2ksL14oPzooTEFOR3xEQVRBVFlQRXxJUkl8VVJJfEFCU3xDRUlMfEZMT09SfFJPVU5EfFNUUkxFTnxTVFJ8VUNBU0V8TENBU0V8RU5DT0RFX0ZPUl9VUkl8WUVBUnxNT05USHxEQVl8SE9VUlN8TUlOVVRFU3xTRUNPTkRTfFRJTUVaT05FfFRafE1ENXxTSEExfFNIQTI1NnxTSEEzODR8U0hBNTEyfGlzSVJJfGlzVVJJfGlzQkxBTkt8aXNMSVRFUkFMfGlzTlVNRVJJQykpL2ksL14oPzooTEFOR01BVENIRVN8Q09OVEFJTlN8U1RSU1RBUlRTfFNUUkVORFN8U1RSQkVGT1JFfFNUUkFGVEVSfFNUUkxBTkd8U1RSRFR8c2FtZVRlcm0pKS9pLC9eKD86Q09OQ0FUKS9pLC9eKD86Q09BTEVTQ0UpL2ksL14oPzpJRikvaSwvXig/OlJFR0VYKS9pLC9eKD86U1VCU1RSKS9pLC9eKD86UkVQTEFDRSkvaSwvXig/OkVYSVNUUykvaSwvXig/OkNPVU5UKS9pLC9eKD86U1VNfE1JTnxNQVh8QVZHfFNBTVBMRSkvaSwvXig/OkdST1VQX0NPTkNBVCkvaSwvXig/OlNFUEFSQVRPUikvaSwvXig/OlxcXlxcXikvaSwvXig/OnRydWUpL2ksL14oPzpmYWxzZSkvaSwvXig/Oig8KFtePD5cXFwiXFx7XFx9XFx8XFxeYFxcXFxcXHUwMDAwLVxcdTAwMjBdKSo+KSkvaSwvXig/OigoKFtBLVpdfFthLXpdfFtcXHUwMEMwLVxcdTAwRDZdfFtcXHUwMEQ4LVxcdTAwRjZdfFtcXHUwMEY4LVxcdTAyRkZdfFtcXHUwMzcwLVxcdTAzN0RdfFtcXHUwMzdGLVxcdTFGRkZdfFtcXHUyMDBDLVxcdTIwMERdfFtcXHUyMDcwLVxcdTIxOEZdfFtcXHUyQzAwLVxcdTJGRUZdfFtcXHUzMDAxLVxcdUQ3RkZdfFtcXHVGOTAwLVxcdUZEQ0ZdfFtcXHVGREYwLVxcdUZGRkRdfFtcXHVEODAwLVxcdURCN0ZdW1xcdURDMDAtXFx1REZGRl0pKCgoKCg/OihbQS1aXXxbYS16XXxbXFx1MDBDMC1cXHUwMEQ2XXxbXFx1MDBEOC1cXHUwMEY2XXxbXFx1MDBGOC1cXHUwMkZGXXxbXFx1MDM3MC1cXHUwMzdEXXxbXFx1MDM3Ri1cXHUxRkZGXXxbXFx1MjAwQy1cXHUyMDBEXXxbXFx1MjA3MC1cXHUyMThGXXxbXFx1MkMwMC1cXHUyRkVGXXxbXFx1MzAwMS1cXHVEN0ZGXXxbXFx1RjkwMC1cXHVGRENGXXxbXFx1RkRGMC1cXHVGRkZEXXxbXFx1RDgwMC1cXHVEQjdGXVtcXHVEQzAwLVxcdURGRkZdKXxfKSl8LXxbMC05XXxcXHUwMEI3fFtcXHUwMzAwLVxcdTAzNkZdfFtcXHUyMDNGLVxcdTIwNDBdKXxcXC4pKigoKD86KFtBLVpdfFthLXpdfFtcXHUwMEMwLVxcdTAwRDZdfFtcXHUwMEQ4LVxcdTAwRjZdfFtcXHUwMEY4LVxcdTAyRkZdfFtcXHUwMzcwLVxcdTAzN0RdfFtcXHUwMzdGLVxcdTFGRkZdfFtcXHUyMDBDLVxcdTIwMERdfFtcXHUyMDcwLVxcdTIxOEZdfFtcXHUyQzAwLVxcdTJGRUZdfFtcXHUzMDAxLVxcdUQ3RkZdfFtcXHVGOTAwLVxcdUZEQ0ZdfFtcXHVGREYwLVxcdUZGRkRdfFtcXHVEODAwLVxcdURCN0ZdW1xcdURDMDAtXFx1REZGRl0pfF8pKXwtfFswLTldfFxcdTAwQjd8W1xcdTAzMDAtXFx1MDM2Rl18W1xcdTIwM0YtXFx1MjA0MF0pKT8pPzopKS9pLC9eKD86KCgoKFtBLVpdfFthLXpdfFtcXHUwMEMwLVxcdTAwRDZdfFtcXHUwMEQ4LVxcdTAwRjZdfFtcXHUwMEY4LVxcdTAyRkZdfFtcXHUwMzcwLVxcdTAzN0RdfFtcXHUwMzdGLVxcdTFGRkZdfFtcXHUyMDBDLVxcdTIwMERdfFtcXHUyMDcwLVxcdTIxOEZdfFtcXHUyQzAwLVxcdTJGRUZdfFtcXHUzMDAxLVxcdUQ3RkZdfFtcXHVGOTAwLVxcdUZEQ0ZdfFtcXHVGREYwLVxcdUZGRkRdfFtcXHVEODAwLVxcdURCN0ZdW1xcdURDMDAtXFx1REZGRl0pKCgoKCg/OihbQS1aXXxbYS16XXxbXFx1MDBDMC1cXHUwMEQ2XXxbXFx1MDBEOC1cXHUwMEY2XXxbXFx1MDBGOC1cXHUwMkZGXXxbXFx1MDM3MC1cXHUwMzdEXXxbXFx1MDM3Ri1cXHUxRkZGXXxbXFx1MjAwQy1cXHUyMDBEXXxbXFx1MjA3MC1cXHUyMThGXXxbXFx1MkMwMC1cXHUyRkVGXXxbXFx1MzAwMS1cXHVEN0ZGXXxbXFx1RjkwMC1cXHVGRENGXXxbXFx1RkRGMC1cXHVGRkZEXXxbXFx1RDgwMC1cXHVEQjdGXVtcXHVEQzAwLVxcdURGRkZdKXxfKSl8LXxbMC05XXxcXHUwMEI3fFtcXHUwMzAwLVxcdTAzNkZdfFtcXHUyMDNGLVxcdTIwNDBdKXxcXC4pKigoKD86KFtBLVpdfFthLXpdfFtcXHUwMEMwLVxcdTAwRDZdfFtcXHUwMEQ4LVxcdTAwRjZdfFtcXHUwMEY4LVxcdTAyRkZdfFtcXHUwMzcwLVxcdTAzN0RdfFtcXHUwMzdGLVxcdTFGRkZdfFtcXHUyMDBDLVxcdTIwMERdfFtcXHUyMDcwLVxcdTIxOEZdfFtcXHUyQzAwLVxcdTJGRUZdfFtcXHUzMDAxLVxcdUQ3RkZdfFtcXHVGOTAwLVxcdUZEQ0ZdfFtcXHVGREYwLVxcdUZGRkRdfFtcXHVEODAwLVxcdURCN0ZdW1xcdURDMDAtXFx1REZGRl0pfF8pKXwtfFswLTldfFxcdTAwQjd8W1xcdTAzMDAtXFx1MDM2Rl18W1xcdTIwM0YtXFx1MjA0MF0pKT8pPzopKCgoKD86KFtBLVpdfFthLXpdfFtcXHUwMEMwLVxcdTAwRDZdfFtcXHUwMEQ4LVxcdTAwRjZdfFtcXHUwMEY4LVxcdTAyRkZdfFtcXHUwMzcwLVxcdTAzN0RdfFtcXHUwMzdGLVxcdTFGRkZdfFtcXHUyMDBDLVxcdTIwMERdfFtcXHUyMDcwLVxcdTIxOEZdfFtcXHUyQzAwLVxcdTJGRUZdfFtcXHUzMDAxLVxcdUQ3RkZdfFtcXHVGOTAwLVxcdUZEQ0ZdfFtcXHVGREYwLVxcdUZGRkRdfFtcXHVEODAwLVxcdURCN0ZdW1xcdURDMDAtXFx1REZGRl0pfF8pKXw6fFswLTldfCgoJShbMC05XXxbQS1GXXxbYS1mXSkoWzAtOV18W0EtRl18W2EtZl0pKXwoXFxcXChffH58XFwufC18IXxcXCR8JnwnfFxcKHxcXCl8XFwqfFxcK3wsfDt8PXxcXC98XFw/fCN8QHwlKSkpKSgoKCgoPzooW0EtWl18W2Etel18W1xcdTAwQzAtXFx1MDBENl18W1xcdTAwRDgtXFx1MDBGNl18W1xcdTAwRjgtXFx1MDJGRl18W1xcdTAzNzAtXFx1MDM3RF18W1xcdTAzN0YtXFx1MUZGRl18W1xcdTIwMEMtXFx1MjAwRF18W1xcdTIwNzAtXFx1MjE4Rl18W1xcdTJDMDAtXFx1MkZFRl18W1xcdTMwMDEtXFx1RDdGRl18W1xcdUY5MDAtXFx1RkRDRl18W1xcdUZERjAtXFx1RkZGRF18W1xcdUQ4MDAtXFx1REI3Rl1bXFx1REMwMC1cXHVERkZGXSl8XykpfC18WzAtOV18XFx1MDBCN3xbXFx1MDMwMC1cXHUwMzZGXXxbXFx1MjAzRi1cXHUyMDQwXSl8XFwufDp8KCglKFswLTldfFtBLUZdfFthLWZdKShbMC05XXxbQS1GXXxbYS1mXSkpfChcXFxcKF98fnxcXC58LXwhfFxcJHwmfCd8XFwofFxcKXxcXCp8XFwrfCx8O3w9fFxcL3xcXD98I3xAfCUpKSkpKigoKCg/OihbQS1aXXxbYS16XXxbXFx1MDBDMC1cXHUwMEQ2XXxbXFx1MDBEOC1cXHUwMEY2XXxbXFx1MDBGOC1cXHUwMkZGXXxbXFx1MDM3MC1cXHUwMzdEXXxbXFx1MDM3Ri1cXHUxRkZGXXxbXFx1MjAwQy1cXHUyMDBEXXxbXFx1MjA3MC1cXHUyMThGXXxbXFx1MkMwMC1cXHUyRkVGXXxbXFx1MzAwMS1cXHVEN0ZGXXxbXFx1RjkwMC1cXHVGRENGXXxbXFx1RkRGMC1cXHVGRkZEXXxbXFx1RDgwMC1cXHVEQjdGXVtcXHVEQzAwLVxcdURGRkZdKXxfKSl8LXxbMC05XXxcXHUwMEI3fFtcXHUwMzAwLVxcdTAzNkZdfFtcXHUyMDNGLVxcdTIwNDBdKXw6fCgoJShbMC05XXxbQS1GXXxbYS1mXSkoWzAtOV18W0EtRl18W2EtZl0pKXwoXFxcXChffH58XFwufC18IXxcXCR8JnwnfFxcKHxcXCl8XFwqfFxcK3wsfDt8PXxcXC98XFw/fCN8QHwlKSkpKSk/KSkpL2ksL14oPzooXzooKCg/OihbQS1aXXxbYS16XXxbXFx1MDBDMC1cXHUwMEQ2XXxbXFx1MDBEOC1cXHUwMEY2XXxbXFx1MDBGOC1cXHUwMkZGXXxbXFx1MDM3MC1cXHUwMzdEXXxbXFx1MDM3Ri1cXHUxRkZGXXxbXFx1MjAwQy1cXHUyMDBEXXxbXFx1MjA3MC1cXHUyMThGXXxbXFx1MkMwMC1cXHUyRkVGXXxbXFx1MzAwMS1cXHVEN0ZGXXxbXFx1RjkwMC1cXHVGRENGXXxbXFx1RkRGMC1cXHVGRkZEXXxbXFx1RDgwMC1cXHVEQjdGXVtcXHVEQzAwLVxcdURGRkZdKXxfKSl8WzAtOV0pKCgoKCg/OihbQS1aXXxbYS16XXxbXFx1MDBDMC1cXHUwMEQ2XXxbXFx1MDBEOC1cXHUwMEY2XXxbXFx1MDBGOC1cXHUwMkZGXXxbXFx1MDM3MC1cXHUwMzdEXXxbXFx1MDM3Ri1cXHUxRkZGXXxbXFx1MjAwQy1cXHUyMDBEXXxbXFx1MjA3MC1cXHUyMThGXXxbXFx1MkMwMC1cXHUyRkVGXXxbXFx1MzAwMS1cXHVEN0ZGXXxbXFx1RjkwMC1cXHVGRENGXXxbXFx1RkRGMC1cXHVGRkZEXXxbXFx1RDgwMC1cXHVEQjdGXVtcXHVEQzAwLVxcdURGRkZdKXxfKSl8LXxbMC05XXxcXHUwMEI3fFtcXHUwMzAwLVxcdTAzNkZdfFtcXHUyMDNGLVxcdTIwNDBdKXxcXC4pKigoKD86KFtBLVpdfFthLXpdfFtcXHUwMEMwLVxcdTAwRDZdfFtcXHUwMEQ4LVxcdTAwRjZdfFtcXHUwMEY4LVxcdTAyRkZdfFtcXHUwMzcwLVxcdTAzN0RdfFtcXHUwMzdGLVxcdTFGRkZdfFtcXHUyMDBDLVxcdTIwMERdfFtcXHUyMDcwLVxcdTIxOEZdfFtcXHUyQzAwLVxcdTJGRUZdfFtcXHUzMDAxLVxcdUQ3RkZdfFtcXHVGOTAwLVxcdUZEQ0ZdfFtcXHVGREYwLVxcdUZGRkRdfFtcXHVEODAwLVxcdURCN0ZdW1xcdURDMDAtXFx1REZGRl0pfF8pKXwtfFswLTldfFxcdTAwQjd8W1xcdTAzMDAtXFx1MDM2Rl18W1xcdTIwM0YtXFx1MjA0MF0pKT8pKS9pLC9eKD86KFtcXD9cXCRdKCgoKD86KFtBLVpdfFthLXpdfFtcXHUwMEMwLVxcdTAwRDZdfFtcXHUwMEQ4LVxcdTAwRjZdfFtcXHUwMEY4LVxcdTAyRkZdfFtcXHUwMzcwLVxcdTAzN0RdfFtcXHUwMzdGLVxcdTFGRkZdfFtcXHUyMDBDLVxcdTIwMERdfFtcXHUyMDcwLVxcdTIxOEZdfFtcXHUyQzAwLVxcdTJGRUZdfFtcXHUzMDAxLVxcdUQ3RkZdfFtcXHVGOTAwLVxcdUZEQ0ZdfFtcXHVGREYwLVxcdUZGRkRdfFtcXHVEODAwLVxcdURCN0ZdW1xcdURDMDAtXFx1REZGRl0pfF8pKXxbMC05XSkoKCg/OihbQS1aXXxbYS16XXxbXFx1MDBDMC1cXHUwMEQ2XXxbXFx1MDBEOC1cXHUwMEY2XXxbXFx1MDBGOC1cXHUwMkZGXXxbXFx1MDM3MC1cXHUwMzdEXXxbXFx1MDM3Ri1cXHUxRkZGXXxbXFx1MjAwQy1cXHUyMDBEXXxbXFx1MjA3MC1cXHUyMThGXXxbXFx1MkMwMC1cXHUyRkVGXXxbXFx1MzAwMS1cXHVEN0ZGXXxbXFx1RjkwMC1cXHVGRENGXXxbXFx1RkRGMC1cXHVGRkZEXXxbXFx1RDgwMC1cXHVEQjdGXVtcXHVEQzAwLVxcdURGRkZdKXxfKSl8WzAtOV18XFx1MDBCN3xbXFx1MDMwMC1cXHUwMzZGXXxbXFx1MjAzRi1cXHUyMDQwXSkqKSkpL2ksL14oPzooQFthLXpBLVpdKygtW2EtekEtWjAtOV0rKSopKS9pLC9eKD86KFswLTldKykpL2ksL14oPzooWzAtOV0qXFwuWzAtOV0rKSkvaSwvXig/OihbMC05XStcXC5bMC05XSooW2VFXVsrLV0/WzAtOV0rKXxcXC4oWzAtOV0pKyhbZUVdWystXT9bMC05XSspfChbMC05XSkrKFtlRV1bKy1dP1swLTldKykpKS9pLC9eKD86KFxcKyhbMC05XSspKSkvaSwvXig/OihcXCsoWzAtOV0qXFwuWzAtOV0rKSkpL2ksL14oPzooXFwrKFswLTldK1xcLlswLTldKihbZUVdWystXT9bMC05XSspfFxcLihbMC05XSkrKFtlRV1bKy1dP1swLTldKyl8KFswLTldKSsoW2VFXVsrLV0/WzAtOV0rKSkpKS9pLC9eKD86KC0oWzAtOV0rKSkpL2ksL14oPzooLShbMC05XSpcXC5bMC05XSspKSkvaSwvXig/OigtKFswLTldK1xcLlswLTldKihbZUVdWystXT9bMC05XSspfFxcLihbMC05XSkrKFtlRV1bKy1dP1swLTldKyl8KFswLTldKSsoW2VFXVsrLV0/WzAtOV0rKSkpKS9pLC9eKD86KFtlRV1bKy1dP1swLTldKykpL2ksL14oPzooJygoW15cXHUwMDI3XFx1MDA1Q1xcdTAwMEFcXHUwMDBEXSl8KFxcXFxbdGJucmZcXFxcXFxcIiddfFxcXFx1KFswLTldfFtBLUZdfFthLWZdKShbMC05XXxbQS1GXXxbYS1mXSkoWzAtOV18W0EtRl18W2EtZl0pKFswLTldfFtBLUZdfFthLWZdKXxcXFxcVShbMC05XXxbQS1GXXxbYS1mXSkoWzAtOV18W0EtRl18W2EtZl0pKFswLTldfFtBLUZdfFthLWZdKShbMC05XXxbQS1GXXxbYS1mXSkoWzAtOV18W0EtRl18W2EtZl0pKFswLTldfFtBLUZdfFthLWZdKShbMC05XXxbQS1GXXxbYS1mXSkoWzAtOV18W0EtRl18W2EtZl0pKSkqJykpL2ksL14oPzooXCIoKFteXFx1MDAyMlxcdTAwNUNcXHUwMDBBXFx1MDAwRF0pfChcXFxcW3RibnJmXFxcXFxcXCInXXxcXFxcdShbMC05XXxbQS1GXXxbYS1mXSkoWzAtOV18W0EtRl18W2EtZl0pKFswLTldfFtBLUZdfFthLWZdKShbMC05XXxbQS1GXXxbYS1mXSl8XFxcXFUoWzAtOV18W0EtRl18W2EtZl0pKFswLTldfFtBLUZdfFthLWZdKShbMC05XXxbQS1GXXxbYS1mXSkoWzAtOV18W0EtRl18W2EtZl0pKFswLTldfFtBLUZdfFthLWZdKShbMC05XXxbQS1GXXxbYS1mXSkoWzAtOV18W0EtRl18W2EtZl0pKFswLTldfFtBLUZdfFthLWZdKSkpKlwiKSkvaSwvXig/OignJycoKCd8JycpPyhbXidcXFxcXXwoXFxcXFt0Ym5yZlxcXFxcXFwiJ118XFxcXHUoWzAtOV18W0EtRl18W2EtZl0pKFswLTldfFtBLUZdfFthLWZdKShbMC05XXxbQS1GXXxbYS1mXSkoWzAtOV18W0EtRl18W2EtZl0pfFxcXFxVKFswLTldfFtBLUZdfFthLWZdKShbMC05XXxbQS1GXXxbYS1mXSkoWzAtOV18W0EtRl18W2EtZl0pKFswLTldfFtBLUZdfFthLWZdKShbMC05XXxbQS1GXXxbYS1mXSkoWzAtOV18W0EtRl18W2EtZl0pKFswLTldfFtBLUZdfFthLWZdKShbMC05XXxbQS1GXXxbYS1mXSkpKSkqJycnKSkvaSwvXig/OihcIlwiXCIoKFwifFwiXCIpPyhbXlxcXCJcXFxcXXwoXFxcXFt0Ym5yZlxcXFxcXFwiJ118XFxcXHUoWzAtOV18W0EtRl18W2EtZl0pKFswLTldfFtBLUZdfFthLWZdKShbMC05XXxbQS1GXXxbYS1mXSkoWzAtOV18W0EtRl18W2EtZl0pfFxcXFxVKFswLTldfFtBLUZdfFthLWZdKShbMC05XXxbQS1GXXxbYS1mXSkoWzAtOV18W0EtRl18W2EtZl0pKFswLTldfFtBLUZdfFthLWZdKShbMC05XXxbQS1GXXxbYS1mXSkoWzAtOV18W0EtRl18W2EtZl0pKFswLTldfFtBLUZdfFthLWZdKShbMC05XXxbQS1GXXxbYS1mXSkpKSkqXCJcIlwiKSkvaSwvXig/OihcXCgoXFx1MDAyMHxcXHUwMDA5fFxcdTAwMER8XFx1MDAwQSkqXFwpKSkvaSwvXig/OihcXFsoXFx1MDAyMHxcXHUwMDA5fFxcdTAwMER8XFx1MDAwQSkqXFxdKSkvaSwvXig/OiQpL2ksL14oPzouKS9pLC9eKD86LikvaV0sXG5jb25kaXRpb25zOiB7XCJJTklUSUFMXCI6e1wicnVsZXNcIjpbMCwxLDIsMyw0LDUsNiw3LDgsOSwxMCwxMSwxMiwxMywxNCwxNSwxNiwxNywxOCwxOSwyMCwyMSwyMiwyMywyNCwyNSwyNiwyNywyOCwyOSwzMCwzMSwzMiwzMywzNCwzNSwzNiwzNywzOCwzOSw0MCw0MSw0Miw0Myw0NCw0NSw0Niw0Nyw0OCw0OSw1MCw1MSw1Miw1Myw1NCw1NSw1Niw1Nyw1OCw1OSw2MCw2MSw2Miw2Myw2NCw2NSw2Niw2Nyw2OCw2OSw3MCw3MSw3Miw3Myw3NCw3NSw3Niw3Nyw3OCw3OSw4MCw4MSw4Miw4Myw4NCw4NSw4Niw4Nyw4OCw4OSw5MCw5MSw5Miw5Myw5NCw5NSw5Niw5Nyw5OCw5OSwxMDAsMTAxLDEwMiwxMDMsMTA0LDEwNSwxMDYsMTA3LDEwOCwxMDksMTEwLDExMSwxMTIsMTEzLDExNCwxMTUsMTE2LDExNywxMTgsMTE5LDEyMF0sXCJpbmNsdXNpdmVcIjp0cnVlfX1cbn0pO1xucmV0dXJuIGxleGVyO1xufSkoKTtcbnBhcnNlci5sZXhlciA9IGxleGVyO1xuZnVuY3Rpb24gUGFyc2VyICgpIHtcbiAgdGhpcy55eSA9IHt9O1xufVxuUGFyc2VyLnByb3RvdHlwZSA9IHBhcnNlcjtwYXJzZXIuUGFyc2VyID0gUGFyc2VyO1xucmV0dXJuIG5ldyBQYXJzZXI7XG59KSgpO1xuXG5cbmlmICh0eXBlb2YgcmVxdWlyZSAhPT0gJ3VuZGVmaW5lZCcgJiYgdHlwZW9mIGV4cG9ydHMgIT09ICd1bmRlZmluZWQnKSB7XG5leHBvcnRzLnBhcnNlciA9IFNwYXJxbFBhcnNlcjtcbmV4cG9ydHMuUGFyc2VyID0gU3BhcnFsUGFyc2VyLlBhcnNlcjtcbmV4cG9ydHMucGFyc2UgPSBmdW5jdGlvbiAoKSB7IHJldHVybiBTcGFycWxQYXJzZXIucGFyc2UuYXBwbHkoU3BhcnFsUGFyc2VyLCBhcmd1bWVudHMpOyB9O1xuZXhwb3J0cy5tYWluID0gZnVuY3Rpb24gY29tbW9uanNNYWluIChhcmdzKSB7XG4gICAgaWYgKCFhcmdzWzFdKSB7XG4gICAgICAgIGNvbnNvbGUubG9nKCdVc2FnZTogJythcmdzWzBdKycgRklMRScpO1xuICAgICAgICBwcm9jZXNzLmV4aXQoMSk7XG4gICAgfVxuICAgIHZhciBzb3VyY2UgPSByZXF1aXJlKCdmcycpLnJlYWRGaWxlU3luYyhyZXF1aXJlKCdwYXRoJykubm9ybWFsaXplKGFyZ3NbMV0pLCBcInV0ZjhcIik7XG4gICAgcmV0dXJuIGV4cG9ydHMucGFyc2VyLnBhcnNlKHNvdXJjZSk7XG59O1xuaWYgKHR5cGVvZiBtb2R1bGUgIT09ICd1bmRlZmluZWQnICYmIHJlcXVpcmUubWFpbiA9PT0gbW9kdWxlKSB7XG4gIGV4cG9ydHMubWFpbihwcm9jZXNzLmFyZ3Yuc2xpY2UoMSkpO1xufVxufSIsInZhciBQYXJzZXIgPSByZXF1aXJlKCcuL2xpYi9TcGFycWxQYXJzZXInKS5QYXJzZXI7XG52YXIgR2VuZXJhdG9yID0gcmVxdWlyZSgnLi9saWIvU3BhcnFsR2VuZXJhdG9yJyk7XG5cbm1vZHVsZS5leHBvcnRzID0ge1xuICAvKipcbiAgICogQ3JlYXRlcyBhIFNQQVJRTCBwYXJzZXIgd2l0aCB0aGUgZ2l2ZW4gcHJlLWRlZmluZWQgcHJlZml4ZXMgYW5kIGJhc2UgSVJJXG4gICAqIEBwYXJhbSBwcmVmaXhlcyB7IFtwcmVmaXg6IHN0cmluZ106IHN0cmluZyB9XG4gICAqIEBwYXJhbSBiYXNlSVJJIHN0cmluZ1xuICAgKi9cbiAgUGFyc2VyOiBmdW5jdGlvbiAocHJlZml4ZXMsIGJhc2VJUkkpIHtcbiAgICAvLyBDcmVhdGUgYSBjb3B5IG9mIHRoZSBwcmVmaXhlc1xuICAgIHZhciBwcmVmaXhlc0NvcHkgPSB7fTtcbiAgICBmb3IgKHZhciBwcmVmaXggaW4gcHJlZml4ZXMgfHwge30pXG4gICAgICBwcmVmaXhlc0NvcHlbcHJlZml4XSA9IHByZWZpeGVzW3ByZWZpeF07XG5cbiAgICAvLyBDcmVhdGUgYSBuZXcgcGFyc2VyIHdpdGggdGhlIGdpdmVuIHByZWZpeGVzXG4gICAgLy8gKFdvcmthcm91bmQgZm9yIGh0dHBzOi8vZ2l0aHViLmNvbS96YWFjaC9qaXNvbi9pc3N1ZXMvMjQxKVxuICAgIHZhciBwYXJzZXIgPSBuZXcgUGFyc2VyKCk7XG4gICAgcGFyc2VyLnBhcnNlID0gZnVuY3Rpb24gKCkge1xuICAgICAgUGFyc2VyLmJhc2UgPSBiYXNlSVJJIHx8ICcnO1xuICAgICAgUGFyc2VyLnByZWZpeGVzID0gT2JqZWN0LmNyZWF0ZShwcmVmaXhlc0NvcHkpO1xuICAgICAgcmV0dXJuIFBhcnNlci5wcm90b3R5cGUucGFyc2UuYXBwbHkocGFyc2VyLCBhcmd1bWVudHMpO1xuICAgIH07XG4gICAgcGFyc2VyLl9yZXNldEJsYW5rcyA9IFBhcnNlci5fcmVzZXRCbGFua3M7XG4gICAgcmV0dXJuIHBhcnNlcjtcbiAgfSxcbiAgR2VuZXJhdG9yOiBHZW5lcmF0b3IsXG59O1xuIiwiaW1wb3J0IHsgUGFyc2VyLCBEZXNjcmliZVF1ZXJ5LCBWYXJpYWJsZSwgVmFyaWFibGVFeHByZXNzaW9uLCBUZXJtIH0gZnJvbSAnc3BhcnFsanMnO1xuaW1wb3J0IHsgUXVlcnlCdWlsZGVyIH0gZnJvbSAnLi9RdWVyeUJ1aWxkZXInO1xuXG5leHBvcnQgY2xhc3MgRGVzY3JpYmVCdWlsZGVyIGV4dGVuZHMgUXVlcnlCdWlsZGVyXG57XG5cbiAgICBjb25zdHJ1Y3RvcihkZXNjcmliZTogRGVzY3JpYmVRdWVyeSlcbiAgICB7XG4gICAgICAgIHN1cGVyKGRlc2NyaWJlKTtcbiAgICB9XG5cbiAgICBwdWJsaWMgc3RhdGljIGZyb21TdHJpbmcocXVlcnlTdHJpbmc6IHN0cmluZywgcHJlZml4ZXM/OiB7IFtwcmVmaXg6IHN0cmluZ106IHN0cmluZzsgfSB8IHVuZGVmaW5lZCwgYmFzZUlSST86IHN0cmluZyB8IHVuZGVmaW5lZCk6IERlc2NyaWJlQnVpbGRlclxuICAgIHtcbiAgICAgICAgbGV0IHF1ZXJ5ID0gbmV3IFBhcnNlcihwcmVmaXhlcywgYmFzZUlSSSkucGFyc2UocXVlcnlTdHJpbmcpO1xuICAgICAgICBpZiAoITxEZXNjcmliZVF1ZXJ5PnF1ZXJ5KSB0aHJvdyBuZXcgRXJyb3IoXCJPbmx5IERFU0NJQkUgaXMgc3VwcG9ydGVkXCIpO1xuXG4gICAgICAgIHJldHVybiBuZXcgRGVzY3JpYmVCdWlsZGVyKDxEZXNjcmliZVF1ZXJ5PnF1ZXJ5KTtcbiAgICB9XG5cbiAgICBwdWJsaWMgc3RhdGljIGZyb21RdWVyeShxdWVyeTogRGVzY3JpYmVRdWVyeSk6IERlc2NyaWJlQnVpbGRlclxuICAgIHtcbiAgICAgICAgcmV0dXJuIG5ldyBEZXNjcmliZUJ1aWxkZXIocXVlcnkpO1xuICAgIH1cblxuICAgIHB1YmxpYyBzdGF0aWMgbmV3KCk6IERlc2NyaWJlQnVpbGRlclxuICAgIHtcbiAgICAgICAgcmV0dXJuIG5ldyBEZXNjcmliZUJ1aWxkZXIoe1xuICAgICAgICAgIFwicXVlcnlUeXBlXCI6IFwiREVTQ1JJQkVcIixcbiAgICAgICAgICBcInZhcmlhYmxlc1wiOiBbXG4gICAgICAgICAgICBcIipcIlxuICAgICAgICAgIF0sXG4gICAgICAgICAgXCJ0eXBlXCI6IFwicXVlcnlcIixcbiAgICAgICAgICBcInByZWZpeGVzXCI6IHt9XG4gICAgICAgIH0pO1xuICAgIH1cblxuICAgIHB1YmxpYyB2YXJpYWJsZXNBbGwoKTogRGVzY3JpYmVCdWlsZGVyXG4gICAge1xuICAgICAgICB0aGlzLmdldFF1ZXJ5KCkudmFyaWFibGVzID0gWyBcIipcIiBdO1xuXG4gICAgICAgIHJldHVybiB0aGlzO1xuICAgIH1cblxuICAgIHB1YmxpYyB2YXJpYWJsZXModmFyaWFibGVzOiBWYXJpYWJsZVtdKTogRGVzY3JpYmVCdWlsZGVyXG4gICAge1xuICAgICAgICB0aGlzLmdldFF1ZXJ5KCkudmFyaWFibGVzID0gdmFyaWFibGVzO1xuXG4gICAgICAgIHJldHVybiB0aGlzO1xuICAgIH1cblxuICAgIHB1YmxpYyB2YXJpYWJsZSh0ZXJtOiBUZXJtKTogRGVzY3JpYmVCdWlsZGVyXG4gICAge1xuICAgICAgICB0aGlzLmdldFF1ZXJ5KCkudmFyaWFibGVzLnB1c2goPFRlcm0gJiBcIipcIj50ZXJtKTtcblxuICAgICAgICByZXR1cm4gdGhpcztcbiAgICB9XG5cbiAgICBwdWJsaWMgaXNWYXJpYWJsZSh0ZXJtOiBUZXJtKTogYm9vbGVhblxuICAgIHtcbiAgICAgICAgcmV0dXJuIHRoaXMuZ2V0UXVlcnkoKS52YXJpYWJsZXMuaW5jbHVkZXMoPFRlcm0gJiBcIipcIj50ZXJtKTtcbiAgICB9XG5cbiAgICBwcm90ZWN0ZWQgZ2V0UXVlcnkoKTogRGVzY3JpYmVRdWVyeVxuICAgIHtcbiAgICAgICAgcmV0dXJuIDxEZXNjcmliZVF1ZXJ5PnN1cGVyLmdldFF1ZXJ5KCk7XG4gICAgfVxuXG4gICAgcHVibGljIGJ1aWxkKCk6IERlc2NyaWJlUXVlcnlcbiAgICB7XG4gICAgICAgIHJldHVybiA8RGVzY3JpYmVRdWVyeT5zdXBlci5idWlsZCgpO1xuICAgIH1cblxufSIsImltcG9ydCB7IFBhcnNlciwgUXVlcnksIEJhc2VRdWVyeSwgUGF0dGVybiwgRXhwcmVzc2lvbiwgQmxvY2tQYXR0ZXJuLCBGaWx0ZXJQYXR0ZXJuLCBCZ3BQYXR0ZXJuLCBHcmFwaFBhdHRlcm4sIEdyb3VwUGF0dGVybiwgT3BlcmF0aW9uRXhwcmVzc2lvbiwgVHJpcGxlLCBUZXJtLCBQcm9wZXJ0eVBhdGgsIEdlbmVyYXRvciwgU3BhcnFsR2VuZXJhdG9yIH0gZnJvbSAnc3BhcnFsanMnO1xuXG5leHBvcnQgY2xhc3MgUXVlcnlCdWlsZGVyXG57XG5cbiAgICBwcml2YXRlIHJlYWRvbmx5IHF1ZXJ5OiBRdWVyeTtcbiAgICBwcml2YXRlIHJlYWRvbmx5IGdlbmVyYXRvcjogU3BhcnFsR2VuZXJhdG9yO1xuXG4gICAgY29uc3RydWN0b3IocXVlcnk6IFF1ZXJ5KVxuICAgIHtcbiAgICAgICAgdGhpcy5xdWVyeSA9IHF1ZXJ5O1xuICAgICAgICB0aGlzLmdlbmVyYXRvciA9IG5ldyBHZW5lcmF0b3IoKTtcbiAgICAgICAgaWYgKCF0aGlzLnF1ZXJ5LnByZWZpeGVzKSB0aGlzLnF1ZXJ5LnByZWZpeGVzID0ge307XG4gICAgfVxuXG4gICAgcHVibGljIHN0YXRpYyBmcm9tUXVlcnkocXVlcnk6IFF1ZXJ5KTogUXVlcnlCdWlsZGVyXG4gICAge1xuICAgICAgICByZXR1cm4gbmV3IFF1ZXJ5QnVpbGRlcihxdWVyeSk7XG4gICAgfVxuXG4gICAgcHVibGljIHN0YXRpYyBmcm9tU3RyaW5nKHF1ZXJ5U3RyaW5nOiBzdHJpbmcsIHByZWZpeGVzPzogeyBbcHJlZml4OiBzdHJpbmddOiBzdHJpbmc7IH0gfCB1bmRlZmluZWQsIGJhc2VJUkk/OiBzdHJpbmcgfCB1bmRlZmluZWQpOiBRdWVyeUJ1aWxkZXJcbiAgICB7XG4gICAgICAgIGxldCBxdWVyeSA9IG5ldyBQYXJzZXIocHJlZml4ZXMsIGJhc2VJUkkpLnBhcnNlKHF1ZXJ5U3RyaW5nKTtcbiAgICAgICAgaWYgKCE8UXVlcnk+cXVlcnkpIHRocm93IG5ldyBFcnJvcihcIk9ubHkgU1BBUlFMIHF1ZXJpZXMgYXJlIHN1cHBvcnRlZCwgbm90IHVwZGF0ZXNcIik7XG5cbiAgICAgICAgcmV0dXJuIG5ldyBRdWVyeUJ1aWxkZXIoPFF1ZXJ5PnF1ZXJ5KTtcbiAgICB9XG5cbiAgICBwdWJsaWMgd2hlcmUocGF0dGVybjogUGF0dGVybltdKTogUXVlcnlCdWlsZGVyXG4gICAge1xuICAgICAgICB0aGlzLmdldFF1ZXJ5KCkud2hlcmUgPSBwYXR0ZXJuO1xuXG4gICAgICAgIHJldHVybiB0aGlzO1xuICAgIH1cblxuICAgIHB1YmxpYyB3aGVyZVBhdHRlcm4ocGF0dGVybjogUGF0dGVybik6IFF1ZXJ5QnVpbGRlclxuICAgIHtcbiAgICAgICAgaWYgKCF0aGlzLmdldFF1ZXJ5KCkud2hlcmUpIHRoaXMud2hlcmUoW10pO1xuICAgICAgICB0aGlzLmdldFF1ZXJ5KCkud2hlcmUhLnB1c2gocGF0dGVybik7XG5cbiAgICAgICAgcmV0dXJuIHRoaXM7XG4gICAgfVxuXG4gICAgcHVibGljIGJncFRyaXBsZXModHJpcGxlczogVHJpcGxlW10pOiBRdWVyeUJ1aWxkZXJcbiAgICB7XG4gICAgICAgIC8vIGlmIHRoZSBsYXN0IHBhdHRlcm4gaXMgQkdQLCBhcHBlbmQgdHJpcGxlcyB0byBpdCBpbnN0ZWFkIG9mIGFkZGluZyBuZXcgQkdQXG4gICAgICAgIGlmICh0aGlzLmdldFF1ZXJ5KCkud2hlcmUpXG4gICAgICAgIHtcbiAgICAgICAgICAgIGxldCBsYXN0UGF0dGVybiA9IHRoaXMuZ2V0UXVlcnkoKS53aGVyZSFbdGhpcy5nZXRRdWVyeSgpLndoZXJlIS5sZW5ndGggLSAxXTtcbiAgICAgICAgICAgIGlmIChsYXN0UGF0dGVybi50eXBlID09PSBcImJncFwiKVxuICAgICAgICAgICAge1xuICAgICAgICAgICAgICAgIGxhc3RQYXR0ZXJuLnRyaXBsZXMgPSBsYXN0UGF0dGVybi50cmlwbGVzLmNvbmNhdCh0cmlwbGVzKTtcbiAgICAgICAgICAgICAgICByZXR1cm4gdGhpcztcbiAgICAgICAgICAgIH1cbiAgICAgICAgfVxuXG4gICAgICAgIHJldHVybiB0aGlzLndoZXJlUGF0dGVybihRdWVyeUJ1aWxkZXIuYmdwKHRyaXBsZXMpKTtcbiAgICB9XG5cbiAgICBwdWJsaWMgYmdwVHJpcGxlKHRyaXBsZTogVHJpcGxlKTogUXVlcnlCdWlsZGVyXG4gICAge1xuICAgICAgICByZXR1cm4gdGhpcy5iZ3BUcmlwbGVzKFt0cmlwbGVdKTtcbiAgICB9XG5cbiAgICBwcm90ZWN0ZWQgZ2V0UXVlcnkoKTogUXVlcnlcbiAgICB7XG4gICAgICAgIHJldHVybiB0aGlzLnF1ZXJ5O1xuICAgIH1cblxuICAgIHByb3RlY3RlZCBnZXRHZW5lcmF0b3IoKTogU3BhcnFsR2VuZXJhdG9yXG4gICAge1xuICAgICAgICByZXR1cm4gdGhpcy5nZW5lcmF0b3I7XG4gICAgfVxuXG4gICAgcHVibGljIGJ1aWxkKCk6IFF1ZXJ5XG4gICAge1xuICAgICAgICByZXR1cm4gdGhpcy5nZXRRdWVyeSgpO1xuICAgIH1cblxuICAgIHB1YmxpYyB0b1N0cmluZygpOiBzdHJpbmdcbiAgICB7XG4gICAgICAgIHJldHVybiB0aGlzLmdldEdlbmVyYXRvcigpLnN0cmluZ2lmeSh0aGlzLmdldFF1ZXJ5KCkpO1xuICAgIH1cblxuICAgIHB1YmxpYyBzdGF0aWMgdGVybSh2YWx1ZTogc3RyaW5nKTogVGVybVxuICAgIHtcbiAgICAgICAgcmV0dXJuIDxUZXJtPnZhbHVlO1xuICAgIH1cblxuICAgIHB1YmxpYyBzdGF0aWMgdmFyKHZhck5hbWU6IHN0cmluZyk6IFRlcm1cbiAgICB7XG4gICAgICAgIHJldHVybiA8VGVybT4oXCI/XCIgKyB2YXJOYW1lKTtcbiAgICB9XG5cbiAgICBwdWJsaWMgc3RhdGljIGxpdGVyYWwodmFsdWU6IHN0cmluZyk6IFRlcm1cbiAgICB7XG4gICAgICAgIHJldHVybiA8VGVybT4oXCJcXFwiXCIgKyB2YWx1ZSArIFwiXFxcIlwiKTtcbiAgICB9XG5cbiAgICBwdWJsaWMgc3RhdGljIHR5cGVkTGl0ZXJhbCh2YWx1ZTogc3RyaW5nLCBkYXRhdHlwZTogc3RyaW5nKTogVGVybVxuICAgIHtcbiAgICAgICAgcmV0dXJuIDxUZXJtPihcIlxcXCJcIiArIHZhbHVlICsgXCJcXFwiXl5cIiArIGRhdGF0eXBlKTtcbiAgICB9XG5cbiAgICBwdWJsaWMgc3RhdGljIHVyaSh2YWx1ZTogc3RyaW5nKTogVGVybVxuICAgIHtcbiAgICAgICAgcmV0dXJuIDxUZXJtPnZhbHVlO1xuICAgIH1cblxuICAgIHB1YmxpYyBzdGF0aWMgdHJpcGxlKHN1YmplY3Q6IFRlcm0sIHByZWRpY2F0ZTogUHJvcGVydHlQYXRoIHwgVGVybSwgb2JqZWN0OiBUZXJtKTogVHJpcGxlXG4gICAge1xuICAgICAgICByZXR1cm4ge1xuICAgICAgICAgICAgXCJzdWJqZWN0XCI6IHN1YmplY3QsXG4gICAgICAgICAgICBcInByZWRpY2F0ZVwiOiBwcmVkaWNhdGUsXG4gICAgICAgICAgICBcIm9iamVjdFwiOiBvYmplY3RcbiAgICAgICAgfTtcbiAgICB9XG5cbiAgICBwdWJsaWMgc3RhdGljIGJncCh0cmlwbGVzOiBUcmlwbGVbXSk6IEJncFBhdHRlcm5cbiAgICB7XG4gICAgICAgIHJldHVybiB7XG4gICAgICAgICAgXCJ0eXBlXCI6IFwiYmdwXCIsXG4gICAgICAgICAgXCJ0cmlwbGVzXCI6IHRyaXBsZXNcbiAgICAgICAgfTtcbiAgICB9XG5cbiAgICBwdWJsaWMgc3RhdGljIGdyYXBoKG5hbWU6IHN0cmluZywgcGF0dGVybnM6IFBhdHRlcm5bXSk6IEdyYXBoUGF0dGVyblxuICAgIHtcbiAgICAgICAgcmV0dXJuIHtcbiAgICAgICAgICAgIFwidHlwZVwiOiBcImdyYXBoXCIsXG4gICAgICAgICAgICBcIm5hbWVcIjogPFRlcm0+bmFtZSxcbiAgICAgICAgICAgIFwicGF0dGVybnNcIjogcGF0dGVybnNcbiAgICAgICAgfVxuICAgIH1cblxuICAgIHB1YmxpYyBzdGF0aWMgZ3JvdXAocGF0dGVybnM6IFBhdHRlcm5bXSk6IEdyb3VwUGF0dGVyblxuICAgIHtcbiAgICAgICAgcmV0dXJuIHtcbiAgICAgICAgICAgIFwidHlwZVwiOiBcImdyb3VwXCIsXG4gICAgICAgICAgICBcInBhdHRlcm5zXCI6IHBhdHRlcm5zXG4gICAgICAgIH1cbiAgICB9XG5cbiAgICBwdWJsaWMgc3RhdGljIHVuaW9uKHBhdHRlcm5zOiBQYXR0ZXJuW10pOiBCbG9ja1BhdHRlcm5cbiAgICB7XG4gICAgICAgIHJldHVybiB7XG4gICAgICAgICAgICBcInR5cGVcIjogXCJ1bmlvblwiLFxuICAgICAgICAgICAgXCJwYXR0ZXJuc1wiOiBwYXR0ZXJuc1xuICAgICAgICB9XG4gICAgfVxuXG4gICAgcHVibGljIHN0YXRpYyBmaWx0ZXIoZXhwcmVzc2lvbjogRXhwcmVzc2lvbik6IEZpbHRlclBhdHRlcm5cbiAgICB7XG4gICAgICAgIHJldHVybiB7XG4gICAgICAgICAgICBcInR5cGVcIjogXCJmaWx0ZXJcIixcbiAgICAgICAgICAgIFwiZXhwcmVzc2lvblwiOiBleHByZXNzaW9uXG4gICAgICAgIH1cbiAgICB9XG5cbiAgICBwdWJsaWMgc3RhdGljIG9wZXJhdGlvbihvcGVyYXRvcjogc3RyaW5nLCBhcmdzOiBFeHByZXNzaW9uW10pOiBPcGVyYXRpb25FeHByZXNzaW9uXG4gICAge1xuICAgICAgICByZXR1cm4ge1xuICAgICAgICAgICAgXCJ0eXBlXCI6IFwib3BlcmF0aW9uXCIsXG4gICAgICAgICAgICBcIm9wZXJhdG9yXCI6IG9wZXJhdG9yLFxuICAgICAgICAgICAgXCJhcmdzXCI6IGFyZ3NcbiAgICAgICAgfTtcbiAgICB9XG5cbiAgICBwdWJsaWMgc3RhdGljIGluKHRlcm06IFRlcm0sIGxpc3Q6IFRlcm1bXSk6IE9wZXJhdGlvbkV4cHJlc3Npb25cbiAgICB7XG4gICAgICAgIHJldHVybiBRdWVyeUJ1aWxkZXIub3BlcmF0aW9uKFwiaW5cIiwgWyB0ZXJtLCBsaXN0IF0pO1xuICAgIH1cblxuICAgIHB1YmxpYyBzdGF0aWMgcmVnZXgodGVybTogVGVybSwgcGF0dGVybjogVGVybSwgY2FzZUluc2Vuc2l0aXZlPzogYm9vbGVhbik6IE9wZXJhdGlvbkV4cHJlc3Npb25cbiAgICB7XG4gICAgICAgIGxldCBleHByZXNzaW9uOiBPcGVyYXRpb25FeHByZXNzaW9uID0ge1xuICAgICAgICAgICAgXCJ0eXBlXCI6IFwib3BlcmF0aW9uXCIsXG4gICAgICAgICAgICBcIm9wZXJhdG9yXCI6IFwicmVnZXhcIixcbiAgICAgICAgICAgIFwiYXJnc1wiOiBbIHRlcm0sIDxUZXJtPihcIlxcXCJcIiArIHBhdHRlcm4gKyBcIlxcXCJcIikgXVxuICAgICAgICB9O1xuXG4gICAgICAgIGlmIChjYXNlSW5zZW5zaXRpdmUpIGV4cHJlc3Npb24uYXJncy5wdXNoKDxUZXJtPlwiXFxcImlcXFwiXCIpO1xuXG4gICAgICAgIHJldHVybiBleHByZXNzaW9uO1xuICAgIH1cblxuICAgIHB1YmxpYyBzdGF0aWMgZXEoYXJnMTogRXhwcmVzc2lvbiwgYXJnMjogRXhwcmVzc2lvbik6IE9wZXJhdGlvbkV4cHJlc3Npb25cbiAgICB7XG4gICAgICAgIHJldHVybiBRdWVyeUJ1aWxkZXIub3BlcmF0aW9uKFwiPVwiLCBbIGFyZzEsIGFyZzIgXSk7XG4gICAgfVxuXG4gICAgcHVibGljIHN0YXRpYyBzdHIoYXJnOiBFeHByZXNzaW9uKTogT3BlcmF0aW9uRXhwcmVzc2lvblxuICAgIHtcbiAgICAgICAgcmV0dXJuIFF1ZXJ5QnVpbGRlci5vcGVyYXRpb24oXCJzdHJcIiwgWyBhcmcgXSk7XG4gICAgfVxuXG59IiwiaW1wb3J0IHsgUGFyc2VyLCBTZWxlY3RRdWVyeSwgT3JkZXJpbmcsIFRlcm0sIFZhcmlhYmxlLCBFeHByZXNzaW9uIH0gZnJvbSAnc3BhcnFsanMnO1xuaW1wb3J0IHsgUXVlcnlCdWlsZGVyIH0gZnJvbSAnLi9RdWVyeUJ1aWxkZXInO1xuXG5leHBvcnQgY2xhc3MgU2VsZWN0QnVpbGRlciBleHRlbmRzIFF1ZXJ5QnVpbGRlclxue1xuXG4gICAgY29uc3RydWN0b3Ioc2VsZWN0OiBTZWxlY3RRdWVyeSlcbiAgICB7XG4gICAgICAgIHN1cGVyKHNlbGVjdCk7XG4gICAgfVxuXG4gICAgcHVibGljIHN0YXRpYyBmcm9tU3RyaW5nKHF1ZXJ5U3RyaW5nOiBzdHJpbmcsIHByZWZpeGVzPzogeyBbcHJlZml4OiBzdHJpbmddOiBzdHJpbmc7IH0gfCB1bmRlZmluZWQsIGJhc2VJUkk/OiBzdHJpbmcgfCB1bmRlZmluZWQpOiBTZWxlY3RCdWlsZGVyXG4gICAge1xuICAgICAgICBsZXQgcXVlcnkgPSBuZXcgUGFyc2VyKHByZWZpeGVzLCBiYXNlSVJJKS5wYXJzZShxdWVyeVN0cmluZyk7XG4gICAgICAgIGlmICghPFNlbGVjdFF1ZXJ5PnF1ZXJ5KSB0aHJvdyBuZXcgRXJyb3IoXCJPbmx5IFNFTEVDVCBpcyBzdXBwb3J0ZWRcIik7XG5cbiAgICAgICAgcmV0dXJuIG5ldyBTZWxlY3RCdWlsZGVyKDxTZWxlY3RRdWVyeT5xdWVyeSk7XG4gICAgfVxuXG4gICAgcHVibGljIHN0YXRpYyBmcm9tUXVlcnkocXVlcnk6IFNlbGVjdFF1ZXJ5KTogU2VsZWN0QnVpbGRlclxuICAgIHtcbiAgICAgICAgcmV0dXJuIG5ldyBTZWxlY3RCdWlsZGVyKHF1ZXJ5KTtcbiAgICB9XG5cbiAgICBwdWJsaWMgdmFyaWFibGVzQWxsKCk6IFNlbGVjdEJ1aWxkZXJcbiAgICB7XG4gICAgICAgIHRoaXMuZ2V0UXVlcnkoKS52YXJpYWJsZXMgPSBbIFwiKlwiIF07XG5cbiAgICAgICAgcmV0dXJuIHRoaXM7XG4gICAgfVxuXG4gICAgcHVibGljIHZhcmlhYmxlcyh2YXJpYWJsZXM6IFZhcmlhYmxlW10pOiBTZWxlY3RCdWlsZGVyXG4gICAge1xuICAgICAgICB0aGlzLmdldFF1ZXJ5KCkudmFyaWFibGVzID0gdmFyaWFibGVzO1xuXG4gICAgICAgIHJldHVybiB0aGlzO1xuICAgIH1cblxuICAgIHB1YmxpYyB2YXJpYWJsZSh0ZXJtOiBUZXJtKTogU2VsZWN0QnVpbGRlclxuICAgIHtcbiAgICAgICAgdGhpcy5nZXRRdWVyeSgpLnZhcmlhYmxlcy5wdXNoKDxUZXJtICYgXCIqXCI+dGVybSk7XG5cbiAgICAgICAgcmV0dXJuIHRoaXM7XG4gICAgfVxuXG4gICAgcHVibGljIGlzVmFyaWFibGUodGVybTogVGVybSk6IGJvb2xlYW5cbiAgICB7XG4gICAgICAgIHJldHVybiB0aGlzLmdldFF1ZXJ5KCkudmFyaWFibGVzLmluY2x1ZGVzKDxUZXJtICYgXCIqXCI+dGVybSk7XG4gICAgfVxuXG4gICAgcHVibGljIG9yZGVyQnkob3JkZXJpbmc6IE9yZGVyaW5nKTogU2VsZWN0QnVpbGRlclxuICAgIHtcbiAgICAgICAgaWYgKCF0aGlzLmdldFF1ZXJ5KCkub3JkZXIpIHRoaXMuZ2V0UXVlcnkoKS5vcmRlciA9IFtdO1xuICAgICAgICB0aGlzLmdldFF1ZXJ5KCkub3JkZXIhLnB1c2gob3JkZXJpbmcpO1xuXG4gICAgICAgIHJldHVybiB0aGlzO1xuICAgIH1cblxuICAgIHB1YmxpYyBvZmZzZXQob2Zmc2V0OiBudW1iZXIpOiBTZWxlY3RCdWlsZGVyXG4gICAge1xuICAgICAgICB0aGlzLmdldFF1ZXJ5KCkub2Zmc2V0ID0gb2Zmc2V0O1xuXG4gICAgICAgIHJldHVybiB0aGlzO1xuICAgIH1cblxuICAgIHB1YmxpYyBsaW1pdChsaW1pdDogbnVtYmVyKTogU2VsZWN0QnVpbGRlclxuICAgIHtcbiAgICAgICAgdGhpcy5nZXRRdWVyeSgpLmxpbWl0ID0gbGltaXQ7XG5cbiAgICAgICAgcmV0dXJuIHRoaXM7XG4gICAgfVxuXG4gICAgcHJvdGVjdGVkIGdldFF1ZXJ5KCk6IFNlbGVjdFF1ZXJ5XG4gICAge1xuICAgICAgICByZXR1cm4gPFNlbGVjdFF1ZXJ5PnN1cGVyLmdldFF1ZXJ5KCk7XG4gICAgfVxuXG4gICAgcHVibGljIGJ1aWxkKCk6IFNlbGVjdFF1ZXJ5XG4gICAge1xuICAgICAgICByZXR1cm4gPFNlbGVjdFF1ZXJ5PnN1cGVyLmJ1aWxkKCk7XG4gICAgfVxuXG4gICAgcHVibGljIHN0YXRpYyBvcmRlcmluZyhleHByOiBFeHByZXNzaW9uLCBkZXNjPzogYm9vbGVhbik6IE9yZGVyaW5nXG4gICAge1xuICAgICAgICBsZXQgb3JkZXJpbmc6IE9yZGVyaW5nID0ge1xuICAgICAgICAgIFwiZXhwcmVzc2lvblwiOiBleHByLFxuICAgICAgICB9O1xuXG4gICAgICAgIGlmIChkZXNjICE9PSB1bmRlZmluZWQgJiYgZGVzYyA9PSB0cnVlKSBvcmRlcmluZy5kZXNjZW5kaW5nID0gZGVzYztcblxuICAgICAgICByZXR1cm4gb3JkZXJpbmc7XG4gICAgfVxuXG59IiwiLy8gc2hpbSBmb3IgdXNpbmcgcHJvY2VzcyBpbiBicm93c2VyXG52YXIgcHJvY2VzcyA9IG1vZHVsZS5leHBvcnRzID0ge307XG5cbi8vIGNhY2hlZCBmcm9tIHdoYXRldmVyIGdsb2JhbCBpcyBwcmVzZW50IHNvIHRoYXQgdGVzdCBydW5uZXJzIHRoYXQgc3R1YiBpdFxuLy8gZG9uJ3QgYnJlYWsgdGhpbmdzLiAgQnV0IHdlIG5lZWQgdG8gd3JhcCBpdCBpbiBhIHRyeSBjYXRjaCBpbiBjYXNlIGl0IGlzXG4vLyB3cmFwcGVkIGluIHN0cmljdCBtb2RlIGNvZGUgd2hpY2ggZG9lc24ndCBkZWZpbmUgYW55IGdsb2JhbHMuICBJdCdzIGluc2lkZSBhXG4vLyBmdW5jdGlvbiBiZWNhdXNlIHRyeS9jYXRjaGVzIGRlb3B0aW1pemUgaW4gY2VydGFpbiBlbmdpbmVzLlxuXG52YXIgY2FjaGVkU2V0VGltZW91dDtcbnZhciBjYWNoZWRDbGVhclRpbWVvdXQ7XG5cbmZ1bmN0aW9uIGRlZmF1bHRTZXRUaW1vdXQoKSB7XG4gICAgdGhyb3cgbmV3IEVycm9yKCdzZXRUaW1lb3V0IGhhcyBub3QgYmVlbiBkZWZpbmVkJyk7XG59XG5mdW5jdGlvbiBkZWZhdWx0Q2xlYXJUaW1lb3V0ICgpIHtcbiAgICB0aHJvdyBuZXcgRXJyb3IoJ2NsZWFyVGltZW91dCBoYXMgbm90IGJlZW4gZGVmaW5lZCcpO1xufVxuKGZ1bmN0aW9uICgpIHtcbiAgICB0cnkge1xuICAgICAgICBpZiAodHlwZW9mIHNldFRpbWVvdXQgPT09ICdmdW5jdGlvbicpIHtcbiAgICAgICAgICAgIGNhY2hlZFNldFRpbWVvdXQgPSBzZXRUaW1lb3V0O1xuICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgY2FjaGVkU2V0VGltZW91dCA9IGRlZmF1bHRTZXRUaW1vdXQ7XG4gICAgICAgIH1cbiAgICB9IGNhdGNoIChlKSB7XG4gICAgICAgIGNhY2hlZFNldFRpbWVvdXQgPSBkZWZhdWx0U2V0VGltb3V0O1xuICAgIH1cbiAgICB0cnkge1xuICAgICAgICBpZiAodHlwZW9mIGNsZWFyVGltZW91dCA9PT0gJ2Z1bmN0aW9uJykge1xuICAgICAgICAgICAgY2FjaGVkQ2xlYXJUaW1lb3V0ID0gY2xlYXJUaW1lb3V0O1xuICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgY2FjaGVkQ2xlYXJUaW1lb3V0ID0gZGVmYXVsdENsZWFyVGltZW91dDtcbiAgICAgICAgfVxuICAgIH0gY2F0Y2ggKGUpIHtcbiAgICAgICAgY2FjaGVkQ2xlYXJUaW1lb3V0ID0gZGVmYXVsdENsZWFyVGltZW91dDtcbiAgICB9XG59ICgpKVxuZnVuY3Rpb24gcnVuVGltZW91dChmdW4pIHtcbiAgICBpZiAoY2FjaGVkU2V0VGltZW91dCA9PT0gc2V0VGltZW91dCkge1xuICAgICAgICAvL25vcm1hbCBlbnZpcm9tZW50cyBpbiBzYW5lIHNpdHVhdGlvbnNcbiAgICAgICAgcmV0dXJuIHNldFRpbWVvdXQoZnVuLCAwKTtcbiAgICB9XG4gICAgLy8gaWYgc2V0VGltZW91dCB3YXNuJ3QgYXZhaWxhYmxlIGJ1dCB3YXMgbGF0dGVyIGRlZmluZWRcbiAgICBpZiAoKGNhY2hlZFNldFRpbWVvdXQgPT09IGRlZmF1bHRTZXRUaW1vdXQgfHwgIWNhY2hlZFNldFRpbWVvdXQpICYmIHNldFRpbWVvdXQpIHtcbiAgICAgICAgY2FjaGVkU2V0VGltZW91dCA9IHNldFRpbWVvdXQ7XG4gICAgICAgIHJldHVybiBzZXRUaW1lb3V0KGZ1biwgMCk7XG4gICAgfVxuICAgIHRyeSB7XG4gICAgICAgIC8vIHdoZW4gd2hlbiBzb21lYm9keSBoYXMgc2NyZXdlZCB3aXRoIHNldFRpbWVvdXQgYnV0IG5vIEkuRS4gbWFkZG5lc3NcbiAgICAgICAgcmV0dXJuIGNhY2hlZFNldFRpbWVvdXQoZnVuLCAwKTtcbiAgICB9IGNhdGNoKGUpe1xuICAgICAgICB0cnkge1xuICAgICAgICAgICAgLy8gV2hlbiB3ZSBhcmUgaW4gSS5FLiBidXQgdGhlIHNjcmlwdCBoYXMgYmVlbiBldmFsZWQgc28gSS5FLiBkb2Vzbid0IHRydXN0IHRoZSBnbG9iYWwgb2JqZWN0IHdoZW4gY2FsbGVkIG5vcm1hbGx5XG4gICAgICAgICAgICByZXR1cm4gY2FjaGVkU2V0VGltZW91dC5jYWxsKG51bGwsIGZ1biwgMCk7XG4gICAgICAgIH0gY2F0Y2goZSl7XG4gICAgICAgICAgICAvLyBzYW1lIGFzIGFib3ZlIGJ1dCB3aGVuIGl0J3MgYSB2ZXJzaW9uIG9mIEkuRS4gdGhhdCBtdXN0IGhhdmUgdGhlIGdsb2JhbCBvYmplY3QgZm9yICd0aGlzJywgaG9wZnVsbHkgb3VyIGNvbnRleHQgY29ycmVjdCBvdGhlcndpc2UgaXQgd2lsbCB0aHJvdyBhIGdsb2JhbCBlcnJvclxuICAgICAgICAgICAgcmV0dXJuIGNhY2hlZFNldFRpbWVvdXQuY2FsbCh0aGlzLCBmdW4sIDApO1xuICAgICAgICB9XG4gICAgfVxuXG5cbn1cbmZ1bmN0aW9uIHJ1bkNsZWFyVGltZW91dChtYXJrZXIpIHtcbiAgICBpZiAoY2FjaGVkQ2xlYXJUaW1lb3V0ID09PSBjbGVhclRpbWVvdXQpIHtcbiAgICAgICAgLy9ub3JtYWwgZW52aXJvbWVudHMgaW4gc2FuZSBzaXR1YXRpb25zXG4gICAgICAgIHJldHVybiBjbGVhclRpbWVvdXQobWFya2VyKTtcbiAgICB9XG4gICAgLy8gaWYgY2xlYXJUaW1lb3V0IHdhc24ndCBhdmFpbGFibGUgYnV0IHdhcyBsYXR0ZXIgZGVmaW5lZFxuICAgIGlmICgoY2FjaGVkQ2xlYXJUaW1lb3V0ID09PSBkZWZhdWx0Q2xlYXJUaW1lb3V0IHx8ICFjYWNoZWRDbGVhclRpbWVvdXQpICYmIGNsZWFyVGltZW91dCkge1xuICAgICAgICBjYWNoZWRDbGVhclRpbWVvdXQgPSBjbGVhclRpbWVvdXQ7XG4gICAgICAgIHJldHVybiBjbGVhclRpbWVvdXQobWFya2VyKTtcbiAgICB9XG4gICAgdHJ5IHtcbiAgICAgICAgLy8gd2hlbiB3aGVuIHNvbWVib2R5IGhhcyBzY3Jld2VkIHdpdGggc2V0VGltZW91dCBidXQgbm8gSS5FLiBtYWRkbmVzc1xuICAgICAgICByZXR1cm4gY2FjaGVkQ2xlYXJUaW1lb3V0KG1hcmtlcik7XG4gICAgfSBjYXRjaCAoZSl7XG4gICAgICAgIHRyeSB7XG4gICAgICAgICAgICAvLyBXaGVuIHdlIGFyZSBpbiBJLkUuIGJ1dCB0aGUgc2NyaXB0IGhhcyBiZWVuIGV2YWxlZCBzbyBJLkUuIGRvZXNuJ3QgIHRydXN0IHRoZSBnbG9iYWwgb2JqZWN0IHdoZW4gY2FsbGVkIG5vcm1hbGx5XG4gICAgICAgICAgICByZXR1cm4gY2FjaGVkQ2xlYXJUaW1lb3V0LmNhbGwobnVsbCwgbWFya2VyKTtcbiAgICAgICAgfSBjYXRjaCAoZSl7XG4gICAgICAgICAgICAvLyBzYW1lIGFzIGFib3ZlIGJ1dCB3aGVuIGl0J3MgYSB2ZXJzaW9uIG9mIEkuRS4gdGhhdCBtdXN0IGhhdmUgdGhlIGdsb2JhbCBvYmplY3QgZm9yICd0aGlzJywgaG9wZnVsbHkgb3VyIGNvbnRleHQgY29ycmVjdCBvdGhlcndpc2UgaXQgd2lsbCB0aHJvdyBhIGdsb2JhbCBlcnJvci5cbiAgICAgICAgICAgIC8vIFNvbWUgdmVyc2lvbnMgb2YgSS5FLiBoYXZlIGRpZmZlcmVudCBydWxlcyBmb3IgY2xlYXJUaW1lb3V0IHZzIHNldFRpbWVvdXRcbiAgICAgICAgICAgIHJldHVybiBjYWNoZWRDbGVhclRpbWVvdXQuY2FsbCh0aGlzLCBtYXJrZXIpO1xuICAgICAgICB9XG4gICAgfVxuXG5cblxufVxudmFyIHF1ZXVlID0gW107XG52YXIgZHJhaW5pbmcgPSBmYWxzZTtcbnZhciBjdXJyZW50UXVldWU7XG52YXIgcXVldWVJbmRleCA9IC0xO1xuXG5mdW5jdGlvbiBjbGVhblVwTmV4dFRpY2soKSB7XG4gICAgaWYgKCFkcmFpbmluZyB8fCAhY3VycmVudFF1ZXVlKSB7XG4gICAgICAgIHJldHVybjtcbiAgICB9XG4gICAgZHJhaW5pbmcgPSBmYWxzZTtcbiAgICBpZiAoY3VycmVudFF1ZXVlLmxlbmd0aCkge1xuICAgICAgICBxdWV1ZSA9IGN1cnJlbnRRdWV1ZS5jb25jYXQocXVldWUpO1xuICAgIH0gZWxzZSB7XG4gICAgICAgIHF1ZXVlSW5kZXggPSAtMTtcbiAgICB9XG4gICAgaWYgKHF1ZXVlLmxlbmd0aCkge1xuICAgICAgICBkcmFpblF1ZXVlKCk7XG4gICAgfVxufVxuXG5mdW5jdGlvbiBkcmFpblF1ZXVlKCkge1xuICAgIGlmIChkcmFpbmluZykge1xuICAgICAgICByZXR1cm47XG4gICAgfVxuICAgIHZhciB0aW1lb3V0ID0gcnVuVGltZW91dChjbGVhblVwTmV4dFRpY2spO1xuICAgIGRyYWluaW5nID0gdHJ1ZTtcblxuICAgIHZhciBsZW4gPSBxdWV1ZS5sZW5ndGg7XG4gICAgd2hpbGUobGVuKSB7XG4gICAgICAgIGN1cnJlbnRRdWV1ZSA9IHF1ZXVlO1xuICAgICAgICBxdWV1ZSA9IFtdO1xuICAgICAgICB3aGlsZSAoKytxdWV1ZUluZGV4IDwgbGVuKSB7XG4gICAgICAgICAgICBpZiAoY3VycmVudFF1ZXVlKSB7XG4gICAgICAgICAgICAgICAgY3VycmVudFF1ZXVlW3F1ZXVlSW5kZXhdLnJ1bigpO1xuICAgICAgICAgICAgfVxuICAgICAgICB9XG4gICAgICAgIHF1ZXVlSW5kZXggPSAtMTtcbiAgICAgICAgbGVuID0gcXVldWUubGVuZ3RoO1xuICAgIH1cbiAgICBjdXJyZW50UXVldWUgPSBudWxsO1xuICAgIGRyYWluaW5nID0gZmFsc2U7XG4gICAgcnVuQ2xlYXJUaW1lb3V0KHRpbWVvdXQpO1xufVxuXG5wcm9jZXNzLm5leHRUaWNrID0gZnVuY3Rpb24gKGZ1bikge1xuICAgIHZhciBhcmdzID0gbmV3IEFycmF5KGFyZ3VtZW50cy5sZW5ndGggLSAxKTtcbiAgICBpZiAoYXJndW1lbnRzLmxlbmd0aCA+IDEpIHtcbiAgICAgICAgZm9yICh2YXIgaSA9IDE7IGkgPCBhcmd1bWVudHMubGVuZ3RoOyBpKyspIHtcbiAgICAgICAgICAgIGFyZ3NbaSAtIDFdID0gYXJndW1lbnRzW2ldO1xuICAgICAgICB9XG4gICAgfVxuICAgIHF1ZXVlLnB1c2gobmV3IEl0ZW0oZnVuLCBhcmdzKSk7XG4gICAgaWYgKHF1ZXVlLmxlbmd0aCA9PT0gMSAmJiAhZHJhaW5pbmcpIHtcbiAgICAgICAgcnVuVGltZW91dChkcmFpblF1ZXVlKTtcbiAgICB9XG59O1xuXG4vLyB2OCBsaWtlcyBwcmVkaWN0aWJsZSBvYmplY3RzXG5mdW5jdGlvbiBJdGVtKGZ1biwgYXJyYXkpIHtcbiAgICB0aGlzLmZ1biA9IGZ1bjtcbiAgICB0aGlzLmFycmF5ID0gYXJyYXk7XG59XG5JdGVtLnByb3RvdHlwZS5ydW4gPSBmdW5jdGlvbiAoKSB7XG4gICAgdGhpcy5mdW4uYXBwbHkobnVsbCwgdGhpcy5hcnJheSk7XG59O1xucHJvY2Vzcy50aXRsZSA9ICdicm93c2VyJztcbnByb2Nlc3MuYnJvd3NlciA9IHRydWU7XG5wcm9jZXNzLmVudiA9IHt9O1xucHJvY2Vzcy5hcmd2ID0gW107XG5wcm9jZXNzLnZlcnNpb24gPSAnJzsgLy8gZW1wdHkgc3RyaW5nIHRvIGF2b2lkIHJlZ2V4cCBpc3N1ZXNcbnByb2Nlc3MudmVyc2lvbnMgPSB7fTtcblxuZnVuY3Rpb24gbm9vcCgpIHt9XG5cbnByb2Nlc3Mub24gPSBub29wO1xucHJvY2Vzcy5hZGRMaXN0ZW5lciA9IG5vb3A7XG5wcm9jZXNzLm9uY2UgPSBub29wO1xucHJvY2Vzcy5vZmYgPSBub29wO1xucHJvY2Vzcy5yZW1vdmVMaXN0ZW5lciA9IG5vb3A7XG5wcm9jZXNzLnJlbW92ZUFsbExpc3RlbmVycyA9IG5vb3A7XG5wcm9jZXNzLmVtaXQgPSBub29wO1xucHJvY2Vzcy5wcmVwZW5kTGlzdGVuZXIgPSBub29wO1xucHJvY2Vzcy5wcmVwZW5kT25jZUxpc3RlbmVyID0gbm9vcDtcblxucHJvY2Vzcy5saXN0ZW5lcnMgPSBmdW5jdGlvbiAobmFtZSkgeyByZXR1cm4gW10gfVxuXG5wcm9jZXNzLmJpbmRpbmcgPSBmdW5jdGlvbiAobmFtZSkge1xuICAgIHRocm93IG5ldyBFcnJvcigncHJvY2Vzcy5iaW5kaW5nIGlzIG5vdCBzdXBwb3J0ZWQnKTtcbn07XG5cbnByb2Nlc3MuY3dkID0gZnVuY3Rpb24gKCkgeyByZXR1cm4gJy8nIH07XG5wcm9jZXNzLmNoZGlyID0gZnVuY3Rpb24gKGRpcikge1xuICAgIHRocm93IG5ldyBFcnJvcigncHJvY2Vzcy5jaGRpciBpcyBub3Qgc3VwcG9ydGVkJyk7XG59O1xucHJvY2Vzcy51bWFzayA9IGZ1bmN0aW9uKCkgeyByZXR1cm4gMDsgfTtcbiIsIm1vZHVsZS5leHBvcnRzID0gZnVuY3Rpb24obW9kdWxlKSB7XG5cdGlmICghbW9kdWxlLndlYnBhY2tQb2x5ZmlsbCkge1xuXHRcdG1vZHVsZS5kZXByZWNhdGUgPSBmdW5jdGlvbigpIHt9O1xuXHRcdG1vZHVsZS5wYXRocyA9IFtdO1xuXHRcdC8vIG1vZHVsZS5wYXJlbnQgPSB1bmRlZmluZWQgYnkgZGVmYXVsdFxuXHRcdGlmICghbW9kdWxlLmNoaWxkcmVuKSBtb2R1bGUuY2hpbGRyZW4gPSBbXTtcblx0XHRPYmplY3QuZGVmaW5lUHJvcGVydHkobW9kdWxlLCBcImxvYWRlZFwiLCB7XG5cdFx0XHRlbnVtZXJhYmxlOiB0cnVlLFxuXHRcdFx0Z2V0OiBmdW5jdGlvbigpIHtcblx0XHRcdFx0cmV0dXJuIG1vZHVsZS5sO1xuXHRcdFx0fVxuXHRcdH0pO1xuXHRcdE9iamVjdC5kZWZpbmVQcm9wZXJ0eShtb2R1bGUsIFwiaWRcIiwge1xuXHRcdFx0ZW51bWVyYWJsZTogdHJ1ZSxcblx0XHRcdGdldDogZnVuY3Rpb24oKSB7XG5cdFx0XHRcdHJldHVybiBtb2R1bGUuaTtcblx0XHRcdH1cblx0XHR9KTtcblx0XHRtb2R1bGUud2VicGFja1BvbHlmaWxsID0gMTtcblx0fVxuXHRyZXR1cm4gbW9kdWxlO1xufTtcbiIsImltcG9ydCB7IE1hcE92ZXJsYXkgfSBmcm9tICcuL21hcC9NYXBPdmVybGF5JztcbmltcG9ydCB7IFNlbGVjdEJ1aWxkZXIgfSBmcm9tICdAYXRvbWdyYXBoL1NQQVJRTEJ1aWxkZXIvY29tL2F0b21ncmFwaC9saW5rZWRkYXRhaHViL3F1ZXJ5L1NlbGVjdEJ1aWxkZXInO1xuaW1wb3J0IHsgRGVzY3JpYmVCdWlsZGVyIH0gZnJvbSAnQGF0b21ncmFwaC9TUEFSUUxCdWlsZGVyL2NvbS9hdG9tZ3JhcGgvbGlua2VkZGF0YWh1Yi9xdWVyeS9EZXNjcmliZUJ1aWxkZXInO1xuaW1wb3J0IHsgUXVlcnlCdWlsZGVyIH0gZnJvbSAnQGF0b21ncmFwaC9TUEFSUUxCdWlsZGVyL2NvbS9hdG9tZ3JhcGgvbGlua2VkZGF0YWh1Yi9xdWVyeS9RdWVyeUJ1aWxkZXInO1xuaW1wb3J0IHsgU2VsZWN0UXVlcnkgfSBmcm9tICdzcGFycWxqcyc7XG5pbXBvcnQgeyBVUkxCdWlsZGVyIH0gZnJvbSAnQGF0b21ncmFwaC9VUkxCdWlsZGVyL2NvbS9hdG9tZ3JhcGgvbGlua2VkZGF0YWh1Yi91dGlsL1VSTEJ1aWxkZXInO1xuXG5leHBvcnQgY2xhc3MgR2VvXG57XG5cbiAgICBwdWJsaWMgc3RhdGljIHJlYWRvbmx5IFJERl9OUyA9IFwiaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zI1wiO1xuICAgIHB1YmxpYyBzdGF0aWMgcmVhZG9ubHkgWFNEX05TID0gXCJodHRwOi8vd3d3LnczLm9yZy8yMDAxL1hNTFNjaGVtYSNcIjtcbiAgICBwdWJsaWMgc3RhdGljIHJlYWRvbmx5IEFQTFRfTlMgPSBcImh0dHBzOi8vdzNpZC5vcmcvYXRvbWdyYXBoL2xpbmtlZGRhdGFodWIvdGVtcGxhdGVzI1wiO1xuICAgIHB1YmxpYyBzdGF0aWMgcmVhZG9ubHkgR0VPX05TID0gXCJodHRwOi8vd3d3LnczLm9yZy8yMDAzLzAxL2dlby93Z3M4NF9wb3MjXCJcbiAgICBwdWJsaWMgc3RhdGljIHJlYWRvbmx5IEZPQUZfTlMgPSBcImh0dHA6Ly94bWxucy5jb20vZm9hZi8wLjEvXCI7XG5cbiAgICBwcml2YXRlIHJlYWRvbmx5IG1hcDogZ29vZ2xlLm1hcHMuTWFwO1xuICAgIHByaXZhdGUgcmVhZG9ubHkgZW5kcG9pbnQ6IFVSTDtcbiAgICBwcml2YXRlIHJlYWRvbmx5IHNlbGVjdDogc3RyaW5nO1xuICAgIHByaXZhdGUgcmVhZG9ubHkgZm9jdXNWYXJOYW1lOiBzdHJpbmc7XG4gICAgcHJpdmF0ZSByZWFkb25seSBncmFwaFZhck5hbWU/OiBzdHJpbmc7XG4gICAgcHJpdmF0ZSByZWFkb25seSBsb2FkZWRSZXNvdXJjZXM6IE1hcDxVUkwsIGJvb2xlYW4+O1xuICAgIHByaXZhdGUgbG9hZGVkQm91bmRzOiBnb29nbGUubWFwcy5MYXRMbmdCb3VuZHMgfCBudWxsIHwgdW5kZWZpbmVkO1xuICAgIHByaXZhdGUgbWFya2VyQm91bmRzOiBnb29nbGUubWFwcy5MYXRMbmdCb3VuZHM7XG4gICAgcHJpdmF0ZSBmaXRCb3VuZHM6IGJvb2xlYW47XG4gICAgcHJpdmF0ZSByZWFkb25seSBpY29uczogc3RyaW5nW107XG4gICAgcHJpdmF0ZSByZWFkb25seSB0eXBlSWNvbnM6IE1hcDxzdHJpbmcsIHN0cmluZz47XG5cbiAgICBjb25zdHJ1Y3RvcihtYXA6IGdvb2dsZS5tYXBzLk1hcCwgZW5kcG9pbnQ6IFVSTCwgc2VsZWN0OiBzdHJpbmcsIGZvY3VzVmFyTmFtZTogc3RyaW5nLCBncmFwaFZhck5hbWU/OiBzdHJpbmcpXG4gICAge1xuICAgICAgICB0aGlzLm1hcCA9IG1hcDtcbiAgICAgICAgdGhpcy5lbmRwb2ludCA9IGVuZHBvaW50O1xuICAgICAgICB0aGlzLnNlbGVjdCA9IHNlbGVjdDtcbiAgICAgICAgdGhpcy5mb2N1c1Zhck5hbWUgPSBmb2N1c1Zhck5hbWU7XG4gICAgICAgIHRoaXMuZ3JhcGhWYXJOYW1lID0gZ3JhcGhWYXJOYW1lO1xuICAgICAgICB0aGlzLm1hcmtlckJvdW5kcyA9IG5ldyBnb29nbGUubWFwcy5MYXRMbmdCb3VuZHMoKTtcbiAgICAgICAgdGhpcy5maXRCb3VuZHMgPSB0cnVlO1xuICAgICAgICB0aGlzLmxvYWRlZFJlc291cmNlcyA9IG5ldyBNYXA8VVJMLCBib29sZWFuPigpO1xuICAgICAgICB0aGlzLmljb25zID0gWyBcImh0dHBzOi8vbWFwcy5nb29nbGUuY29tL21hcGZpbGVzL21zL2ljb25zL2JsdWUtZG90LnBuZ1wiLFxuICAgICAgICAgICAgXCJodHRwczovL21hcHMuZ29vZ2xlLmNvbS9tYXBmaWxlcy9tcy9pY29ucy9yZWQtZG90LnBuZ1wiLFxuICAgICAgICAgICAgXCJodHRwczovL21hcHMuZ29vZ2xlLmNvbS9tYXBmaWxlcy9tcy9pY29ucy9wdXJwbGUtZG90LnBuZ1wiLFxuICAgICAgICAgICAgXCJodHRwczovL21hcHMuZ29vZ2xlLmNvbS9tYXBmaWxlcy9tcy9pY29ucy95ZWxsb3ctZG90LnBuZ1wiLFxuICAgICAgICAgICAgXCJodHRwczovL21hcHMuZ29vZ2xlLmNvbS9tYXBmaWxlcy9tcy9pY29ucy9ncmVlbi1kb3QucG5nXCIgXTtcbiAgICAgICAgdGhpcy50eXBlSWNvbnMgPSBuZXcgTWFwPHN0cmluZywgc3RyaW5nPigpO1xuICAgIH1cblxuICAgIHByaXZhdGUgZ2V0TWFwKCk6IGdvb2dsZS5tYXBzLk1hcFxuICAgIHtcbiAgICAgICAgcmV0dXJuIHRoaXMubWFwO1xuICAgIH07XG5cbiAgICBwcml2YXRlIGdldEVuZHBvaW50KCk6IFVSTFxuICAgIHtcbiAgICAgICAgcmV0dXJuIHRoaXMuZW5kcG9pbnQ7XG4gICAgfVxuXG4gICAgcHJpdmF0ZSBnZXRTZWxlY3QoKTogc3RyaW5nXG4gICAge1xuICAgICAgICByZXR1cm4gdGhpcy5zZWxlY3Q7XG4gICAgfVxuXG4gICAgcHJpdmF0ZSBnZXRGb2N1c1Zhck5hbWUoKTogc3RyaW5nXG4gICAge1xuICAgICAgICByZXR1cm4gdGhpcy5mb2N1c1Zhck5hbWU7XG4gICAgfTtcblxuICAgIHByaXZhdGUgZ2V0R3JhcGhWYXJOYW1lKCk6IHN0cmluZyB8IHVuZGVmaW5lZFxuICAgIHtcbiAgICAgICAgcmV0dXJuIHRoaXMuZ3JhcGhWYXJOYW1lO1xuICAgIH07XG5cbiAgICBwcml2YXRlIGdldExvYWRlZFJlc291cmNlcygpOiBNYXA8VVJMLCBib29sZWFuPlxuICAgIHtcbiAgICAgICAgcmV0dXJuIHRoaXMubG9hZGVkUmVzb3VyY2VzO1xuICAgIH1cblxuICAgIHB1YmxpYyBnZXRMb2FkZWRCb3VuZHMoKTogZ29vZ2xlLm1hcHMuTGF0TG5nQm91bmRzIHwgbnVsbCB8IHVuZGVmaW5lZFxuICAgIHtcbiAgICAgICAgcmV0dXJuIHRoaXMubG9hZGVkQm91bmRzO1xuICAgIH1cblxuICAgIHByaXZhdGUgc2V0TG9hZGVkQm91bmRzKGJvdW5kcz86IGdvb2dsZS5tYXBzLkxhdExuZ0JvdW5kcyB8IG51bGwgfCB1bmRlZmluZWQpXG4gICAge1xuICAgICAgICB0aGlzLmxvYWRlZEJvdW5kcyA9IGJvdW5kcztcbiAgICB9XG5cbiAgICBwdWJsaWMgZ2V0TWFya2VyQm91bmRzKCk6IGdvb2dsZS5tYXBzLkxhdExuZ0JvdW5kc1xuICAgIHtcbiAgICAgICAgcmV0dXJuIHRoaXMubWFya2VyQm91bmRzO1xuICAgIH1cblxuICAgIHB1YmxpYyBpc0ZpdEJvdW5kcygpOiBib29sZWFuXG4gICAge1xuICAgICAgICByZXR1cm4gdGhpcy5maXRCb3VuZHM7XG4gICAgfVxuXG4gICAgcHJpdmF0ZSBzZXRGaXRCb3VuZHMoZml0Qm91bmRzOiBib29sZWFuKTogdm9pZFxuICAgIHtcbiAgICAgICAgdGhpcy5maXRCb3VuZHMgPSBmaXRCb3VuZHM7XG4gICAgfVxuXG4gICAgcHVibGljIGdldEljb25zKCk6IHN0cmluZ1tdXG4gICAge1xuICAgICAgICByZXR1cm4gdGhpcy5pY29ucztcbiAgICB9XG5cbiAgICBwdWJsaWMgZ2V0VHlwZUljb25zKCk6IE1hcDxzdHJpbmcsIHN0cmluZz5cbiAgICB7XG4gICAgICAgIHJldHVybiB0aGlzLnR5cGVJY29ucztcbiAgICB9XG5cbiAgICBwcml2YXRlIGxvYWRNYXJrZXJzKHRoaXM6IEdlbywgcHJvbWlzZTogKHRoaXM6IHZvaWQsIHJkZlhtbDogRG9jdW1lbnQpID0+ICh2b2lkKSk6IHZvaWRcbiAgICB7XG4gICAgICAgIGlmICh0aGlzLmdldE1hcCgpLmdldEJvdW5kcygpID09IG51bGwpIHRocm93IEVycm9yKFwiTWFwIGJvdW5kcyBhcmUgbnVsbCBvciB1bmRlZmluZWRcIik7XG5cbiAgICAgICAgLy8gZG8gbm90IGxvYWQgbWFya2VycyBpZiB0aGUgbmV3IGJvdW5kcyBhcmUgd2l0aGluIGFscmVhZHkgbG9hZGVkIGJvdW5kc1xuICAgICAgICBpZiAodGhpcy5nZXRMb2FkZWRCb3VuZHMoKSAhPSBudWxsICYmXG4gICAgICAgICAgICAgICAgdGhpcy5nZXRMb2FkZWRCb3VuZHMoKSEuY29udGFpbnModGhpcy5nZXRNYXAoKS5nZXRCb3VuZHMoKSEuZ2V0Tm9ydGhFYXN0KCkpICYmIFxuICAgICAgICAgICAgICAgIHRoaXMuZ2V0TG9hZGVkQm91bmRzKCkhLmNvbnRhaW5zKHRoaXMuZ2V0TWFwKCkuZ2V0Qm91bmRzKCkhLmdldFNvdXRoV2VzdCgpKSlcbiAgICAgICAgICAgIHJldHVybjtcbiAgICAgICAgXG4gICAgICAgIGxldCBtYXJrZXJPdmVybGF5ID0gbmV3IE1hcE92ZXJsYXkodGhpcy5nZXRNYXAoKSwgXCJtYXJrZXItcHJvZ3Jlc3NcIik7XG4gICAgICAgIG1hcmtlck92ZXJsYXkuc2hvdygpO1xuXG4gICAgICAgIFByb21pc2UucmVzb2x2ZShTZWxlY3RCdWlsZGVyLmZyb21TdHJpbmcodGhpcy5nZXRTZWxlY3QoKSkuYnVpbGQoKSkuXG4gICAgICAgICAgICB0aGVuKHRoaXMuYnVpbGRRdWVyeSkuXG4gICAgICAgICAgICB0aGVuKHRoaXMuYnVpbGRRdWVyeVVSTCkuXG4gICAgICAgICAgICB0aGVuKHVybCA9PiB1cmwudG9TdHJpbmcoKSkuXG4gICAgICAgICAgICB0aGVuKHRoaXMucmVxdWVzdFJERlhNTCkuXG4gICAgICAgICAgICB0aGVuKHJlc3BvbnNlID0+XG4gICAgICAgICAgICB7XG4gICAgICAgICAgICAgICAgaWYocmVzcG9uc2Uub2spIHJldHVybiByZXNwb25zZS50ZXh0KCk7XG5cbiAgICAgICAgICAgICAgICB0aHJvdyBuZXcgRXJyb3IoXCJDb3VsZCBub3QgbG9hZCBSREYvWE1MIHJlc3BvbnNlIGZyb20gJ1wiICsgcmVzcG9uc2UudXJsICsgXCInXCIpO1xuICAgICAgICAgICAgfSkuXG4gICAgICAgICAgICB0aGVuKHRoaXMucGFyc2VYTUwpLlxuICAgICAgICAgICAgdGhlbihwcm9taXNlKS5cbiAgICAgICAgICAgIHRoZW4oKCkgPT5cbiAgICAgICAgICAgIHtcbiAgICAgICAgICAgICAgICB0aGlzLnNldExvYWRlZEJvdW5kcyh0aGlzLmdldE1hcCgpLmdldEJvdW5kcygpKTtcbiAgICAgICAgICAgICAgICBpZiAodGhpcy5pc0ZpdEJvdW5kcygpICYmICF0aGlzLmdldE1hcmtlckJvdW5kcygpLmlzRW1wdHkoKSlcbiAgICAgICAgICAgICAgICB7XG4gICAgICAgICAgICAgICAgICAgIHRoaXMuZ2V0TWFwKCkuZml0Qm91bmRzKHRoaXMuZ2V0TWFya2VyQm91bmRzKCkpO1xuICAgICAgICAgICAgICAgICAgICB0aGlzLnNldEZpdEJvdW5kcyhmYWxzZSk7IC8vIGRvIG5vdCBmaXQgYm91bmRzIGFmdGVyIHRoZSBmaXJzdCBsb2FkXG4gICAgICAgICAgICAgICAgfVxuXG4gICAgICAgICAgICAgICAgbWFya2VyT3ZlcmxheS5oaWRlKCk7XG4gICAgICAgICAgICB9KS5cbiAgICAgICAgICAgIGNhdGNoKGVycm9yID0+XG4gICAgICAgICAgICB7XG4gICAgICAgICAgICAgICAgY29uc29sZS5sb2coJ0hUVFAgcmVxdWVzdCBmYWlsZWQ6ICcsIGVycm9yLm1lc3NhZ2UpO1xuICAgICAgICAgICAgfSk7XG4gICAgfVxuXG4gICAgcHVibGljIGFkZE1hcmtlcnMgPSAocmRmWG1sOiBYTUxEb2N1bWVudCkgPT5cbiAgICB7ICAgXG4gICAgICAgIGxldCBkZXNjcmlwdGlvbnMgPSByZGZYbWwuZ2V0RWxlbWVudHNCeVRhZ05hbWVOUyhHZW8uUkRGX05TLCBcIkRlc2NyaXB0aW9uXCIpO1xuICAgICAgICBmb3IgKGxldCBkZXNjcmlwdGlvbiBvZiA8YW55PmRlc2NyaXB0aW9ucylcbiAgICAgICAge1xuICAgICAgICAgICAgaWYgKGRlc2NyaXB0aW9uLmhhc0F0dHJpYnV0ZU5TKEdlby5SREZfTlMsIFwiYWJvdXRcIikgfHwgZGVzY3JpcHRpb24uaGFzQXR0cmlidXRlTlMoR2VvLlJERl9OUywgXCJub2RlSURcIikpXG4gICAgICAgICAgICB7XG4gICAgICAgICAgICAgICAgbGV0IHVyaSA9IGRlc2NyaXB0aW9uLmdldEF0dHJpYnV0ZU5TKEdlby5SREZfTlMsIFwiYWJvdXRcIik7XG4gICAgICAgICAgICAgICAgbGV0IGJub2RlID0gZGVzY3JpcHRpb24uZ2V0QXR0cmlidXRlTlMoR2VvLlJERl9OUywgXCJub2RlSURcIik7XG4gICAgICAgICAgICAgICAgbGV0IGtleSA9IG51bGw7XG4gICAgICAgICAgICAgICAgaWYgKGJub2RlICE9PSBudWxsKSBrZXkgPSByZGZYbWwuZG9jdW1lbnRVUkkgKyBcIiNcIiArIGJub2RlO1xuICAgICAgICAgICAgICAgIGVsc2Uga2V5ID0gdXJpO1xuICAgICAgICAgICAgICAgIFxuICAgICAgICAgICAgICAgIGlmICghdGhpcy5nZXRMb2FkZWRSZXNvdXJjZXMoKS5oYXMoa2V5KSlcbiAgICAgICAgICAgICAgICB7XG4gICAgICAgICAgICAgICAgICAgIGxldCBsYXRFbGVtcyA9IGRlc2NyaXB0aW9uLmdldEVsZW1lbnRzQnlUYWdOYW1lTlMoR2VvLkdFT19OUywgXCJsYXRcIik7XG4gICAgICAgICAgICAgICAgICAgIGxldCBsb25nRWxlbXMgPSBkZXNjcmlwdGlvbi5nZXRFbGVtZW50c0J5VGFnTmFtZU5TKEdlby5HRU9fTlMsIFwibG9uZ1wiKTtcbiAgICAgICAgICAgICAgICAgICAgXG4gICAgICAgICAgICAgICAgICAgIGlmIChsYXRFbGVtcy5sZW5ndGggPiAwICYmIGxvbmdFbGVtcy5sZW5ndGggPiAwKVxuICAgICAgICAgICAgICAgICAgICB7XG4gICAgICAgICAgICAgICAgICAgICAgICB0aGlzLmdldExvYWRlZFJlc291cmNlcygpLnNldChrZXksIHRydWUpOyAvLyBtYXJrIHJlc291cmNlIGFzIGxvYWRlZFxuXG4gICAgICAgICAgICAgICAgICAgICAgICBsZXQgaWNvbiA9IG51bGw7XG4gICAgICAgICAgICAgICAgICAgICAgICBsZXQgdHlwZSA9IG51bGw7XG4gICAgICAgICAgICAgICAgICAgICAgICBsZXQgdHlwZUVsZW1zID0gZGVzY3JpcHRpb24uZ2V0RWxlbWVudHNCeVRhZ05hbWVOUyhHZW8uUkRGX05TLCBcInR5cGVcIik7XG4gICAgICAgICAgICAgICAgICAgICAgICBpZiAodHlwZUVsZW1zLmxlbmd0aCA+IDApXG4gICAgICAgICAgICAgICAgICAgICAgICB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdHlwZSA9IHR5cGVFbGVtc1swXS5nZXRBdHRyaWJ1dGVOUyhHZW8uUkRGX05TLCBcInJlc291cmNlXCIpO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGlmICghdGhpcy5nZXRUeXBlSWNvbnMoKS5oYXModHlwZSkpXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAvLyBpY29ucyBnZXQgcmVjeWNsZWQgd2hlbiAjIG9mIGRpZmZlcmVudCB0eXBlcyBpbiByZXNwb25zZSA+ICMgb2YgaWNvbnNcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgbGV0IGljb25JbmRleCA9IHRoaXMuZ2V0VHlwZUljb25zKCkuc2l6ZSAlIHRoaXMuZ2V0SWNvbnMoKS5sZW5ndGg7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGljb24gPSB0aGlzLmdldEljb25zKClbaWNvbkluZGV4XTtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdGhpcy5nZXRUeXBlSWNvbnMoKS5zZXQodHlwZSwgaWNvbik7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGVsc2UgaWNvbiA9IHRoaXMuZ2V0VHlwZUljb25zKCkuZ2V0KHR5cGUpO1xuICAgICAgICAgICAgICAgICAgICAgICAgfVxuXG4gICAgICAgICAgICAgICAgICAgICAgICBsZXQgbGF0TG5nID0gbmV3IGdvb2dsZS5tYXBzLkxhdExuZyhsYXRFbGVtc1swXS50ZXh0Q29udGVudCwgbG9uZ0VsZW1zWzBdLnRleHRDb250ZW50KTtcbiAgICAgICAgICAgICAgICAgICAgICAgIHRoaXMuZ2V0TWFya2VyQm91bmRzKCkuZXh0ZW5kKGxhdExuZyk7XG4gICAgICAgICAgICAgICAgICAgICAgICBsZXQgbWFya2VyQ29uZmlnID0gPGdvb2dsZS5tYXBzLk1hcmtlck9wdGlvbnM+e1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIFwicG9zaXRpb25cIjogbGF0TG5nLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIC8vIFwibGFiZWxcIjogbGFiZWwsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgXCJtYXBcIjogdGhpcy5nZXRNYXAoKVxuICAgICAgICAgICAgICAgICAgICAgICAgfTtcbiAgICAgICAgICAgICAgICAgICAgICAgIGxldCB0aXRsZUVsZW1zID0gZGVzY3JpcHRpb24uZ2V0RWxlbWVudHNCeVRhZ05hbWVOUyhcImh0dHA6Ly9wdXJsLm9yZy9kYy90ZXJtcy9cIiwgXCJ0aXRsZVwiKTsgLy8gVE8tRE86IGNhbGwgYWM6bGFiZWwoKSB2aWEgU2F4b25KUy5YUGF0aC5ldmFsdWF0ZSgpP1xuICAgICAgICAgICAgICAgICAgICAgICAgaWYgKHRpdGxlRWxlbXMubGVuZ3RoID4gMCkgbWFya2VyQ29uZmlnLnRpdGxlID0gdGl0bGVFbGVtc1swXS50ZXh0Q29udGVudDtcblxuICAgICAgICAgICAgICAgICAgICAgICAgbGV0IG1hcmtlciA9IG5ldyBnb29nbGUubWFwcy5NYXJrZXIobWFya2VyQ29uZmlnKTtcbiAgICAgICAgICAgICAgICAgICAgICAgIGlmIChpY29uICE9IG51bGwpIG1hcmtlci5zZXRJY29uKGljb24pO1xuICAgICAgICAgICAgICAgICAgICAgICAgXG4gICAgICAgICAgICAgICAgICAgICAgICAvLyBwb3BvdXQgSW5mb1dpbmRvdyBmb3IgdGhlIHRvcGljIG9mIGN1cnJlbnQgZG9jdW1lbnQgKHNhbWUgYXMgb24gY2xpY2spXG4gICAgICAgICAgICAgICAgICAgICAgICBsZXQgZG9jcyA9IGRlc2NyaXB0aW9uLmdldEVsZW1lbnRzQnlUYWdOYW1lTlMoR2VvLkZPQUZfTlMsIFwiaXNQcmltYXJ5VG9waWNPZlwiKTsgLy8gdHJ5IHRvIGdldCBmb2FmOmlzUHJpbWFyeVRvcGljT2YgdmFsdWUgZmlyc3RcbiAgICAgICAgICAgICAgICAgICAgICAgIGlmIChkb2NzLmxlbmd0aCA9PT0gMCkgZG9jcyA9IGRlc2NyaXB0aW9uLmdldEVsZW1lbnRzQnlUYWdOYW1lTlMoR2VvLkZPQUZfTlMsIFwicGFnZVwiKTsgLy8gZmFsbGJhY2sgdG8gZm9hZjpwYWdlIGFzIGEgc2Vjb25kIG9wdGlvblxuXG4gICAgICAgICAgICAgICAgICAgICAgICBpZiAoZG9jcy5sZW5ndGggPiAwICYmIGRvY3NbMF0uaGFzQXR0cmlidXRlTlMoR2VvLlJERl9OUywgXCJyZXNvdXJjZVwiKSlcbiAgICAgICAgICAgICAgICAgICAgICAgIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBsZXQgZG9jVXJpID0gZG9jc1swXS5nZXRBdHRyaWJ1dGVOUyhHZW8uUkRGX05TLCBcInJlc291cmNlXCIpO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHRoaXMuYmluZE1hcmtlckNsaWNrKG1hcmtlciwgZG9jVXJpKTsgLy8gYmluZCBsb2FkSW5mb1dpbmRvd0hUTUwoKSB0byBtYXJrZXIgb25jbGlja1xuICAgICAgICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgfVxuICAgICAgICB9XG4gICAgfVxuXG4gICAgcHJvdGVjdGVkIGJpbmRNYXJrZXJDbGljayhtYXJrZXI6IGdvb2dsZS5tYXBzLk1hcmtlciwgdXJsOiBzdHJpbmcpOiB2b2lkXG4gICAge1xuICAgICAgICBsZXQgcmVuZGVySW5mb1dpbmRvdyA9IChldmVudDogZ29vZ2xlLm1hcHMuTWFwTW91c2VFdmVudCkgPT5cbiAgICAgICAge1xuICAgICAgICAgICAgbGV0IG92ZXJsYXkgPSBuZXcgTWFwT3ZlcmxheSh0aGlzLmdldE1hcCgpLCBcImluZm93aW5kb3ctcHJvZ3Jlc3NcIik7XG4gICAgICAgICAgICBvdmVybGF5LnNob3coKTtcbiAgICAgICAgICAgIFxuICAgICAgICAgICAgUHJvbWlzZS5yZXNvbHZlKHVybCkuXG4gICAgICAgICAgICAgICAgdGhlbih0aGlzLmJ1aWxkSW5mb1VSTCkuXG4gICAgICAgICAgICAgICAgdGhlbih1cmwgPT4gdXJsLnRvU3RyaW5nKCkpLlxuICAgICAgICAgICAgICAgIHRoZW4odGhpcy5yZXF1ZXN0SFRNTCkuXG4gICAgICAgICAgICAgICAgdGhlbihyZXNwb25zZSA9PiBcbiAgICAgICAgICAgICAgICB7XG4gICAgICAgICAgICAgICAgICAgIGlmKHJlc3BvbnNlLm9rKSByZXR1cm4gcmVzcG9uc2UudGV4dCgpO1xuXG4gICAgICAgICAgICAgICAgICAgIHRocm93IG5ldyBFcnJvcihcIkNvdWxkIG5vdCBsb2FkIEhUTUwgcmVzcG9uc2UgZnJvbSAnXCIgKyByZXNwb25zZS51cmwgKyBcIidcIik7XG4gICAgICAgICAgICAgICAgfSkuXG4gICAgICAgICAgICAgICAgdGhlbih0aGlzLnBhcnNlSFRNTCkuXG4gICAgICAgICAgICAgICAgdGhlbihodG1sID0+XG4gICAgICAgICAgICAgICAge1xuICAgICAgICAgICAgICAgICAgICAvLyByZW5kZXIgZmlyc3QgY2hpbGQgb2YgPGJvZHk+IGFzIEluZm9XaW5kb3cgY29udGVudFxuICAgICAgICAgICAgICAgICAgICBsZXQgaW5mb0NvbnRlbnQgPSBodG1sLmdldEVsZW1lbnRzQnlUYWdOYW1lTlMoXCJodHRwOi8vd3d3LnczLm9yZy8xOTk5L3hodG1sXCIsIFwiYm9keVwiKVswXS5jaGlsZHJlblswXTtcblxuICAgICAgICAgICAgICAgICAgICBsZXQgaW5mb1dpbmRvdyA9IG5ldyBnb29nbGUubWFwcy5JbmZvV2luZG93KHsgXCJjb250ZW50XCIgOiBpbmZvQ29udGVudCB9KTtcbiAgICAgICAgICAgICAgICAgICAgb3ZlcmxheS5oaWRlKCk7XG4gICAgICAgICAgICAgICAgICAgIGluZm9XaW5kb3cub3Blbih0aGlzLmdldE1hcCgpLCBtYXJrZXIpO1xuICAgICAgICAgICAgICAgIH0pLlxuICAgICAgICAgICAgICAgIGNhdGNoKGVycm9yID0+XG4gICAgICAgICAgICAgICAge1xuICAgICAgICAgICAgICAgICAgICBjb25zb2xlLmxvZygnSFRUUCByZXF1ZXN0IGZhaWxlZDogJywgZXJyb3IubWVzc2FnZSk7XG4gICAgICAgICAgICAgICAgfSk7XG4gICAgICAgIH1cblxuICAgICAgICBtYXJrZXIuYWRkTGlzdGVuZXIoXCJjbGlja1wiLCByZW5kZXJJbmZvV2luZG93KTtcbiAgICB9XG5cbiAgICBwcm90ZWN0ZWQgYnVpbGRHZW9Cb3VuZGVkUXVlcnkoc2VsZWN0UXVlcnk6IFNlbGVjdFF1ZXJ5LCBlYXN0OiBudW1iZXIsIG5vcnRoOiBudW1iZXIsIHNvdXRoOiBudW1iZXIsIHdlc3Q6IG51bWJlcik6IFF1ZXJ5QnVpbGRlclxuICAgIHtcbiAgICAgICAgbGV0IGJvdW5kc1BhdHRlcm4gPSBbXG4gICAgICAgICAgICBRdWVyeUJ1aWxkZXIuYmdwKFxuICAgICAgICAgICAgICAgIFtcbiAgICAgICAgICAgICAgICAgICAgUXVlcnlCdWlsZGVyLnRyaXBsZShRdWVyeUJ1aWxkZXIudmFyKHRoaXMuZ2V0Rm9jdXNWYXJOYW1lKCkpLCBRdWVyeUJ1aWxkZXIudXJpKEdlby5HRU9fTlMgKyBcImxhdFwiKSwgUXVlcnlCdWlsZGVyLnZhcihcImxhdFwiKSksXG4gICAgICAgICAgICAgICAgICAgIFF1ZXJ5QnVpbGRlci50cmlwbGUoUXVlcnlCdWlsZGVyLnZhcih0aGlzLmdldEZvY3VzVmFyTmFtZSgpKSwgUXVlcnlCdWlsZGVyLnVyaShHZW8uR0VPX05TICsgXCJsb25nXCIpLCBRdWVyeUJ1aWxkZXIudmFyKFwibG9uZ1wiKSlcbiAgICAgICAgICAgICAgICBdKSxcbiAgICAgICAgICAgIFF1ZXJ5QnVpbGRlci5maWx0ZXIoUXVlcnlCdWlsZGVyLm9wZXJhdGlvbihcIjxcIiwgWyBRdWVyeUJ1aWxkZXIudmFyKFwibG9uZ1wiKSwgUXVlcnlCdWlsZGVyLnR5cGVkTGl0ZXJhbChlYXN0LnRvU3RyaW5nKCksIEdlby5YU0RfTlMgKyBcImRlY2ltYWxcIikgXSkpLFxuICAgICAgICAgICAgUXVlcnlCdWlsZGVyLmZpbHRlcihRdWVyeUJ1aWxkZXIub3BlcmF0aW9uKFwiPFwiLCBbIFF1ZXJ5QnVpbGRlci52YXIoXCJsYXRcIiksIFF1ZXJ5QnVpbGRlci50eXBlZExpdGVyYWwobm9ydGgudG9TdHJpbmcoKSwgR2VvLlhTRF9OUyArIFwiZGVjaW1hbFwiKSBdKSksXG4gICAgICAgICAgICBRdWVyeUJ1aWxkZXIuZmlsdGVyKFF1ZXJ5QnVpbGRlci5vcGVyYXRpb24oXCI+XCIsIFsgUXVlcnlCdWlsZGVyLnZhcihcImxhdFwiKSwgUXVlcnlCdWlsZGVyLnR5cGVkTGl0ZXJhbChzb3V0aC50b1N0cmluZygpLCBHZW8uWFNEX05TICsgXCJkZWNpbWFsXCIpIF0pKSxcbiAgICAgICAgICAgIFF1ZXJ5QnVpbGRlci5maWx0ZXIoUXVlcnlCdWlsZGVyLm9wZXJhdGlvbihcIj5cIiwgWyBRdWVyeUJ1aWxkZXIudmFyKFwibG9uZ1wiKSwgUXVlcnlCdWlsZGVyLnR5cGVkTGl0ZXJhbCh3ZXN0LnRvU3RyaW5nKCksIEdlby5YU0RfTlMgKyBcImRlY2ltYWxcIikgXSkpXG4gICAgICAgIF07XG5cbiAgICAgICAgbGV0IGJ1aWxkZXIgPSBEZXNjcmliZUJ1aWxkZXIubmV3KCkuXG4gICAgICAgICAgICB2YXJpYWJsZXMoWyBRdWVyeUJ1aWxkZXIudmFyKHRoaXMuZ2V0Rm9jdXNWYXJOYW1lKCkpIF0pLlxuICAgICAgICAgICAgd2hlcmVQYXR0ZXJuKFF1ZXJ5QnVpbGRlci5ncm91cChbIHNlbGVjdFF1ZXJ5IF0pKTtcblxuICAgICAgICBpZiAodGhpcy5nZXRHcmFwaFZhck5hbWUoKSAhPT0gdW5kZWZpbmVkKVxuICAgICAgICAgICAgcmV0dXJuIGJ1aWxkZXIud2hlcmVQYXR0ZXJuKFF1ZXJ5QnVpbGRlci51bmlvbihbIFF1ZXJ5QnVpbGRlci5ncm91cChib3VuZHNQYXR0ZXJuKSwgUXVlcnlCdWlsZGVyLmdyYXBoKFF1ZXJ5QnVpbGRlci52YXIodGhpcy5nZXRHcmFwaFZhck5hbWUoKSEpLCBib3VuZHNQYXR0ZXJuKSBdKSlcbiAgICAgICAgZWxzZVxuICAgICAgICAgICAgcmV0dXJuIGJ1aWxkZXIud2hlcmVQYXR0ZXJuKFF1ZXJ5QnVpbGRlci5ncm91cChib3VuZHNQYXR0ZXJuKSk7XG4gICAgfVxuXG4gICAgcHVibGljIGJ1aWxkUXVlcnkgPSAoc2VsZWN0UXVlcnk6IFNlbGVjdFF1ZXJ5KTogc3RyaW5nID0+XG4gICAge1xuICAgICAgICByZXR1cm4gdGhpcy5idWlsZEdlb0JvdW5kZWRRdWVyeShzZWxlY3RRdWVyeSxcbiAgICAgICAgICAgIHRoaXMuZ2V0TWFwKCkuZ2V0Qm91bmRzKCkhLmdldE5vcnRoRWFzdCgpLmxuZygpLFxuICAgICAgICAgICAgdGhpcy5nZXRNYXAoKS5nZXRCb3VuZHMoKSEuZ2V0Tm9ydGhFYXN0KCkubGF0KCksXG4gICAgICAgICAgICB0aGlzLmdldE1hcCgpLmdldEJvdW5kcygpIS5nZXRTb3V0aFdlc3QoKS5sYXQoKSxcbiAgICAgICAgICAgIHRoaXMuZ2V0TWFwKCkuZ2V0Qm91bmRzKCkhLmdldFNvdXRoV2VzdCgpLmxuZygpKS5cbiAgICAgICAgICAgIHRvU3RyaW5nKCk7XG4gICAgfVxuXG4gICAgcHVibGljIGJ1aWxkUXVlcnlVUkwgPSAocXVlcnlTdHJpbmc6IHN0cmluZyk6IFVSTCA9PlxuICAgIHtcbiAgICAgICAgcmV0dXJuIFVSTEJ1aWxkZXIuZnJvbVVSTCh0aGlzLmdldEVuZHBvaW50KCkpLlxuICAgICAgICAgICAgc2VhcmNoUGFyYW0oXCJxdWVyeVwiLCBxdWVyeVN0cmluZykuXG4gICAgICAgICAgICBidWlsZCgpO1xuICAgIH1cblxuICAgIHB1YmxpYyBidWlsZEluZm9VUkwodXJsOiBzdHJpbmcpOiBVUkxcbiAgICB7XG4gICAgICAgIHJldHVybiBVUkxCdWlsZGVyLmZyb21TdHJpbmcodXJsKS5cbiAgICAgICAgICAgIHNlYXJjaFBhcmFtKFwibW9kZVwiLCBHZW8uQVBMVF9OUyArIFwiSW5mb1dpbmRvd01vZGVcIikuXG4gICAgICAgICAgICBoYXNoKG51bGwpLlxuICAgICAgICAgICAgYnVpbGQoKTtcbiAgICB9XG5cbiAgICBwdWJsaWMgcmVxdWVzdFJERlhNTCA9ICh1cmw6IHN0cmluZyk6IFByb21pc2U8UmVzcG9uc2U+ID0+XG4gICAge1xuICAgICAgICByZXR1cm4gZmV0Y2gobmV3IFJlcXVlc3QodXJsLCB7IFwiaGVhZGVyc1wiOiB7IFwiQWNjZXB0XCI6IFwiYXBwbGljYXRpb24vcmRmK3htbFwiIH0gfSApKTtcbiAgICB9XG5cbiAgICBwdWJsaWMgcmVxdWVzdEhUTUwgPSAodXJsOiBzdHJpbmcpOiBQcm9taXNlPFJlc3BvbnNlPiA9PlxuICAgIHtcbiAgICAgICAgcmV0dXJuIGZldGNoKG5ldyBSZXF1ZXN0KHVybCwgeyBcImhlYWRlcnNcIjogeyBcIkFjY2VwdFwiOiBcInRleHQvaHRtbCwqLyo7cT0wLjhcIiB9IH0gKSk7XG4gICAgfVxuXG4gICAgcHVibGljIHBhcnNlWE1MKHN0cjogc3RyaW5nKTogRG9jdW1lbnRcbiAgICB7XG4gICAgICAgIHJldHVybiAobmV3IERPTVBhcnNlcigpKS5wYXJzZUZyb21TdHJpbmcoc3RyLCBcInRleHQveG1sXCIpO1xuICAgIH1cblxuICAgIHB1YmxpYyBwYXJzZUhUTUwoc3RyOiBzdHJpbmcpOiBEb2N1bWVudFxuICAgIHtcbiAgICAgICAgcmV0dXJuIChuZXcgRE9NUGFyc2VyKCkpLnBhcnNlRnJvbVN0cmluZyhzdHIsIFwidGV4dC9odG1sXCIpO1xuICAgIH1cblxufSIsImV4cG9ydCBjbGFzcyBNYXBPdmVybGF5XG57XG5cbiAgICBwcml2YXRlIHJlYWRvbmx5IGRpdjogSFRNTEVsZW1lbnQ7XG5cbiAgICBjb25zdHJ1Y3RvcihtYXA6IGdvb2dsZS5tYXBzLk1hcCwgaWQ6IHN0cmluZylcbiAgICB7XG4gICAgICAgIGxldCBkaXYgPSBtYXAuZ2V0RGl2KCkub3duZXJEb2N1bWVudCEuZ2V0RWxlbWVudEJ5SWQoaWQpO1xuXG4gICAgICAgIGlmIChkaXYgIT09IG51bGwpIHRoaXMuZGl2ID0gZGl2O1xuICAgICAgICBlbHNlXG4gICAgICAgIHtcbiAgICAgICAgICAgIHRoaXMuZGl2ID0gbWFwLmdldERpdigpLm93bmVyRG9jdW1lbnQhLmNyZWF0ZUVsZW1lbnQoXCJkaXZcIik7XG4gICAgICAgICAgICB0aGlzLmRpdi5pZCA9IGlkO1xuICAgICAgICAgICAgdGhpcy5kaXYuY2xhc3NOYW1lID0gXCJwcm9ncmVzcyBwcm9ncmVzcy1zdHJpcGVkIGFjdGl2ZVwiO1xuICAgICAgICAgICAgXG4gICAgICAgICAgICAvLyBuZWVkIHRvIHNldCBDU1MgcHJvcGVydGllcyBwcm9ncmFtbWF0aWNhbGx5XG4gICAgICAgICAgICB0aGlzLmRpdi5zdHlsZS5wb3NpdGlvbiA9IFwiYWJzb2x1dGVcIjtcbiAgICAgICAgICAgIHRoaXMuZGl2LnN0eWxlLnRvcCA9IFwiMTdlbVwiO1xuICAgICAgICAgICAgdGhpcy5kaXYuc3R5bGUuekluZGV4ID0gXCIyXCI7XG4gICAgICAgICAgICB0aGlzLmRpdi5zdHlsZS53aWR0aCA9IFwiMjQlXCI7XG4gICAgICAgICAgICB0aGlzLmRpdi5zdHlsZS5sZWZ0ID0gXCIzOCVcIjtcbiAgICAgICAgICAgIHRoaXMuZGl2LnN0eWxlLnJpZ2h0ID0gXCIzOCVcIjtcbiAgICAgICAgICAgIHRoaXMuZGl2LnN0eWxlLnBhZGRpbmcgPSBcIjEwcHhcIjtcbiAgICAgICAgICAgIHRoaXMuZGl2LnN0eWxlLnZpc2liaWxpdHkgPSBcImhpZGRlblwiO1xuICAgICAgICAgICAgXG4gICAgICAgICAgICB2YXIgYmFyRGl2ID0gbWFwLmdldERpdigpLm93bmVyRG9jdW1lbnQhLmNyZWF0ZUVsZW1lbnQoXCJkaXZcIik7XG4gICAgICAgICAgICBiYXJEaXYuY2xhc3NOYW1lID0gXCJiYXJcIjtcbiAgICAgICAgICAgIGJhckRpdi5zdHlsZS53aWR0aCA9IFwiMTAwJVwiO1xuICAgICAgICAgICAgdGhpcy5kaXYuYXBwZW5kQ2hpbGQoYmFyRGl2KTtcbiAgICAgICAgICAgIFxuICAgICAgICAgICAgbWFwLmdldERpdigpLmFwcGVuZENoaWxkKHRoaXMuZGl2KTtcbiAgICAgICAgfVxuICAgIH1cblxuICAgIHB1YmxpYyBzaG93KCk6IHZvaWRcbiAgICB7XG4gICAgICAgIHRoaXMuZGl2LnN0eWxlLnZpc2liaWxpdHkgPSBcInZpc2libGVcIjtcbiAgICB9O1xuXG4gICAgcHVibGljIGhpZGUoKTogdm9pZFxuICAgIHtcbiAgICAgICAgdGhpcy5kaXYuc3R5bGUudmlzaWJpbGl0eSA9IFwiaGlkZGVuXCI7XG4gICAgfTtcblxufSIsIi8qIChpZ25vcmVkKSAqLyIsIi8qIChpZ25vcmVkKSAqLyJdLCJzb3VyY2VSb290IjoiIn0=