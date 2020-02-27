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
        this.url = url;
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
    projectAll() {
        this.getQuery().variables = ["*"];
        return this;
    }
    projection(variables) {
        this.getQuery().variables = variables;
        return this;
    }
    project(term) {
        this.getQuery().variables.push(term);
        return this;
    }
    isProjected(term) {
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
    static fromString(queryString, prefixes, baseIRI) {
        let query = new sparqljs__WEBPACK_IMPORTED_MODULE_0__["Parser"](prefixes, baseIRI).parse(queryString);
        if (!query)
            throw new Error("Only SPARQL queries are supported, not updates");
        return new QueryBuilder(query);
    }
    where(pattern) {
        if (!this.getQuery().where)
            this.getQuery().where = [];
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
        return this.where(QueryBuilder.bgp(triples));
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
    projectAll() {
        this.getQuery().variables = ["*"];
        return this;
    }
    projection(variables) {
        this.getQuery().variables = variables;
        return this;
    }
    project(term) {
        this.getQuery().variables.push(term);
        return this;
    }
    isProjected(term) {
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
/* harmony import */ var _atomgraph_URLBuilder_com_atomgraph_linkeddatahub_util_URLBuilder__WEBPACK_IMPORTED_MODULE_3__ = __webpack_require__(/*! @atomgraph/URLBuilder/com/atomgraph/linkeddatahub/util/URLBuilder */ "../URLBuilder/src/com/atomgraph/linkeddatahub/util/URLBuilder.ts");
/// <reference types="googlemaps" />
// import { Map, LatLng, LatLngBounds, Marker, InfoWindow } from 'googlemaps'; // using <reference> instead as otherwise we would get the "@types/googlemaps/index.d.ts is not a module" error




class Geo {
    constructor(map, endpoint, select, itemVarName) {
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
                        let titleElems = description.getElementsByTagNameNS("http://purl.org/dc/terms/", "title");
                        if (latElems.length > 0 && longElems.length > 0 && titleElems.length > 0) {
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
                            let markerConfig = {
                                "position": latLng,
                                // "label": label,
                                "map": this.getMap(),
                                "title": titleElems[0].textContent
                            };
                            let marker = new google.maps.Marker(markerConfig);
                            if (icon != null)
                                marker.setIcon(icon);
                            // popout InfoWindow for the topic of current document (same as on click)
                            let docs = description.getElementsByTagNameNS(Geo.FOAF_NS, "isPrimaryTopicOf");
                            if (docs.length > 0 && docs[0].hasAttributeNS(Geo.RDF_NS, "resource")) {
                                let docUri = docs[0].getAttributeNS(Geo.RDF_NS, "resource");
                                this.bindMarkerClick(marker, docUri); // bind loadInfoWindowHTML() to marker onclick
                                //if (docUri === this.getMap().getDiv().ownerDocument.documentURI) this.loadInfoWindowHTML(marker, docUri);
                            }
                        }
                    }
                }
            }
        };
        this.buildQuery = (selectQuery) => {
            return this.buildGeoBounderQuery(selectQuery, this.getItemVarName(), this.getMap().getBounds().getNorthEast().lng(), this.getMap().getBounds().getNorthEast().lat(), this.getMap().getBounds().getSouthWest().lat(), this.getMap().getBounds().getSouthWest().lng());
        };
        this.buildQueryURL = (queryBuilder) => {
            return _atomgraph_URLBuilder_com_atomgraph_linkeddatahub_util_URLBuilder__WEBPACK_IMPORTED_MODULE_3__["URLBuilder"].fromURL(this.getEndpoint()).
                searchParam("query", queryBuilder.toString()).
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
        this.itemVarName = itemVarName;
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
    getItemVarName() {
        return this.itemVarName;
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
    buildGeoBounderQuery(selectQuery, itemVarName, east, north, south, west) {
        return _atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_DescribeBuilder__WEBPACK_IMPORTED_MODULE_2__["DescribeBuilder"].new().
            where(_atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_DescribeBuilder__WEBPACK_IMPORTED_MODULE_2__["DescribeBuilder"].group([selectQuery])).
            where(_atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_SelectBuilder__WEBPACK_IMPORTED_MODULE_1__["SelectBuilder"].graph(_atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_SelectBuilder__WEBPACK_IMPORTED_MODULE_1__["SelectBuilder"].var("childGraph"), [
            _atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_SelectBuilder__WEBPACK_IMPORTED_MODULE_1__["SelectBuilder"].bgp([
                _atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_SelectBuilder__WEBPACK_IMPORTED_MODULE_1__["SelectBuilder"].triple(_atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_SelectBuilder__WEBPACK_IMPORTED_MODULE_1__["SelectBuilder"].var(itemVarName), _atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_SelectBuilder__WEBPACK_IMPORTED_MODULE_1__["SelectBuilder"].uri(Geo.GEO_NS + "lat"), _atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_SelectBuilder__WEBPACK_IMPORTED_MODULE_1__["SelectBuilder"].var("lat")),
                _atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_SelectBuilder__WEBPACK_IMPORTED_MODULE_1__["SelectBuilder"].triple(_atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_SelectBuilder__WEBPACK_IMPORTED_MODULE_1__["SelectBuilder"].var(itemVarName), _atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_SelectBuilder__WEBPACK_IMPORTED_MODULE_1__["SelectBuilder"].uri(Geo.GEO_NS + "long"), _atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_SelectBuilder__WEBPACK_IMPORTED_MODULE_1__["SelectBuilder"].var("long"))
            ]),
            _atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_SelectBuilder__WEBPACK_IMPORTED_MODULE_1__["SelectBuilder"].filter(_atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_SelectBuilder__WEBPACK_IMPORTED_MODULE_1__["SelectBuilder"].operation("<", [_atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_SelectBuilder__WEBPACK_IMPORTED_MODULE_1__["SelectBuilder"].var("long"), _atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_SelectBuilder__WEBPACK_IMPORTED_MODULE_1__["SelectBuilder"].typedLiteral(east.toString(), Geo.XSD_NS + "decimal")])),
            _atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_SelectBuilder__WEBPACK_IMPORTED_MODULE_1__["SelectBuilder"].filter(_atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_SelectBuilder__WEBPACK_IMPORTED_MODULE_1__["SelectBuilder"].operation("<", [_atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_SelectBuilder__WEBPACK_IMPORTED_MODULE_1__["SelectBuilder"].var("lat"), _atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_SelectBuilder__WEBPACK_IMPORTED_MODULE_1__["SelectBuilder"].typedLiteral(north.toString(), Geo.XSD_NS + "decimal")])),
            _atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_SelectBuilder__WEBPACK_IMPORTED_MODULE_1__["SelectBuilder"].filter(_atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_SelectBuilder__WEBPACK_IMPORTED_MODULE_1__["SelectBuilder"].operation(">", [_atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_SelectBuilder__WEBPACK_IMPORTED_MODULE_1__["SelectBuilder"].var("lat"), _atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_SelectBuilder__WEBPACK_IMPORTED_MODULE_1__["SelectBuilder"].typedLiteral(south.toString(), Geo.XSD_NS + "decimal")])),
            _atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_SelectBuilder__WEBPACK_IMPORTED_MODULE_1__["SelectBuilder"].filter(_atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_SelectBuilder__WEBPACK_IMPORTED_MODULE_1__["SelectBuilder"].operation(">", [_atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_SelectBuilder__WEBPACK_IMPORTED_MODULE_1__["SelectBuilder"].var("long"), _atomgraph_SPARQLBuilder_com_atomgraph_linkeddatahub_query_SelectBuilder__WEBPACK_IMPORTED_MODULE_1__["SelectBuilder"].typedLiteral(west.toString(), Geo.XSD_NS + "decimal")]))
        ]));
    }
    buildInfoURL(url) {
        return _atomgraph_URLBuilder_com_atomgraph_linkeddatahub_util_URLBuilder__WEBPACK_IMPORTED_MODULE_3__["URLBuilder"].fromString(url).
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
/// <reference types="googlemaps" />
// import { Map } from 'googlemaps'; // using <reference> instead as otherwise we would get the "@types/googlemaps/index.d.ts is not a module" error
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
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIndlYnBhY2s6Ly9TUEFSUUxNYXAvd2VicGFjay9ib290c3RyYXAiLCJ3ZWJwYWNrOi8vU1BBUlFMTWFwLy4uL1VSTEJ1aWxkZXIvc3JjL2NvbS9hdG9tZ3JhcGgvbGlua2VkZGF0YWh1Yi91dGlsL1VSTEJ1aWxkZXIudHMiLCJ3ZWJwYWNrOi8vU1BBUlFMTWFwLy4uL3NwYXJxbC1idWlsZGVyL25vZGVfbW9kdWxlcy9zcGFycWxqcy9saWIvU3BhcnFsR2VuZXJhdG9yLmpzIiwid2VicGFjazovL1NQQVJRTE1hcC8uLi9zcGFycWwtYnVpbGRlci9ub2RlX21vZHVsZXMvc3BhcnFsanMvbGliL1NwYXJxbFBhcnNlci5qcyIsIndlYnBhY2s6Ly9TUEFSUUxNYXAvLi4vc3BhcnFsLWJ1aWxkZXIvbm9kZV9tb2R1bGVzL3NwYXJxbGpzL3NwYXJxbC5qcyIsIndlYnBhY2s6Ly9TUEFSUUxNYXAvLi4vc3BhcnFsLWJ1aWxkZXIvc3JjL2NvbS9hdG9tZ3JhcGgvbGlua2VkZGF0YWh1Yi9xdWVyeS9EZXNjcmliZUJ1aWxkZXIudHMiLCJ3ZWJwYWNrOi8vU1BBUlFMTWFwLy4uL3NwYXJxbC1idWlsZGVyL3NyYy9jb20vYXRvbWdyYXBoL2xpbmtlZGRhdGFodWIvcXVlcnkvUXVlcnlCdWlsZGVyLnRzIiwid2VicGFjazovL1NQQVJRTE1hcC8uLi9zcGFycWwtYnVpbGRlci9zcmMvY29tL2F0b21ncmFwaC9saW5rZWRkYXRhaHViL3F1ZXJ5L1NlbGVjdEJ1aWxkZXIudHMiLCJ3ZWJwYWNrOi8vU1BBUlFMTWFwLy4vbm9kZV9tb2R1bGVzL3Byb2Nlc3MvYnJvd3Nlci5qcyIsIndlYnBhY2s6Ly9TUEFSUUxNYXAvKHdlYnBhY2spL2J1aWxkaW4vbW9kdWxlLmpzIiwid2VicGFjazovL1NQQVJRTE1hcC8uL3NyYy9jb20vYXRvbWdyYXBoL2xpbmtlZGRhdGFodWIvY2xpZW50L01hcC50cyIsIndlYnBhY2s6Ly9TUEFSUUxNYXAvLi9zcmMvY29tL2F0b21ncmFwaC9saW5rZWRkYXRhaHViL2NsaWVudC9tYXAvTWFwT3ZlcmxheS50cyIsIndlYnBhY2s6Ly9TUEFSUUxNYXAvZnMgKGlnbm9yZWQpIiwid2VicGFjazovL1NQQVJRTE1hcC9wYXRoIChpZ25vcmVkKSJdLCJuYW1lcyI6W10sIm1hcHBpbmdzIjoiOztRQUFBO1FBQ0E7O1FBRUE7UUFDQTs7UUFFQTtRQUNBO1FBQ0E7UUFDQTtRQUNBO1FBQ0E7UUFDQTtRQUNBO1FBQ0E7UUFDQTs7UUFFQTtRQUNBOztRQUVBO1FBQ0E7O1FBRUE7UUFDQTtRQUNBOzs7UUFHQTtRQUNBOztRQUVBO1FBQ0E7O1FBRUE7UUFDQTtRQUNBO1FBQ0EsMENBQTBDLGdDQUFnQztRQUMxRTtRQUNBOztRQUVBO1FBQ0E7UUFDQTtRQUNBLHdEQUF3RCxrQkFBa0I7UUFDMUU7UUFDQSxpREFBaUQsY0FBYztRQUMvRDs7UUFFQTtRQUNBO1FBQ0E7UUFDQTtRQUNBO1FBQ0E7UUFDQTtRQUNBO1FBQ0E7UUFDQTtRQUNBO1FBQ0EseUNBQXlDLGlDQUFpQztRQUMxRSxnSEFBZ0gsbUJBQW1CLEVBQUU7UUFDckk7UUFDQTs7UUFFQTtRQUNBO1FBQ0E7UUFDQSwyQkFBMkIsMEJBQTBCLEVBQUU7UUFDdkQsaUNBQWlDLGVBQWU7UUFDaEQ7UUFDQTtRQUNBOztRQUVBO1FBQ0Esc0RBQXNELCtEQUErRDs7UUFFckg7UUFDQTs7O1FBR0E7UUFDQTs7Ozs7Ozs7Ozs7OztBQ2xGQTtBQUFBO0FBQUE7Ozs7Ozs7Ozs7Ozs7O0dBY0c7QUFFSSxNQUFNLFVBQVU7SUFLbkIsWUFBc0IsR0FBUTtRQUUxQixJQUFJLENBQUMsR0FBRyxHQUFHLEdBQUcsQ0FBQztJQUNuQixDQUFDO0lBQUEsQ0FBQztJQUVGOzs7OztPQUtHO0lBQ0ksSUFBSSxDQUFDLElBQW1CO1FBRTNCLElBQUksSUFBSSxJQUFJLElBQUk7WUFBRSxJQUFJLENBQUMsR0FBRyxDQUFDLElBQUksR0FBRyxFQUFFLENBQUM7O1lBQ2hDLElBQUksQ0FBQyxHQUFHLENBQUMsSUFBSSxHQUFHLEdBQUcsR0FBRyxJQUFJ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QXVCLE9BQU87QUFDOUI7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQSxLQUFLO0FBQ0w7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQSwrREFBK0Q7QUFDL0Q7QUFDQTtBQUNBO0FBQ0E7QUFDQSxTQUFTO0FBQ1Q7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0EsaUJBQWlCO0FBQ2pCO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQSxpQkFBaUI7QUFDakI7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQSxhQUFhO0FBQ2I7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOztBQUVBO0FBQ0E7QUFDQTs7QUFFQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7QUFFQTs7QUFFQTtBQUNBO0FBQ0E7QUFDQTs7QUFFQTtBQUNBO0FBQ0E7QUFDQTs7QUFFQTtBQUNBO0FBQ0E7QUFDQTs7QUFFQTtBQUNBO0FBQ0E7QUFDQSw4Q0FBOEMsbUNBQW1DLEVBQUU7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UztBQUNUO0FBQ0E7QUFDQSxLQUFLOztBQUVMO0FBQ0E7QUFDQTtBQUNBLEtBQUs7O0FBRUw7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBLFNBQVM7QUFDVDtBQUNBO0FBQ0EsS0FBSzs7QUFFTDtBQUNBO0FBQ0E7QUFDQTtBQUNBLFNBQVM7QUFDVDtBQUNBO0FBQ0EsS0FBSzs7QUFFTCxxREFBcUQ7QUFDckQ7QUFDQTtBQUNBO0FBQ0E7QUFDQSxTQUFTO0FBQ1Q7QUFDQTtBQUNBLEtBQUs7O0FBRUw7QUFDQTtBQUNBO0FBQ0EsS0FBSzs7QUFFTDtBQUNBO0FBQ0E7QUFDQSxLQUFLO0FBQ0wsVUFBVSxvQ0FBb0M7QUFDOUM7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtB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Q0E7QUFDQTtBQUNBO0FBQ0EsU0FBUztBQUNUO0FBQ0E7QUFDQSxLQUFLO0FBQ0w7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBLFNBQVM7QUFDVDtBQUNBO0FBQ0EsS0FBSztBQUNMO0FBQ0E7QUFDQSxDQUFDO0FBQ0Q7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQSxLQUFLO0FBQ0w7QUFDQTtBQUNBO0FBQ0EsU0FBUztBQUNUO0FBQ0E7QUFDQTtBQUNBOzs7QUFHQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0EsS0FBSztBQUNMO0FBQ0E7QUFDQTtBQUNBLFNBQVM7QUFDVDtBQUNBO0FBQ0E7QUFDQTtBQUNBOzs7O0FBSUE7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7QUFFQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBLEtBQUs7QUFDTDtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7O0FBRUE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOztBQUVBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOztBQUVBO0FBQ0E7QUFDQTtBQUNBLHVCQUF1QixzQkFBc0I7QUFDN0M7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7QUFFQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQSxxQkFBcUI7QUFDckI7O0FBRUE7O0FBRUE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOztBQUVBLHFDQUFxQzs7QUFFckM7QUFDQTtBQUNBOztBQUVBLDJCQUEyQjtBQUMzQjtBQUNBO0FBQ0E7QUFDQSw0QkFBNEIsVUFBVTs7Ozs7Ozs7Ozs7O0FDdkx0QztBQUNBO0FBQ0E7QUFD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LENBQUMsTUFBTSxDQUFDLHNIQUFhLENBQUMsR0FBRyxDQUFDLFdBQVcsQ0FBQyxFQUFFLHNIQUFhLENBQUMsR0FBRyxDQUFDLEdBQUcsQ0FBQyxNQUFNLEdBQUcsS0FBSyxDQUFDLEVBQUUsc0hBQWEsQ0FBQyxHQUFHLENBQUMsS0FBSyxDQUFDLENBQUM7Z0JBQ3JILHNIQUFhLENBQUMsTUFBTSxDQUFDLHNIQUFhLENBQUMsR0FBRyxDQUFDLFdBQVcsQ0FBQyxFQUFFLHNIQUFhLENBQUMsR0FBRyxDQUFDLEdBQUcsQ0FBQyxNQUFNLEdBQUcsTUFBTSxDQUFDLEVBQUUsc0hBQWEsQ0FBQyxHQUFHLENBQUMsTUFBTSxDQUFDLENBQUM7YUFDMUgsQ0FBQztZQUNOLHNIQUFhLENBQUMsTUFBTSxDQUFDLHNIQUFhLENBQUMsU0FBUyxDQUFDLEdBQUcsRUFBRSxDQUFFLHNIQUFhLENBQUMsR0FBRyxDQUFDLE1BQU0sQ0FBQyxFQUFFLHNIQUFhLENBQUMsWUFBWSxDQUFDLElBQUksQ0FBQyxRQUFRLEVBQUUsRUFBRSxHQUFHLENBQUMsTUFBTSxHQUFHLFNBQVMsQ0FBQyxDQUFFLENBQUMsQ0FBQztZQUN0SixzSEFBYSxDQUFDLE1BQU0sQ0FBQyxzSEFBYSxDQUFDLFNBQVMsQ0FBQyxHQUFHLEVBQUUsQ0FBRSxzSEFBYSxDQUFDLEdBQUcsQ0FBQyxLQUFLLENBQUMsRUFBRSxzSEFBYSxDQUFDLFlBQVksQ0FBQyxLQUFLLENBQUMsUUFBUSxFQUFFLEVBQUUsR0FBRyxDQUFDLE1BQU0sR0FBRyxTQUFTLENBQUMsQ0FBRSxDQUFDLENBQUM7WUFDdEosc0hBQWEsQ0FBQyxNQUFNLENBQUMsc0hBQWEsQ0FBQyxTQUFTLENBQUMsR0FBRyxFQUFFLENBQUUsc0hBQWEsQ0FBQyxHQUFHLENBQUMsS0FBSyxDQUFDLEVBQUUsc0hBQWEsQ0FBQyxZQUFZLENBQUMsS0FBSyxDQUFDLFFBQVEsRUFBRSxFQUFFLEdBQUcsQ0FBQyxNQUFNLEdBQUcsU0FBUyxDQUFDLENBQUUsQ0FBQyxDQUFDO1lBQ3RKLHNIQUFhLENBQUMsTUFB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QUFXLENBQUMsTUFBTSxDQUFDLENBQUM7WUFFN0IsR0FBRyxDQUFDLE1BQU0sRUFBRSxDQUFDLFdBQVcsQ0FBQyxJQUFJLENBQUMsR0FBRyxDQUFDLENBQUM7U0FDdEM7SUFDTCxDQUFDO0lBRU0sSUFBSTtRQUVQLElBQUksQ0FBQyxHQUFHLENBQUMsS0FBSyxDQUFDLFVBQVUsR0FBRyxTQUFTLENBQUM7SUFDMUMsQ0FBQztJQUFBLENBQUM7SUFFSyxJQUFJO1FBRVAsSUFBSSxDQUFDLEdBQUcsQ0FBQyxLQUFLLENBQUMsVUFBVSxHQUFHLFFBQVEsQ0FBQztJQUN6QyxDQUFDO0lBQUEsQ0FBQztDQUVMOzs7Ozs7Ozs7Ozs7QUNqREQsZTs7Ozs7Ozs7Ozs7QUNBQSxlIiwiZmlsZSI6IlNQQVJRTE1hcC5qcyIsInNvdXJjZXNDb250ZW50IjpbIiBcdC8vIFRoZSBtb2R1bGUgY2FjaGVcbiBcdHZhciBpbnN0YWxsZWRNb2R1bGVzID0ge307XG5cbiBcdC8vIFRoZSByZXF1aXJlIGZ1bmN0aW9uXG4gXHRmdW5jdGlvbiBfX3dlYnBhY2tfcmVxdWlyZV9fKG1vZHVsZUlkKSB7XG5cbiBcdFx0Ly8gQ2hlY2sgaWYgbW9kdWxlIGlzIGluIGNhY2hlXG4gXHRcdGlmKGluc3RhbGxlZE1vZHVsZXNbbW9kdWxlSWRdKSB7XG4gXHRcdFx0cmV0dXJuIGluc3RhbGxlZE1vZHVsZXNbbW9kdWxlSWRdLmV4cG9ydHM7XG4gXHRcdH1cbiBcdFx0Ly8gQ3JlYXRlIGEgbmV3IG1vZHVsZSAoYW5kIHB1dCBpdCBpbnRvIHRoZSBjYWNoZSlcbiBcdFx0dmFyIG1vZHVsZSA9IGluc3RhbGxlZE1vZHVsZXNbbW9kdWxlSWRdID0ge1xuIFx0XHRcdGk6IG1vZHVsZUlkLFxuIFx0XHRcdGw6IGZhbHNlLFxuIFx0XHRcdGV4cG9ydHM6IHt9XG4gXHRcdH07XG5cbiBcdFx0Ly8gRXhlY3V0ZSB0aGUgbW9kdWxlIGZ1bmN0aW9uXG4gXHRcdG1vZHVsZXNbbW9kdWxlSWRdLmNhbGwobW9kdWxlLmV4cG9ydHMsIG1vZHVsZSwgbW9kdWxlLmV4cG9ydHMsIF9fd2VicGFja19yZXF1aXJlX18pO1xuXG4gXHRcdC8vIEZsYWcgdGhlIG1vZHVsZSBhcyBsb2FkZWRcbiBcdFx0bW9kdWxlLmwgPSB0cnVlO1xuXG4gXHRcdC8vIFJldHVybiB0aGUgZXhwb3J0cyBvZiB0aGUgbW9kdWxlXG4gXHRcdHJldHVybiBtb2R1bGUuZXhwb3J0cztcbiBcdH1cblxuXG4gXHQvLyBleHBvc2UgdGhlIG1vZHVsZXMgb2JqZWN0IChfX3dlYnBhY2tfbW9kdWxlc19fKVxuIFx0X193ZWJwYWNrX3JlcXVpcmVfXy5tID0gbW9kdWxlcztcblxuIFx0Ly8gZXhwb3NlIHRoZSBtb2R1bGUgY2FjaGVcbiBcdF9fd2VicGFja19yZXF1aXJlX18uYyA9IGluc3RhbGxlZE1vZHVsZXM7XG5cbiBcdC8vIGRlZmluZSBnZXR0ZXIgZnVuY3Rpb24gZm9yIGhhcm1vbnkgZXhwb3J0c1xuIFx0X193ZWJwYWNrX3JlcXVpcmVfXy5kID0gZnVuY3Rpb24oZXhwb3J0cywgbmFtZSwgZ2V0dGVyKSB7XG4gXHRcdGlmKCFfX3dlYnBhY2tfcmVxdWlyZV9fLm8oZXhwb3J0cywgbmFtZSkpIHtcbiBcdFx0XHRPYmplY3QuZGVmaW5lUHJvcGVydHkoZXhwb3J0cywgbmFtZSwgeyBlbnVtZXJhYmxlOiB0cnVlLCBnZXQ6IGdldHRlciB9KTtcbiBcdFx0fVxuIFx0fTtcblxuIFx0Ly8gZGVmaW5lIF9fZXNNb2R1bGUgb24gZXhwb3J0c1xuIFx0X193ZWJwYWNrX3JlcXVpcmVfXy5yID0gZnVuY3Rpb24oZXhwb3J0cykge1xuIFx0XHRpZih0eXBlb2YgU3ltYm9sICE9PSAndW5kZWZpbmVkJyAmJiBTeW1ib2wudG9TdHJpbmdUYWcpIHtcbiBcdFx0XHRPYmplY3QuZGVmaW5lUHJvcGVydHkoZXhwb3J0cywgU3ltYm9sLnRvU3RyaW5nVGFnLCB7IHZhbHVlOiAnTW9kdWxlJyB9KTtcbiBcdFx0fVxuIFx0XHRPYmplY3QuZGVmaW5lUHJvcGVydHkoZXhwb3J0cywgJ19fZXNNb2R1bGUnLCB7IHZhbHVlOiB0cnVlIH0pO1xuIFx0fTtcblxuIFx0Ly8gY3JlYXRlIGEgZmFrZSBuYW1lc3BhY2Ugb2JqZWN0XG4gXHQvLyBtb2RlICYgMTogdmFsdWUgaXMgYSBtb2R1bGUgaWQsIHJlcXVpcmUgaXRcbiBcdC8vIG1vZGUgJiAyOiBtZXJnZSBhbGwgcHJvcGVydGllcyBvZiB2YWx1ZSBpbnRvIHRoZSBuc1xuIFx0Ly8gbW9kZSAmIDQ6IHJldHVybiB2YWx1ZSB3aGVuIGFscmVhZHkgbnMgb2JqZWN0XG4gXHQvLyBtb2RlICYgOHwxOiBiZWhhdmUgbGlrZSByZXF1aXJlXG4gXHRfX3dlYnBhY2tfcmVxdWlyZV9fLnQgPSBmdW5jdGlvbih2YWx1ZSwgbW9kZSkge1xuIFx0XHRpZihtb2RlICYgMSkgdmFsdWUgPSBfX3dlYnBhY2tfcmVxdWlyZV9fKHZhbHVlKTtcbiBcdFx0aWYobW9kZSAmIDgpIHJldHVybiB2YWx1ZTtcbiBcdFx0aWYoKG1vZGUgJiA0KSAmJiB0eXBlb2YgdmFsdWUgPT09ICdvYmplY3QnICYmIHZhbHVlICYmIHZhbHVlLl9fZXNNb2R1bGUpIHJldHVybiB2YWx1ZTtcbiBcdFx0dmFyIG5zID0gT2JqZWN0LmNyZWF0ZShudWxsKTtcbiBcdFx0X193ZWJwYWNrX3JlcXVpcmVfXy5yKG5zKTtcbiBcdFx0T2JqZWN0LmRlZmluZVByb3BlcnR5KG5zLCAnZGVmYXVsdCcsIHsgZW51bWVyYWJsZTogdHJ1ZSwgdmFsdWU6IHZhbHVlIH0pO1xuIFx0XHRpZihtb2RlICYgMiAmJiB0eXBlb2YgdmFsdWUgIT0gJ3N0cmluZycpIGZvcih2YXIga2V5IGluIHZhbHVlKSBfX3dlYnBhY2tfcmVxdWlyZV9fLmQobnMsIGtleSwgZnVuY3Rpb24oa2V5KSB7IHJldHVybiB2YWx1ZVtrZXldOyB9LmJpbmQobnVsbCwga2V5KSk7XG4gXHRcdHJldHVybiBucztcbiBcdH07XG5cbiBcdC8vIGdldERlZmF1bHRFeHBvcnQgZnVuY3Rpb24gZm9yIGNvbXBhdGliaWxpdHkgd2l0aCBub24taGFybW9ueSBtb2R1bGVzXG4gXHRfX3dlYnBhY2tfcmVxdWlyZV9fLm4gPSBmdW5jdGlvbihtb2R1bGUpIHtcbiBcdFx0dmFyIGdldHRlciA9IG1vZHVsZSAmJiBtb2R1bGUuX19lc01vZHVsZSA/XG4gXHRcdFx0ZnVuY3Rpb24gZ2V0RGVmYXVsdCgpIHsgcmV0dXJuIG1vZHVsZVsnZGVmYXVsdCddOyB9IDpcbiBcdFx0XHRmdW5jdGlvbiBnZXRNb2R1bGVFeHBvcnRzKCkgeyByZXR1cm4gbW9kdWxlOyB9O1xuIFx0XHRfX3dlYnBhY2tfcmVxdWlyZV9fLmQoZ2V0dGVyLCAnYScsIGdldHRlcik7XG4gXHRcdHJldHVybiBnZXR0ZXI7XG4gXHR9O1xuXG4gXHQvLyBPYmplY3QucHJvdG90eXBlLmhhc093blByb3BlcnR5LmNhbGxcbiBcdF9fd2VicGFja19yZXF1aXJlX18ubyA9IGZ1bmN0aW9uKG9iamVjdCwgcHJvcGVydHkpIHsgcmV0dXJuIE9iamVjdC5wcm90b3R5cGUuaGFzT3duUHJvcGVydHkuY2FsbChvYmplY3QsIHByb3BlcnR5KTsgfTtcblxuIFx0Ly8gX193ZWJwYWNrX3B1YmxpY19wYXRoX19cbiBcdF9fd2VicGFja19yZXF1aXJlX18ucCA9IFwiXCI7XG5cblxuIFx0Ly8gTG9hZCBlbnRyeSBtb2R1bGUgYW5kIHJldHVybiBleHBvcnRzXG4gXHRyZXR1cm4gX193ZWJwYWNrX3JlcXVpcmVfXyhfX3dlYnBhY2tfcmVxdWlyZV9fLnMgPSBcIi4vc3JjL2NvbS9hdG9tZ3JhcGgvbGlua2VkZGF0YWh1Yi9jbGllbnQvTWFwLnRzXCIpO1xuIiwiLyoqXG4gKiAgVVJMQnVpbGRlciBjbGFzcyBmb3IgZWFzaWVyIGNvbXBvc2l0aW9uIG9mIFVSTHMuXG4gKiAgXG4gKiAgRXhhbXBsZSB1c2FnZTpcbiAqICBcbiAqICBVUkxCdWlsZGVyLmZyb21VUkwoXCJodHRwczovL2F0b21ncmFwaC5jb21cIikucGF0aChcImNhc2VzXCIpLnBhdGgoXCJueHAtc2VtaWNvbmR1Y3RvcnNcIikuYnVpbGQoKS50b1N0cmluZygpO1xuICogIFxuICogIFdpbGwgcmV0dXJuOlxuICogIFxuICogIFwiaHR0cHM6Ly9hdG9tZ3JhcGguY29tL2Nhc2VzL254cC1zZW1pY29uZHVjdG9yc1wiXG4gKiAgXG4gKiAgVGhpcyBpbXBsZW1lbnRhdGlvbiBkb2VzIG5vdCBzdXBwb3J0IHZhcmlhYmxlIHRlbXBsYXRlcyBzdWNoIGFzIHt2YXJ9IGFzIG9mIHlldC5cbiAqICBcbiAqICBAYXV0aG9yIE1hcnR5bmFzIEp1c2V2acSNaXVzIDxtYXJ0eW5hc0BhdG9tZ3JhcGguY29tPlxuICovXG5cbmV4cG9ydCBjbGFzcyBVUkxCdWlsZGVyXG57XG5cbiAgICBwcml2YXRlIHJlYWRvbmx5IHVybDogVVJMO1xuXG4gICAgcHJvdGVjdGVkIGNvbnN0cnVjdG9yKHVybDogVVJMKVxuICAgIHtcbiAgICAgICAgdGhpcy51cmwgPSB1cmw7XG4gICAgfTtcblxuICAgIC8qKlxuICAgICAqIFNldCBoYXNoICh3aXRob3V0IFwiI1wiKVxuICAgICAqIFxuICAgICAqIEBwYXJhbSBzdHJpbmcgaGFzaFxuICAgICAqIEByZXR1cm5zIHtVUkxCdWlsZGVyfVxuICAgICAqL1xuICAgIHB1YmxpYyBoYXNoKGhhc2g6IHN0cmluZyB8IG51bGwpOiBVUkxCdWlsZGVyXG4gICAge1xuICAgICAgICBpZiAoaGFzaCA9PSBudWxsKSB0aGlzLnVybC5oYXNoID0gXCJcIjtcbiAgICAgICAgZWxzZSB0aGlzLnVybC5oYXNoID0gXCIjXCIgKyBoYXNoO1xuXG4gICAgICAgIHJldHVybiB0aGlzO1xuICAgIH07XG5cbiAgICAvKipcbiAgICAgKiBTZXQgaG9zdFxuICAgICAqIFxuICAgICAqIEBwYXJhbSBzdHJpbmcgaG9zdFxuICAgICAqIEByZXR1cm5zIHtVUkxCdWlsZGVyfVxuICAgICAqL1xuICAgIHB1YmxpYyBob3N0KGhvc3Q6IHN0cmluZyk6IFVSTEJ1aWxkZXJcbiAgICB7XG4gICAgICAgIHRoaXMudXJsLmhvc3QgPSBob3N0O1xuXG4gICAgICAgIHJldHVybiB0aGlzO1xuICAgIH07XG5cbiAgICAvKipcbiAgICAgKiBTZXQgaG9zdG5hbWVcbiAgICAgKiBcbiAgICAgKiBAcGFyYW0gc3RyaW5nIGhvc3RuYW1lXG4gICAgICogQHJldHVybnMge1VSTEJ1aWxkZXJ9XG4gICAgICovXG4gICAgcHVibGljIGhvc3RuYW1lKGhvc3RuYW1lOiBzdHJpbmcpOiBVUkxCdWlsZGVyXG4gICAge1xuICAgICAgICB0aGlzLnVybC5ob3N0bmFtZSA9IGhvc3RuYW1lO1xuXG4gICAgICAgIHJldHVybiB0aGlzO1xuICAgIH07XG5cbiAgICAvKipcbiAgICAgKiBTZXQgcGFzc3dvcmRcbiAgICAgKiBcbiAgICAgKiBAcGFyYW0gc3RyaW5nIHBhc3N3b3JkXG4gICAgICogQHJldHVybiB7VVJMQnVpbGRlcn1cbiAgICAgKi9cbiAgICBwdWJsaWMgcGFzc3dvcmQocGFzc3dvcmQ6IHN0cmluZyk6IFVSTEJ1aWxkZXJcbiAgICB7XG4gICAgICAgIHRoaXMudXJsLnBhc3N3b3JkID0gcGFzc3dvcmQ7XG5cbiAgICAgICAgcmV0dXJuIHRoaXM7XG4gICAgfTtcblxuICAgIC8qKlxuICAgICAqIEFwcGVuZCBwYXRoIFxuICAgICAqIFxuICAgICAqIEBwYXJhbSBzdHJpbmcgcGF0aFxuICAgICAqIEByZXR1cm5zIHtVUkxCdWlsZGVyfVxuICAgICAqL1xuICAgIHB1YmxpYyBwYXRoKHBhdGg6IHN0cmluZyB8IG51bGwpOiBVUkxCdWlsZGVyXG4gICAge1xuICAgICAgICBpZiAocGF0aCA9PSBudWxsKSB0aGlzLnVybC5wYXRobmFtZSA9IFwiXCI7XG4gICAgICAgIGVsc2VcbiAgICAgICAge1xuICAgICAgICAgICAgaWYgKHRoaXMudXJsLnBhdGhuYW1lLmxlbmd0aCA9PT0gMClcbiAgICAgICAgICAgIHtcbiAgICAgICAgICAgICAgICBpZiAoIXBhdGguc3RhcnRzV2l0aChcIi9cIikpIHBhdGggPSBcIi9cIiArIHBhdGg7XG4gICAgICAgICAgICAgICAgdGhpcy51cmwucGF0aG5hbWUgPSBwYXRoO1xuICAgICAgICAgICAgfVxuICAgICAgICAgICAgZWxzZVxuICAgICAgICAgICAge1xuICAgICAgICAgICAgICAgIGlmICghcGF0aC5zdGFydHNXaXRoKFwiL1wiKSAmJiAhdGhpcy51cmwucGF0aG5hbWUuZW5kc1dpdGgoXCIvXCIpKSBwYXRoID0gXCIvXCIgKyBwYXRoO1xuICAgICAgICAgICAgICAgIHRoaXMudXJsLnBhdGhuYW1lICs9IHBhdGg7XG4gICAgICAgICAgICB9XG4gICAgICAgIH1cblxuICAgICAgICByZXR1cm4gdGhpcztcbiAgICB9O1xuXG4gICAgLyoqXG4gICAgICogU2V0IHBvcnRcbiAgICAgKiBcbiAgICAgKiBAcGFyYW0gc3RyaW5nIHBvcnRcbiAgICAgKiBAcmV0dXJucyB7VVJMQnVpbGRlcn1cbiAgICAgKi9cbiAgICBwdWJsaWMgcG9ydChwb3J0OiBzdHJpbmcgfCBudWxsKTogVVJMQnVpbGRlclxuICAgIHtcbiAgICAgICAgaWYgKHBvcnQgPT0gbnVsbCkgdGhpcy51cmwucG9ydCA9IFwiXCI7XG4gICAgICAgIGVsc2UgdGhpcy51cmwucG9ydCA9IHBvcnQ7XG5cbiAgICAgICAgcmV0dXJuIHRoaXM7XG4gICAgfTtcblxuICAgIC8qKlxuICAgICAqIFNldCBwcm90b2NvbFxuICAgICAqIFxuICAgICAqIEBwYXJhbSBzdHJpbmcgcHJvdG9jb2xcbiAgICAgKiBAcmV0dXJuIHtVUkxCdWlsZGVyfVxuICAgICAqL1xuICAgIHB1YmxpYyBwcm90b2NvbChwcm90b2NvbDogc3RyaW5nKTogVVJMQnVpbGRlclxuICAgIHtcbiAgICAgICAgdGhpcy51cmwucHJvdG9jb2wgPSBwcm90b2NvbDtcblxuICAgICAgICByZXR1cm4gdGhpcztcbiAgICB9O1xuXG4gICAgLyoqXG4gICAgICogU2V0IGEgcXVlcnkgc3RyaW5nICh3aXRoIGxlYWRpbmcgXCI/XCIpXG4gICAgICogXG4gICAgICogQHBhcmFtIHN0cmluZyBzZWFyY2hcbiAgICAgKiBAcmV0dXJucyB7VVJMQnVpbGRlcn1cbiAgICAgKi9cbiAgICBwdWJsaWMgc2VhcmNoKHNlYXJjaDogc3RyaW5nIHwgbnVsbCk6IFVSTEJ1aWxkZXJcbiAgICB7XG4gICAgICAgIGlmIChzZWFyY2ggPT0gbnVsbCkgdGhpcy51cmwuc2VhcmNoID0gXCJcIjtcbiAgICAgICAgZWxzZSB0aGlzLnVybC5zZWFyY2ggPSBzZWFyY2g7XG5cbiAgICAgICAgcmV0dXJuIHRoaXM7XG4gICAgfTtcblxuICAgIC8qKlxuICAgICAqIEFkZCBhIHF1ZXJ5IG5hbWU9dmFsdWUgcGFpci5cbiAgICAgKiBNdWx0aXBsZSB2YWx1ZXMgYXJlIGFsbG93ZWQuXG4gICAgICogXG4gICAgICogQHBhcmFtIHN0cmluZyBuYW1lXG4gICAgICogQHBhcmFtIHN0cmluZyB2YWx1ZVxuICAgICAqIEByZXR1cm5zIHtVUkxCdWlsZGVyfVxuICAgICAqL1xuICAgIHB1YmxpYyBzZWFyY2hQYXJhbShuYW1lOiBzdHJpbmcsIC4uLnZhbHVlczogc3RyaW5nW10pOiBVUkxCdWlsZGVyXG4gICAge1xuICAgICAgICBmb3IgKGxldCB2YWx1ZSBvZiB2YWx1ZXMpXG4gICAgICAgICAgICB0aGlzLnVybC5zZWFyY2hQYXJhbXMuYXBwZW5kKG5hbWUsIHZhbHVlKTtcblxuICAgICAgICByZXR1cm4gdGhpcztcbiAgICB9O1xuXG4gICAgLyoqXG4gICAgICogUmVwbGFjZSBhIHF1ZXJ5IHBhcmFtXG4gICAgICogTXVsdGlwbGUgdmFsdWVzIGFyZSBhbGxvd2VkLlxuICAgICAqXG4gICAgICogQHBhcmFtIHN0cmluZyBuYW1lXG4gICAgICogQHBhcmFtIHN0cmluZyB2YWx1ZVxuICAgICAqIEByZXR1cm5zIHtVUkxCdWlsZGVyfVxuICAgICAqL1xuICAgIHB1YmxpYyByZXBsYWNlU2VhcmNoUGFyYW0obmFtZTogc3RyaW5nLCAuLi52YWx1ZXM6IHN0cmluZ1tdKTogVVJMQnVpbGRlclxuICAgIHtcbiAgICAgICAgdGhpcy51cmwuc2VhcmNoUGFyYW1zLmRlbGV0ZShuYW1lKTtcblxuICAgICAgICBmb3IgKGxldCB2YWx1ZSBvZiB2YWx1ZXMpXG4gICAgICAgICAgICB0aGlzLnVybC5zZWFyY2hQYXJhbXMuYXBwZW5kKG5hbWUsIHZhbHVlKTtcblxuICAgICAgICByZXR1cm4gdGhpcztcbiAgICB9O1xuXG4gICAgLyoqXG4gICAgICogU2V0IHVzZXJuYW1lXG4gICAgICogXG4gICAgICogQHBhcmFtIHN0cmluZyB1c2VybmFtZVxuICAgICAqIEByZXR1cm4ge1VSTEJ1aWxkZXJ9XG4gICAgICovXG4gICAgcHVibGljIHVzZXJuYW1lKHVzZXJuYW1lOiBzdHJpbmcpOiBVUkxCdWlsZGVyXG4gICAge1xuICAgICAgICB0aGlzLnVybC51c2VybmFtZSA9IHVzZXJuYW1lO1xuXG4gICAgICAgIHJldHVybiB0aGlzO1xuICAgIH07XG5cbiAgICAvKipcbiAgICAgKiBCdWlsZCBVUkwgb2JqZWN0XG4gICAgICogXG4gICAgICogQHJldHVybnMge1VSTH1cbiAgICAgKi9cbiAgICBwdWJsaWMgYnVpbGQoKTogVVJMXG4gICAge1xuICAgICAgICByZXR1cm4gdGhpcy51cmw7XG4gICAgfTtcblxuICAgIC8qKlxuICAgICAqIENyZWF0ZSBhIG5ldyBpbnN0YW5jZSBmcm9tIGFuIGV4aXN0aW5nIFVSTC5cbiAgICAgKiBcbiAgICAgKiBAcGFyYW0gVVJMIHVybFxuICAgICAqIEByZXR1cm5zIHtVUkxCdWlsZGVyfVxuICAgICAqL1xuICAgIHB1YmxpYyBzdGF0aWMgZnJvbVVSTCh1cmw6IFVSTCk6IFVSTEJ1aWxkZXJcbiAgICB7XG4gICAgICAgIHJldHVybiBuZXcgVVJMQnVpbGRlcih1cmwpO1xuICAgIH07XG5cbiAgICAvKipcbiAgICAgKiBDcmVhdGUgYSBuZXcgaW5zdGFuY2UgZnJvbSBzdHJpbmcgYW5kIG9wdGlvbmFsIGJhc2UuXG4gICAgICogXG4gICAgICogQHBhcmFtIHN0cmluZyB1cmxcbiAgICAgKiBAcGFyYW0gc3RyaW5nIGJhc2VcbiAgICAgKiBAcmV0dXJucyB7VVJMQnVpbGRlcn1cbiAgICAgKi9cbiAgICBwdWJsaWMgc3RhdGljIGZyb21TdHJpbmcodXJsOiBzdHJpbmcsIGJhc2U/OiBzdHJpbmcpOiBVUkxCdWlsZGVyXG4gICAge1xuICAgICAgICByZXR1cm4gbmV3IFVSTEJ1aWxkZXIobmV3IFVSTCh1cmwsIGJhc2UpKTtcbiAgICB9O1xuXG59IiwidmFyIFhTRF9JTlRFR0VSID0gJ2h0dHA6Ly93d3cudzMub3JnLzIwMDEvWE1MU2NoZW1hI2ludGVnZXInO1xuXG5mdW5jdGlvbiBHZW5lcmF0b3Iob3B0aW9ucywgcHJlZml4ZXMpIHtcbiAgdGhpcy5fb3B0aW9ucyA9IG9wdGlvbnMgPSBvcHRpb25zIHx8IHt9O1xuXG4gIHByZWZpeGVzID0gcHJlZml4ZXMgfHwge307XG4gIHRoaXMuX3ByZWZpeEJ5SXJpID0ge307XG4gIHZhciBwcmVmaXhJcmlzID0gW107XG4gIGZvciAodmFyIHByZWZpeCBpbiBwcmVmaXhlcykge1xuICAgIHZhciBpcmkgPSBwcmVmaXhlc1twcmVmaXhdO1xuICAgIGlmIChpc1N0cmluZyhpcmkpKSB7XG4gICAgICB0aGlzLl9wcmVmaXhCeUlyaVtpcmldID0gcHJlZml4O1xuICAgICAgcHJlZml4SXJpcy5wdXNoKGlyaSk7XG4gICAgfVxuICB9XG4gIHZhciBpcmlMaXN0ID0gcHJlZml4SXJpcy5qb2luKCd8JykucmVwbGFjZSgvW1xcXVxcL1xcKFxcKVxcKlxcK1xcP1xcLlxcXFxcXCRdL2csICdcXFxcJCYnKTtcbiAgdGhpcy5fcHJlZml4UmVnZXggPSBuZXcgUmVnRXhwKCdeKCcgKyBpcmlMaXN0ICsgJykoW2EtekEtWl1bXFxcXC1fYS16QS1aMC05XSopJCcpO1xuICB0aGlzLl91c2VkUHJlZml4ZXMgPSB7fTtcbiAgdGhpcy5faW5kZW50ID0gIGlzU3RyaW5nKG9wdGlvbnMuaW5kZW50KSAgPyBvcHRpb25zLmluZGVudCAgOiAnICAnO1xuICB0aGlzLl9uZXdsaW5lID0gaXNTdHJpbmcob3B0aW9ucy5uZXdsaW5lKSA/IG9wdGlvbnMubmV3bGluZSA6ICdcXG4nO1xufVxuXG4vLyBDb252ZXJ0cyB0aGUgcGFyc2VkIHF1ZXJ5IG9iamVjdCBpbnRvIGEgU1BBUlFMIHF1ZXJ5XG5HZW5lcmF0b3IucHJvdG90eXBlLnRvUXVlcnkgPSBmdW5jdGlvbiAocSkge1xuICB2YXIgcXVlcnkgPSAnJztcblxuICBpZiAocS5xdWVyeVR5cGUpXG4gICAgcXVlcnkgKz0gcS5xdWVyeVR5cGUudG9VcHBlckNhc2UoKSArICcgJztcbiAgaWYgKHEucmVkdWNlZClcbiAgICBxdWVyeSArPSAnUkVEVUNFRCAnO1xuICBpZiAocS5kaXN0aW5jdClcbiAgICBxdWVyeSArPSAnRElTVElOQ1QgJztcblxuICBpZiAocS52YXJpYWJsZXMpXG4gICAgcXVlcnkgKz0gbWFwSm9pbihxLnZhcmlhYmxlcywgdW5kZWZpbmVkLCBmdW5jdGlvbiAodmFyaWFibGUpIHtcbiAgICAgIHJldHVybiBpc1N0cmluZyh2YXJpYWJsZSkgPyB0aGlzLnRvRW50aXR5KHZhcmlhYmxlKSA6XG4gICAgICAgICAgICAgJygnICsgdGhpcy50b0V4cHJlc3Npb24odmFyaWFibGUuZXhwcmVzc2lvbikgKyAnIEFTICcgKyB2YXJpYWJsZS52YXJpYWJsZSArICcpJztcbiAgICB9LCB0aGlzKSArICcgJztcbiAgZWxzZSBpZiAocS50ZW1wbGF0ZSlcbiAgICBxdWVyeSArPSB0aGlzLmdyb3VwKHEudGVtcGxhdGUsIHRydWUpICsgdGhpcy5fbmV3bGluZTtcblxuICBpZiAocS5mcm9tKVxuICAgIHF1ZXJ5ICs9IG1hcEpvaW4ocS5mcm9tLmRlZmF1bHQgfHwgW10sICcnLCBmdW5jdGlvbiAoZykgeyByZXR1cm4gJ0ZST00gJyArIHRoaXMudG9FbnRpdHkoZykgKyB0aGlzLl9uZXdsaW5lOyB9LCB0aGlzKSArXG4gICAgICAgICAgICAgbWFwSm9pbihxLmZyb20ubmFtZWQgfHwgW10sICcnLCBmdW5jdGlvbiAoZykgeyByZXR1cm4gJ0ZST00gTkFNRUQgJyArIHRoaXMudG9FbnRpdHkoZykgKyB0aGlzLl9uZXdsaW5lOyB9LCB0aGlzKTtcbiAgaWYgKHEud2hlcmUpXG4gICAgcXVlcnkgKz0gJ1dIRVJFICcgKyB0aGlzLmdyb3VwKHEud2hlcmUsIHRydWUpICsgdGhpcy5fbmV3bGluZTtcblxuICBpZiAocS51cGRhdGVzKVxuICAgIHF1ZXJ5ICs9IG1hcEpvaW4ocS51cGRhdGVzLCAnOycgKyB0aGlzLl9uZXdsaW5lLCB0aGlzLnRvVXBkYXRlLCB0aGlzKTtcblxuICBpZiAocS5ncm91cClcbiAgICBxdWVyeSArPSAnR1JPVVAgQlkgJyArIG1hcEpvaW4ocS5ncm91cCwgdW5kZWZpbmVkLCBmdW5jdGlvbiAoaXQpIHtcbiAgICAgIHZhciByZXN1bHQgPSBpc1N0cmluZyhpdC5leHByZXNzaW9uKSA/IGl0LmV4cHJlc3Npb24gOiAnKCcgKyB0aGlzLnRvRXhwcmVzc2lvbihpdC5leHByZXNzaW9uKSArICcpJztcbiAgICAgIHJldHVybiBpdC52YXJpYWJsZSA/ICcoJyArIHJlc3VsdCArICcgQVMgJyArIGl0LnZhcmlhYmxlICsgJyknIDogcmVzdWx0O1xuICAgIH0sIHRoaXMpICsgdGhpcy5fbmV3bGluZTtcbiAgaWYgKHEuaGF2aW5nKVxuICAgIHF1ZXJ5ICs9ICdIQVZJTkcgKCcgKyBtYXBKb2luKHEuaGF2aW5nLCB1bmRlZmluZWQsIHRoaXMudG9FeHByZXNzaW9uLCB0aGlzKSArICcpJyArIHRoaXMuX25ld2xpbmU7XG4gIGlmIChxLm9yZGVyKVxuICAgIHF1ZXJ5ICs9ICdPUkRFUiBCWSAnICsgbWFwSm9pbihxLm9yZGVyLCB1bmRlZmluZWQsIGZ1bmN0aW9uIChpdCkge1xuICAgICAgdmFyIGV4cHIgPSAnKCcgKyB0aGlzLnRvRXhwcmVzc2lvbihpdC5leHByZXNzaW9uKSArICcpJztcbiAgICAgIHJldHVybiAhaXQuZGVzY2VuZGluZyA/IGV4cHIgOiAnREVTQyAnICsgZXhwcjtcbiAgICB9LCB0aGlzKSArIHRoaXMuX25ld2xpbmU7XG5cbiAgaWYgKHEub2Zmc2V0KVxuICAgIHF1ZXJ5ICs9ICdPRkZTRVQgJyArIHEub2Zmc2V0ICsgdGhpcy5fbmV3bGluZTtcbiAgaWYgKHEubGltaXQpXG4gICAgcXVlcnkgKz0gJ0xJTUlUICcgKyBxLmxpbWl0ICsgdGhpcy5fbmV3bGluZTtcblxuICBpZiAocS52YWx1ZXMpXG4gICAgcXVlcnkgKz0gdGhpcy52YWx1ZXMocSk7XG5cbiAgLy8gc3RyaW5naWZ5IHByZWZpeGVzIGF0IHRoZSBlbmQgdG8gbWFyayB1c2VkIG9uZXNcbiAgcXVlcnkgPSB0aGlzLmJhc2VBbmRQcmVmaXhlcyhxKSArIHF1ZXJ5O1xuICByZXR1cm4gcXVlcnkudHJpbSgpO1xufTtcblxuR2VuZXJhdG9yLnByb3RvdHlwZS5iYXNlQW5kUHJlZml4ZXMgPSBmdW5jdGlvbiAocSkge1xuICB2YXIgYmFzZSA9IHEuYmFzZSA/ICgnQkFTRSA8JyArIHEuYmFzZSArICc+JyArIHRoaXMuX25ld2xpbmUpIDogJyc7XG4gIHZhciBwcmVmaXhlcyA9ICcnO1xuICBmb3IgKHZhciBrZXkgaW4gcS5wcmVmaXhlcykge1xuICAgIGlmICh0aGlzLl9vcHRpb25zLmFsbFByZWZpeGVzIHx8IHRoaXMuX3VzZWRQcmVmaXhlc1trZXldKVxuICAgICAgcHJlZml4ZXMgKz0gJ1BSRUZJWCAnICsga2V5ICsgJzogPCcgKyBxLnByZWZpeGVzW2tleV0gKyAnPicgKyB0aGlzLl9uZXdsaW5lO1xuICB9XG4gIHJldHVybiBiYXNlICsgcHJlZml4ZXM7XG59O1xuXG4vLyBDb252ZXJ0cyB0aGUgcGFyc2VkIFNQQVJRTCBwYXR0ZXJuIGludG8gYSBTUEFSUUwgcGF0dGVyblxuR2VuZXJhdG9yLnByb3RvdHlwZS50b1BhdHRlcm4gPSBmdW5jdGlvbiAocGF0dGVybikge1xuICB2YXIgdHlwZSA9IHBhdHRlcm4udHlwZSB8fCAocGF0dGVybiBpbnN0YW5jZW9mIEFycmF5KSAmJiAnYXJyYXknIHx8XG4gICAgICAgICAgICAgKHBhdHRlcm4uc3ViamVjdCAmJiBwYXR0ZXJuLnByZWRpY2F0ZSAmJiBwYXR0ZXJuLm9iamVjdCA/ICd0cmlwbGUnIDogJycpO1xuICBpZiAoISh0eXBlIGluIHRoaXMpKVxuICAgIHRocm93IG5ldyBFcnJvcignVW5rbm93biBlbnRyeSB0eXBlOiAnICsgdHlwZSk7XG4gIHJldHVybiB0aGlzW3R5cGVdKHBhdHRlcm4pO1xufTtcblxuR2VuZXJhdG9yLnByb3RvdHlwZS50cmlwbGUgPSBmdW5jdGlvbiAodCkge1xuICByZXR1cm4gdGhpcy50b0VudGl0eSh0LnN1YmplY3QpICsgJyAnICsgdGhpcy50b0VudGl0eSh0LnByZWRpY2F0ZSkgKyAnICcgKyB0aGlzLnRvRW50aXR5KHQub2JqZWN0KSArICcuJztcbn07XG5cbkdlbmVyYXRvci5wcm90b3R5cGUuYXJyYXkgPSBmdW5jdGlvbiAoaXRlbXMpIHtcbiAgcmV0dXJuIG1hcEpvaW4oaXRlbXMsIHRoaXMuX25ld2xpbmUsIHRoaXMudG9QYXR0ZXJuLCB0aGlzKTtcbn07XG5cbkdlbmVyYXRvci5wcm90b3R5cGUuYmdwID0gZnVuY3Rpb24gKGJncCkge1xuICByZXR1cm4gdGhpcy5lbmNvZGVUcmlwbGVzKGJncC50cmlwbGVzKTtcbn07XG5cbkdlbmVyYXRvci5wcm90b3R5cGUuZW5jb2RlVHJpcGxlcyA9IGZ1bmN0aW9uICh0cmlwbGVzKSB7XG4gIGlmICghdHJpcGxlcy5sZW5ndGgpXG4gICAgcmV0dXJuICcnO1xuXG4gIHZhciBwYXJ0cyA9IFtdLCBzdWJqZWN0ID0gJycsIHByZWRpY2F0ZSA9ICcnO1xuICBmb3IgKHZhciBpID0gMDsgaSA8IHRyaXBsZXMubGVuZ3RoOyBpKyspIHtcbiAgICB2YXIgdHJpcGxlID0gdHJpcGxlc1tpXTtcbiAgICAvLyBUcmlwbGUgd2l0aCBkaWZmZXJlbnQgc3ViamVjdFxuICAgIGlmICh0cmlwbGUuc3ViamVjdCAhPT0gc3ViamVjdCkge1xuICAgICAgLy8gVGVybWluYXRlIHByZXZpb3VzIHRyaXBsZVxuICAgICAgaWYgKHN1YmplY3QpXG4gICAgICAgIHBhcnRzLnB1c2goJy4nICsgdGhpcy5fbmV3bGluZSk7XG4gICAgICBzdWJqZWN0ID0gdHJpcGxlLnN1YmplY3Q7XG4gICAgICBwcmVkaWNhdGUgPSB0cmlwbGUucHJlZGljYXRlO1xuICAgICAgcGFydHMucHVzaCh0aGlzLnRvRW50aXR5KHN1YmplY3QpLCAnICcsIHRoaXMudG9FbnRpdHkocHJlZGljYXRlKSk7XG4gICAgfVxuICAgIC8vIFRyaXBsZSB3aXRoIHNhbWUgc3ViamVjdCBidXQgZGlmZmVyZW50IHByZWRpY2F0ZVxuICAgIGVsc2UgaWYgKHRyaXBsZS5wcmVkaWNhdGUgIT09IHByZWRpY2F0ZSkge1xuICAgICAgcHJlZGljYXRlID0gdHJpcGxlLnByZWRpY2F0ZTtcbiAgICAgIHBhcnRzLnB1c2goJzsnICsgdGhpcy5fbmV3bGluZSwgdGhpcy5faW5kZW50LCB0aGlzLnRvRW50aXR5KHByZWRpY2F0ZSkpO1xuICAgIH1cbiAgICAvLyBUcmlwbGUgd2l0aCBzYW1lIHN1YmplY3QgYW5kIHByZWRpY2F0ZVxuICAgIGVsc2Uge1xuICAgICAgcGFydHMucHVzaCgnLCcpO1xuICAgIH1cbiAgICBwYXJ0cy5wdXNoKCcgJywgdGhpcy50b0VudGl0eSh0cmlwbGUub2JqZWN0KSk7XG4gIH1cbiAgcGFydHMucHVzaCgnLicpO1xuXG4gIHJldHVybiBwYXJ0cy5qb2luKCcnKTtcbn1cblxuR2VuZXJhdG9yLnByb3RvdHlwZS5ncmFwaCA9IGZ1bmN0aW9uIChncmFwaCkge1xuICByZXR1cm4gJ0dSQVBIICcgKyB0aGlzLnRvRW50aXR5KGdyYXBoLm5hbWUpICsgJyAnICsgdGhpcy5ncm91cChncmFwaCk7XG59O1xuXG5HZW5lcmF0b3IucHJvdG90eXBlLmdyb3VwID0gZnVuY3Rpb24gKGdyb3VwLCBpbmxpbmUpIHtcbiAgZ3JvdXAgPSBpbmxpbmUgIT09IHRydWUgPyB0aGlzLmFycmF5KGdyb3VwLnBhdHRlcm5zIHx8IGdyb3VwLnRyaXBsZXMpXG4gICAgICAgICAgICAgICAgICAgICAgICAgIDogdGhpcy50b1BhdHRlcm4oZ3JvdXAudHlwZSAhPT0gJ2dyb3VwJyA/IGdyb3VwIDogZ3JvdXAucGF0dGVybnMpO1xuICByZXR1cm4gZ3JvdXAuaW5kZXhPZih0aGlzLl9uZXdsaW5lKSA9PT0gLTEgPyAneyAnICsgZ3JvdXAgKyAnIH0nIDogJ3snICsgdGhpcy5fbmV3bGluZSArIHRoaXMuaW5kZW50KGdyb3VwKSArIHRoaXMuX25ld2xpbmUgKyAnfSc7XG59O1xuXG5HZW5lcmF0b3IucHJvdG90eXBlLnF1ZXJ5ID0gZnVuY3Rpb24gKHF1ZXJ5KSB7XG4gIHJldHVybiB0aGlzLnRvUXVlcnkocXVlcnkpO1xufTtcblxuR2VuZXJhdG9yLnByb3RvdHlwZS5maWx0ZXIgPSBmdW5jdGlvbiAoZmlsdGVyKSB7XG4gIHJldHVybiAnRklMVEVSKCcgKyB0aGlzLnRvRXhwcmVzc2lvbihmaWx0ZXIuZXhwcmVzc2lvbikgKyAnKSc7XG59O1xuXG5HZW5lcmF0b3IucHJvdG90eXBlLmJpbmQgPSBmdW5jdGlvbiAoYmluZCkge1xuICByZXR1cm4gJ0JJTkQoJyArIHRoaXMudG9FeHByZXNzaW9uKGJpbmQuZXhwcmVzc2lvbikgKyAnIEFTICcgKyBiaW5kLnZhcmlhYmxlICsgJyknO1xufTtcblxuR2VuZXJhdG9yLnByb3RvdHlwZS5vcHRpb25hbCA9IGZ1bmN0aW9uIChvcHRpb25hbCkge1xuICByZXR1cm4gJ09QVElPTkFMICcgKyB0aGlzLmdyb3VwKG9wdGlvbmFsKTtcbn07XG5cbkdlbmVyYXRvci5wcm90b3R5cGUudW5pb24gPSBmdW5jdGlvbiAodW5pb24pIHtcbiAgcmV0dXJuIG1hcEpvaW4odW5pb24ucGF0dGVybnMsIHRoaXMuX25ld2xpbmUgKyAnVU5JT04nICsgdGhpcy5fbmV3bGluZSwgZnVuY3Rpb24gKHApIHsgcmV0dXJuIHRoaXMuZ3JvdXAocCwgdHJ1ZSk7IH0sIHRoaXMpO1xufTtcblxuR2VuZXJhdG9yLnByb3RvdHlwZS5taW51cyA9IGZ1bmN0aW9uIChtaW51cykge1xuICByZXR1cm4gJ01JTlVTICcgKyB0aGlzLmdyb3VwKG1pbnVzKTtcbn07XG5cbkdlbmVyYXRvci5wcm90b3R5cGUudmFsdWVzID0gZnVuY3Rpb24gKHZhbHVlc0xpc3QpIHtcbiAgLy8gR2F0aGVyIHVuaXF1ZSBrZXlzXG4gIHZhciBrZXlzID0gT2JqZWN0LmtleXModmFsdWVzTGlzdC52YWx1ZXMucmVkdWNlKGZ1bmN0aW9uIChrZXlIYXNoLCB2YWx1ZXMpIHtcbiAgICBmb3IgKHZhciBrZXkgaW4gdmFsdWVzKSBrZXlIYXNoW2tleV0gPSB0cnVlO1xuICAgIHJldHVybiBrZXlIYXNoO1xuICB9LCB7fSkpO1xuICAvLyBDaGVjayB3aGV0aGVyIHNpbXBsZSBzeW50YXggY2FuIGJlIHVzZWRcbiAgdmFyIGxwYXJlbiwgcnBhcmVuO1xuICBpZiAoa2V5cy5sZW5ndGggPT09IDEpIHtcbiAgICBscGFyZW4gPSBycGFyZW4gPSAnJztcbiAgfSBlbHNlIHtcbiAgICBscGFyZW4gPSAnKCc7XG4gICAgcnBhcmVuID0gJyknO1xuICB9XG4gIC8vIENyZWF0ZSB2YWx1ZSByb3dzXG4gIHJldHVybiAnVkFMVUVTICcgKyBscGFyZW4gKyBrZXlzLmpvaW4oJyAnKSArIHJwYXJlbiArICcgeycgKyB0aGlzLl9uZXdsaW5lICtcbiAgICBtYXBKb2luKHZhbHVlc0xpc3QudmFsdWVzLCB0aGlzLl9uZXdsaW5lLCBmdW5jdGlvbiAodmFsdWVzKSB7XG4gICAgICByZXR1cm4gJyAgJyArIGxwYXJlbiArIG1hcEpvaW4oa2V5cywgdW5kZWZpbmVkLCBmdW5jdGlvbiAoa2V5KSB7XG4gICAgICAgIHJldHVybiB2YWx1ZXNba2V5XSAhPT0gdW5kZWZpbmVkID8gdGhpcy50b0VudGl0eSh2YWx1ZXNba2V5XSkgOiAnVU5ERUYnO1xuICAgICAgfSwgdGhpcykgKyBycGFyZW47XG4gICAgfSwgdGhpcykgKyB0aGlzLl9uZXdsaW5lICsgJ30nO1xufTtcblxuR2VuZXJhdG9yLnByb3RvdHlwZS5zZXJ2aWNlID0gZnVuY3Rpb24gKHNlcnZpY2UpIHtcbiAgcmV0dXJuICdTRVJWSUNFICcgKyAoc2VydmljZS5zaWxlbnQgPyAnU0lMRU5UICcgOiAnJykgKyB0aGlzLnRvRW50aXR5KHNlcnZpY2UubmFtZSkgKyAnICcgK1xuICAgICAgICAgdGhpcy5ncm91cChzZXJ2aWNlKTtcbn07XG5cbi8vIENvbnZlcnRzIHRoZSBwYXJzZWQgZXhwcmVzc2lvbiBvYmplY3QgaW50byBhIFNQQVJRTCBleHByZXNzaW9uXG5HZW5lcmF0b3IucHJvdG90eXBlLnRvRXhwcmVzc2lvbiA9IGZ1bmN0aW9uIChleHByKSB7XG4gIGlmIChpc1N0cmluZyhleHByKSlcbiAgICByZXR1cm4gdGhpcy50b0VudGl0eShleHByKTtcblxuICBzd2l0Y2ggKGV4cHIudHlwZS50b0xvd2VyQ2FzZSgpKSB7XG4gICAgY2FzZSAnYWdncmVnYXRlJzpcbiAgICAgIHJldHVybiBleHByLmFnZ3JlZ2F0aW9uLnRvVXBwZXJDYXNlKCkgK1xuICAgICAgICAgICAgICcoJyArIChleHByLmRpc3RpbmN0ID8gJ0RJU1RJTkNUICcgOiAnJykgKyB0aGlzLnRvRXhwcmVzc2lvbihleHByLmV4cHJlc3Npb24pICtcbiAgICAgICAgICAgICAoZXhwci5zZXBhcmF0b3IgPyAnOyBTRVBBUkFUT1IgPSAnICsgdGhpcy50b0VudGl0eSgnXCInICsgZXhwci5zZXBhcmF0b3IgKyAnXCInKSA6ICcnKSArICcpJztcbiAgICBjYXNlICdmdW5jdGlvbmNhbGwnOlxuICAgICAgcmV0dXJuIHRoaXMudG9FbnRpdHkoZXhwci5mdW5jdGlvbikgKyAnKCcgKyBtYXBKb2luKGV4cHIuYXJncywgJywgJywgdGhpcy50b0V4cHJlc3Npb24sIHRoaXMpICsgJyknO1xuICAgIGNhc2UgJ29wZXJhdGlvbic6XG4gICAgICB2YXIgb3BlcmF0b3IgPSBleHByLm9wZXJhdG9yLnRvVXBwZXJDYXNlKCksIGFyZ3MgPSBleHByLmFyZ3MgfHwgW107XG4gICAgICBzd2l0Y2ggKGV4cHIub3BlcmF0b3IudG9Mb3dlckNhc2UoKSkge1xuICAgICAgLy8gSW5maXggb3BlcmF0b3JzXG4gICAgICBjYXNlICc8JzpcbiAgICAgIGNhc2UgJz4nOlxuICAgICAgY2FzZSAnPj0nOlxuICAgICAgY2FzZSAnPD0nOlxuICAgICAgY2FzZSAnJiYnOlxuICAgICAgY2FzZSAnfHwnOlxuICAgICAgY2FzZSAnPSc6XG4gICAgICBjYXNlICchPSc6XG4gICAgICBjYXNlICcrJzpcbiAgICAgIGNhc2UgJy0nOlxuICAgICAgY2FzZSAnKic6XG4gICAgICBjYXNlICcvJzpcbiAgICAgICAgICByZXR1cm4gKGlzU3RyaW5nKGFyZ3NbMF0pID8gdGhpcy50b0VudGl0eShhcmdzWzBdKSA6ICcoJyArIHRoaXMudG9FeHByZXNzaW9uKGFyZ3NbMF0pICsgJyknKSArXG4gICAgICAgICAgICAgICAgICcgJyArIG9wZXJhdG9yICsgJyAnICtcbiAgICAgICAgICAgICAgICAgKGlzU3RyaW5nKGFyZ3NbMV0pID8gdGhpcy50b0VudGl0eShhcmdzWzFdKSA6ICcoJyArIHRoaXMudG9FeHByZXNzaW9uKGFyZ3NbMV0pICsgJyknKTtcbiAgICAgIC8vIFVuYXJ5IG9wZXJhdG9yc1xuICAgICAgY2FzZSAnISc6XG4gICAgICAgIHJldHVybiAnISgnICsgdGhpcy50b0V4cHJlc3Npb24oYXJnc1swXSkgKyAnKSc7XG4gICAgICAvLyBJTiBhbmQgTk9UIElOXG4gICAgICBjYXNlICdub3Rpbic6XG4gICAgICAgIG9wZXJhdG9yID0gJ05PVCBJTic7XG4gICAgICBjYXNlICdpbic6XG4gICAgICAgIHJldHVybiB0aGlzLnRvRXhwcmVzc2lvbihhcmdzWzBdKSArICcgJyArIG9wZXJhdG9yICtcbiAgICAgICAgICAgICAgICcoJyArIChpc1N0cmluZyhhcmdzWzFdKSA/IGFyZ3NbMV0gOiBtYXBKb2luKGFyZ3NbMV0sICcsICcsIHRoaXMudG9FeHByZXNzaW9uLCB0aGlzKSkgKyAnKSc7XG4gICAgICAvLyBFWElTVFMgYW5kIE5PVCBFWElTVFNcbiAgICAgIGNhc2UgJ25vdGV4aXN0cyc6XG4gICAgICAgIG9wZXJhdG9yID0gJ05PVCBFWElTVFMnO1xuICAgICAgY2FzZSAnZXhpc3RzJzpcbiAgICAgICAgcmV0dXJuIG9wZXJhdG9yICsgJyAnICsgdGhpcy5ncm91cChhcmdzWzBdLCB0cnVlKTtcbiAgICAgIC8vIE90aGVyIGV4cHJlc3Npb25zXG4gICAgICBkZWZhdWx0OlxuICAgICAgICByZXR1cm4gb3BlcmF0b3IgKyAnKCcgKyBtYXBKb2luKGFyZ3MsICcsICcsIHRoaXMudG9FeHByZXNzaW9uLCB0aGlzKSArICcpJztcbiAgICAgIH1cbiAgICBkZWZhdWx0OlxuICAgICAgdGhyb3cgbmV3IEVycm9yKCdVbmtub3duIGV4cHJlc3Npb24gdHlwZTogJyArIGV4cHIudHlwZSk7XG4gIH1cbn07XG5cbi8vIENvbnZlcnRzIHRoZSBwYXJzZWQgZW50aXR5IChvciBwcm9wZXJ0eSBwYXRoKSBpbnRvIGEgU1BBUlFMIGVudGl0eVxuR2VuZXJhdG9yLnByb3RvdHlwZS50b0VudGl0eSA9IGZ1bmN0aW9uICh2YWx1ZSkge1xuICAvLyByZWd1bGFyIGVudGl0eVxuICBpZiAoaXNTdHJpbmcodmFsdWUpKSB7XG4gICAgc3dpdGNoICh2YWx1ZVswXSkge1xuICAgIC8vIHZhcmlhYmxlLCAqIHNlbGVjdG9yLCBvciBibGFuayBub2RlXG4gICAgY2FzZSAnPyc6XG4gICAgY2FzZSAnJCc6XG4gICAgY2FzZSAnKic6XG4gICAgY2FzZSAnXyc6XG4gICAgICByZXR1cm4gdmFsdWU7XG4gICAgLy8gbGl0ZXJhbFxuICAgIGNhc2UgJ1wiJzpcbiAgICAgIHZhciBtYXRjaCA9IHZhbHVlLm1hdGNoKC9eXCIoW15dKilcIig/OihALispfFxcXlxcXiguKykpPyQvKSB8fCB7fSxcbiAgICAgICAgICBsZXhpY2FsID0gbWF0Y2hbMV0gfHwgJycsIGxhbmd1YWdlID0gbWF0Y2hbMl0gfHwgJycsIGRhdGF0eXBlID0gbWF0Y2hbM107XG4gICAgICB2YWx1ZSA9ICdcIicgKyBsZXhpY2FsLnJlcGxhY2UoZXNjYXBlLCBlc2NhcGVSZXBsYWNlcikgKyAnXCInICsgbGFuZ3VhZ2U7XG4gICAgICBpZiAoZGF0YXR5cGUpIHtcbiAgICAgICAgaWYgKGRhdGF0eXBlID09PSBYU0RfSU5URUdFUiAmJiAvXlxcZCskLy50ZXN0KGxleGljYWwpKVxuICAgICAgICAgIC8vIEFkZCBzcGFjZSB0byBhdm9pZCBjb25mdXNpb24gd2l0aCBkZWNpbWFscyBpbiBicm9rZW4gcGFyc2Vyc1xuICAgICAgICAgIHJldHVybiBsZXhpY2FsICsgJyAnO1xuICAgICAgICB2YWx1ZSArPSAnXl4nICsgdGhpcy5lbmNvZGVJUkkoZGF0YXR5cGUpO1xuICAgICAgfVxuICAgICAgcmV0dXJuIHZhbHVlO1xuICAgIC8vIElSSVxuICAgIGRlZmF1bHQ6XG4gICAgICByZXR1cm4gdGhpcy5lbmNvZGVJUkkodmFsdWUpO1xuICAgIH1cbiAgfVxuICAvLyBwcm9wZXJ0eSBwYXRoXG4gIGVsc2Uge1xuICAgIHZhciBpdGVtcyA9IHZhbHVlLml0ZW1zLm1hcCh0aGlzLnRvRW50aXR5LCB0aGlzKSwgcGF0aCA9IHZhbHVlLnBhdGhUeXBlO1xuICAgIHN3aXRjaCAocGF0aCkge1xuICAgIC8vIHByZWZpeCBvcGVyYXRvclxuICAgIGNhc2UgJ14nOlxuICAgIGNhc2UgJyEnOlxuICAgICAgcmV0dXJuIHBhdGggKyBpdGVtc1swXTtcbiAgICAvLyBwb3N0Zml4IG9wZXJhdG9yXG4gICAgY2FzZSAnKic6XG4gICAgY2FzZSAnKyc6XG4gICAgY2FzZSAnPyc6XG4gICAgICByZXR1cm4gJygnICsgaXRlbXNbMF0gKyBwYXRoICsgJyknO1xuICAgIC8vIGluZml4IG9wZXJhdG9yXG4gICAgZGVmYXVsdDpcbiAgICAgIHJldHVybiAnKCcgKyBpdGVtcy5qb2luKHBhdGgpICsgJyknO1xuICAgIH1cbiAgfVxufTtcbnZhciBlc2NhcGUgPSAvW1wiXFxcXFxcdFxcblxcclxcYlxcZl0vZyxcbiAgICBlc2NhcGVSZXBsYWNlciA9IGZ1bmN0aW9uIChjKSB7IHJldHVybiBlc2NhcGVSZXBsYWNlbWVudHNbY107IH0sXG4gICAgZXNjYXBlUmVwbGFjZW1lbnRzID0geyAnXFxcXCc6ICdcXFxcXFxcXCcsICdcIic6ICdcXFxcXCInLCAnXFx0JzogJ1xcXFx0JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICdcXG4nOiAnXFxcXG4nLCAnXFxyJzogJ1xcXFxyJywgJ1xcYic6ICdcXFxcYicsICdcXGYnOiAnXFxcXGYnIH07XG5cbi8vIFJlcHJlc2VudCB0aGUgSVJJLCBhcyBhIHByZWZpeGVkIG5hbWUgd2hlbiBwb3NzaWJsZVxuR2VuZXJhdG9yLnByb3RvdHlwZS5lbmNvZGVJUkkgPSBmdW5jdGlvbiAoaXJpKSB7XG4gIHZhciBwcmVmaXhNYXRjaCA9IHRoaXMuX3ByZWZpeFJlZ2V4LmV4ZWMoaXJpKTtcbiAgaWYgKHByZWZpeE1hdGNoKSB7XG4gICAgdmFyIHByZWZpeCA9IHRoaXMuX3ByZWZpeEJ5SXJpW3ByZWZpeE1hdGNoWzFdXTtcbiAgICB0aGlzLl91c2VkUHJlZml4ZXNbcHJlZml4XSA9IHRydWU7XG4gICAgcmV0dXJuIHByZWZpeCArICc6JyArIHByZWZpeE1hdGNoWzJdO1xuICB9XG4gIHJldHVybiAnPCcgKyBpcmkgKyAnPic7XG59O1xuXG4vLyBDb252ZXJ0cyB0aGUgcGFyc2VkIHVwZGF0ZSBvYmplY3QgaW50byBhIFNQQVJRTCB1cGRhdGUgY2xhdXNlXG5HZW5lcmF0b3IucHJvdG90eXBlLnRvVXBkYXRlID0gZnVuY3Rpb24gKHVwZGF0ZSkge1xuICBzd2l0Y2ggKHVwZGF0ZS50eXBlIHx8IHVwZGF0ZS51cGRhdGVUeXBlKSB7XG4gIGNhc2UgJ2xvYWQnOlxuICAgIHJldHVybiAnTE9BRCcgKyAodXBkYXRlLnNvdXJjZSA/ICcgJyArIHRoaXMudG9FbnRpdHkodXBkYXRlLnNvdXJjZSkgOiAnJykgK1xuICAgICAgICAgICAodXBkYXRlLmRlc3RpbmF0aW9uID8gJyBJTlRPIEdSQVBIICcgKyB0aGlzLnRvRW50aXR5KHVwZGF0ZS5kZXN0aW5hdGlvbikgOiAnJyk7XG4gIGNhc2UgJ2luc2VydCc6XG4gICAgcmV0dXJuICdJTlNFUlQgREFUQSAnICArIHRoaXMuZ3JvdXAodXBkYXRlLmluc2VydCwgdHJ1ZSk7XG4gIGNhc2UgJ2RlbGV0ZSc6XG4gICAgcmV0dXJuICdERUxFVEUgREFUQSAnICArIHRoaXMuZ3JvdXAodXBkYXRlLmRlbGV0ZSwgdHJ1ZSk7XG4gIGNhc2UgJ2RlbGV0ZXdoZXJlJzpcbiAgICByZXR1cm4gJ0RFTEVURSBXSEVSRSAnICsgdGhpcy5ncm91cCh1cGRhdGUuZGVsZXRlLCB0cnVlKTtcbiAgY2FzZSAnaW5zZXJ0ZGVsZXRlJzpcbiAgICByZXR1cm4gKHVwZGF0ZS5ncmFwaCA/ICdXSVRIICcgKyB0aGlzLnRvRW50aXR5KHVwZGF0ZS5ncmFwaCkgKyB0aGlzLl9uZXdsaW5lIDogJycpICtcbiAgICAgICAgICAgKHVwZGF0ZS5kZWxldGUubGVuZ3RoID8gJ0RFTEVURSAnICsgdGhpcy5ncm91cCh1cGRhdGUuZGVsZXRlLCB0cnVlKSArIHRoaXMuX25ld2xpbmUgOiAnJykgK1xuICAgICAgICAgICAodXBkYXRlLmluc2VydC5sZW5ndGggPyAnSU5TRVJUICcgKyB0aGlzLmdyb3VwKHVwZGF0ZS5pbnNlcnQsIHRydWUpICsgdGhpcy5fbmV3bGluZSA6ICcnKSArXG4gICAgICAgICAgICdXSEVSRSAnICsgdGhpcy5ncm91cCh1cGRhdGUud2hlcmUsIHRydWUpO1xuICBjYXNlICdhZGQnOlxuICBjYXNlICdjb3B5JzpcbiAgY2FzZSAnbW92ZSc6XG4gICAgcmV0dXJuIHVwZGF0ZS50eXBlLnRvVXBwZXJDYXNlKCkgKyAodXBkYXRlLnNvdXJjZS5kZWZhdWx0ID8gJyBERUZBVUxUICcgOiAnICcpICtcbiAgICAgICAgICAgJ1RPICcgKyB0aGlzLnRvRW50aXR5KHVwZGF0ZS5kZXN0aW5hdGlvbi5uYW1lKTtcbiAgY2FzZSAnY3JlYXRlJzpcbiAgY2FzZSAnY2xlYXInOlxuICBjYXNlICdkcm9wJzpcbiAgICByZXR1cm4gdXBkYXRlLnR5cGUudG9VcHBlckNhc2UoKSArICh1cGRhdGUuc2lsZW50ID8gJyBTSUxFTlQgJyA6ICcgJykgKyAoXG4gICAgICB1cGRhdGUuZ3JhcGguZGVmYXVsdCA/ICdERUZBVUxUJyA6XG4gICAgICB1cGRhdGUuZ3JhcGgubmFtZWQgPyAnTkFNRUQnIDpcbiAgICAgIHVwZGF0ZS5ncmFwaC5hbGwgPyAnQUxMJyA6XG4gICAgICAoJ0dSQVBIICcgKyB0aGlzLnRvRW50aXR5KHVwZGF0ZS5ncmFwaC5uYW1lKSlcbiAgICApO1xuICBkZWZhdWx0OlxuICAgIHRocm93IG5ldyBFcnJvcignVW5rbm93biB1cGRhdGUgcXVlcnkgdHlwZTogJyArIHVwZGF0ZS50eXBlKTtcbiAgfVxufTtcblxuLy8gSW5kZW50cyBlYWNoIGxpbmUgb2YgdGhlIHN0cmluZ1xuR2VuZXJhdG9yLnByb3RvdHlwZS5pbmRlbnQgPSBmdW5jdGlvbih0ZXh0KSB7IHJldHVybiB0ZXh0LnJlcGxhY2UoL14vZ20sIHRoaXMuX2luZGVudCk7IH1cblxuLy8gQ2hlY2tzIHdoZXRoZXIgdGhlIG9iamVjdCBpcyBhIHN0cmluZ1xuZnVuY3Rpb24gaXNTdHJpbmcob2JqZWN0KSB7IHJldHVybiB0eXBlb2Ygb2JqZWN0ID09PSAnc3RyaW5nJzsgfVxuXG4vLyBNYXBzIHRoZSBhcnJheSB3aXRoIHRoZSBnaXZlbiBmdW5jdGlvbiwgYW5kIGpvaW5zIHRoZSByZXN1bHRzIHVzaW5nIHRoZSBzZXBhcmF0b3JcbmZ1bmN0aW9uIG1hcEpvaW4oYXJyYXksIHNlcCwgZnVuYywgc2VsZikge1xuICByZXR1cm4gYXJyYXkubWFwKGZ1bmMsIHNlbGYpLmpvaW4oaXNTdHJpbmcoc2VwKSA/IHNlcCA6ICcgJyk7XG59XG5cbi8qKlxuICogQHBhcmFtIG9wdGlvbnMge1xuICogICBhbGxQcmVmaXhlczogYm9vbGVhbixcbiAqICAgaW5kZW50YXRpb246IHN0cmluZyxcbiAqICAgbmV3bGluZTogc3RyaW5nXG4gKiB9XG4gKi9cbm1vZHVsZS5leHBvcnRzID0gZnVuY3Rpb24gU3BhcnFsR2VuZXJhdG9yKG9wdGlvbnMpIHtcbiAgcmV0dXJuIHtcbiAgICBzdHJpbmdpZnk6IGZ1bmN0aW9uIChxKSB7IHJldHVybiBuZXcgR2VuZXJhdG9yKG9wdGlvbnMsIHEucHJlZml4ZXMpLnRvUXVlcnkocSk7IH1cbiAgfTtcbn07XG4iLCIvKiBwYXJzZXIgZ2VuZXJhdGVkIGJ5IGppc29uIDAuNC4xOCAqL1xuLypcbiAgUmV0dXJucyBhIFBhcnNlciBvYmplY3Qgb2YgdGhlIGZvbGxvd2luZyBzdHJ1Y3R1cmU6XG5cbiAgUGFyc2VyOiB7XG4gICAgeXk6IHt9XG4gIH1cblxuICBQYXJzZXIucHJvdG90eXBlOiB7XG4gICAgeXk6IHt9LFxuICAgIHRyYWNlOiBmdW5jdGlvbigpLFxuICAgIHN5bWJvbHNfOiB7YXNzb2NpYXRpdmUgbGlzdDogbmFtZSA9PT4gbnVtYmVyfSxcbiAgICB0ZXJtaW5hbHNfOiB7YXNzb2NpYXRpdmUgbGlzdDogbnVtYmVyID09PiBuYW1lfSxcbiAgICBwcm9kdWN0aW9uc186IFsuLi5dLFxuICAgIHBlcmZvcm1BY3Rpb246IGZ1bmN0aW9uIGFub255bW91cyh5eXRleHQsIHl5bGVuZywgeXlsaW5lbm8sIHl5LCB5eXN0YXRlLCAkJCwgXyQpLFxuICAgIHRhYmxlOiBbLi4uXSxcbiAgICBkZWZhdWx0QWN0aW9uczogey4uLn0sXG4gICAgcGFyc2VFcnJvcjogZnVuY3Rpb24oc3RyLCBoYXNoKSxcbiAgICBwYXJzZTogZnVuY3Rpb24oaW5wdXQpLFxuXG4gICAgbGV4ZXI6IHtcbiAgICAgICAgRU9GOiAxLFxuICAgICAgICBwYXJzZUVycm9yOiBmdW5jdGlvbihzdHIsIGhhc2gpLFxuICAgICAgICBzZXRJbnB1dDogZnVuY3Rpb24oaW5wdXQpLFxuICAgICAgICBpbnB1dDogZnVuY3Rpb24oKSxcbiAgICAgICAgdW5wdXQ6IGZ1bmN0aW9uKHN0ciksXG4gICAgICAgIG1vcmU6IGZ1bmN0aW9uKCksXG4gICAgICAgIGxlc3M6IGZ1bmN0aW9uKG4pLFxuICAgICAgICBwYXN0SW5wdXQ6IGZ1bmN0aW9uKCksXG4gICAgICAgIHVwY29taW5nSW5wdXQ6IGZ1bmN0aW9uKCksXG4gICAgICAgIHNob3dQb3NpdGlvbjogZnVuY3Rpb24oKSxcbiAgICAgICAgdGVzdF9tYXRjaDogZnVuY3Rpb24ocmVnZXhfbWF0Y2hfYXJyYXksIHJ1bGVfaW5kZXgpLFxuICAgICAgICBuZXh0OiBmdW5jdGlvbigpLFxuICAgICAgICBsZXg6IGZ1bmN0aW9uKCksXG4gICAgICAgIGJlZ2luOiBmdW5jdGlvbihjb25kaXRpb24pLFxuICAgICAgICBwb3BTdGF0ZTogZnVuY3Rpb24oKSxcbiAgICAgICAgX2N1cnJlbnRSdWxlczogZnVuY3Rpb24oKSxcbiAgICAgICAgdG9wU3RhdGU6IGZ1bmN0aW9uKCksXG4gICAgICAgIHB1c2hTdGF0ZTogZnVuY3Rpb24oY29uZGl0aW9uKSxcblxuICAgICAgICBvcHRpb25zOiB7XG4gICAgICAgICAgICByYW5nZXM6IGJvb2xlYW4gICAgICAgICAgIChvcHRpb25hbDogdHJ1ZSA9PT4gdG9rZW4gbG9jYXRpb24gaW5mbyB3aWxsIGluY2x1ZGUgYSAucmFuZ2VbXSBtZW1iZXIpXG4gICAgICAgICAgICBmbGV4OiBib29sZWFuICAgICAgICAgICAgIChvcHRpb25hbDogdHJ1ZSA9PT4gZmxleC1saWtlIGxleGluZyBiZWhhdmlvdXIgd2hlcmUgdGhlIHJ1bGVzIGFyZSB0ZXN0ZWQgZXhoYXVzdGl2ZWx5IHRvIGZpbmQgdGhlIGxvbmdlc3QgbWF0Y2gpXG4gICAgICAgICAgICBiYWNrdHJhY2tfbGV4ZXI6IGJvb2xlYW4gIChvcHRpb25hbDogdHJ1ZSA9PT4gbGV4ZXIgcmVnZXhlcyBhcmUgdGVzdGVkIGluIG9yZGVyIGFuZCBmb3IgZWFjaCBtYXRjaGluZyByZWdleCB0aGUgYWN0aW9uIGNvZGUgaXMgaW52b2tlZDsgdGhlIGxleGVyIHRlcm1pbmF0ZXMgdGhlIHNjYW4gd2hlbiBhIHRva2VuIGlzIHJldHVybmVkIGJ5IHRoZSBhY3Rpb24gY29kZSlcbiAgICAgICAgfSxcblxuICAgICAgICBwZXJmb3JtQWN0aW9uOiBmdW5jdGlvbih5eSwgeXlfLCAkYXZvaWRpbmdfbmFtZV9jb2xsaXNpb25zLCBZWV9TVEFSVCksXG4gICAgICAgIHJ1bGVzOiBbLi4uXSxcbiAgICAgICAgY29uZGl0aW9uczoge2Fzc29jaWF0aXZlIGxpc3Q6IG5hbWUgPT0+IHNldH0sXG4gICAgfVxuICB9XG5cblxuICB0b2tlbiBsb2NhdGlvbiBpbmZvIChAJCwgXyQsIGV0Yy4pOiB7XG4gICAgZmlyc3RfbGluZTogbixcbiAgICBsYXN0X2xpbmU6IG4sXG4gICAgZmlyc3RfY29sdW1uOiBuLFxuICAgIGxhc3RfY29sdW1uOiBuLFxuICAgIHJhbmdlOiBbc3RhcnRfbnVtYmVyLCBlbmRfbnVtYmVyXSAgICAgICAod2hlcmUgdGhlIG51bWJlcnMgYXJlIGluZGV4ZXMgaW50byB0aGUgaW5wdXQgc3RyaW5nLCByZWd1bGFyIHplcm8tYmFzZWQpXG4gIH1cblxuXG4gIHRoZSBwYXJzZUVycm9yIGZ1bmN0aW9uIHJlY2VpdmVzIGEgJ2hhc2gnIG9iamVjdCB3aXRoIHRoZXNlIG1lbWJlcnMgZm9yIGxleGVyIGFuZCBwYXJzZXIgZXJyb3JzOiB7XG4gICAgdGV4dDogICAgICAgIChtYXRjaGVkIHRleHQpXG4gICAgdG9rZW46ICAgICAgICh0aGUgcHJvZHVjZWQgdGVybWluYWwgdG9rZW4sIGlmIGFueSlcbiAgICBsaW5lOiAgICAgICAgKHl5bGluZW5vKVxuICB9XG4gIHdoaWxlIHBhcnNlciAoZ3JhbW1hcikgZXJyb3JzIHdpbGwgYWxzbyBwcm92aWRlIHRoZXNlIG1lbWJlcnMsIGkuZS4gcGFyc2VyIGVycm9ycyBkZWxpdmVyIGEgc3VwZXJzZXQgb2YgYXR0cmlidXRlczoge1xuICAgIGxvYzogICAgICAgICAoeXlsbG9jKVxuICAgIGV4cGVjdGVkOiAgICAoc3RyaW5nIGRlc2NyaWJpbmcgdGhlIHNldCBvZiBleHBlY3RlZCB0b2tlbnMpXG4gICAgcmVjb3ZlcmFibGU6IChib29sZWFuOiBUUlVFIHdoZW4gdGhlIHBhcnNlciBoYXMgYSBlcnJvciByZWNvdmVyeSBydWxlIGF2YWlsYWJsZSBmb3IgdGhpcyBwYXJ0aWN1bGFyIGVycm9yKVxuICB9XG4qL1xudmFyIFNwYXJxbFBhcnNlciA9IChmdW5jdGlvbigpe1xudmFyIG89ZnVuY3Rpb24oayx2LG8sbCl7Zm9yKG89b3x8e30sbD1rLmxlbmd0aDtsLS07b1trW2xdXT12KTtyZXR1cm4gb30sJFYwPVs2LDEyLDE1LDI0LDM0LDQzLDQ4LDk5LDEwOSwxMTIsMTE0LDExNSwxMjQsMTI1LDEzMCwyOTgsMjk5LDMwMCwzMDEsMzAyXSwkVjE9WzIsMTk2XSwkVjI9Wzk5LDEwOSwxMTIsMTE0LDExNSwxMjQsMTI1LDEzMCwyOTgsMjk5LDMwMCwzMDEsMzAyXSwkVjM9WzEsMThdLCRWND1bMSwyN10sJFY1PVs2LDgzXSwkVjY9WzM4LDM5LDUxXSwkVjc9WzM4LDUxXSwkVjg9WzEsNTVdLCRWOT1bMSw1N10sJFZhPVsxLDUzXSwkVmI9WzEsNTZdLCRWYz1bMjgsMjksMjkzXSwkVmQ9WzEzLDE2LDI4Nl0sJFZlPVsxMTEsMTMzLDI5NiwzMDNdLCRWZj1bMTMsMTYsMTExLDEzMywyODZdLCRWZz1bMSw4MF0sJFZoPVsxLDg0XSwkVmk9WzEsODZdLCRWaj1bMTExLDEzMywyOTYsMjk3LDMwM10sJFZrPVsxMywxNiwxMTEsMTMzLDI4NiwyOTddLCRWbD1bMSw5Ml0sJFZtPVsyLDIzNl0sJFZuPVsxLDkxXSwkVm89WzEzLDE2LDI4LDI5LDgwLDg2LDIxNSwyMTgsMjE5LDI3MiwyNzMsMjc0LDI3NSwyNzYsMjc3LDI3OCwyNzksMjgwLDI4MSwyODIsMjgzLDI4NCwyODUsMjg2XSwkVnA9WzYsMzgsMzksNTEsNjEsNjgsNzEsNzksODEsODNdLCRWcT1bNiwxMywxNiwyOCwzOCwzOSw1MSw2MSw2OCw3MSw3OSw4MSw4MywyODZdLCRWcj1bNiwxMywxNiwyOCwyOSwzMSwzMiwzOCwzOSw0MSw1MSw2MSw2OCw3MSw3OSw4MCw4MSw4Myw4Niw5MiwxMDgsMTExLDEyNCwxMjUsMTI3LDEzMiwxNTksMTYwLDE2MiwxNjUsMTY2LDE4MywxODcsMjA4LDIxMywyMTUsMjE2LDIxOCwyMTksMjIzLDIyNywyMzEsMjQ2LDI1MSwyNjgsMjcyLDI3MywyNzQsMjc1LDI3NiwyNzcsMjc4LDI3OSwyODAsMjgxLDI4MiwyODMsMjg0LDI4NSwyODYsMjkzLDMwNCwzMDYsMzA3LDMwOSwzMTAsMzExLDMxMiwzMTMsMzE0LDMxNSwzMTZdLCRWcz1bMSwxMDddLCRWdD1bMSwxMDhdLCRWdT1bNiwxMywxNiwyOCwyOSwzOSw0MSw4MCw4Myw4NiwxMTEsMTU5LDE2MCwxNjIsMTY1LDE2NiwyMTUsMjE4LDIxOSwyNzIsMjczLDI3NCwyNzUsMjc2LDI3NywyNzgsMjc5LDI4MCwyODEsMjgyLDI4MywyODQsMjg1LDI4NiwzMDRdLCRWdj1bMiwyOTVdLCRWdz1bMSwxMjVdLCRWeD1bMSwxMjNdLCRWeT1bNiwxODNdLCRWej1bMiwzMTJdLCRWQT1bMiwzMDBdLCRWQj1bMzgsMTI3XSwkVkM9WzYsNDEsNjgsNzEsNzksODEsODNdLCRWRD1bMiwyMzhdLCRWRT1bMSwxMzldLCRWRj1bMSwxNDFdLCRWRz1bMSwxNTFdLCRWSD1bMSwxNTddLCRWST1bMSwxNjBdLCRWSj1bMSwxNTZdLCRWSz1bMSwxNThdLCRWTD1bMSwxNTRdLCRWTT1bMSwxNTVdLCRWTj1bMSwxNjFdLCRWTz1bMSwxNjJdLCRWUD1bMSwxNjVdLCRWUT1bMSwxNjZdLCRWUj1bMSwxNjddLCRWUz1bMSwxNjhdLCRWVD1bMSwxNjldLCRWVT1bMSwxNzBdLCRWVj1bMSwxNzFdLCRWVz1bMSwxNzJdLCRWWD1bMSwxNzNdLCRWWT1bMSwxNzRdLCRWWj1bMSwxNzVdLCRWXz1bMSwxNzZdLCRWJD1bNiw2MSw2OCw3MSw3OSw4MSw4M10sJFYwMT1bMjgsMjksMzgsMzksNTFdLCRWMTE9WzEzLDE2LDI4LDI5LDgwLDI0OCwyNDksMjUwLDI1MiwyNTQsMjU1LDI1NywyNTgsMjYxLDI2MywyNzIsMjczLDI3NCwyNzUsMjc2LDI3NywyNzgsMjc5LDI4MCwyODEsMjgyLDI4MywyODQsMjg1LDI4NiwzMTYsMzE3LDMxOCwzMTksMzIwLDMyMV0sJFYyMT1bMiw0MDldLCRWMzE9WzEsMTg5XSwkVjQxPVsxLDE5MF0sJFY1MT1bMSwxOTFdLCRWNjE9WzEzLDE2LDQxLDgwLDkyLDI3MiwyNzMsMjc0LDI3NSwyNzYsMjc3LDI3OCwyNzksMjgwLDI4MSwyODIsMjgzLDI4NCwyODUsMjg2XSwkVjcxPVs0MSw4Nl0sJFY4MT1bMjgsMzJdLCRWOTE9WzYsMTA4LDE4M10sJFZhMT1bNDEsMTExXSwkVmIxPVs2LDQxLDcxLDc5LDgxLDgzXSwkVmMxPVsyLDMyNF0sJFZkMT1bMiwzMTZdLCRWZTE9WzEsMjI2XSwkVmYxPVsxLDIyOF0sJFZnMT1bNDEsMTExLDMwNF0sJFZoMT1bMTMsMTYsMjgsMjksMzIsMzksNDEsODAsODMsODYsMTExLDE1OSwxNjAsMTYyLDE2NSwxNjYsMTgzLDE4NywyMDgsMjEzLDIxNSwyMTYsMjE4LDIxOSwyNTEsMjcyLDI3MywyNzQsMjc1LDI3NiwyNzcsMjc4LDI3OSwyODAsMjgxLDI4MiwyODMsMjg0LDI4NSwyODYsMzA0XSwkVmkxPVsxMywxNiwyOCwyOSwzMSwzMiwzOSw0MSw4MCw4Myw4Niw5MiwxMTEsMTU5LDE2MCwxNjIsMTY1LDE2NiwxODMsMTg3LDIwOCwyMTMsMjE1LDIxNiwyMTgsMjE5LDIyMywyMjcsMjMxLDI0NiwyNTEsMjY4LDI3MiwyNzMsMjc0LDI3NSwyNzYsMjc3LDI3OCwyNzksMjgwLDI4MSwyODIsMjgzLDI4NCwyODUsMjg2LDI5MywzMDQsMzA3LDMxMCwzMTEsMzEyLDMxMywzMTQsMzE1LDMxNl0sJFZqMT1bMTMsMTYsMjgsMjksMzEsMzIsMzksNDEsODAsODMsODYsOTIsMTExLDE1OSwxNjAsMTYyLDE2NSwxNjYsMTgzLDE4NywyMDgsMjEzLDIxNSwyMTYsMjE4LDIxOSwyMjMsMjI3LDIzMSwyNDYsMjUxLDI2OCwyNzAsMjcxLDI3MiwyNzMsMjc0LDI3NSwyNzYsMjc3LDI3OCwyNzksMjgwLDI4MSwyODIsMjgzLDI4NCwyODUsMjg2LDI5MywzMDQsMzA3LDMxMCwzMTEsMzEyLDMxMywzMTQsMzE1LDMxNl0sJFZrMT1bMzEsMzIsMTgzLDIyMywyNTFdLCRWbDE9WzMxLDMyLDE4MywyMjMsMjI3LDI1MV0sJFZtMT1bMzEsMzIsMTgzLDIyMywyMjcsMjMxLDI0NiwyNTEsMjY4LDI4MCwyODEsMjgyLDI4MywyODQsMjg1LDMxMCwzMTEsMzEyLDMxMywzMTQsMzE1LDMxNl0sJFZuMT1bMzEsMzIsMTgzLDIyMywyMjcsMjMxLDI0NiwyNTEsMjY4LDI4MCwyODEsMjgyLDI4MywyODQsMjg1LDI5MywzMDcsMzEwLDMxMSwzMTIsMzEzLDMxNCwzMTUsMzE2XSwkVm8xPVsxLDI2MF0sJFZwMT1bMSwyNjFdLCRWcTE9WzEsMjYzXSwkVnIxPVsxLDI2NF0sJFZzMT1bMSwyNjVdLCRWdDE9WzEsMjY2XSwkVnUxPVsxLDI2OF0sJFZ2MT1bMSwyNjldLCRWdzE9WzIsNDE2XSwkVngxPVsxLDI3MV0sJFZ5MT1bMSwyNzJdLCRWejE9WzEsMjczXSwkVkExPVsxLDI3OV0sJFZCMT1bMSwyNzRdLCRWQzE9WzEsMjc1XSwkVkQxPVsxLDI3Nl0sJFZFMT1bMSwyNzddLCRWRjE9WzEsMjc4XSwkVkcxPVsxLDI4Nl0sJFZIMT1bMSwyOTldLCRWSTE9WzYsNDEsNzksODEsODNdLCRWSjE9WzEsMzE2XSwkVksxPVsxLDMxNV0sJFZMMT1bMzksNDEsODMsMTExLDE1OSwxNjAsMTYyLDE2NSwxNjZdLCRWTTE9WzEsMzI0XSwkVk4xPVsxLDMyNV0sJFZPMT1bNDEsMTExLDE4MywyMTYsMzA0XSwkVlAxPVsyLDM1NF0sJFZRMT1bMTMsMTYsMjgsMjksMzIsODAsODYsMjE1LDIxOCwyMTksMjcyLDI3MywyNzQsMjc1LDI3NiwyNzcsMjc4LDI3OSwyODAsMjgxLDI4MiwyODMsMjg0LDI4NSwyODZdLCRWUjE9WzEzLDE2LDI4LDI5LDMyLDM5LDQxLDgwLDgzLDg2LDExMSwxNTksMTYwLDE2MiwxNjUsMTY2LDE4MywyMTUsMjE2LDIxOCwyMTksMjUxLDI3MiwyNzMsMjc0LDI3NSwyNzYsMjc3LDI3OCwyNzksMjgwLDI4MSwyODIsMjgzLDI4NCwyODUsMjg2LDMwNF0sJFZTMT1bMTMsMTYsMjgsMjksODAsMjA4LDI0NiwyNDgsMjQ5LDI1MCwyNTIsMjU0LDI1NSwyNTcsMjU4LDI2MSwyNjMsMjcyLDI3MywyNzQsMjc1LDI3NiwyNzcsMjc4LDI3OSwyODAsMjgxLDI4MiwyODMsMjg0LDI4NSwyODYsMzEwLDMxNiwzMTcsMzE4LDMxOSwzMjAsMzIxXSwkVlQxPVsxLDM0OV0sJFZVMT1bMSwzNTBdLCRWVjE9WzEsMzUyXSwkVlcxPVsxLDM1MV0sJFZYMT1bNiwxMywxNiwyOCwyOSwzMSwzMiwzOSw0MSw2OCw3MSw3NCw3Niw3OSw4MCw4MSw4Myw4NiwxMTEsMTU5LDE2MCwxNjIsMTY1LDE2NiwxODMsMjE1LDIxOCwyMTksMjIzLDIyNywyMzEsMjQ2LDI0OCwyNDksMjUwLDI1MSwyNTIsMjU0LDI1NSwyNTcsMjU4LDI2MSwyNjMsMjY4LDI3MiwyNzMsMjc0LDI3NSwyNzYsMjc3LDI3OCwyNzksMjgwLDI4MSwyODIsMjgzLDI4NCwyODUsMjg2LDI5MywzMDQsMzA3LDMxMCwzMTEsMzEyLDMxMywzMTQsMzE1LDMxNiwzMTcsMzE4LDMxOSwzMjAsMzIxXSwkVlkxPVsxLDM2MF0sJFZaMT1bMSwzNTldLCRWXzE9WzI5LDg2XSwkViQxPVsxMywxNiwzMiw0MSw4MCw5MiwyNzIsMjczLDI3NCwyNzUsMjc2LDI3NywyNzgsMjc5LDI4MCwyODEsMjgyLDI4MywyODQsMjg1LDI4Nl0sJFYwMj1bMjksNDFdLCRWMTI9WzIsMzE1XSwkVjIyPVs2LDQxLDgzXSwkVjMyPVs2LDEzLDE2LDI5LDQxLDcxLDc5LDgxLDgzLDI0OCwyNDksMjUwLDI1MiwyNTQsMjU1LDI1NywyNTgsMjYxLDI2MywyODYsMzE2LDMxNywzMTgsMzE5LDMyMCwzMjFdLCRWNDI9WzYsMTMsMTYsMjgsMjksMzksNDEsNzEsNzQsNzYsNzksODAsODEsODMsODYsMTExLDE1OSwxNjAsMTYyLDE2NSwxNjYsMjE1LDIxOCwyMTksMjQ4LDI0OSwyNTAsMjUyLDI1NCwyNTUsMjU3LDI1OCwyNjEsMjYzLDI3MiwyNzMsMjc0LDI3NSwyNzYsMjc3LDI3OCwyNzksMjgwLDI4MSwyODIsMjgzLDI4NCwyODUsMjg2LDMwNCwzMTYsMzE3LDMxOCwzMTksMzIwLDMyMV0sJFY1Mj1bNiwxMywxNiwyOCwyOSw0MSw2OCw3MSw3OSw4MSw4MywyNDgsMjQ5LDI1MCwyNTIsMjU0LDI1NSwyNTcsMjU4LDI2MSwyNjMsMjg2LDMxNiwzMTcsMzE4LDMxOSwzMjAsMzIxXSwkVjYyPVs2LDEzLDE2LDI4LDI5LDMxLDMyLDM5LDQxLDYxLDY4LDcxLDc0LDc2LDc5LDgwLDgxLDgzLDg2LDExMSwxNTksMTYwLDE2MiwxNjUsMTY2LDE4MywyMTUsMjE4LDIxOSwyMjMsMjI3LDIzMSwyNDYsMjQ4LDI0OSwyNTAsMjUxLDI1MiwyNTQsMjU1LDI1NywyNTgsMjYxLDI2MywyNjgsMjcyLDI3MywyNzQsMjc1LDI3NiwyNzcsMjc4LDI3OSwyODAsMjgxLDI4MiwyODMsMjg0LDI4NSwyODYsMjkzLDMwNCwzMDUsMzA3LDMxMCwzMTEsMzEyLDMxMywzMTQsMzE1LDMxNiwzMTcsMzE4LDMxOSwzMjAsMzIxXSwkVjcyPVsxMywxNiwyOSwxODcsMjA4LDIxMywyODZdLCRWODI9WzIsMzY2XSwkVjkyPVsxLDQwMV0sJFZhMj1bMzksNDEsODMsMTExLDE1OSwxNjAsMTYyLDE2NSwxNjYsMzA0XSwkVmIyPVsxMywxNiwyOCwyOSwzMiwzOSw0MSw4MCw4Myw4NiwxMTEsMTU5LDE2MCwxNjIsMTY1LDE2NiwxODMsMTg3LDIxNSwyMTYsMjE4LDIxOSwyNTEsMjcyLDI3MywyNzQsMjc1LDI3NiwyNzcsMjc4LDI3OSwyODAsMjgxLDI4MiwyODMsMjg0LDI4NSwyODYsMzA0XSwkVmMyPVsxMywxNiwyOCwyOSw4MCwyMDgsMjQ2LDI0OCwyNDksMjUwLDI1MiwyNTQsMjU1LDI1NywyNTgsMjYxLDI2MywyNzIsMjczLDI3NCwyNzUsMjc2LDI3NywyNzgsMjc5LDI4MCwyODEsMjgyLDI4MywyODQsMjg1LDI4NiwyOTMsMzEwLDMxNiwzMTcsMzE4LDMxOSwzMjAsMzIxXSwkVmQyPVsxLDQ1MF0sJFZlMj1bMSw0NDddLCRWZjI9WzEsNDQ4XSwkVmcyPVsxMywxNiwyOCwyOSwzOSw0MSw4MCw4Myw4NiwxMTEsMTU5LDE2MCwxNjIsMTY1LDE2NiwyMTUsMjE4LDIxOSwyNzIsMjczLDI3NCwyNzUsMjc2LDI3NywyNzgsMjc5LDI4MCwyODEsMjgyLDI4MywyODQsMjg1LDI4Nl0sJFZoMj1bMTMsMTYsMjgsMjg2XSwkVmkyPVsxMywxNiwyOCwyOSwzOSw0MSw4MCw4Myw4NiwxMTEsMTU5LDE2MCwxNjIsMTY1LDE2NiwyMTUsMjE4LDIxOSwyNzIsMjczLDI3NCwyNzUsMjc2LDI3NywyNzgsMjc5LDI4MCwyODEsMjgyLDI4MywyODQsMjg1LDI4NiwzMDRdLCRWajI9WzIsMzI3XSwkVmsyPVszOSw0MSw4MywxMTEsMTU5LDE2MCwxNjIsMTY1LDE2NiwxODMsMjE2LDMwNF0sJFZsMj1bNiwxMywxNiwyOCwyOSw0MSw3NCw3Niw3OSw4MSw4MywyNDgsMjQ5LDI1MCwyNTIsMjU0LDI1NSwyNTcsMjU4LDI2MSwyNjMsMjg2LDMxNiwzMTcsMzE4LDMxOSwzMjAsMzIxXSwkVm0yPVsyLDMyMl0sJFZuMj1bMTMsMTYsMjksMTg3LDIwOCwyODZdLCRWbzI9WzEzLDE2LDMyLDgwLDkyLDI3MiwyNzMsMjc0LDI3NSwyNzYsMjc3LDI3OCwyNzksMjgwLDI4MSwyODIsMjgzLDI4NCwyODUsMjg2XSwkVnAyPVsxMywxNiwyOCwyOSw0MSw4MCw4NiwxMTEsMjE1LDIxOCwyMTksMjcyLDI3MywyNzQsMjc1LDI3NiwyNzcsMjc4LDI3OSwyODAsMjgxLDI4MiwyODMsMjg0LDI4NSwyODZdLCRWcTI9WzEzLDE2LDI4LDI5LDMyLDgwLDg2LDIxNSwyMTgsMjE5LDI3MiwyNzMsMjc0LDI3NSwyNzYsMjc3LDI3OCwyNzksMjgwLDI4MSwyODIsMjgzLDI4NCwyODUsMjg2LDMwNiwzMDddLCRWcjI9WzEzLDE2LDI4LDI5LDMyLDgwLDg2LDIxNSwyMTgsMjE5LDI3MiwyNzMsMjc0LDI3NSwyNzYsMjc3LDI3OCwyNzksMjgwLDI4MSwyODIsMjgzLDI4NCwyODUsMjg2LDI5MywzMDYsMzA3LDMwOSwzMTBdLCRWczI9WzEsNTYxXSwkVnQyPVsxLDU2Ml0sJFZ1Mj1bMiwzMTBdLCRWdjI9WzEzLDE2LDMyLDE4NywyMTMsMjg2XTtcbnZhciBwYXJzZXIgPSB7dHJhY2U6IGZ1bmN0aW9uIHRyYWNlICgpIHsgfSxcbnl5OiB7fSxcbnN5bWJvbHNfOiB7XCJlcnJvclwiOjIsXCJRdWVyeU9yVXBkYXRlXCI6MyxcIlByb2xvZ3VlXCI6NCxcIlF1ZXJ5T3JVcGRhdGVfZ3JvdXAwXCI6NSxcIkVPRlwiOjYsXCJQcm9sb2d1ZV9yZXBldGl0aW9uMFwiOjcsXCJRdWVyeVwiOjgsXCJRdWVyeV9ncm91cDBcIjo5LFwiUXVlcnlfb3B0aW9uMFwiOjEwLFwiQmFzZURlY2xcIjoxMSxcIkJBU0VcIjoxMixcIklSSVJFRlwiOjEzLFwiUHJlZml4RGVjbFwiOjE0LFwiUFJFRklYXCI6MTUsXCJQTkFNRV9OU1wiOjE2LFwiU2VsZWN0UXVlcnlcIjoxNyxcIlNlbGVjdENsYXVzZVwiOjE4LFwiU2VsZWN0UXVlcnlfcmVwZXRpdGlvbjBcIjoxOSxcIldoZXJlQ2xhdXNlXCI6MjAsXCJTb2x1dGlvbk1vZGlmaWVyXCI6MjEsXCJTdWJTZWxlY3RcIjoyMixcIlN1YlNlbGVjdF9vcHRpb24wXCI6MjMsXCJTRUxFQ1RcIjoyNCxcIlNlbGVjdENsYXVzZV9vcHRpb24wXCI6MjUsXCJTZWxlY3RDbGF1c2VfZ3JvdXAwXCI6MjYsXCJTZWxlY3RDbGF1c2VJdGVtXCI6MjcsXCJWQVJcIjoyOCxcIihcIjoyOSxcIkV4cHJlc3Npb25cIjozMCxcIkFTXCI6MzEsXCIpXCI6MzIsXCJDb25zdHJ1Y3RRdWVyeVwiOjMzLFwiQ09OU1RSVUNUXCI6MzQsXCJDb25zdHJ1Y3RUZW1wbGF0ZVwiOjM1LFwiQ29uc3RydWN0UXVlcnlfcmVwZXRpdGlvbjBcIjozNixcIkNvbnN0cnVjdFF1ZXJ5X3JlcGV0aXRpb24xXCI6MzcsXCJXSEVSRVwiOjM4LFwie1wiOjM5LFwiQ29uc3RydWN0UXVlcnlfb3B0aW9uMFwiOjQwLFwifVwiOjQxLFwiRGVzY3JpYmVRdWVyeVwiOjQyLFwiREVTQ1JJQkVcIjo0MyxcIkRlc2NyaWJlUXVlcnlfZ3JvdXAwXCI6NDQsXCJEZXNjcmliZVF1ZXJ5X3JlcGV0aXRpb24wXCI6NDUsXCJEZXNjcmliZVF1ZXJ5X29wdGlvbjBcIjo0NixcIkFza1F1ZXJ5XCI6NDcsXCJBU0tcIjo0OCxcIkFza1F1ZXJ5X3JlcGV0aXRpb24wXCI6NDksXCJEYXRhc2V0Q2xhdXNlXCI6NTAsXCJGUk9NXCI6NTEsXCJEYXRhc2V0Q2xhdXNlX29wdGlvbjBcIjo1MixcImlyaVwiOjUzLFwiV2hlcmVDbGF1c2Vfb3B0aW9uMFwiOjU0LFwiR3JvdXBHcmFwaFBhdHRlcm5cIjo1NSxcIlNvbHV0aW9uTW9kaWZpZXJfb3B0aW9uMFwiOjU2LFwiU29sdXRpb25Nb2RpZmllcl9vcHRpb24xXCI6NTcsXCJTb2x1dGlvbk1vZGlmaWVyX29wdGlvbjJcIjo1OCxcIlNvbHV0aW9uTW9kaWZpZXJfb3B0aW9uM1wiOjU5LFwiR3JvdXBDbGF1c2VcIjo2MCxcIkdST1VQXCI6NjEsXCJCWVwiOjYyLFwiR3JvdXBDbGF1c2VfcmVwZXRpdGlvbl9wbHVzMFwiOjYzLFwiR3JvdXBDb25kaXRpb25cIjo2NCxcIkJ1aWx0SW5DYWxsXCI6NjUsXCJGdW5jdGlvbkNhbGxcIjo2NixcIkhhdmluZ0NsYXVzZVwiOjY3LFwiSEFWSU5HXCI6NjgsXCJIYXZpbmdDbGF1c2VfcmVwZXRpdGlvbl9wbHVzMFwiOjY5LFwiT3JkZXJDbGF1c2VcIjo3MCxcIk9SREVSXCI6NzEsXCJPcmRlckNsYXVzZV9yZXBldGl0aW9uX3BsdXMwXCI6NzIsXCJPcmRlckNvbmRpdGlvblwiOjczLFwiQVNDXCI6NzQsXCJCcmFja2V0dGVkRXhwcmVzc2lvblwiOjc1LFwiREVTQ1wiOjc2LFwiQ29uc3RyYWludFwiOjc3LFwiTGltaXRPZmZzZXRDbGF1c2VzXCI6NzgsXCJMSU1JVFwiOjc5LFwiSU5URUdFUlwiOjgwLFwiT0ZGU0VUXCI6ODEsXCJWYWx1ZXNDbGF1c2VcIjo4MixcIlZBTFVFU1wiOjgzLFwiSW5saW5lRGF0YVwiOjg0LFwiSW5saW5lRGF0YV9yZXBldGl0aW9uMFwiOjg1LFwiTklMXCI6ODYsXCJJbmxpbmVEYXRhX3JlcGV0aXRpb24xXCI6ODcsXCJJbmxpbmVEYXRhX3JlcGV0aXRpb25fcGx1czJcIjo4OCxcIklubGluZURhdGFfcmVwZXRpdGlvbjNcIjo4OSxcIkRhdGFCbG9ja1ZhbHVlXCI6OTAsXCJMaXRlcmFsXCI6OTEsXCJVTkRFRlwiOjkyLFwiRGF0YUJsb2NrVmFsdWVMaXN0XCI6OTMsXCJEYXRhQmxvY2tWYWx1ZUxpc3RfcmVwZXRpdGlvbl9wbHVzMFwiOjk0LFwiVXBkYXRlXCI6OTUsXCJVcGRhdGVfcmVwZXRpdGlvbjBcIjo5NixcIlVwZGF0ZTFcIjo5NyxcIlVwZGF0ZV9vcHRpb24wXCI6OTgsXCJMT0FEXCI6OTksXCJVcGRhdGUxX29wdGlvbjBcIjoxMDAsXCJVcGRhdGUxX29wdGlvbjFcIjoxMDEsXCJVcGRhdGUxX2dyb3VwMFwiOjEwMixcIlVwZGF0ZTFfb3B0aW9uMlwiOjEwMyxcIkdyYXBoUmVmQWxsXCI6MTA0LFwiVXBkYXRlMV9ncm91cDFcIjoxMDUsXCJVcGRhdGUxX29wdGlvbjNcIjoxMDYsXCJHcmFwaE9yRGVmYXVsdFwiOjEwNyxcIlRPXCI6MTA4LFwiQ1JFQVRFXCI6MTA5LFwiVXBkYXRlMV9vcHRpb240XCI6MTEwLFwiR1JBUEhcIjoxMTEsXCJJTlNFUlREQVRBXCI6MTEyLFwiUXVhZFBhdHRlcm5cIjoxMTMsXCJERUxFVEVEQVRBXCI6MTE0LFwiREVMRVRFV0hFUkVcIjoxMTUsXCJVcGRhdGUxX29wdGlvbjVcIjoxMTYsXCJJbnNlcnRDbGF1c2VcIjoxMTcsXCJVcGRhdGUxX29wdGlvbjZcIjoxMTgsXCJVcGRhdGUxX3JlcGV0aXRpb24wXCI6MTE5LFwiVXBkYXRlMV9vcHRpb243XCI6MTIwLFwiRGVsZXRlQ2xhdXNlXCI6MTIxLFwiVXBkYXRlMV9vcHRpb244XCI6MTIyLFwiVXBkYXRlMV9yZXBldGl0aW9uMVwiOjEyMyxcIkRFTEVURVwiOjEyNCxcIklOU0VSVFwiOjEyNSxcIlVzaW5nQ2xhdXNlXCI6MTI2LFwiVVNJTkdcIjoxMjcsXCJVc2luZ0NsYXVzZV9vcHRpb24wXCI6MTI4LFwiV2l0aENsYXVzZVwiOjEyOSxcIldJVEhcIjoxMzAsXCJJbnRvR3JhcGhDbGF1c2VcIjoxMzEsXCJJTlRPXCI6MTMyLFwiREVGQVVMVFwiOjEzMyxcIkdyYXBoT3JEZWZhdWx0X29wdGlvbjBcIjoxMzQsXCJHcmFwaFJlZkFsbF9ncm91cDBcIjoxMzUsXCJRdWFkUGF0dGVybl9vcHRpb24wXCI6MTM2LFwiUXVhZFBhdHRlcm5fcmVwZXRpdGlvbjBcIjoxMzcsXCJRdWFkc05vdFRyaXBsZXNcIjoxMzgsXCJRdWFkc05vdFRyaXBsZXNfZ3JvdXAwXCI6MTM5LFwiUXVhZHNOb3RUcmlwbGVzX29wdGlvbjBcIjoxNDAsXCJRdWFkc05vdFRyaXBsZXNfb3B0aW9uMVwiOjE0MSxcIlF1YWRzTm90VHJpcGxlc19vcHRpb24yXCI6MTQyLFwiVHJpcGxlc1RlbXBsYXRlXCI6MTQzLFwiVHJpcGxlc1RlbXBsYXRlX3JlcGV0aXRpb24wXCI6MTQ0LFwiVHJpcGxlc1NhbWVTdWJqZWN0XCI6MTQ1LFwiVHJpcGxlc1RlbXBsYXRlX29wdGlvbjBcIjoxNDYsXCJHcm91cEdyYXBoUGF0dGVyblN1YlwiOjE0NyxcIkdyb3VwR3JhcGhQYXR0ZXJuU3ViX29wdGlvbjBcIjoxNDgsXCJHcm91cEdyYXBoUGF0dGVyblN1Yl9yZXBldGl0aW9uMFwiOjE0OSxcIkdyb3VwR3JhcGhQYXR0ZXJuU3ViVGFpbFwiOjE1MCxcIkdyYXBoUGF0dGVybk5vdFRyaXBsZXNcIjoxNTEsXCJHcm91cEdyYXBoUGF0dGVyblN1YlRhaWxfb3B0aW9uMFwiOjE1MixcIkdyb3VwR3JhcGhQYXR0ZXJuU3ViVGFpbF9vcHRpb24xXCI6MTUzLFwiVHJpcGxlc0Jsb2NrXCI6MTU0LFwiVHJpcGxlc0Jsb2NrX3JlcGV0aXRpb24wXCI6MTU1LFwiVHJpcGxlc1NhbWVTdWJqZWN0UGF0aFwiOjE1NixcIlRyaXBsZXNCbG9ja19vcHRpb24wXCI6MTU3LFwiR3JhcGhQYXR0ZXJuTm90VHJpcGxlc19yZXBldGl0aW9uMFwiOjE1OCxcIk9QVElPTkFMXCI6MTU5LFwiTUlOVVNcIjoxNjAsXCJHcmFwaFBhdHRlcm5Ob3RUcmlwbGVzX2dyb3VwMFwiOjE2MSxcIlNFUlZJQ0VcIjoxNjIsXCJHcmFwaFBhdHRlcm5Ob3RUcmlwbGVzX29wdGlvbjBcIjoxNjMsXCJHcmFwaFBhdHRlcm5Ob3RUcmlwbGVzX2dyb3VwMVwiOjE2NCxcIkZJTFRFUlwiOjE2NSxcIkJJTkRcIjoxNjYsXCJGdW5jdGlvbkNhbGxfb3B0aW9uMFwiOjE2NyxcIkZ1bmN0aW9uQ2FsbF9yZXBldGl0aW9uMFwiOjE2OCxcIkV4cHJlc3Npb25MaXN0XCI6MTY5LFwiRXhwcmVzc2lvbkxpc3RfcmVwZXRpdGlvbjBcIjoxNzAsXCJDb25zdHJ1Y3RUZW1wbGF0ZV9vcHRpb24wXCI6MTcxLFwiQ29uc3RydWN0VHJpcGxlc1wiOjE3MixcIkNvbnN0cnVjdFRyaXBsZXNfcmVwZXRpdGlvbjBcIjoxNzMsXCJDb25zdHJ1Y3RUcmlwbGVzX29wdGlvbjBcIjoxNzQsXCJWYXJPclRlcm1cIjoxNzUsXCJQcm9wZXJ0eUxpc3ROb3RFbXB0eVwiOjE3NixcIlRyaXBsZXNOb2RlXCI6MTc3LFwiUHJvcGVydHlMaXN0XCI6MTc4LFwiUHJvcGVydHlMaXN0X29wdGlvbjBcIjoxNzksXCJWZXJiT2JqZWN0TGlzdFwiOjE4MCxcIlByb3BlcnR5TGlzdE5vdEVtcHR5X3JlcGV0aXRpb24wXCI6MTgxLFwiU2VtaU9wdGlvbmFsVmVyYk9iamVjdExpc3RcIjoxODIsXCI7XCI6MTgzLFwiU2VtaU9wdGlvbmFsVmVyYk9iamVjdExpc3Rfb3B0aW9uMFwiOjE4NCxcIlZlcmJcIjoxODUsXCJPYmplY3RMaXN0XCI6MTg2LFwiYVwiOjE4NyxcIk9iamVjdExpc3RfcmVwZXRpdGlvbjBcIjoxODgsXCJHcmFwaE5vZGVcIjoxODksXCJQcm9wZXJ0eUxpc3RQYXRoTm90RW1wdHlcIjoxOTAsXCJUcmlwbGVzTm9kZVBhdGhcIjoxOTEsXCJUcmlwbGVzU2FtZVN1YmplY3RQYXRoX29wdGlvbjBcIjoxOTIsXCJQcm9wZXJ0eUxpc3RQYXRoTm90RW1wdHlfZ3JvdXAwXCI6MTkzLFwiUHJvcGVydHlMaXN0UGF0aE5vdEVtcHR5X3JlcGV0aXRpb24wXCI6MTk0LFwiR3JhcGhOb2RlUGF0aFwiOjE5NSxcIlByb3BlcnR5TGlzdFBhdGhOb3RFbXB0eV9yZXBldGl0aW9uMVwiOjE5NixcIlByb3BlcnR5TGlzdFBhdGhOb3RFbXB0eVRhaWxcIjoxOTcsXCJQcm9wZXJ0eUxpc3RQYXRoTm90RW1wdHlUYWlsX2dyb3VwMFwiOjE5OCxcIlBhdGhcIjoxOTksXCJQYXRoX3JlcGV0aXRpb24wXCI6MjAwLFwiUGF0aFNlcXVlbmNlXCI6MjAxLFwiUGF0aFNlcXVlbmNlX3JlcGV0aXRpb24wXCI6MjAyLFwiUGF0aEVsdE9ySW52ZXJzZVwiOjIwMyxcIlBhdGhFbHRcIjoyMDQsXCJQYXRoUHJpbWFyeVwiOjIwNSxcIlBhdGhFbHRfb3B0aW9uMFwiOjIwNixcIlBhdGhFbHRPckludmVyc2Vfb3B0aW9uMFwiOjIwNyxcIiFcIjoyMDgsXCJQYXRoTmVnYXRlZFByb3BlcnR5U2V0XCI6MjA5LFwiUGF0aE9uZUluUHJvcGVydHlTZXRcIjoyMTAsXCJQYXRoTmVnYXRlZFByb3BlcnR5U2V0X3JlcGV0aXRpb24wXCI6MjExLFwiUGF0aE5lZ2F0ZWRQcm9wZXJ0eVNldF9vcHRpb24wXCI6MjEyLFwiXlwiOjIxMyxcIlRyaXBsZXNOb2RlX3JlcGV0aXRpb25fcGx1czBcIjoyMTQsXCJbXCI6MjE1LFwiXVwiOjIxNixcIlRyaXBsZXNOb2RlUGF0aF9yZXBldGl0aW9uX3BsdXMwXCI6MjE3LFwiQkxBTktfTk9ERV9MQUJFTFwiOjIxOCxcIkFOT05cIjoyMTksXCJDb25kaXRpb25hbEFuZEV4cHJlc3Npb25cIjoyMjAsXCJFeHByZXNzaW9uX3JlcGV0aXRpb24wXCI6MjIxLFwiRXhwcmVzc2lvblRhaWxcIjoyMjIsXCJ8fFwiOjIyMyxcIlJlbGF0aW9uYWxFeHByZXNzaW9uXCI6MjI0LFwiQ29uZGl0aW9uYWxBbmRFeHByZXNzaW9uX3JlcGV0aXRpb24wXCI6MjI1LFwiQ29uZGl0aW9uYWxBbmRFeHByZXNzaW9uVGFpbFwiOjIyNixcIiYmXCI6MjI3LFwiQWRkaXRpdmVFeHByZXNzaW9uXCI6MjI4LFwiUmVsYXRpb25hbEV4cHJlc3Npb25fZ3JvdXAwXCI6MjI5LFwiUmVsYXRpb25hbEV4cHJlc3Npb25fb3B0aW9uMFwiOjIzMCxcIklOXCI6MjMxLFwiTXVsdGlwbGljYXRpdmVFeHByZXNzaW9uXCI6MjMyLFwiQWRkaXRpdmVFeHByZXNzaW9uX3JlcGV0aXRpb24wXCI6MjMzLFwiQWRkaXRpdmVFeHByZXNzaW9uVGFpbFwiOjIzNCxcIkFkZGl0aXZlRXhwcmVzc2lvblRhaWxfZ3JvdXAwXCI6MjM1LFwiTnVtZXJpY0xpdGVyYWxQb3NpdGl2ZVwiOjIzNixcIkFkZGl0aXZlRXhwcmVzc2lvblRhaWxfcmVwZXRpdGlvbjBcIjoyMzcsXCJOdW1lcmljTGl0ZXJhbE5lZ2F0aXZlXCI6MjM4LFwiQWRkaXRpdmVFeHByZXNzaW9uVGFpbF9yZXBldGl0aW9uMVwiOjIzOSxcIlVuYXJ5RXhwcmVzc2lvblwiOjI0MCxcIk11bHRpcGxpY2F0aXZlRXhwcmVzc2lvbl9yZXBldGl0aW9uMFwiOjI0MSxcIk11bHRpcGxpY2F0aXZlRXhwcmVzc2lvblRhaWxcIjoyNDIsXCJNdWx0aXBsaWNhdGl2ZUV4cHJlc3Npb25UYWlsX2dyb3VwMFwiOjI0MyxcIlVuYXJ5RXhwcmVzc2lvbl9vcHRpb24wXCI6MjQ0LFwiUHJpbWFyeUV4cHJlc3Npb25cIjoyNDUsXCItXCI6MjQ2LFwiQWdncmVnYXRlXCI6MjQ3LFwiRlVOQ19BUklUWTBcIjoyNDgsXCJGVU5DX0FSSVRZMVwiOjI0OSxcIkZVTkNfQVJJVFkyXCI6MjUwLFwiLFwiOjI1MSxcIklGXCI6MjUyLFwiQnVpbHRJbkNhbGxfZ3JvdXAwXCI6MjUzLFwiQk9VTkRcIjoyNTQsXCJCTk9ERVwiOjI1NSxcIkJ1aWx0SW5DYWxsX29wdGlvbjBcIjoyNTYsXCJFWElTVFNcIjoyNTcsXCJDT1VOVFwiOjI1OCxcIkFnZ3JlZ2F0ZV9vcHRpb24wXCI6MjU5LFwiQWdncmVnYXRlX2dyb3VwMFwiOjI2MCxcIkZVTkNfQUdHUkVHQVRFXCI6MjYxLFwiQWdncmVnYXRlX29wdGlvbjFcIjoyNjIsXCJHUk9VUF9DT05DQVRcIjoyNjMsXCJBZ2dyZWdhdGVfb3B0aW9uMlwiOjI2NCxcIkFnZ3JlZ2F0ZV9vcHRpb24zXCI6MjY1LFwiR3JvdXBDb25jYXRTZXBhcmF0b3JcIjoyNjYsXCJTRVBBUkFUT1JcIjoyNjcsXCI9XCI6MjY4LFwiU3RyaW5nXCI6MjY5LFwiTEFOR1RBR1wiOjI3MCxcIl5eXCI6MjcxLFwiREVDSU1BTFwiOjI3MixcIkRPVUJMRVwiOjI3MyxcInRydWVcIjoyNzQsXCJmYWxzZVwiOjI3NSxcIlNUUklOR19MSVRFUkFMMVwiOjI3NixcIlNUUklOR19MSVRFUkFMMlwiOjI3NyxcIlNUUklOR19MSVRFUkFMX0xPTkcxXCI6Mjc4LFwiU1RSSU5HX0xJVEVSQUxfTE9ORzJcIjoyNzksXCJJTlRFR0VSX1BPU0lUSVZFXCI6MjgwLFwiREVDSU1BTF9QT1NJVElWRVwiOjI4MSxcIkRPVUJMRV9QT1NJVElWRVwiOjI4MixcIklOVEVHRVJfTkVHQVRJVkVcIjoyODMsXCJERUNJTUFMX05FR0FUSVZFXCI6Mjg0LFwiRE9VQkxFX05FR0FUSVZFXCI6Mjg1LFwiUE5BTUVfTE5cIjoyODYsXCJRdWVyeU9yVXBkYXRlX2dyb3VwMF9vcHRpb24wXCI6Mjg3LFwiUHJvbG9ndWVfcmVwZXRpdGlvbjBfZ3JvdXAwXCI6Mjg4LFwiU2VsZWN0Q2xhdXNlX29wdGlvbjBfZ3JvdXAwXCI6Mjg5LFwiRElTVElOQ1RcIjoyOTAsXCJSRURVQ0VEXCI6MjkxLFwiU2VsZWN0Q2xhdXNlX2dyb3VwMF9yZXBldGl0aW9uX3BsdXMwXCI6MjkyLFwiKlwiOjI5MyxcIkRlc2NyaWJlUXVlcnlfZ3JvdXAwX3JlcGV0aXRpb25fcGx1czBfZ3JvdXAwXCI6Mjk0LFwiRGVzY3JpYmVRdWVyeV9ncm91cDBfcmVwZXRpdGlvbl9wbHVzMFwiOjI5NSxcIk5BTUVEXCI6Mjk2LFwiU0lMRU5UXCI6Mjk3LFwiQ0xFQVJcIjoyOTgsXCJEUk9QXCI6Mjk5LFwiQUREXCI6MzAwLFwiTU9WRVwiOjMwMSxcIkNPUFlcIjozMDIsXCJBTExcIjozMDMsXCIuXCI6MzA0LFwiVU5JT05cIjozMDUsXCJ8XCI6MzA2LFwiL1wiOjMwNyxcIlBhdGhFbHRfb3B0aW9uMF9ncm91cDBcIjozMDgsXCI/XCI6MzA5LFwiK1wiOjMxMCxcIiE9XCI6MzExLFwiPFwiOjMxMixcIj5cIjozMTMsXCI8PVwiOjMxNCxcIj49XCI6MzE1LFwiTk9UXCI6MzE2LFwiQ09OQ0FUXCI6MzE3LFwiQ09BTEVTQ0VcIjozMTgsXCJTVUJTVFJcIjozMTksXCJSRUdFWFwiOjMyMCxcIlJFUExBQ0VcIjozMjEsXCIkYWNjZXB0XCI6MCxcIiRlbmRcIjoxfSxcbnRlcm1pbmFsc186IHsyOlwiZXJyb3JcIiw2OlwiRU9GXCIsMTI6XCJCQVNFXCIsMTM6XCJJUklSRUZcIiwxNTpcIlBSRUZJWFwiLDE2OlwiUE5BTUVfTlNcIiwyNDpcIlNFTEVDVFwiLDI4OlwiVkFSXCIsMjk6XCIoXCIsMzE6XCJBU1wiLDMyOlwiKVwiLDM0OlwiQ09OU1RSVUNUXCIsMzg6XCJXSEVSRVwiLDM5Olwie1wiLDQxOlwifVwiLDQzOlwiREVTQ1JJQkVcIiw0ODpcIkFTS1wiLDUxOlwiRlJPTVwiLDYxOlwiR1JPVVBcIiw2MjpcIkJZXCIsNjg6XCJIQVZJTkdcIiw3MTpcIk9SREVSXCIsNzQ6XCJBU0NcIiw3NjpcIkRFU0NcIiw3OTpcIkxJTUlUXCIsODA6XCJJTlRFR0VSXCIsODE6XCJPRkZTRVRcIiw4MzpcIlZBTFVFU1wiLDg2OlwiTklMXCIsOTI6XCJVTkRFRlwiLDk5OlwiTE9BRFwiLDEwODpcIlRPXCIsMTA5OlwiQ1JFQVRFXCIsMTExOlwiR1JBUEhcIiwxMTI6XCJJTlNFUlREQVRBXCIsMTE0OlwiREVMRVRFREFUQVwiLDExNTpcIkRFTEVURVdIRVJFXCIsMTI0OlwiREVMRVRFXCIsMTI1OlwiSU5TRVJUXCIsMTI3OlwiVVNJTkdcIiwxMzA6XCJXSVRIXCIsMTMyOlwiSU5UT1wiLDEzMzpcIkRFRkFVTFRcIiwxNTk6XCJPUFRJT05BTFwiLDE2MDpcIk1JTlVTXCIsMTYyOlwiU0VSVklDRVwiLDE2NTpcIkZJTFRFUlwiLDE2NjpcIkJJTkRcIiwxODM6XCI7XCIsMTg3OlwiYVwiLDIwODpcIiFcIiwyMTM6XCJeXCIsMjE1OlwiW1wiLDIxNjpcIl1cIiwyMTg6XCJCTEFOS19OT0RFX0xBQkVMXCIsMjE5OlwiQU5PTlwiLDIyMzpcInx8XCIsMjI3OlwiJiZcIiwyMzE6XCJJTlwiLDI0NjpcIi1cIiwyNDg6XCJGVU5DX0FSSVRZMFwiLDI0OTpcIkZVTkNfQVJJVFkxXCIsMjUwOlwiRlVOQ19BUklUWTJcIiwyNTE6XCIsXCIsMjUyOlwiSUZcIiwyNTQ6XCJCT1VORFwiLDI1NTpcIkJOT0RFXCIsMjU3OlwiRVhJU1RTXCIsMjU4OlwiQ09VTlRcIiwyNjE6XCJGVU5DX0FHR1JFR0FURVwiLDI2MzpcIkdST1VQX0NPTkNBVFwiLDI2NzpcIlNFUEFSQVRPUlwiLDI2ODpcIj1cIiwyNzA6XCJMQU5HVEFHXCIsMjcxOlwiXl5cIiwyNzI6XCJERUNJTUFMXCIsMjczOlwiRE9VQkxFXCIsMjc0OlwidHJ1ZVwiLDI3NTpcImZhbHNlXCIsMjc2OlwiU1RSSU5HX0xJVEVSQUwxXCIsMjc3OlwiU1RSSU5HX0xJVEVSQUwyXCIsMjc4OlwiU1RSSU5HX0xJVEVSQUxfTE9ORzFcIiwyNzk6XCJTVFJJTkdfTElURVJBTF9MT05HMlwiLDI4MDpcIklOVEVHRVJfUE9TSVRJVkVcIiwyODE6XCJERUNJTUFMX1BPU0lUSVZFXCIsMjgyOlwiRE9VQkxFX1BPU0lUSVZFXCIsMjgzOlwiSU5URUdFUl9ORUdBVElWRVwiLDI4NDpcIkRFQ0lNQUxfTkVHQVRJVkVcIiwyODU6XCJET1VCTEVfTkVHQVRJVkVcIiwyODY6XCJQTkFNRV9MTlwiLDI5MDpcIkRJU1RJTkNUXCIsMjkxOlwiUkVEVUNFRFwiLDI5MzpcIipcIiwyOTY6XCJOQU1FRFwiLDI5NzpcIlNJTEVOVFwiLDI5ODpcIkNMRUFSXCIsMjk5OlwiRFJPUFwiLDMwMDpcIkFERFwiLDMwMTpcIk1PVkVcIiwzMDI6XCJDT1BZXCIsMzAzOlwiQUxMXCIsMzA0OlwiLlwiLDMwNTpcIlVOSU9OXCIsMzA2OlwifFwiLDMwNzpcIi9cIiwzMDk6XCI/XCIsMzEwOlwiK1wiLDMxMTpcIiE9XCIsMzEyOlwiPFwiLDMxMzpcIj5cIiwzMTQ6XCI8PVwiLDMxNTpcIj49XCIsMzE2OlwiTk9UXCIsMzE3OlwiQ09OQ0FUXCIsMzE4OlwiQ09BTEVTQ0VcIiwzMTk6XCJTVUJTVFJcIiwzMjA6XCJSRUdFWFwiLDMyMTpcIlJFUExBQ0VcIn0sXG5wcm9kdWN0aW9uc186IFswLFszLDNdLFs0LDFdLFs4LDJdLFsxMSwyXSxbMTQsM10sWzE3LDRdLFsyMiw0XSxbMTgsM10sWzI3LDFdLFsyNyw1XSxbMzMsNV0sWzMzLDddLFs0Miw1XSxbNDcsNF0sWzUwLDNdLFsyMCwyXSxbMjEsNF0sWzYwLDNdLFs2NCwxXSxbNjQsMV0sWzY0LDNdLFs2NCw1XSxbNjQsMV0sWzY3LDJdLFs3MCwzXSxbNzMsMl0sWzczLDJdLFs3MywxXSxbNzMsMV0sWzc4LDJdLFs3OCwyXSxbNzgsNF0sWzc4LDRdLFs4MiwyXSxbODQsNF0sWzg0LDRdLFs4NCw2XSxbOTAsMV0sWzkwLDFdLFs5MCwxXSxbOTMsM10sWzk1LDNdLFs5Nyw0XSxbOTcsM10sWzk3LDVdLFs5Nyw0XSxbOTcsMl0sWzk3LDJdLFs5NywyXSxbOTcsNl0sWzk3LDZdLFsxMjEsMl0sWzExNywyXSxbMTI2LDNdLFsxMjksMl0sWzEzMSwzXSxbMTA3LDFdLFsxMDcsMl0sWzEwNCwyXSxbMTA0LDFdLFsxMTMsNF0sWzEzOCw3XSxbMTQzLDNdLFs1NSwzXSxbNTUsM10sWzE0NywyXSxbMTUwLDNdLFsxNTQsM10sWzE1MSwyXSxbMTUxLDJdLFsxNTEsMl0sWzE1MSwzXSxbMTUxLDRdLFsxNTEsMl0sWzE1MSw2XSxbMTUxLDFdLFs3NywxXSxbNzcsMV0sWzc3LDFdLFs2NiwyXSxbNjYsNl0sWzE2OSwxXSxbMTY5LDRdLFszNSwzXSxbMTcyLDNdLFsxNDUsMl0sWzE0NSwyXSxbMTc4LDFdLFsxNzYsMl0sWzE4MiwyXSxbMTgwLDJdLFsxODUsMV0sWzE4NSwxXSxbMTg1LDFdLFsxODYsMl0sWzE1NiwyXSxbMTU2LDJdLFsxOTAsNF0sWzE5NywxXSxbMTk3LDNdLFsxOTksMl0sWzIwMSwyXSxbMjA0LDJdLFsyMDMsMl0sWzIwNSwxXSxbMjA1LDFdLFsyMDUsMl0sWzIwNSwzXSxbMjA5LDFdLFsyMDksMV0sWzIwOSw0XSxbMjEwLDFdLFsyMTAsMV0sWzIxMCwyXSxbMjEwLDJdLFsxNzcsM10sWzE3NywzXSxbMTkxLDNdLFsxOTEsM10sWzE4OSwxXSxbMTg5LDFdLFsxOTUsMV0sWzE5NSwxXSxbMTc1LDFdLFsxNzUsMV0sWzE3NSwxXSxbMTc1LDFdLFsxNzUsMV0sWzE3NSwxXSxbMzAsMl0sWzIyMiwyXSxbMjIwLDJdLFsyMjYsMl0sWzIyNCwxXSxbMjI0LDNdLFsyMjQsNF0sWzIyOCwyXSxbMjM0LDJdLFsyMzQsMl0sWzIzNCwyXSxbMjMyLDJdLFsyNDIsMl0sWzI0MCwyXSxbMjQwLDJdLFsyNDAsMl0sWzI0NSwxXSxbMjQ1LDFdLFsyNDUsMV0sWzI0NSwxXSxbMjQ1LDFdLFsyNDUsMV0sWzc1LDNdLFs2NSwxXSxbNjUsMl0sWzY1LDRdLFs2NSw2XSxbNjUsOF0sWzY1LDJdLFs2NSw0XSxbNjUsMl0sWzY1LDRdLFs2NSwzXSxbMjQ3LDVdLFsyNDcsNV0sWzI0Nyw2XSxbMjY2LDRdLFs5MSwxXSxbOTEsMl0sWzkxLDNdLFs5MSwxXSxbOTEsMV0sWzkxLDFdLFs5MSwxXSxbOTEsMV0sWzkxLDFdLFs5MSwxXSxbMjY5LDFdLFsyNjksMV0sWzI2OSwxXSxbMjY5LDFdLFsyMzYsMV0sWzIzNiwxXSxbMjM2LDFdLFsyMzgsMV0sWzIzOCwxXSxbMjM4LDFdLFs1MywxXSxbNTMsMV0sWzUzLDFdLFsyODcsMF0sWzI4NywxXSxbNSwxXSxbNSwxXSxbMjg4LDFdLFsyODgsMV0sWzcsMF0sWzcsMl0sWzksMV0sWzksMV0sWzksMV0sWzksMV0sWzEwLDBdLFsxMCwxXSxbMTksMF0sWzE5LDJdLFsyMywwXSxbMjMsMV0sWzI4OSwxXSxbMjg5LDFdLFsyNSwwXSxbMjUsMV0sWzI5MiwxXSxbMjkyLDJdLFsyNiwxXSxbMjYsMV0sWzM2LDBdLFszNiwyXSxbMzcsMF0sWzM3LDJdLFs0MCwwXSxbNDAsMV0sWzI5NCwxXSxbMjk0LDFdLFsyOTUsMV0sWzI5NSwyXSxbNDQsMV0sWzQ0LDFdLFs0NSwwXSxbNDUsMl0sWzQ2LDBdLFs0NiwxXSxbNDksMF0sWzQ5LDJdLFs1MiwwXSxbNTIsMV0sWzU0LDBdLFs1NCwxXSxbNTYsMF0sWzU2LDFdLFs1NywwXSxbNTcsMV0sWzU4LDBdLFs1OCwxXSxbNTksMF0sWzU5LDFdLFs2MywxXSxbNjMsMl0sWzY5LDFdLFs2OSwyXSxbNzIsMV0sWzcyLDJdLFs4NSwwXSxbODUsMl0sWzg3LDBdLFs4NywyXSxbODgsMV0sWzg4LDJdLFs4OSwwXSxbODksMl0sWzk0LDFdLFs5NCwyXSxbOTYsMF0sWzk2LDRdLFs5OCwwXSxbOTgsMl0sWzEwMCwwXSxbMTAwLDFdLFsxMDEsMF0sWzEwMSwxXSxbMTAyLDFdLFsxMDIsMV0sWzEwMywwXSxbMTAzLDFdLFsxMDUsMV0sWzEwNSwxXSxbMTA1LDFdLFsxMDYsMF0sWzEwNiwxXSxbMTEwLDBdLFsxMTAsMV0sWzExNiwwXSxbMTE2LDFdLFsxMTgsMF0sWzExOCwxXSxbMTE5LDBdLFsxMTksMl0sWzEyMCwwXSxbMTIwLDFdLFsxMjIsMF0sWzEyMiwxXSxbMTIzLDBdLFsxMjMsMl0sWzEyOCwwXSxbMTI4LDFdLFsxMzQsMF0sWzEzNCwxXSxbMTM1LDFdLFsxMzUsMV0sWzEzNSwxXSxbMTM2LDBdLFsxMzYsMV0sWzEzNywwXSxbMTM3LDJdLFsxMzksMV0sWzEzOSwxXSxbMTQwLDBdLFsxNDAsMV0sWzE0MSwwXSxbMTQxLDFdLFsxNDIsMF0sWzE0MiwxXSxbMTQ0LDBdLFsxNDQsM10sWzE0NiwwXSxbMTQ2LDFdLFsxNDgsMF0sWzE0OCwxXSxbMTQ5LDBdLFsxNDksMl0sWzE1MiwwXSxbMTUyLDFdLFsxNTMsMF0sWzE1MywxXSxbMTU1LDBdLFsxNTUsM10sWzE1NywwXSxbMTU3LDFdLFsxNTgsMF0sWzE1OCwzXSxbMTYxLDFdLFsxNjEsMV0sWzE2MywwXSxbMTYzLDFdLFsxNjQsMV0sWzE2NCwxXSxbMTY3LDBdLFsxNjcsMV0sWzE2OCwwXSxbMTY4LDNdLFsxNzAsMF0sWzE3MCwzXSxbMTcxLDBdLFsxNzEsMV0sWzE3MywwXSxbMTczLDNdLFsxNzQsMF0sWzE3NCwxXSxbMTc5LDBdLFsxNzksMV0sWzE4MSwwXSxbMTgxLDJdLFsxODQsMF0sWzE4NCwxXSxbMTg4LDBdLFsxODgsM10sWzE5MiwwXSxbMTkyLDFdLFsxOTMsMV0sWzE5MywxXSxbMTk0LDBdLFsxOTQsM10sWzE5NiwwXSxbMTk2LDJdLFsxOTgsMV0sWzE5OCwxXSxbMjAwLDBdLFsyMDAsM10sWzIwMiwwXSxbMjAyLDNdLFszMDgsMV0sWzMwOCwxXSxbMzA4LDFdLFsyMDYsMF0sWzIwNiwxXSxbMjA3LDBdLFsyMDcsMV0sWzIxMSwwXSxbMjExLDNdLFsyMTIsMF0sWzIxMiwxXSxbMjE0LDFdLFsyMTQsMl0sWzIxNywxXSxbMjE3LDJdLFsyMjEsMF0sWzIyMSwyXSxbMjI1LDBdLFsyMjUsMl0sWzIyOSwxXSxbMjI5LDFdLFsyMjksMV0sWzIyOSwxXSxbMjI5LDFdLFsyMjksMV0sWzIzMCwwXSxbMjMwLDFdLFsyMzMsMF0sWzIzMywyXSxbMjM1LDFdLFsyMzUsMV0sWzIzNywwXSxbMjM3LDJdLFsyMzksMF0sWzIzOSwyXSxbMjQxLDBdLFsyNDEsMl0sWzI0MywxXSxbMjQzLDFdLFsyNDQsMF0sWzI0NCwxXSxbMjUzLDFdLFsyNTMsMV0sWzI1MywxXSxbMjUzLDFdLFsyNTMsMV0sWzI1NiwwXSxbMjU2LDFdLFsyNTksMF0sWzI1OSwxXSxbMjYwLDFdLFsyNjAsMV0sWzI2MiwwXSxbMjYyLDFdLFsyNjQsMF0sWzI2NCwxXSxbMjY1LDBdLFsyNjUsMV1dLFxucGVyZm9ybUFjdGlvbjogZnVuY3Rpb24gYW5vbnltb3VzKHl5dGV4dCwgeXlsZW5nLCB5eWxpbmVubywgeXksIHl5c3RhdGUgLyogYWN0aW9uWzFdICovLCAkJCAvKiB2c3RhY2sgKi8sIF8kIC8qIGxzdGFjayAqLykge1xuLyogdGhpcyA9PSB5eXZhbCAqL1xuXG52YXIgJDAgPSAkJC5sZW5ndGggLSAxO1xuc3dpdGNoICh5eXN0YXRlKSB7XG5jYXNlIDE6XG5cbiAgICAgICQkWyQwLTFdID0gJCRbJDAtMV0gfHwge307XG4gICAgICBpZiAoUGFyc2VyLmJhc2UpXG4gICAgICAgICQkWyQwLTFdLmJhc2UgPSBQYXJzZXIuYmFzZTtcbiAgICAgIFBhcnNlci5iYXNlID0gYmFzZSA9IGJhc2VQYXRoID0gYmFzZVJvb3QgPSAnJztcbiAgICAgICQkWyQwLTFdLnByZWZpeGVzID0gUGFyc2VyLnByZWZpeGVzO1xuICAgICAgUGFyc2VyLnByZWZpeGVzID0gbnVsbDtcbiAgICAgIHJldHVybiAkJFskMC0xXTtcbiAgICBcbmJyZWFrO1xuY2FzZSAzOlxudGhpcy4kID0gZXh0ZW5kKCQkWyQwLTFdLCAkJFskMF0sIHsgdHlwZTogJ3F1ZXJ5JyB9KTtcbmJyZWFrO1xuY2FzZSA0OlxuXG4gICAgICBQYXJzZXIuYmFzZSA9IHJlc29sdmVJUkkoJCRbJDBdKVxuICAgICAgYmFzZSA9IGJhc2VQYXRoID0gYmFzZVJvb3QgPSAnJztcbiAgICBcbmJyZWFrO1xuY2FzZSA1OlxuXG4gICAgICBpZiAoIVBhcnNlci5wcmVmaXhlcykgUGFyc2VyLnByZWZpeGVzID0ge307XG4gICAgICAkJFskMC0xXSA9ICQkWyQwLTFdLnN1YnN0cigwLCAkJFskMC0xXS5sZW5ndGggLSAxKTtcbiAgICAgICQkWyQwXSA9IHJlc29sdmVJUkkoJCRbJDBdKTtcbiAgICAgIFBhcnNlci5wcmVmaXhlc1skJFskMC0xXV0gPSAkJFskMF07XG4gICAgXG5icmVhaztcbmNhc2UgNjpcbnRoaXMuJCA9IGV4dGVuZCgkJFskMC0zXSwgZ3JvdXBEYXRhc2V0cygkJFskMC0yXSksICQkWyQwLTFdLCAkJFskMF0pO1xuYnJlYWs7XG5jYXNlIDc6XG50aGlzLiQgPSBleHRlbmQoJCRbJDAtM10sICQkWyQwLTJdLCAkJFskMC0xXSwgJCRbJDBdLCB7IHR5cGU6ICdxdWVyeScgfSk7XG5icmVhaztcbmNhc2UgODpcbnRoaXMuJCA9IGV4dGVuZCh7IHF1ZXJ5VHlwZTogJ1NFTEVDVCcsIHZhcmlhYmxlczogJCRbJDBdID09PSAnKicgPyBbJyonXSA6ICQkWyQwXSB9LCAkJFskMC0xXSAmJiAoJCRbJDAtMl0gPSBsb3dlcmNhc2UoJCRbJDAtMV0pLCAkJFskMC0xXSA9IHt9LCAkJFskMC0xXVskJFskMC0yXV0gPSB0cnVlLCAkJFskMC0xXSkpO1xuYnJlYWs7XG5jYXNlIDk6IGNhc2UgOTI6IGNhc2UgMTI0OiBjYXNlIDE1MTpcbnRoaXMuJCA9IHRvVmFyKCQkWyQwXSk7XG5icmVhaztcbmNhc2UgMTA6IGNhc2UgMjI6XG50aGlzLiQgPSBleHByZXNzaW9uKCQkWyQwLTNdLCB7IHZhcmlhYmxlOiB0b1ZhcigkJFskMC0xXSkgfSk7XG5icmVhaztcbmNhc2UgMTE6XG50aGlzLiQgPSBleHRlbmQoeyBxdWVyeVR5cGU6ICdDT05TVFJVQ1QnLCB0ZW1wbGF0ZTogJCRbJDAtM10gfSwgZ3JvdXBEYXRhc2V0cygkJFskMC0yXSksICQkWyQwLTFdLCAkJFskMF0pO1xuYnJlYWs7XG5jYXNlIDEyOlxudGhpcy4kID0gZXh0ZW5kKHsgcXVlcnlUeXBlOiAnQ09OU1RSVUNUJywgdGVtcGxhdGU6ICQkWyQwLTJdID0gKCQkWyQwLTJdID8gJCRbJDAtMl0udHJpcGxlcyA6IFtdKSB9LCBncm91cERhdGFzZXRzKCQkWyQwLTVdKSwgeyB3aGVyZTogWyB7IHR5cGU6ICdiZ3AnLCB0cmlwbGVzOiBhcHBlbmRBbGxUbyhbXSwgJCRbJDAtMl0pIH0gXSB9LCAkJFskMF0pO1xuYnJlYWs7XG5jYXNlIDEzOlxudGhpcy4kID0gZXh0ZW5kKHsgcXVlcnlUeXBlOiAnREVTQ1JJQkUnLCB2YXJpYWJsZXM6ICQkWyQwLTNdID09PSAnKicgPyBbJyonXSA6ICQkWyQwLTNdLm1hcCh0b1ZhcikgfSwgZ3JvdXBEYXRhc2V0cygkJFskMC0yXSksICQkWyQwLTFdLCAkJFskMF0pO1xuYnJlYWs7XG5jYXNlIDE0OlxudGhpcy4kID0gZXh0ZW5kKHsgcXVlcnlUeXBlOiAnQVNLJyB9LCBncm91cERhdGFzZXRzKCQkWyQwLTJdKSwgJCRbJDAtMV0sICQkWyQwXSk7XG5icmVhaztcbmNhc2UgMTU6IGNhc2UgNTQ6XG50aGlzLiQgPSB7IGlyaTogJCRbJDBdLCBuYW1lZDogISEkJFskMC0xXSB9O1xuYnJlYWs7XG5jYXNlIDE2OlxudGhpcy4kID0geyB3aGVyZTogJCRbJDBdLnBhdHRlcm5zIH07XG5icmVhaztcbmNhc2UgMTc6XG50aGlzLiQgPSBleHRlbmQoJCRbJDAtM10sICQkWyQwLTJdLCAkJFskMC0xXSwgJCRbJDBdKTtcbmJyZWFrO1xuY2FzZSAxODpcbnRoaXMuJCA9IHsgZ3JvdXA6ICQkWyQwXSB9O1xuYnJlYWs7XG5jYXNlIDE5OiBjYXNlIDIwOiBjYXNlIDI2OiBjYXNlIDI4OlxudGhpcy4kID0gZXhwcmVzc2lvbigkJFskMF0pO1xuYnJlYWs7XG5jYXNlIDIxOlxudGhpcy4kID0gZXhwcmVzc2lvbigkJFskMC0xXSk7XG5icmVhaztcbmNhc2UgMjM6IGNhc2UgMjk6XG50aGlzLiQgPSBleHByZXNzaW9uKHRvVmFyKCQkWyQwXSkpO1xuYnJlYWs7XG5jYXNlIDI0OlxudGhpcy4kID0geyBoYXZpbmc6ICQkWyQwXSB9O1xuYnJlYWs7XG5jYXNlIDI1OlxudGhpcy4kID0geyBvcmRlcjogJCRbJDBdIH07XG5icmVhaztcbmNhc2UgMjc6XG50aGlzLiQgPSBleHByZXNzaW9uKCQkWyQwXSwgeyBkZXNjZW5kaW5nOiB0cnVlIH0pO1xuYnJlYWs7XG5jYXNlIDMwOlxudGhpcy4kID0geyBsaW1pdDogIHRvSW50KCQkWyQwXSkgfTtcbmJyZWFrO1xuY2FzZSAzMTpcbnRoaXMuJCA9IHsgb2Zmc2V0OiB0b0ludCgkJFskMF0pIH07XG5icmVhaztcbmNhc2UgMzI6XG50aGlzLiQgPSB7IGxpbWl0OiB0b0ludCgkJFskMC0yXSksIG9mZnNldDogdG9JbnQoJCRbJDBdKSB9O1xuYnJlYWs7XG5jYXNlIDMzOlxudGhpcy4kID0geyBsaW1pdDogdG9JbnQoJCRbJDBdKSwgb2Zmc2V0OiB0b0ludCgkJFskMC0yXSkgfTtcbmJyZWFrO1xuY2FzZSAzNDpcbnRoaXMuJCA9IHsgdHlwZTogJ3ZhbHVlcycsIHZhbHVlczogJCRbJDBdIH07XG5icmVhaztcbmNhc2UgMzU6XG5cbiAgICAgICQkWyQwLTNdID0gdG9WYXIoJCRbJDAtM10pO1xuICAgICAgdGhpcy4kID0gJCRbJDAtMV0ubWFwKGZ1bmN0aW9uKHYpIHsgdmFyIG8gPSB7fTsgb1skJFskMC0zXV0gPSB2OyByZXR1cm4gbzsgfSlcbiAgICBcbmJyZWFrO1xuY2FzZSAzNjpcblxuICAgICAgdGhpcy4kID0gJCRbJDAtMV0ubWFwKGZ1bmN0aW9uKCkgeyByZXR1cm4ge307IH0pXG4gICAgXG5icmVhaztcbmNhc2UgMzc6XG5cbiAgICAgIHZhciBsZW5ndGggPSAkJFskMC00XS5sZW5ndGg7XG4gICAgICAkJFskMC00XSA9ICQkWyQwLTRdLm1hcCh0b1Zhcik7XG4gICAgICB0aGlzLiQgPSAkJFskMC0xXS5tYXAoZnVuY3Rpb24gKHZhbHVlcykge1xuICAgICAgICBpZiAodmFsdWVzLmxlbmd0aCAhPT0gbGVuZ3RoKVxuICAgICAgICAgIHRocm93IEVycm9yKCdJbmNvbnNpc3RlbnQgVkFMVUVTIGxlbmd0aCcpO1xuICAgICAgICB2YXIgdmFsdWVzT2JqZWN0ID0ge307XG4gICAgICAgIGZvcih2YXIgaSA9IDA7IGk8bGVuZ3RoOyBpKyspXG4gICAgICAgICAgdmFsdWVzT2JqZWN0WyQkWyQwLTRdW2ldXSA9IHZhbHVlc1tpXTtcbiAgICAgICAgcmV0dXJuIHZhbHVlc09iamVjdDtcbiAgICAgIH0pO1xuICAgIFxuYnJlYWs7XG5jYXNlIDQwOlxudGhpcy4kID0gdW5kZWZpbmVkO1xuYnJlYWs7XG5jYXNlIDQxOiBjYXNlIDg0OiBjYXNlIDEwODogY2FzZSAxNTI6XG50aGlzLiQgPSAkJFskMC0xXTtcbmJyZWFrO1xuY2FzZSA0MjpcbnRoaXMuJCA9IHsgdHlwZTogJ3VwZGF0ZScsIHVwZGF0ZXM6IGFwcGVuZFRvKCQkWyQwLTJdLCAkJFskMC0xXSkgfTtcbmJyZWFrO1xuY2FzZSA0MzpcbnRoaXMuJCA9IGV4dGVuZCh7IHR5cGU6ICdsb2FkJywgc2lsZW50OiAhISQkWyQwLTJdLCBzb3VyY2U6ICQkWyQwLTFdIH0sICQkWyQwXSAmJiB7IGRlc3RpbmF0aW9uOiAkJFskMF0gfSk7XG5icmVhaztcbmNhc2UgNDQ6XG50aGlzLiQgPSB7IHR5cGU6IGxvd2VyY2FzZSgkJFskMC0yXSksIHNpbGVudDogISEkJFskMC0xXSwgZ3JhcGg6ICQkWyQwXSB9O1xuYnJlYWs7XG5jYXNlIDQ1OlxudGhpcy4kID0geyB0eXBlOiBsb3dlcmNhc2UoJCRbJDAtNF0pLCBzaWxlbnQ6ICEhJCRbJDAtM10sIHNvdXJjZTogJCRbJDAtMl0sIGRlc3RpbmF0aW9uOiAkJFskMF0gfTtcbmJyZWFrO1xuY2FzZSA0NjpcbnRoaXMuJCA9IHsgdHlwZTogJ2NyZWF0ZScsIHNpbGVudDogISEkJFskMC0yXSwgZ3JhcGg6IHsgdHlwZTogJ2dyYXBoJywgbmFtZTogJCRbJDBdIH0gfTtcbmJyZWFrO1xuY2FzZSA0NzpcbnRoaXMuJCA9IHsgdXBkYXRlVHlwZTogJ2luc2VydCcsICAgICAgaW5zZXJ0OiAkJFskMF0gfTtcbmJyZWFrO1xuY2FzZSA0ODpcbnRoaXMuJCA9IHsgdXBkYXRlVHlwZTogJ2RlbGV0ZScsICAgICAgZGVsZXRlOiAkJFskMF0gfTtcbmJyZWFrO1xuY2FzZSA0OTpcbnRoaXMuJCA9IHsgdXBkYXRlVHlwZTogJ2RlbGV0ZXdoZXJlJywgZGVsZXRlOiAkJFskMF0gfTtcbmJyZWFrO1xuY2FzZSA1MDpcbnRoaXMuJCA9IGV4dGVuZCh7IHVwZGF0ZVR5cGU6ICdpbnNlcnRkZWxldGUnIH0sICQkWyQwLTVdLCB7IGluc2VydDogJCRbJDAtNF0gfHwgW10gfSwgeyBkZWxldGU6ICQkWyQwLTNdIHx8IFtdIH0sIGdyb3VwRGF0YXNldHMoJCRbJDAtMl0pLCB7IHdoZXJlOiAkJFskMF0ucGF0dGVybnMgfSk7XG5icmVhaztcbmNhc2UgNTE6XG50aGlzLiQgPSBleHRlbmQoeyB1cGRhdGVUeXBlOiAnaW5zZXJ0ZGVsZXRlJyB9LCAkJFskMC01XSwgeyBkZWxldGU6ICQkWyQwLTRdIHx8IFtdIH0sIHsgaW5zZXJ0OiAkJFskMC0zXSB8fCBbXSB9LCBncm91cERhdGFzZXRzKCQkWyQwLTJdKSwgeyB3aGVyZTogJCRbJDBdLnBhdHRlcm5zIH0pO1xuYnJlYWs7XG5jYXNlIDUyOiBjYXNlIDUzOiBjYXNlIDU2OiBjYXNlIDE0MzpcbnRoaXMuJCA9ICQkWyQwXTtcbmJyZWFrO1xuY2FzZSA1NTpcbnRoaXMuJCA9IHsgZ3JhcGg6ICQkWyQwXSB9O1xuYnJlYWs7XG5jYXNlIDU3OlxudGhpcy4kID0geyB0eXBlOiAnZ3JhcGgnLCBkZWZhdWx0OiB0cnVlIH07XG5icmVhaztcbmNhc2UgNTg6IGNhc2UgNTk6XG50aGlzLiQgPSB7IHR5cGU6ICdncmFwaCcsIG5hbWU6ICQkWyQwXSB9O1xuYnJlYWs7XG5jYXNlIDYwOlxuIHRoaXMuJCA9IHt9OyB0aGlzLiRbbG93ZXJjYXNlKCQkWyQwXSldID0gdHJ1ZTsgXG5icmVhaztcbmNhc2UgNjE6XG50aGlzLiQgPSAkJFskMC0yXSA/IHVuaW9uQWxsKCQkWyQwLTFdLCBbJCRbJDAtMl1dKSA6IHVuaW9uQWxsKCQkWyQwLTFdKTtcbmJyZWFrO1xuY2FzZSA2MjpcblxuICAgICAgdmFyIGdyYXBoID0gZXh0ZW5kKCQkWyQwLTNdIHx8IHsgdHJpcGxlczogW10gfSwgeyB0eXBlOiAnZ3JhcGgnLCBuYW1lOiB0b1ZhcigkJFskMC01XSkgfSk7XG4gICAgICB0aGlzLiQgPSAkJFskMF0gPyBbZ3JhcGgsICQkWyQwXV0gOiBbZ3JhcGhdO1xuICAgIFxuYnJlYWs7XG5jYXNlIDYzOiBjYXNlIDY4OlxudGhpcy4kID0geyB0eXBlOiAnYmdwJywgdHJpcGxlczogdW5pb25BbGwoJCRbJDAtMl0sIFskJFskMC0xXV0pIH07XG5icmVhaztcbmNhc2UgNjQ6XG50aGlzLiQgPSB7IHR5cGU6ICdncm91cCcsIHBhdHRlcm5zOiBbICQkWyQwLTFdIF0gfTtcbmJyZWFrO1xuY2FzZSA2NTpcbnRoaXMuJCA9IHsgdHlwZTogJ2dyb3VwJywgcGF0dGVybnM6ICQkWyQwLTFdIH07XG5icmVhaztcbmNhc2UgNjY6XG50aGlzLiQgPSAkJFskMC0xXSA/IHVuaW9uQWxsKFskJFskMC0xXV0sICQkWyQwXSkgOiB1bmlvbkFsbCgkJFskMF0pO1xuYnJlYWs7XG5jYXNlIDY3OlxudGhpcy4kID0gJCRbJDBdID8gWyQkWyQwLTJdLCAkJFskMF1dIDogJCRbJDAtMl07XG5icmVhaztcbmNhc2UgNjk6XG5cbiAgICAgIGlmICgkJFskMC0xXS5sZW5ndGgpXG4gICAgICAgIHRoaXMuJCA9IHsgdHlwZTogJ3VuaW9uJywgcGF0dGVybnM6IHVuaW9uQWxsKCQkWyQwLTFdLm1hcChkZWdyb3VwU2luZ2xlKSwgW2RlZ3JvdXBTaW5nbGUoJCRbJDBdKV0pIH07XG4gICAgICBlbHNlXG4gICAgICAgIHRoaXMuJCA9ICQkWyQwXTtcbiAgICBcbmJyZWFrO1xuY2FzZSA3MDpcbnRoaXMuJCA9IGV4dGVuZCgkJFskMF0sIHsgdHlwZTogJ29wdGlvbmFsJyB9KTtcbmJyZWFrO1xuY2FzZSA3MTpcbnRoaXMuJCA9IGV4dGVuZCgkJFskMF0sIHsgdHlwZTogJ21pbnVzJyB9KTtcbmJyZWFrO1xuY2FzZSA3MjpcbnRoaXMuJCA9IGV4dGVuZCgkJFskMF0sIHsgdHlwZTogJ2dyYXBoJywgbmFtZTogdG9WYXIoJCRbJDAtMV0pIH0pO1xuYnJlYWs7XG5jYXNlIDczOlxudGhpcy4kID0gZXh0ZW5kKCQkWyQwXSwgeyB0eXBlOiAnc2VydmljZScsIG5hbWU6IHRvVmFyKCQkWyQwLTFdKSwgc2lsZW50OiAhISQkWyQwLTJdIH0pO1xuYnJlYWs7XG5jYXNlIDc0OlxudGhpcy4kID0geyB0eXBlOiAnZmlsdGVyJywgZXhwcmVzc2lvbjogJCRbJDBdIH07XG5icmVhaztcbmNhc2UgNzU6XG50aGlzLiQgPSB7IHR5cGU6ICdiaW5kJywgdmFyaWFibGU6IHRvVmFyKCQkWyQwLTFdKSwgZXhwcmVzc2lvbjogJCRbJDAtM10gfTtcbmJyZWFrO1xuY2FzZSA4MDpcbnRoaXMuJCA9IHsgdHlwZTogJ2Z1bmN0aW9uQ2FsbCcsIGZ1bmN0aW9uOiAkJFskMC0xXSwgYXJnczogW10gfTtcbmJyZWFrO1xuY2FzZSA4MTpcbnRoaXMuJCA9IHsgdHlwZTogJ2Z1bmN0aW9uQ2FsbCcsIGZ1bmN0aW9uOiAkJFskMC01XSwgYXJnczogYXBwZW5kVG8oJCRbJDAtMl0sICQkWyQwLTFdKSwgZGlzdGluY3Q6ICEhJCRbJDAtM10gfTtcbmJyZWFrO1xuY2FzZSA4MjogY2FzZSA5OTogY2FzZSAxMTA6IGNhc2UgMTk2OiBjYXNlIDIwNDogY2FzZSAyMTY6IGNhc2UgMjE4OiBjYXNlIDIyODogY2FzZSAyMzI6IGNhc2UgMjUyOiBjYXNlIDI1NDogY2FzZSAyNTg6IGNhc2UgMjYyOiBjYXNlIDI4NTogY2FzZSAyOTE6IGNhc2UgMzAyOiBjYXNlIDMxMjogY2FzZSAzMTg6IGNhc2UgMzI0OiBjYXNlIDMyODogY2FzZSAzMzg6IGNhc2UgMzQwOiBjYXNlIDM0NDogY2FzZSAzNTA6IGNhc2UgMzU0OiBjYXNlIDM2MDogY2FzZSAzNjI6IGNhc2UgMzY2OiBjYXNlIDM2ODogY2FzZSAzNzc6IGNhc2UgMzg1OiBjYXNlIDM4NzogY2FzZSAzOTc6IGNhc2UgNDAxOiBjYXNlIDQwMzogY2FzZSA0MDU6XG50aGlzLiQgPSBbXTtcbmJyZWFrO1xuY2FzZSA4MzpcbnRoaXMuJCA9IGFwcGVuZFRvKCQkWyQwLTJdLCAkJFskMC0xXSk7XG5icmVhaztcbmNhc2UgODU6XG50aGlzLiQgPSB1bmlvbkFsbCgkJFskMC0yXSwgWyQkWyQwLTFdXSk7XG5icmVhaztcbmNhc2UgODY6IGNhc2UgOTY6XG50aGlzLiQgPSAkJFskMF0ubWFwKGZ1bmN0aW9uICh0KSB7IHJldHVybiBleHRlbmQodHJpcGxlKCQkWyQwLTFdKSwgdCk7IH0pO1xuYnJlYWs7XG5jYXNlIDg3OlxudGhpcy4kID0gYXBwZW5kQWxsVG8oJCRbJDBdLm1hcChmdW5jdGlvbiAodCkgeyByZXR1cm4gZXh0ZW5kKHRyaXBsZSgkJFskMC0xXS5lbnRpdHkpLCB0KTsgfSksICQkWyQwLTFdLnRyaXBsZXMpIC8qIHRoZSBzdWJqZWN0IGlzIGEgYmxhbmsgbm9kZSwgcG9zc2libHkgd2l0aCBtb3JlIHRyaXBsZXMgKi87XG5icmVhaztcbmNhc2UgODk6XG50aGlzLiQgPSB1bmlvbkFsbChbJCRbJDAtMV1dLCAkJFskMF0pO1xuYnJlYWs7XG5jYXNlIDkwOlxudGhpcy4kID0gdW5pb25BbGwoJCRbJDBdKTtcbmJyZWFrO1xuY2FzZSA5MTpcbnRoaXMuJCA9IG9iamVjdExpc3RUb1RyaXBsZXMoJCRbJDAtMV0sICQkWyQwXSk7XG5icmVhaztcbmNhc2UgOTQ6IGNhc2UgMTA2OiBjYXNlIDExMzpcbnRoaXMuJCA9IFJERl9UWVBFO1xuYnJlYWs7XG5jYXNlIDk1OlxudGhpcy4kID0gYXBwZW5kVG8oJCRbJDAtMV0sICQkWyQwXSk7XG5icmVhaztcbmNhc2UgOTc6XG50aGlzLiQgPSAhJCRbJDBdID8gJCRbJDAtMV0udHJpcGxlcyA6IGFwcGVuZEFsbFRvKCQkWyQwXS5tYXAoZnVuY3Rpb24gKHQpIHsgcmV0dXJuIGV4dGVuZCh0cmlwbGUoJCRbJDAtMV0uZW50aXR5KSwgdCk7IH0pLCAkJFskMC0xXS50cmlwbGVzKSAvKiB0aGUgc3ViamVjdCBpcyBhIGJsYW5rIG5vZGUsIHBvc3NpYmx5IHdpdGggbW9yZSB0cmlwbGVzICovO1xuYnJlYWs7XG5jYXNlIDk4OlxudGhpcy4kID0gb2JqZWN0TGlzdFRvVHJpcGxlcyh0b1ZhcigkJFskMC0zXSksIGFwcGVuZFRvKCQkWyQwLTJdLCAkJFskMC0xXSksICQkWyQwXSk7XG5icmVhaztcbmNhc2UgMTAwOlxudGhpcy4kID0gb2JqZWN0TGlzdFRvVHJpcGxlcyh0b1ZhcigkJFskMC0xXSksICQkWyQwXSk7XG5icmVhaztcbmNhc2UgMTAxOlxudGhpcy4kID0gJCRbJDAtMV0ubGVuZ3RoID8gcGF0aCgnfCcsYXBwZW5kVG8oJCRbJDAtMV0sICQkWyQwXSkpIDogJCRbJDBdO1xuYnJlYWs7XG5jYXNlIDEwMjpcbnRoaXMuJCA9ICQkWyQwLTFdLmxlbmd0aCA/IHBhdGgoJy8nLCBhcHBlbmRUbygkJFskMC0xXSwgJCRbJDBdKSkgOiAkJFskMF07XG5icmVhaztcbmNhc2UgMTAzOlxudGhpcy4kID0gJCRbJDBdID8gcGF0aCgkJFskMF0sIFskJFskMC0xXV0pIDogJCRbJDAtMV07XG5icmVhaztcbmNhc2UgMTA0OlxudGhpcy4kID0gJCRbJDAtMV0gPyBwYXRoKCQkWyQwLTFdLCBbJCRbJDBdXSkgOiAkJFskMF07O1xuYnJlYWs7XG5jYXNlIDEwNzogY2FzZSAxMTQ6XG50aGlzLiQgPSBwYXRoKCQkWyQwLTFdLCBbJCRbJDBdXSk7XG5icmVhaztcbmNhc2UgMTExOlxudGhpcy4kID0gcGF0aCgnfCcsIGFwcGVuZFRvKCQkWyQwLTJdLCAkJFskMC0xXSkpO1xuYnJlYWs7XG5jYXNlIDExNTpcbnRoaXMuJCA9IHBhdGgoJCRbJDAtMV0sIFtSREZfVFlQRV0pO1xuYnJlYWs7XG5jYXNlIDExNjogY2FzZSAxMTg6XG50aGlzLiQgPSBjcmVhdGVMaXN0KCQkWyQwLTFdKTtcbmJyZWFrO1xuY2FzZSAxMTc6IGNhc2UgMTE5OlxudGhpcy4kID0gY3JlYXRlQW5vbnltb3VzT2JqZWN0KCQkWyQwLTFdKTtcbmJyZWFrO1xuY2FzZSAxMjA6XG50aGlzLiQgPSB7IGVudGl0eTogJCRbJDBdLCB0cmlwbGVzOiBbXSB9IC8qIGZvciBjb25zaXN0ZW5jeSB3aXRoIFRyaXBsZXNOb2RlICovO1xuYnJlYWs7XG5jYXNlIDEyMjpcbnRoaXMuJCA9IHsgZW50aXR5OiAkJFskMF0sIHRyaXBsZXM6IFtdIH0gLyogZm9yIGNvbnNpc3RlbmN5IHdpdGggVHJpcGxlc05vZGVQYXRoICovO1xuYnJlYWs7XG5jYXNlIDEyODpcbnRoaXMuJCA9IGJsYW5rKCk7XG5icmVhaztcbmNhc2UgMTI5OlxudGhpcy4kID0gUkRGX05JTDtcbmJyZWFrO1xuY2FzZSAxMzA6IGNhc2UgMTMyOiBjYXNlIDEzNzogY2FzZSAxNDE6XG50aGlzLiQgPSBjcmVhdGVPcGVyYXRpb25UcmVlKCQkWyQwLTFdLCAkJFskMF0pO1xuYnJlYWs7XG5jYXNlIDEzMTpcbnRoaXMuJCA9IFsnfHwnLCAkJFskMF1dO1xuYnJlYWs7XG5jYXNlIDEzMzpcbnRoaXMuJCA9IFsnJiYnLCAkJFskMF1dO1xuYnJlYWs7XG5jYXNlIDEzNTpcbnRoaXMuJCA9IG9wZXJhdGlvbigkJFskMC0xXSwgWyQkWyQwLTJdLCAkJFskMF1dKTtcbmJyZWFrO1xuY2FzZSAxMzY6XG50aGlzLiQgPSBvcGVyYXRpb24oJCRbJDAtMl0gPyAnbm90aW4nIDogJ2luJywgWyQkWyQwLTNdLCAkJFskMF1dKTtcbmJyZWFrO1xuY2FzZSAxMzg6IGNhc2UgMTQyOlxudGhpcy4kID0gWyQkWyQwLTFdLCAkJFskMF1dO1xuYnJlYWs7XG5jYXNlIDEzOTpcbnRoaXMuJCA9IFsnKycsIGNyZWF0ZU9wZXJhdGlvblRyZWUoJCRbJDAtMV0sICQkWyQwXSldO1xuYnJlYWs7XG5jYXNlIDE0MDpcbnRoaXMuJCA9IFsnLScsIGNyZWF0ZU9wZXJhdGlvblRyZWUoJCRbJDAtMV0ucmVwbGFjZSgnLScsICcnKSwgJCRbJDBdKV07XG5icmVhaztcbmNhc2UgMTQ0OlxudGhpcy4kID0gb3BlcmF0aW9uKCQkWyQwLTFdLCBbJCRbJDBdXSk7XG5icmVhaztcbmNhc2UgMTQ1OlxudGhpcy4kID0gb3BlcmF0aW9uKCdVTUlOVVMnLCBbJCRbJDBdXSk7XG5icmVhaztcbmNhc2UgMTU0OlxudGhpcy4kID0gb3BlcmF0aW9uKGxvd2VyY2FzZSgkJFskMC0xXSkpO1xuYnJlYWs7XG5jYXNlIDE1NTpcbnRoaXMuJCA9IG9wZXJhdGlvbihsb3dlcmNhc2UoJCRbJDAtM10pLCBbJCRbJDAtMV1dKTtcbmJyZWFrO1xuY2FzZSAxNTY6XG50aGlzLiQgPSBvcGVyYXRpb24obG93ZXJjYXNlKCQkWyQwLTVdKSwgWyQkWyQwLTNdLCAkJFskMC0xXV0pO1xuYnJlYWs7XG5jYXNlIDE1NzpcbnRoaXMuJCA9IG9wZXJhdGlvbihsb3dlcmNhc2UoJCRbJDAtN10pLCBbJCRbJDAtNV0sICQkWyQwLTNdLCAkJFskMC0xXV0pO1xuYnJlYWs7XG5jYXNlIDE1ODpcbnRoaXMuJCA9IG9wZXJhdGlvbihsb3dlcmNhc2UoJCRbJDAtMV0pLCAkJFskMF0pO1xuYnJlYWs7XG5jYXNlIDE1OTpcbnRoaXMuJCA9IG9wZXJhdGlvbignYm91bmQnLCBbdG9WYXIoJCRbJDAtMV0pXSk7XG5icmVhaztcbmNhc2UgMTYwOlxudGhpcy4kID0gb3BlcmF0aW9uKCQkWyQwLTFdLCBbXSk7XG5icmVhaztcbmNhc2UgMTYxOlxudGhpcy4kID0gb3BlcmF0aW9uKCQkWyQwLTNdLCBbJCRbJDAtMV1dKTtcbmJyZWFrO1xuY2FzZSAxNjI6XG50aGlzLiQgPSBvcGVyYXRpb24oJCRbJDAtMl0gPyAnbm90ZXhpc3RzJyA6J2V4aXN0cycsIFtkZWdyb3VwU2luZ2xlKCQkWyQwXSldKTtcbmJyZWFrO1xuY2FzZSAxNjM6IGNhc2UgMTY0OlxudGhpcy4kID0gZXhwcmVzc2lvbigkJFskMC0xXSwgeyB0eXBlOiAnYWdncmVnYXRlJywgYWdncmVnYXRpb246IGxvd2VyY2FzZSgkJFskMC00XSksIGRpc3RpbmN0OiAhISQkWyQwLTJdIH0pO1xuYnJlYWs7XG5jYXNlIDE2NTpcbnRoaXMuJCA9IGV4cHJlc3Npb24oJCRbJDAtMl0sIHsgdHlwZTogJ2FnZ3JlZ2F0ZScsIGFnZ3JlZ2F0aW9uOiBsb3dlcmNhc2UoJCRbJDAtNV0pLCBkaXN0aW5jdDogISEkJFskMC0zXSwgc2VwYXJhdG9yOiAkJFskMC0xXSB8fCAnICcgfSk7XG5icmVhaztcbmNhc2UgMTY2OlxudGhpcy4kID0gJCRbJDBdLnN1YnN0cigxLCAkJFskMF0ubGVuZ3RoIC0gMik7XG5icmVhaztcbmNhc2UgMTY4OlxudGhpcy4kID0gJCRbJDAtMV0gKyBsb3dlcmNhc2UoJCRbJDBdKTtcbmJyZWFrO1xuY2FzZSAxNjk6XG50aGlzLiQgPSAkJFskMC0yXSArICdeXicgKyAkJFskMF07XG5icmVhaztcbmNhc2UgMTcwOiBjYXNlIDE4NDpcbnRoaXMuJCA9IGNyZWF0ZUxpdGVyYWwoJCRbJDBdLCBYU0RfSU5URUdFUik7XG5icmVhaztcbmNhc2UgMTcxOiBjYXNlIDE4NTpcbnRoaXMuJCA9IGNyZWF0ZUxpdGVyYWwoJCRbJDBdLCBYU0RfREVDSU1BTCk7XG5icmVhaztcbmNhc2UgMTcyOiBjYXNlIDE4NjpcbnRoaXMuJCA9IGNyZWF0ZUxpdGVyYWwobG93ZXJjYXNlKCQkWyQwXSksIFhTRF9ET1VCTEUpO1xuYnJlYWs7XG5jYXNlIDE3NTpcbnRoaXMuJCA9IFhTRF9UUlVFO1xuYnJlYWs7XG5jYXNlIDE3NjpcbnRoaXMuJCA9IFhTRF9GQUxTRTtcbmJyZWFrO1xuY2FzZSAxNzc6IGNhc2UgMTc4OlxudGhpcy4kID0gdW5lc2NhcGVTdHJpbmcoJCRbJDBdLCAxKTtcbmJyZWFrO1xuY2FzZSAxNzk6IGNhc2UgMTgwOlxudGhpcy4kID0gdW5lc2NhcGVTdHJpbmcoJCRbJDBdLCAzKTtcbmJyZWFrO1xuY2FzZSAxODE6XG50aGlzLiQgPSBjcmVhdGVMaXRlcmFsKCQkWyQwXS5zdWJzdHIoMSksIFhTRF9JTlRFR0VSKTtcbmJyZWFrO1xuY2FzZSAxODI6XG50aGlzLiQgPSBjcmVhdGVMaXRlcmFsKCQkWyQwXS5zdWJzdHIoMSksIFhTRF9ERUNJTUFMKTtcbmJyZWFrO1xuY2FzZSAxODM6XG50aGlzLiQgPSBjcmVhdGVMaXRlcmFsKCQkWyQwXS5zdWJzdHIoMSkudG9Mb3dlckNhc2UoKSwgWFNEX0RPVUJMRSk7XG5icmVhaztcbmNhc2UgMTg3OlxudGhpcy4kID0gcmVzb2x2ZUlSSSgkJFskMF0pO1xuYnJlYWs7XG5jYXNlIDE4ODpcblxuICAgICAgdmFyIG5hbWVQb3MgPSAkJFskMF0uaW5kZXhPZignOicpLFxuICAgICAgICAgIHByZWZpeCA9ICQkWyQwXS5zdWJzdHIoMCwgbmFtZVBvcyksXG4gICAgICAgICAgZXhwYW5zaW9uID0gUGFyc2VyLnByZWZpeGVzW3ByZWZpeF07XG4gICAgICBpZiAoIWV4cGFuc2lvbikgdGhyb3cgbmV3IEVycm9yKCdVbmtub3duIHByZWZpeDogJyArIHByZWZpeCk7XG4gICAgICB0aGlzLiQgPSByZXNvbHZlSVJJKGV4cGFuc2lvbiArICQkWyQwXS5zdWJzdHIobmFtZVBvcyArIDEpKTtcbiAgICBcbmJyZWFrO1xuY2FzZSAxODk6XG5cbiAgICAgICQkWyQwXSA9ICQkWyQwXS5zdWJzdHIoMCwgJCRbJDBdLmxlbmd0aCAtIDEpO1xuICAgICAgaWYgKCEoJCRbJDBdIGluIFBhcnNlci5wcmVmaXhlcykpIHRocm93IG5ldyBFcnJvcignVW5rbm93biBwcmVmaXg6ICcgKyAkJFskMF0pO1xuICAgICAgdGhpcy4kID0gcmVzb2x2ZUlSSShQYXJzZXIucHJlZml4ZXNbJCRbJDBdXSk7XG4gICAgXG5icmVhaztcbmNhc2UgMTk3OiBjYXNlIDIwNTogY2FzZSAyMTM6IGNhc2UgMjE3OiBjYXNlIDIxOTogY2FzZSAyMjU6IGNhc2UgMjI5OiBjYXNlIDIzMzogY2FzZSAyNDc6IGNhc2UgMjQ5OiBjYXNlIDI1MTogY2FzZSAyNTM6IGNhc2UgMjU1OiBjYXNlIDI1NzogY2FzZSAyNTk6IGNhc2UgMjYxOiBjYXNlIDI4NjogY2FzZSAyOTI6IGNhc2UgMzAzOiBjYXNlIDMxOTogY2FzZSAzNTE6IGNhc2UgMzYzOiBjYXNlIDM4MjogY2FzZSAzODQ6IGNhc2UgMzg2OiBjYXNlIDM4ODogY2FzZSAzOTg6IGNhc2UgNDAyOiBjYXNlIDQwNDogY2FzZSA0MDY6XG4kJFskMC0xXS5wdXNoKCQkWyQwXSk7XG5icmVhaztcbmNhc2UgMjEyOiBjYXNlIDIyNDogY2FzZSAyNDY6IGNhc2UgMjQ4OiBjYXNlIDI1MDogY2FzZSAyNTY6IGNhc2UgMjYwOiBjYXNlIDM4MTogY2FzZSAzODM6XG50aGlzLiQgPSBbJCRbJDBdXTtcbmJyZWFrO1xuY2FzZSAyNjM6XG4kJFskMC0zXS5wdXNoKCQkWyQwLTJdKTtcbmJyZWFrO1xuY2FzZSAzMTM6IGNhc2UgMzI1OiBjYXNlIDMyOTogY2FzZSAzMzk6IGNhc2UgMzQxOiBjYXNlIDM0NTogY2FzZSAzNTU6IGNhc2UgMzYxOiBjYXNlIDM2NzogY2FzZSAzNjk6IGNhc2UgMzc4OlxuJCRbJDAtMl0ucHVzaCgkJFskMC0xXSk7XG5icmVhaztcbn1cbn0sXG50YWJsZTogW28oJFYwLCRWMSx7MzoxLDQ6Miw3OjN9KSx7MTpbM119LG8oJFYyLFsyLDI2Ml0sezU6NCw4OjUsMjg3OjYsOTo3LDk1OjgsMTc6OSwzMzoxMCw0MjoxMSw0NzoxMiw5NjoxMywxODoxNCw2OlsyLDE5MF0sMjQ6JFYzLDM0OlsxLDE1XSw0MzpbMSwxNl0sNDg6WzEsMTddfSksbyhbNiwyNCwzNCw0Myw0OCw5OSwxMDksMTEyLDExNCwxMTUsMTI0LDEyNSwxMzAsMjk4LDI5OSwzMDAsMzAxLDMwMl0sWzIsMl0sezI4ODoxOSwxMToyMCwxNDoyMSwxMjpbMSwyMl0sMTU6WzEsMjNdfSksezY6WzEsMjRdfSx7NjpbMiwxOTJdfSx7NjpbMiwxOTNdfSx7NjpbMiwyMDJdLDEwOjI1LDgyOjI2LDgzOiRWNH0sezY6WzIsMTkxXX0sbygkVjUsWzIsMTk4XSksbygkVjUsWzIsMTk5XSksbygkVjUsWzIsMjAwXSksbygkVjUsWzIsMjAxXSksezk3OjI4LDk5OlsxLDI5XSwxMDI6MzAsMTA1OjMxLDEwOTpbMSwzMl0sMTEyOlsxLDMzXSwxMTQ6WzEsMzRdLDExNTpbMSwzNV0sMTE2OjM2LDEyMDozNywxMjQ6WzIsMjg3XSwxMjU6WzIsMjgxXSwxMjk6NDMsMTMwOlsxLDQ0XSwyOTg6WzEsMzhdLDI5OTpbMSwzOV0sMzAwOlsxLDQwXSwzMDE6WzEsNDFdLDMwMjpbMSw0Ml19LG8oJFY2LFsyLDIwNF0sezE5OjQ1fSksbygkVjcsWzIsMjE4XSx7MzU6NDYsMzc6NDcsMzk6WzEsNDhdfSksezEzOiRWOCwxNjokVjksMjg6JFZhLDQ0OjQ5LDUzOjU0LDI4NjokVmIsMjkzOlsxLDUxXSwyOTQ6NTIsMjk1OjUwfSxvKCRWNixbMiwyMzJdLHs0OTo1OH0pLG8oJFZjLFsyLDIxMF0sezI1OjU5LDI4OTo2MCwyOTA6WzEsNjFdLDI5MTpbMSw2Ml19KSxvKCRWMCxbMiwxOTddKSxvKCRWMCxbMiwxOTRdKSxvKCRWMCxbMiwxOTVdKSx7MTM6WzEsNjNdfSx7MTY6WzEsNjRdfSx7MTpbMiwxXX0sezY6WzIsM119LHs2OlsyLDIwM119LHsyODpbMSw2Nl0sMjk6WzEsNjhdLDg0OjY1LDg2OlsxLDY3XX0sezY6WzIsMjY0XSw5ODo2OSwxODM6WzEsNzBdfSxvKCRWZCxbMiwyNjZdLHsxMDA6NzEsMjk3OlsxLDcyXX0pLG8oJFZlLFsyLDI3Ml0sezEwMzo3MywyOTc6WzEsNzRdfSksbygkVmYsWzIsMjc3XSx7MTA2Ojc1LDI5NzpbMSw3Nl19KSx7MTEwOjc3LDExMTpbMiwyNzldLDI5NzpbMSw3OF19LHszOTokVmcsMTEzOjc5fSx7Mzk6JFZnLDExMzo4MX0sezM5OiRWZywxMTM6ODJ9LHsxMTc6ODMsMTI1OiRWaH0sezEyMTo4NSwxMjQ6JFZpfSxvKCRWaixbMiwyNzBdKSxvKCRWaixbMiwyNzFdKSxvKCRWayxbMiwyNzRdKSxvKCRWayxbMiwyNzVdKSxvKCRWayxbMiwyNzZdKSx7MTI0OlsyLDI4OF0sMTI1OlsyLDI4Ml19LHsxMzokVjgsMTY6JFY5LDUzOjg3LDI4NjokVmJ9LHsyMDo4OCwzODokVmwsMzk6JFZtLDUwOjg5LDUxOiRWbiw1NDo5MH0sbygkVjYsWzIsMjE2XSx7MzY6OTN9KSx7Mzg6WzEsOTRdLDUwOjk1LDUxOiRWbn0sbygkVm8sWzIsMzQ0XSx7MTcxOjk2LDE3Mjo5NywxNzM6OTgsNDE6WzIsMzQyXX0pLG8oJFZwLFsyLDIyOF0sezQ1Ojk5fSksbygkVnAsWzIsMjI2XSx7NTM6NTQsMjk0OjEwMCwxMzokVjgsMTY6JFY5LDI4OiRWYSwyODY6JFZifSksbygkVnAsWzIsMjI3XSksbygkVnEsWzIsMjI0XSksbygkVnEsWzIsMjIyXSksbygkVnEsWzIsMjIzXSksbygkVnIsWzIsMTg3XSksbygkVnIsWzIsMTg4XSksbygkVnIsWzIsMTg5XSksezIwOjEwMSwzODokVmwsMzk6JFZtLDUwOjEwMiw1MTokVm4sNTQ6OTB9LHsyNjoxMDMsMjc6MTA2LDI4OiRWcywyOTokVnQsMjkyOjEwNCwyOTM6WzEsMTA1XX0sbygkVmMsWzIsMjExXSksbygkVmMsWzIsMjA4XSksbygkVmMsWzIsMjA5XSksbygkVjAsWzIsNF0pLHsxMzpbMSwxMDldfSxvKCRWdSxbMiwzNF0pLHszOTpbMSwxMTBdfSx7Mzk6WzEsMTExXX0sezI4OlsxLDExM10sODg6MTEyfSx7NjpbMiw0Ml19LG8oJFYwLCRWMSx7NzozLDQ6MTE0fSksezEzOiRWOCwxNjokVjksNTM6MTE1LDI4NjokVmJ9LG8oJFZkLFsyLDI2N10pLHsxMDQ6MTE2LDExMTpbMSwxMTddLDEzMzpbMSwxMTldLDEzNToxMTgsMjk2OlsxLDEyMF0sMzAzOlsxLDEyMV19LG8oJFZlLFsyLDI3M10pLG8oJFZkLCRWdix7MTA3OjEyMiwxMzQ6MTI0LDExMTokVncsMTMzOiRWeH0pLG8oJFZmLFsyLDI3OF0pLHsxMTE6WzEsMTI2XX0sezExMTpbMiwyODBdfSxvKCRWeSxbMiw0N10pLG8oJFZvLCRWeix7MTM2OjEyNywxNDM6MTI4LDE0NDoxMjksNDE6JFZBLDExMTokVkF9KSxvKCRWeSxbMiw0OF0pLG8oJFZ5LFsyLDQ5XSksbygkVkIsWzIsMjgzXSx7MTE4OjEzMCwxMjE6MTMxLDEyNDokVml9KSx7Mzk6JFZnLDExMzoxMzJ9LG8oJFZCLFsyLDI4OV0sezEyMjoxMzMsMTE3OjEzNCwxMjU6JFZofSksezM5OiRWZywxMTM6MTM1fSxvKFsxMjQsMTI1XSxbMiw1NV0pLG8oJFZDLCRWRCx7MjE6MTM2LDU2OjEzNyw2MDoxMzgsNjE6JFZFfSksbygkVjYsWzIsMjA1XSksezM5OiRWRiw1NToxNDB9LG8oJFZkLFsyLDIzNF0sezUyOjE0MiwyOTY6WzEsMTQzXX0pLHszOTpbMiwyMzddfSx7MjA6MTQ0LDM4OiRWbCwzOTokVm0sNTA6MTQ1LDUxOiRWbiw1NDo5MH0sezM5OlsxLDE0Nl19LG8oJFY3LFsyLDIxOV0pLHs0MTpbMSwxNDddfSx7NDE6WzIsMzQzXX0sezEzOiRWOCwxNjokVjksMjg6JFZHLDI5OiRWSCw1MzoxNTIsODA6JFZJLDg2OiRWSiw5MToxNTMsMTQ1OjE0OCwxNzU6MTQ5LDE3NzoxNTAsMjE1OiRWSywyMTg6JFZMLDIxOTokVk0sMjM2OjE2MywyMzg6MTY0LDI2OToxNTksMjcyOiRWTiwyNzM6JFZPLDI3NDokVlAsMjc1OiRWUSwyNzY6JFZSLDI3NzokVlMsMjc4OiRWVCwyNzk6JFZVLDI4MDokVlYsMjgxOiRWVywyODI6JFZYLDI4MzokVlksMjg0OiRWWiwyODU6JFZfLDI4NjokVmJ9LG8oJFYkLFsyLDIzMF0sezU0OjkwLDQ2OjE3Nyw1MDoxNzgsMjA6MTc5LDM4OiRWbCwzOTokVm0sNTE6JFZufSksbygkVnEsWzIsMjI1XSksbygkVkMsJFZELHs1NjoxMzcsNjA6MTM4LDIxOjE4MCw2MTokVkV9KSxvKCRWNixbMiwyMzNdKSxvKCRWNixbMiw4XSksbygkVjYsWzIsMjE0XSx7Mjc6MTgxLDI4OiRWcywyOTokVnR9KSxvKCRWNixbMiwyMTVdKSxvKCRWMDEsWzIsMjEyXSksbygkVjAxLFsyLDldKSxvKCRWMTEsJFYyMSx7MzA6MTgyLDIyMDoxODMsMjI0OjE4NCwyMjg6MTg1LDIzMjoxODYsMjQwOjE4NywyNDQ6MTg4LDIwODokVjMxLDI0NjokVjQxLDMxMDokVjUxfSksbygkVjAsWzIsNV0pLG8oJFY2MSxbMiwyNTJdLHs4NToxOTJ9KSxvKCRWNzEsWzIsMjU0XSx7ODc6MTkzfSksezI4OlsxLDE5NV0sMzI6WzEsMTk0XX0sbygkVjgxLFsyLDI1Nl0pLG8oJFYyLFsyLDI2M10sezY6WzIsMjY1XX0pLG8oJFZ5LFsyLDI2OF0sezEwMToxOTYsMTMxOjE5NywxMzI6WzEsMTk4XX0pLG8oJFZ5LFsyLDQ0XSksezEzOiRWOCwxNjokVjksNTM6MTk5LDI4NjokVmJ9LG8oJFZ5LFsyLDYwXSksbygkVnksWzIsMjk3XSksbygkVnksWzIsMjk4XSksbygkVnksWzIsMjk5XSksezEwODpbMSwyMDBdfSxvKCRWOTEsWzIsNTddKSx7MTM6JFY4LDE2OiRWOSw1MzoyMDEsMjg2OiRWYn0sbygkVmQsWzIsMjk2XSksezEzOiRWOCwxNjokVjksNTM6MjAyLDI4NjokVmJ9LG8oJFZhMSxbMiwzMDJdLHsxMzc6MjAzfSksbygkVmExLFsyLDMwMV0pLHsxMzokVjgsMTY6JFY5LDI4OiRWRywyOTokVkgsNTM6MTUyLDgwOiRWSSw4NjokVkosOTE6MTUzLDE0NToyMDQsMTc1OjE0OSwxNzc6MTUwLDIxNTokVkssMjE4OiRWTCwyMTk6JFZNLDIzNjoxNjMsMjM4OjE2NCwyNjk6MTU5LDI3MjokVk4sMjczOiRWTywyNzQ6JFZQLDI3NTokVlEsMjc2OiRWUiwyNzc6JFZTLDI3ODokVlQsMjc5OiRWVSwyODA6JFZWLDI4MTokVlcsMjgyOiRWWCwyODM6JFZZLDI4NDokVlosMjg1OiRWXywyODY6JFZifSxvKCRWQixbMiwyODVdLHsxMTk6MjA1fSksbygkVkIsWzIsMjg0XSksbyhbMzgsMTI0LDEyN10sWzIsNTNdKSxvKCRWQixbMiwyOTFdLHsxMjM6MjA2fSksbygkVkIsWzIsMjkwXSksbyhbMzgsMTI1LDEyN10sWzIsNTJdKSxvKCRWNSxbMiw2XSksbygkVmIxLFsyLDI0MF0sezU3OjIwNyw2NzoyMDgsNjg6WzEsMjA5XX0pLG8oJFZDLFsyLDIzOV0pLHs2MjpbMSwyMTBdfSxvKFs2LDQxLDYxLDY4LDcxLDc5LDgxLDgzXSxbMiwxNl0pLG8oJFZvLCRWYzEsezIyOjIxMSwxNDc6MjEyLDE4OjIxMywxNDg6MjE0LDE1NDoyMTUsMTU1OjIxNiwyNDokVjMsMzk6JFZkMSw0MTokVmQxLDgzOiRWZDEsMTExOiRWZDEsMTU5OiRWZDEsMTYwOiRWZDEsMTYyOiRWZDEsMTY1OiRWZDEsMTY2OiRWZDF9KSx7MTM6JFY4LDE2OiRWOSw1MzoyMTcsMjg2OiRWYn0sbygkVmQsWzIsMjM1XSksbygkVkMsJFZELHs1NjoxMzcsNjA6MTM4LDIxOjIxOCw2MTokVkV9KSxvKCRWNixbMiwyMTddKSxvKCRWbywkVnosezE0NDoxMjksNDA6MjE5LDE0MzoyMjAsNDE6WzIsMjIwXX0pLG8oJFY2LFsyLDg0XSksezQxOlsyLDM0Nl0sMTc0OjIyMSwzMDQ6WzEsMjIyXX0sezEzOiRWOCwxNjokVjksMjg6JFZlMSw1MzoyMjcsMTc2OjIyMywxODA6MjI0LDE4NToyMjUsMTg3OiRWZjEsMjg2OiRWYn0sbygkVmcxLFsyLDM0OF0sezE4MDoyMjQsMTg1OjIyNSw1MzoyMjcsMTc4OjIyOSwxNzk6MjMwLDE3NjoyMzEsMTM6JFY4LDE2OiRWOSwyODokVmUxLDE4NzokVmYxLDI4NjokVmJ9KSxvKCRWaDEsWzIsMTI0XSksbygkVmgxLFsyLDEyNV0pLG8oJFZoMSxbMiwxMjZdKSxvKCRWaDEsWzIsMTI3XSksbygkVmgxLFsyLDEyOF0pLG8oJFZoMSxbMiwxMjldKSx7MTM6JFY4LDE2OiRWOSwyODokVkcsMjk6JFZILDUzOjE1Miw4MDokVkksODY6JFZKLDkxOjE1MywxNzU6MjM0LDE3NzoyMzUsMTg5OjIzMywyMTQ6MjMyLDIxNTokVkssMjE4OiRWTCwyMTk6JFZNLDIzNjoxNjMsMjM4OjE2NCwyNjk6MTU5LDI3MjokVk4sMjczOiRWTywyNzQ6JFZQLDI3NTokVlEsMjc2OiRWUiwyNzc6JFZTLDI3ODokVlQsMjc5OiRWVSwyODA6JFZWLDI4MTokVlcsMjgyOiRWWCwyODM6JFZZLDI4NDokVlosMjg1OiRWXywyODY6JFZifSx7MTM6JFY4LDE2OiRWOSwyODokVmUxLDUzOjIyNywxNzY6MjM2LDE4MDoyMjQsMTg1OjIyNSwxODc6JFZmMSwyODY6JFZifSxvKCRWaTEsWzIsMTY3XSx7MjcwOlsxLDIzN10sMjcxOlsxLDIzOF19KSxvKCRWaTEsWzIsMTcwXSksbygkVmkxLFsyLDE3MV0pLG8oJFZpMSxbMiwxNzJdKSxvKCRWaTEsWzIsMTczXSksbygkVmkxLFsyLDE3NF0pLG8oJFZpMSxbMiwxNzVdKSxvKCRWaTEsWzIsMTc2XSksbygkVmoxLFsyLDE3N10pLG8oJFZqMSxbMiwxNzhdKSxvKCRWajEsWzIsMTc5XSksbygkVmoxLFsyLDE4MF0pLG8oJFZpMSxbMiwxODFdKSxvKCRWaTEsWzIsMTgyXSksbygkVmkxLFsyLDE4M10pLG8oJFZpMSxbMiwxODRdKSxvKCRWaTEsWzIsMTg1XSksbygkVmkxLFsyLDE4Nl0pLG8oJFZDLCRWRCx7NTY6MTM3LDYwOjEzOCwyMToyMzksNjE6JFZFfSksbygkVnAsWzIsMjI5XSksbygkViQsWzIsMjMxXSksbygkVjUsWzIsMTRdKSxvKCRWMDEsWzIsMjEzXSksezMxOlsxLDI0MF19LG8oJFZrMSxbMiwzODVdLHsyMjE6MjQxfSksbygkVmwxLFsyLDM4N10sezIyNToyNDJ9KSxvKCRWbDEsWzIsMTM0XSx7MjI5OjI0MywyMzA6MjQ0LDIzMTpbMiwzOTVdLDI2ODpbMSwyNDVdLDMxMTpbMSwyNDZdLDMxMjpbMSwyNDddLDMxMzpbMSwyNDhdLDMxNDpbMSwyNDldLDMxNTpbMSwyNTBdLDMxNjpbMSwyNTFdfSksbygkVm0xLFsyLDM5N10sezIzMzoyNTJ9KSxvKCRWbjEsWzIsNDA1XSx7MjQxOjI1M30pLHsxMzokVjgsMTY6JFY5LDI4OiRWbzEsMjk6JFZwMSw1MzoyNTcsNjU6MjU2LDY2OjI1OCw3NToyNTUsODA6JFZJLDkxOjI1OSwyMzY6MTYzLDIzODoxNjQsMjQ1OjI1NCwyNDc6MjYyLDI0ODokVnExLDI0OTokVnIxLDI1MDokVnMxLDI1MjokVnQxLDI1MzoyNjcsMjU0OiRWdTEsMjU1OiRWdjEsMjU2OjI3MCwyNTc6JFZ3MSwyNTg6JFZ4MSwyNjE6JFZ5MSwyNjM6JFZ6MSwyNjk6MTU5LDI3MjokVk4sMjczOiRWTywyNzQ6JFZQLDI3NTokVlEsMjc2OiRWUiwyNzc6JFZTLDI3ODokVlQsMjc5OiRWVSwyODA6JFZWLDI4MTokVlcsMjgyOiRWWCwyODM6JFZZLDI4NDokVlosMjg1OiRWXywyODY6JFZiLDMxNjokVkExLDMxNzokVkIxLDMxODokVkMxLDMxOTokVkQxLDMyMDokVkUxLDMyMTokVkYxfSx7MTM6JFY4LDE2OiRWOSwyODokVm8xLDI5OiRWcDEsNTM6MjU3LDY1OjI1Niw2NjoyNTgsNzU6MjU1LDgwOiRWSSw5MToyNTksMjM2OjE2MywyMzg6MTY0LDI0NToyODAsMjQ3OjI2MiwyNDg6JFZxMSwyNDk6JFZyMSwyNTA6JFZzMSwyNTI6JFZ0MSwyNTM6MjY3LDI1NDokVnUxLDI1NTokVnYxLDI1NjoyNzAsMjU3OiRWdzEsMjU4OiRWeDEsMjYxOiRWeTEsMjYzOiRWejEsMjY5OjE1OSwyNzI6JFZOLDI3MzokVk8sMjc0OiRWUCwyNzU6JFZRLDI3NjokVlIsMjc3OiRWUywyNzg6JFZULDI3OTokVlUsMjgwOiRWViwyODE6JFZXLDI4MjokVlgsMjgzOiRWWSwyODQ6JFZaLDI4NTokVl8sMjg2OiRWYiwzMTY6JFZBMSwzMTc6JFZCMSwzMTg6JFZDMSwzMTk6JFZEMSwzMjA6JFZFMSwzMjE6JFZGMX0sezEzOiRWOCwxNjokVjksMjg6JFZvMSwyOTokVnAxLDUzOjI1Nyw2NToyNTYsNjY6MjU4LDc1OjI1NSw4MDokVkksOTE6MjU5LDIzNjoxNjMsMjM4OjE2NCwyNDU6MjgxLDI0NzoyNjIsMjQ4OiRWcTEsMjQ5OiRWcjEsMjUwOiRWczEsMjUyOiRWdDEsMjUzOjI2NywyNTQ6JFZ1MSwyNTU6JFZ2MSwyNTY6MjcwLDI1NzokVncxLDI1ODokVngxLDI2MTokVnkxLDI2MzokVnoxLDI2OToxNTksMjcyOiRWTiwyNzM6JFZPLDI3NDokVlAsMjc1OiRWUSwyNzY6JFZSLDI3NzokVlMsMjc4OiRWVCwyNzk6JFZVLDI4MDokVlYsMjgxOiRWVywyODI6JFZYLDI4MzokVlksMjg0OiRWWiwyODU6JFZfLDI4NjokVmIsMzE2OiRWQTEsMzE3OiRWQjEsMzE4OiRWQzEsMzE5OiRWRDEsMzIwOiRWRTEsMzIxOiRWRjF9LG8oJFYxMSxbMiw0MTBdKSx7MTM6JFY4LDE2OiRWOSw0MTpbMSwyODJdLDUzOjI4NCw4MDokVkksOTA6MjgzLDkxOjI4NSw5MjokVkcxLDIzNjoxNjMsMjM4OjE2NCwyNjk6MTU5LDI3MjokVk4sMjczOiRWTywyNzQ6JFZQLDI3NTokVlEsMjc2OiRWUiwyNzc6JFZTLDI3ODokVlQsMjc5OiRWVSwyODA6JFZWLDI4MTokVlcsMjgyOiRWWCwyODM6JFZZLDI4NDokVlosMjg1OiRWXywyODY6JFZifSx7NDE6WzEsMjg3XSw4NjpbMSwyODhdfSx7Mzk6WzEsMjg5XX0sbygkVjgxLFsyLDI1N10pLG8oJFZ5LFsyLDQzXSksbygkVnksWzIsMjY5XSksezExMTpbMSwyOTBdfSxvKCRWeSxbMiw1OV0pLG8oJFZkLCRWdix7MTM0OjEyNCwxMDc6MjkxLDExMTokVncsMTMzOiRWeH0pLG8oJFY5MSxbMiw1OF0pLG8oJFZ5LFsyLDQ2XSksezQxOlsxLDI5Ml0sMTExOlsxLDI5NF0sMTM4OjI5M30sbygkVmExLFsyLDMxNF0sezE0NjoyOTUsMzA0OlsxLDI5Nl19KSx7Mzg6WzEsMjk3XSwxMjY6Mjk4LDEyNzokVkgxfSx7Mzg6WzEsMzAwXSwxMjY6MzAxLDEyNzokVkgxfSxvKCRWSTEsWzIsMjQyXSx7NTg6MzAyLDcwOjMwMyw3MTpbMSwzMDRdfSksbygkVmIxLFsyLDI0MV0pLHsxMzokVjgsMTY6JFY5LDI5OiRWcDEsNTM6MzEwLDY1OjMwOCw2NjozMDksNjk6MzA1LDc1OjMwNyw3NzozMDYsMjQ3OjI2MiwyNDg6JFZxMSwyNDk6JFZyMSwyNTA6JFZzMSwyNTI6JFZ0MSwyNTM6MjY3LDI1NDokVnUxLDI1NTokVnYxLDI1NjoyNzAsMjU3OiRWdzEsMjU4OiRWeDEsMjYxOiRWeTEsMjYzOiRWejEsMjg2OiRWYiwzMTY6JFZBMSwzMTc6JFZCMSwzMTg6JFZDMSwzMTk6JFZEMSwzMjA6JFZFMSwzMjE6JFZGMX0sezEzOiRWOCwxNjokVjksMjg6JFZKMSwyOTokVksxLDUzOjMxMCw2MzozMTEsNjQ6MzEyLDY1OjMxMyw2NjozMTQsMjQ3OjI2MiwyNDg6JFZxMSwyNDk6JFZyMSwyNTA6JFZzMSwyNTI6JFZ0MSwyNTM6MjY3LDI1NDokVnUxLDI1NTokVnYxLDI1NjoyNzAsMjU3OiRWdzEsMjU4OiRWeDEsMjYxOiRWeTEsMjYzOiRWejEsMjg2OiRWYiwzMTY6JFZBMSwzMTc6JFZCMSwzMTg6JFZDMSwzMTk6JFZEMSwzMjA6JFZFMSwzMjE6JFZGMX0sezQxOlsxLDMxN119LHs0MTpbMSwzMThdfSx7MjA6MzE5LDM4OiRWbCwzOTokVm0sNTQ6OTB9LG8oJFZMMSxbMiwzMThdLHsxNDk6MzIwfSksbygkVkwxLFsyLDMxN10pLHsxMzokVjgsMTY6JFY5LDI4OiRWRywyOTokVk0xLDUzOjE1Miw4MDokVkksODY6JFZKLDkxOjE1MywxNTY6MzIxLDE3NTozMjIsMTkxOjMyMywyMTU6JFZOMSwyMTg6JFZMLDIxOTokVk0sMjM2OjE2MywyMzg6MTY0LDI2OToxNTksMjcyOiRWTiwyNzM6JFZPLDI3NDokVlAsMjc1OiRWUSwyNzY6JFZSLDI3NzokVlMsMjc4OiRWVCwyNzk6JFZVLDI4MDokVlYsMjgxOiRWVywyODI6JFZYLDI4MzokVlksMjg0OiRWWiwyODU6JFZfLDI4NjokVmJ9LG8oJFZwLFsyLDE1XSksbygkVjUsWzIsMTFdKSx7NDE6WzEsMzI2XX0sezQxOlsyLDIyMV19LHs0MTpbMiw4NV19LG8oJFZvLFsyLDM0NV0sezQxOlsyLDM0N119KSxvKCRWZzEsWzIsODZdKSxvKCRWTzEsWzIsMzUwXSx7MTgxOjMyN30pLG8oJFZvLCRWUDEsezE4NjozMjgsMTg4OjMyOX0pLG8oJFZvLFsyLDkyXSksbygkVm8sWzIsOTNdKSxvKCRWbyxbMiw5NF0pLG8oJFZnMSxbMiw4N10pLG8oJFZnMSxbMiw4OF0pLG8oJFZnMSxbMiwzNDldKSx7MTM6JFY4LDE2OiRWOSwyODokVkcsMjk6JFZILDMyOlsxLDMzMF0sNTM6MTUyLDgwOiRWSSw4NjokVkosOTE6MTUzLDE3NToyMzQsMTc3OjIzNSwxODk6MzMxLDIxNTokVkssMjE4OiRWTCwyMTk6JFZNLDIzNjoxNjMsMjM4OjE2NCwyNjk6MTU5LDI3MjokVk4sMjczOiRWTywyNzQ6JFZQLDI3NTokVlEsMjc2OiRWUiwyNzc6JFZTLDI3ODokVlQsMjc5OiRWVSwyODA6JFZWLDI4MTokVlcsMjgyOiRWWCwyODM6JFZZLDI4NDokVlosMjg1OiRWXywyODY6JFZifSxvKCRWUTEsWzIsMzgxXSksbygkVlIxLFsyLDEyMF0pLG8oJFZSMSxbMiwxMjFdKSx7MjE2OlsxLDMzMl19LG8oJFZpMSxbMiwxNjhdKSx7MTM6JFY4LDE2OiRWOSw1MzozMzMsMjg2OiRWYn0sbygkVjUsWzIsMTNdKSx7Mjg6WzEsMzM0XX0sbyhbMzEsMzIsMTgzLDI1MV0sWzIsMTMwXSx7MjIyOjMzNSwyMjM6WzEsMzM2XX0pLG8oJFZrMSxbMiwxMzJdLHsyMjY6MzM3LDIyNzpbMSwzMzhdfSksbygkVjExLCRWMjEsezIzMjoxODYsMjQwOjE4NywyNDQ6MTg4LDIyODozMzksMjA4OiRWMzEsMjQ2OiRWNDEsMzEwOiRWNTF9KSx7MjMxOlsxLDM0MF19LG8oJFZTMSxbMiwzODldKSxvKCRWUzEsWzIsMzkwXSksbygkVlMxLFsyLDM5MV0pLG8oJFZTMSxbMiwzOTJdKSxvKCRWUzEsWzIsMzkzXSksbygkVlMxLFsyLDM5NF0pLHsyMzE6WzIsMzk2XX0sbyhbMzEsMzIsMTgzLDIyMywyMjcsMjMxLDI1MSwyNjgsMzExLDMxMiwzMTMsMzE0LDMxNSwzMTZdLFsyLDEzN10sezIzNDozNDEsMjM1OjM0MiwyMzY6MzQzLDIzODozNDQsMjQ2OlsxLDM0Nl0sMjgwOiRWViwyODE6JFZXLDI4MjokVlgsMjgzOiRWWSwyODQ6JFZaLDI4NTokVl8sMzEwOlsxLDM0NV19KSxvKCRWbTEsWzIsMTQxXSx7MjQyOjM0NywyNDM6MzQ4LDI5MzokVlQxLDMwNzokVlUxfSksbygkVm4xLFsyLDE0M10pLG8oJFZuMSxbMiwxNDZdKSxvKCRWbjEsWzIsMTQ3XSksbygkVm4xLFsyLDE0OF0sezI5OiRWVjEsODY6JFZXMX0pLG8oJFZuMSxbMiwxNDldKSxvKCRWbjEsWzIsMTUwXSksbygkVm4xLFsyLDE1MV0pLG8oJFYxMSwkVjIxLHsyMjA6MTgzLDIyNDoxODQsMjI4OjE4NSwyMzI6MTg2LDI0MDoxODcsMjQ0OjE4OCwzMDozNTMsMjA4OiRWMzEsMjQ2OiRWNDEsMzEwOiRWNTF9KSxvKCRWWDEsWzIsMTUzXSksezg2OlsxLDM1NF19LHsyOTpbMSwzNTVdfSx7Mjk6WzEsMzU2XX0sezI5OlsxLDM1N119LHsyOTokVlkxLDg2OiRWWjEsMTY5OjM1OH0sezI5OlsxLDM2MV19LHsyOTpbMSwzNjNdLDg2OlsxLDM2Ml19LHsyNTc6WzEsMzY0XX0sezI5OlsxLDM2NV19LHsyOTpbMSwzNjZdfSx7Mjk6WzEsMzY3XX0sbygkVl8xLFsyLDQxMV0pLG8oJFZfMSxbMiw0MTJdKSxvKCRWXzEsWzIsNDEzXSksbygkVl8xLFsyLDQxNF0pLG8oJFZfMSxbMiw0MTVdKSx7MjU3OlsyLDQxN119LG8oJFZuMSxbMiwxNDRdKSxvKCRWbjEsWzIsMTQ1XSksbygkVnUsWzIsMzVdKSxvKCRWNjEsWzIsMjUzXSksbygkViQxLFsyLDM4XSksbygkViQxLFsyLDM5XSksbygkViQxLFsyLDQwXSksbygkVnUsWzIsMzZdKSxvKCRWNzEsWzIsMjU1XSksbygkVjAyLFsyLDI1OF0sezg5OjM2OH0pLHsxMzokVjgsMTY6JFY5LDUzOjM2OSwyODY6JFZifSxvKCRWeSxbMiw0NV0pLG8oWzYsMzgsMTI0LDEyNSwxMjcsMTgzXSxbMiw2MV0pLG8oJFZhMSxbMiwzMDNdKSx7MTM6JFY4LDE2OiRWOSwyODpbMSwzNzFdLDUzOjM3MiwxMzk6MzcwLDI4NjokVmJ9LG8oJFZhMSxbMiw2M10pLG8oJFZvLFsyLDMxM10sezQxOiRWMTIsMTExOiRWMTJ9KSx7Mzk6JFZGLDU1OjM3M30sbygkVkIsWzIsMjg2XSksbygkVmQsWzIsMjkzXSx7MTI4OjM3NCwyOTY6WzEsMzc1XX0pLHszOTokVkYsNTU6Mzc2fSxvKCRWQixbMiwyOTJdKSxvKCRWMjIsWzIsMjQ0XSx7NTk6Mzc3LDc4OjM3OCw3OTpbMSwzNzldLDgxOlsxLDM4MF19KSxvKCRWSTEsWzIsMjQzXSksezYyOlsxLDM4MV19LG8oJFZiMSxbMiwyNF0sezI0NzoyNjIsMjUzOjI2NywyNTY6MjcwLDc1OjMwNyw2NTozMDgsNjY6MzA5LDUzOjMxMCw3NzozODIsMTM6JFY4LDE2OiRWOSwyOTokVnAxLDI0ODokVnExLDI0OTokVnIxLDI1MDokVnMxLDI1MjokVnQxLDI1NDokVnUxLDI1NTokVnYxLDI1NzokVncxLDI1ODokVngxLDI2MTokVnkxLDI2MzokVnoxLDI4NjokVmIsMzE2OiRWQTEsMzE3OiRWQjEsMzE4OiRWQzEsMzE5OiRWRDEsMzIwOiRWRTEsMzIxOiRWRjF9KSxvKCRWMzIsWzIsMjQ4XSksbygkVjQyLFsyLDc3XSksbygkVjQyLFsyLDc4XSksbygkVjQyLFsyLDc5XSksezI5OiRWVjEsODY6JFZXMX0sbygkVkMsWzIsMThdLHsyNDc6MjYyLDI1MzoyNjcsMjU2OjI3MCw1MzozMTAsNjU6MzEzLDY2OjMxNCw2NDozODMsMTM6JFY4LDE2OiRWOSwyODokVkoxLDI5OiRWSzEsMjQ4OiRWcTEsMjQ5OiRWcjEsMjUwOiRWczEsMjUyOiRWdDEsMjU0OiRWdTEsMjU1OiRWdjEsMjU3OiRWdzEsMjU4OiRWeDEsMjYxOiRWeTEsMjYzOiRWejEsMjg2OiRWYiwzMTY6JFZBMSwzMTc6JFZCMSwzMTg6JFZDMSwzMTk6JFZEMSwzMjA6JFZFMSwzMjE6JFZGMX0pLG8oJFY1MixbMiwyNDZdKSxvKCRWNTIsWzIsMTldKSxvKCRWNTIsWzIsMjBdKSxvKCRWMTEsJFYyMSx7MjIwOjE4MywyMjQ6MTg0LDIyODoxODUsMjMyOjE4NiwyNDA6MTg3LDI0NDoxODgsMzA6Mzg0LDIwODokVjMxLDI0NjokVjQxLDMxMDokVjUxfSksbygkVjUyLFsyLDIzXSksbygkVjYyLFsyLDY0XSksbygkVjYyLFsyLDY1XSksbygkVkMsJFZELHs1NjoxMzcsNjA6MTM4LDIxOjM4NSw2MTokVkV9KSx7Mzk6WzIsMzI4XSw0MTpbMiw2Nl0sODI6Mzk1LDgzOiRWNCwxMTE6WzEsMzkxXSwxNTA6Mzg2LDE1MTozODcsMTU4OjM4OCwxNTk6WzEsMzg5XSwxNjA6WzEsMzkwXSwxNjI6WzEsMzkyXSwxNjU6WzEsMzkzXSwxNjY6WzEsMzk0XX0sbygkVkwxLFsyLDMyNl0sezE1NzozOTYsMzA0OlsxLDM5N119KSxvKCRWNzIsJFY4Mix7MTkwOjM5OCwxOTM6Mzk5LDE5OTo0MDAsMjAwOjQwMiwyODokVjkyfSksbygkVmEyLFsyLDM1Nl0sezE5MzozOTksMTk5OjQwMCwyMDA6NDAyLDE5Mjo0MDMsMTkwOjQwNCwxMzokVjgyLDE2OiRWODIsMjk6JFY4MiwxODc6JFY4MiwyMDg6JFY4MiwyMTM6JFY4MiwyODY6JFY4MiwyODokVjkyfSksezEzOiRWOCwxNjokVjksMjg6JFZHLDI5OiRWTTEsNTM6MTUyLDgwOiRWSSw4NjokVkosOTE6MTUzLDE3NTo0MDcsMTkxOjQwOCwxOTU6NDA2LDIxNTokVk4xLDIxNzo0MDUsMjE4OiRWTCwyMTk6JFZNLDIzNjoxNjMsMjM4OjE2NCwyNjk6MTU5LDI3MjokVk4sMjczOiRWTywyNzQ6JFZQLDI3NTokVlEsMjc2OiRWUiwyNzc6JFZTLDI3ODokVlQsMjc5OiRWVSwyODA6JFZWLDI4MTokVlcsMjgyOiRWWCwyODM6JFZZLDI4NDokVlosMjg1OiRWXywyODY6JFZifSxvKCRWNzIsJFY4Mix7MTkzOjM5OSwxOTk6NDAwLDIwMDo0MDIsMTkwOjQwOSwyODokVjkyfSksbygkVkMsJFZELHs1NjoxMzcsNjA6MTM4LDIxOjQxMCw2MTokVkV9KSxvKFs0MSwxMTEsMjE2LDMwNF0sWzIsODldLHsxODI6NDExLDE4MzpbMSw0MTJdfSksbygkVk8xLFsyLDkxXSksezEzOiRWOCwxNjokVjksMjg6JFZHLDI5OiRWSCw1MzoxNTIsODA6JFZJLDg2OiRWSiw5MToxNTMsMTc1OjIzNCwxNzc6MjM1LDE4OTo0MTMsMjE1OiRWSywyMTg6JFZMLDIxOTokVk0sMjM2OjE2MywyMzg6MTY0LDI2OToxNTksMjcyOiRWTiwyNzM6JFZPLDI3NDokVlAsMjc1OiRWUSwyNzY6JFZSLDI3NzokVlMsMjc4OiRWVCwyNzk6JFZVLDI4MDokVlYsMjgxOiRWVywyODI6JFZYLDI4MzokVlksMjg0OiRWWiwyODU6JFZfLDI4NjokVmJ9LG8oJFZiMixbMiwxMTZdKSxvKCRWUTEsWzIsMzgyXSksbygkVmIyLFsyLDExN10pLG8oJFZpMSxbMiwxNjldKSx7MzI6WzEsNDE0XX0sbygkVmsxLFsyLDM4Nl0pLG8oJFYxMSwkVjIxLHsyMjQ6MTg0LDIyODoxODUsMjMyOjE4NiwyNDA6MTg3LDI0NDoxODgsMjIwOjQxNSwyMDg6JFYzMSwyNDY6JFY0MSwzMTA6JFY1MX0pLG8oJFZsMSxbMiwzODhdKSxvKCRWMTEsJFYyMSx7MjI4OjE4NSwyMzI6MTg2LDI0MDoxODcsMjQ0OjE4OCwyMjQ6NDE2LDIwODokVjMxLDI0NjokVjQxLDMxMDokVjUxfSksbygkVmwxLFsyLDEzNV0pLHsyOTokVlkxLDg2OiRWWjEsMTY5OjQxN30sbygkVm0xLFsyLDM5OF0pLG8oJFYxMSwkVjIxLHsyNDA6MTg3LDI0NDoxODgsMjMyOjQxOCwyMDg6JFYzMSwyNDY6JFY0MSwzMTA6JFY1MX0pLG8oJFZuMSxbMiw0MDFdLHsyMzc6NDE5fSksbygkVm4xLFsyLDQwM10sezIzOTo0MjB9KSxvKCRWUzEsWzIsMzk5XSksbygkVlMxLFsyLDQwMF0pLG8oJFZuMSxbMiw0MDZdKSxvKCRWMTEsJFYyMSx7MjQ0OjE4OCwyNDA6NDIxLDIwODokVjMxLDI0NjokVjQxLDMxMDokVjUxfSksbygkVlMxLFsyLDQwN10pLG8oJFZTMSxbMiw0MDhdKSxvKCRWWDEsWzIsODBdKSxvKCRWUzEsWzIsMzM2XSx7MTY3OjQyMiwyOTA6WzEsNDIzXX0pLHszMjpbMSw0MjRdfSxvKCRWWDEsWzIsMTU0XSksbygkVjExLCRWMjEsezIyMDoxODMsMjI0OjE4NCwyMjg6MTg1LDIzMjoxODYsMjQwOjE4NywyNDQ6MTg4LDMwOjQyNSwyMDg6JFYzMSwyNDY6JFY0MSwzMTA6JFY1MX0pLG8oJFYxMSwkVjIxLHsyMjA6MTgzLDIyNDoxODQsMjI4OjE4NSwyMzI6MTg2LDI0MDoxODcsMjQ0OjE4OCwzMDo0MjYsMjA4OiRWMzEsMjQ2OiRWNDEsMzEwOiRWNTF9KSxvKCRWMTEsJFYyMSx7MjIwOjE4MywyMjQ6MTg0LDIyODoxODUsMjMyOjE4NiwyNDA6MTg3LDI0NDoxODgsMzA6NDI3LDIwODokVjMxLDI0NjokVjQxLDMxMDokVjUxfSksbygkVlgxLFsyLDE1OF0pLG8oJFZYMSxbMiw4Ml0pLG8oJFZTMSxbMiwzNDBdLHsxNzA6NDI4fSksezI4OlsxLDQyOV19LG8oJFZYMSxbMiwxNjBdKSxvKCRWMTEsJFYyMSx7MjIwOjE4MywyMjQ6MTg0LDIyODoxODUsMjMyOjE4NiwyNDA6MTg3LDI0NDoxODgsMzA6NDMwLDIwODokVjMxLDI0NjokVjQxLDMxMDokVjUxfSksezM5OiRWRiw1NTo0MzF9LG8oJFZjMixbMiw0MThdLHsyNTk6NDMyLDI5MDpbMSw0MzNdfSksbygkVlMxLFsyLDQyMl0sezI2Mjo0MzQsMjkwOlsxLDQzNV19KSxvKCRWUzEsWzIsNDI0XSx7MjY0OjQzNiwyOTA6WzEsNDM3XX0pLHsyOTpbMSw0NDBdLDQxOlsxLDQzOF0sOTM6NDM5fSxvKCRWeSxbMiw1Nl0pLHszOTpbMSw0NDFdfSx7Mzk6WzIsMzA0XX0sezM5OlsyLDMwNV19LG8oJFZ5LFsyLDUwXSksezEzOiRWOCwxNjokVjksNTM6NDQyLDI4NjokVmJ9LG8oJFZkLFsyLDI5NF0pLG8oJFZ5LFsyLDUxXSksbygkVjIyLFsyLDE3XSksbygkVjIyLFsyLDI0NV0pLHs4MDpbMSw0NDNdfSx7ODA6WzEsNDQ0XX0sezEzOiRWOCwxNjokVjksMjg6JFZkMiwyOTokVnAxLDUzOjMxMCw2NTozMDgsNjY6MzA5LDcyOjQ0NSw3Mzo0NDYsNzQ6JFZlMiw3NTozMDcsNzY6JFZmMiw3Nzo0NDksMjQ3OjI2MiwyNDg6JFZxMSwyNDk6JFZyMSwyNTA6JFZzMSwyNTI6JFZ0MSwyNTM6MjY3LDI1NDokVnUxLDI1NTokVnYxLDI1NjoyNzAsMjU3OiRWdzEsMjU4OiRWeDEsMjYxOiRWeTEsMjYzOiRWejEsMjg2OiRWYiwzMTY6JFZBMSwzMTc6JFZCMSwzMTg6JFZDMSwzMTk6JFZEMSwzMjA6JFZFMSwzMjE6JFZGMX0sbygkVjMyLFsyLDI0OV0pLG8oJFY1MixbMiwyNDddKSx7MzE6WzEsNDUyXSwzMjpbMSw0NTFdfSx7MjM6NDUzLDQxOlsyLDIwNl0sODI6NDU0LDgzOiRWNH0sbygkVkwxLFsyLDMxOV0pLG8oJFZnMixbMiwzMjBdLHsxNTI6NDU1LDMwNDpbMSw0NTZdfSksezM5OiRWRiw1NTo0NTd9LHszOTokVkYsNTU6NDU4fSx7Mzk6JFZGLDU1OjQ1OX0sezEzOiRWOCwxNjokVjksMjg6WzEsNDYxXSw1Mzo0NjIsMTYxOjQ2MCwyODY6JFZifSxvKCRWaDIsWzIsMzMyXSx7MTYzOjQ2MywyOTc6WzEsNDY0XX0pLHsxMzokVjgsMTY6JFY5LDI5OiRWcDEsNTM6MzEwLDY1OjMwOCw2NjozMDksNzU6MzA3LDc3OjQ2NSwyNDc6MjYyLDI0ODokVnExLDI0OTokVnIxLDI1MDokVnMxLDI1MjokVnQxLDI1MzoyNjcsMjU0OiRWdTEsMjU1OiRWdjEsMjU2OjI3MCwyNTc6JFZ3MSwyNTg6JFZ4MSwyNjE6JFZ5MSwyNjM6JFZ6MSwyODY6JFZiLDMxNjokVkExLDMxNzokVkIxLDMxODokVkMxLDMxOTokVkQxLDMyMDokVkUxLDMyMTokVkYxfSx7Mjk6WzEsNDY2XX0sbygkVmkyLFsyLDc2XSksbygkVkwxLFsyLDY4XSksbygkVm8sWzIsMzI1XSx7Mzk6JFZqMiw0MTokVmoyLDgzOiRWajIsMTExOiRWajIsMTU5OiRWajIsMTYwOiRWajIsMTYyOiRWajIsMTY1OiRWajIsMTY2OiRWajJ9KSxvKCRWYTIsWzIsOTZdKSxvKCRWbyxbMiwzNjBdLHsxOTQ6NDY3fSksbygkVm8sWzIsMzU4XSksbygkVm8sWzIsMzU5XSksbygkVjcyLFsyLDM2OF0sezIwMTo0NjgsMjAyOjQ2OX0pLG8oJFZhMixbMiw5N10pLG8oJFZhMixbMiwzNTddKSx7MTM6JFY4LDE2OiRWOSwyODokVkcsMjk6JFZNMSwzMjpbMSw0NzBdLDUzOjE1Miw4MDokVkksODY6JFZKLDkxOjE1MywxNzU6NDA3LDE5MTo0MDgsMTk1OjQ3MSwyMTU6JFZOMSwyMTg6JFZMLDIxOTokVk0sMjM2OjE2MywyMzg6MTY0LDI2OToxNTksMjcyOiRWTiwyNzM6JFZPLDI3NDokVlAsMjc1OiRWUSwyNzY6JFZSLDI3NzokVlMsMjc4OiRWVCwyNzk6JFZVLDI4MDokVlYsMjgxOiRWVywyODI6JFZYLDI4MzokVlksMjg0OiRWWiwyODU6JFZfLDI4NjokVmJ9LG8oJFZRMSxbMiwzODNdKSxvKCRWUjEsWzIsMTIyXSksbygkVlIxLFsyLDEyM10pLHsyMTY6WzEsNDcyXX0sbygkVjUsWzIsMTJdKSxvKCRWTzEsWzIsMzUxXSksbygkVk8xLFsyLDM1Ml0sezE4NToyMjUsNTM6MjI3LDE4NDo0NzMsMTgwOjQ3NCwxMzokVjgsMTY6JFY5LDI4OiRWZTEsMTg3OiRWZjEsMjg2OiRWYn0pLG8oJFZrMixbMiw5NV0sezI1MTpbMSw0NzVdfSksbygkVjAxLFsyLDEwXSksbygkVmsxLFsyLDEzMV0pLG8oJFZsMSxbMiwxMzNdKSxvKCRWbDEsWzIsMTM2XSksbygkVm0xLFsyLDEzOF0pLG8oJFZtMSxbMiwxMzldLHsyNDM6MzQ4LDI0Mjo0NzYsMjkzOiRWVDEsMzA3OiRWVTF9KSxvKCRWbTEsWzIsMTQwXSx7MjQzOjM0OCwyNDI6NDc3LDI5MzokVlQxLDMwNzokVlUxfSksbygkVm4xLFsyLDE0Ml0pLG8oJFZTMSxbMiwzMzhdLHsxNjg6NDc4fSksbygkVlMxLFsyLDMzN10pLG8oWzYsMTMsMTYsMjgsMjksMzEsMzIsMzksNDEsNzEsNzQsNzYsNzksODAsODEsODMsODYsMTExLDE1OSwxNjAsMTYyLDE2NSwxNjYsMTgzLDIxNSwyMTgsMjE5LDIyMywyMjcsMjMxLDI0NiwyNDgsMjQ5LDI1MCwyNTEsMjUyLDI1NCwyNTUsMjU3LDI1OCwyNjEsMjYzLDI2OCwyNzIsMjczLDI3NCwyNzUsMjc2LDI3NywyNzgsMjc5LDI4MCwyODEsMjgyLDI4MywyODQsMjg1LDI4NiwyOTMsMzA0LDMwNywzMTAsMzExLDMxMiwzMTMsMzE0LDMxNSwzMTYsMzE3LDMxOCwzMTksMzIwLDMyMV0sWzIsMTUyXSksezMyOlsxLDQ3OV19LHsyNTE6WzEsNDgwXX0sezI1MTpbMSw0ODFdfSxvKCRWMTEsJFYyMSx7MjIwOjE4MywyMjQ6MTg0LDIyODoxODUsMjMyOjE4NiwyNDA6MTg3LDI0NDoxODgsMzA6NDgyLDIwODokVjMxLDI0NjokVjQxLDMxMDokVjUxfSksezMyOlsxLDQ4M119LHszMjpbMSw0ODRdfSxvKCRWWDEsWzIsMTYyXSksbygkVjExLCRWMjEsezIyMDoxODMsMjI0OjE4NCwyMjg6MTg1LDIzMjoxODYsMjQwOjE4NywyNDQ6MTg4LDI2MDo0ODUsMzA6NDg3LDIwODokVjMxLDI0NjokVjQxLDI5MzpbMSw0ODZdLDMxMDokVjUxfSksbygkVmMyLFsyLDQxOV0pLG8oJFYxMSwkVjIxLHsyMjA6MTgzLDIyNDoxODQsMjI4OjE4NSwyMzI6MTg2LDI0MDoxODcsMjQ0OjE4OCwzMDo0ODgsMjA4OiRWMzEsMjQ2OiRWNDEsMzEwOiRWNTF9KSxvKCRWUzEsWzIsNDIzXSksbygkVjExLCRWMjEsezIyMDoxODMsMjI0OjE4NCwyMjg6MTg1LDIzMjoxODYsMjQwOjE4NywyNDQ6MTg4LDMwOjQ4OSwyMDg6JFYzMSwyNDY6JFY0MSwzMTA6JFY1MX0pLG8oJFZTMSxbMiw0MjVdKSxvKCRWdSxbMiwzN10pLG8oJFYwMixbMiwyNTldKSx7MTM6JFY4LDE2OiRWOSw1MzoyODQsODA6JFZJLDkwOjQ5MSw5MToyODUsOTI6JFZHMSw5NDo0OTAsMjM2OjE2MywyMzg6MTY0LDI2OToxNTksMjcyOiRWTiwyNzM6JFZPLDI3NDokVlAsMjc1OiRWUSwyNzY6JFZSLDI3NzokVlMsMjc4OiRWVCwyNzk6JFZVLDI4MDokVlYsMjgxOiRWVywyODI6JFZYLDI4MzokVlksMjg0OiRWWiwyODU6JFZfLDI4NjokVmJ9LG8oJFZvLCRWeix7MTQ0OjEyOSwxNDA6NDkyLDE0Mzo0OTMsNDE6WzIsMzA2XX0pLG8oJFZCLFsyLDU0XSksbygkVjIyLFsyLDMwXSx7ODE6WzEsNDk0XX0pLG8oJFYyMixbMiwzMV0sezc5OlsxLDQ5NV19KSxvKCRWSTEsWzIsMjVdLHsyNDc6MjYyLDI1MzoyNjcsMjU2OjI3MCw3NTozMDcsNjU6MzA4LDY2OjMwOSw1MzozMTAsNzc6NDQ5LDczOjQ5NiwxMzokVjgsMTY6JFY5LDI4OiRWZDIsMjk6JFZwMSw3NDokVmUyLDc2OiRWZjIsMjQ4OiRWcTEsMjQ5OiRWcjEsMjUwOiRWczEsMjUyOiRWdDEsMjU0OiRWdTEsMjU1OiRWdjEsMjU3OiRWdzEsMjU4OiRWeDEsMjYxOiRWeTEsMjYzOiRWejEsMjg2OiRWYiwzMTY6JFZBMSwzMTc6JFZCMSwzMTg6JFZDMSwzMTk6JFZEMSwzMjA6JFZFMSwzMjE6JFZGMX0pLG8oJFZsMixbMiwyNTBdKSx7Mjk6JFZwMSw3NTo0OTd9LHsyOTokVnAxLDc1OjQ5OH0sbygkVmwyLFsyLDI4XSksbygkVmwyLFsyLDI5XSksbygkVjUyLFsyLDIxXSksezI4OlsxLDQ5OV19LHs0MTpbMiw3XX0sezQxOlsyLDIwN119LG8oJFZvLCRWYzEsezE1NToyMTYsMTUzOjUwMCwxNTQ6NTAxLDM5OiRWbTIsNDE6JFZtMiw4MzokVm0yLDExMTokVm0yLDE1OTokVm0yLDE2MDokVm0yLDE2MjokVm0yLDE2NTokVm0yLDE2NjokVm0yfSksbygkVmcyLFsyLDMyMV0pLG8oJFZpMixbMiw2OV0sezMwNTpbMSw1MDJdfSksbygkVmkyLFsyLDcwXSksbygkVmkyLFsyLDcxXSksezM5OiRWRiw1NTo1MDN9LHszOTpbMiwzMzBdfSx7Mzk6WzIsMzMxXX0sezEzOiRWOCwxNjokVjksMjg6WzEsNTA1XSw1Mzo1MDYsMTY0OjUwNCwyODY6JFZifSxvKCRWaDIsWzIsMzMzXSksbygkVmkyLFsyLDc0XSksbygkVjExLCRWMjEsezIyMDoxODMsMjI0OjE4NCwyMjg6MTg1LDIzMjoxODYsMjQwOjE4NywyNDQ6MTg4LDMwOjUwNywyMDg6JFYzMSwyNDY6JFY0MSwzMTA6JFY1MX0pLHsxMzokVjgsMTY6JFY5LDI4OiRWRywyOTokVk0xLDUzOjE1Miw4MDokVkksODY6JFZKLDkxOjE1MywxNzU6NDA3LDE5MTo0MDgsMTk1OjUwOCwyMTU6JFZOMSwyMTg6JFZMLDIxOTokVk0sMjM2OjE2MywyMzg6MTY0LDI2OToxNTksMjcyOiRWTiwyNzM6JFZPLDI3NDokVlAsMjc1OiRWUSwyNzY6JFZSLDI3NzokVlMsMjc4OiRWVCwyNzk6JFZVLDI4MDokVlYsMjgxOiRWVywyODI6JFZYLDI4MzokVlksMjg0OiRWWiwyODU6JFZfLDI4NjokVmJ9LG8oJFZRMSxbMiwxMDFdLHszMDY6WzEsNTA5XX0pLG8oJFZuMixbMiwzNzVdLHsyMDM6NTEwLDIwNzo1MTEsMjEzOlsxLDUxMl19KSxvKCRWaDEsWzIsMTE4XSksbygkVlExLFsyLDM4NF0pLG8oJFZoMSxbMiwxMTldKSxvKCRWTzEsWzIsOTBdKSxvKCRWTzEsWzIsMzUzXSksbygkVm8sWzIsMzU1XSksbygkVm4xLFsyLDQwMl0pLG8oJFZuMSxbMiw0MDRdKSxvKCRWMTEsJFYyMSx7MjIwOjE4MywyMjQ6MTg0LDIyODoxODUsMjMyOjE4NiwyNDA6MTg3LDI0NDoxODgsMzA6NTEzLDIwODokVjMxLDI0NjokVjQxLDMxMDokVjUxfSksbygkVlgxLFsyLDE1NV0pLG8oJFYxMSwkVjIxLHsyMjA6MTgzLDIyNDoxODQsMjI4OjE4NSwyMzI6MTg2LDI0MDoxODcsMjQ0OjE4OCwzMDo1MTQsMjA4OiRWMzEsMjQ2OiRWNDEsMzEwOiRWNTF9KSxvKCRWMTEsJFYyMSx7MjIwOjE4MywyMjQ6MTg0LDIyODoxODUsMjMyOjE4NiwyNDA6MTg3LDI0NDoxODgsMzA6NTE1LDIwODokVjMxLDI0NjokVjQxLDMxMDokVjUxfSksezMyOlsxLDUxNl0sMjUxOlsxLDUxN119LG8oJFZYMSxbMiwxNTldKSxvKCRWWDEsWzIsMTYxXSksezMyOlsxLDUxOF19LHszMjpbMiw0MjBdfSx7MzI6WzIsNDIxXX0sezMyOlsxLDUxOV19LHszMjpbMiw0MjZdLDE4MzpbMSw1MjJdLDI2NTo1MjAsMjY2OjUyMX0sezEzOiRWOCwxNjokVjksMzI6WzEsNTIzXSw1MzoyODQsODA6JFZJLDkwOjUyNCw5MToyODUsOTI6JFZHMSwyMzY6MTYzLDIzODoxNjQsMjY5OjE1OSwyNzI6JFZOLDI3MzokVk8sMjc0OiRWUCwyNzU6JFZRLDI3NjokVlIsMjc3OiRWUywyNzg6JFZULDI3OTokVlUsMjgwOiRWViwyODE6JFZXLDI4MjokVlgsMjgzOiRWWSwyODQ6JFZaLDI4NTokVl8sMjg2OiRWYn0sbygkVm8yLFsyLDI2MF0pLHs0MTpbMSw1MjVdfSx7NDE6WzIsMzA3XX0sezgwOlsxLDUyNl19LHs4MDpbMSw1MjddfSxvKCRWbDIsWzIsMjUxXSksbygkVmwyLFsyLDI2XSksbygkVmwyLFsyLDI3XSksezMyOlsxLDUyOF19LG8oJFZMMSxbMiw2N10pLG8oJFZMMSxbMiwzMjNdKSx7Mzk6WzIsMzI5XX0sbygkVmkyLFsyLDcyXSksezM5OiRWRiw1NTo1Mjl9LHszOTpbMiwzMzRdfSx7Mzk6WzIsMzM1XX0sezMxOlsxLDUzMF19LG8oJFZrMixbMiwzNjJdLHsxOTY6NTMxLDI1MTpbMSw1MzJdfSksbygkVjcyLFsyLDM2N10pLG8oWzEzLDE2LDI4LDI5LDMyLDgwLDg2LDIxNSwyMTgsMjE5LDI3MiwyNzMsMjc0LDI3NSwyNzYsMjc3LDI3OCwyNzksMjgwLDI4MSwyODIsMjgzLDI4NCwyODUsMjg2LDMwNl0sWzIsMTAyXSx7MzA3OlsxLDUzM119KSx7MTM6JFY4LDE2OiRWOSwyOTpbMSw1MzldLDUzOjUzNiwxODc6WzEsNTM3XSwyMDQ6NTM0LDIwNTo1MzUsMjA4OlsxLDUzOF0sMjg2OiRWYn0sbygkVm4yLFsyLDM3Nl0pLHszMjpbMSw1NDBdLDI1MTpbMSw1NDFdfSx7MzI6WzEsNTQyXX0sezI1MTpbMSw1NDNdfSxvKCRWWDEsWzIsODNdKSxvKCRWUzEsWzIsMzQxXSksbygkVlgxLFsyLDE2M10pLG8oJFZYMSxbMiwxNjRdKSx7MzI6WzEsNTQ0XX0sezMyOlsyLDQyN119LHsyNjc6WzEsNTQ1XX0sbygkVjAyLFsyLDQxXSksbygkVm8yLFsyLDI2MV0pLG8oJFZwMixbMiwzMDhdLHsxNDE6NTQ2LDMwNDpbMSw1NDddfSksbygkVjIyLFsyLDMyXSksbygkVjIyLFsyLDMzXSksbygkVjUyLFsyLDIyXSksbygkVmkyLFsyLDczXSksezI4OlsxLDU0OF19LG8oWzM5LDQxLDgzLDExMSwxNTksMTYwLDE2MiwxNjUsMTY2LDIxNiwzMDRdLFsyLDk4XSx7MTk3OjU0OSwxODM6WzEsNTUwXX0pLG8oJFZvLFsyLDM2MV0pLG8oJFY3MixbMiwzNjldKSxvKCRWcTIsWzIsMTA0XSksbygkVnEyLFsyLDM3M10sezIwNjo1NTEsMzA4OjU1MiwyOTM6WzEsNTU0XSwzMDk6WzEsNTUzXSwzMTA6WzEsNTU1XX0pLG8oJFZyMixbMiwxMDVdKSxvKCRWcjIsWzIsMTA2XSksezEzOiRWOCwxNjokVjksMjk6WzEsNTU5XSw1Mzo1NjAsODY6WzEsNTU4XSwxODc6JFZzMiwyMDk6NTU2LDIxMDo1NTcsMjEzOiRWdDIsMjg2OiRWYn0sbygkVjcyLCRWODIsezIwMDo0MDIsMTk5OjU2M30pLG8oJFZYMSxbMiw4MV0pLG8oJFZTMSxbMiwzMzldKSxvKCRWWDEsWzIsMTU2XSksbygkVjExLCRWMjEsezIyMDoxODMsMjI0OjE4NCwyMjg6MTg1LDIzMjoxODYsMjQwOjE4NywyNDQ6MTg4LDMwOjU2NCwyMDg6JFYzMSwyNDY6JFY0MSwzMTA6JFY1MX0pLG8oJFZYMSxbMiwxNjVdKSx7MjY4OlsxLDU2NV19LG8oJFZvLCRWeix7MTQ0OjEyOSwxNDI6NTY2LDE0Mzo1NjcsNDE6JFZ1MiwxMTE6JFZ1Mn0pLG8oJFZwMixbMiwzMDldKSx7MzI6WzEsNTY4XX0sbygkVmsyLFsyLDM2M10pLG8oJFZrMixbMiw5OV0sezIwMDo0MDIsMTk4OjU2OSwxOTk6NTcwLDEzOiRWODIsMTY6JFY4MiwyOTokVjgyLDE4NzokVjgyLDIwODokVjgyLDIxMzokVjgyLDI4NjokVjgyLDI4OlsxLDU3MV19KSxvKCRWcTIsWzIsMTAzXSksbygkVnEyLFsyLDM3NF0pLG8oJFZxMixbMiwzNzBdKSxvKCRWcTIsWzIsMzcxXSksbygkVnEyLFsyLDM3Ml0pLG8oJFZyMixbMiwxMDddKSxvKCRWcjIsWzIsMTA5XSksbygkVnIyLFsyLDExMF0pLG8oJFZ2MixbMiwzNzddLHsyMTE6NTcyfSksbygkVnIyLFsyLDExMl0pLG8oJFZyMixbMiwxMTNdKSx7MTM6JFY4LDE2OiRWOSw1Mzo1NzMsMTg3OlsxLDU3NF0sMjg2OiRWYn0sezMyOlsxLDU3NV19LHszMjpbMSw1NzZdfSx7MjY5OjU3NywyNzY6JFZSLDI3NzokVlMsMjc4OiRWVCwyNzk6JFZVfSxvKCRWYTEsWzIsNjJdKSxvKCRWYTEsWzIsMzExXSksbygkVmkyLFsyLDc1XSksbygkVm8sJFZQMSx7MTg4OjMyOSwxODY6NTc4fSksbygkVm8sWzIsMzY0XSksbygkVm8sWzIsMzY1XSksezEzOiRWOCwxNjokVjksMzI6WzIsMzc5XSw1Mzo1NjAsMTg3OiRWczIsMjEwOjU4MCwyMTI6NTc5LDIxMzokVnQyLDI4NjokVmJ9LG8oJFZyMixbMiwxMTRdKSxvKCRWcjIsWzIsMTE1XSksbygkVnIyLFsyLDEwOF0pLG8oJFZYMSxbMiwxNTddKSx7MzI6WzIsMTY2XX0sbygkVmsyLFsyLDEwMF0pLHszMjpbMSw1ODFdfSx7MzI6WzIsMzgwXSwzMDY6WzEsNTgyXX0sbygkVnIyLFsyLDExMV0pLG8oJFZ2MixbMiwzNzhdKV0sXG5kZWZhdWx0QWN0aW9uczogezU6WzIsMTkyXSw2OlsyLDE5M10sODpbMiwxOTFdLDI0OlsyLDFdLDI1OlsyLDNdLDI2OlsyLDIwM10sNjk6WzIsNDJdLDc4OlsyLDI4MF0sOTI6WzIsMjM3XSw5NzpbMiwzNDNdLDIyMDpbMiwyMjFdLDIyMTpbMiw4NV0sMjUxOlsyLDM5Nl0sMjc5OlsyLDQxN10sMzcxOlsyLDMwNF0sMzcyOlsyLDMwNV0sNDUzOlsyLDddLDQ1NDpbMiwyMDddLDQ2MTpbMiwzMzBdLDQ2MjpbMiwzMzFdLDQ4NjpbMiw0MjBdLDQ4NzpbMiw0MjFdLDQ5MzpbMiwzMDddLDUwMjpbMiwzMjldLDUwNTpbMiwzMzRdLDUwNjpbMiwzMzVdLDUyMTpbMiw0MjddLDU3NzpbMiwxNjZdfSxcbnBhcnNlRXJyb3I6IGZ1bmN0aW9uIHBhcnNlRXJyb3IgKHN0ciwgaGFzaCkge1xuICAgIGlmIChoYXNoLnJlY292ZXJhYmxlKSB7XG4gICAgICAgIHRoaXMudHJhY2Uoc3RyKTtcbiAgICB9IGVsc2Uge1xuICAgICAgICB2YXIgZXJyb3IgPSBuZXcgRXJyb3Ioc3RyKTtcbiAgICAgICAgZXJyb3IuaGFzaCA9IGhhc2g7XG4gICAgICAgIHRocm93IGVycm9yO1xuICAgIH1cbn0sXG5wYXJzZTogZnVuY3Rpb24gcGFyc2UoaW5wdXQpIHtcbiAgICB2YXIgc2VsZiA9IHRoaXMsIHN0YWNrID0gWzBdLCB0c3RhY2sgPSBbXSwgdnN0YWNrID0gW251bGxdLCBsc3RhY2sgPSBbXSwgdGFibGUgPSB0aGlzLnRhYmxlLCB5eXRleHQgPSAnJywgeXlsaW5lbm8gPSAwLCB5eWxlbmcgPSAwLCByZWNvdmVyaW5nID0gMCwgVEVSUk9SID0gMiwgRU9GID0gMTtcbiAgICB2YXIgYXJncyA9IGxzdGFjay5zbGljZS5jYWxsKGFyZ3VtZW50cywgMSk7XG4gICAgdmFyIGxleGVyID0gT2JqZWN0LmNyZWF0ZSh0aGlzLmxleGVyKTtcbiAgICB2YXIgc2hhcmVkU3RhdGUgPSB7IHl5OiB7fSB9O1xuICAgIGZvciAodmFyIGsgaW4gdGhpcy55eSkge1xuICAgICAgICBpZiAoT2JqZWN0LnByb3RvdHlwZS5oYXNPd25Qcm9wZXJ0eS5jYWxsKHRoaXMueXksIGspKSB7XG4gICAgICAgICAgICBzaGFyZWRTdGF0ZS55eVtrXSA9IHRoaXMueXlba107XG4gICAgICAgIH1cbiAgICB9XG4gICAgbGV4ZXIuc2V0SW5wdXQoaW5wdXQsIHNoYXJlZFN0YXRlLnl5KTtcbiAgICBzaGFyZWRTdGF0ZS55eS5sZXhlciA9IGxleGVyO1xuICAgIHNoYXJlZFN0YXRlLnl5LnBhcnNlciA9IHRoaXM7XG4gICAgaWYgKHR5cGVvZiBsZXhlci55eWxsb2MgPT0gJ3VuZGVmaW5lZCcpIHtcbiAgICAgICAgbGV4ZXIueXlsbG9jID0ge307XG4gICAgfVxuICAgIHZhciB5eWxvYyA9IGxleGVyLnl5bGxvYztcbiAgICBsc3RhY2sucHVzaCh5eWxvYyk7XG4gICAgdmFyIHJhbmdlcyA9IGxleGVyLm9wdGlvbnMgJiYgbGV4ZXIub3B0aW9ucy5yYW5nZXM7XG4gICAgaWYgKHR5cGVvZiBzaGFyZWRTdGF0ZS55eS5wYXJzZUVycm9yID09PSAnZnVuY3Rpb24nKSB7XG4gICAgICAgIHRoaXMucGFyc2VFcnJvciA9IHNoYXJlZFN0YXRlLnl5LnBhcnNlRXJyb3I7XG4gICAgfSBlbHNlIHtcbiAgICAgICAgdGhpcy5wYXJzZUVycm9yID0gT2JqZWN0LmdldFByb3RvdHlwZU9mKHRoaXMpLnBhcnNlRXJyb3I7XG4gICAgfVxuICAgIGZ1bmN0aW9uIHBvcFN0YWNrKG4pIHtcbiAgICAgICAgc3RhY2subGVuZ3RoID0gc3RhY2subGVuZ3RoIC0gMiAqIG47XG4gICAgICAgIHZzdGFjay5sZW5ndGggPSB2c3RhY2subGVuZ3RoIC0gbjtcbiAgICAgICAgbHN0YWNrLmxlbmd0aCA9IGxzdGFjay5sZW5ndGggLSBuO1xuICAgIH1cbiAgICBfdG9rZW5fc3RhY2s6XG4gICAgICAgIHZhciBsZXggPSBmdW5jdGlvbiAoKSB7XG4gICAgICAgICAgICB2YXIgdG9rZW47XG4gICAgICAgICAgICB0b2tlbiA9IGxleGVyLmxleCgpIHx8IEVPRjtcbiAgICAgICAgICAgIGlmICh0eXBlb2YgdG9rZW4gIT09ICdudW1iZXInKSB7XG4gICAgICAgICAgICAgICAgdG9rZW4gPSBzZWxmLnN5bWJvbHNfW3Rva2VuXSB8fCB0b2tlbjtcbiAgICAgICAgICAgIH1cbiAgICAgICAgICAgIHJldHVybiB0b2tlbjtcbiAgICAgICAgfTtcbiAgICB2YXIgc3ltYm9sLCBwcmVFcnJvclN5bWJvbCwgc3RhdGUsIGFjdGlvbiwgYSwgciwgeXl2YWwgPSB7fSwgcCwgbGVuLCBuZXdTdGF0ZSwgZXhwZWN0ZWQ7XG4gICAgd2hpbGUgKHRydWUpIHtcbiAgICAgICAgc3RhdGUgPSBzdGFja1tzdGFjay5sZW5ndGggLSAxXTtcbiAgICAgICAgaWYgKHRoaXMuZGVmYXVsdEFjdGlvbnNbc3RhdGVdKSB7XG4gICAgICAgICAgICBhY3Rpb24gPSB0aGlzLmRlZmF1bHRBY3Rpb25zW3N0YXRlXTtcbiAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgIGlmIChzeW1ib2wgPT09IG51bGwgfHwgdHlwZW9mIHN5bWJvbCA9PSAndW5kZWZpbmVkJykge1xuICAgICAgICAgICAgICAgIHN5bWJvbCA9IGxleCgpO1xuICAgICAgICAgICAgfVxuICAgICAgICAgICAgYWN0aW9uID0gdGFibGVbc3RhdGVdICYmIHRhYmxlW3N0YXRlXVtzeW1ib2xdO1xuICAgICAgICB9XG4gICAgICAgICAgICAgICAgICAgIGlmICh0eXBlb2YgYWN0aW9uID09PSAndW5kZWZpbmVkJyB8fCAhYWN0aW9uLmxlbmd0aCB8fCAhYWN0aW9uWzBdKSB7XG4gICAgICAgICAgICAgICAgdmFyIGVyclN0ciA9ICcnO1xuICAgICAgICAgICAgICAgIGV4cGVjdGVkID0gW107XG4gICAgICAgICAgICAgICAgZm9yIChwIGluIHRhYmxlW3N0YXRlXSkge1xuICAgICAgICAgICAgICAgICAgICBpZiAodGhpcy50ZXJtaW5hbHNfW3BdICYmIHAgPiBURVJST1IpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIGV4cGVjdGVkLnB1c2goJ1xcJycgKyB0aGlzLnRlcm1pbmFsc19bcF0gKyAnXFwnJyk7XG4gICAgICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgICAgaWYgKGxleGVyLnNob3dQb3NpdGlvbikge1xuICAgICAgICAgICAgICAgICAgICBlcnJTdHIgPSAnUGFyc2UgZXJyb3Igb24gbGluZSAnICsgKHl5bGluZW5vICsgMSkgKyAnOlxcbicgKyBsZXhlci5zaG93UG9zaXRpb24oKSArICdcXG5FeHBlY3RpbmcgJyArIGV4cGVjdGVkLmpvaW4oJywgJykgKyAnLCBnb3QgXFwnJyArICh0aGlzLnRlcm1pbmFsc19bc3ltYm9sXSB8fCBzeW1ib2wpICsgJ1xcJyc7XG4gICAgICAgICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgICAgICAgICAgZXJyU3RyID0gJ1BhcnNlIGVycm9yIG9uIGxpbmUgJyArICh5eWxpbmVubyArIDEpICsgJzogVW5leHBlY3RlZCAnICsgKHN5bWJvbCA9PSBFT0YgPyAnZW5kIG9mIGlucHV0JyA6ICdcXCcnICsgKHRoaXMudGVybWluYWxzX1tzeW1ib2xdIHx8IHN5bWJvbCkgKyAnXFwnJyk7XG4gICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgIHRoaXMucGFyc2VFcnJvcihlcnJTdHIsIHtcbiAgICAgICAgICAgICAgICAgICAgdGV4dDogbGV4ZXIubWF0Y2gsXG4gICAgICAgICAgICAgICAgICAgIHRva2VuOiB0aGlzLnRlcm1pbmFsc19bc3ltYm9sXSB8fCBzeW1ib2wsXG4gICAgICAgICAgICAgICAgICAgIGxpbmU6IGxleGVyLnl5bGluZW5vLFxuICAgICAgICAgICAgICAgICAgICBsb2M6IHl5bG9jLFxuICAgICAgICAgICAgICAgICAgICBleHBlY3RlZDogZXhwZWN0ZWRcbiAgICAgICAgICAgICAgICB9KTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgaWYgKGFjdGlvblswXSBpbnN0YW5jZW9mIEFycmF5ICYmIGFjdGlvbi5sZW5ndGggPiAxKSB7XG4gICAgICAgICAgICB0aHJvdyBuZXcgRXJyb3IoJ1BhcnNlIEVycm9yOiBtdWx0aXBsZSBhY3Rpb25zIHBvc3NpYmxlIGF0IHN0YXRlOiAnICsgc3RhdGUgKyAnLCB0b2tlbjogJyArIHN5bWJvbCk7XG4gICAgICAgIH1cbiAgICAgICAgc3dpdGNoIChhY3Rpb25bMF0pIHtcbiAgICAgICAgY2FzZSAxOlxuICAgICAgICAgICAgc3RhY2sucHVzaChzeW1ib2wpO1xuICAgICAgICAgICAgdnN0YWNrLnB1c2gobGV4ZXIueXl0ZXh0KTtcbiAgICAgICAgICAgIGxzdGFjay5wdXNoKGxleGVyLnl5bGxvYyk7XG4gICAgICAgICAgICBzdGFjay5wdXNoKGFjdGlvblsxXSk7XG4gICAgICAgICAgICBzeW1ib2wgPSBudWxsO1xuICAgICAgICAgICAgaWYgKCFwcmVFcnJvclN5bWJvbCkge1xuICAgICAgICAgICAgICAgIHl5bGVuZyA9IGxleGVyLnl5bGVuZztcbiAgICAgICAgICAgICAgICB5eXRleHQgPSBsZXhlci55eXRleHQ7XG4gICAgICAgICAgICAgICAgeXlsaW5lbm8gPSBsZXhlci55eWxpbmVubztcbiAgICAgICAgICAgICAgICB5eWxvYyA9IGxleGVyLnl5bGxvYztcbiAgICAgICAgICAgICAgICBpZiAocmVjb3ZlcmluZyA+IDApIHtcbiAgICAgICAgICAgICAgICAgICAgcmVjb3ZlcmluZy0tO1xuICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICAgICAgc3ltYm9sID0gcHJlRXJyb3JTeW1ib2w7XG4gICAgICAgICAgICAgICAgcHJlRXJyb3JTeW1ib2wgPSBudWxsO1xuICAgICAgICAgICAgfVxuICAgICAgICAgICAgYnJlYWs7XG4gICAgICAgIGNhc2UgMjpcbiAgICAgICAgICAgIGxlbiA9IHRoaXMucHJvZHVjdGlvbnNfW2FjdGlvblsxXV1bMV07XG4gICAgICAgICAgICB5eXZhbC4kID0gdnN0YWNrW3ZzdGFjay5sZW5ndGggLSBsZW5dO1xuICAgICAgICAgICAgeXl2YWwuXyQgPSB7XG4gICAgICAgICAgICAgICAgZmlyc3RfbGluZTogbHN0YWNrW2xzdGFjay5sZW5ndGggLSAobGVuIHx8IDEpXS5maXJzdF9saW5lLFxuICAgICAgICAgICAgICAgIGxhc3RfbGluZTogbHN0YWNrW2xzdGFjay5sZW5ndGggLSAxXS5sYXN0X2xpbmUsXG4gICAgICAgICAgICAgICAgZmlyc3RfY29sdW1uOiBsc3RhY2tbbHN0YWNrLmxlbmd0aCAtIChsZW4gfHwgMSldLmZpcnN0X2NvbHVtbixcbiAgICAgICAgICAgICAgICBsYXN0X2NvbHVtbjogbHN0YWNrW2xzdGFjay5sZW5ndGggLSAxXS5sYXN0X2NvbHVtblxuICAgICAgICAgICAgfTtcbiAgICAgICAgICAgIGlmIChyYW5nZXMpIHtcbiAgICAgICAgICAgICAgICB5eXZhbC5fJC5yYW5nZSA9IFtcbiAgICAgICAgICAgICAgICAgICAgbHN0YWNrW2xzdGFjay5sZW5ndGggLSAobGVuIHx8IDEpXS5yYW5nZVswXSxcbiAgICAgICAgICAgICAgICAgICAgbHN0YWNrW2xzdGFjay5sZW5ndGggLSAxXS5yYW5nZVsxXVxuICAgICAgICAgICAgICAgIF07XG4gICAgICAgICAgICB9XG4gICAgICAgICAgICByID0gdGhpcy5wZXJmb3JtQWN0aW9uLmFwcGx5KHl5dmFsLCBbXG4gICAgICAgICAgICAgICAgeXl0ZXh0LFxuICAgICAgICAgICAgICAgIHl5bGVuZyxcbiAgICAgICAgICAgICAgICB5eWxpbmVubyxcbiAgICAgICAgICAgICAgICBzaGFyZWRTdGF0ZS55eSxcbiAgICAgICAgICAgICAgICBhY3Rpb25bMV0sXG4gICAgICAgICAgICAgICAgdnN0YWNrLFxuICAgICAgICAgICAgICAgIGxzdGFja1xuICAgICAgICAgICAgXS5jb25jYXQoYXJncykpO1xuICAgICAgICAgICAgaWYgKHR5cGVvZiByICE9PSAndW5kZWZpbmVkJykge1xuICAgICAgICAgICAgICAgIHJldHVybiByO1xuICAgICAgICAgICAgfVxuICAgICAgICAgICAgaWYgKGxlbikge1xuICAgICAgICAgICAgICAgIHN0YWNrID0gc3RhY2suc2xpY2UoMCwgLTEgKiBsZW4gKiAyKTtcbiAgICAgICAgICAgICAgICB2c3RhY2sgPSB2c3RhY2suc2xpY2UoMCwgLTEgKiBsZW4pO1xuICAgICAgICAgICAgICAgIGxzdGFjayA9IGxzdGFjay5zbGljZSgwLCAtMSAqIGxlbik7XG4gICAgICAgICAgICB9XG4gICAgICAgICAgICBzdGFjay5wdXNoKHRoaXMucHJvZHVjdGlvbnNfW2FjdGlvblsxXV1bMF0pO1xuICAgICAgICAgICAgdnN0YWNrLnB1c2goeXl2YWwuJCk7XG4gICAgICAgICAgICBsc3RhY2sucHVzaCh5eXZhbC5fJCk7XG4gICAgICAgICAgICBuZXdTdGF0ZSA9IHRhYmxlW3N0YWNrW3N0YWNrLmxlbmd0aCAtIDJdXVtzdGFja1tzdGFjay5sZW5ndGggLSAxXV07XG4gICAgICAgICAgICBzdGFjay5wdXNoKG5ld1N0YXRlKTtcbiAgICAgICAgICAgIGJyZWFrO1xuICAgICAgICBjYXNlIDM6XG4gICAgICAgICAgICByZXR1cm4gdHJ1ZTtcbiAgICAgICAgfVxuICAgIH1cbiAgICByZXR1cm4gdHJ1ZTtcbn19O1xuXG4gIC8qXG4gICAgU1BBUlFMIHBhcnNlciBpbiB0aGUgSmlzb24gcGFyc2VyIGdlbmVyYXRvciBmb3JtYXQuXG4gICovXG5cbiAgLy8gQ29tbW9uIG5hbWVzcGFjZXMgYW5kIGVudGl0aWVzXG4gIHZhciBSREYgPSAnaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIycsXG4gICAgICBSREZfVFlQRSAgPSBSREYgKyAndHlwZScsXG4gICAgICBSREZfRklSU1QgPSBSREYgKyAnZmlyc3QnLFxuICAgICAgUkRGX1JFU1QgID0gUkRGICsgJ3Jlc3QnLFxuICAgICAgUkRGX05JTCAgID0gUkRGICsgJ25pbCcsXG4gICAgICBYU0QgPSAnaHR0cDovL3d3dy53My5vcmcvMjAwMS9YTUxTY2hlbWEjJyxcbiAgICAgIFhTRF9JTlRFR0VSICA9IFhTRCArICdpbnRlZ2VyJyxcbiAgICAgIFhTRF9ERUNJTUFMICA9IFhTRCArICdkZWNpbWFsJyxcbiAgICAgIFhTRF9ET1VCTEUgICA9IFhTRCArICdkb3VibGUnLFxuICAgICAgWFNEX0JPT0xFQU4gID0gWFNEICsgJ2Jvb2xlYW4nLFxuICAgICAgWFNEX1RSVUUgPSAgJ1widHJ1ZVwiXl4nICArIFhTRF9CT09MRUFOLFxuICAgICAgWFNEX0ZBTFNFID0gJ1wiZmFsc2VcIl5eJyArIFhTRF9CT09MRUFOO1xuXG4gIHZhciBiYXNlID0gJycsIGJhc2VQYXRoID0gJycsIGJhc2VSb290ID0gJyc7XG5cbiAgLy8gUmV0dXJucyBhIGxvd2VyY2FzZSB2ZXJzaW9uIG9mIHRoZSBnaXZlbiBzdHJpbmdcbiAgZnVuY3Rpb24gbG93ZXJjYXNlKHN0cmluZykge1xuICAgIHJldHVybiBzdHJpbmcudG9Mb3dlckNhc2UoKTtcbiAgfVxuXG4gIC8vIEFwcGVuZHMgdGhlIGl0ZW0gdG8gdGhlIGFycmF5IGFuZCByZXR1cm5zIHRoZSBhcnJheVxuICBmdW5jdGlvbiBhcHBlbmRUbyhhcnJheSwgaXRlbSkge1xuICAgIHJldHVybiBhcnJheS5wdXNoKGl0ZW0pLCBhcnJheTtcbiAgfVxuXG4gIC8vIEFwcGVuZHMgdGhlIGl0ZW1zIHRvIHRoZSBhcnJheSBhbmQgcmV0dXJucyB0aGUgYXJyYXlcbiAgZnVuY3Rpb24gYXBwZW5kQWxsVG8oYXJyYXksIGl0ZW1zKSB7XG4gICAgcmV0dXJuIGFycmF5LnB1c2guYXBwbHkoYXJyYXksIGl0ZW1zKSwgYXJyYXk7XG4gIH1cblxuICAvLyBFeHRlbmRzIGEgYmFzZSBvYmplY3Qgd2l0aCBwcm9wZXJ0aWVzIG9mIG90aGVyIG9iamVjdHNcbiAgZnVuY3Rpb24gZXh0ZW5kKGJhc2UpIHtcbiAgICBpZiAoIWJhc2UpIGJhc2UgPSB7fTtcbiAgICBmb3IgKHZhciBpID0gMSwgbCA9IGFyZ3VtZW50cy5sZW5ndGgsIGFyZzsgaSA8IGwgJiYgKGFyZyA9IGFyZ3VtZW50c1tpXSB8fCB7fSk7IGkrKylcbiAgICAgIGZvciAodmFyIG5hbWUgaW4gYXJnKVxuICAgICAgICBiYXNlW25hbWVdID0gYXJnW25hbWVdO1xuICAgIHJldHVybiBiYXNlO1xuICB9XG5cbiAgLy8gQ3JlYXRlcyBhbiBhcnJheSB0aGF0IGNvbnRhaW5zIGFsbCBpdGVtcyBvZiB0aGUgZ2l2ZW4gYXJyYXlzXG4gIGZ1bmN0aW9uIHVuaW9uQWxsKCkge1xuICAgIHZhciB1bmlvbiA9IFtdO1xuICAgIGZvciAodmFyIGkgPSAwLCBsID0gYXJndW1lbnRzLmxlbmd0aDsgaSA8IGw7IGkrKylcbiAgICAgIHVuaW9uID0gdW5pb24uY29uY2F0LmFwcGx5KHVuaW9uLCBhcmd1bWVudHNbaV0pO1xuICAgIHJldHVybiB1bmlvbjtcbiAgfVxuXG4gIC8vIFJlc29sdmVzIGFuIElSSSBhZ2FpbnN0IGEgYmFzZSBwYXRoXG4gIGZ1bmN0aW9uIHJlc29sdmVJUkkoaXJpKSB7XG4gICAgLy8gU3RyaXAgb2ZmIHBvc3NpYmxlIGFuZ3VsYXIgYnJhY2tldHNcbiAgICBpZiAoaXJpWzBdID09PSAnPCcpXG4gICAgICBpcmkgPSBpcmkuc3Vic3RyaW5nKDEsIGlyaS5sZW5ndGggLSAxKTtcbiAgICAvLyBSZXR1cm4gYWJzb2x1dGUgSVJJcyB1bm1vZGlmaWVkXG4gICAgaWYgKC9eW2Etel0rOi8udGVzdChpcmkpKVxuICAgICAgcmV0dXJuIGlyaTtcbiAgICBpZiAoIVBhcnNlci5iYXNlKVxuICAgICAgdGhyb3cgbmV3IEVycm9yKCdDYW5ub3QgcmVzb2x2ZSByZWxhdGl2ZSBJUkkgJyArIGlyaSArICcgYmVjYXVzZSBubyBiYXNlIElSSSB3YXMgc2V0LicpO1xuICAgIGlmICghYmFzZSkge1xuICAgICAgYmFzZSA9IFBhcnNlci5iYXNlO1xuICAgICAgYmFzZVBhdGggPSBiYXNlLnJlcGxhY2UoL1teXFwvOl0qJC8sICcnKTtcbiAgICAgIGJhc2VSb290ID0gYmFzZS5tYXRjaCgvXig/OlthLXpdKzpcXC8qKT9bXlxcL10qLylbMF07XG4gICAgfVxuICAgIHN3aXRjaCAoaXJpWzBdKSB7XG4gICAgLy8gQW4gZW1wdHkgcmVsYXRpdmUgSVJJIGluZGljYXRlcyB0aGUgYmFzZSBJUklcbiAgICBjYXNlIHVuZGVmaW5lZDpcbiAgICAgIHJldHVybiBiYXNlO1xuICAgIC8vIFJlc29sdmUgcmVsYXRpdmUgZnJhZ21lbnQgSVJJcyBhZ2FpbnN0IHRoZSBiYXNlIElSSVxuICAgIGNhc2UgJyMnOlxuICAgICAgcmV0dXJuIGJhc2UgKyBpcmk7XG4gICAgLy8gUmVzb2x2ZSByZWxhdGl2ZSBxdWVyeSBzdHJpbmcgSVJJcyBieSByZXBsYWNpbmcgdGhlIHF1ZXJ5IHN0cmluZ1xuICAgIGNhc2UgJz8nOlxuICAgICAgcmV0dXJuIGJhc2UucmVwbGFjZSgvKD86XFw/LiopPyQvLCBpcmkpO1xuICAgIC8vIFJlc29sdmUgcm9vdCByZWxhdGl2ZSBJUklzIGF0IHRoZSByb290IG9mIHRoZSBiYXNlIElSSVxuICAgIGNhc2UgJy8nOlxuICAgICAgcmV0dXJuIGJhc2VSb290ICsgaXJpO1xuICAgIC8vIFJlc29sdmUgYWxsIG90aGVyIElSSXMgYXQgdGhlIGJhc2UgSVJJJ3MgcGF0aFxuICAgIGRlZmF1bHQ6XG4gICAgICByZXR1cm4gYmFzZVBhdGggKyBpcmk7XG4gICAgfVxuICB9XG5cbiAgLy8gSWYgdGhlIGl0ZW0gaXMgYSB2YXJpYWJsZSwgZW5zdXJlcyBpdCBzdGFydHMgd2l0aCBhIHF1ZXN0aW9uIG1hcmtcbiAgZnVuY3Rpb24gdG9WYXIodmFyaWFibGUpIHtcbiAgICBpZiAodmFyaWFibGUpIHtcbiAgICAgIHZhciBmaXJzdCA9IHZhcmlhYmxlWzBdO1xuICAgICAgaWYgKGZpcnN0ID09PSAnPycpIHJldHVybiB2YXJpYWJsZTtcbiAgICAgIGlmIChmaXJzdCA9PT0gJyQnKSByZXR1cm4gJz8nICsgdmFyaWFibGUuc3Vic3RyKDEpO1xuICAgIH1cbiAgICByZXR1cm4gdmFyaWFibGU7XG4gIH1cblxuICAvLyBDcmVhdGVzIGFuIG9wZXJhdGlvbiB3aXRoIHRoZSBnaXZlbiBuYW1lIGFuZCBhcmd1bWVudHNcbiAgZnVuY3Rpb24gb3BlcmF0aW9uKG9wZXJhdG9yTmFtZSwgYXJncykge1xuICAgIHJldHVybiB7IHR5cGU6ICdvcGVyYXRpb24nLCBvcGVyYXRvcjogb3BlcmF0b3JOYW1lLCBhcmdzOiBhcmdzIHx8IFtdIH07XG4gIH1cblxuICAvLyBDcmVhdGVzIGFuIGV4cHJlc3Npb24gd2l0aCB0aGUgZ2l2ZW4gdHlwZSBhbmQgYXR0cmlidXRlc1xuICBmdW5jdGlvbiBleHByZXNzaW9uKGV4cHIsIGF0dHIpIHtcbiAgICB2YXIgZXhwcmVzc2lvbiA9IHsgZXhwcmVzc2lvbjogZXhwciB9O1xuICAgIGlmIChhdHRyKVxuICAgICAgZm9yICh2YXIgYSBpbiBhdHRyKVxuICAgICAgICBleHByZXNzaW9uW2FdID0gYXR0clthXTtcbiAgICByZXR1cm4gZXhwcmVzc2lvbjtcbiAgfVxuXG4gIC8vIENyZWF0ZXMgYSBwYXRoIHdpdGggdGhlIGdpdmVuIHR5cGUgYW5kIGl0ZW1zXG4gIGZ1bmN0aW9uIHBhdGgodHlwZSwgaXRlbXMpIHtcbiAgICByZXR1cm4geyB0eXBlOiAncGF0aCcsIHBhdGhUeXBlOiB0eXBlLCBpdGVtczogaXRlbXMgfTtcbiAgfVxuXG4gIC8vIFRyYW5zZm9ybXMgYSBsaXN0IG9mIG9wZXJhdGlvbnMgdHlwZXMgYW5kIGFyZ3VtZW50cyBpbnRvIGEgdHJlZSBvZiBvcGVyYXRpb25zXG4gIGZ1bmN0aW9uIGNyZWF0ZU9wZXJhdGlvblRyZWUoaW5pdGlhbEV4cHJlc3Npb24sIG9wZXJhdGlvbkxpc3QpIHtcbiAgICBmb3IgKHZhciBpID0gMCwgbCA9IG9wZXJhdGlvbkxpc3QubGVuZ3RoLCBpdGVtOyBpIDwgbCAmJiAoaXRlbSA9IG9wZXJhdGlvbkxpc3RbaV0pOyBpKyspXG4gICAgICBpbml0aWFsRXhwcmVzc2lvbiA9IG9wZXJhdGlvbihpdGVtWzBdLCBbaW5pdGlhbEV4cHJlc3Npb24sIGl0ZW1bMV1dKTtcbiAgICByZXR1cm4gaW5pdGlhbEV4cHJlc3Npb247XG4gIH1cblxuICAvLyBHcm91cCBkYXRhc2V0cyBieSBkZWZhdWx0IGFuZCBuYW1lZFxuICBmdW5jdGlvbiBncm91cERhdGFzZXRzKGZyb21DbGF1c2VzKSB7XG4gICAgdmFyIGRlZmF1bHRzID0gW10sIG5hbWVkID0gW10sIGwgPSBmcm9tQ2xhdXNlcy5sZW5ndGgsIGZyb21DbGF1c2U7XG4gICAgZm9yICh2YXIgaSA9IDA7IGkgPCBsICYmIChmcm9tQ2xhdXNlID0gZnJvbUNsYXVzZXNbaV0pOyBpKyspXG4gICAgICAoZnJvbUNsYXVzZS5uYW1lZCA/IG5hbWVkIDogZGVmYXVsdHMpLnB1c2goZnJvbUNsYXVzZS5pcmkpO1xuICAgIHJldHVybiBsID8geyBmcm9tOiB7IGRlZmF1bHQ6IGRlZmF1bHRzLCBuYW1lZDogbmFtZWQgfSB9IDogbnVsbDtcbiAgfVxuXG4gIC8vIENvbnZlcnRzIHRoZSBudW1iZXIgdG8gYSBzdHJpbmdcbiAgZnVuY3Rpb24gdG9JbnQoc3RyaW5nKSB7XG4gICAgcmV0dXJuIHBhcnNlSW50KHN0cmluZywgMTApO1xuICB9XG5cbiAgLy8gVHJhbnNmb3JtcyBhIHBvc3NpYmx5IHNpbmdsZSBncm91cCBpbnRvIGl0cyBwYXR0ZXJuc1xuICBmdW5jdGlvbiBkZWdyb3VwU2luZ2xlKGdyb3VwKSB7XG4gICAgcmV0dXJuIGdyb3VwLnR5cGUgPT09ICdncm91cCcgJiYgZ3JvdXAucGF0dGVybnMubGVuZ3RoID09PSAxID8gZ3JvdXAucGF0dGVybnNbMF0gOiBncm91cDtcbiAgfVxuXG4gIC8vIENyZWF0ZXMgYSBsaXRlcmFsIHdpdGggdGhlIGdpdmVuIHZhbHVlIGFuZCB0eXBlXG4gIGZ1bmN0aW9uIGNyZWF0ZUxpdGVyYWwodmFsdWUsIHR5cGUpIHtcbiAgICByZXR1cm4gJ1wiJyArIHZhbHVlICsgJ1wiXl4nICsgdHlwZTtcbiAgfVxuXG4gIC8vIENyZWF0ZXMgYSB0cmlwbGUgd2l0aCB0aGUgZ2l2ZW4gc3ViamVjdCwgcHJlZGljYXRlLCBhbmQgb2JqZWN0XG4gIGZ1bmN0aW9uIHRyaXBsZShzdWJqZWN0LCBwcmVkaWNhdGUsIG9iamVjdCkge1xuICAgIHZhciB0cmlwbGUgPSB7fTtcbiAgICBpZiAoc3ViamVjdCAgICE9IG51bGwpIHRyaXBsZS5zdWJqZWN0ICAgPSBzdWJqZWN0O1xuICAgIGlmIChwcmVkaWNhdGUgIT0gbnVsbCkgdHJpcGxlLnByZWRpY2F0ZSA9IHByZWRpY2F0ZTtcbiAgICBpZiAob2JqZWN0ICAgICE9IG51bGwpIHRyaXBsZS5vYmplY3QgICAgPSBvYmplY3Q7XG4gICAgcmV0dXJuIHRyaXBsZTtcbiAgfVxuXG4gIC8vIENyZWF0ZXMgYSBuZXcgYmxhbmsgbm9kZSBpZGVudGlmaWVyXG4gIGZ1bmN0aW9uIGJsYW5rKCkge1xuICAgIHJldHVybiAnXzpiJyArIGJsYW5rSWQrKztcbiAgfTtcbiAgdmFyIGJsYW5rSWQgPSAwO1xuICBQYXJzZXIuX3Jlc2V0QmxhbmtzID0gZnVuY3Rpb24gKCkgeyBibGFua0lkID0gMDsgfVxuXG4gIC8vIFJlZ3VsYXIgZXhwcmVzc2lvbiBhbmQgcmVwbGFjZW1lbnQgc3RyaW5ncyB0byBlc2NhcGUgc3RyaW5nc1xuICB2YXIgZXNjYXBlU2VxdWVuY2UgPSAvXFxcXHUoW2EtZkEtRjAtOV17NH0pfFxcXFxVKFthLWZBLUYwLTldezh9KXxcXFxcKC4pL2csXG4gICAgICBlc2NhcGVSZXBsYWNlbWVudHMgPSB7ICdcXFxcJzogJ1xcXFwnLCBcIidcIjogXCInXCIsICdcIic6ICdcIicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICd0JzogJ1xcdCcsICdiJzogJ1xcYicsICduJzogJ1xcbicsICdyJzogJ1xccicsICdmJzogJ1xcZicgfSxcbiAgICAgIGZyb21DaGFyQ29kZSA9IFN0cmluZy5mcm9tQ2hhckNvZGU7XG5cbiAgLy8gVHJhbnNsYXRlcyBlc2NhcGUgY29kZXMgaW4gdGhlIHN0cmluZyBpbnRvIHRoZWlyIHRleHR1YWwgZXF1aXZhbGVudFxuICBmdW5jdGlvbiB1bmVzY2FwZVN0cmluZyhzdHJpbmcsIHRyaW1MZW5ndGgpIHtcbiAgICBzdHJpbmcgPSBzdHJpbmcuc3Vic3RyaW5nKHRyaW1MZW5ndGgsIHN0cmluZy5sZW5ndGggLSB0cmltTGVuZ3RoKTtcbiAgICB0cnkge1xuICAgICAgc3RyaW5nID0gc3RyaW5nLnJlcGxhY2UoZXNjYXBlU2VxdWVuY2UsIGZ1bmN0aW9uIChzZXF1ZW5jZSwgdW5pY29kZTQsIHVuaWNvZGU4LCBlc2NhcGVkQ2hhcikge1xuICAgICAgICB2YXIgY2hhckNvZGU7XG4gICAgICAgIGlmICh1bmljb2RlNCkge1xuICAgICAgICAgIGNoYXJDb2RlID0gcGFyc2VJbnQodW5pY29kZTQsIDE2KTtcbiAgICAgICAgICBpZiAoaXNOYU4oY2hhckNvZGUpKSB0aHJvdyBuZXcgRXJyb3IoKTsgLy8gY2FuIG5ldmVyIGhhcHBlbiAocmVnZXgpLCBidXQgaGVscHMgcGVyZm9ybWFuY2VcbiAgICAgICAgICByZXR1cm4gZnJvbUNoYXJDb2RlKGNoYXJDb2RlKTtcbiAgICAgICAgfVxuICAgICAgICBlbHNlIGlmICh1bmljb2RlOCkge1xuICAgICAgICAgIGNoYXJDb2RlID0gcGFyc2VJbnQodW5pY29kZTgsIDE2KTtcbiAgICAgICAgICBpZiAoaXNOYU4oY2hhckNvZGUpKSB0aHJvdyBuZXcgRXJyb3IoKTsgLy8gY2FuIG5ldmVyIGhhcHBlbiAocmVnZXgpLCBidXQgaGVscHMgcGVyZm9ybWFuY2VcbiAgICAgICAgICBpZiAoY2hhckNvZGUgPCAweEZGRkYpIHJldHVybiBmcm9tQ2hhckNvZGUoY2hhckNvZGUpO1xuICAgICAgICAgIHJldHVybiBmcm9tQ2hhckNvZGUoMHhEODAwICsgKChjaGFyQ29kZSAtPSAweDEwMDAwKSA+PiAxMCksIDB4REMwMCArIChjaGFyQ29kZSAmIDB4M0ZGKSk7XG4gICAgICAgIH1cbiAgICAgICAgZWxzZSB7XG4gICAgICAgICAgdmFyIHJlcGxhY2VtZW50ID0gZXNjYXBlUmVwbGFjZW1lbnRzW2VzY2FwZWRDaGFyXTtcbiAgICAgICAgICBpZiAoIXJlcGxhY2VtZW50KSB0aHJvdyBuZXcgRXJyb3IoKTtcbiAgICAgICAgICByZXR1cm4gcmVwbGFjZW1lbnQ7XG4gICAgICAgIH1cbiAgICAgIH0pO1xuICAgIH1cbiAgICBjYXRjaCAoZXJyb3IpIHsgcmV0dXJuICcnOyB9XG4gICAgcmV0dXJuICdcIicgKyBzdHJpbmcgKyAnXCInO1xuICB9XG5cbiAgLy8gQ3JlYXRlcyBhIGxpc3QsIGNvbGxlY3RpbmcgaXRzIChwb3NzaWJseSBibGFuaykgaXRlbXMgYW5kIHRyaXBsZXMgYXNzb2NpYXRlZCB3aXRoIHRob3NlIGl0ZW1zXG4gIGZ1bmN0aW9uIGNyZWF0ZUxpc3Qob2JqZWN0cykge1xuICAgIHZhciBsaXN0ID0gYmxhbmsoKSwgaGVhZCA9IGxpc3QsIGxpc3RJdGVtcyA9IFtdLCBsaXN0VHJpcGxlcywgdHJpcGxlcyA9IFtdO1xuICAgIG9iamVjdHMuZm9yRWFjaChmdW5jdGlvbiAobykgeyBsaXN0SXRlbXMucHVzaChvLmVudGl0eSk7IGFwcGVuZEFsbFRvKHRyaXBsZXMsIG8udHJpcGxlcyk7IH0pO1xuXG4gICAgLy8gQnVpbGQgYW4gUkRGIGxpc3Qgb3V0IG9mIHRoZSBpdGVtc1xuICAgIGZvciAodmFyIGkgPSAwLCBqID0gMCwgbCA9IGxpc3RJdGVtcy5sZW5ndGgsIGxpc3RUcmlwbGVzID0gQXJyYXkobCAqIDIpOyBpIDwgbDspXG4gICAgICBsaXN0VHJpcGxlc1tqKytdID0gdHJpcGxlKGhlYWQsIFJERl9GSVJTVCwgbGlzdEl0ZW1zW2ldKSxcbiAgICAgIGxpc3RUcmlwbGVzW2orK10gPSB0cmlwbGUoaGVhZCwgUkRGX1JFU1QsICBoZWFkID0gKytpIDwgbCA/IGJsYW5rKCkgOiBSREZfTklMKTtcblxuICAgIC8vIFJldHVybiB0aGUgbGlzdCdzIGlkZW50aWZpZXIsIGl0cyB0cmlwbGVzLCBhbmQgdGhlIHRyaXBsZXMgYXNzb2NpYXRlZCB3aXRoIGl0cyBpdGVtc1xuICAgIHJldHVybiB7IGVudGl0eTogbGlzdCwgdHJpcGxlczogYXBwZW5kQWxsVG8obGlzdFRyaXBsZXMsIHRyaXBsZXMpIH07XG4gIH1cblxuICAvLyBDcmVhdGVzIGEgYmxhbmsgbm9kZSBpZGVudGlmaWVyLCBjb2xsZWN0aW5nIHRyaXBsZXMgd2l0aCB0aGF0IGJsYW5rIG5vZGUgYXMgc3ViamVjdFxuICBmdW5jdGlvbiBjcmVhdGVBbm9ueW1vdXNPYmplY3QocHJvcGVydHlMaXN0KSB7XG4gICAgdmFyIGVudGl0eSA9IGJsYW5rKCk7XG4gICAgcmV0dXJuIHtcbiAgICAgIGVudGl0eTogZW50aXR5LFxuICAgICAgdHJpcGxlczogcHJvcGVydHlMaXN0Lm1hcChmdW5jdGlvbiAodCkgeyByZXR1cm4gZXh0ZW5kKHRyaXBsZShlbnRpdHkpLCB0KTsgfSlcbiAgICB9O1xuICB9XG5cbiAgLy8gQ29sbGVjdHMgYWxsIChwb3NzaWJseSBibGFuaykgb2JqZWN0cywgYW5kIHRyaXBsZXMgdGhhdCBoYXZlIHRoZW0gYXMgc3ViamVjdFxuICBmdW5jdGlvbiBvYmplY3RMaXN0VG9UcmlwbGVzKHByZWRpY2F0ZSwgb2JqZWN0TGlzdCwgb3RoZXJUcmlwbGVzKSB7XG4gICAgdmFyIG9iamVjdHMgPSBbXSwgdHJpcGxlcyA9IFtdO1xuICAgIG9iamVjdExpc3QuZm9yRWFjaChmdW5jdGlvbiAobCkge1xuICAgICAgb2JqZWN0cy5wdXNoKHRyaXBsZShudWxsLCBwcmVkaWNhdGUsIGwuZW50aXR5KSk7XG4gICAgICBhcHBlbmRBbGxUbyh0cmlwbGVzLCBsLnRyaXBsZXMpO1xuICAgIH0pO1xuICAgIHJldHVybiB1bmlvbkFsbChvYmplY3RzLCBvdGhlclRyaXBsZXMgfHwgW10sIHRyaXBsZXMpO1xuICB9XG5cbiAgLy8gU2ltcGxpZmllcyBncm91cHMgYnkgbWVyZ2luZyBhZGphY2VudCBCR1BzXG4gIGZ1bmN0aW9uIG1lcmdlQWRqYWNlbnRCR1BzKGdyb3Vwcykge1xuICAgIHZhciBtZXJnZWQgPSBbXSwgY3VycmVudEJncDtcbiAgICBmb3IgKHZhciBpID0gMCwgZ3JvdXA7IGdyb3VwID0gZ3JvdXBzW2ldOyBpKyspIHtcbiAgICAgIHN3aXRjaCAoZ3JvdXAudHlwZSkge1xuICAgICAgICAvLyBBZGQgYSBCR1AncyB0cmlwbGVzIHRvIHRoZSBjdXJyZW50IEJHUFxuICAgICAgICBjYXNlICdiZ3AnOlxuICAgICAgICAgIGlmIChncm91cC50cmlwbGVzLmxlbmd0aCkge1xuICAgICAgICAgICAgaWYgKCFjdXJyZW50QmdwKVxuICAgICAgICAgICAgICBhcHBlbmRUbyhtZXJnZWQsIGN1cnJlbnRCZ3AgPSBncm91cCk7XG4gICAgICAgICAgICBlbHNlXG4gICAgICAgICAgICAgIGFwcGVuZEFsbFRvKGN1cnJlbnRCZ3AudHJpcGxlcywgZ3JvdXAudHJpcGxlcyk7XG4gICAgICAgICAgfVxuICAgICAgICAgIGJyZWFrO1xuICAgICAgICAvLyBBbGwgb3RoZXIgZ3JvdXBzIGJyZWFrIHVwIGEgQkdQXG4gICAgICAgIGRlZmF1bHQ6XG4gICAgICAgICAgLy8gT25seSBhZGQgdGhlIGdyb3VwIGlmIGl0cyBwYXR0ZXJuIGlzIG5vbi1lbXB0eVxuICAgICAgICAgIGlmICghZ3JvdXAucGF0dGVybnMgfHwgZ3JvdXAucGF0dGVybnMubGVuZ3RoID4gMCkge1xuICAgICAgICAgICAgYXBwZW5kVG8obWVyZ2VkLCBncm91cCk7XG4gICAgICAgICAgICBjdXJyZW50QmdwID0gbnVsbDtcbiAgICAgICAgICB9XG4gICAgICB9XG4gICAgfVxuICAgIHJldHVybiBtZXJnZWQ7XG4gIH1cbi8qIGdlbmVyYXRlZCBieSBqaXNvbi1sZXggMC4zLjQgKi9cbnZhciBsZXhlciA9IChmdW5jdGlvbigpe1xudmFyIGxleGVyID0gKHtcblxuRU9GOjEsXG5cbnBhcnNlRXJyb3I6ZnVuY3Rpb24gcGFyc2VFcnJvcihzdHIsIGhhc2gpIHtcbiAgICAgICAgaWYgKHRoaXMueXkucGFyc2VyKSB7XG4gICAgICAgICAgICB0aGlzLnl5LnBhcnNlci5wYXJzZUVycm9yKHN0ciwgaGFzaCk7XG4gICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICB0aHJvdyBuZXcgRXJyb3Ioc3RyKTtcbiAgICAgICAgfVxuICAgIH0sXG5cbi8vIHJlc2V0cyB0aGUgbGV4ZXIsIHNldHMgbmV3IGlucHV0XG5zZXRJbnB1dDpmdW5jdGlvbiAoaW5wdXQsIHl5KSB7XG4gICAgICAgIHRoaXMueXkgPSB5eSB8fCB0aGlzLnl5IHx8IHt9O1xuICAgICAgICB0aGlzLl9pbnB1dCA9IGlucHV0O1xuICAgICAgICB0aGlzLl9tb3JlID0gdGhpcy5fYmFja3RyYWNrID0gdGhpcy5kb25lID0gZmFsc2U7XG4gICAgICAgIHRoaXMueXlsaW5lbm8gPSB0aGlzLnl5bGVuZyA9IDA7XG4gICAgICAgIHRoaXMueXl0ZXh0ID0gdGhpcy5tYXRjaGVkID0gdGhpcy5tYXRjaCA9ICcnO1xuICAgICAgICB0aGlzLmNvbmRpdGlvblN0YWNrID0gWydJTklUSUFMJ107XG4gICAgICAgIHRoaXMueXlsbG9jID0ge1xuICAgICAgICAgICAgZmlyc3RfbGluZTogMSxcbiAgICAgICAgICAgIGZpcnN0X2NvbHVtbjogMCxcbiAgICAgICAgICAgIGxhc3RfbGluZTogMSxcbiAgICAgICAgICAgIGxhc3RfY29sdW1uOiAwXG4gICAgICAgIH07XG4gICAgICAgIGlmICh0aGlzLm9wdGlvbnMucmFuZ2VzKSB7XG4gICAgICAgICAgICB0aGlzLnl5bGxvYy5yYW5nZSA9IFswLDBdO1xuICAgICAgICB9XG4gICAgICAgIHRoaXMub2Zmc2V0ID0gMDtcbiAgICAgICAgcmV0dXJuIHRoaXM7XG4gICAgfSxcblxuLy8gY29uc3VtZXMgYW5kIHJldHVybnMgb25lIGNoYXIgZnJvbSB0aGUgaW5wdXRcbmlucHV0OmZ1bmN0aW9uICgpIHtcbiAgICAgICAgdmFyIGNoID0gdGhpcy5faW5wdXRbMF07XG4gICAgICAgIHRoaXMueXl0ZXh0ICs9IGNoO1xuICAgICAgICB0aGlzLnl5bGVuZysrO1xuICAgICAgICB0aGlzLm9mZnNldCsrO1xuICAgICAgICB0aGlzLm1hdGNoICs9IGNoO1xuICAgICAgICB0aGlzLm1hdGNoZWQgKz0gY2g7XG4gICAgICAgIHZhciBsaW5lcyA9IGNoLm1hdGNoKC8oPzpcXHJcXG4/fFxcbikuKi9nKTtcbiAgICAgICAgaWYgKGxpbmVzKSB7XG4gICAgICAgICAgICB0aGlzLnl5bGluZW5vKys7XG4gICAgICAgICAgICB0aGlzLnl5bGxvYy5sYXN0X2xpbmUrKztcbiAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgIHRoaXMueXlsbG9jLmxhc3RfY29sdW1uKys7XG4gICAgICAgIH1cbiAgICAgICAgaWYgKHRoaXMub3B0aW9ucy5yYW5nZXMpIHtcbiAgICAgICAgICAgIHRoaXMueXlsbG9jLnJhbmdlWzFdKys7XG4gICAgICAgIH1cblxuICAgICAgICB0aGlzLl9pbnB1dCA9IHRoaXMuX2lucHV0LnNsaWNlKDEpO1xuICAgICAgICByZXR1cm4gY2g7XG4gICAgfSxcblxuLy8gdW5zaGlmdHMgb25lIGNoYXIgKG9yIGEgc3RyaW5nKSBpbnRvIHRoZSBpbnB1dFxudW5wdXQ6ZnVuY3Rpb24gKGNoKSB7XG4gICAgICAgIHZhciBsZW4gPSBjaC5sZW5ndGg7XG4gICAgICAgIHZhciBsaW5lcyA9IGNoLnNwbGl0KC8oPzpcXHJcXG4/fFxcbikvZyk7XG5cbiAgICAgICAgdGhpcy5faW5wdXQgPSBjaCArIHRoaXMuX2lucHV0O1xuICAgICAgICB0aGlzLnl5dGV4dCA9IHRoaXMueXl0ZXh0LnN1YnN0cigwLCB0aGlzLnl5dGV4dC5sZW5ndGggLSBsZW4pO1xuICAgICAgICAvL3RoaXMueXlsZW5nIC09IGxlbjtcbiAgICAgICAgdGhpcy5vZmZzZXQgLT0gbGVuO1xuICAgICAgICB2YXIgb2xkTGluZXMgPSB0aGlzLm1hdGNoLnNwbGl0KC8oPzpcXHJcXG4/fFxcbikvZyk7XG4gICAgICAgIHRoaXMubWF0Y2ggPSB0aGlzLm1hdGNoLnN1YnN0cigwLCB0aGlzLm1hdGNoLmxlbmd0aCAtIDEpO1xuICAgICAgICB0aGlzLm1hdGNoZWQgPSB0aGlzLm1hdGNoZWQuc3Vic3RyKDAsIHRoaXMubWF0Y2hlZC5sZW5ndGggLSAxKTtcblxuICAgICAgICBpZiAobGluZXMubGVuZ3RoIC0gMSkge1xuICAgICAgICAgICAgdGhpcy55eWxpbmVubyAtPSBsaW5lcy5sZW5ndGggLSAxO1xuICAgICAgICB9XG4gICAgICAgIHZhciByID0gdGhpcy55eWxsb2MucmFuZ2U7XG5cbiAgICAgICAgdGhpcy55eWxsb2MgPSB7XG4gICAgICAgICAgICBmaXJzdF9saW5lOiB0aGlzLnl5bGxvYy5maXJzdF9saW5lLFxuICAgICAgICAgICAgbGFzdF9saW5lOiB0aGlzLnl5bGluZW5vICsgMSxcbiAgICAgICAgICAgIGZpcnN0X2NvbHVtbjogdGhpcy55eWxsb2MuZmlyc3RfY29sdW1uLFxuICAgICAgICAgICAgbGFzdF9jb2x1bW46IGxpbmVzID9cbiAgICAgICAgICAgICAgICAobGluZXMubGVuZ3RoID09PSBvbGRMaW5lcy5sZW5ndGggPyB0aGlzLnl5bGxvYy5maXJzdF9jb2x1bW4gOiAwKVxuICAgICAgICAgICAgICAgICArIG9sZExpbmVzW29sZExpbmVzLmxlbmd0aCAtIGxpbmVzLmxlbmd0aF0ubGVuZ3RoIC0gbGluZXNbMF0ubGVuZ3RoIDpcbiAgICAgICAgICAgICAgdGhpcy55eWxsb2MuZmlyc3RfY29sdW1uIC0gbGVuXG4gICAgICAgIH07XG5cbiAgICAgICAgaWYgKHRoaXMub3B0aW9ucy5yYW5nZXMpIHtcbiAgICAgICAgICAgIHRoaXMueXlsbG9jLnJhbmdlID0gW3JbMF0sIHJbMF0gKyB0aGlzLnl5bGVuZyAtIGxlbl07XG4gICAgICAgIH1cbiAgICAgICAgdGhpcy55eWxlbmcgPSB0aGlzLnl5dGV4dC5sZW5ndGg7XG4gICAgICAgIHJldHVybiB0aGlzO1xuICAgIH0sXG5cbi8vIFdoZW4gY2FsbGVkIGZyb20gYWN0aW9uLCBjYWNoZXMgbWF0Y2hlZCB0ZXh0IGFuZCBhcHBlbmRzIGl0IG9uIG5leHQgYWN0aW9uXG5tb3JlOmZ1bmN0aW9uICgpIHtcbiAgICAgICAgdGhpcy5fbW9yZSA9IHRydWU7XG4gICAgICAgIHJldHVybiB0aGlzO1xuICAgIH0sXG5cbi8vIFdoZW4gY2FsbGVkIGZyb20gYWN0aW9uLCBzaWduYWxzIHRoZSBsZXhlciB0aGF0IHRoaXMgcnVsZSBmYWlscyB0byBtYXRjaCB0aGUgaW5wdXQsIHNvIHRoZSBuZXh0IG1hdGNoaW5nIHJ1bGUgKHJlZ2V4KSBzaG91bGQgYmUgdGVzdGVkIGluc3RlYWQuXG5yZWplY3Q6ZnVuY3Rpb24gKCkge1xuICAgICAgICBpZiAodGhpcy5vcHRpb25zLmJhY2t0cmFja19sZXhlcikge1xuICAgICAgICAgICAgdGhpcy5fYmFja3RyYWNrID0gdHJ1ZTtcbiAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgIHJldHVybiB0aGlzLnBhcnNlRXJyb3IoJ0xleGljYWwgZXJyb3Igb24gbGluZSAnICsgKHRoaXMueXlsaW5lbm8gKyAxKSArICcuIFlvdSBjYW4gb25seSBpbnZva2UgcmVqZWN0KCkgaW4gdGhlIGxleGVyIHdoZW4gdGhlIGxleGVyIGlzIG9mIHRoZSBiYWNrdHJhY2tpbmcgcGVyc3Vhc2lvbiAob3B0aW9ucy5iYWNrdHJhY2tfbGV4ZXIgPSB0cnVlKS5cXG4nICsgdGhpcy5zaG93UG9zaXRpb24oKSwge1xuICAgICAgICAgICAgICAgIHRleHQ6IFwiXCIsXG4gICAgICAgICAgICAgICAgdG9rZW46IG51bGwsXG4gICAgICAgICAgICAgICAgbGluZTogdGhpcy55eWxpbmVub1xuICAgICAgICAgICAgfSk7XG5cbiAgICAgICAgfVxuICAgICAgICByZXR1cm4gdGhpcztcbiAgICB9LFxuXG4vLyByZXRhaW4gZmlyc3QgbiBjaGFyYWN0ZXJzIG9mIHRoZSBtYXRjaFxubGVzczpmdW5jdGlvbiAobikge1xuICAgICAgICB0aGlzLnVucHV0KHRoaXMubWF0Y2guc2xpY2UobikpO1xuICAgIH0sXG5cbi8vIGRpc3BsYXlzIGFscmVhZHkgbWF0Y2hlZCBpbnB1dCwgaS5lLiBmb3IgZXJyb3IgbWVzc2FnZXNcbnBhc3RJbnB1dDpmdW5jdGlvbiAoKSB7XG4gICAgICAgIHZhciBwYXN0ID0gdGhpcy5tYXRjaGVkLnN1YnN0cigwLCB0aGlzLm1hdGNoZWQubGVuZ3RoIC0gdGhpcy5tYXRjaC5sZW5ndGgpO1xuICAgICAgICByZXR1cm4gKHBhc3QubGVuZ3RoID4gMjAgPyAnLi4uJzonJykgKyBwYXN0LnN1YnN0cigtMjApLnJlcGxhY2UoL1xcbi9nLCBcIlwiKTtcbiAgICB9LFxuXG4vLyBkaXNwbGF5cyB1cGNvbWluZyBpbnB1dCwgaS5lLiBmb3IgZXJyb3IgbWVzc2FnZXNcbnVwY29taW5nSW5wdXQ6ZnVuY3Rpb24gKCkge1xuICAgICAgICB2YXIgbmV4dCA9IHRoaXMubWF0Y2g7XG4gICAgICAgIGlmIChuZXh0Lmxlbmd0aCA8IDIwKSB7XG4gICAgICAgICAgICBuZXh0ICs9IHRoaXMuX2lucHV0LnN1YnN0cigwLCAyMC1uZXh0Lmxlbmd0aCk7XG4gICAgICAgIH1cbiAgICAgICAgcmV0dXJuIChuZXh0LnN1YnN0cigwLDIwKSArIChuZXh0Lmxlbmd0aCA+IDIwID8gJy4uLicgOiAnJykpLnJlcGxhY2UoL1xcbi9nLCBcIlwiKTtcbiAgICB9LFxuXG4vLyBkaXNwbGF5cyB0aGUgY2hhcmFjdGVyIHBvc2l0aW9uIHdoZXJlIHRoZSBsZXhpbmcgZXJyb3Igb2NjdXJyZWQsIGkuZS4gZm9yIGVycm9yIG1lc3NhZ2VzXG5zaG93UG9zaXRpb246ZnVuY3Rpb24gKCkge1xuICAgICAgICB2YXIgcHJlID0gdGhpcy5wYXN0SW5wdXQoKTtcbiAgICAgICAgdmFyIGMgPSBuZXcgQXJyYXkocHJlLmxlbmd0aCArIDEpLmpvaW4oXCItXCIpO1xuICAgICAgICByZXR1cm4gcHJlICsgdGhpcy51cGNvbWluZ0lucHV0KCkgKyBcIlxcblwiICsgYyArIFwiXlwiO1xuICAgIH0sXG5cbi8vIHRlc3QgdGhlIGxleGVkIHRva2VuOiByZXR1cm4gRkFMU0Ugd2hlbiBub3QgYSBtYXRjaCwgb3RoZXJ3aXNlIHJldHVybiB0b2tlblxudGVzdF9tYXRjaDpmdW5jdGlvbihtYXRjaCwgaW5kZXhlZF9ydWxlKSB7XG4gICAgICAgIHZhciB0b2tlbixcbiAgICAgICAgICAgIGxpbmVzLFxuICAgICAgICAgICAgYmFja3VwO1xuXG4gICAgICAgIGlmICh0aGlzLm9wdGlvbnMuYmFja3RyYWNrX2xleGVyKSB7XG4gICAgICAgICAgICAvLyBzYXZlIGNvbnRleHRcbiAgICAgICAgICAgIGJhY2t1cCA9IHtcbiAgICAgICAgICAgICAgICB5eWxpbmVubzogdGhpcy55eWxpbmVubyxcbiAgICAgICAgICAgICAgICB5eWxsb2M6IHtcbiAgICAgICAgICAgICAgICAgICAgZmlyc3RfbGluZTogdGhpcy55eWxsb2MuZmlyc3RfbGluZSxcbiAgICAgICAgICAgICAgICAgICAgbGFzdF9saW5lOiB0aGlzLmxhc3RfbGluZSxcbiAgICAgICAgICAgICAgICAgICAgZmlyc3RfY29sdW1uOiB0aGlzLnl5bGxvYy5maXJzdF9jb2x1bW4sXG4gICAgICAgICAgICAgICAgICAgIGxhc3RfY29sdW1uOiB0aGlzLnl5bGxvYy5sYXN0X2NvbHVtblxuICAgICAgICAgICAgICAgIH0sXG4gICAgICAgICAgICAgICAgeXl0ZXh0OiB0aGlzLnl5dGV4dCxcbiAgICAgICAgICAgICAgICBtYXRjaDogdGhpcy5tYXRjaCxcbiAgICAgICAgICAgICAgICBtYXRjaGVzOiB0aGlzLm1hdGNoZXMsXG4gICAgICAgICAgICAgICAgbWF0Y2hlZDogdGhpcy5tYXRjaGVkLFxuICAgICAgICAgICAgICAgIHl5bGVuZzogdGhpcy55eWxlbmcsXG4gICAgICAgICAgICAgICAgb2Zmc2V0OiB0aGlzLm9mZnNldCxcbiAgICAgICAgICAgICAgICBfbW9yZTogdGhpcy5fbW9yZSxcbiAgICAgICAgICAgICAgICBfaW5wdXQ6IHRoaXMuX2lucHV0LFxuICAgICAgICAgICAgICAgIHl5OiB0aGlzLnl5LFxuICAgICAgICAgICAgICAgIGNvbmRpdGlvblN0YWNrOiB0aGlzLmNvbmRpdGlvblN0YWNrLnNsaWNlKDApLFxuICAgICAgICAgICAgICAgIGRvbmU6IHRoaXMuZG9uZVxuICAgICAgICAgICAgfTtcbiAgICAgICAgICAgIGlmICh0aGlzLm9wdGlvbnMucmFuZ2VzKSB7XG4gICAgICAgICAgICAgICAgYmFja3VwLnl5bGxvYy5yYW5nZSA9IHRoaXMueXlsbG9jLnJhbmdlLnNsaWNlKDApO1xuICAgICAgICAgICAgfVxuICAgICAgICB9XG5cbiAgICAgICAgbGluZXMgPSBtYXRjaFswXS5tYXRjaCgvKD86XFxyXFxuP3xcXG4pLiovZyk7XG4gICAgICAgIGlmIChsaW5lcykge1xuICAgICAgICAgICAgdGhpcy55eWxpbmVubyArPSBsaW5lcy5sZW5ndGg7XG4gICAgICAgIH1cbiAgICAgICAgdGhpcy55eWxsb2MgPSB7XG4gICAgICAgICAgICBmaXJzdF9saW5lOiB0aGlzLnl5bGxvYy5sYXN0X2xpbmUsXG4gICAgICAgICAgICBsYXN0X2xpbmU6IHRoaXMueXlsaW5lbm8gKyAxLFxuICAgICAgICAgICAgZmlyc3RfY29sdW1uOiB0aGlzLnl5bGxvYy5sYXN0X2NvbHVtbixcbiAgICAgICAgICAgIGxhc3RfY29sdW1uOiBsaW5lcyA/XG4gICAgICAgICAgICAgICAgICAgICAgICAgbGluZXNbbGluZXMubGVuZ3RoIC0gMV0ubGVuZ3RoIC0gbGluZXNbbGluZXMubGVuZ3RoIC0gMV0ubWF0Y2goL1xccj9cXG4/LylbMF0ubGVuZ3RoIDpcbiAgICAgICAgICAgICAgICAgICAgICAgICB0aGlzLnl5bGxvYy5sYXN0X2NvbHVtbiArIG1hdGNoWzBdLmxlbmd0aFxuICAgICAgICB9O1xuICAgICAgICB0aGlzLnl5dGV4dCArPSBtYXRjaFswXTtcbiAgICAgICAgdGhpcy5tYXRjaCArPSBtYXRjaFswXTtcbiAgICAgICAgdGhpcy5tYXRjaGVzID0gbWF0Y2g7XG4gICAgICAgIHRoaXMueXlsZW5nID0gdGhpcy55eXRleHQubGVuZ3RoO1xuICAgICAgICBpZiAodGhpcy5vcHRpb25zLnJhbmdlcykge1xuICAgICAgICAgICAgdGhpcy55eWxsb2MucmFuZ2UgPSBbdGhpcy5vZmZzZXQsIHRoaXMub2Zmc2V0ICs9IHRoaXMueXlsZW5nXTtcbiAgICAgICAgfVxuICAgICAgICB0aGlzLl9tb3JlID0gZmFsc2U7XG4gICAgICAgIHRoaXMuX2JhY2t0cmFjayA9IGZhbHNlO1xuICAgICAgICB0aGlzLl9pbnB1dCA9IHRoaXMuX2lucHV0LnNsaWNlKG1hdGNoWzBdLmxlbmd0aCk7XG4gICAgICAgIHRoaXMubWF0Y2hlZCArPSBtYXRjaFswXTtcbiAgICAgICAgdG9rZW4gPSB0aGlzLnBlcmZvcm1BY3Rpb24uY2FsbCh0aGlzLCB0aGlzLnl5LCB0aGlzLCBpbmRleGVkX3J1bGUsIHRoaXMuY29uZGl0aW9uU3RhY2tbdGhpcy5jb25kaXRpb25TdGFjay5sZW5ndGggLSAxXSk7XG4gICAgICAgIGlmICh0aGlzLmRvbmUgJiYgdGhpcy5faW5wdXQpIHtcbiAgICAgICAgICAgIHRoaXMuZG9uZSA9IGZhbHNlO1xuICAgICAgICB9XG4gICAgICAgIGlmICh0b2tlbikge1xuICAgICAgICAgICAgcmV0dXJuIHRva2VuO1xuICAgICAgICB9IGVsc2UgaWYgKHRoaXMuX2JhY2t0cmFjaykge1xuICAgICAgICAgICAgLy8gcmVjb3ZlciBjb250ZXh0XG4gICAgICAgICAgICBmb3IgKHZhciBrIGluIGJhY2t1cCkge1xuICAgICAgICAgICAgICAgIHRoaXNba10gPSBiYWNrdXBba107XG4gICAgICAgICAgICB9XG4gICAgICAgICAgICByZXR1cm4gZmFsc2U7IC8vIHJ1bGUgYWN0aW9uIGNhbGxlZCByZWplY3QoKSBpbXBseWluZyB0aGUgbmV4dCBydWxlIHNob3VsZCBiZSB0ZXN0ZWQgaW5zdGVhZC5cbiAgICAgICAgfVxuICAgICAgICByZXR1cm4gZmFsc2U7XG4gICAgfSxcblxuLy8gcmV0dXJuIG5leHQgbWF0Y2ggaW4gaW5wdXRcbm5leHQ6ZnVuY3Rpb24gKCkge1xuICAgICAgICBpZiAodGhpcy5kb25lKSB7XG4gICAgICAgICAgICByZXR1cm4gdGhpcy5FT0Y7XG4gICAgICAgIH1cbiAgICAgICAgaWYgKCF0aGlzLl9pbnB1dCkge1xuICAgICAgICAgICAgdGhpcy5kb25lID0gdHJ1ZTtcbiAgICAgICAgfVxuXG4gICAgICAgIHZhciB0b2tlbixcbiAgICAgICAgICAgIG1hdGNoLFxuICAgICAgICAgICAgdGVtcE1hdGNoLFxuICAgICAgICAgICAgaW5kZXg7XG4gICAgICAgIGlmICghdGhpcy5fbW9yZSkge1xuICAgICAgICAgICAgdGhpcy55eXRleHQgPSAnJztcbiAgICAgICAgICAgIHRoaXMubWF0Y2ggPSAnJztcbiAgICAgICAgfVxuICAgICAgICB2YXIgcnVsZXMgPSB0aGlzLl9jdXJyZW50UnVsZXMoKTtcbiAgICAgICAgZm9yICh2YXIgaSA9IDA7IGkgPCBydWxlcy5sZW5ndGg7IGkrKykge1xuICAgICAgICAgICAgdGVtcE1hdGNoID0gdGhpcy5faW5wdXQubWF0Y2godGhpcy5ydWxlc1tydWxlc1tpXV0pO1xuICAgICAgICAgICAgaWYgKHRlbXBNYXRjaCAmJiAoIW1hdGNoIHx8IHRlbXBNYXRjaFswXS5sZW5ndGggPiBtYXRjaFswXS5sZW5ndGgpKSB7XG4gICAgICAgICAgICAgICAgbWF0Y2ggPSB0ZW1wTWF0Y2g7XG4gICAgICAgICAgICAgICAgaW5kZXggPSBpO1xuICAgICAgICAgICAgICAgIGlmICh0aGlzLm9wdGlvbnMuYmFja3RyYWNrX2xleGVyKSB7XG4gICAgICAgICAgICAgICAgICAgIHRva2VuID0gdGhpcy50ZXN0X21hdGNoKHRlbXBNYXRjaCwgcnVsZXNbaV0pO1xuICAgICAgICAgICAgICAgICAgICBpZiAodG9rZW4gIT09IGZhbHNlKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICByZXR1cm4gdG9rZW47XG4gICAgICAgICAgICAgICAgICAgIH0gZWxzZSBpZiAodGhpcy5fYmFja3RyYWNrKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICBtYXRjaCA9IGZhbHNlO1xuICAgICAgICAgICAgICAgICAgICAgICAgY29udGludWU7IC8vIHJ1bGUgYWN0aW9uIGNhbGxlZCByZWplY3QoKSBpbXBseWluZyBhIHJ1bGUgTUlTbWF0Y2guXG4gICAgICAgICAgICAgICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICAgICAgICAgICAgICAvLyBlbHNlOiB0aGlzIGlzIGEgbGV4ZXIgcnVsZSB3aGljaCBjb25zdW1lcyBpbnB1dCB3aXRob3V0IHByb2R1Y2luZyBhIHRva2VuIChlLmcuIHdoaXRlc3BhY2UpXG4gICAgICAgICAgICAgICAgICAgICAgICByZXR1cm4gZmFsc2U7XG4gICAgICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICB9IGVsc2UgaWYgKCF0aGlzLm9wdGlvbnMuZmxleCkge1xuICAgICAgICAgICAgICAgICAgICBicmVhaztcbiAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICB9XG4gICAgICAgIH1cbiAgICAgICAgaWYgKG1hdGNoKSB7XG4gICAgICAgICAgICB0b2tlbiA9IHRoaXMudGVzdF9tYXRjaChtYXRjaCwgcnVsZXNbaW5kZXhdKTtcbiAgICAgICAgICAgIGlmICh0b2tlbiAhPT0gZmFsc2UpIHtcbiAgICAgICAgICAgICAgICByZXR1cm4gdG9rZW47XG4gICAgICAgICAgICB9XG4gICAgICAgICAgICAvLyBlbHNlOiB0aGlzIGlzIGEgbGV4ZXIgcnVsZSB3aGljaCBjb25zdW1lcyBpbnB1dCB3aXRob3V0IHByb2R1Y2luZyBhIHRva2VuIChlLmcuIHdoaXRlc3BhY2UpXG4gICAgICAgICAgICByZXR1cm4gZmFsc2U7XG4gICAgICAgIH1cbiAgICAgICAgaWYgKHRoaXMuX2lucHV0ID09PSBcIlwiKSB7XG4gICAgICAgICAgICByZXR1cm4gdGhpcy5FT0Y7XG4gICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICByZXR1cm4gdGhpcy5wYXJzZUVycm9yKCdMZXhpY2FsIGVycm9yIG9uIGxpbmUgJyArICh0aGlzLnl5bGluZW5vICsgMSkgKyAnLiBVbnJlY29nbml6ZWQgdGV4dC5cXG4nICsgdGhpcy5zaG93UG9zaXRpb24oKSwge1xuICAgICAgICAgICAgICAgIHRleHQ6IFwiXCIsXG4gICAgICAgICAgICAgICAgdG9rZW46IG51bGwsXG4gICAgICAgICAgICAgICAgbGluZTogdGhpcy55eWxpbmVub1xuICAgICAgICAgICAgfSk7XG4gICAgICAgIH1cbiAgICB9LFxuXG4vLyByZXR1cm4gbmV4dCBtYXRjaCB0aGF0IGhhcyBhIHRva2VuXG5sZXg6ZnVuY3Rpb24gbGV4ICgpIHtcbiAgICAgICAgdmFyIHIgPSB0aGlzLm5leHQoKTtcbiAgICAgICAgaWYgKHIpIHtcbiAgICAgICAgICAgIHJldHVybiByO1xuICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgcmV0dXJuIHRoaXMubGV4KCk7XG4gICAgICAgIH1cbiAgICB9LFxuXG4vLyBhY3RpdmF0ZXMgYSBuZXcgbGV4ZXIgY29uZGl0aW9uIHN0YXRlIChwdXNoZXMgdGhlIG5ldyBsZXhlciBjb25kaXRpb24gc3RhdGUgb250byB0aGUgY29uZGl0aW9uIHN0YWNrKVxuYmVnaW46ZnVuY3Rpb24gYmVnaW4gKGNvbmRpdGlvbikge1xuICAgICAgICB0aGlzLmNvbmRpdGlvblN0YWNrLnB1c2goY29uZGl0aW9uKTtcbiAgICB9LFxuXG4vLyBwb3AgdGhlIHByZXZpb3VzbHkgYWN0aXZlIGxleGVyIGNvbmRpdGlvbiBzdGF0ZSBvZmYgdGhlIGNvbmRpdGlvbiBzdGFja1xucG9wU3RhdGU6ZnVuY3Rpb24gcG9wU3RhdGUgKCkge1xuICAgICAgICB2YXIgbiA9IHRoaXMuY29uZGl0aW9uU3RhY2subGVuZ3RoIC0gMTtcbiAgICAgICAgaWYgKG4gPiAwKSB7XG4gICAgICAgICAgICByZXR1cm4gdGhpcy5jb25kaXRpb25TdGFjay5wb3AoKTtcbiAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgIHJldHVybiB0aGlzLmNvbmRpdGlvblN0YWNrWzBdO1xuICAgICAgICB9XG4gICAgfSxcblxuLy8gcHJvZHVjZSB0aGUgbGV4ZXIgcnVsZSBzZXQgd2hpY2ggaXMgYWN0aXZlIGZvciB0aGUgY3VycmVudGx5IGFjdGl2ZSBsZXhlciBjb25kaXRpb24gc3RhdGVcbl9jdXJyZW50UnVsZXM6ZnVuY3Rpb24gX2N1cnJlbnRSdWxlcyAoKSB7XG4gICAgICAgIGlmICh0aGlzLmNvbmRpdGlvblN0YWNrLmxlbmd0aCAmJiB0aGlzLmNvbmRpdGlvblN0YWNrW3RoaXMuY29uZGl0aW9uU3RhY2subGVuZ3RoIC0gMV0pIHtcbiAgICAgICAgICAgIHJldHVybiB0aGlzLmNvbmRpdGlvbnNbdGhpcy5jb25kaXRpb25TdGFja1t0aGlzLmNvbmRpdGlvblN0YWNrLmxlbmd0aCAtIDFdXS5ydWxlcztcbiAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgIHJldHVybiB0aGlzLmNvbmRpdGlvbnNbXCJJTklUSUFMXCJdLnJ1bGVzO1xuICAgICAgICB9XG4gICAgfSxcblxuLy8gcmV0dXJuIHRoZSBjdXJyZW50bHkgYWN0aXZlIGxleGVyIGNvbmRpdGlvbiBzdGF0ZTsgd2hlbiBhbiBpbmRleCBhcmd1bWVudCBpcyBwcm92aWRlZCBpdCBwcm9kdWNlcyB0aGUgTi10aCBwcmV2aW91cyBjb25kaXRpb24gc3RhdGUsIGlmIGF2YWlsYWJsZVxudG9wU3RhdGU6ZnVuY3Rpb24gdG9wU3RhdGUgKG4pIHtcbiAgICAgICAgbiA9IHRoaXMuY29uZGl0aW9uU3RhY2subGVuZ3RoIC0gMSAtIE1hdGguYWJzKG4gfHwgMCk7XG4gICAgICAgIGlmIChuID49IDApIHtcbiAgICAgICAgICAgIHJldHVybiB0aGlzLmNvbmRpdGlvblN0YWNrW25dO1xuICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgcmV0dXJuIFwiSU5JVElBTFwiO1xuICAgICAgICB9XG4gICAgfSxcblxuLy8gYWxpYXMgZm9yIGJlZ2luKGNvbmRpdGlvbilcbnB1c2hTdGF0ZTpmdW5jdGlvbiBwdXNoU3RhdGUgKGNvbmRpdGlvbikge1xuICAgICAgICB0aGlzLmJlZ2luKGNvbmRpdGlvbik7XG4gICAgfSxcblxuLy8gcmV0dXJuIHRoZSBudW1iZXIgb2Ygc3RhdGVzIGN1cnJlbnRseSBvbiB0aGUgc3RhY2tcbnN0YXRlU3RhY2tTaXplOmZ1bmN0aW9uIHN0YXRlU3RhY2tTaXplKCkge1xuICAgICAgICByZXR1cm4gdGhpcy5jb25kaXRpb25TdGFjay5sZW5ndGg7XG4gICAgfSxcbm9wdGlvbnM6IHtcImZsZXhcIjp0cnVlLFwiY2FzZS1pbnNlbnNpdGl2ZVwiOnRydWV9LFxucGVyZm9ybUFjdGlvbjogZnVuY3Rpb24gYW5vbnltb3VzKHl5LHl5XywkYXZvaWRpbmdfbmFtZV9jb2xsaXNpb25zLFlZX1NUQVJUKSB7XG52YXIgWVlTVEFURT1ZWV9TVEFSVDtcbnN3aXRjaCgkYXZvaWRpbmdfbmFtZV9jb2xsaXNpb25zKSB7XG5jYXNlIDA6LyogaWdub3JlICovXG5icmVhaztcbmNhc2UgMTpyZXR1cm4gMTJcbmJyZWFrO1xuY2FzZSAyOnJldHVybiAxNVxuYnJlYWs7XG5jYXNlIDM6cmV0dXJuIDI0XG5icmVhaztcbmNhc2UgNDpyZXR1cm4gMjkwXG5icmVhaztcbmNhc2UgNTpyZXR1cm4gMjkxXG5icmVhaztcbmNhc2UgNjpyZXR1cm4gMjlcbmJyZWFrO1xuY2FzZSA3OnJldHVybiAzMVxuYnJlYWs7XG5jYXNlIDg6cmV0dXJuIDMyXG5icmVhaztcbmNhc2UgOTpyZXR1cm4gMjkzXG5icmVhaztcbmNhc2UgMTA6cmV0dXJuIDM0XG5icmVhaztcbmNhc2UgMTE6cmV0dXJuIDM4XG5icmVhaztcbmNhc2UgMTI6cmV0dXJuIDM5XG5icmVhaztcbmNhc2UgMTM6cmV0dXJuIDQxXG5icmVhaztcbmNhc2UgMTQ6cmV0dXJuIDQzXG5icmVhaztcbmNhc2UgMTU6cmV0dXJuIDQ4XG5icmVhaztcbmNhc2UgMTY6cmV0dXJuIDUxXG5icmVhaztcbmNhc2UgMTc6cmV0dXJuIDI5NlxuYnJlYWs7XG5jYXNlIDE4OnJldHVybiA2MVxuYnJlYWs7XG5jYXNlIDE5OnJldHVybiA2MlxuYnJlYWs7XG5jYXNlIDIwOnJldHVybiA2OFxuYnJlYWs7XG5jYXNlIDIxOnJldHVybiA3MVxuYnJlYWs7XG5jYXNlIDIyOnJldHVybiA3NFxuYnJlYWs7XG5jYXNlIDIzOnJldHVybiA3NlxuYnJlYWs7XG5jYXNlIDI0OnJldHVybiA3OVxuYnJlYWs7XG5jYXNlIDI1OnJldHVybiA4MVxuYnJlYWs7XG5jYXNlIDI2OnJldHVybiA4M1xuYnJlYWs7XG5jYXNlIDI3OnJldHVybiAxODNcbmJyZWFrO1xuY2FzZSAyODpyZXR1cm4gOTlcbmJyZWFrO1xuY2FzZSAyOTpyZXR1cm4gMjk3XG5icmVhaztcbmNhc2UgMzA6cmV0dXJuIDEzMlxuYnJlYWs7XG5jYXNlIDMxOnJldHVybiAyOThcbmJyZWFrO1xuY2FzZSAzMjpyZXR1cm4gMjk5XG5icmVhaztcbmNhc2UgMzM6cmV0dXJuIDEwOVxuYnJlYWs7XG5jYXNlIDM0OnJldHVybiAzMDBcbmJyZWFrO1xuY2FzZSAzNTpyZXR1cm4gMTA4XG5icmVhaztcbmNhc2UgMzY6cmV0dXJuIDMwMVxuYnJlYWs7XG5jYXNlIDM3OnJldHVybiAzMDJcbmJyZWFrO1xuY2FzZSAzODpyZXR1cm4gMTEyXG5icmVhaztcbmNhc2UgMzk6cmV0dXJuIDExNFxuYnJlYWs7XG5jYXNlIDQwOnJldHVybiAxMTVcbmJyZWFrO1xuY2FzZSA0MTpyZXR1cm4gMTMwXG5icmVhaztcbmNhc2UgNDI6cmV0dXJuIDEyNFxuYnJlYWs7XG5jYXNlIDQzOnJldHVybiAxMjVcbmJyZWFrO1xuY2FzZSA0NDpyZXR1cm4gMTI3XG5icmVhaztcbmNhc2UgNDU6cmV0dXJuIDEzM1xuYnJlYWs7XG5jYXNlIDQ2OnJldHVybiAxMTFcbmJyZWFrO1xuY2FzZSA0NzpyZXR1cm4gMzAzXG5icmVhaztcbmNhc2UgNDg6cmV0dXJuIDMwNFxuYnJlYWs7XG5jYXNlIDQ5OnJldHVybiAxNTlcbmJyZWFrO1xuY2FzZSA1MDpyZXR1cm4gMTYyXG5icmVhaztcbmNhc2UgNTE6cmV0dXJuIDE2NlxuYnJlYWs7XG5jYXNlIDUyOnJldHVybiA5MlxuYnJlYWs7XG5jYXNlIDUzOnJldHVybiAxNjBcbmJyZWFrO1xuY2FzZSA1NDpyZXR1cm4gMzA1XG5icmVhaztcbmNhc2UgNTU6cmV0dXJuIDE2NVxuYnJlYWs7XG5jYXNlIDU2OnJldHVybiAyNTFcbmJyZWFrO1xuY2FzZSA1NzpyZXR1cm4gMTg3XG5icmVhaztcbmNhc2UgNTg6cmV0dXJuIDMwNlxuYnJlYWs7XG5jYXNlIDU5OnJldHVybiAzMDdcbmJyZWFrO1xuY2FzZSA2MDpyZXR1cm4gMjEzXG5icmVhaztcbmNhc2UgNjE6cmV0dXJuIDMwOVxuYnJlYWs7XG5jYXNlIDYyOnJldHVybiAzMTBcbmJyZWFrO1xuY2FzZSA2MzpyZXR1cm4gMjA4XG5icmVhaztcbmNhc2UgNjQ6cmV0dXJuIDIxNVxuYnJlYWs7XG5jYXNlIDY1OnJldHVybiAyMTZcbmJyZWFrO1xuY2FzZSA2NjpyZXR1cm4gMjIzXG5icmVhaztcbmNhc2UgNjc6cmV0dXJuIDIyN1xuYnJlYWs7XG5jYXNlIDY4OnJldHVybiAyNjhcbmJyZWFrO1xuY2FzZSA2OTpyZXR1cm4gMzExXG5icmVhaztcbmNhc2UgNzA6cmV0dXJuIDMxMlxuYnJlYWs7XG5jYXNlIDcxOnJldHVybiAzMTNcbmJyZWFrO1xuY2FzZSA3MjpyZXR1cm4gMzE0XG5icmVhaztcbmNhc2UgNzM6cmV0dXJuIDMxNVxuYnJlYWs7XG5jYXNlIDc0OnJldHVybiAyMzFcbmJyZWFrO1xuY2FzZSA3NTpyZXR1cm4gMzE2XG5icmVhaztcbmNhc2UgNzY6cmV0dXJuIDI0NlxuYnJlYWs7XG5jYXNlIDc3OnJldHVybiAyNTRcbmJyZWFrO1xuY2FzZSA3ODpyZXR1cm4gMjU1XG5icmVhaztcbmNhc2UgNzk6cmV0dXJuIDI0OFxuYnJlYWs7XG5jYXNlIDgwOnJldHVybiAyNDlcbmJyZWFrO1xuY2FzZSA4MTpyZXR1cm4gMjUwXG5icmVhaztcbmNhc2UgODI6cmV0dXJuIDMxN1xuYnJlYWs7XG5jYXNlIDgzOnJldHVybiAzMThcbmJyZWFrO1xuY2FzZSA4NDpyZXR1cm4gMjUyXG5icmVhaztcbmNhc2UgODU6cmV0dXJuIDMyMFxuYnJlYWs7XG5jYXNlIDg2OnJldHVybiAzMTlcbmJyZWFrO1xuY2FzZSA4NzpyZXR1cm4gMzIxXG5icmVhaztcbmNhc2UgODg6cmV0dXJuIDI1N1xuYnJlYWs7XG5jYXNlIDg5OnJldHVybiAyNThcbmJyZWFrO1xuY2FzZSA5MDpyZXR1cm4gMjYxXG5icmVhaztcbmNhc2UgOTE6cmV0dXJuIDI2M1xuYnJlYWs7XG5jYXNlIDkyOnJldHVybiAyNjdcbmJyZWFrO1xuY2FzZSA5MzpyZXR1cm4gMjcxXG5icmVhaztcbmNhc2UgOTQ6cmV0dXJuIDI3NFxuYnJlYWs7XG5jYXNlIDk1OnJldHVybiAyNzVcbmJyZWFrO1xuY2FzZSA5NjpyZXR1cm4gMTNcbmJyZWFrO1xuY2FzZSA5NzpyZXR1cm4gMTZcbmJyZWFrO1xuY2FzZSA5ODpyZXR1cm4gMjg2XG5icmVhaztcbmNhc2UgOTk6cmV0dXJuIDIxOFxuYnJlYWs7XG5jYXNlIDEwMDpyZXR1cm4gMjhcbmJyZWFrO1xuY2FzZSAxMDE6cmV0dXJuIDI3MFxuYnJlYWs7XG5jYXNlIDEwMjpyZXR1cm4gODBcbmJyZWFrO1xuY2FzZSAxMDM6cmV0dXJuIDI3MlxuYnJlYWs7XG5jYXNlIDEwNDpyZXR1cm4gMjczXG5icmVhaztcbmNhc2UgMTA1OnJldHVybiAyODBcbmJyZWFrO1xuY2FzZSAxMDY6cmV0dXJuIDI4MVxuYnJlYWs7XG5jYXNlIDEwNzpyZXR1cm4gMjgyXG5icmVhaztcbmNhc2UgMTA4OnJldHVybiAyODNcbmJyZWFrO1xuY2FzZSAxMDk6cmV0dXJuIDI4NFxuYnJlYWs7XG5jYXNlIDExMDpyZXR1cm4gMjg1XG5icmVhaztcbmNhc2UgMTExOnJldHVybiAnRVhQT05FTlQnXG5icmVhaztcbmNhc2UgMTEyOnJldHVybiAyNzZcbmJyZWFrO1xuY2FzZSAxMTM6cmV0dXJuIDI3N1xuYnJlYWs7XG5jYXNlIDExNDpyZXR1cm4gMjc4XG5icmVhaztcbmNhc2UgMTE1OnJldHVybiAyNzlcbmJyZWFrO1xuY2FzZSAxMTY6cmV0dXJuIDg2XG5icmVhaztcbmNhc2UgMTE3OnJldHVybiAyMTlcbmJyZWFrO1xuY2FzZSAxMTg6cmV0dXJuIDZcbmJyZWFrO1xuY2FzZSAxMTk6cmV0dXJuICdJTlZBTElEJ1xuYnJlYWs7XG5jYXNlIDEyMDpjb25zb2xlLmxvZyh5eV8ueXl0ZXh0KTtcbmJyZWFrO1xufVxufSxcbnJ1bGVzOiBbL14oPzpcXHMrfCNbXlxcblxccl0qKS9pLC9eKD86QkFTRSkvaSwvXig/OlBSRUZJWCkvaSwvXig/OlNFTEVDVCkvaSwvXig/OkRJU1RJTkNUKS9pLC9eKD86UkVEVUNFRCkvaSwvXig/OlxcKCkvaSwvXig/OkFTKS9pLC9eKD86XFwpKS9pLC9eKD86XFwqKS9pLC9eKD86Q09OU1RSVUNUKS9pLC9eKD86V0hFUkUpL2ksL14oPzpcXHspL2ksL14oPzpcXH0pL2ksL14oPzpERVNDUklCRSkvaSwvXig/OkFTSykvaSwvXig/OkZST00pL2ksL14oPzpOQU1FRCkvaSwvXig/OkdST1VQKS9pLC9eKD86QlkpL2ksL14oPzpIQVZJTkcpL2ksL14oPzpPUkRFUikvaSwvXig/OkFTQykvaSwvXig/OkRFU0MpL2ksL14oPzpMSU1JVCkvaSwvXig/Ok9GRlNFVCkvaSwvXig/OlZBTFVFUykvaSwvXig/OjspL2ksL14oPzpMT0FEKS9pLC9eKD86U0lMRU5UKS9pLC9eKD86SU5UTykvaSwvXig/OkNMRUFSKS9pLC9eKD86RFJPUCkvaSwvXig/OkNSRUFURSkvaSwvXig/OkFERCkvaSwvXig/OlRPKS9pLC9eKD86TU9WRSkvaSwvXig/OkNPUFkpL2ksL14oPzpJTlNFUlRcXHMrREFUQSkvaSwvXig/OkRFTEVURVxccytEQVRBKS9pLC9eKD86REVMRVRFXFxzK1dIRVJFKS9pLC9eKD86V0lUSCkvaSwvXig/OkRFTEVURSkvaSwvXig/OklOU0VSVCkvaSwvXig/OlVTSU5HKS9pLC9eKD86REVGQVVMVCkvaSwvXig/OkdSQVBIKS9pLC9eKD86QUxMKS9pLC9eKD86XFwuKS9pLC9eKD86T1BUSU9OQUwpL2ksL14oPzpTRVJWSUNFKS9pLC9eKD86QklORCkvaSwvXig/OlVOREVGKS9pLC9eKD86TUlOVVMpL2ksL14oPzpVTklPTikvaSwvXig/OkZJTFRFUikvaSwvXig/OiwpL2ksL14oPzphKS9pLC9eKD86XFx8KS9pLC9eKD86XFwvKS9pLC9eKD86XFxeKS9pLC9eKD86XFw/KS9pLC9eKD86XFwrKS9pLC9eKD86ISkvaSwvXig/OlxcWykvaSwvXig/OlxcXSkvaSwvXig/OlxcfFxcfCkvaSwvXig/OiYmKS9pLC9eKD86PSkvaSwvXig/OiE9KS9pLC9eKD86PCkvaSwvXig/Oj4pL2ksL14oPzo8PSkvaSwvXig/Oj49KS9pLC9eKD86SU4pL2ksL14oPzpOT1QpL2ksL14oPzotKS9pLC9eKD86Qk9VTkQpL2ksL14oPzpCTk9ERSkvaSwvXig/OihSQU5EfE5PV3xVVUlEfFNUUlVVSUQpKS9pLC9eKD86KExBTkd8REFUQVRZUEV8SVJJfFVSSXxBQlN8Q0VJTHxGTE9PUnxST1VORHxTVFJMRU58U1RSfFVDQVNFfExDQVNFfEVOQ09ERV9GT1JfVVJJfFlFQVJ8TU9OVEh8REFZfEhPVVJTfE1JTlVURVN8U0VDT05EU3xUSU1FWk9ORXxUWnxNRDV8U0hBMXxTSEEyNTZ8U0hBMzg0fFNIQTUxMnxpc0lSSXxpc1VSSXxpc0JMQU5LfGlzTElURVJBTHxpc05VTUVSSUMpKS9pLC9eKD86KExBTkdNQVRDSEVTfENPTlRBSU5TfFNUUlNUQVJUU3xTVFJFTkRTfFNUUkJFRk9SRXxTVFJBRlRFUnxTVFJMQU5HfFNUUkRUfHNhbWVUZXJtKSkvaSwvXig/OkNPTkNBVCkvaSwvXig/OkNPQUxFU0NFKS9pLC9eKD86SUYpL2ksL14oPzpSRUdFWCkvaSwvXig/OlNVQlNUUikvaSwvXig/OlJFUExBQ0UpL2ksL14oPzpFWElTVFMpL2ksL14oPzpDT1VOVCkvaSwvXig/OlNVTXxNSU58TUFYfEFWR3xTQU1QTEUpL2ksL14oPzpHUk9VUF9DT05DQVQpL2ksL14oPzpTRVBBUkFUT1IpL2ksL14oPzpcXF5cXF4pL2ksL14oPzp0cnVlKS9pLC9eKD86ZmFsc2UpL2ksL14oPzooPChbXjw+XFxcIlxce1xcfVxcfFxcXmBcXFxcXFx1MDAwMC1cXHUwMDIwXSkqPikpL2ksL14oPzooKChbQS1aXXxbYS16XXxbXFx1MDBDMC1cXHUwMEQ2XXxbXFx1MDBEOC1cXHUwMEY2XXxbXFx1MDBGOC1cXHUwMkZGXXxbXFx1MDM3MC1cXHUwMzdEXXxbXFx1MDM3Ri1cXHUxRkZGXXxbXFx1MjAwQy1cXHUyMDBEXXxbXFx1MjA3MC1cXHUyMThGXXxbXFx1MkMwMC1cXHUyRkVGXXxbXFx1MzAwMS1cXHVEN0ZGXXxbXFx1RjkwMC1cXHVGRENGXXxbXFx1RkRGMC1cXHVGRkZEXXxbXFx1RDgwMC1cXHVEQjdGXVtcXHVEQzAwLVxcdURGRkZdKSgoKCgoPzooW0EtWl18W2Etel18W1xcdTAwQzAtXFx1MDBENl18W1xcdTAwRDgtXFx1MDBGNl18W1xcdTAwRjgtXFx1MDJGRl18W1xcdTAzNzAtXFx1MDM3RF18W1xcdTAzN0YtXFx1MUZGRl18W1xcdTIwMEMtXFx1MjAwRF18W1xcdTIwNzAtXFx1MjE4Rl18W1xcdTJDMDAtXFx1MkZFRl18W1xcdTMwMDEtXFx1RDdGRl18W1xcdUY5MDAtXFx1RkRDRl18W1xcdUZERjAtXFx1RkZGRF18W1xcdUQ4MDAtXFx1REI3Rl1bXFx1REMwMC1cXHVERkZGXSl8XykpfC18WzAtOV18XFx1MDBCN3xbXFx1MDMwMC1cXHUwMzZGXXxbXFx1MjAzRi1cXHUyMDQwXSl8XFwuKSooKCg/OihbQS1aXXxbYS16XXxbXFx1MDBDMC1cXHUwMEQ2XXxbXFx1MDBEOC1cXHUwMEY2XXxbXFx1MDBGOC1cXHUwMkZGXXxbXFx1MDM3MC1cXHUwMzdEXXxbXFx1MDM3Ri1cXHUxRkZGXXxbXFx1MjAwQy1cXHUyMDBEXXxbXFx1MjA3MC1cXHUyMThGXXxbXFx1MkMwMC1cXHUyRkVGXXxbXFx1MzAwMS1cXHVEN0ZGXXxbXFx1RjkwMC1cXHVGRENGXXxbXFx1RkRGMC1cXHVGRkZEXXxbXFx1RDgwMC1cXHVEQjdGXVtcXHVEQzAwLVxcdURGRkZdKXxfKSl8LXxbMC05XXxcXHUwMEI3fFtcXHUwMzAwLVxcdTAzNkZdfFtcXHUyMDNGLVxcdTIwNDBdKSk/KT86KSkvaSwvXig/OigoKChbQS1aXXxbYS16XXxbXFx1MDBDMC1cXHUwMEQ2XXxbXFx1MDBEOC1cXHUwMEY2XXxbXFx1MDBGOC1cXHUwMkZGXXxbXFx1MDM3MC1cXHUwMzdEXXxbXFx1MDM3Ri1cXHUxRkZGXXxbXFx1MjAwQy1cXHUyMDBEXXxbXFx1MjA3MC1cXHUyMThGXXxbXFx1MkMwMC1cXHUyRkVGXXxbXFx1MzAwMS1cXHVEN0ZGXXxbXFx1RjkwMC1cXHVGRENGXXxbXFx1RkRGMC1cXHVGRkZEXXxbXFx1RDgwMC1cXHVEQjdGXVtcXHVEQzAwLVxcdURGRkZdKSgoKCgoPzooW0EtWl18W2Etel18W1xcdTAwQzAtXFx1MDBENl18W1xcdTAwRDgtXFx1MDBGNl18W1xcdTAwRjgtXFx1MDJGRl18W1xcdTAzNzAtXFx1MDM3RF18W1xcdTAzN0YtXFx1MUZGRl18W1xcdTIwMEMtXFx1MjAwRF18W1xcdTIwNzAtXFx1MjE4Rl18W1xcdTJDMDAtXFx1MkZFRl18W1xcdTMwMDEtXFx1RDdGRl18W1xcdUY5MDAtXFx1RkRDRl18W1xcdUZERjAtXFx1RkZGRF18W1xcdUQ4MDAtXFx1REI3Rl1bXFx1REMwMC1cXHVERkZGXSl8XykpfC18WzAtOV18XFx1MDBCN3xbXFx1MDMwMC1cXHUwMzZGXXxbXFx1MjAzRi1cXHUyMDQwXSl8XFwuKSooKCg/OihbQS1aXXxbYS16XXxbXFx1MDBDMC1cXHUwMEQ2XXxbXFx1MDBEOC1cXHUwMEY2XXxbXFx1MDBGOC1cXHUwMkZGXXxbXFx1MDM3MC1cXHUwMzdEXXxbXFx1MDM3Ri1cXHUxRkZGXXxbXFx1MjAwQy1cXHUyMDBEXXxbXFx1MjA3MC1cXHUyMThGXXxbXFx1MkMwMC1cXHUyRkVGXXxbXFx1MzAwMS1cXHVEN0ZGXXxbXFx1RjkwMC1cXHVGRENGXXxbXFx1RkRGMC1cXHVGRkZEXXxbXFx1RDgwMC1cXHVEQjdGXVtcXHVEQzAwLVxcdURGRkZdKXxfKSl8LXxbMC05XXxcXHUwMEI3fFtcXHUwMzAwLVxcdTAzNkZdfFtcXHUyMDNGLVxcdTIwNDBdKSk/KT86KSgoKCg/OihbQS1aXXxbYS16XXxbXFx1MDBDMC1cXHUwMEQ2XXxbXFx1MDBEOC1cXHUwMEY2XXxbXFx1MDBGOC1cXHUwMkZGXXxbXFx1MDM3MC1cXHUwMzdEXXxbXFx1MDM3Ri1cXHUxRkZGXXxbXFx1MjAwQy1cXHUyMDBEXXxbXFx1MjA3MC1cXHUyMThGXXxbXFx1MkMwMC1cXHUyRkVGXXxbXFx1MzAwMS1cXHVEN0ZGXXxbXFx1RjkwMC1cXHVGRENGXXxbXFx1RkRGMC1cXHVGRkZEXXxbXFx1RDgwMC1cXHVEQjdGXVtcXHVEQzAwLVxcdURGRkZdKXxfKSl8OnxbMC05XXwoKCUoWzAtOV18W0EtRl18W2EtZl0pKFswLTldfFtBLUZdfFthLWZdKSl8KFxcXFwoX3x+fFxcLnwtfCF8XFwkfCZ8J3xcXCh8XFwpfFxcKnxcXCt8LHw7fD18XFwvfFxcP3wjfEB8JSkpKSkoKCgoKD86KFtBLVpdfFthLXpdfFtcXHUwMEMwLVxcdTAwRDZdfFtcXHUwMEQ4LVxcdTAwRjZdfFtcXHUwMEY4LVxcdTAyRkZdfFtcXHUwMzcwLVxcdTAzN0RdfFtcXHUwMzdGLVxcdTFGRkZdfFtcXHUyMDBDLVxcdTIwMERdfFtcXHUyMDcwLVxcdTIxOEZdfFtcXHUyQzAwLVxcdTJGRUZdfFtcXHUzMDAxLVxcdUQ3RkZdfFtcXHVGOTAwLVxcdUZEQ0ZdfFtcXHVGREYwLVxcdUZGRkRdfFtcXHVEODAwLVxcdURCN0ZdW1xcdURDMDAtXFx1REZGRl0pfF8pKXwtfFswLTldfFxcdTAwQjd8W1xcdTAzMDAtXFx1MDM2Rl18W1xcdTIwM0YtXFx1MjA0MF0pfFxcLnw6fCgoJShbMC05XXxbQS1GXXxbYS1mXSkoWzAtOV18W0EtRl18W2EtZl0pKXwoXFxcXChffH58XFwufC18IXxcXCR8JnwnfFxcKHxcXCl8XFwqfFxcK3wsfDt8PXxcXC98XFw/fCN8QHwlKSkpKSooKCgoPzooW0EtWl18W2Etel18W1xcdTAwQzAtXFx1MDBENl18W1xcdTAwRDgtXFx1MDBGNl18W1xcdTAwRjgtXFx1MDJGRl18W1xcdTAzNzAtXFx1MDM3RF18W1xcdTAzN0YtXFx1MUZGRl18W1xcdTIwMEMtXFx1MjAwRF18W1xcdTIwNzAtXFx1MjE4Rl18W1xcdTJDMDAtXFx1MkZFRl18W1xcdTMwMDEtXFx1RDdGRl18W1xcdUY5MDAtXFx1RkRDRl18W1xcdUZERjAtXFx1RkZGRF18W1xcdUQ4MDAtXFx1REI3Rl1bXFx1REMwMC1cXHVERkZGXSl8XykpfC18WzAtOV18XFx1MDBCN3xbXFx1MDMwMC1cXHUwMzZGXXxbXFx1MjAzRi1cXHUyMDQwXSl8OnwoKCUoWzAtOV18W0EtRl18W2EtZl0pKFswLTldfFtBLUZdfFthLWZdKSl8KFxcXFwoX3x+fFxcLnwtfCF8XFwkfCZ8J3xcXCh8XFwpfFxcKnxcXCt8LHw7fD18XFwvfFxcP3wjfEB8JSkpKSkpPykpKS9pLC9eKD86KF86KCgoPzooW0EtWl18W2Etel18W1xcdTAwQzAtXFx1MDBENl18W1xcdTAwRDgtXFx1MDBGNl18W1xcdTAwRjgtXFx1MDJGRl18W1xcdTAzNzAtXFx1MDM3RF18W1xcdTAzN0YtXFx1MUZGRl18W1xcdTIwMEMtXFx1MjAwRF18W1xcdTIwNzAtXFx1MjE4Rl18W1xcdTJDMDAtXFx1MkZFRl18W1xcdTMwMDEtXFx1RDdGRl18W1xcdUY5MDAtXFx1RkRDRl18W1xcdUZERjAtXFx1RkZGRF18W1xcdUQ4MDAtXFx1REI3Rl1bXFx1REMwMC1cXHVERkZGXSl8XykpfFswLTldKSgoKCgoPzooW0EtWl18W2Etel18W1xcdTAwQzAtXFx1MDBENl18W1xcdTAwRDgtXFx1MDBGNl18W1xcdTAwRjgtXFx1MDJGRl18W1xcdTAzNzAtXFx1MDM3RF18W1xcdTAzN0YtXFx1MUZGRl18W1xcdTIwMEMtXFx1MjAwRF18W1xcdTIwNzAtXFx1MjE4Rl18W1xcdTJDMDAtXFx1MkZFRl18W1xcdTMwMDEtXFx1RDdGRl18W1xcdUY5MDAtXFx1RkRDRl18W1xcdUZERjAtXFx1RkZGRF18W1xcdUQ4MDAtXFx1REI3Rl1bXFx1REMwMC1cXHVERkZGXSl8XykpfC18WzAtOV18XFx1MDBCN3xbXFx1MDMwMC1cXHUwMzZGXXxbXFx1MjAzRi1cXHUyMDQwXSl8XFwuKSooKCg/OihbQS1aXXxbYS16XXxbXFx1MDBDMC1cXHUwMEQ2XXxbXFx1MDBEOC1cXHUwMEY2XXxbXFx1MDBGOC1cXHUwMkZGXXxbXFx1MDM3MC1cXHUwMzdEXXxbXFx1MDM3Ri1cXHUxRkZGXXxbXFx1MjAwQy1cXHUyMDBEXXxbXFx1MjA3MC1cXHUyMThGXXxbXFx1MkMwMC1cXHUyRkVGXXxbXFx1MzAwMS1cXHVEN0ZGXXxbXFx1RjkwMC1cXHVGRENGXXxbXFx1RkRGMC1cXHVGRkZEXXxbXFx1RDgwMC1cXHVEQjdGXVtcXHVEQzAwLVxcdURGRkZdKXxfKSl8LXxbMC05XXxcXHUwMEI3fFtcXHUwMzAwLVxcdTAzNkZdfFtcXHUyMDNGLVxcdTIwNDBdKSk/KSkvaSwvXig/OihbXFw/XFwkXSgoKCg/OihbQS1aXXxbYS16XXxbXFx1MDBDMC1cXHUwMEQ2XXxbXFx1MDBEOC1cXHUwMEY2XXxbXFx1MDBGOC1cXHUwMkZGXXxbXFx1MDM3MC1cXHUwMzdEXXxbXFx1MDM3Ri1cXHUxRkZGXXxbXFx1MjAwQy1cXHUyMDBEXXxbXFx1MjA3MC1cXHUyMThGXXxbXFx1MkMwMC1cXHUyRkVGXXxbXFx1MzAwMS1cXHVEN0ZGXXxbXFx1RjkwMC1cXHVGRENGXXxbXFx1RkRGMC1cXHVGRkZEXXxbXFx1RDgwMC1cXHVEQjdGXVtcXHVEQzAwLVxcdURGRkZdKXxfKSl8WzAtOV0pKCgoPzooW0EtWl18W2Etel18W1xcdTAwQzAtXFx1MDBENl18W1xcdTAwRDgtXFx1MDBGNl18W1xcdTAwRjgtXFx1MDJGRl18W1xcdTAzNzAtXFx1MDM3RF18W1xcdTAzN0YtXFx1MUZGRl18W1xcdTIwMEMtXFx1MjAwRF18W1xcdTIwNzAtXFx1MjE4Rl18W1xcdTJDMDAtXFx1MkZFRl18W1xcdTMwMDEtXFx1RDdGRl18W1xcdUY5MDAtXFx1RkRDRl18W1xcdUZERjAtXFx1RkZGRF18W1xcdUQ4MDAtXFx1REI3Rl1bXFx1REMwMC1cXHVERkZGXSl8XykpfFswLTldfFxcdTAwQjd8W1xcdTAzMDAtXFx1MDM2Rl18W1xcdTIwM0YtXFx1MjA0MF0pKikpKS9pLC9eKD86KEBbYS16QS1aXSsoLVthLXpBLVowLTldKykqKSkvaSwvXig/OihbMC05XSspKS9pLC9eKD86KFswLTldKlxcLlswLTldKykpL2ksL14oPzooWzAtOV0rXFwuWzAtOV0qKFtlRV1bKy1dP1swLTldKyl8XFwuKFswLTldKSsoW2VFXVsrLV0/WzAtOV0rKXwoWzAtOV0pKyhbZUVdWystXT9bMC05XSspKSkvaSwvXig/OihcXCsoWzAtOV0rKSkpL2ksL14oPzooXFwrKFswLTldKlxcLlswLTldKykpKS9pLC9eKD86KFxcKyhbMC05XStcXC5bMC05XSooW2VFXVsrLV0/WzAtOV0rKXxcXC4oWzAtOV0pKyhbZUVdWystXT9bMC05XSspfChbMC05XSkrKFtlRV1bKy1dP1swLTldKykpKSkvaSwvXig/OigtKFswLTldKykpKS9pLC9eKD86KC0oWzAtOV0qXFwuWzAtOV0rKSkpL2ksL14oPzooLShbMC05XStcXC5bMC05XSooW2VFXVsrLV0/WzAtOV0rKXxcXC4oWzAtOV0pKyhbZUVdWystXT9bMC05XSspfChbMC05XSkrKFtlRV1bKy1dP1swLTldKykpKSkvaSwvXig/OihbZUVdWystXT9bMC05XSspKS9pLC9eKD86KCcoKFteXFx1MDAyN1xcdTAwNUNcXHUwMDBBXFx1MDAwRF0pfChcXFxcW3RibnJmXFxcXFxcXCInXXxcXFxcdShbMC05XXxbQS1GXXxbYS1mXSkoWzAtOV18W0EtRl18W2EtZl0pKFswLTldfFtBLUZdfFthLWZdKShbMC05XXxbQS1GXXxbYS1mXSl8XFxcXFUoWzAtOV18W0EtRl18W2EtZl0pKFswLTldfFtBLUZdfFthLWZdKShbMC05XXxbQS1GXXxbYS1mXSkoWzAtOV18W0EtRl18W2EtZl0pKFswLTldfFtBLUZdfFthLWZdKShbMC05XXxbQS1GXXxbYS1mXSkoWzAtOV18W0EtRl18W2EtZl0pKFswLTldfFtBLUZdfFthLWZdKSkpKicpKS9pLC9eKD86KFwiKChbXlxcdTAwMjJcXHUwMDVDXFx1MDAwQVxcdTAwMERdKXwoXFxcXFt0Ym5yZlxcXFxcXFwiJ118XFxcXHUoWzAtOV18W0EtRl18W2EtZl0pKFswLTldfFtBLUZdfFthLWZdKShbMC05XXxbQS1GXXxbYS1mXSkoWzAtOV18W0EtRl18W2EtZl0pfFxcXFxVKFswLTldfFtBLUZdfFthLWZdKShbMC05XXxbQS1GXXxbYS1mXSkoWzAtOV18W0EtRl18W2EtZl0pKFswLTldfFtBLUZdfFthLWZdKShbMC05XXxbQS1GXXxbYS1mXSkoWzAtOV18W0EtRl18W2EtZl0pKFswLTldfFtBLUZdfFthLWZdKShbMC05XXxbQS1GXXxbYS1mXSkpKSpcIikpL2ksL14oPzooJycnKCgnfCcnKT8oW14nXFxcXF18KFxcXFxbdGJucmZcXFxcXFxcIiddfFxcXFx1KFswLTldfFtBLUZdfFthLWZdKShbMC05XXxbQS1GXXxbYS1mXSkoWzAtOV18W0EtRl18W2EtZl0pKFswLTldfFtBLUZdfFthLWZdKXxcXFxcVShbMC05XXxbQS1GXXxbYS1mXSkoWzAtOV18W0EtRl18W2EtZl0pKFswLTldfFtBLUZdfFthLWZdKShbMC05XXxbQS1GXXxbYS1mXSkoWzAtOV18W0EtRl18W2EtZl0pKFswLTldfFtBLUZdfFthLWZdKShbMC05XXxbQS1GXXxbYS1mXSkoWzAtOV18W0EtRl18W2EtZl0pKSkpKicnJykpL2ksL14oPzooXCJcIlwiKChcInxcIlwiKT8oW15cXFwiXFxcXF18KFxcXFxbdGJucmZcXFxcXFxcIiddfFxcXFx1KFswLTldfFtBLUZdfFthLWZdKShbMC05XXxbQS1GXXxbYS1mXSkoWzAtOV18W0EtRl18W2EtZl0pKFswLTldfFtBLUZdfFthLWZdKXxcXFxcVShbMC05XXxbQS1GXXxbYS1mXSkoWzAtOV18W0EtRl18W2EtZl0pKFswLTldfFtBLUZdfFthLWZdKShbMC05XXxbQS1GXXxbYS1mXSkoWzAtOV18W0EtRl18W2EtZl0pKFswLTldfFtBLUZdfFthLWZdKShbMC05XXxbQS1GXXxbYS1mXSkoWzAtOV18W0EtRl18W2EtZl0pKSkpKlwiXCJcIikpL2ksL14oPzooXFwoKFxcdTAwMjB8XFx1MDAwOXxcXHUwMDBEfFxcdTAwMEEpKlxcKSkpL2ksL14oPzooXFxbKFxcdTAwMjB8XFx1MDAwOXxcXHUwMDBEfFxcdTAwMEEpKlxcXSkpL2ksL14oPzokKS9pLC9eKD86LikvaSwvXig/Oi4pL2ldLFxuY29uZGl0aW9uczoge1wiSU5JVElBTFwiOntcInJ1bGVzXCI6WzAsMSwyLDMsNCw1LDYsNyw4LDksMTAsMTEsMTIsMTMsMTQsMTUsMTYsMTcsMTgsMTksMjAsMjEsMjIsMjMsMjQsMjUsMjYsMjcsMjgsMjksMzAsMzEsMzIsMzMsMzQsMzUsMzYsMzcsMzgsMzksNDAsNDEsNDIsNDMsNDQsNDUsNDYsNDcsNDgsNDksNTAsNTEsNTIsNTMsNTQsNTUsNTYsNTcsNTgsNTksNjAsNjEsNjIsNjMsNjQsNjUsNjYsNjcsNjgsNjksNzAsNzEsNzIsNzMsNzQsNzUsNzYsNzcsNzgsNzksODAsODEsODIsODMsODQsODUsODYsODcsODgsODksOTAsOTEsOTIsOTMsOTQsOTUsOTYsOTcsOTgsOTksMTAwLDEwMSwxMDIsMTAzLDEwNCwxMDUsMTA2LDEwNywxMDgsMTA5LDExMCwxMTEsMTEyLDExMywxMTQsMTE1LDExNiwxMTcsMTE4LDExOSwxMjBdLFwiaW5jbHVzaXZlXCI6dHJ1ZX19XG59KTtcbnJldHVybiBsZXhlcjtcbn0pKCk7XG5wYXJzZXIubGV4ZXIgPSBsZXhlcjtcbmZ1bmN0aW9uIFBhcnNlciAoKSB7XG4gIHRoaXMueXkgPSB7fTtcbn1cblBhcnNlci5wcm90b3R5cGUgPSBwYXJzZXI7cGFyc2VyLlBhcnNlciA9IFBhcnNlcjtcbnJldHVybiBuZXcgUGFyc2VyO1xufSkoKTtcblxuXG5pZiAodHlwZW9mIHJlcXVpcmUgIT09ICd1bmRlZmluZWQnICYmIHR5cGVvZiBleHBvcnRzICE9PSAndW5kZWZpbmVkJykge1xuZXhwb3J0cy5wYXJzZXIgPSBTcGFycWxQYXJzZXI7XG5leHBvcnRzLlBhcnNlciA9IFNwYXJxbFBhcnNlci5QYXJzZXI7XG5leHBvcnRzLnBhcnNlID0gZnVuY3Rpb24gKCkgeyByZXR1cm4gU3BhcnFsUGFyc2VyLnBhcnNlLmFwcGx5KFNwYXJxbFBhcnNlciwgYXJndW1lbnRzKTsgfTtcbmV4cG9ydHMubWFpbiA9IGZ1bmN0aW9uIGNvbW1vbmpzTWFpbiAoYXJncykge1xuICAgIGlmICghYXJnc1sxXSkge1xuICAgICAgICBjb25zb2xlLmxvZygnVXNhZ2U6ICcrYXJnc1swXSsnIEZJTEUnKTtcbiAgICAgICAgcHJvY2Vzcy5leGl0KDEpO1xuICAgIH1cbiAgICB2YXIgc291cmNlID0gcmVxdWlyZSgnZnMnKS5yZWFkRmlsZVN5bmMocmVxdWlyZSgncGF0aCcpLm5vcm1hbGl6ZShhcmdzWzFdKSwgXCJ1dGY4XCIpO1xuICAgIHJldHVybiBleHBvcnRzLnBhcnNlci5wYXJzZShzb3VyY2UpO1xufTtcbmlmICh0eXBlb2YgbW9kdWxlICE9PSAndW5kZWZpbmVkJyAmJiByZXF1aXJlLm1haW4gPT09IG1vZHVsZSkge1xuICBleHBvcnRzLm1haW4ocHJvY2Vzcy5hcmd2LnNsaWNlKDEpKTtcbn1cbn0iLCJ2YXIgUGFyc2VyID0gcmVxdWlyZSgnLi9saWIvU3BhcnFsUGFyc2VyJykuUGFyc2VyO1xudmFyIEdlbmVyYXRvciA9IHJlcXVpcmUoJy4vbGliL1NwYXJxbEdlbmVyYXRvcicpO1xuXG5tb2R1bGUuZXhwb3J0cyA9IHtcbiAgLyoqXG4gICAqIENyZWF0ZXMgYSBTUEFSUUwgcGFyc2VyIHdpdGggdGhlIGdpdmVuIHByZS1kZWZpbmVkIHByZWZpeGVzIGFuZCBiYXNlIElSSVxuICAgKiBAcGFyYW0gcHJlZml4ZXMgeyBbcHJlZml4OiBzdHJpbmddOiBzdHJpbmcgfVxuICAgKiBAcGFyYW0gYmFzZUlSSSBzdHJpbmdcbiAgICovXG4gIFBhcnNlcjogZnVuY3Rpb24gKHByZWZpeGVzLCBiYXNlSVJJKSB7XG4gICAgLy8gQ3JlYXRlIGEgY29weSBvZiB0aGUgcHJlZml4ZXNcbiAgICB2YXIgcHJlZml4ZXNDb3B5ID0ge307XG4gICAgZm9yICh2YXIgcHJlZml4IGluIHByZWZpeGVzIHx8IHt9KVxuICAgICAgcHJlZml4ZXNDb3B5W3ByZWZpeF0gPSBwcmVmaXhlc1twcmVmaXhdO1xuXG4gICAgLy8gQ3JlYXRlIGEgbmV3IHBhcnNlciB3aXRoIHRoZSBnaXZlbiBwcmVmaXhlc1xuICAgIC8vIChXb3JrYXJvdW5kIGZvciBodHRwczovL2dpdGh1Yi5jb20vemFhY2gvamlzb24vaXNzdWVzLzI0MSlcbiAgICB2YXIgcGFyc2VyID0gbmV3IFBhcnNlcigpO1xuICAgIHBhcnNlci5wYXJzZSA9IGZ1bmN0aW9uICgpIHtcbiAgICAgIFBhcnNlci5iYXNlID0gYmFzZUlSSSB8fCAnJztcbiAgICAgIFBhcnNlci5wcmVmaXhlcyA9IE9iamVjdC5jcmVhdGUocHJlZml4ZXNDb3B5KTtcbiAgICAgIHJldHVybiBQYXJzZXIucHJvdG90eXBlLnBhcnNlLmFwcGx5KHBhcnNlciwgYXJndW1lbnRzKTtcbiAgICB9O1xuICAgIHBhcnNlci5fcmVzZXRCbGFua3MgPSBQYXJzZXIuX3Jlc2V0QmxhbmtzO1xuICAgIHJldHVybiBwYXJzZXI7XG4gIH0sXG4gIEdlbmVyYXRvcjogR2VuZXJhdG9yLFxufTtcbiIsImltcG9ydCB7IFBhcnNlciwgRGVzY3JpYmVRdWVyeSwgVmFyaWFibGUsIFZhcmlhYmxlRXhwcmVzc2lvbiwgVGVybSB9IGZyb20gJ3NwYXJxbGpzJztcbmltcG9ydCB7IFF1ZXJ5QnVpbGRlciB9IGZyb20gJy4vUXVlcnlCdWlsZGVyJztcblxuZXhwb3J0IGNsYXNzIERlc2NyaWJlQnVpbGRlciBleHRlbmRzIFF1ZXJ5QnVpbGRlclxue1xuXG4gICAgY29uc3RydWN0b3IoZGVzY3JpYmU6IERlc2NyaWJlUXVlcnkpXG4gICAge1xuICAgICAgICBzdXBlcihkZXNjcmliZSk7XG4gICAgfVxuXG4gICAgcHVibGljIHN0YXRpYyBmcm9tU3RyaW5nKHF1ZXJ5U3RyaW5nOiBzdHJpbmcsIHByZWZpeGVzPzogeyBbcHJlZml4OiBzdHJpbmddOiBzdHJpbmc7IH0gfCB1bmRlZmluZWQsIGJhc2VJUkk/OiBzdHJpbmcgfCB1bmRlZmluZWQpOiBEZXNjcmliZUJ1aWxkZXJcbiAgICB7XG4gICAgICAgIGxldCBxdWVyeSA9IG5ldyBQYXJzZXIocHJlZml4ZXMsIGJhc2VJUkkpLnBhcnNlKHF1ZXJ5U3RyaW5nKTtcbiAgICAgICAgaWYgKCE8RGVzY3JpYmVRdWVyeT5xdWVyeSkgdGhyb3cgbmV3IEVycm9yKFwiT25seSBERVNDSUJFIGlzIHN1cHBvcnRlZFwiKTtcblxuICAgICAgICByZXR1cm4gbmV3IERlc2NyaWJlQnVpbGRlcig8RGVzY3JpYmVRdWVyeT5xdWVyeSk7XG4gICAgfVxuXG4gICAgcHVibGljIHN0YXRpYyBuZXcoKTogRGVzY3JpYmVCdWlsZGVyXG4gICAge1xuICAgICAgICByZXR1cm4gbmV3IERlc2NyaWJlQnVpbGRlcih7XG4gICAgICAgICAgXCJxdWVyeVR5cGVcIjogXCJERVNDUklCRVwiLFxuICAgICAgICAgIFwidmFyaWFibGVzXCI6IFtcbiAgICAgICAgICAgIFwiKlwiXG4gICAgICAgICAgXSxcbiAgICAgICAgICBcInR5cGVcIjogXCJxdWVyeVwiLFxuICAgICAgICAgIFwicHJlZml4ZXNcIjoge31cbiAgICAgICAgfSk7XG4gICAgfVxuXG4gICAgcHVibGljIHByb2plY3RBbGwoKTogRGVzY3JpYmVCdWlsZGVyXG4gICAge1xuICAgICAgICB0aGlzLmdldFF1ZXJ5KCkudmFyaWFibGVzID0gWyBcIipcIiBdO1xuXG4gICAgICAgIHJldHVybiB0aGlzO1xuICAgIH1cblxuICAgIHB1YmxpYyBwcm9qZWN0aW9uKHZhcmlhYmxlczogVmFyaWFibGVbXSk6IERlc2NyaWJlQnVpbGRlclxuICAgIHtcbiAgICAgICAgdGhpcy5nZXRRdWVyeSgpLnZhcmlhYmxlcyA9IHZhcmlhYmxlcztcblxuICAgICAgICByZXR1cm4gdGhpcztcbiAgICB9XG5cbiAgICBwdWJsaWMgcHJvamVjdCh0ZXJtOiBUZXJtKTogRGVzY3JpYmVCdWlsZGVyXG4gICAge1xuICAgICAgICB0aGlzLmdldFF1ZXJ5KCkudmFyaWFibGVzLnB1c2goPFRlcm0gJiBcIipcIj50ZXJtKTtcblxuICAgICAgICByZXR1cm4gdGhpcztcbiAgICB9XG5cbiAgICBwdWJsaWMgaXNQcm9qZWN0ZWQodGVybTogVGVybSk6IGJvb2xlYW5cbiAgICB7XG4gICAgICAgIHJldHVybiB0aGlzLmdldFF1ZXJ5KCkudmFyaWFibGVzLmluY2x1ZGVzKDxUZXJtICYgXCIqXCI+dGVybSk7XG4gICAgfVxuXG4gICAgcHJvdGVjdGVkIGdldFF1ZXJ5KCk6IERlc2NyaWJlUXVlcnlcbiAgICB7XG4gICAgICAgIHJldHVybiA8RGVzY3JpYmVRdWVyeT5zdXBlci5nZXRRdWVyeSgpO1xuICAgIH1cblxuICAgIHB1YmxpYyBidWlsZCgpOiBEZXNjcmliZVF1ZXJ5XG4gICAge1xuICAgICAgICByZXR1cm4gPERlc2NyaWJlUXVlcnk+c3VwZXIuYnVpbGQoKTtcbiAgICB9XG5cbn0iLCJpbXBvcnQgeyBQYXJzZXIsIFF1ZXJ5LCBCYXNlUXVlcnksIFBhdHRlcm4sIEV4cHJlc3Npb24sIEZpbHRlclBhdHRlcm4sIEJncFBhdHRlcm4sIEdyYXBoUGF0dGVybiwgR3JvdXBQYXR0ZXJuLCBPcGVyYXRpb25FeHByZXNzaW9uLCBUcmlwbGUsIFRlcm0sIFByb3BlcnR5UGF0aCwgR2VuZXJhdG9yLCBTcGFycWxHZW5lcmF0b3IgfSBmcm9tICdzcGFycWxqcyc7XG5cbmV4cG9ydCBjbGFzcyBRdWVyeUJ1aWxkZXJcbntcblxuICAgIHByaXZhdGUgcmVhZG9ubHkgcXVlcnk6IFF1ZXJ5O1xuICAgIHByaXZhdGUgcmVhZG9ubHkgZ2VuZXJhdG9yOiBTcGFycWxHZW5lcmF0b3I7XG5cbiAgICBjb25zdHJ1Y3RvcihxdWVyeTogUXVlcnkpXG4gICAge1xuICAgICAgICB0aGlzLnF1ZXJ5ID0gcXVlcnk7XG4gICAgICAgIHRoaXMuZ2VuZXJhdG9yID0gbmV3IEdlbmVyYXRvcigpO1xuICAgICAgICBpZiAoIXRoaXMucXVlcnkucHJlZml4ZXMpIHRoaXMucXVlcnkucHJlZml4ZXMgPSB7fTtcbiAgICB9XG5cbiAgICBwdWJsaWMgc3RhdGljIGZyb21TdHJpbmcocXVlcnlTdHJpbmc6IHN0cmluZywgcHJlZml4ZXM/OiB7IFtwcmVmaXg6IHN0cmluZ106IHN0cmluZzsgfSB8IHVuZGVmaW5lZCwgYmFzZUlSST86IHN0cmluZyB8IHVuZGVmaW5lZCk6IFF1ZXJ5QnVpbGRlclxuICAgIHtcbiAgICAgICAgbGV0IHF1ZXJ5ID0gbmV3IFBhcnNlcihwcmVmaXhlcywgYmFzZUlSSSkucGFyc2UocXVlcnlTdHJpbmcpO1xuICAgICAgICBpZiAoITxRdWVyeT5xdWVyeSkgdGhyb3cgbmV3IEVycm9yKFwiT25seSBTUEFSUUwgcXVlcmllcyBhcmUgc3VwcG9ydGVkLCBub3QgdXBkYXRlc1wiKTtcblxuICAgICAgICByZXR1cm4gbmV3IFF1ZXJ5QnVpbGRlcig8UXVlcnk+cXVlcnkpO1xuICAgIH1cblxuICAgIHB1YmxpYyB3aGVyZShwYXR0ZXJuOiBQYXR0ZXJuKTogUXVlcnlCdWlsZGVyXG4gICAge1xuICAgICAgICBpZiAoIXRoaXMuZ2V0UXVlcnkoKS53aGVyZSkgdGhpcy5nZXRRdWVyeSgpLndoZXJlID0gW107XG4gICAgICAgIHRoaXMuZ2V0UXVlcnkoKS53aGVyZSEucHVzaChwYXR0ZXJuKTtcblxuICAgICAgICByZXR1cm4gdGhpcztcbiAgICB9XG5cbiAgICBwdWJsaWMgYmdwVHJpcGxlcyh0cmlwbGVzOiBUcmlwbGVbXSk6IFF1ZXJ5QnVpbGRlclxuICAgIHtcbiAgICAgICAgLy8gaWYgdGhlIGxhc3QgcGF0dGVybiBpcyBCR1AsIGFwcGVuZCB0cmlwbGVzIHRvIGl0IGluc3RlYWQgb2YgYWRkaW5nIG5ldyBCR1BcbiAgICAgICAgaWYgKHRoaXMuZ2V0UXVlcnkoKS53aGVyZSlcbiAgICAgICAge1xuICAgICAgICAgICAgbGV0IGxhc3RQYXR0ZXJuID0gdGhpcy5nZXRRdWVyeSgpLndoZXJlIVt0aGlzLmdldFF1ZXJ5KCkud2hlcmUhLmxlbmd0aCAtIDFdO1xuICAgICAgICAgICAgaWYgKGxhc3RQYXR0ZXJuLnR5cGUgPT09IFwiYmdwXCIpXG4gICAgICAgICAgICB7XG4gICAgICAgICAgICAgICAgbGFzdFBhdHRlcm4udHJpcGxlcyA9IGxhc3RQYXR0ZXJuLnRyaXBsZXMuY29uY2F0KHRyaXBsZXMpO1xuICAgICAgICAgICAgICAgIHJldHVybiB0aGlzO1xuICAgICAgICAgICAgfVxuICAgICAgICB9XG5cbiAgICAgICAgcmV0dXJuIHRoaXMud2hlcmUoUXVlcnlCdWlsZGVyLmJncCh0cmlwbGVzKSk7XG4gICAgfVxuXG4gICAgcHVibGljIGJncFRyaXBsZSh0cmlwbGU6IFRyaXBsZSk6IFF1ZXJ5QnVpbGRlclxuICAgIHtcbiAgICAgICAgcmV0dXJuIHRoaXMuYmdwVHJpcGxlcyhbdHJpcGxlXSk7XG4gICAgfVxuXG4gICAgcHJvdGVjdGVkIGdldFF1ZXJ5KCk6IFF1ZXJ5XG4gICAge1xuICAgICAgICByZXR1cm4gdGhpcy5xdWVyeTtcbiAgICB9XG5cbiAgICBwcm90ZWN0ZWQgZ2V0R2VuZXJhdG9yKCk6IFNwYXJxbEdlbmVyYXRvclxuICAgIHtcbiAgICAgICAgcmV0dXJuIHRoaXMuZ2VuZXJhdG9yO1xuICAgIH1cblxuICAgIHB1YmxpYyBidWlsZCgpOiBRdWVyeVxuICAgIHtcbiAgICAgICAgcmV0dXJuIHRoaXMuZ2V0UXVlcnkoKTtcbiAgICB9XG5cbiAgICBwdWJsaWMgdG9TdHJpbmcoKTogc3RyaW5nXG4gICAge1xuICAgICAgICByZXR1cm4gdGhpcy5nZXRHZW5lcmF0b3IoKS5zdHJpbmdpZnkodGhpcy5nZXRRdWVyeSgpKTtcbiAgICB9XG5cbiAgICBwdWJsaWMgc3RhdGljIHRlcm0odmFsdWU6IHN0cmluZyk6IFRlcm1cbiAgICB7XG4gICAgICAgIHJldHVybiA8VGVybT52YWx1ZTtcbiAgICB9XG5cbiAgICBwdWJsaWMgc3RhdGljIHZhcih2YXJOYW1lOiBzdHJpbmcpOiBUZXJtXG4gICAge1xuICAgICAgICByZXR1cm4gPFRlcm0+KFwiP1wiICsgdmFyTmFtZSk7XG4gICAgfVxuXG4gICAgcHVibGljIHN0YXRpYyBsaXRlcmFsKHZhbHVlOiBzdHJpbmcpOiBUZXJtXG4gICAge1xuICAgICAgICByZXR1cm4gPFRlcm0+KFwiXFxcIlwiICsgdmFsdWUgKyBcIlxcXCJcIik7XG4gICAgfVxuXG4gICAgcHVibGljIHN0YXRpYyB0eXBlZExpdGVyYWwodmFsdWU6IHN0cmluZywgZGF0YXR5cGU6IHN0cmluZyk6IFRlcm1cbiAgICB7XG4gICAgICAgIHJldHVybiA8VGVybT4oXCJcXFwiXCIgKyB2YWx1ZSArIFwiXFxcIl5eXCIgKyBkYXRhdHlwZSk7XG4gICAgfVxuXG4gICAgcHVibGljIHN0YXRpYyB1cmkodmFsdWU6IHN0cmluZyk6IFRlcm1cbiAgICB7XG4gICAgICAgIHJldHVybiA8VGVybT52YWx1ZTtcbiAgICB9XG5cbiAgICBwdWJsaWMgc3RhdGljIHRyaXBsZShzdWJqZWN0OiBUZXJtLCBwcmVkaWNhdGU6IFByb3BlcnR5UGF0aCB8IFRlcm0sIG9iamVjdDogVGVybSk6IFRyaXBsZVxuICAgIHtcbiAgICAgICAgcmV0dXJuIHtcbiAgICAgICAgICAgIFwic3ViamVjdFwiOiBzdWJqZWN0LFxuICAgICAgICAgICAgXCJwcmVkaWNhdGVcIjogcHJlZGljYXRlLFxuICAgICAgICAgICAgXCJvYmplY3RcIjogb2JqZWN0XG4gICAgICAgIH07XG4gICAgfVxuXG4gICAgcHVibGljIHN0YXRpYyBiZ3AodHJpcGxlczogVHJpcGxlW10pOiBCZ3BQYXR0ZXJuXG4gICAge1xuICAgICAgICByZXR1cm4ge1xuICAgICAgICAgIFwidHlwZVwiOiBcImJncFwiLFxuICAgICAgICAgIFwidHJpcGxlc1wiOiB0cmlwbGVzXG4gICAgICAgIH07XG4gICAgfVxuXG4gICAgcHVibGljIHN0YXRpYyBncmFwaChuYW1lOiBzdHJpbmcsIHBhdHRlcm5zOiBQYXR0ZXJuW10pOiBHcmFwaFBhdHRlcm5cbiAgICB7XG4gICAgICAgIHJldHVybiB7XG4gICAgICAgICAgICBcInR5cGVcIjogXCJncmFwaFwiLFxuICAgICAgICAgICAgXCJuYW1lXCI6IDxUZXJtPm5hbWUsXG4gICAgICAgICAgICBcInBhdHRlcm5zXCI6IHBhdHRlcm5zXG4gICAgICAgIH1cbiAgICB9XG5cbiAgICBwdWJsaWMgc3RhdGljIGdyb3VwKHBhdHRlcm5zOiBQYXR0ZXJuW10pOiBHcm91cFBhdHRlcm5cbiAgICB7XG4gICAgICAgIHJldHVybiB7XG4gICAgICAgICAgICBcInR5cGVcIjogXCJncm91cFwiLFxuICAgICAgICAgICAgXCJwYXR0ZXJuc1wiOiBwYXR0ZXJuc1xuICAgICAgICB9XG4gICAgfVxuXG4gICAgcHVibGljIHN0YXRpYyBmaWx0ZXIoZXhwcmVzc2lvbjogRXhwcmVzc2lvbik6IEZpbHRlclBhdHRlcm5cbiAgICB7XG4gICAgICAgIHJldHVybiB7XG4gICAgICAgICAgICBcInR5cGVcIjogXCJmaWx0ZXJcIixcbiAgICAgICAgICAgIFwiZXhwcmVzc2lvblwiOiBleHByZXNzaW9uXG4gICAgICAgIH1cbiAgICB9XG5cbiAgICBwdWJsaWMgc3RhdGljIG9wZXJhdGlvbihvcGVyYXRvcjogc3RyaW5nLCBhcmdzOiBFeHByZXNzaW9uW10pOiBPcGVyYXRpb25FeHByZXNzaW9uXG4gICAge1xuICAgICAgICByZXR1cm4ge1xuICAgICAgICAgICAgXCJ0eXBlXCI6IFwib3BlcmF0aW9uXCIsXG4gICAgICAgICAgICBcIm9wZXJhdG9yXCI6IG9wZXJhdG9yLFxuICAgICAgICAgICAgXCJhcmdzXCI6IGFyZ3NcbiAgICAgICAgfTtcbiAgICB9XG5cbiAgICBwdWJsaWMgc3RhdGljIGluKHRlcm06IFRlcm0sIGxpc3Q6IFRlcm1bXSk6IE9wZXJhdGlvbkV4cHJlc3Npb25cbiAgICB7XG4gICAgICAgIHJldHVybiBRdWVyeUJ1aWxkZXIub3BlcmF0aW9uKFwiaW5cIiwgWyB0ZXJtLCBsaXN0IF0pO1xuICAgIH1cblxuICAgIHB1YmxpYyBzdGF0aWMgcmVnZXgodGVybTogVGVybSwgcGF0dGVybjogVGVybSwgY2FzZUluc2Vuc2l0aXZlPzogYm9vbGVhbik6IE9wZXJhdGlvbkV4cHJlc3Npb25cbiAgICB7XG4gICAgICAgIGxldCBleHByZXNzaW9uOiBPcGVyYXRpb25FeHByZXNzaW9uID0ge1xuICAgICAgICAgICAgXCJ0eXBlXCI6IFwib3BlcmF0aW9uXCIsXG4gICAgICAgICAgICBcIm9wZXJhdG9yXCI6IFwicmVnZXhcIixcbiAgICAgICAgICAgIFwiYXJnc1wiOiBbIHRlcm0sIDxUZXJtPihcIlxcXCJcIiArIHBhdHRlcm4gKyBcIlxcXCJcIikgXVxuICAgICAgICB9O1xuXG4gICAgICAgIGlmIChjYXNlSW5zZW5zaXRpdmUpIGV4cHJlc3Npb24uYXJncy5wdXNoKDxUZXJtPlwiXFxcImlcXFwiXCIpO1xuXG4gICAgICAgIHJldHVybiBleHByZXNzaW9uO1xuICAgIH1cblxuICAgIHB1YmxpYyBzdGF0aWMgZXEoYXJnMTogRXhwcmVzc2lvbiwgYXJnMjogRXhwcmVzc2lvbik6IE9wZXJhdGlvbkV4cHJlc3Npb25cbiAgICB7XG4gICAgICAgIHJldHVybiBRdWVyeUJ1aWxkZXIub3BlcmF0aW9uKFwiPVwiLCBbIGFyZzEsIGFyZzIgXSk7XG4gICAgfVxuXG4gICAgcHVibGljIHN0YXRpYyBzdHIoYXJnOiBFeHByZXNzaW9uKTogT3BlcmF0aW9uRXhwcmVzc2lvblxuICAgIHtcbiAgICAgICAgcmV0dXJuIFF1ZXJ5QnVpbGRlci5vcGVyYXRpb24oXCJzdHJcIiwgWyBhcmcgXSk7XG4gICAgfVxuXG59IiwiaW1wb3J0IHsgUGFyc2VyLCBTZWxlY3RRdWVyeSwgT3JkZXJpbmcsIFRlcm0sIFZhcmlhYmxlLCBFeHByZXNzaW9uIH0gZnJvbSAnc3BhcnFsanMnO1xuaW1wb3J0IHsgUXVlcnlCdWlsZGVyIH0gZnJvbSAnLi9RdWVyeUJ1aWxkZXInO1xuXG5leHBvcnQgY2xhc3MgU2VsZWN0QnVpbGRlciBleHRlbmRzIFF1ZXJ5QnVpbGRlclxue1xuXG4gICAgY29uc3RydWN0b3Ioc2VsZWN0OiBTZWxlY3RRdWVyeSlcbiAgICB7XG4gICAgICAgIHN1cGVyKHNlbGVjdCk7XG4gICAgfVxuXG4gICAgcHVibGljIHN0YXRpYyBmcm9tU3RyaW5nKHF1ZXJ5U3RyaW5nOiBzdHJpbmcsIHByZWZpeGVzPzogeyBbcHJlZml4OiBzdHJpbmddOiBzdHJpbmc7IH0gfCB1bmRlZmluZWQsIGJhc2VJUkk/OiBzdHJpbmcgfCB1bmRlZmluZWQpOiBTZWxlY3RCdWlsZGVyXG4gICAge1xuICAgICAgICBsZXQgcXVlcnkgPSBuZXcgUGFyc2VyKHByZWZpeGVzLCBiYXNlSVJJKS5wYXJzZShxdWVyeVN0cmluZyk7XG4gICAgICAgIGlmICghPFNlbGVjdFF1ZXJ5PnF1ZXJ5KSB0aHJvdyBuZXcgRXJyb3IoXCJPbmx5IFNFTEVDVCBpcyBzdXBwb3J0ZWRcIik7XG5cbiAgICAgICAgcmV0dXJuIG5ldyBTZWxlY3RCdWlsZGVyKDxTZWxlY3RRdWVyeT5xdWVyeSk7XG4gICAgfVxuXG4gICAgcHVibGljIHByb2plY3RBbGwoKTogU2VsZWN0QnVpbGRlclxuICAgIHtcbiAgICAgICAgdGhpcy5nZXRRdWVyeSgpLnZhcmlhYmxlcyA9IFsgXCIqXCIgXTtcblxuICAgICAgICByZXR1cm4gdGhpcztcbiAgICB9XG5cbiAgICBwdWJsaWMgcHJvamVjdGlvbih2YXJpYWJsZXM6IFZhcmlhYmxlW10pOiBTZWxlY3RCdWlsZGVyXG4gICAge1xuICAgICAgICB0aGlzLmdldFF1ZXJ5KCkudmFyaWFibGVzID0gdmFyaWFibGVzO1xuXG4gICAgICAgIHJldHVybiB0aGlzO1xuICAgIH1cblxuICAgIHB1YmxpYyBwcm9qZWN0KHRlcm06IFRlcm0pOiBTZWxlY3RCdWlsZGVyXG4gICAge1xuICAgICAgICB0aGlzLmdldFF1ZXJ5KCkudmFyaWFibGVzLnB1c2goPFRlcm0gJiBcIipcIj50ZXJtKTtcblxuICAgICAgICByZXR1cm4gdGhpcztcbiAgICB9XG5cbiAgICBwdWJsaWMgaXNQcm9qZWN0ZWQodGVybTogVGVybSk6IGJvb2xlYW5cbiAgICB7XG4gICAgICAgIHJldHVybiB0aGlzLmdldFF1ZXJ5KCkudmFyaWFibGVzLmluY2x1ZGVzKDxUZXJtICYgXCIqXCI+dGVybSk7XG4gICAgfVxuXG4gICAgcHVibGljIG9yZGVyQnkob3JkZXJpbmc6IE9yZGVyaW5nKTogU2VsZWN0QnVpbGRlclxuICAgIHtcbiAgICAgICAgaWYgKCF0aGlzLmdldFF1ZXJ5KCkub3JkZXIpIHRoaXMuZ2V0UXVlcnkoKS5vcmRlciA9IFtdO1xuICAgICAgICB0aGlzLmdldFF1ZXJ5KCkub3JkZXIhLnB1c2gob3JkZXJpbmcpO1xuXG4gICAgICAgIHJldHVybiB0aGlzO1xuICAgIH1cblxuICAgIHB1YmxpYyBvZmZzZXQob2Zmc2V0OiBudW1iZXIpOiBTZWxlY3RCdWlsZGVyXG4gICAge1xuICAgICAgICB0aGlzLmdldFF1ZXJ5KCkub2Zmc2V0ID0gb2Zmc2V0O1xuXG4gICAgICAgIHJldHVybiB0aGlzO1xuICAgIH1cblxuICAgIHB1YmxpYyBsaW1pdChsaW1pdDogbnVtYmVyKTogU2VsZWN0QnVpbGRlclxuICAgIHtcbiAgICAgICAgdGhpcy5nZXRRdWVyeSgpLmxpbWl0ID0gbGltaXQ7XG5cbiAgICAgICAgcmV0dXJuIHRoaXM7XG4gICAgfVxuXG4gICAgcHJvdGVjdGVkIGdldFF1ZXJ5KCk6IFNlbGVjdFF1ZXJ5XG4gICAge1xuICAgICAgICByZXR1cm4gPFNlbGVjdFF1ZXJ5PnN1cGVyLmdldFF1ZXJ5KCk7XG4gICAgfVxuXG4gICAgcHVibGljIGJ1aWxkKCk6IFNlbGVjdFF1ZXJ5XG4gICAge1xuICAgICAgICByZXR1cm4gPFNlbGVjdFF1ZXJ5PnN1cGVyLmJ1aWxkKCk7XG4gICAgfVxuXG4gICAgcHVibGljIHN0YXRpYyBvcmRlcmluZyhleHByOiBFeHByZXNzaW9uLCBkZXNjPzogYm9vbGVhbik6IE9yZGVyaW5nXG4gICAge1xuICAgICAgICBsZXQgb3JkZXJpbmc6IE9yZGVyaW5nID0ge1xuICAgICAgICAgIFwiZXhwcmVzc2lvblwiOiBleHByLFxuICAgICAgICB9O1xuXG4gICAgICAgIGlmIChkZXNjICE9PSB1bmRlZmluZWQgJiYgZGVzYyA9PSB0cnVlKSBvcmRlcmluZy5kZXNjZW5kaW5nID0gZGVzYztcblxuICAgICAgICByZXR1cm4gb3JkZXJpbmc7XG4gICAgfVxuXG59IiwiLy8gc2hpbSBmb3IgdXNpbmcgcHJvY2VzcyBpbiBicm93c2VyXG52YXIgcHJvY2VzcyA9IG1vZHVsZS5leHBvcnRzID0ge307XG5cbi8vIGNhY2hlZCBmcm9tIHdoYXRldmVyIGdsb2JhbCBpcyBwcmVzZW50IHNvIHRoYXQgdGVzdCBydW5uZXJzIHRoYXQgc3R1YiBpdFxuLy8gZG9uJ3QgYnJlYWsgdGhpbmdzLiAgQnV0IHdlIG5lZWQgdG8gd3JhcCBpdCBpbiBhIHRyeSBjYXRjaCBpbiBjYXNlIGl0IGlzXG4vLyB3cmFwcGVkIGluIHN0cmljdCBtb2RlIGNvZGUgd2hpY2ggZG9lc24ndCBkZWZpbmUgYW55IGdsb2JhbHMuICBJdCdzIGluc2lkZSBhXG4vLyBmdW5jdGlvbiBiZWNhdXNlIHRyeS9jYXRjaGVzIGRlb3B0aW1pemUgaW4gY2VydGFpbiBlbmdpbmVzLlxuXG52YXIgY2FjaGVkU2V0VGltZW91dDtcbnZhciBjYWNoZWRDbGVhclRpbWVvdXQ7XG5cbmZ1bmN0aW9uIGRlZmF1bHRTZXRUaW1vdXQoKSB7XG4gICAgdGhyb3cgbmV3IEVycm9yKCdzZXRUaW1lb3V0IGhhcyBub3QgYmVlbiBkZWZpbmVkJyk7XG59XG5mdW5jdGlvbiBkZWZhdWx0Q2xlYXJUaW1lb3V0ICgpIHtcbiAgICB0aHJvdyBuZXcgRXJyb3IoJ2NsZWFyVGltZW91dCBoYXMgbm90IGJlZW4gZGVmaW5lZCcpO1xufVxuKGZ1bmN0aW9uICgpIHtcbiAgICB0cnkge1xuICAgICAgICBpZiAodHlwZW9mIHNldFRpbWVvdXQgPT09ICdmdW5jdGlvbicpIHtcbiAgICAgICAgICAgIGNhY2hlZFNldFRpbWVvdXQgPSBzZXRUaW1lb3V0O1xuICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgY2FjaGVkU2V0VGltZW91dCA9IGRlZmF1bHRTZXRUaW1vdXQ7XG4gICAgICAgIH1cbiAgICB9IGNhdGNoIChlKSB7XG4gICAgICAgIGNhY2hlZFNldFRpbWVvdXQgPSBkZWZhdWx0U2V0VGltb3V0O1xuICAgIH1cbiAgICB0cnkge1xuICAgICAgICBpZiAodHlwZW9mIGNsZWFyVGltZW91dCA9PT0gJ2Z1bmN0aW9uJykge1xuICAgICAgICAgICAgY2FjaGVkQ2xlYXJUaW1lb3V0ID0gY2xlYXJUaW1lb3V0O1xuICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgY2FjaGVkQ2xlYXJUaW1lb3V0ID0gZGVmYXVsdENsZWFyVGltZW91dDtcbiAgICAgICAgfVxuICAgIH0gY2F0Y2ggKGUpIHtcbiAgICAgICAgY2FjaGVkQ2xlYXJUaW1lb3V0ID0gZGVmYXVsdENsZWFyVGltZW91dDtcbiAgICB9XG59ICgpKVxuZnVuY3Rpb24gcnVuVGltZW91dChmdW4pIHtcbiAgICBpZiAoY2FjaGVkU2V0VGltZW91dCA9PT0gc2V0VGltZW91dCkge1xuICAgICAgICAvL25vcm1hbCBlbnZpcm9tZW50cyBpbiBzYW5lIHNpdHVhdGlvbnNcbiAgICAgICAgcmV0dXJuIHNldFRpbWVvdXQoZnVuLCAwKTtcbiAgICB9XG4gICAgLy8gaWYgc2V0VGltZW91dCB3YXNuJ3QgYXZhaWxhYmxlIGJ1dCB3YXMgbGF0dGVyIGRlZmluZWRcbiAgICBpZiAoKGNhY2hlZFNldFRpbWVvdXQgPT09IGRlZmF1bHRTZXRUaW1vdXQgfHwgIWNhY2hlZFNldFRpbWVvdXQpICYmIHNldFRpbWVvdXQpIHtcbiAgICAgICAgY2FjaGVkU2V0VGltZW91dCA9IHNldFRpbWVvdXQ7XG4gICAgICAgIHJldHVybiBzZXRUaW1lb3V0KGZ1biwgMCk7XG4gICAgfVxuICAgIHRyeSB7XG4gICAgICAgIC8vIHdoZW4gd2hlbiBzb21lYm9keSBoYXMgc2NyZXdlZCB3aXRoIHNldFRpbWVvdXQgYnV0IG5vIEkuRS4gbWFkZG5lc3NcbiAgICAgICAgcmV0dXJuIGNhY2hlZFNldFRpbWVvdXQoZnVuLCAwKTtcbiAgICB9IGNhdGNoKGUpe1xuICAgICAgICB0cnkge1xuICAgICAgICAgICAgLy8gV2hlbiB3ZSBhcmUgaW4gSS5FLiBidXQgdGhlIHNjcmlwdCBoYXMgYmVlbiBldmFsZWQgc28gSS5FLiBkb2Vzbid0IHRydXN0IHRoZSBnbG9iYWwgb2JqZWN0IHdoZW4gY2FsbGVkIG5vcm1hbGx5XG4gICAgICAgICAgICByZXR1cm4gY2FjaGVkU2V0VGltZW91dC5jYWxsKG51bGwsIGZ1biwgMCk7XG4gICAgICAgIH0gY2F0Y2goZSl7XG4gICAgICAgICAgICAvLyBzYW1lIGFzIGFib3ZlIGJ1dCB3aGVuIGl0J3MgYSB2ZXJzaW9uIG9mIEkuRS4gdGhhdCBtdXN0IGhhdmUgdGhlIGdsb2JhbCBvYmplY3QgZm9yICd0aGlzJywgaG9wZnVsbHkgb3VyIGNvbnRleHQgY29ycmVjdCBvdGhlcndpc2UgaXQgd2lsbCB0aHJvdyBhIGdsb2JhbCBlcnJvclxuICAgICAgICAgICAgcmV0dXJuIGNhY2hlZFNldFRpbWVvdXQuY2FsbCh0aGlzLCBmdW4sIDApO1xuICAgICAgICB9XG4gICAgfVxuXG5cbn1cbmZ1bmN0aW9uIHJ1bkNsZWFyVGltZW91dChtYXJrZXIpIHtcbiAgICBpZiAoY2FjaGVkQ2xlYXJUaW1lb3V0ID09PSBjbGVhclRpbWVvdXQpIHtcbiAgICAgICAgLy9ub3JtYWwgZW52aXJvbWVudHMgaW4gc2FuZSBzaXR1YXRpb25zXG4gICAgICAgIHJldHVybiBjbGVhclRpbWVvdXQobWFya2VyKTtcbiAgICB9XG4gICAgLy8gaWYgY2xlYXJUaW1lb3V0IHdhc24ndCBhdmFpbGFibGUgYnV0IHdhcyBsYXR0ZXIgZGVmaW5lZFxuICAgIGlmICgoY2FjaGVkQ2xlYXJUaW1lb3V0ID09PSBkZWZhdWx0Q2xlYXJUaW1lb3V0IHx8ICFjYWNoZWRDbGVhclRpbWVvdXQpICYmIGNsZWFyVGltZW91dCkge1xuICAgICAgICBjYWNoZWRDbGVhclRpbWVvdXQgPSBjbGVhclRpbWVvdXQ7XG4gICAgICAgIHJldHVybiBjbGVhclRpbWVvdXQobWFya2VyKTtcbiAgICB9XG4gICAgdHJ5IHtcbiAgICAgICAgLy8gd2hlbiB3aGVuIHNvbWVib2R5IGhhcyBzY3Jld2VkIHdpdGggc2V0VGltZW91dCBidXQgbm8gSS5FLiBtYWRkbmVzc1xuICAgICAgICByZXR1cm4gY2FjaGVkQ2xlYXJUaW1lb3V0KG1hcmtlcik7XG4gICAgfSBjYXRjaCAoZSl7XG4gICAgICAgIHRyeSB7XG4gICAgICAgICAgICAvLyBXaGVuIHdlIGFyZSBpbiBJLkUuIGJ1dCB0aGUgc2NyaXB0IGhhcyBiZWVuIGV2YWxlZCBzbyBJLkUuIGRvZXNuJ3QgIHRydXN0IHRoZSBnbG9iYWwgb2JqZWN0IHdoZW4gY2FsbGVkIG5vcm1hbGx5XG4gICAgICAgICAgICByZXR1cm4gY2FjaGVkQ2xlYXJUaW1lb3V0LmNhbGwobnVsbCwgbWFya2VyKTtcbiAgICAgICAgfSBjYXRjaCAoZSl7XG4gICAgICAgICAgICAvLyBzYW1lIGFzIGFib3ZlIGJ1dCB3aGVuIGl0J3MgYSB2ZXJzaW9uIG9mIEkuRS4gdGhhdCBtdXN0IGhhdmUgdGhlIGdsb2JhbCBvYmplY3QgZm9yICd0aGlzJywgaG9wZnVsbHkgb3VyIGNvbnRleHQgY29ycmVjdCBvdGhlcndpc2UgaXQgd2lsbCB0aHJvdyBhIGdsb2JhbCBlcnJvci5cbiAgICAgICAgICAgIC8vIFNvbWUgdmVyc2lvbnMgb2YgSS5FLiBoYXZlIGRpZmZlcmVudCBydWxlcyBmb3IgY2xlYXJUaW1lb3V0IHZzIHNldFRpbWVvdXRcbiAgICAgICAgICAgIHJldHVybiBjYWNoZWRDbGVhclRpbWVvdXQuY2FsbCh0aGlzLCBtYXJrZXIpO1xuICAgICAgICB9XG4gICAgfVxuXG5cblxufVxudmFyIHF1ZXVlID0gW107XG52YXIgZHJhaW5pbmcgPSBmYWxzZTtcbnZhciBjdXJyZW50UXVldWU7XG52YXIgcXVldWVJbmRleCA9IC0xO1xuXG5mdW5jdGlvbiBjbGVhblVwTmV4dFRpY2soKSB7XG4gICAgaWYgKCFkcmFpbmluZyB8fCAhY3VycmVudFF1ZXVlKSB7XG4gICAgICAgIHJldHVybjtcbiAgICB9XG4gICAgZHJhaW5pbmcgPSBmYWxzZTtcbiAgICBpZiAoY3VycmVudFF1ZXVlLmxlbmd0aCkge1xuICAgICAgICBxdWV1ZSA9IGN1cnJlbnRRdWV1ZS5jb25jYXQocXVldWUpO1xuICAgIH0gZWxzZSB7XG4gICAgICAgIHF1ZXVlSW5kZXggPSAtMTtcbiAgICB9XG4gICAgaWYgKHF1ZXVlLmxlbmd0aCkge1xuICAgICAgICBkcmFpblF1ZXVlKCk7XG4gICAgfVxufVxuXG5mdW5jdGlvbiBkcmFpblF1ZXVlKCkge1xuICAgIGlmIChkcmFpbmluZykge1xuICAgICAgICByZXR1cm47XG4gICAgfVxuICAgIHZhciB0aW1lb3V0ID0gcnVuVGltZW91dChjbGVhblVwTmV4dFRpY2spO1xuICAgIGRyYWluaW5nID0gdHJ1ZTtcblxuICAgIHZhciBsZW4gPSBxdWV1ZS5sZW5ndGg7XG4gICAgd2hpbGUobGVuKSB7XG4gICAgICAgIGN1cnJlbnRRdWV1ZSA9IHF1ZXVlO1xuICAgICAgICBxdWV1ZSA9IFtdO1xuICAgICAgICB3aGlsZSAoKytxdWV1ZUluZGV4IDwgbGVuKSB7XG4gICAgICAgICAgICBpZiAoY3VycmVudFF1ZXVlKSB7XG4gICAgICAgICAgICAgICAgY3VycmVudFF1ZXVlW3F1ZXVlSW5kZXhdLnJ1bigpO1xuICAgICAgICAgICAgfVxuICAgICAgICB9XG4gICAgICAgIHF1ZXVlSW5kZXggPSAtMTtcbiAgICAgICAgbGVuID0gcXVldWUubGVuZ3RoO1xuICAgIH1cbiAgICBjdXJyZW50UXVldWUgPSBudWxsO1xuICAgIGRyYWluaW5nID0gZmFsc2U7XG4gICAgcnVuQ2xlYXJUaW1lb3V0KHRpbWVvdXQpO1xufVxuXG5wcm9jZXNzLm5leHRUaWNrID0gZnVuY3Rpb24gKGZ1bikge1xuICAgIHZhciBhcmdzID0gbmV3IEFycmF5KGFyZ3VtZW50cy5sZW5ndGggLSAxKTtcbiAgICBpZiAoYXJndW1lbnRzLmxlbmd0aCA+IDEpIHtcbiAgICAgICAgZm9yICh2YXIgaSA9IDE7IGkgPCBhcmd1bWVudHMubGVuZ3RoOyBpKyspIHtcbiAgICAgICAgICAgIGFyZ3NbaSAtIDFdID0gYXJndW1lbnRzW2ldO1xuICAgICAgICB9XG4gICAgfVxuICAgIHF1ZXVlLnB1c2gobmV3IEl0ZW0oZnVuLCBhcmdzKSk7XG4gICAgaWYgKHF1ZXVlLmxlbmd0aCA9PT0gMSAmJiAhZHJhaW5pbmcpIHtcbiAgICAgICAgcnVuVGltZW91dChkcmFpblF1ZXVlKTtcbiAgICB9XG59O1xuXG4vLyB2OCBsaWtlcyBwcmVkaWN0aWJsZSBvYmplY3RzXG5mdW5jdGlvbiBJdGVtKGZ1biwgYXJyYXkpIHtcbiAgICB0aGlzLmZ1biA9IGZ1bjtcbiAgICB0aGlzLmFycmF5ID0gYXJyYXk7XG59XG5JdGVtLnByb3RvdHlwZS5ydW4gPSBmdW5jdGlvbiAoKSB7XG4gICAgdGhpcy5mdW4uYXBwbHkobnVsbCwgdGhpcy5hcnJheSk7XG59O1xucHJvY2Vzcy50aXRsZSA9ICdicm93c2VyJztcbnByb2Nlc3MuYnJvd3NlciA9IHRydWU7XG5wcm9jZXNzLmVudiA9IHt9O1xucHJvY2Vzcy5hcmd2ID0gW107XG5wcm9jZXNzLnZlcnNpb24gPSAnJzsgLy8gZW1wdHkgc3RyaW5nIHRvIGF2b2lkIHJlZ2V4cCBpc3N1ZXNcbnByb2Nlc3MudmVyc2lvbnMgPSB7fTtcblxuZnVuY3Rpb24gbm9vcCgpIHt9XG5cbnByb2Nlc3Mub24gPSBub29wO1xucHJvY2Vzcy5hZGRMaXN0ZW5lciA9IG5vb3A7XG5wcm9jZXNzLm9uY2UgPSBub29wO1xucHJvY2Vzcy5vZmYgPSBub29wO1xucHJvY2Vzcy5yZW1vdmVMaXN0ZW5lciA9IG5vb3A7XG5wcm9jZXNzLnJlbW92ZUFsbExpc3RlbmVycyA9IG5vb3A7XG5wcm9jZXNzLmVtaXQgPSBub29wO1xucHJvY2Vzcy5wcmVwZW5kTGlzdGVuZXIgPSBub29wO1xucHJvY2Vzcy5wcmVwZW5kT25jZUxpc3RlbmVyID0gbm9vcDtcblxucHJvY2Vzcy5saXN0ZW5lcnMgPSBmdW5jdGlvbiAobmFtZSkgeyByZXR1cm4gW10gfVxuXG5wcm9jZXNzLmJpbmRpbmcgPSBmdW5jdGlvbiAobmFtZSkge1xuICAgIHRocm93IG5ldyBFcnJvcigncHJvY2Vzcy5iaW5kaW5nIGlzIG5vdCBzdXBwb3J0ZWQnKTtcbn07XG5cbnByb2Nlc3MuY3dkID0gZnVuY3Rpb24gKCkgeyByZXR1cm4gJy8nIH07XG5wcm9jZXNzLmNoZGlyID0gZnVuY3Rpb24gKGRpcikge1xuICAgIHRocm93IG5ldyBFcnJvcigncHJvY2Vzcy5jaGRpciBpcyBub3Qgc3VwcG9ydGVkJyk7XG59O1xucHJvY2Vzcy51bWFzayA9IGZ1bmN0aW9uKCkgeyByZXR1cm4gMDsgfTtcbiIsIm1vZHVsZS5leHBvcnRzID0gZnVuY3Rpb24obW9kdWxlKSB7XG5cdGlmICghbW9kdWxlLndlYnBhY2tQb2x5ZmlsbCkge1xuXHRcdG1vZHVsZS5kZXByZWNhdGUgPSBmdW5jdGlvbigpIHt9O1xuXHRcdG1vZHVsZS5wYXRocyA9IFtdO1xuXHRcdC8vIG1vZHVsZS5wYXJlbnQgPSB1bmRlZmluZWQgYnkgZGVmYXVsdFxuXHRcdGlmICghbW9kdWxlLmNoaWxkcmVuKSBtb2R1bGUuY2hpbGRyZW4gPSBbXTtcblx0XHRPYmplY3QuZGVmaW5lUHJvcGVydHkobW9kdWxlLCBcImxvYWRlZFwiLCB7XG5cdFx0XHRlbnVtZXJhYmxlOiB0cnVlLFxuXHRcdFx0Z2V0OiBmdW5jdGlvbigpIHtcblx0XHRcdFx0cmV0dXJuIG1vZHVsZS5sO1xuXHRcdFx0fVxuXHRcdH0pO1xuXHRcdE9iamVjdC5kZWZpbmVQcm9wZXJ0eShtb2R1bGUsIFwiaWRcIiwge1xuXHRcdFx0ZW51bWVyYWJsZTogdHJ1ZSxcblx0XHRcdGdldDogZnVuY3Rpb24oKSB7XG5cdFx0XHRcdHJldHVybiBtb2R1bGUuaTtcblx0XHRcdH1cblx0XHR9KTtcblx0XHRtb2R1bGUud2VicGFja1BvbHlmaWxsID0gMTtcblx0fVxuXHRyZXR1cm4gbW9kdWxlO1xufTtcbiIsIi8vLyA8cmVmZXJlbmNlIHR5cGVzPVwiZ29vZ2xlbWFwc1wiIC8+XG5cbi8vIGltcG9ydCB7IE1hcCwgTGF0TG5nLCBMYXRMbmdCb3VuZHMsIE1hcmtlciwgSW5mb1dpbmRvdyB9IGZyb20gJ2dvb2dsZW1hcHMnOyAvLyB1c2luZyA8cmVmZXJlbmNlPiBpbnN0ZWFkIGFzIG90aGVyd2lzZSB3ZSB3b3VsZCBnZXQgdGhlIFwiQHR5cGVzL2dvb2dsZW1hcHMvaW5kZXguZC50cyBpcyBub3QgYSBtb2R1bGVcIiBlcnJvclxuaW1wb3J0IHsgTWFwT3ZlcmxheSB9IGZyb20gJy4vbWFwL01hcE92ZXJsYXknO1xuaW1wb3J0IHsgU2VsZWN0QnVpbGRlciB9IGZyb20gJ0BhdG9tZ3JhcGgvU1BBUlFMQnVpbGRlci9jb20vYXRvbWdyYXBoL2xpbmtlZGRhdGFodWIvcXVlcnkvU2VsZWN0QnVpbGRlcic7XG5pbXBvcnQgeyBEZXNjcmliZUJ1aWxkZXIgfSBmcm9tICdAYXRvbWdyYXBoL1NQQVJRTEJ1aWxkZXIvY29tL2F0b21ncmFwaC9saW5rZWRkYXRhaHViL3F1ZXJ5L0Rlc2NyaWJlQnVpbGRlcic7XG5pbXBvcnQgeyBRdWVyeUJ1aWxkZXIgfSBmcm9tICdAYXRvbWdyYXBoL1NQQVJRTEJ1aWxkZXIvY29tL2F0b21ncmFwaC9saW5rZWRkYXRhaHViL3F1ZXJ5L1F1ZXJ5QnVpbGRlcic7XG5pbXBvcnQgeyBTZWxlY3RRdWVyeSB9IGZyb20gJ3NwYXJxbGpzJztcbmltcG9ydCB7IFVSTEJ1aWxkZXIgfSBmcm9tICdAYXRvbWdyYXBoL1VSTEJ1aWxkZXIvY29tL2F0b21ncmFwaC9saW5rZWRkYXRhaHViL3V0aWwvVVJMQnVpbGRlcic7XG5cbmV4cG9ydCBjbGFzcyBHZW9cbntcblxuICAgIHB1YmxpYyBzdGF0aWMgcmVhZG9ubHkgUkRGX05TID0gXCJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjXCI7XG4gICAgcHVibGljIHN0YXRpYyByZWFkb25seSBYU0RfTlMgPSBcImh0dHA6Ly93d3cudzMub3JnLzIwMDEvWE1MU2NoZW1hI1wiO1xuICAgIHB1YmxpYyBzdGF0aWMgcmVhZG9ubHkgQVBMVF9OUyA9IFwiaHR0cHM6Ly93M2lkLm9yZy9hdG9tZ3JhcGgvbGlua2VkZGF0YWh1Yi90ZW1wbGF0ZXMjXCI7XG4gICAgcHVibGljIHN0YXRpYyByZWFkb25seSBHRU9fTlMgPSBcImh0dHA6Ly93d3cudzMub3JnLzIwMDMvMDEvZ2VvL3dnczg0X3BvcyNcIlxuICAgIHB1YmxpYyBzdGF0aWMgcmVhZG9ubHkgRk9BRl9OUyA9IFwiaHR0cDovL3htbG5zLmNvbS9mb2FmLzAuMS9cIjtcblxuICAgIHByaXZhdGUgcmVhZG9ubHkgbWFwOiBnb29nbGUubWFwcy5NYXA7XG4gICAgcHJpdmF0ZSByZWFkb25seSBlbmRwb2ludDogVVJMO1xuICAgIHByaXZhdGUgcmVhZG9ubHkgc2VsZWN0OiBzdHJpbmc7XG4gICAgcHJpdmF0ZSByZWFkb25seSBpdGVtVmFyTmFtZTogc3RyaW5nO1xuICAgIHByaXZhdGUgcmVhZG9ubHkgbG9hZGVkUmVzb3VyY2VzOiBNYXA8VVJMLCBib29sZWFuPjtcbiAgICBwcml2YXRlIGxvYWRlZEJvdW5kczogZ29vZ2xlLm1hcHMuTGF0TG5nQm91bmRzIHwgbnVsbCB8IHVuZGVmaW5lZDtcbiAgICBwcml2YXRlIHJlYWRvbmx5IGljb25zOiBzdHJpbmdbXTtcbiAgICBwcml2YXRlIHJlYWRvbmx5IHR5cGVJY29uczogTWFwPHN0cmluZywgc3RyaW5nPjtcblxuICAgIGNvbnN0cnVjdG9yKG1hcDogZ29vZ2xlLm1hcHMuTWFwLCBlbmRwb2ludDogVVJMLCBzZWxlY3Q6IHN0cmluZywgaXRlbVZhck5hbWU6IHN0cmluZylcbiAgICB7XG4gICAgICAgIHRoaXMubWFwID0gbWFwO1xuICAgICAgICB0aGlzLmVuZHBvaW50ID0gZW5kcG9pbnQ7XG4gICAgICAgIHRoaXMuc2VsZWN0ID0gc2VsZWN0O1xuICAgICAgICB0aGlzLml0ZW1WYXJOYW1lID0gaXRlbVZhck5hbWU7XG4gICAgICAgIHRoaXMubG9hZGVkUmVzb3VyY2VzID0gbmV3IE1hcDxVUkwsIGJvb2xlYW4+KCk7XG4gICAgICAgIHRoaXMuaWNvbnMgPSBbIFwiaHR0cHM6Ly9tYXBzLmdvb2dsZS5jb20vbWFwZmlsZXMvbXMvaWNvbnMvYmx1ZS1kb3QucG5nXCIsXG4gICAgICAgICAgICBcImh0dHBzOi8vbWFwcy5nb29nbGUuY29tL21hcGZpbGVzL21zL2ljb25zL3JlZC1kb3QucG5nXCIsXG4gICAgICAgICAgICBcImh0dHBzOi8vbWFwcy5nb29nbGUuY29tL21hcGZpbGVzL21zL2ljb25zL3B1cnBsZS1kb3QucG5nXCIsXG4gICAgICAgICAgICBcImh0dHBzOi8vbWFwcy5nb29nbGUuY29tL21hcGZpbGVzL21zL2ljb25zL3llbGxvdy1kb3QucG5nXCIsXG4gICAgICAgICAgICBcImh0dHBzOi8vbWFwcy5nb29nbGUuY29tL21hcGZpbGVzL21zL2ljb25zL2dyZWVuLWRvdC5wbmdcIiBdO1xuICAgICAgICB0aGlzLnR5cGVJY29ucyA9IG5ldyBNYXA8c3RyaW5nLCBzdHJpbmc+KCk7XG4gICAgfVxuXG4gICAgcHJpdmF0ZSBnZXRNYXAoKTogZ29vZ2xlLm1hcHMuTWFwXG4gICAge1xuICAgICAgICByZXR1cm4gdGhpcy5tYXA7XG4gICAgfTtcblxuICAgIHByaXZhdGUgZ2V0RW5kcG9pbnQoKTogVVJMXG4gICAge1xuICAgICAgICByZXR1cm4gdGhpcy5lbmRwb2ludDtcbiAgICB9XG5cbiAgICBwcml2YXRlIGdldFNlbGVjdCgpOiBzdHJpbmdcbiAgICB7XG4gICAgICAgIHJldHVybiB0aGlzLnNlbGVjdDtcbiAgICB9XG5cbiAgICBwcml2YXRlIGdldEl0ZW1WYXJOYW1lKCk6IHN0cmluZ1xuICAgIHtcbiAgICAgICAgcmV0dXJuIHRoaXMuaXRlbVZhck5hbWU7XG4gICAgfTtcblxuICAgIHByaXZhdGUgZ2V0TG9hZGVkUmVzb3VyY2VzKCk6IE1hcDxVUkwsIGJvb2xlYW4+XG4gICAge1xuICAgICAgICByZXR1cm4gdGhpcy5sb2FkZWRSZXNvdXJjZXM7XG4gICAgfVxuXG4gICAgcHVibGljIGdldExvYWRlZEJvdW5kcygpOiBnb29nbGUubWFwcy5MYXRMbmdCb3VuZHMgfCBudWxsIHwgdW5kZWZpbmVkXG4gICAge1xuICAgICAgICByZXR1cm4gdGhpcy5sb2FkZWRCb3VuZHM7XG4gICAgfVxuXG4gICAgcHJpdmF0ZSBzZXRMb2FkZWRCb3VuZHMoYm91bmRzPzogZ29vZ2xlLm1hcHMuTGF0TG5nQm91bmRzIHwgbnVsbCB8IHVuZGVmaW5lZClcbiAgICB7XG4gICAgICAgIHRoaXMubG9hZGVkQm91bmRzID0gYm91bmRzO1xuICAgIH1cblxuICAgIHB1YmxpYyBnZXRJY29ucygpOiBzdHJpbmdbXVxuICAgIHtcbiAgICAgICAgcmV0dXJuIHRoaXMuaWNvbnM7XG4gICAgfVxuXG4gICAgcHVibGljIGdldFR5cGVJY29ucygpOiBNYXA8c3RyaW5nLCBzdHJpbmc+XG4gICAge1xuICAgICAgICByZXR1cm4gdGhpcy50eXBlSWNvbnM7XG4gICAgfVxuXG4gICAgcHJpdmF0ZSBsb2FkTWFya2Vycyh0aGlzOiBHZW8sIHByb21pc2U6ICh0aGlzOiB2b2lkLCByZGZYbWw6IERvY3VtZW50KSA9PiAodm9pZCkpOiB2b2lkXG4gICAge1xuICAgICAgICBpZiAodGhpcy5nZXRNYXAoKS5nZXRCb3VuZHMoKSA9PSBudWxsKSB0aHJvdyBFcnJvcihcIk1hcCBib3VuZHMgYXJlIG51bGwgb3IgdW5kZWZpbmVkXCIpO1xuXG4gICAgICAgIC8vIGRvIG5vdCBsb2FkIG1hcmtlcnMgaWYgdGhlIG5ldyBib3VuZHMgYXJlIHdpdGhpbiBhbHJlYWR5IGxvYWRlZCBib3VuZHNcbiAgICAgICAgaWYgKHRoaXMuZ2V0TG9hZGVkQm91bmRzKCkgIT0gbnVsbCAmJlxuICAgICAgICAgICAgICAgIHRoaXMuZ2V0TG9hZGVkQm91bmRzKCkhLmNvbnRhaW5zKHRoaXMuZ2V0TWFwKCkuZ2V0Qm91bmRzKCkhLmdldE5vcnRoRWFzdCgpKSAmJiBcbiAgICAgICAgICAgICAgICB0aGlzLmdldExvYWRlZEJvdW5kcygpIS5jb250YWlucyh0aGlzLmdldE1hcCgpLmdldEJvdW5kcygpIS5nZXRTb3V0aFdlc3QoKSkpXG4gICAgICAgICAgICByZXR1cm47XG4gICAgICAgIFxuICAgICAgICBsZXQgbWFya2VyT3ZlcmxheSA9IG5ldyBNYXBPdmVybGF5KHRoaXMuZ2V0TWFwKCksIFwibWFya2VyLXByb2dyZXNzXCIpO1xuICAgICAgICBtYXJrZXJPdmVybGF5LnNob3coKTtcblxuICAgICAgICBQcm9taXNlLnJlc29sdmUoU2VsZWN0QnVpbGRlci5mcm9tU3RyaW5nKHRoaXMuZ2V0U2VsZWN0KCkpLmJ1aWxkKCkpLlxuICAgICAgICAgICAgdGhlbih0aGlzLmJ1aWxkUXVlcnkpLlxuICAgICAgICAgICAgdGhlbih0aGlzLmJ1aWxkUXVlcnlVUkwpLlxuICAgICAgICAgICAgdGhlbih1cmwgPT4gdXJsLnRvU3RyaW5nKCkpLlxuICAgICAgICAgICAgdGhlbih0aGlzLnJlcXVlc3RSREZYTUwpLlxuICAgICAgICAgICAgdGhlbihyZXNwb25zZSA9PlxuICAgICAgICAgICAge1xuICAgICAgICAgICAgICAgIGlmKHJlc3BvbnNlLm9rKSByZXR1cm4gcmVzcG9uc2UudGV4dCgpO1xuXG4gICAgICAgICAgICAgICAgdGhyb3cgbmV3IEVycm9yKFwiQ291bGQgbm90IGxvYWQgUkRGL1hNTCByZXNwb25zZSBmcm9tICdcIiArIHJlc3BvbnNlLnVybCArIFwiJ1wiKTtcbiAgICAgICAgICAgIH0pLlxuICAgICAgICAgICAgdGhlbih0aGlzLnBhcnNlWE1MKS5cbiAgICAgICAgICAgIHRoZW4ocHJvbWlzZSkuXG4gICAgICAgICAgICB0aGVuKCgpID0+XG4gICAgICAgICAgICB7XG4gICAgICAgICAgICAgICAgdGhpcy5zZXRMb2FkZWRCb3VuZHModGhpcy5nZXRNYXAoKS5nZXRCb3VuZHMoKSk7XG5cbiAgICAgICAgICAgICAgICBtYXJrZXJPdmVybGF5LmhpZGUoKTtcbiAgICAgICAgICAgIH0pLlxuICAgICAgICAgICAgY2F0Y2goZXJyb3IgPT5cbiAgICAgICAgICAgIHtcbiAgICAgICAgICAgICAgICBjb25zb2xlLmxvZygnSFRUUCByZXF1ZXN0IGZhaWxlZDogJywgZXJyb3IubWVzc2FnZSk7XG4gICAgICAgICAgICB9KTtcbiAgICB9XG5cbiAgICBwdWJsaWMgYWRkTWFya2VycyA9IChyZGZYbWw6IFhNTERvY3VtZW50KSA9PlxuICAgIHsgICBcbiAgICAgICAgbGV0IGRlc2NyaXB0aW9ucyA9IHJkZlhtbC5nZXRFbGVtZW50c0J5VGFnTmFtZU5TKEdlby5SREZfTlMsIFwiRGVzY3JpcHRpb25cIik7XG4gICAgICAgIGZvciAobGV0IGRlc2NyaXB0aW9uIG9mIDxhbnk+ZGVzY3JpcHRpb25zKVxuICAgICAgICB7XG4gICAgICAgICAgICBpZiAoZGVzY3JpcHRpb24uaGFzQXR0cmlidXRlTlMoR2VvLlJERl9OUywgXCJhYm91dFwiKSB8fCBkZXNjcmlwdGlvbi5oYXNBdHRyaWJ1dGVOUyhHZW8uUkRGX05TLCBcIm5vZGVJRFwiKSlcbiAgICAgICAgICAgIHtcbiAgICAgICAgICAgICAgICBsZXQgdXJpID0gZGVzY3JpcHRpb24uZ2V0QXR0cmlidXRlTlMoR2VvLlJERl9OUywgXCJhYm91dFwiKTtcbiAgICAgICAgICAgICAgICBsZXQgYm5vZGUgPSBkZXNjcmlwdGlvbi5nZXRBdHRyaWJ1dGVOUyhHZW8uUkRGX05TLCBcIm5vZGVJRFwiKTtcbiAgICAgICAgICAgICAgICBsZXQga2V5ID0gbnVsbDtcbiAgICAgICAgICAgICAgICBpZiAoYm5vZGUgIT09IG51bGwpIGtleSA9IHJkZlhtbC5kb2N1bWVudFVSSSArIFwiI1wiICsgYm5vZGU7XG4gICAgICAgICAgICAgICAgZWxzZSBrZXkgPSB1cmk7XG4gICAgICAgICAgICAgICAgXG4gICAgICAgICAgICAgICAgaWYgKCF0aGlzLmdldExvYWRlZFJlc291cmNlcygpLmhhcyhrZXkpKVxuICAgICAgICAgICAgICAgIHtcbiAgICAgICAgICAgICAgICAgICAgbGV0IGxhdEVsZW1zID0gZGVzY3JpcHRpb24uZ2V0RWxlbWVudHNCeVRhZ05hbWVOUyhHZW8uR0VPX05TLCBcImxhdFwiKTtcbiAgICAgICAgICAgICAgICAgICAgbGV0IGxvbmdFbGVtcyA9IGRlc2NyaXB0aW9uLmdldEVsZW1lbnRzQnlUYWdOYW1lTlMoR2VvLkdFT19OUywgXCJsb25nXCIpO1xuICAgICAgICAgICAgICAgICAgICBsZXQgdGl0bGVFbGVtcyA9IGRlc2NyaXB0aW9uLmdldEVsZW1lbnRzQnlUYWdOYW1lTlMoXCJodHRwOi8vcHVybC5vcmcvZGMvdGVybXMvXCIsIFwidGl0bGVcIik7XG4gICAgICAgICAgICAgICAgICAgIFxuICAgICAgICAgICAgICAgICAgICBpZiAobGF0RWxlbXMubGVuZ3RoID4gMCAmJiBsb25nRWxlbXMubGVuZ3RoID4gMCAmJiB0aXRsZUVsZW1zLmxlbmd0aCA+IDApXG4gICAgICAgICAgICAgICAgICAgIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIHRoaXMuZ2V0TG9hZGVkUmVzb3VyY2VzKCkuc2V0KGtleSwgdHJ1ZSk7IC8vIG1hcmsgcmVzb3VyY2UgYXMgbG9hZGVkXG5cbiAgICAgICAgICAgICAgICAgICAgICAgIGxldCBpY29uID0gbnVsbDtcbiAgICAgICAgICAgICAgICAgICAgICAgIGxldCB0eXBlID0gbnVsbDtcbiAgICAgICAgICAgICAgICAgICAgICAgIGxldCB0eXBlRWxlbXMgPSBkZXNjcmlwdGlvbi5nZXRFbGVtZW50c0J5VGFnTmFtZU5TKEdlby5SREZfTlMsIFwidHlwZVwiKTtcbiAgICAgICAgICAgICAgICAgICAgICAgIGlmICh0eXBlRWxlbXMubGVuZ3RoID4gMClcbiAgICAgICAgICAgICAgICAgICAgICAgIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB0eXBlID0gdHlwZUVsZW1zWzBdLmdldEF0dHJpYnV0ZU5TKEdlby5SREZfTlMsIFwicmVzb3VyY2VcIik7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgaWYgKCF0aGlzLmdldFR5cGVJY29ucygpLmhhcyh0eXBlKSlcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIC8vIGljb25zIGdldCByZWN5Y2xlZCB3aGVuICMgb2YgZGlmZmVyZW50IHR5cGVzIGluIHJlc3BvbnNlID4gIyBvZiBpY29uc1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBsZXQgaWNvbkluZGV4ID0gdGhpcy5nZXRUeXBlSWNvbnMoKS5zaXplICUgdGhpcy5nZXRJY29ucygpLmxlbmd0aDtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgaWNvbiA9IHRoaXMuZ2V0SWNvbnMoKVtpY29uSW5kZXhdO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB0aGlzLmdldFR5cGVJY29ucygpLnNldCh0eXBlLCBpY29uKTtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgZWxzZSBpY29uID0gdGhpcy5nZXRUeXBlSWNvbnMoKS5nZXQodHlwZSk7XG4gICAgICAgICAgICAgICAgICAgICAgICB9XG5cbiAgICAgICAgICAgICAgICAgICAgICAgIGxldCBsYXRMbmcgPSBuZXcgZ29vZ2xlLm1hcHMuTGF0TG5nKGxhdEVsZW1zWzBdLnRleHRDb250ZW50LCBsb25nRWxlbXNbMF0udGV4dENvbnRlbnQpO1xuICAgICAgICAgICAgICAgICAgICAgICAgbGV0IG1hcmtlckNvbmZpZyA9IDxnb29nbGUubWFwcy5SZWFkb25seU1hcmtlck9wdGlvbnM+e1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIFwicG9zaXRpb25cIjogbGF0TG5nLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIC8vIFwibGFiZWxcIjogbGFiZWwsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgXCJtYXBcIjogdGhpcy5nZXRNYXAoKSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBcInRpdGxlXCI6IHRpdGxlRWxlbXNbMF0udGV4dENvbnRlbnRcbiAgICAgICAgICAgICAgICAgICAgICAgIH0gO1xuICAgICAgICAgICAgICAgICAgICAgICAgbGV0IG1hcmtlciA9IG5ldyBnb29nbGUubWFwcy5NYXJrZXIobWFya2VyQ29uZmlnKTtcbiAgICAgICAgICAgICAgICAgICAgICAgIGlmIChpY29uICE9IG51bGwpIG1hcmtlci5zZXRJY29uKGljb24pO1xuICAgICAgICAgICAgICAgICAgICAgICAgXG4gICAgICAgICAgICAgICAgICAgICAgICAvLyBwb3BvdXQgSW5mb1dpbmRvdyBmb3IgdGhlIHRvcGljIG9mIGN1cnJlbnQgZG9jdW1lbnQgKHNhbWUgYXMgb24gY2xpY2spXG4gICAgICAgICAgICAgICAgICAgICAgICBsZXQgZG9jcyA9IGRlc2NyaXB0aW9uLmdldEVsZW1lbnRzQnlUYWdOYW1lTlMoR2VvLkZPQUZfTlMsIFwiaXNQcmltYXJ5VG9waWNPZlwiKTtcblxuICAgICAgICAgICAgICAgICAgICAgICAgaWYgKGRvY3MubGVuZ3RoID4gMCAmJiBkb2NzWzBdLmhhc0F0dHJpYnV0ZU5TKEdlby5SREZfTlMsIFwicmVzb3VyY2VcIikpXG4gICAgICAgICAgICAgICAgICAgICAgICB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgbGV0IGRvY1VyaSA9IGRvY3NbMF0uZ2V0QXR0cmlidXRlTlMoR2VvLlJERl9OUywgXCJyZXNvdXJjZVwiKTtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB0aGlzLmJpbmRNYXJrZXJDbGljayhtYXJrZXIsIGRvY1VyaSk7IC8vIGJpbmQgbG9hZEluZm9XaW5kb3dIVE1MKCkgdG8gbWFya2VyIG9uY2xpY2tcblxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIC8vaWYgKGRvY1VyaSA9PT0gdGhpcy5nZXRNYXAoKS5nZXREaXYoKS5vd25lckRvY3VtZW50LmRvY3VtZW50VVJJKSB0aGlzLmxvYWRJbmZvV2luZG93SFRNTChtYXJrZXIsIGRvY1VyaSk7XG4gICAgICAgICAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICB9XG4gICAgICAgIH1cbiAgICB9XG5cbiAgICBwcm90ZWN0ZWQgYmluZE1hcmtlckNsaWNrKG1hcmtlcjogZ29vZ2xlLm1hcHMuTWFya2VyLCB1cmw6IHN0cmluZyk6IHZvaWRcbiAgICB7XG4gICAgICAgIGxldCByZW5kZXJJbmZvV2luZG93ID0gKGV2ZW50OiBnb29nbGUubWFwcy5Nb3VzZUV2ZW50KSA9PlxuICAgICAgICB7XG4gICAgICAgICAgICBsZXQgb3ZlcmxheSA9IG5ldyBNYXBPdmVybGF5KHRoaXMuZ2V0TWFwKCksIFwiaW5mb3dpbmRvdy1wcm9ncmVzc1wiKTtcbiAgICAgICAgICAgIG92ZXJsYXkuc2hvdygpO1xuICAgICAgICAgICAgXG4gICAgICAgICAgICBQcm9taXNlLnJlc29sdmUodXJsKS5cbiAgICAgICAgICAgICAgICB0aGVuKHRoaXMuYnVpbGRJbmZvVVJMKS5cbiAgICAgICAgICAgICAgICB0aGVuKHVybCA9PiB1cmwudG9TdHJpbmcoKSkuXG4gICAgICAgICAgICAgICAgdGhlbih0aGlzLnJlcXVlc3RIVE1MKS5cbiAgICAgICAgICAgICAgICB0aGVuKHJlc3BvbnNlID0+IFxuICAgICAgICAgICAgICAgIHtcbiAgICAgICAgICAgICAgICAgICAgaWYocmVzcG9uc2Uub2spIHJldHVybiByZXNwb25zZS50ZXh0KCk7XG5cbiAgICAgICAgICAgICAgICAgICAgdGhyb3cgbmV3IEVycm9yKFwiQ291bGQgbm90IGxvYWQgSFRNTCByZXNwb25zZSBmcm9tICdcIiArIHJlc3BvbnNlLnVybCArIFwiJ1wiKTtcbiAgICAgICAgICAgICAgICB9KS5cbiAgICAgICAgICAgICAgICB0aGVuKHRoaXMucGFyc2VIVE1MKS5cbiAgICAgICAgICAgICAgICB0aGVuKGh0bWwgPT5cbiAgICAgICAgICAgICAgICB7XG4gICAgICAgICAgICAgICAgICAgIC8vIHJlbmRlciBmaXJzdCBjaGlsZCBvZiA8Ym9keT4gYXMgSW5mb1dpbmRvdyBjb250ZW50XG4gICAgICAgICAgICAgICAgICAgIGxldCBpbmZvQ29udGVudCA9IGh0bWwuZ2V0RWxlbWVudHNCeVRhZ05hbWVOUyhcImh0dHA6Ly93d3cudzMub3JnLzE5OTkveGh0bWxcIiwgXCJib2R5XCIpWzBdLmNoaWxkcmVuWzBdO1xuXG4gICAgICAgICAgICAgICAgICAgIGxldCBpbmZvV2luZG93ID0gbmV3IGdvb2dsZS5tYXBzLkluZm9XaW5kb3coeyBcImNvbnRlbnRcIiA6IGluZm9Db250ZW50IH0pO1xuICAgICAgICAgICAgICAgICAgICBvdmVybGF5LmhpZGUoKTtcbiAgICAgICAgICAgICAgICAgICAgaW5mb1dpbmRvdy5vcGVuKHRoaXMuZ2V0TWFwKCksIG1hcmtlcik7XG4gICAgICAgICAgICAgICAgfSkuXG4gICAgICAgICAgICAgICAgY2F0Y2goZXJyb3IgPT5cbiAgICAgICAgICAgICAgICB7XG4gICAgICAgICAgICAgICAgICAgIGNvbnNvbGUubG9nKCdIVFRQIHJlcXVlc3QgZmFpbGVkOiAnLCBlcnJvci5tZXNzYWdlKTtcbiAgICAgICAgICAgICAgICB9KTtcbiAgICAgICAgfVxuXG4gICAgICAgIG1hcmtlci5hZGRMaXN0ZW5lcihcImNsaWNrXCIsIHJlbmRlckluZm9XaW5kb3cpO1xuICAgIH1cblxuICAgIHByb3RlY3RlZCBidWlsZEdlb0JvdW5kZXJRdWVyeShzZWxlY3RRdWVyeTogU2VsZWN0UXVlcnksIGl0ZW1WYXJOYW1lOiBzdHJpbmcsIGVhc3Q6IG51bWJlciwgbm9ydGg6IG51bWJlciwgc291dGg6IG51bWJlciwgd2VzdDogbnVtYmVyKTogRGVzY3JpYmVCdWlsZGVyXG4gICAge1xuICAgICAgICByZXR1cm4gPERlc2NyaWJlQnVpbGRlcj5EZXNjcmliZUJ1aWxkZXIubmV3KCkuXG4gICAgICAgICAgICB3aGVyZShEZXNjcmliZUJ1aWxkZXIuZ3JvdXAoWyBzZWxlY3RRdWVyeSBdKSkuXG4gICAgICAgICAgICB3aGVyZShTZWxlY3RCdWlsZGVyLmdyYXBoKFNlbGVjdEJ1aWxkZXIudmFyKFwiY2hpbGRHcmFwaFwiKSxcbiAgICAgICAgICAgICAgICBbXG4gICAgICAgICAgICAgICAgICAgIFNlbGVjdEJ1aWxkZXIuYmdwKFxuICAgICAgICAgICAgICAgICAgICAgICAgW1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIFNlbGVjdEJ1aWxkZXIudHJpcGxlKFNlbGVjdEJ1aWxkZXIudmFyKGl0ZW1WYXJOYW1lKSwgU2VsZWN0QnVpbGRlci51cmkoR2VvLkdFT19OUyArIFwibGF0XCIpLCBTZWxlY3RCdWlsZGVyLnZhcihcImxhdFwiKSksXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgU2VsZWN0QnVpbGRlci50cmlwbGUoU2VsZWN0QnVpbGRlci52YXIoaXRlbVZhck5hbWUpLCBTZWxlY3RCdWlsZGVyLnVyaShHZW8uR0VPX05TICsgXCJsb25nXCIpLCBTZWxlY3RCdWlsZGVyLnZhcihcImxvbmdcIikpXG4gICAgICAgICAgICAgICAgICAgICAgICBdKSxcbiAgICAgICAgICAgICAgICAgICAgU2VsZWN0QnVpbGRlci5maWx0ZXIoU2VsZWN0QnVpbGRlci5vcGVyYXRpb24oXCI8XCIsIFsgU2VsZWN0QnVpbGRlci52YXIoXCJsb25nXCIpLCBTZWxlY3RCdWlsZGVyLnR5cGVkTGl0ZXJhbChlYXN0LnRvU3RyaW5nKCksIEdlby5YU0RfTlMgKyBcImRlY2ltYWxcIikgXSkpLFxuICAgICAgICAgICAgICAgICAgICBTZWxlY3RCdWlsZGVyLmZpbHRlcihTZWxlY3RCdWlsZGVyLm9wZXJhdGlvbihcIjxcIiwgWyBTZWxlY3RCdWlsZGVyLnZhcihcImxhdFwiKSwgU2VsZWN0QnVpbGRlci50eXBlZExpdGVyYWwobm9ydGgudG9TdHJpbmcoKSwgR2VvLlhTRF9OUyArIFwiZGVjaW1hbFwiKSBdKSksXG4gICAgICAgICAgICAgICAgICAgIFNlbGVjdEJ1aWxkZXIuZmlsdGVyKFNlbGVjdEJ1aWxkZXIub3BlcmF0aW9uKFwiPlwiLCBbIFNlbGVjdEJ1aWxkZXIudmFyKFwibGF0XCIpLCBTZWxlY3RCdWlsZGVyLnR5cGVkTGl0ZXJhbChzb3V0aC50b1N0cmluZygpLCBHZW8uWFNEX05TICsgXCJkZWNpbWFsXCIpIF0pKSxcbiAgICAgICAgICAgICAgICAgICAgU2VsZWN0QnVpbGRlci5maWx0ZXIoU2VsZWN0QnVpbGRlci5vcGVyYXRpb24oXCI+XCIsIFsgU2VsZWN0QnVpbGRlci52YXIoXCJsb25nXCIpLCBTZWxlY3RCdWlsZGVyLnR5cGVkTGl0ZXJhbCh3ZXN0LnRvU3RyaW5nKCksIEdlby5YU0RfTlMgKyBcImRlY2ltYWxcIikgXSkpXG4gICAgICAgICAgICAgICAgXVxuICAgICAgICAgICAgKSk7XG4gICAgfVxuXG4gICAgcHVibGljIGJ1aWxkUXVlcnkgPSAoc2VsZWN0UXVlcnk6IFNlbGVjdFF1ZXJ5KTogUXVlcnlCdWlsZGVyID0+XG4gICAge1xuICAgICAgICByZXR1cm4gdGhpcy5idWlsZEdlb0JvdW5kZXJRdWVyeShzZWxlY3RRdWVyeSxcbiAgICAgICAgICAgIHRoaXMuZ2V0SXRlbVZhck5hbWUoKSxcbiAgICAgICAgICAgIHRoaXMuZ2V0TWFwKCkuZ2V0Qm91bmRzKCkhLmdldE5vcnRoRWFzdCgpLmxuZygpLFxuICAgICAgICAgICAgdGhpcy5nZXRNYXAoKS5nZXRCb3VuZHMoKSEuZ2V0Tm9ydGhFYXN0KCkubGF0KCksXG4gICAgICAgICAgICB0aGlzLmdldE1hcCgpLmdldEJvdW5kcygpIS5nZXRTb3V0aFdlc3QoKS5sYXQoKSxcbiAgICAgICAgICAgIHRoaXMuZ2V0TWFwKCkuZ2V0Qm91bmRzKCkhLmdldFNvdXRoV2VzdCgpLmxuZygpKTtcbiAgICB9XG5cbiAgICBwdWJsaWMgYnVpbGRRdWVyeVVSTCA9IChxdWVyeUJ1aWxkZXI6IFF1ZXJ5QnVpbGRlcik6IFVSTCA9PlxuICAgIHtcbiAgICAgICAgcmV0dXJuIFVSTEJ1aWxkZXIuZnJvbVVSTCh0aGlzLmdldEVuZHBvaW50KCkpLlxuICAgICAgICAgICAgc2VhcmNoUGFyYW0oXCJxdWVyeVwiLCBxdWVyeUJ1aWxkZXIudG9TdHJpbmcoKSkuXG4gICAgICAgICAgICBidWlsZCgpO1xuICAgIH1cblxuICAgIHB1YmxpYyBidWlsZEluZm9VUkwodXJsOiBzdHJpbmcpOiBVUkxcbiAgICB7XG4gICAgICAgIHJldHVybiBVUkxCdWlsZGVyLmZyb21TdHJpbmcodXJsKS5cbiAgICAgICAgICAgIHNlYXJjaFBhcmFtKFwibW9kZVwiLCBHZW8uQVBMVF9OUyArIFwiSW5mb1dpbmRvd01vZGVcIikuXG4gICAgICAgICAgICBoYXNoKG51bGwpLlxuICAgICAgICAgICAgYnVpbGQoKTtcbiAgICB9XG5cbiAgICBwdWJsaWMgcmVxdWVzdFJERlhNTCA9ICh1cmw6IHN0cmluZyk6IFByb21pc2U8UmVzcG9uc2U+ID0+XG4gICAge1xuICAgICAgICByZXR1cm4gZmV0Y2gobmV3IFJlcXVlc3QodXJsLCB7IFwiaGVhZGVyc1wiOiB7IFwiQWNjZXB0XCI6IFwiYXBwbGljYXRpb24vcmRmK3htbFwiIH0gfSApKTtcbiAgICB9XG5cbiAgICBwdWJsaWMgcmVxdWVzdEhUTUwgPSAodXJsOiBzdHJpbmcpOiBQcm9taXNlPFJlc3BvbnNlPiA9PlxuICAgIHtcbiAgICAgICAgcmV0dXJuIGZldGNoKG5ldyBSZXF1ZXN0KHVybCwgeyBcImhlYWRlcnNcIjogeyBcIkFjY2VwdFwiOiBcInRleHQvaHRtbCwqLyo7cT0wLjhcIiB9IH0gKSk7XG4gICAgfVxuXG4gICAgcHVibGljIHBhcnNlWE1MKHN0cjogc3RyaW5nKTogRG9jdW1lbnRcbiAgICB7XG4gICAgICAgIHJldHVybiAobmV3IERPTVBhcnNlcigpKS5wYXJzZUZyb21TdHJpbmcoc3RyLCBcInRleHQveG1sXCIpO1xuICAgIH1cblxuICAgIHB1YmxpYyBwYXJzZUhUTUwoc3RyOiBzdHJpbmcpOiBEb2N1bWVudFxuICAgIHtcbiAgICAgICAgcmV0dXJuIChuZXcgRE9NUGFyc2VyKCkpLnBhcnNlRnJvbVN0cmluZyhzdHIsIFwidGV4dC9odG1sXCIpO1xuICAgIH1cblxufSIsIi8vLyA8cmVmZXJlbmNlIHR5cGVzPVwiZ29vZ2xlbWFwc1wiIC8+XG5cbi8vIGltcG9ydCB7IE1hcCB9IGZyb20gJ2dvb2dsZW1hcHMnOyAvLyB1c2luZyA8cmVmZXJlbmNlPiBpbnN0ZWFkIGFzIG90aGVyd2lzZSB3ZSB3b3VsZCBnZXQgdGhlIFwiQHR5cGVzL2dvb2dsZW1hcHMvaW5kZXguZC50cyBpcyBub3QgYSBtb2R1bGVcIiBlcnJvclxuXG5leHBvcnQgY2xhc3MgTWFwT3ZlcmxheVxue1xuXG4gICAgcHJpdmF0ZSByZWFkb25seSBkaXY6IEhUTUxFbGVtZW50O1xuXG4gICAgY29uc3RydWN0b3IobWFwOiBnb29nbGUubWFwcy5NYXAsIGlkOiBzdHJpbmcpXG4gICAge1xuICAgICAgICBsZXQgZGl2ID0gbWFwLmdldERpdigpLm93bmVyRG9jdW1lbnQhLmdldEVsZW1lbnRCeUlkKGlkKTtcblxuICAgICAgICBpZiAoZGl2ICE9PSBudWxsKSB0aGlzLmRpdiA9IGRpdjtcbiAgICAgICAgZWxzZVxuICAgICAgICB7XG4gICAgICAgICAgICB0aGlzLmRpdiA9IG1hcC5nZXREaXYoKS5vd25lckRvY3VtZW50IS5jcmVhdGVFbGVtZW50KFwiZGl2XCIpO1xuICAgICAgICAgICAgdGhpcy5kaXYuaWQgPSBpZDtcbiAgICAgICAgICAgIHRoaXMuZGl2LmNsYXNzTmFtZSA9IFwicHJvZ3Jlc3MgcHJvZ3Jlc3Mtc3RyaXBlZCBhY3RpdmVcIjtcbiAgICAgICAgICAgIFxuICAgICAgICAgICAgLy8gbmVlZCB0byBzZXQgQ1NTIHByb3BlcnRpZXMgcHJvZ3JhbW1hdGljYWxseVxuICAgICAgICAgICAgdGhpcy5kaXYuc3R5bGUucG9zaXRpb24gPSBcImFic29sdXRlXCI7XG4gICAgICAgICAgICB0aGlzLmRpdi5zdHlsZS50b3AgPSBcIjE3ZW1cIjtcbiAgICAgICAgICAgIHRoaXMuZGl2LnN0eWxlLnpJbmRleCA9IFwiMlwiO1xuICAgICAgICAgICAgdGhpcy5kaXYuc3R5bGUud2lkdGggPSBcIjI0JVwiO1xuICAgICAgICAgICAgdGhpcy5kaXYuc3R5bGUubGVmdCA9IFwiMzglXCI7XG4gICAgICAgICAgICB0aGlzLmRpdi5zdHlsZS5yaWdodCA9IFwiMzglXCI7XG4gICAgICAgICAgICB0aGlzLmRpdi5zdHlsZS5wYWRkaW5nID0gXCIxMHB4XCI7XG4gICAgICAgICAgICB0aGlzLmRpdi5zdHlsZS52aXNpYmlsaXR5ID0gXCJoaWRkZW5cIjtcbiAgICAgICAgICAgIFxuICAgICAgICAgICAgdmFyIGJhckRpdiA9IG1hcC5nZXREaXYoKS5vd25lckRvY3VtZW50IS5jcmVhdGVFbGVtZW50KFwiZGl2XCIpO1xuICAgICAgICAgICAgYmFyRGl2LmNsYXNzTmFtZSA9IFwiYmFyXCI7XG4gICAgICAgICAgICBiYXJEaXYuc3R5bGUud2lkdGggPSBcIjEwMCVcIjtcbiAgICAgICAgICAgIHRoaXMuZGl2LmFwcGVuZENoaWxkKGJhckRpdik7XG4gICAgICAgICAgICBcbiAgICAgICAgICAgIG1hcC5nZXREaXYoKS5hcHBlbmRDaGlsZCh0aGlzLmRpdik7XG4gICAgICAgIH1cbiAgICB9XG5cbiAgICBwdWJsaWMgc2hvdygpOiB2b2lkXG4gICAge1xuICAgICAgICB0aGlzLmRpdi5zdHlsZS52aXNpYmlsaXR5ID0gXCJ2aXNpYmxlXCI7XG4gICAgfTtcblxuICAgIHB1YmxpYyBoaWRlKCk6IHZvaWRcbiAgICB7XG4gICAgICAgIHRoaXMuZGl2LnN0eWxlLnZpc2liaWxpdHkgPSBcImhpZGRlblwiO1xuICAgIH07XG5cbn0iLCIvKiAoaWdub3JlZCkgKi8iLCIvKiAoaWdub3JlZCkgKi8iXSwic291cmNlUm9vdCI6IiJ9