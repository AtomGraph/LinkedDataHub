window["SPARQLBuilder"] =
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
/******/ 	return __webpack_require__(__webpack_require__.s = "./src/com/atomgraph/linkeddatahub/query/SPARQLBuilder.ts");
/******/ })
/************************************************************************/
/******/ ({

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

/***/ "./node_modules/sparqljs/lib/SparqlGenerator.js":
/*!******************************************************!*\
  !*** ./node_modules/sparqljs/lib/SparqlGenerator.js ***!
  \******************************************************/
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

/***/ "./node_modules/sparqljs/lib/SparqlParser.js":
/*!***************************************************!*\
  !*** ./node_modules/sparqljs/lib/SparqlParser.js ***!
  \***************************************************/
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
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(/*! ./../../process/browser.js */ "./node_modules/process/browser.js"), __webpack_require__(/*! ./../../webpack/buildin/module.js */ "./node_modules/webpack/buildin/module.js")(module)))

/***/ }),

/***/ "./node_modules/sparqljs/sparql.js":
/*!*****************************************!*\
  !*** ./node_modules/sparqljs/sparql.js ***!
  \*****************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

var Parser = __webpack_require__(/*! ./lib/SparqlParser */ "./node_modules/sparqljs/lib/SparqlParser.js").Parser;
var Generator = __webpack_require__(/*! ./lib/SparqlGenerator */ "./node_modules/sparqljs/lib/SparqlGenerator.js");

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

/***/ "./src/com/atomgraph/linkeddatahub/query/DescribeBuilder.ts":
/*!******************************************************************!*\
  !*** ./src/com/atomgraph/linkeddatahub/query/DescribeBuilder.ts ***!
  \******************************************************************/
/*! exports provided: DescribeBuilder */
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "DescribeBuilder", function() { return DescribeBuilder; });
/* harmony import */ var sparqljs__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! sparqljs */ "./node_modules/sparqljs/sparql.js");
/* harmony import */ var sparqljs__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(sparqljs__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var _QueryBuilder__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ./QueryBuilder */ "./src/com/atomgraph/linkeddatahub/query/QueryBuilder.ts");


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

/***/ "./src/com/atomgraph/linkeddatahub/query/QueryBuilder.ts":
/*!***************************************************************!*\
  !*** ./src/com/atomgraph/linkeddatahub/query/QueryBuilder.ts ***!
  \***************************************************************/
/*! exports provided: QueryBuilder */
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "QueryBuilder", function() { return QueryBuilder; });
/* harmony import */ var sparqljs__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! sparqljs */ "./node_modules/sparqljs/sparql.js");
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

/***/ "./src/com/atomgraph/linkeddatahub/query/SPARQLBuilder.ts":
/*!****************************************************************!*\
  !*** ./src/com/atomgraph/linkeddatahub/query/SPARQLBuilder.ts ***!
  \****************************************************************/
/*! exports provided: QueryBuilder, SelectBuilder, DescribeBuilder */
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _QueryBuilder__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./QueryBuilder */ "./src/com/atomgraph/linkeddatahub/query/QueryBuilder.ts");
/* harmony reexport (safe) */ __webpack_require__.d(__webpack_exports__, "QueryBuilder", function() { return _QueryBuilder__WEBPACK_IMPORTED_MODULE_0__["QueryBuilder"]; });

/* harmony import */ var _SelectBuilder__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ./SelectBuilder */ "./src/com/atomgraph/linkeddatahub/query/SelectBuilder.ts");
/* harmony reexport (safe) */ __webpack_require__.d(__webpack_exports__, "SelectBuilder", function() { return _SelectBuilder__WEBPACK_IMPORTED_MODULE_1__["SelectBuilder"]; });

/* harmony import */ var _DescribeBuilder__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! ./DescribeBuilder */ "./src/com/atomgraph/linkeddatahub/query/DescribeBuilder.ts");
/* harmony reexport (safe) */ __webpack_require__.d(__webpack_exports__, "DescribeBuilder", function() { return _DescribeBuilder__WEBPACK_IMPORTED_MODULE_2__["DescribeBuilder"]; });






/***/ }),

/***/ "./src/com/atomgraph/linkeddatahub/query/SelectBuilder.ts":
/*!****************************************************************!*\
  !*** ./src/com/atomgraph/linkeddatahub/query/SelectBuilder.ts ***!
  \****************************************************************/
/*! exports provided: SelectBuilder */
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "SelectBuilder", function() { return SelectBuilder; });
/* harmony import */ var sparqljs__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! sparqljs */ "./node_modules/sparqljs/sparql.js");
/* harmony import */ var sparqljs__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(sparqljs__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var _QueryBuilder__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ./QueryBuilder */ "./src/com/atomgraph/linkeddatahub/query/QueryBuilder.ts");


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
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIndlYnBhY2s6Ly9TUEFSUUxCdWlsZGVyL3dlYnBhY2svYm9vdHN0cmFwIiwid2VicGFjazovL1NQQVJRTEJ1aWxkZXIvLi9ub2RlX21vZHVsZXMvcHJvY2Vzcy9icm93c2VyLmpzIiwid2VicGFjazovL1NQQVJRTEJ1aWxkZXIvLi9ub2RlX21vZHVsZXMvc3BhcnFsanMvbGliL1NwYXJxbEdlbmVyYXRvci5qcyIsIndlYnBhY2s6Ly9TUEFSUUxCdWlsZGVyLy4vbm9kZV9tb2R1bGVzL3NwYXJxbGpzL2xpYi9TcGFycWxQYXJzZXIuanMiLCJ3ZWJwYWNrOi8vU1BBUlFMQnVpbGRlci8uL25vZGVfbW9kdWxlcy9zcGFycWxqcy9zcGFycWwuanMiLCJ3ZWJwYWNrOi8vU1BBUlFMQnVpbGRlci8od2VicGFjaykvYnVpbGRpbi9tb2R1bGUuanMiLCJ3ZWJwYWNrOi8vU1BBUlFMQnVpbGRlci8uL3NyYy9jb20vYXRvbWdyYXBoL2xpbmtlZGRhdGFodWIvcXVlcnkvRGVzY3JpYmVCdWlsZGVyLnRzIiwid2VicGFjazovL1NQQVJRTEJ1aWxkZXIvLi9zcmMvY29tL2F0b21ncmFwaC9saW5rZWRkYXRhaHViL3F1ZXJ5L1F1ZXJ5QnVpbGRlci50cyIsIndlYnBhY2s6Ly9TUEFSUUxCdWlsZGVyLy4vc3JjL2NvbS9hdG9tZ3JhcGgvbGlua2VkZGF0YWh1Yi9xdWVyeS9TUEFSUUxCdWlsZGVyLnRzIiwid2VicGFjazovL1NQQVJRTEJ1aWxkZXIvLi9zcmMvY29tL2F0b21ncmFwaC9saW5rZWRkYXRhaHViL3F1ZXJ5L1NlbGVjdEJ1aWxkZXIudHMiLCJ3ZWJwYWNrOi8vU1BBUlFMQnVpbGRlci9mcyAoaWdub3JlZCkiLCJ3ZWJwYWNrOi8vU1BBUlFMQnVpbGRlci9wYXRoIChpZ25vcmVkKSJdLCJuYW1lcyI6W10sIm1hcHBpbmdzIjoiOztBQUFBO0FBQ0E7O0FBRUE7QUFDQTs7QUFFQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7QUFF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QUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0EsK0RBQStEO0FBQy9EO0FBQ0E7QUFDQTtBQUNBO0FBQ0EsU0FBUztBQUNUO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBLGlCQUFpQjtBQUNqQjtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0EsaUJBQWlCO0FBQ2pCO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0EsYUFBYTtBQUNiO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7QUFFQTtBQUNBO0FBQ0E7O0FBRUE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7O0FBRUE7O0FBRUE7QUFDQTtBQUNBO0FBQ0E7O0FBRUE7QUFDQTtBQUNBO0FBQ0E7O0FBRUE7QUFDQTtBQUNBO0FBQ0E7O0FBRUE7QUFDQTtBQUNBO0FBQ0EsOENBQThDLG1DQUFtQyxFQUFFO0FBQ25GO0FBQ0E7QUFDQTtBQUNBOztBQUVBO0FBQ0E7QUFDQTtBQUNBLHlDQUF5QyxPQUFPO0FBQ2hEO0FBQ0E7QUFDQTs7QUFFQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7O0FBRUE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOztBQUVBO0FBQ0E7QUFDQSxZQUFZO0FBQ1o7O0FBRUE7QUFDQTtBQUNBLHNCQUFzQjtBQUN0QjtBQUNBO0FBQ0E7QUFDQTtBQUNBOztBQUVBO0FBQ0E7QUFDQSxZQUFZO0FBQ1o7O0FBRUE7QUFDQTtBQUNBLG1EQUFtRCxvQ0FBb0M7QUFDdkY7QUFDQTtBQUNBOztBQUVBO0FBQ0E7QUFDQTtBQUNBLG1CQUFtQix3Q0FBd0M7QUFDM0Q7QUFDQSxnQkFBZ0IsUUFBUSxrQ0FBa0MsRUFBRTtBQUM1RDs7QUFFQTtBQUNBO0FBQ0E7QUFDQTs7QUFFQTtBQUNBO0FBQ0E7QUFDQTs7QUFFQTtBQUNBO0FBQ0E7QUFDQTs7QUFFQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOztBQUVBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQSxxQ0FBcUMsYUFBYTs7QUFFbEQ7QUFDQSx3Q0FBd0MsRUFBRSxrQkFBa0IsRUFBRTtBQUM5RCw0QkFBNEI7QUFDNUIsb0ZBQW9GO0FBQ3BGOztBQUVBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQSxpREFBaUQ7QUFDakQ7QUFDQTtBQUNBO0FBQ0E7QUFDQSxpREFBaUQ7QUFDakQ7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBLE9BQU87QUFDUDtBQUNBLG1CQUFtQixXQUFXO0FBQzlCO0FBQ0E7O0FBRUE7QUFDQTtBQUNBO0FBQ0Esa0NBQWtDLDBCQUEwQixpQ0FBaUMsRUFBRTs7QUFFL0Y7QUFDQSw0RUFBNEUsT0FBTztBQUNuRjtBQUNBOztBQUVBO0FBQ0EsWUFBWTtBQUNaOztBQUVBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQSw4Q0FBOEMsa0NBQWtDLEVBQUU7QUFDbEY7QUFDQTs7QUFFQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQSxLQUFLO0FBQ0w7QUFDQTs7QUFFQTtBQUNBO0FBQ0E7QUFDQSwwQkFBMEIsbUJBQW1CO0FBQzdDO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7QUFFQTs7QUFFQTtBQUNBO0FBQ0E7QUFDQSxTQUFTO0FBQ1Q7QUFDQTtBQUNBLEtBQUs7O0FBRUw7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQSxLQUFLOztBQUVMO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBLFNBQVM7QUFDVDtBQUNBO0FBQ0E7QUFDQTtBQUNBOztBQUVBO0FBQ0E7QUFDQSxLQUFLOztBQUVMO0FBQ0E7QUFDQTtBQUNBOztBQUVBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOztBQUVBO0FBQ0E7QUFDQTtBQUNBOztBQUVBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7QUFFQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0EsS0FBSzs7QUFFTDtBQUNBO0FBQ0E7QUFDQTtBQUNBLEtBQUs7O0FBRUw7QUFDQTtBQUNBO0FBQ0E7QUFDQSxTQUFTO0FBQ1Q7QUFDQTtBQUNBO0FBQ0E7QUFDQSxhQUFhOztBQUViO0FBQ0E7QUFDQSxLQUFLOztBQUVMO0FBQ0E7QUFDQTtBQUNBLEtBQUs7O0FBRUw7QUFDQTtBQUNBO0FBQ0E7QUFDQSxLQUFLOztBQUVMO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0EsS0FBSzs7QUFFTDtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0EsS0FBSzs7QUFFTDtBQUNBO0FBQ0E7QUFDQTtBQUNBOztBQUVBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBLGlCQUFpQjtBQUNqQjtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7QUFFQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0EsU0FBUztBQUNUO0FBQ0E7QUFDQTtBQUNBO0FBQ0EseUJBQXlCO0FBQ3pCO0FBQ0E7QUFDQSxLQUFLOztBQUVMO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7O0FBRUE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0EsdUJBQXVCLGtCQUFrQjtBQUN6QztBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0EscUJBQXFCO0FBQ3JCO0FBQ0EsaUNBQWlDO0FBQ2pDLHFCQUFxQjtBQUNyQjtBQUNBO0FBQ0E7QUFDQSxpQkFBaUI7QUFDakI7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBLFNBQVM7QUFDVDtBQUNBO0FBQ0E7QUFDQTtBQUNBLGFBQWE7QUFDYjtBQUNBLEtBQUs7O0FBRUw7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBLFNBQVM7QUFDVDtBQUNBO0FBQ0EsS0FBSzs7QUFFTDtBQUNBO0FBQ0E7QUFDQSxLQUFLOztBQUVMO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQSxTQUFTO0FBQ1Q7QUFDQTtBQUNBLEtBQUs7O0FBRUw7QUFDQTtBQUNBO0FBQ0E7QUFDQSxTQUFTO0FBQ1Q7QUFDQTtBQUNBLEtBQUs7O0FBRUwscURBQXFEO0FBQ3JEO0FBQ0E7QUFDQTtBQUNBO0FBQ0EsU0FBUztBQUNUO0FBQ0E7QUFDQSxLQUFLOztBQUVMO0FBQ0E7QUFDQTtBQUNBLEtBQUs7O0FBRUw7QUFDQTtBQUNBO0FBQ0EsS0FBSztBQUNMLFVBQVUsb0NBQW9DO0FBQzlDO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FB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RUFBRSxJQUFjO1FBRW5ELElBQUksUUFBUSxHQUFhO1lBQ3ZCLFlBQVksRUFBRSxJQUFJO1NBQ25CLENBQUM7UUFFRixJQUFJLElBQUksS0FBSyxTQUFTLElBQUksSUFBSSxJQUFJLElBQUk7WUFBRSxRQUFRLENBQUMsVUFBVSxHQUFHLElBQUksQ0FBQztRQUVuRSxPQUFPLFFBQVEsQ0FBQztJQUNwQixDQUFDO0NBRUo7Ozs7Ozs7Ozs7OztBQ3hGRCxlOzs7Ozs7Ozs7OztBQ0FBLGUiLCJmaWxlIjoiU1BBUlFMQnVpbGRlci5qcyIsInNvdXJjZXNDb250ZW50IjpbIiBcdC8vIFRoZSBtb2R1bGUgY2FjaGVcbiBcdHZhciBpbnN0YWxsZWRNb2R1bGVzID0ge307XG5cbiBcdC8vIFRoZSByZXF1aXJlIGZ1bmN0aW9uXG4gXHRmdW5jdGlvbiBfX3dlYnBhY2tfcmVxdWlyZV9fKG1vZHVsZUlkKSB7XG5cbiBcdFx0Ly8gQ2hlY2sgaWYgbW9kdWxlIGlzIGluIGNhY2hlXG4gXHRcdGlmKGluc3RhbGxlZE1vZHVsZXNbbW9kdWxlSWRdKSB7XG4gXHRcdFx0cmV0dXJuIGluc3RhbGxlZE1vZHVsZXNbbW9kdWxlSWRdLmV4cG9ydHM7XG4gXHRcdH1cbiBcdFx0Ly8gQ3JlYXRlIGEgbmV3IG1vZHVsZSAoYW5kIHB1dCBpdCBpbnRvIHRoZSBjYWNoZSlcbiBcdFx0dmFyIG1vZHVsZSA9IGluc3RhbGxlZE1vZHVsZXNbbW9kdWxlSWRdID0ge1xuIFx0XHRcdGk6IG1vZHVsZUlkLFxuIFx0XHRcdGw6IGZhbHNlLFxuIFx0XHRcdGV4cG9ydHM6IHt9XG4gXHRcdH07XG5cbiBcdFx0Ly8gRXhlY3V0ZSB0aGUgbW9kdWxlIGZ1bmN0aW9uXG4gXHRcdG1vZHVsZXNbbW9kdWxlSWRdLmNhbGwobW9kdWxlLmV4cG9ydHMsIG1vZHVsZSwgbW9kdWxlLmV4cG9ydHMsIF9fd2VicGFja19yZXF1aXJlX18pO1xuXG4gXHRcdC8vIEZsYWcgdGhlIG1vZHVsZSBhcyBsb2FkZWRcbiBcdFx0bW9kdWxlLmwgPSB0cnVlO1xuXG4gXHRcdC8vIFJldHVybiB0aGUgZXhwb3J0cyBvZiB0aGUgbW9kdWxlXG4gXHRcdHJldHVybiBtb2R1bGUuZXhwb3J0cztcbiBcdH1cblxuXG4gXHQvLyBleHBvc2UgdGhlIG1vZHVsZXMgb2JqZWN0IChfX3dlYnBhY2tfbW9kdWxlc19fKVxuIFx0X193ZWJwYWNrX3JlcXVpcmVfXy5tID0gbW9kdWxlcztcblxuIFx0Ly8gZXhwb3NlIHRoZSBtb2R1bGUgY2FjaGVcbiBcdF9fd2VicGFja19yZXF1aXJlX18uYyA9IGluc3RhbGxlZE1vZHVsZXM7XG5cbiBcdC8vIGRlZmluZSBnZXR0ZXIgZnVuY3Rpb24gZm9yIGhhcm1vbnkgZXhwb3J0c1xuIFx0X193ZWJwYWNrX3JlcXVpcmVfXy5kID0gZnVuY3Rpb24oZXhwb3J0cywgbmFtZSwgZ2V0dGVyKSB7XG4gXHRcdGlmKCFfX3dlYnBhY2tfcmVxdWlyZV9fLm8oZXhwb3J0cywgbmFtZSkpIHtcbiBcdFx0XHRPYmplY3QuZGVmaW5lUHJvcGVydHkoZXhwb3J0cywgbmFtZSwgeyBlbnVtZXJhYmxlOiB0cnVlLCBnZXQ6IGdldHRlciB9KTtcbiBcdFx0fVxuIFx0fTtcblxuIFx0Ly8gZGVmaW5lIF9fZXNNb2R1bGUgb24gZXhwb3J0c1xuIFx0X193ZWJwYWNrX3JlcXVpcmVfXy5yID0gZnVuY3Rpb24oZXhwb3J0cykge1xuIFx0XHRpZih0eXBlb2YgU3ltYm9sICE9PSAndW5kZWZpbmVkJyAmJiBTeW1ib2wudG9TdHJpbmdUYWcpIHtcbiBcdFx0XHRPYmplY3QuZGVmaW5lUHJvcGVydHkoZXhwb3J0cywgU3ltYm9sLnRvU3RyaW5nVGFnLCB7IHZhbHVlOiAnTW9kdWxlJyB9KTtcbiBcdFx0fVxuIFx0XHRPYmplY3QuZGVmaW5lUHJvcGVydHkoZXhwb3J0cywgJ19fZXNNb2R1bGUnLCB7IHZhbHVlOiB0cnVlIH0pO1xuIFx0fTtcblxuIFx0Ly8gY3JlYXRlIGEgZmFrZSBuYW1lc3BhY2Ugb2JqZWN0XG4gXHQvLyBtb2RlICYgMTogdmFsdWUgaXMgYSBtb2R1bGUgaWQsIHJlcXVpcmUgaXRcbiBcdC8vIG1vZGUgJiAyOiBtZXJnZSBhbGwgcHJvcGVydGllcyBvZiB2YWx1ZSBpbnRvIHRoZSBuc1xuIFx0Ly8gbW9kZSAmIDQ6IHJldHVybiB2YWx1ZSB3aGVuIGFscmVhZHkgbnMgb2JqZWN0XG4gXHQvLyBtb2RlICYgOHwxOiBiZWhhdmUgbGlrZSByZXF1aXJlXG4gXHRfX3dlYnBhY2tfcmVxdWlyZV9fLnQgPSBmdW5jdGlvbih2YWx1ZSwgbW9kZSkge1xuIFx0XHRpZihtb2RlICYgMSkgdmFsdWUgPSBfX3dlYnBhY2tfcmVxdWlyZV9fKHZhbHVlKTtcbiBcdFx0aWYobW9kZSAmIDgpIHJldHVybiB2YWx1ZTtcbiBcdFx0aWYoKG1vZGUgJiA0KSAmJiB0eXBlb2YgdmFsdWUgPT09ICdvYmplY3QnICYmIHZhbHVlICYmIHZhbHVlLl9fZXNNb2R1bGUpIHJldHVybiB2YWx1ZTtcbiBcdFx0dmFyIG5zID0gT2JqZWN0LmNyZWF0ZShudWxsKTtcbiBcdFx0X193ZWJwYWNrX3JlcXVpcmVfXy5yKG5zKTtcbiBcdFx0T2JqZWN0LmRlZmluZVByb3BlcnR5KG5zLCAnZGVmYXVsdCcsIHsgZW51bWVyYWJsZTogdHJ1ZSwgdmFsdWU6IHZhbHVlIH0pO1xuIFx0XHRpZihtb2RlICYgMiAmJiB0eXBlb2YgdmFsdWUgIT0gJ3N0cmluZycpIGZvcih2YXIga2V5IGluIHZhbHVlKSBfX3dlYnBhY2tfcmVxdWlyZV9fLmQobnMsIGtleSwgZnVuY3Rpb24oa2V5KSB7IHJldHVybiB2YWx1ZVtrZXldOyB9LmJpbmQobnVsbCwga2V5KSk7XG4gXHRcdHJldHVybiBucztcbiBcdH07XG5cbiBcdC8vIGdldERlZmF1bHRFeHBvcnQgZnVuY3Rpb24gZm9yIGNvbXBhdGliaWxpdHkgd2l0aCBub24taGFybW9ueSBtb2R1bGVzXG4gXHRfX3dlYnBhY2tfcmVxdWlyZV9fLm4gPSBmdW5jdGlvbihtb2R1bGUpIHtcbiBcdFx0dmFyIGdldHRlciA9IG1vZHVsZSAmJiBtb2R1bGUuX19lc01vZHVsZSA/XG4gXHRcdFx0ZnVuY3Rpb24gZ2V0RGVmYXVsdCgpIHsgcmV0dXJuIG1vZHVsZVsnZGVmYXVsdCddOyB9IDpcbiBcdFx0XHRmdW5jdGlvbiBnZXRNb2R1bGVFeHBvcnRzKCkgeyByZXR1cm4gbW9kdWxlOyB9O1xuIFx0XHRfX3dlYnBhY2tfcmVxdWlyZV9fLmQoZ2V0dGVyLCAnYScsIGdldHRlcik7XG4gXHRcdHJldHVybiBnZXR0ZXI7XG4gXHR9O1xuXG4gXHQvLyBPYmplY3QucHJvdG90eXBlLmhhc093blByb3BlcnR5LmNhbGxcbiBcdF9fd2VicGFja19yZXF1aXJlX18ubyA9IGZ1bmN0aW9uKG9iamVjdCwgcHJvcGVydHkpIHsgcmV0dXJuIE9iamVjdC5wcm90b3R5cGUuaGFzT3duUHJvcGVydHkuY2FsbChvYmplY3QsIHByb3BlcnR5KTsgfTtcblxuIFx0Ly8gX193ZWJwYWNrX3B1YmxpY19wYXRoX19cbiBcdF9fd2VicGFja19yZXF1aXJlX18ucCA9IFwiXCI7XG5cblxuIFx0Ly8gTG9hZCBlbnRyeSBtb2R1bGUgYW5kIHJldHVybiBleHBvcnRzXG4gXHRyZXR1cm4gX193ZWJwYWNrX3JlcXVpcmVfXyhfX3dlYnBhY2tfcmVxdWlyZV9fLnMgPSBcIi4vc3JjL2NvbS9hdG9tZ3JhcGgvbGlua2VkZGF0YWh1Yi9xdWVyeS9TUEFSUUxCdWlsZGVyLnRzXCIpO1xuIiwiLy8gc2hpbSBmb3IgdXNpbmcgcHJvY2VzcyBpbiBicm93c2VyXG52YXIgcHJvY2VzcyA9IG1vZHVsZS5leHBvcnRzID0ge307XG5cbi8vIGNhY2hlZCBmcm9tIHdoYXRldmVyIGdsb2JhbCBpcyBwcmVzZW50IHNvIHRoYXQgdGVzdCBydW5uZXJzIHRoYXQgc3R1YiBpdFxuLy8gZG9uJ3QgYnJlYWsgdGhpbmdzLiAgQnV0IHdlIG5lZWQgdG8gd3JhcCBpdCBpbiBhIHRyeSBjYXRjaCBpbiBjYXNlIGl0IGlzXG4vLyB3cmFwcGVkIGluIHN0cmljdCBtb2RlIGNvZGUgd2hpY2ggZG9lc24ndCBkZWZpbmUgYW55IGdsb2JhbHMuICBJdCdzIGluc2lkZSBhXG4vLyBmdW5jdGlvbiBiZWNhdXNlIHRyeS9jYXRjaGVzIGRlb3B0aW1pemUgaW4gY2VydGFpbiBlbmdpbmVzLlxuXG52YXIgY2FjaGVkU2V0VGltZW91dDtcbnZhciBjYWNoZWRDbGVhclRpbWVvdXQ7XG5cbmZ1bmN0aW9uIGRlZmF1bHRTZXRUaW1vdXQoKSB7XG4gICAgdGhyb3cgbmV3IEVycm9yKCdzZXRUaW1lb3V0IGhhcyBub3QgYmVlbiBkZWZpbmVkJyk7XG59XG5mdW5jdGlvbiBkZWZhdWx0Q2xlYXJUaW1lb3V0ICgpIHtcbiAgICB0aHJvdyBuZXcgRXJyb3IoJ2NsZWFyVGltZW91dCBoYXMgbm90IGJlZW4gZGVmaW5lZCcpO1xufVxuKGZ1bmN0aW9uICgpIHtcbiAgICB0cnkge1xuICAgICAgICBpZiAodHlwZW9mIHNldFRpbWVvdXQgPT09ICdmdW5jdGlvbicpIHtcbiAgICAgICAgICAgIGNhY2hlZFNldFRpbWVvdXQgPSBzZXRUaW1lb3V0O1xuICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgY2FjaGVkU2V0VGltZW91dCA9IGRlZmF1bHRTZXRUaW1vdXQ7XG4gICAgICAgIH1cbiAgICB9IGNhdGNoIChlKSB7XG4gICAgICAgIGNhY2hlZFNldFRpbWVvdXQgPSBkZWZhdWx0U2V0VGltb3V0O1xuICAgIH1cbiAgICB0cnkge1xuICAgICAgICBpZiAodHlwZW9mIGNsZWFyVGltZW91dCA9PT0gJ2Z1bmN0aW9uJykge1xuICAgICAgICAgICAgY2FjaGVkQ2xlYXJUaW1lb3V0ID0gY2xlYXJUaW1lb3V0O1xuICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgY2FjaGVkQ2xlYXJUaW1lb3V0ID0gZGVmYXVsdENsZWFyVGltZW91dDtcbiAgICAgICAgfVxuICAgIH0gY2F0Y2ggKGUpIHtcbiAgICAgICAgY2FjaGVkQ2xlYXJUaW1lb3V0ID0gZGVmYXVsdENsZWFyVGltZW91dDtcbiAgICB9XG59ICgpKVxuZnVuY3Rpb24gcnVuVGltZW91dChmdW4pIHtcbiAgICBpZiAoY2FjaGVkU2V0VGltZW91dCA9PT0gc2V0VGltZW91dCkge1xuICAgICAgICAvL25vcm1hbCBlbnZpcm9tZW50cyBpbiBzYW5lIHNpdHVhdGlvbnNcbiAgICAgICAgcmV0dXJuIHNldFRpbWVvdXQoZnVuLCAwKTtcbiAgICB9XG4gICAgLy8gaWYgc2V0VGltZW91dCB3YXNuJ3QgYXZhaWxhYmxlIGJ1dCB3YXMgbGF0dGVyIGRlZmluZWRcbiAgICBpZiAoKGNhY2hlZFNldFRpbWVvdXQgPT09IGRlZmF1bHRTZXRUaW1vdXQgfHwgIWNhY2hlZFNldFRpbWVvdXQpICYmIHNldFRpbWVvdXQpIHtcbiAgICAgICAgY2FjaGVkU2V0VGltZW91dCA9IHNldFRpbWVvdXQ7XG4gICAgICAgIHJldHVybiBzZXRUaW1lb3V0KGZ1biwgMCk7XG4gICAgfVxuICAgIHRyeSB7XG4gICAgICAgIC8vIHdoZW4gd2hlbiBzb21lYm9keSBoYXMgc2NyZXdlZCB3aXRoIHNldFRpbWVvdXQgYnV0IG5vIEkuRS4gbWFkZG5lc3NcbiAgICAgICAgcmV0dXJuIGNhY2hlZFNldFRpbWVvdXQoZnVuLCAwKTtcbiAgICB9IGNhdGNoKGUpe1xuICAgICAgICB0cnkge1xuICAgICAgICAgICAgLy8gV2hlbiB3ZSBhcmUgaW4gSS5FLiBidXQgdGhlIHNjcmlwdCBoYXMgYmVlbiBldmFsZWQgc28gSS5FLiBkb2Vzbid0IHRydXN0IHRoZSBnbG9iYWwgb2JqZWN0IHdoZW4gY2FsbGVkIG5vcm1hbGx5XG4gICAgICAgICAgICByZXR1cm4gY2FjaGVkU2V0VGltZW91dC5jYWxsKG51bGwsIGZ1biwgMCk7XG4gICAgICAgIH0gY2F0Y2goZSl7XG4gICAgICAgICAgICAvLyBzYW1lIGFzIGFib3ZlIGJ1dCB3aGVuIGl0J3MgYSB2ZXJzaW9uIG9mIEkuRS4gdGhhdCBtdXN0IGhhdmUgdGhlIGdsb2JhbCBvYmplY3QgZm9yICd0aGlzJywgaG9wZnVsbHkgb3VyIGNvbnRleHQgY29ycmVjdCBvdGhlcndpc2UgaXQgd2lsbCB0aHJvdyBhIGdsb2JhbCBlcnJvclxuICAgICAgICAgICAgcmV0dXJuIGNhY2hlZFNldFRpbWVvdXQuY2FsbCh0aGlzLCBmdW4sIDApO1xuICAgICAgICB9XG4gICAgfVxuXG5cbn1cbmZ1bmN0aW9uIHJ1bkNsZWFyVGltZW91dChtYXJrZXIpIHtcbiAgICBpZiAoY2FjaGVkQ2xlYXJUaW1lb3V0ID09PSBjbGVhclRpbWVvdXQpIHtcbiAgICAgICAgLy9ub3JtYWwgZW52aXJvbWVudHMgaW4gc2FuZSBzaXR1YXRpb25zXG4gICAgICAgIHJldHVybiBjbGVhclRpbWVvdXQobWFya2VyKTtcbiAgICB9XG4gICAgLy8gaWYgY2xlYXJUaW1lb3V0IHdhc24ndCBhdmFpbGFibGUgYnV0IHdhcyBsYXR0ZXIgZGVmaW5lZFxuICAgIGlmICgoY2FjaGVkQ2xlYXJUaW1lb3V0ID09PSBkZWZhdWx0Q2xlYXJUaW1lb3V0IHx8ICFjYWNoZWRDbGVhclRpbWVvdXQpICYmIGNsZWFyVGltZW91dCkge1xuICAgICAgICBjYWNoZWRDbGVhclRpbWVvdXQgPSBjbGVhclRpbWVvdXQ7XG4gICAgICAgIHJldHVybiBjbGVhclRpbWVvdXQobWFya2VyKTtcbiAgICB9XG4gICAgdHJ5IHtcbiAgICAgICAgLy8gd2hlbiB3aGVuIHNvbWVib2R5IGhhcyBzY3Jld2VkIHdpdGggc2V0VGltZW91dCBidXQgbm8gSS5FLiBtYWRkbmVzc1xuICAgICAgICByZXR1cm4gY2FjaGVkQ2xlYXJUaW1lb3V0KG1hcmtlcik7XG4gICAgfSBjYXRjaCAoZSl7XG4gICAgICAgIHRyeSB7XG4gICAgICAgICAgICAvLyBXaGVuIHdlIGFyZSBpbiBJLkUuIGJ1dCB0aGUgc2NyaXB0IGhhcyBiZWVuIGV2YWxlZCBzbyBJLkUuIGRvZXNuJ3QgIHRydXN0IHRoZSBnbG9iYWwgb2JqZWN0IHdoZW4gY2FsbGVkIG5vcm1hbGx5XG4gICAgICAgICAgICByZXR1cm4gY2FjaGVkQ2xlYXJUaW1lb3V0LmNhbGwobnVsbCwgbWFya2VyKTtcbiAgICAgICAgfSBjYXRjaCAoZSl7XG4gICAgICAgICAgICAvLyBzYW1lIGFzIGFib3ZlIGJ1dCB3aGVuIGl0J3MgYSB2ZXJzaW9uIG9mIEkuRS4gdGhhdCBtdXN0IGhhdmUgdGhlIGdsb2JhbCBvYmplY3QgZm9yICd0aGlzJywgaG9wZnVsbHkgb3VyIGNvbnRleHQgY29ycmVjdCBvdGhlcndpc2UgaXQgd2lsbCB0aHJvdyBhIGdsb2JhbCBlcnJvci5cbiAgICAgICAgICAgIC8vIFNvbWUgdmVyc2lvbnMgb2YgSS5FLiBoYXZlIGRpZmZlcmVudCBydWxlcyBmb3IgY2xlYXJUaW1lb3V0IHZzIHNldFRpbWVvdXRcbiAgICAgICAgICAgIHJldHVybiBjYWNoZWRDbGVhclRpbWVvdXQuY2FsbCh0aGlzLCBtYXJrZXIpO1xuICAgICAgICB9XG4gICAgfVxuXG5cblxufVxudmFyIHF1ZXVlID0gW107XG52YXIgZHJhaW5pbmcgPSBmYWxzZTtcbnZhciBjdXJyZW50UXVldWU7XG52YXIgcXVldWVJbmRleCA9IC0xO1xuXG5mdW5jdGlvbiBjbGVhblVwTmV4dFRpY2soKSB7XG4gICAgaWYgKCFkcmFpbmluZyB8fCAhY3VycmVudFF1ZXVlKSB7XG4gICAgICAgIHJldHVybjtcbiAgICB9XG4gICAgZHJhaW5pbmcgPSBmYWxzZTtcbiAgICBpZiAoY3VycmVudFF1ZXVlLmxlbmd0aCkge1xuICAgICAgICBxdWV1ZSA9IGN1cnJlbnRRdWV1ZS5jb25jYXQocXVldWUpO1xuICAgIH0gZWxzZSB7XG4gICAgICAgIHF1ZXVlSW5kZXggPSAtMTtcbiAgICB9XG4gICAgaWYgKHF1ZXVlLmxlbmd0aCkge1xuICAgICAgICBkcmFpblF1ZXVlKCk7XG4gICAgfVxufVxuXG5mdW5jdGlvbiBkcmFpblF1ZXVlKCkge1xuICAgIGlmIChkcmFpbmluZykge1xuICAgICAgICByZXR1cm47XG4gICAgfVxuICAgIHZhciB0aW1lb3V0ID0gcnVuVGltZW91dChjbGVhblVwTmV4dFRpY2spO1xuICAgIGRyYWluaW5nID0gdHJ1ZTtcblxuICAgIHZhciBsZW4gPSBxdWV1ZS5sZW5ndGg7XG4gICAgd2hpbGUobGVuKSB7XG4gICAgICAgIGN1cnJlbnRRdWV1ZSA9IHF1ZXVlO1xuICAgICAgICBxdWV1ZSA9IFtdO1xuICAgICAgICB3aGlsZSAoKytxdWV1ZUluZGV4IDwgbGVuKSB7XG4gICAgICAgICAgICBpZiAoY3VycmVudFF1ZXVlKSB7XG4gICAgICAgICAgICAgICAgY3VycmVudFF1ZXVlW3F1ZXVlSW5kZXhdLnJ1bigpO1xuICAgICAgICAgICAgfVxuICAgICAgICB9XG4gICAgICAgIHF1ZXVlSW5kZXggPSAtMTtcbiAgICAgICAgbGVuID0gcXVldWUubGVuZ3RoO1xuICAgIH1cbiAgICBjdXJyZW50UXVldWUgPSBudWxsO1xuICAgIGRyYWluaW5nID0gZmFsc2U7XG4gICAgcnVuQ2xlYXJUaW1lb3V0KHRpbWVvdXQpO1xufVxuXG5wcm9jZXNzLm5leHRUaWNrID0gZnVuY3Rpb24gKGZ1bikge1xuICAgIHZhciBhcmdzID0gbmV3IEFycmF5KGFyZ3VtZW50cy5sZW5ndGggLSAxKTtcbiAgICBpZiAoYXJndW1lbnRzLmxlbmd0aCA+IDEpIHtcbiAgICAgICAgZm9yICh2YXIgaSA9IDE7IGkgPCBhcmd1bWVudHMubGVuZ3RoOyBpKyspIHtcbiAgICAgICAgICAgIGFyZ3NbaSAtIDFdID0gYXJndW1lbnRzW2ldO1xuICAgICAgICB9XG4gICAgfVxuICAgIHF1ZXVlLnB1c2gobmV3IEl0ZW0oZnVuLCBhcmdzKSk7XG4gICAgaWYgKHF1ZXVlLmxlbmd0aCA9PT0gMSAmJiAhZHJhaW5pbmcpIHtcbiAgICAgICAgcnVuVGltZW91dChkcmFpblF1ZXVlKTtcbiAgICB9XG59O1xuXG4vLyB2OCBsaWtlcyBwcmVkaWN0aWJsZSBvYmplY3RzXG5mdW5jdGlvbiBJdGVtKGZ1biwgYXJyYXkpIHtcbiAgICB0aGlzLmZ1biA9IGZ1bjtcbiAgICB0aGlzLmFycmF5ID0gYXJyYXk7XG59XG5JdGVtLnByb3RvdHlwZS5ydW4gPSBmdW5jdGlvbiAoKSB7XG4gICAgdGhpcy5mdW4uYXBwbHkobnVsbCwgdGhpcy5hcnJheSk7XG59O1xucHJvY2Vzcy50aXRsZSA9ICdicm93c2VyJztcbnByb2Nlc3MuYnJvd3NlciA9IHRydWU7XG5wcm9jZXNzLmVudiA9IHt9O1xucHJvY2Vzcy5hcmd2ID0gW107XG5wcm9jZXNzLnZlcnNpb24gPSAnJzsgLy8gZW1wdHkgc3RyaW5nIHRvIGF2b2lkIHJlZ2V4cCBpc3N1ZXNcbnByb2Nlc3MudmVyc2lvbnMgPSB7fTtcblxuZnVuY3Rpb24gbm9vcCgpIHt9XG5cbnByb2Nlc3Mub24gPSBub29wO1xucHJvY2Vzcy5hZGRMaXN0ZW5lciA9IG5vb3A7XG5wcm9jZXNzLm9uY2UgPSBub29wO1xucHJvY2Vzcy5vZmYgPSBub29wO1xucHJvY2Vzcy5yZW1vdmVMaXN0ZW5lciA9IG5vb3A7XG5wcm9jZXNzLnJlbW92ZUFsbExpc3RlbmVycyA9IG5vb3A7XG5wcm9jZXNzLmVtaXQgPSBub29wO1xucHJvY2Vzcy5wcmVwZW5kTGlzdGVuZXIgPSBub29wO1xucHJvY2Vzcy5wcmVwZW5kT25jZUxpc3RlbmVyID0gbm9vcDtcblxucHJvY2Vzcy5saXN0ZW5lcnMgPSBmdW5jdGlvbiAobmFtZSkgeyByZXR1cm4gW10gfVxuXG5wcm9jZXNzLmJpbmRpbmcgPSBmdW5jdGlvbiAobmFtZSkge1xuICAgIHRocm93IG5ldyBFcnJvcigncHJvY2Vzcy5iaW5kaW5nIGlzIG5vdCBzdXBwb3J0ZWQnKTtcbn07XG5cbnByb2Nlc3MuY3dkID0gZnVuY3Rpb24gKCkgeyByZXR1cm4gJy8nIH07XG5wcm9jZXNzLmNoZGlyID0gZnVuY3Rpb24gKGRpcikge1xuICAgIHRocm93IG5ldyBFcnJvcigncHJvY2Vzcy5jaGRpciBpcyBub3Qgc3VwcG9ydGVkJyk7XG59O1xucHJvY2Vzcy51bWFzayA9IGZ1bmN0aW9uKCkgeyByZXR1cm4gMDsgfTtcbiIsInZhciBYU0RfSU5URUdFUiA9ICdodHRwOi8vd3d3LnczLm9yZy8yMDAxL1hNTFNjaGVtYSNpbnRlZ2VyJztcblxuZnVuY3Rpb24gR2VuZXJhdG9yKG9wdGlvbnMsIHByZWZpeGVzKSB7XG4gIHRoaXMuX29wdGlvbnMgPSBvcHRpb25zID0gb3B0aW9ucyB8fCB7fTtcblxuICBwcmVmaXhlcyA9IHByZWZpeGVzIHx8IHt9O1xuICB0aGlzLl9wcmVmaXhCeUlyaSA9IHt9O1xuICB2YXIgcHJlZml4SXJpcyA9IFtdO1xuICBmb3IgKHZhciBwcmVmaXggaW4gcHJlZml4ZXMpIHtcbiAgICB2YXIgaXJpID0gcHJlZml4ZXNbcHJlZml4XTtcbiAgICBpZiAoaXNTdHJpbmcoaXJpKSkge1xuICAgICAgdGhpcy5fcHJlZml4QnlJcmlbaXJpXSA9IHByZWZpeDtcbiAgICAgIHByZWZpeElyaXMucHVzaChpcmkpO1xuICAgIH1cbiAgfVxuICB2YXIgaXJpTGlzdCA9IHByZWZpeElyaXMuam9pbignfCcpLnJlcGxhY2UoL1tcXF1cXC9cXChcXClcXCpcXCtcXD9cXC5cXFxcXFwkXS9nLCAnXFxcXCQmJyk7XG4gIHRoaXMuX3ByZWZpeFJlZ2V4ID0gbmV3IFJlZ0V4cCgnXignICsgaXJpTGlzdCArICcpKFthLXpBLVpdW1xcXFwtX2EtekEtWjAtOV0qKSQnKTtcbiAgdGhpcy5fdXNlZFByZWZpeGVzID0ge307XG4gIHRoaXMuX2luZGVudCA9ICBpc1N0cmluZyhvcHRpb25zLmluZGVudCkgID8gb3B0aW9ucy5pbmRlbnQgIDogJyAgJztcbiAgdGhpcy5fbmV3bGluZSA9IGlzU3RyaW5nKG9wdGlvbnMubmV3bGluZSkgPyBvcHRpb25zLm5ld2xpbmUgOiAnXFxuJztcbn1cblxuLy8gQ29udmVydHMgdGhlIHBhcnNlZCBxdWVyeSBvYmplY3QgaW50byBhIFNQQVJRTCBxdWVyeVxuR2VuZXJhdG9yLnByb3RvdHlwZS50b1F1ZXJ5ID0gZnVuY3Rpb24gKHEpIHtcbiAgdmFyIHF1ZXJ5ID0gJyc7XG5cbiAgaWYgKHEucXVlcnlUeXBlKVxuICAgIHF1ZXJ5ICs9IHEucXVlcnlUeXBlLnRvVXBwZXJDYXNlKCkgKyAnICc7XG4gIGlmIChxLnJlZHVjZWQpXG4gICAgcXVlcnkgKz0gJ1JFRFVDRUQgJztcbiAgaWYgKHEuZGlzdGluY3QpXG4gICAgcXVlcnkgKz0gJ0RJU1RJTkNUICc7XG5cbiAgaWYgKHEudmFyaWFibGVzKVxuICAgIHF1ZXJ5ICs9IG1hcEpvaW4ocS52YXJpYWJsZXMsIHVuZGVmaW5lZCwgZnVuY3Rpb24gKHZhcmlhYmxlKSB7XG4gICAgICByZXR1cm4gaXNTdHJpbmcodmFyaWFibGUpID8gdGhpcy50b0VudGl0eSh2YXJpYWJsZSkgOlxuICAgICAgICAgICAgICcoJyArIHRoaXMudG9FeHByZXNzaW9uKHZhcmlhYmxlLmV4cHJlc3Npb24pICsgJyBBUyAnICsgdmFyaWFibGUudmFyaWFibGUgKyAnKSc7XG4gICAgfSwgdGhpcykgKyAnICc7XG4gIGVsc2UgaWYgKHEudGVtcGxhdGUpXG4gICAgcXVlcnkgKz0gdGhpcy5ncm91cChxLnRlbXBsYXRlLCB0cnVlKSArIHRoaXMuX25ld2xpbmU7XG5cbiAgaWYgKHEuZnJvbSlcbiAgICBxdWVyeSArPSBtYXBKb2luKHEuZnJvbS5kZWZhdWx0IHx8IFtdLCAnJywgZnVuY3Rpb24gKGcpIHsgcmV0dXJuICdGUk9NICcgKyB0aGlzLnRvRW50aXR5KGcpICsgdGhpcy5fbmV3bGluZTsgfSwgdGhpcykgK1xuICAgICAgICAgICAgIG1hcEpvaW4ocS5mcm9tLm5hbWVkIHx8IFtdLCAnJywgZnVuY3Rpb24gKGcpIHsgcmV0dXJuICdGUk9NIE5BTUVEICcgKyB0aGlzLnRvRW50aXR5KGcpICsgdGhpcy5fbmV3bGluZTsgfSwgdGhpcyk7XG4gIGlmIChxLndoZXJlKVxuICAgIHF1ZXJ5ICs9ICdXSEVSRSAnICsgdGhpcy5ncm91cChxLndoZXJlLCB0cnVlKSArIHRoaXMuX25ld2xpbmU7XG5cbiAgaWYgKHEudXBkYXRlcylcbiAgICBxdWVyeSArPSBtYXBKb2luKHEudXBkYXRlcywgJzsnICsgdGhpcy5fbmV3bGluZSwgdGhpcy50b1VwZGF0ZSwgdGhpcyk7XG5cbiAgaWYgKHEuZ3JvdXApXG4gICAgcXVlcnkgKz0gJ0dST1VQIEJZICcgKyBtYXBKb2luKHEuZ3JvdXAsIHVuZGVmaW5lZCwgZnVuY3Rpb24gKGl0KSB7XG4gICAgICB2YXIgcmVzdWx0ID0gaXNTdHJpbmcoaXQuZXhwcmVzc2lvbikgPyBpdC5leHByZXNzaW9uIDogJygnICsgdGhpcy50b0V4cHJlc3Npb24oaXQuZXhwcmVzc2lvbikgKyAnKSc7XG4gICAgICByZXR1cm4gaXQudmFyaWFibGUgPyAnKCcgKyByZXN1bHQgKyAnIEFTICcgKyBpdC52YXJpYWJsZSArICcpJyA6IHJlc3VsdDtcbiAgICB9LCB0aGlzKSArIHRoaXMuX25ld2xpbmU7XG4gIGlmIChxLmhhdmluZylcbiAgICBxdWVyeSArPSAnSEFWSU5HICgnICsgbWFwSm9pbihxLmhhdmluZywgdW5kZWZpbmVkLCB0aGlzLnRvRXhwcmVzc2lvbiwgdGhpcykgKyAnKScgKyB0aGlzLl9uZXdsaW5lO1xuICBpZiAocS5vcmRlcilcbiAgICBxdWVyeSArPSAnT1JERVIgQlkgJyArIG1hcEpvaW4ocS5vcmRlciwgdW5kZWZpbmVkLCBmdW5jdGlvbiAoaXQpIHtcbiAgICAgIHZhciBleHByID0gJygnICsgdGhpcy50b0V4cHJlc3Npb24oaXQuZXhwcmVzc2lvbikgKyAnKSc7XG4gICAgICByZXR1cm4gIWl0LmRlc2NlbmRpbmcgPyBleHByIDogJ0RFU0MgJyArIGV4cHI7XG4gICAgfSwgdGhpcykgKyB0aGlzLl9uZXdsaW5lO1xuXG4gIGlmIChxLm9mZnNldClcbiAgICBxdWVyeSArPSAnT0ZGU0VUICcgKyBxLm9mZnNldCArIHRoaXMuX25ld2xpbmU7XG4gIGlmIChxLmxpbWl0KVxuICAgIHF1ZXJ5ICs9ICdMSU1JVCAnICsgcS5saW1pdCArIHRoaXMuX25ld2xpbmU7XG5cbiAgaWYgKHEudmFsdWVzKVxuICAgIHF1ZXJ5ICs9IHRoaXMudmFsdWVzKHEpO1xuXG4gIC8vIHN0cmluZ2lmeSBwcmVmaXhlcyBhdCB0aGUgZW5kIHRvIG1hcmsgdXNlZCBvbmVzXG4gIHF1ZXJ5ID0gdGhpcy5iYXNlQW5kUHJlZml4ZXMocSkgKyBxdWVyeTtcbiAgcmV0dXJuIHF1ZXJ5LnRyaW0oKTtcbn07XG5cbkdlbmVyYXRvci5wcm90b3R5cGUuYmFzZUFuZFByZWZpeGVzID0gZnVuY3Rpb24gKHEpIHtcbiAgdmFyIGJhc2UgPSBxLmJhc2UgPyAoJ0JBU0UgPCcgKyBxLmJhc2UgKyAnPicgKyB0aGlzLl9uZXdsaW5lKSA6ICcnO1xuICB2YXIgcHJlZml4ZXMgPSAnJztcbiAgZm9yICh2YXIga2V5IGluIHEucHJlZml4ZXMpIHtcbiAgICBpZiAodGhpcy5fb3B0aW9ucy5hbGxQcmVmaXhlcyB8fCB0aGlzLl91c2VkUHJlZml4ZXNba2V5XSlcbiAgICAgIHByZWZpeGVzICs9ICdQUkVGSVggJyArIGtleSArICc6IDwnICsgcS5wcmVmaXhlc1trZXldICsgJz4nICsgdGhpcy5fbmV3bGluZTtcbiAgfVxuICByZXR1cm4gYmFzZSArIHByZWZpeGVzO1xufTtcblxuLy8gQ29udmVydHMgdGhlIHBhcnNlZCBTUEFSUUwgcGF0dGVybiBpbnRvIGEgU1BBUlFMIHBhdHRlcm5cbkdlbmVyYXRvci5wcm90b3R5cGUudG9QYXR0ZXJuID0gZnVuY3Rpb24gKHBhdHRlcm4pIHtcbiAgdmFyIHR5cGUgPSBwYXR0ZXJuLnR5cGUgfHwgKHBhdHRlcm4gaW5zdGFuY2VvZiBBcnJheSkgJiYgJ2FycmF5JyB8fFxuICAgICAgICAgICAgIChwYXR0ZXJuLnN1YmplY3QgJiYgcGF0dGVybi5wcmVkaWNhdGUgJiYgcGF0dGVybi5vYmplY3QgPyAndHJpcGxlJyA6ICcnKTtcbiAgaWYgKCEodHlwZSBpbiB0aGlzKSlcbiAgICB0aHJvdyBuZXcgRXJyb3IoJ1Vua25vd24gZW50cnkgdHlwZTogJyArIHR5cGUpO1xuICByZXR1cm4gdGhpc1t0eXBlXShwYXR0ZXJuKTtcbn07XG5cbkdlbmVyYXRvci5wcm90b3R5cGUudHJpcGxlID0gZnVuY3Rpb24gKHQpIHtcbiAgcmV0dXJuIHRoaXMudG9FbnRpdHkodC5zdWJqZWN0KSArICcgJyArIHRoaXMudG9FbnRpdHkodC5wcmVkaWNhdGUpICsgJyAnICsgdGhpcy50b0VudGl0eSh0Lm9iamVjdCkgKyAnLic7XG59O1xuXG5HZW5lcmF0b3IucHJvdG90eXBlLmFycmF5ID0gZnVuY3Rpb24gKGl0ZW1zKSB7XG4gIHJldHVybiBtYXBKb2luKGl0ZW1zLCB0aGlzLl9uZXdsaW5lLCB0aGlzLnRvUGF0dGVybiwgdGhpcyk7XG59O1xuXG5HZW5lcmF0b3IucHJvdG90eXBlLmJncCA9IGZ1bmN0aW9uIChiZ3ApIHtcbiAgcmV0dXJuIHRoaXMuZW5jb2RlVHJpcGxlcyhiZ3AudHJpcGxlcyk7XG59O1xuXG5HZW5lcmF0b3IucHJvdG90eXBlLmVuY29kZVRyaXBsZXMgPSBmdW5jdGlvbiAodHJpcGxlcykge1xuICBpZiAoIXRyaXBsZXMubGVuZ3RoKVxuICAgIHJldHVybiAnJztcblxuICB2YXIgcGFydHMgPSBbXSwgc3ViamVjdCA9ICcnLCBwcmVkaWNhdGUgPSAnJztcbiAgZm9yICh2YXIgaSA9IDA7IGkgPCB0cmlwbGVzLmxlbmd0aDsgaSsrKSB7XG4gICAgdmFyIHRyaXBsZSA9IHRyaXBsZXNbaV07XG4gICAgLy8gVHJpcGxlIHdpdGggZGlmZmVyZW50IHN1YmplY3RcbiAgICBpZiAodHJpcGxlLnN1YmplY3QgIT09IHN1YmplY3QpIHtcbiAgICAgIC8vIFRlcm1pbmF0ZSBwcmV2aW91cyB0cmlwbGVcbiAgICAgIGlmIChzdWJqZWN0KVxuICAgICAgICBwYXJ0cy5wdXNoKCcuJyArIHRoaXMuX25ld2xpbmUpO1xuICAgICAgc3ViamVjdCA9IHRyaXBsZS5zdWJqZWN0O1xuICAgICAgcHJlZGljYXRlID0gdHJpcGxlLnByZWRpY2F0ZTtcbiAgICAgIHBhcnRzLnB1c2godGhpcy50b0VudGl0eShzdWJqZWN0KSwgJyAnLCB0aGlzLnRvRW50aXR5KHByZWRpY2F0ZSkpO1xuICAgIH1cbiAgICAvLyBUcmlwbGUgd2l0aCBzYW1lIHN1YmplY3QgYnV0IGRpZmZlcmVudCBwcmVkaWNhdGVcbiAgICBlbHNlIGlmICh0cmlwbGUucHJlZGljYXRlICE9PSBwcmVkaWNhdGUpIHtcbiAgICAgIHByZWRpY2F0ZSA9IHRyaXBsZS5wcmVkaWNhdGU7XG4gICAgICBwYXJ0cy5wdXNoKCc7JyArIHRoaXMuX25ld2xpbmUsIHRoaXMuX2luZGVudCwgdGhpcy50b0VudGl0eShwcmVkaWNhdGUpKTtcbiAgICB9XG4gICAgLy8gVHJpcGxlIHdpdGggc2FtZSBzdWJqZWN0IGFuZCBwcmVkaWNhdGVcbiAgICBlbHNlIHtcbiAgICAgIHBhcnRzLnB1c2goJywnKTtcbiAgICB9XG4gICAgcGFydHMucHVzaCgnICcsIHRoaXMudG9FbnRpdHkodHJpcGxlLm9iamVjdCkpO1xuICB9XG4gIHBhcnRzLnB1c2goJy4nKTtcblxuICByZXR1cm4gcGFydHMuam9pbignJyk7XG59XG5cbkdlbmVyYXRvci5wcm90b3R5cGUuZ3JhcGggPSBmdW5jdGlvbiAoZ3JhcGgpIHtcbiAgcmV0dXJuICdHUkFQSCAnICsgdGhpcy50b0VudGl0eShncmFwaC5uYW1lKSArICcgJyArIHRoaXMuZ3JvdXAoZ3JhcGgpO1xufTtcblxuR2VuZXJhdG9yLnByb3RvdHlwZS5ncm91cCA9IGZ1bmN0aW9uIChncm91cCwgaW5saW5lKSB7XG4gIGdyb3VwID0gaW5saW5lICE9PSB0cnVlID8gdGhpcy5hcnJheShncm91cC5wYXR0ZXJucyB8fCBncm91cC50cmlwbGVzKVxuICAgICAgICAgICAgICAgICAgICAgICAgICA6IHRoaXMudG9QYXR0ZXJuKGdyb3VwLnR5cGUgIT09ICdncm91cCcgPyBncm91cCA6IGdyb3VwLnBhdHRlcm5zKTtcbiAgcmV0dXJuIGdyb3VwLmluZGV4T2YodGhpcy5fbmV3bGluZSkgPT09IC0xID8gJ3sgJyArIGdyb3VwICsgJyB9JyA6ICd7JyArIHRoaXMuX25ld2xpbmUgKyB0aGlzLmluZGVudChncm91cCkgKyB0aGlzLl9uZXdsaW5lICsgJ30nO1xufTtcblxuR2VuZXJhdG9yLnByb3RvdHlwZS5xdWVyeSA9IGZ1bmN0aW9uIChxdWVyeSkge1xuICByZXR1cm4gdGhpcy50b1F1ZXJ5KHF1ZXJ5KTtcbn07XG5cbkdlbmVyYXRvci5wcm90b3R5cGUuZmlsdGVyID0gZnVuY3Rpb24gKGZpbHRlcikge1xuICByZXR1cm4gJ0ZJTFRFUignICsgdGhpcy50b0V4cHJlc3Npb24oZmlsdGVyLmV4cHJlc3Npb24pICsgJyknO1xufTtcblxuR2VuZXJhdG9yLnByb3RvdHlwZS5iaW5kID0gZnVuY3Rpb24gKGJpbmQpIHtcbiAgcmV0dXJuICdCSU5EKCcgKyB0aGlzLnRvRXhwcmVzc2lvbihiaW5kLmV4cHJlc3Npb24pICsgJyBBUyAnICsgYmluZC52YXJpYWJsZSArICcpJztcbn07XG5cbkdlbmVyYXRvci5wcm90b3R5cGUub3B0aW9uYWwgPSBmdW5jdGlvbiAob3B0aW9uYWwpIHtcbiAgcmV0dXJuICdPUFRJT05BTCAnICsgdGhpcy5ncm91cChvcHRpb25hbCk7XG59O1xuXG5HZW5lcmF0b3IucHJvdG90eXBlLnVuaW9uID0gZnVuY3Rpb24gKHVuaW9uKSB7XG4gIHJldHVybiBtYXBKb2luKHVuaW9uLnBhdHRlcm5zLCB0aGlzLl9uZXdsaW5lICsgJ1VOSU9OJyArIHRoaXMuX25ld2xpbmUsIGZ1bmN0aW9uIChwKSB7IHJldHVybiB0aGlzLmdyb3VwKHAsIHRydWUpOyB9LCB0aGlzKTtcbn07XG5cbkdlbmVyYXRvci5wcm90b3R5cGUubWludXMgPSBmdW5jdGlvbiAobWludXMpIHtcbiAgcmV0dXJuICdNSU5VUyAnICsgdGhpcy5ncm91cChtaW51cyk7XG59O1xuXG5HZW5lcmF0b3IucHJvdG90eXBlLnZhbHVlcyA9IGZ1bmN0aW9uICh2YWx1ZXNMaXN0KSB7XG4gIC8vIEdhdGhlciB1bmlxdWUga2V5c1xuICB2YXIga2V5cyA9IE9iamVjdC5rZXlzKHZhbHVlc0xpc3QudmFsdWVzLnJlZHVjZShmdW5jdGlvbiAoa2V5SGFzaCwgdmFsdWVzKSB7XG4gICAgZm9yICh2YXIga2V5IGluIHZhbHVlcykga2V5SGFzaFtrZXldID0gdHJ1ZTtcbiAgICByZXR1cm4ga2V5SGFzaDtcbiAgfSwge30pKTtcbiAgLy8gQ2hlY2sgd2hldGhlciBzaW1wbGUgc3ludGF4IGNhbiBiZSB1c2VkXG4gIHZhciBscGFyZW4sIHJwYXJlbjtcbiAgaWYgKGtleXMubGVuZ3RoID09PSAxKSB7XG4gICAgbHBhcmVuID0gcnBhcmVuID0gJyc7XG4gIH0gZWxzZSB7XG4gICAgbHBhcmVuID0gJygnO1xuICAgIHJwYXJlbiA9ICcpJztcbiAgfVxuICAvLyBDcmVhdGUgdmFsdWUgcm93c1xuICByZXR1cm4gJ1ZBTFVFUyAnICsgbHBhcmVuICsga2V5cy5qb2luKCcgJykgKyBycGFyZW4gKyAnIHsnICsgdGhpcy5fbmV3bGluZSArXG4gICAgbWFwSm9pbih2YWx1ZXNMaXN0LnZhbHVlcywgdGhpcy5fbmV3bGluZSwgZnVuY3Rpb24gKHZhbHVlcykge1xuICAgICAgcmV0dXJuICcgICcgKyBscGFyZW4gKyBtYXBKb2luKGtleXMsIHVuZGVmaW5lZCwgZnVuY3Rpb24gKGtleSkge1xuICAgICAgICByZXR1cm4gdmFsdWVzW2tleV0gIT09IHVuZGVmaW5lZCA/IHRoaXMudG9FbnRpdHkodmFsdWVzW2tleV0pIDogJ1VOREVGJztcbiAgICAgIH0sIHRoaXMpICsgcnBhcmVuO1xuICAgIH0sIHRoaXMpICsgdGhpcy5fbmV3bGluZSArICd9Jztcbn07XG5cbkdlbmVyYXRvci5wcm90b3R5cGUuc2VydmljZSA9IGZ1bmN0aW9uIChzZXJ2aWNlKSB7XG4gIHJldHVybiAnU0VSVklDRSAnICsgKHNlcnZpY2Uuc2lsZW50ID8gJ1NJTEVOVCAnIDogJycpICsgdGhpcy50b0VudGl0eShzZXJ2aWNlLm5hbWUpICsgJyAnICtcbiAgICAgICAgIHRoaXMuZ3JvdXAoc2VydmljZSk7XG59O1xuXG4vLyBDb252ZXJ0cyB0aGUgcGFyc2VkIGV4cHJlc3Npb24gb2JqZWN0IGludG8gYSBTUEFSUUwgZXhwcmVzc2lvblxuR2VuZXJhdG9yLnByb3RvdHlwZS50b0V4cHJlc3Npb24gPSBmdW5jdGlvbiAoZXhwcikge1xuICBpZiAoaXNTdHJpbmcoZXhwcikpXG4gICAgcmV0dXJuIHRoaXMudG9FbnRpdHkoZXhwcik7XG5cbiAgc3dpdGNoIChleHByLnR5cGUudG9Mb3dlckNhc2UoKSkge1xuICAgIGNhc2UgJ2FnZ3JlZ2F0ZSc6XG4gICAgICByZXR1cm4gZXhwci5hZ2dyZWdhdGlvbi50b1VwcGVyQ2FzZSgpICtcbiAgICAgICAgICAgICAnKCcgKyAoZXhwci5kaXN0aW5jdCA/ICdESVNUSU5DVCAnIDogJycpICsgdGhpcy50b0V4cHJlc3Npb24oZXhwci5leHByZXNzaW9uKSArXG4gICAgICAgICAgICAgKGV4cHIuc2VwYXJhdG9yID8gJzsgU0VQQVJBVE9SID0gJyArIHRoaXMudG9FbnRpdHkoJ1wiJyArIGV4cHIuc2VwYXJhdG9yICsgJ1wiJykgOiAnJykgKyAnKSc7XG4gICAgY2FzZSAnZnVuY3Rpb25jYWxsJzpcbiAgICAgIHJldHVybiB0aGlzLnRvRW50aXR5KGV4cHIuZnVuY3Rpb24pICsgJygnICsgbWFwSm9pbihleHByLmFyZ3MsICcsICcsIHRoaXMudG9FeHByZXNzaW9uLCB0aGlzKSArICcpJztcbiAgICBjYXNlICdvcGVyYXRpb24nOlxuICAgICAgdmFyIG9wZXJhdG9yID0gZXhwci5vcGVyYXRvci50b1VwcGVyQ2FzZSgpLCBhcmdzID0gZXhwci5hcmdzIHx8IFtdO1xuICAgICAgc3dpdGNoIChleHByLm9wZXJhdG9yLnRvTG93ZXJDYXNlKCkpIHtcbiAgICAgIC8vIEluZml4IG9wZXJhdG9yc1xuICAgICAgY2FzZSAnPCc6XG4gICAgICBjYXNlICc+JzpcbiAgICAgIGNhc2UgJz49JzpcbiAgICAgIGNhc2UgJzw9JzpcbiAgICAgIGNhc2UgJyYmJzpcbiAgICAgIGNhc2UgJ3x8JzpcbiAgICAgIGNhc2UgJz0nOlxuICAgICAgY2FzZSAnIT0nOlxuICAgICAgY2FzZSAnKyc6XG4gICAgICBjYXNlICctJzpcbiAgICAgIGNhc2UgJyonOlxuICAgICAgY2FzZSAnLyc6XG4gICAgICAgICAgcmV0dXJuIChpc1N0cmluZyhhcmdzWzBdKSA/IHRoaXMudG9FbnRpdHkoYXJnc1swXSkgOiAnKCcgKyB0aGlzLnRvRXhwcmVzc2lvbihhcmdzWzBdKSArICcpJykgK1xuICAgICAgICAgICAgICAgICAnICcgKyBvcGVyYXRvciArICcgJyArXG4gICAgICAgICAgICAgICAgIChpc1N0cmluZyhhcmdzWzFdKSA/IHRoaXMudG9FbnRpdHkoYXJnc1sxXSkgOiAnKCcgKyB0aGlzLnRvRXhwcmVzc2lvbihhcmdzWzFdKSArICcpJyk7XG4gICAgICAvLyBVbmFyeSBvcGVyYXRvcnNcbiAgICAgIGNhc2UgJyEnOlxuICAgICAgICByZXR1cm4gJyEoJyArIHRoaXMudG9FeHByZXNzaW9uKGFyZ3NbMF0pICsgJyknO1xuICAgICAgLy8gSU4gYW5kIE5PVCBJTlxuICAgICAgY2FzZSAnbm90aW4nOlxuICAgICAgICBvcGVyYXRvciA9ICdOT1QgSU4nO1xuICAgICAgY2FzZSAnaW4nOlxuICAgICAgICByZXR1cm4gdGhpcy50b0V4cHJlc3Npb24oYXJnc1swXSkgKyAnICcgKyBvcGVyYXRvciArXG4gICAgICAgICAgICAgICAnKCcgKyAoaXNTdHJpbmcoYXJnc1sxXSkgPyBhcmdzWzFdIDogbWFwSm9pbihhcmdzWzFdLCAnLCAnLCB0aGlzLnRvRXhwcmVzc2lvbiwgdGhpcykpICsgJyknO1xuICAgICAgLy8gRVhJU1RTIGFuZCBOT1QgRVhJU1RTXG4gICAgICBjYXNlICdub3RleGlzdHMnOlxuICAgICAgICBvcGVyYXRvciA9ICdOT1QgRVhJU1RTJztcbiAgICAgIGNhc2UgJ2V4aXN0cyc6XG4gICAgICAgIHJldHVybiBvcGVyYXRvciArICcgJyArIHRoaXMuZ3JvdXAoYXJnc1swXSwgdHJ1ZSk7XG4gICAgICAvLyBPdGhlciBleHByZXNzaW9uc1xuICAgICAgZGVmYXVsdDpcbiAgICAgICAgcmV0dXJuIG9wZXJhdG9yICsgJygnICsgbWFwSm9pbihhcmdzLCAnLCAnLCB0aGlzLnRvRXhwcmVzc2lvbiwgdGhpcykgKyAnKSc7XG4gICAgICB9XG4gICAgZGVmYXVsdDpcbiAgICAgIHRocm93IG5ldyBFcnJvcignVW5rbm93biBleHByZXNzaW9uIHR5cGU6ICcgKyBleHByLnR5cGUpO1xuICB9XG59O1xuXG4vLyBDb252ZXJ0cyB0aGUgcGFyc2VkIGVudGl0eSAob3IgcHJvcGVydHkgcGF0aCkgaW50byBhIFNQQVJRTCBlbnRpdHlcbkdlbmVyYXRvci5wcm90b3R5cGUudG9FbnRpdHkgPSBmdW5jdGlvbiAodmFsdWUpIHtcbiAgLy8gcmVndWxhciBlbnRpdHlcbiAgaWYgKGlzU3RyaW5nKHZhbHVlKSkge1xuICAgIHN3aXRjaCAodmFsdWVbMF0pIHtcbiAgICAvLyB2YXJpYWJsZSwgKiBzZWxlY3Rvciwgb3IgYmxhbmsgbm9kZVxuICAgIGNhc2UgJz8nOlxuICAgIGNhc2UgJyQnOlxuICAgIGNhc2UgJyonOlxuICAgIGNhc2UgJ18nOlxuICAgICAgcmV0dXJuIHZhbHVlO1xuICAgIC8vIGxpdGVyYWxcbiAgICBjYXNlICdcIic6XG4gICAgICB2YXIgbWF0Y2ggPSB2YWx1ZS5tYXRjaCgvXlwiKFteXSopXCIoPzooQC4rKXxcXF5cXF4oLispKT8kLykgfHwge30sXG4gICAgICAgICAgbGV4aWNhbCA9IG1hdGNoWzFdIHx8ICcnLCBsYW5ndWFnZSA9IG1hdGNoWzJdIHx8ICcnLCBkYXRhdHlwZSA9IG1hdGNoWzNdO1xuICAgICAgdmFsdWUgPSAnXCInICsgbGV4aWNhbC5yZXBsYWNlKGVzY2FwZSwgZXNjYXBlUmVwbGFjZXIpICsgJ1wiJyArIGxhbmd1YWdlO1xuICAgICAgaWYgKGRhdGF0eXBlKSB7XG4gICAgICAgIGlmIChkYXRhdHlwZSA9PT0gWFNEX0lOVEVHRVIgJiYgL15cXGQrJC8udGVzdChsZXhpY2FsKSlcbiAgICAgICAgICAvLyBBZGQgc3BhY2UgdG8gYXZvaWQgY29uZnVzaW9uIHdpdGggZGVjaW1hbHMgaW4gYnJva2VuIHBhcnNlcnNcbiAgICAgICAgICByZXR1cm4gbGV4aWNhbCArICcgJztcbiAgICAgICAgdmFsdWUgKz0gJ15eJyArIHRoaXMuZW5jb2RlSVJJKGRhdGF0eXBlKTtcbiAgICAgIH1cbiAgICAgIHJldHVybiB2YWx1ZTtcbiAgICAvLyBJUklcbiAgICBkZWZhdWx0OlxuICAgICAgcmV0dXJuIHRoaXMuZW5jb2RlSVJJKHZhbHVlKTtcbiAgICB9XG4gIH1cbiAgLy8gcHJvcGVydHkgcGF0aFxuICBlbHNlIHtcbiAgICB2YXIgaXRlbXMgPSB2YWx1ZS5pdGVtcy5tYXAodGhpcy50b0VudGl0eSwgdGhpcyksIHBhdGggPSB2YWx1ZS5wYXRoVHlwZTtcbiAgICBzd2l0Y2ggKHBhdGgpIHtcbiAgICAvLyBwcmVmaXggb3BlcmF0b3JcbiAgICBjYXNlICdeJzpcbiAgICBjYXNlICchJzpcbiAgICAgIHJldHVybiBwYXRoICsgaXRlbXNbMF07XG4gICAgLy8gcG9zdGZpeCBvcGVyYXRvclxuICAgIGNhc2UgJyonOlxuICAgIGNhc2UgJysnOlxuICAgIGNhc2UgJz8nOlxuICAgICAgcmV0dXJuICcoJyArIGl0ZW1zWzBdICsgcGF0aCArICcpJztcbiAgICAvLyBpbmZpeCBvcGVyYXRvclxuICAgIGRlZmF1bHQ6XG4gICAgICByZXR1cm4gJygnICsgaXRlbXMuam9pbihwYXRoKSArICcpJztcbiAgICB9XG4gIH1cbn07XG52YXIgZXNjYXBlID0gL1tcIlxcXFxcXHRcXG5cXHJcXGJcXGZdL2csXG4gICAgZXNjYXBlUmVwbGFjZXIgPSBmdW5jdGlvbiAoYykgeyByZXR1cm4gZXNjYXBlUmVwbGFjZW1lbnRzW2NdOyB9LFxuICAgIGVzY2FwZVJlcGxhY2VtZW50cyA9IHsgJ1xcXFwnOiAnXFxcXFxcXFwnLCAnXCInOiAnXFxcXFwiJywgJ1xcdCc6ICdcXFxcdCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAnXFxuJzogJ1xcXFxuJywgJ1xccic6ICdcXFxccicsICdcXGInOiAnXFxcXGInLCAnXFxmJzogJ1xcXFxmJyB9O1xuXG4vLyBSZXByZXNlbnQgdGhlIElSSSwgYXMgYSBwcmVmaXhlZCBuYW1lIHdoZW4gcG9zc2libGVcbkdlbmVyYXRvci5wcm90b3R5cGUuZW5jb2RlSVJJID0gZnVuY3Rpb24gKGlyaSkge1xuICB2YXIgcHJlZml4TWF0Y2ggPSB0aGlzLl9wcmVmaXhSZWdleC5leGVjKGlyaSk7XG4gIGlmIChwcmVmaXhNYXRjaCkge1xuICAgIHZhciBwcmVmaXggPSB0aGlzLl9wcmVmaXhCeUlyaVtwcmVmaXhNYXRjaFsxXV07XG4gICAgdGhpcy5fdXNlZFByZWZpeGVzW3ByZWZpeF0gPSB0cnVlO1xuICAgIHJldHVybiBwcmVmaXggKyAnOicgKyBwcmVmaXhNYXRjaFsyXTtcbiAgfVxuICByZXR1cm4gJzwnICsgaXJpICsgJz4nO1xufTtcblxuLy8gQ29udmVydHMgdGhlIHBhcnNlZCB1cGRhdGUgb2JqZWN0IGludG8gYSBTUEFSUUwgdXBkYXRlIGNsYXVzZVxuR2VuZXJhdG9yLnByb3RvdHlwZS50b1VwZGF0ZSA9IGZ1bmN0aW9uICh1cGRhdGUpIHtcbiAgc3dpdGNoICh1cGRhdGUudHlwZSB8fCB1cGRhdGUudXBkYXRlVHlwZSkge1xuICBjYXNlICdsb2FkJzpcbiAgICByZXR1cm4gJ0xPQUQnICsgKHVwZGF0ZS5zb3VyY2UgPyAnICcgKyB0aGlzLnRvRW50aXR5KHVwZGF0ZS5zb3VyY2UpIDogJycpICtcbiAgICAgICAgICAgKHVwZGF0ZS5kZXN0aW5hdGlvbiA/ICcgSU5UTyBHUkFQSCAnICsgdGhpcy50b0VudGl0eSh1cGRhdGUuZGVzdGluYXRpb24pIDogJycpO1xuICBjYXNlICdpbnNlcnQnOlxuICAgIHJldHVybiAnSU5TRVJUIERBVEEgJyAgKyB0aGlzLmdyb3VwKHVwZGF0ZS5pbnNlcnQsIHRydWUpO1xuICBjYXNlICdkZWxldGUnOlxuICAgIHJldHVybiAnREVMRVRFIERBVEEgJyAgKyB0aGlzLmdyb3VwKHVwZGF0ZS5kZWxldGUsIHRydWUpO1xuICBjYXNlICdkZWxldGV3aGVyZSc6XG4gICAgcmV0dXJuICdERUxFVEUgV0hFUkUgJyArIHRoaXMuZ3JvdXAodXBkYXRlLmRlbGV0ZSwgdHJ1ZSk7XG4gIGNhc2UgJ2luc2VydGRlbGV0ZSc6XG4gICAgcmV0dXJuICh1cGRhdGUuZ3JhcGggPyAnV0lUSCAnICsgdGhpcy50b0VudGl0eSh1cGRhdGUuZ3JhcGgpICsgdGhpcy5fbmV3bGluZSA6ICcnKSArXG4gICAgICAgICAgICh1cGRhdGUuZGVsZXRlLmxlbmd0aCA/ICdERUxFVEUgJyArIHRoaXMuZ3JvdXAodXBkYXRlLmRlbGV0ZSwgdHJ1ZSkgKyB0aGlzLl9uZXdsaW5lIDogJycpICtcbiAgICAgICAgICAgKHVwZGF0ZS5pbnNlcnQubGVuZ3RoID8gJ0lOU0VSVCAnICsgdGhpcy5ncm91cCh1cGRhdGUuaW5zZXJ0LCB0cnVlKSArIHRoaXMuX25ld2xpbmUgOiAnJykgK1xuICAgICAgICAgICAnV0hFUkUgJyArIHRoaXMuZ3JvdXAodXBkYXRlLndoZXJlLCB0cnVlKTtcbiAgY2FzZSAnYWRkJzpcbiAgY2FzZSAnY29weSc6XG4gIGNhc2UgJ21vdmUnOlxuICAgIHJldHVybiB1cGRhdGUudHlwZS50b1VwcGVyQ2FzZSgpICsgKHVwZGF0ZS5zb3VyY2UuZGVmYXVsdCA/ICcgREVGQVVMVCAnIDogJyAnKSArXG4gICAgICAgICAgICdUTyAnICsgdGhpcy50b0VudGl0eSh1cGRhdGUuZGVzdGluYXRpb24ubmFtZSk7XG4gIGNhc2UgJ2NyZWF0ZSc6XG4gIGNhc2UgJ2NsZWFyJzpcbiAgY2FzZSAnZHJvcCc6XG4gICAgcmV0dXJuIHVwZGF0ZS50eXBlLnRvVXBwZXJDYXNlKCkgKyAodXBkYXRlLnNpbGVudCA/ICcgU0lMRU5UICcgOiAnICcpICsgKFxuICAgICAgdXBkYXRlLmdyYXBoLmRlZmF1bHQgPyAnREVGQVVMVCcgOlxuICAgICAgdXBkYXRlLmdyYXBoLm5hbWVkID8gJ05BTUVEJyA6XG4gICAgICB1cGRhdGUuZ3JhcGguYWxsID8gJ0FMTCcgOlxuICAgICAgKCdHUkFQSCAnICsgdGhpcy50b0VudGl0eSh1cGRhdGUuZ3JhcGgubmFtZSkpXG4gICAgKTtcbiAgZGVmYXVsdDpcbiAgICB0aHJvdyBuZXcgRXJyb3IoJ1Vua25vd24gdXBkYXRlIHF1ZXJ5IHR5cGU6ICcgKyB1cGRhdGUudHlwZSk7XG4gIH1cbn07XG5cbi8vIEluZGVudHMgZWFjaCBsaW5lIG9mIHRoZSBzdHJpbmdcbkdlbmVyYXRvci5wcm90b3R5cGUuaW5kZW50ID0gZnVuY3Rpb24odGV4dCkgeyByZXR1cm4gdGV4dC5yZXBsYWNlKC9eL2dtLCB0aGlzLl9pbmRlbnQpOyB9XG5cbi8vIENoZWNrcyB3aGV0aGVyIHRoZSBvYmplY3QgaXMgYSBzdHJpbmdcbmZ1bmN0aW9uIGlzU3RyaW5nKG9iamVjdCkgeyByZXR1cm4gdHlwZW9mIG9iamVjdCA9PT0gJ3N0cmluZyc7IH1cblxuLy8gTWFwcyB0aGUgYXJyYXkgd2l0aCB0aGUgZ2l2ZW4gZnVuY3Rpb24sIGFuZCBqb2lucyB0aGUgcmVzdWx0cyB1c2luZyB0aGUgc2VwYXJhdG9yXG5mdW5jdGlvbiBtYXBKb2luKGFycmF5LCBzZXAsIGZ1bmMsIHNlbGYpIHtcbiAgcmV0dXJuIGFycmF5Lm1hcChmdW5jLCBzZWxmKS5qb2luKGlzU3RyaW5nKHNlcCkgPyBzZXAgOiAnICcpO1xufVxuXG4vKipcbiAqIEBwYXJhbSBvcHRpb25zIHtcbiAqICAgYWxsUHJlZml4ZXM6IGJvb2xlYW4sXG4gKiAgIGluZGVudGF0aW9uOiBzdHJpbmcsXG4gKiAgIG5ld2xpbmU6IHN0cmluZ1xuICogfVxuICovXG5tb2R1bGUuZXhwb3J0cyA9IGZ1bmN0aW9uIFNwYXJxbEdlbmVyYXRvcihvcHRpb25zKSB7XG4gIHJldHVybiB7XG4gICAgc3RyaW5naWZ5OiBmdW5jdGlvbiAocSkgeyByZXR1cm4gbmV3IEdlbmVyYXRvcihvcHRpb25zLCBxLnByZWZpeGVzKS50b1F1ZXJ5KHEpOyB9XG4gIH07XG59O1xuIiwiLyogcGFyc2VyIGdlbmVyYXRlZCBieSBqaXNvbiAwLjQuMTggKi9cbi8qXG4gIFJldHVybnMgYSBQYXJzZXIgb2JqZWN0IG9mIHRoZSBmb2xsb3dpbmcgc3RydWN0dXJlOlxuXG4gIFBhcnNlcjoge1xuICAgIHl5OiB7fVxuICB9XG5cbiAgUGFyc2VyLnByb3RvdHlwZToge1xuICAgIHl5OiB7fSxcbiAgICB0cmFjZTogZnVuY3Rpb24oKSxcbiAgICBzeW1ib2xzXzoge2Fzc29jaWF0aXZlIGxpc3Q6IG5hbWUgPT0+IG51bWJlcn0sXG4gICAgdGVybWluYWxzXzoge2Fzc29jaWF0aXZlIGxpc3Q6IG51bWJlciA9PT4gbmFtZX0sXG4gICAgcHJvZHVjdGlvbnNfOiBbLi4uXSxcbiAgICBwZXJmb3JtQWN0aW9uOiBmdW5jdGlvbiBhbm9ueW1vdXMoeXl0ZXh0LCB5eWxlbmcsIHl5bGluZW5vLCB5eSwgeXlzdGF0ZSwgJCQsIF8kKSxcbiAgICB0YWJsZTogWy4uLl0sXG4gICAgZGVmYXVsdEFjdGlvbnM6IHsuLi59LFxuICAgIHBhcnNlRXJyb3I6IGZ1bmN0aW9uKHN0ciwgaGFzaCksXG4gICAgcGFyc2U6IGZ1bmN0aW9uKGlucHV0KSxcblxuICAgIGxleGVyOiB7XG4gICAgICAgIEVPRjogMSxcbiAgICAgICAgcGFyc2VFcnJvcjogZnVuY3Rpb24oc3RyLCBoYXNoKSxcbiAgICAgICAgc2V0SW5wdXQ6IGZ1bmN0aW9uKGlucHV0KSxcbiAgICAgICAgaW5wdXQ6IGZ1bmN0aW9uKCksXG4gICAgICAgIHVucHV0OiBmdW5jdGlvbihzdHIpLFxuICAgICAgICBtb3JlOiBmdW5jdGlvbigpLFxuICAgICAgICBsZXNzOiBmdW5jdGlvbihuKSxcbiAgICAgICAgcGFzdElucHV0OiBmdW5jdGlvbigpLFxuICAgICAgICB1cGNvbWluZ0lucHV0OiBmdW5jdGlvbigpLFxuICAgICAgICBzaG93UG9zaXRpb246IGZ1bmN0aW9uKCksXG4gICAgICAgIHRlc3RfbWF0Y2g6IGZ1bmN0aW9uKHJlZ2V4X21hdGNoX2FycmF5LCBydWxlX2luZGV4KSxcbiAgICAgICAgbmV4dDogZnVuY3Rpb24oKSxcbiAgICAgICAgbGV4OiBmdW5jdGlvbigpLFxuICAgICAgICBiZWdpbjogZnVuY3Rpb24oY29uZGl0aW9uKSxcbiAgICAgICAgcG9wU3RhdGU6IGZ1bmN0aW9uKCksXG4gICAgICAgIF9jdXJyZW50UnVsZXM6IGZ1bmN0aW9uKCksXG4gICAgICAgIHRvcFN0YXRlOiBmdW5jdGlvbigpLFxuICAgICAgICBwdXNoU3RhdGU6IGZ1bmN0aW9uKGNvbmRpdGlvbiksXG5cbiAgICAgICAgb3B0aW9uczoge1xuICAgICAgICAgICAgcmFuZ2VzOiBib29sZWFuICAgICAgICAgICAob3B0aW9uYWw6IHRydWUgPT0+IHRva2VuIGxvY2F0aW9uIGluZm8gd2lsbCBpbmNsdWRlIGEgLnJhbmdlW10gbWVtYmVyKVxuICAgICAgICAgICAgZmxleDogYm9vbGVhbiAgICAgICAgICAgICAob3B0aW9uYWw6IHRydWUgPT0+IGZsZXgtbGlrZSBsZXhpbmcgYmVoYXZpb3VyIHdoZXJlIHRoZSBydWxlcyBhcmUgdGVzdGVkIGV4aGF1c3RpdmVseSB0byBmaW5kIHRoZSBsb25nZXN0IG1hdGNoKVxuICAgICAgICAgICAgYmFja3RyYWNrX2xleGVyOiBib29sZWFuICAob3B0aW9uYWw6IHRydWUgPT0+IGxleGVyIHJlZ2V4ZXMgYXJlIHRlc3RlZCBpbiBvcmRlciBhbmQgZm9yIGVhY2ggbWF0Y2hpbmcgcmVnZXggdGhlIGFjdGlvbiBjb2RlIGlzIGludm9rZWQ7IHRoZSBsZXhlciB0ZXJtaW5hdGVzIHRoZSBzY2FuIHdoZW4gYSB0b2tlbiBpcyByZXR1cm5lZCBieSB0aGUgYWN0aW9uIGNvZGUpXG4gICAgICAgIH0sXG5cbiAgICAgICAgcGVyZm9ybUFjdGlvbjogZnVuY3Rpb24oeXksIHl5XywgJGF2b2lkaW5nX25hbWVfY29sbGlzaW9ucywgWVlfU1RBUlQpLFxuICAgICAgICBydWxlczogWy4uLl0sXG4gICAgICAgIGNvbmRpdGlvbnM6IHthc3NvY2lhdGl2ZSBsaXN0OiBuYW1lID09PiBzZXR9LFxuICAgIH1cbiAgfVxuXG5cbiAgdG9rZW4gbG9jYXRpb24gaW5mbyAoQCQsIF8kLCBldGMuKToge1xuICAgIGZpcnN0X2xpbmU6IG4sXG4gICAgbGFzdF9saW5lOiBuLFxuICAgIGZpcnN0X2NvbHVtbjogbixcbiAgICBsYXN0X2NvbHVtbjogbixcbiAgICByYW5nZTogW3N0YXJ0X251bWJlciwgZW5kX251bWJlcl0gICAgICAgKHdoZXJlIHRoZSBudW1iZXJzIGFyZSBpbmRleGVzIGludG8gdGhlIGlucHV0IHN0cmluZywgcmVndWxhciB6ZXJvLWJhc2VkKVxuICB9XG5cblxuICB0aGUgcGFyc2VFcnJvciBmdW5jdGlvbiByZWNlaXZlcyBhICdoYXNoJyBvYmplY3Qgd2l0aCB0aGVzZSBtZW1iZXJzIGZvciBsZXhlciBhbmQgcGFyc2VyIGVycm9yczoge1xuICAgIHRleHQ6ICAgICAgICAobWF0Y2hlZCB0ZXh0KVxuICAgIHRva2VuOiAgICAgICAodGhlIHByb2R1Y2VkIHRlcm1pbmFsIHRva2VuLCBpZiBhbnkpXG4gICAgbGluZTogICAgICAgICh5eWxpbmVubylcbiAgfVxuICB3aGlsZSBwYXJzZXIgKGdyYW1tYXIpIGVycm9ycyB3aWxsIGFsc28gcHJvdmlkZSB0aGVzZSBtZW1iZXJzLCBpLmUuIHBhcnNlciBlcnJvcnMgZGVsaXZlciBhIHN1cGVyc2V0IG9mIGF0dHJpYnV0ZXM6IHtcbiAgICBsb2M6ICAgICAgICAgKHl5bGxvYylcbiAgICBleHBlY3RlZDogICAgKHN0cmluZyBkZXNjcmliaW5nIHRoZSBzZXQgb2YgZXhwZWN0ZWQgdG9rZW5zKVxuICAgIHJlY292ZXJhYmxlOiAoYm9vbGVhbjogVFJVRSB3aGVuIHRoZSBwYXJzZXIgaGFzIGEgZXJyb3IgcmVjb3ZlcnkgcnVsZSBhdmFpbGFibGUgZm9yIHRoaXMgcGFydGljdWxhciBlcnJvcilcbiAgfVxuKi9cbnZhciBTcGFycWxQYXJzZXIgPSAoZnVuY3Rpb24oKXtcbnZhciBvPWZ1bmN0aW9uKGssdixvLGwpe2ZvcihvPW98fHt9LGw9ay5sZW5ndGg7bC0tO29ba1tsXV09dik7cmV0dXJuIG99LCRWMD1bNiwxMiwxNSwyNCwzNCw0Myw0OCw5OSwxMDksMTEyLDExNCwxMTUsMTI0LDEyNSwxMzAsMjk4LDI5OSwzMDAsMzAxLDMwMl0sJFYxPVsyLDE5Nl0sJFYyPVs5OSwxMDksMTEyLDExNCwxMTUsMTI0LDEyNSwxMzAsMjk4LDI5OSwzMDAsMzAxLDMwMl0sJFYzPVsxLDE4XSwkVjQ9WzEsMjddLCRWNT1bNiw4M10sJFY2PVszOCwzOSw1MV0sJFY3PVszOCw1MV0sJFY4PVsxLDU1XSwkVjk9WzEsNTddLCRWYT1bMSw1M10sJFZiPVsxLDU2XSwkVmM9WzI4LDI5LDI5M10sJFZkPVsxMywxNiwyODZdLCRWZT1bMTExLDEzMywyOTYsMzAzXSwkVmY9WzEzLDE2LDExMSwxMzMsMjg2XSwkVmc9WzEsODBdLCRWaD1bMSw4NF0sJFZpPVsxLDg2XSwkVmo9WzExMSwxMzMsMjk2LDI5NywzMDNdLCRWaz1bMTMsMTYsMTExLDEzMywyODYsMjk3XSwkVmw9WzEsOTJdLCRWbT1bMiwyMzZdLCRWbj1bMSw5MV0sJFZvPVsxMywxNiwyOCwyOSw4MCw4NiwyMTUsMjE4LDIxOSwyNzIsMjczLDI3NCwyNzUsMjc2LDI3NywyNzgsMjc5LDI4MCwyODEsMjgyLDI4MywyODQsMjg1LDI4Nl0sJFZwPVs2LDM4LDM5LDUxLDYxLDY4LDcxLDc5LDgxLDgzXSwkVnE9WzYsMTMsMTYsMjgsMzgsMzksNTEsNjEsNjgsNzEsNzksODEsODMsMjg2XSwkVnI9WzYsMTMsMTYsMjgsMjksMzEsMzIsMzgsMzksNDEsNTEsNjEsNjgsNzEsNzksODAsODEsODMsODYsOTIsMTA4LDExMSwxMjQsMTI1LDEyNywxMzIsMTU5LDE2MCwxNjIsMTY1LDE2NiwxODMsMTg3LDIwOCwyMTMsMjE1LDIxNiwyMTgsMjE5LDIyMywyMjcsMjMxLDI0NiwyNTEsMjY4LDI3MiwyNzMsMjc0LDI3NSwyNzYsMjc3LDI3OCwyNzksMjgwLDI4MSwyODIsMjgzLDI4NCwyODUsMjg2LDI5MywzMDQsMzA2LDMwNywzMDksMzEwLDMxMSwzMTIsMzEzLDMxNCwzMTUsMzE2XSwkVnM9WzEsMTA3XSwkVnQ9WzEsMTA4XSwkVnU9WzYsMTMsMTYsMjgsMjksMzksNDEsODAsODMsODYsMTExLDE1OSwxNjAsMTYyLDE2NSwxNjYsMjE1LDIxOCwyMTksMjcyLDI3MywyNzQsMjc1LDI3NiwyNzcsMjc4LDI3OSwyODAsMjgxLDI4MiwyODMsMjg0LDI4NSwyODYsMzA0XSwkVnY9WzIsMjk1XSwkVnc9WzEsMTI1XSwkVng9WzEsMTIzXSwkVnk9WzYsMTgzXSwkVno9WzIsMzEyXSwkVkE9WzIsMzAwXSwkVkI9WzM4LDEyN10sJFZDPVs2LDQxLDY4LDcxLDc5LDgxLDgzXSwkVkQ9WzIsMjM4XSwkVkU9WzEsMTM5XSwkVkY9WzEsMTQxXSwkVkc9WzEsMTUxXSwkVkg9WzEsMTU3XSwkVkk9WzEsMTYwXSwkVko9WzEsMTU2XSwkVks9WzEsMTU4XSwkVkw9WzEsMTU0XSwkVk09WzEsMTU1XSwkVk49WzEsMTYxXSwkVk89WzEsMTYyXSwkVlA9WzEsMTY1XSwkVlE9WzEsMTY2XSwkVlI9WzEsMTY3XSwkVlM9WzEsMTY4XSwkVlQ9WzEsMTY5XSwkVlU9WzEsMTcwXSwkVlY9WzEsMTcxXSwkVlc9WzEsMTcyXSwkVlg9WzEsMTczXSwkVlk9WzEsMTc0XSwkVlo9WzEsMTc1XSwkVl89WzEsMTc2XSwkViQ9WzYsNjEsNjgsNzEsNzksODEsODNdLCRWMDE9WzI4LDI5LDM4LDM5LDUxXSwkVjExPVsxMywxNiwyOCwyOSw4MCwyNDgsMjQ5LDI1MCwyNTIsMjU0LDI1NSwyNTcsMjU4LDI2MSwyNjMsMjcyLDI3MywyNzQsMjc1LDI3NiwyNzcsMjc4LDI3OSwyODAsMjgxLDI4MiwyODMsMjg0LDI4NSwyODYsMzE2LDMxNywzMTgsMzE5LDMyMCwzMjFdLCRWMjE9WzIsNDA5XSwkVjMxPVsxLDE4OV0sJFY0MT1bMSwxOTBdLCRWNTE9WzEsMTkxXSwkVjYxPVsxMywxNiw0MSw4MCw5MiwyNzIsMjczLDI3NCwyNzUsMjc2LDI3NywyNzgsMjc5LDI4MCwyODEsMjgyLDI4MywyODQsMjg1LDI4Nl0sJFY3MT1bNDEsODZdLCRWODE9WzI4LDMyXSwkVjkxPVs2LDEwOCwxODNdLCRWYTE9WzQxLDExMV0sJFZiMT1bNiw0MSw3MSw3OSw4MSw4M10sJFZjMT1bMiwzMjRdLCRWZDE9WzIsMzE2XSwkVmUxPVsxLDIyNl0sJFZmMT1bMSwyMjhdLCRWZzE9WzQxLDExMSwzMDRdLCRWaDE9WzEzLDE2LDI4LDI5LDMyLDM5LDQxLDgwLDgzLDg2LDExMSwxNTksMTYwLDE2MiwxNjUsMTY2LDE4MywxODcsMjA4LDIxMywyMTUsMjE2LDIxOCwyMTksMjUxLDI3MiwyNzMsMjc0LDI3NSwyNzYsMjc3LDI3OCwyNzksMjgwLDI4MSwyODIsMjgzLDI4NCwyODUsMjg2LDMwNF0sJFZpMT1bMTMsMTYsMjgsMjksMzEsMzIsMzksNDEsODAsODMsODYsOTIsMTExLDE1OSwxNjAsMTYyLDE2NSwxNjYsMTgzLDE4NywyMDgsMjEzLDIxNSwyMTYsMjE4LDIxOSwyMjMsMjI3LDIzMSwyNDYsMjUxLDI2OCwyNzIsMjczLDI3NCwyNzUsMjc2LDI3NywyNzgsMjc5LDI4MCwyODEsMjgyLDI4MywyODQsMjg1LDI4NiwyOTMsMzA0LDMwNywzMTAsMzExLDMxMiwzMTMsMzE0LDMxNSwzMTZdLCRWajE9WzEzLDE2LDI4LDI5LDMxLDMyLDM5LDQxLDgwLDgzLDg2LDkyLDExMSwxNTksMTYwLDE2MiwxNjUsMTY2LDE4MywxODcsMjA4LDIxMywyMTUsMjE2LDIxOCwyMTksMjIzLDIyNywyMzEsMjQ2LDI1MSwyNjgsMjcwLDI3MSwyNzIsMjczLDI3NCwyNzUsMjc2LDI3NywyNzgsMjc5LDI4MCwyODEsMjgyLDI4MywyODQsMjg1LDI4NiwyOTMsMzA0LDMwNywzMTAsMzExLDMxMiwzMTMsMzE0LDMxNSwzMTZdLCRWazE9WzMxLDMyLDE4MywyMjMsMjUxXSwkVmwxPVszMSwzMiwxODMsMjIzLDIyNywyNTFdLCRWbTE9WzMxLDMyLDE4MywyMjMsMjI3LDIzMSwyNDYsMjUxLDI2OCwyODAsMjgxLDI4MiwyODMsMjg0LDI4NSwzMTAsMzExLDMxMiwzMTMsMzE0LDMxNSwzMTZdLCRWbjE9WzMxLDMyLDE4MywyMjMsMjI3LDIzMSwyNDYsMjUxLDI2OCwyODAsMjgxLDI4MiwyODMsMjg0LDI4NSwyOTMsMzA3LDMxMCwzMTEsMzEyLDMxMywzMTQsMzE1LDMxNl0sJFZvMT1bMSwyNjBdLCRWcDE9WzEsMjYxXSwkVnExPVsxLDI2M10sJFZyMT1bMSwyNjRdLCRWczE9WzEsMjY1XSwkVnQxPVsxLDI2Nl0sJFZ1MT1bMSwyNjhdLCRWdjE9WzEsMjY5XSwkVncxPVsyLDQxNl0sJFZ4MT1bMSwyNzFdLCRWeTE9WzEsMjcyXSwkVnoxPVsxLDI3M10sJFZBMT1bMSwyNzldLCRWQjE9WzEsMjc0XSwkVkMxPVsxLDI3NV0sJFZEMT1bMSwyNzZdLCRWRTE9WzEsMjc3XSwkVkYxPVsxLDI3OF0sJFZHMT1bMSwyODZdLCRWSDE9WzEsMjk5XSwkVkkxPVs2LDQxLDc5LDgxLDgzXSwkVkoxPVsxLDMxNl0sJFZLMT1bMSwzMTVdLCRWTDE9WzM5LDQxLDgzLDExMSwxNTksMTYwLDE2MiwxNjUsMTY2XSwkVk0xPVsxLDMyNF0sJFZOMT1bMSwzMjVdLCRWTzE9WzQxLDExMSwxODMsMjE2LDMwNF0sJFZQMT1bMiwzNTRdLCRWUTE9WzEzLDE2LDI4LDI5LDMyLDgwLDg2LDIxNSwyMTgsMjE5LDI3MiwyNzMsMjc0LDI3NSwyNzYsMjc3LDI3OCwyNzksMjgwLDI4MSwyODIsMjgzLDI4NCwyODUsMjg2XSwkVlIxPVsxMywxNiwyOCwyOSwzMiwzOSw0MSw4MCw4Myw4NiwxMTEsMTU5LDE2MCwxNjIsMTY1LDE2NiwxODMsMjE1LDIxNiwyMTgsMjE5LDI1MSwyNzIsMjczLDI3NCwyNzUsMjc2LDI3NywyNzgsMjc5LDI4MCwyODEsMjgyLDI4MywyODQsMjg1LDI4NiwzMDRdLCRWUzE9WzEzLDE2LDI4LDI5LDgwLDIwOCwyNDYsMjQ4LDI0OSwyNTAsMjUyLDI1NCwyNTUsMjU3LDI1OCwyNjEsMjYzLDI3MiwyNzMsMjc0LDI3NSwyNzYsMjc3LDI3OCwyNzksMjgwLDI4MSwyODIsMjgzLDI4NCwyODUsMjg2LDMxMCwzMTYsMzE3LDMxOCwzMTksMzIwLDMyMV0sJFZUMT1bMSwzNDldLCRWVTE9WzEsMzUwXSwkVlYxPVsxLDM1Ml0sJFZXMT1bMSwzNTFdLCRWWDE9WzYsMTMsMTYsMjgsMjksMzEsMzIsMzksNDEsNjgsNzEsNzQsNzYsNzksODAsODEsODMsODYsMTExLDE1OSwxNjAsMTYyLDE2NSwxNjYsMTgzLDIxNSwyMTgsMjE5LDIyMywyMjcsMjMxLDI0NiwyNDgsMjQ5LDI1MCwyNTEsMjUyLDI1NCwyNTUsMjU3LDI1OCwyNjEsMjYzLDI2OCwyNzIsMjczLDI3NCwyNzUsMjc2LDI3NywyNzgsMjc5LDI4MCwyODEsMjgyLDI4MywyODQsMjg1LDI4NiwyOTMsMzA0LDMwNywzMTAsMzExLDMxMiwzMTMsMzE0LDMxNSwzMTYsMzE3LDMxOCwzMTksMzIwLDMyMV0sJFZZMT1bMSwzNjBdLCRWWjE9WzEsMzU5XSwkVl8xPVsyOSw4Nl0sJFYkMT1bMTMsMTYsMzIsNDEsODAsOTIsMjcyLDI3MywyNzQsMjc1LDI3NiwyNzcsMjc4LDI3OSwyODAsMjgxLDI4MiwyODMsMjg0LDI4NSwyODZdLCRWMDI9WzI5LDQxXSwkVjEyPVsyLDMxNV0sJFYyMj1bNiw0MSw4M10sJFYzMj1bNiwxMywxNiwyOSw0MSw3MSw3OSw4MSw4MywyNDgsMjQ5LDI1MCwyNTIsMjU0LDI1NSwyNTcsMjU4LDI2MSwyNjMsMjg2LDMxNiwzMTcsMzE4LDMxOSwzMjAsMzIxXSwkVjQyPVs2LDEzLDE2LDI4LDI5LDM5LDQxLDcxLDc0LDc2LDc5LDgwLDgxLDgzLDg2LDExMSwxNTksMTYwLDE2MiwxNjUsMTY2LDIxNSwyMTgsMjE5LDI0OCwyNDksMjUwLDI1MiwyNTQsMjU1LDI1NywyNTgsMjYxLDI2MywyNzIsMjczLDI3NCwyNzUsMjc2LDI3NywyNzgsMjc5LDI4MCwyODEsMjgyLDI4MywyODQsMjg1LDI4NiwzMDQsMzE2LDMxNywzMTgsMzE5LDMyMCwzMjFdLCRWNTI9WzYsMTMsMTYsMjgsMjksNDEsNjgsNzEsNzksODEsODMsMjQ4LDI0OSwyNTAsMjUyLDI1NCwyNTUsMjU3LDI1OCwyNjEsMjYzLDI4NiwzMTYsMzE3LDMxOCwzMTksMzIwLDMyMV0sJFY2Mj1bNiwxMywxNiwyOCwyOSwzMSwzMiwzOSw0MSw2MSw2OCw3MSw3NCw3Niw3OSw4MCw4MSw4Myw4NiwxMTEsMTU5LDE2MCwxNjIsMTY1LDE2NiwxODMsMjE1LDIxOCwyMTksMjIzLDIyNywyMzEsMjQ2LDI0OCwyNDksMjUwLDI1MSwyNTIsMjU0LDI1NSwyNTcsMjU4LDI2MSwyNjMsMjY4LDI3MiwyNzMsMjc0LDI3NSwyNzYsMjc3LDI3OCwyNzksMjgwLDI4MSwyODIsMjgzLDI4NCwyODUsMjg2LDI5MywzMDQsMzA1LDMwNywzMTAsMzExLDMxMiwzMTMsMzE0LDMxNSwzMTYsMzE3LDMxOCwzMTksMzIwLDMyMV0sJFY3Mj1bMTMsMTYsMjksMTg3LDIwOCwyMTMsMjg2XSwkVjgyPVsyLDM2Nl0sJFY5Mj1bMSw0MDFdLCRWYTI9WzM5LDQxLDgzLDExMSwxNTksMTYwLDE2MiwxNjUsMTY2LDMwNF0sJFZiMj1bMTMsMTYsMjgsMjksMzIsMzksNDEsODAsODMsODYsMTExLDE1OSwxNjAsMTYyLDE2NSwxNjYsMTgzLDE4NywyMTUsMjE2LDIxOCwyMTksMjUxLDI3MiwyNzMsMjc0LDI3NSwyNzYsMjc3LDI3OCwyNzksMjgwLDI4MSwyODIsMjgzLDI4NCwyODUsMjg2LDMwNF0sJFZjMj1bMTMsMTYsMjgsMjksODAsMjA4LDI0NiwyNDgsMjQ5LDI1MCwyNTIsMjU0LDI1NSwyNTcsMjU4LDI2MSwyNjMsMjcyLDI3MywyNzQsMjc1LDI3NiwyNzcsMjc4LDI3OSwyODAsMjgxLDI4MiwyODMsMjg0LDI4NSwyODYsMjkzLDMxMCwzMTYsMzE3LDMxOCwzMTksMzIwLDMyMV0sJFZkMj1bMSw0NTBdLCRWZTI9WzEsNDQ3XSwkVmYyPVsxLDQ0OF0sJFZnMj1bMTMsMTYsMjgsMjksMzksNDEsODAsODMsODYsMTExLDE1OSwxNjAsMTYyLDE2NSwxNjYsMjE1LDIxOCwyMTksMjcyLDI3MywyNzQsMjc1LDI3NiwyNzcsMjc4LDI3OSwyODAsMjgxLDI4MiwyODMsMjg0LDI4NSwyODZdLCRWaDI9WzEzLDE2LDI4LDI4Nl0sJFZpMj1bMTMsMTYsMjgsMjksMzksNDEsODAsODMsODYsMTExLDE1OSwxNjAsMTYyLDE2NSwxNjYsMjE1LDIxOCwyMTksMjcyLDI3MywyNzQsMjc1LDI3NiwyNzcsMjc4LDI3OSwyODAsMjgxLDI4MiwyODMsMjg0LDI4NSwyODYsMzA0XSwkVmoyPVsyLDMyN10sJFZrMj1bMzksNDEsODMsMTExLDE1OSwxNjAsMTYyLDE2NSwxNjYsMTgzLDIxNiwzMDRdLCRWbDI9WzYsMTMsMTYsMjgsMjksNDEsNzQsNzYsNzksODEsODMsMjQ4LDI0OSwyNTAsMjUyLDI1NCwyNTUsMjU3LDI1OCwyNjEsMjYzLDI4NiwzMTYsMzE3LDMxOCwzMTksMzIwLDMyMV0sJFZtMj1bMiwzMjJdLCRWbjI9WzEzLDE2LDI5LDE4NywyMDgsMjg2XSwkVm8yPVsxMywxNiwzMiw4MCw5MiwyNzIsMjczLDI3NCwyNzUsMjc2LDI3NywyNzgsMjc5LDI4MCwyODEsMjgyLDI4MywyODQsMjg1LDI4Nl0sJFZwMj1bMTMsMTYsMjgsMjksNDEsODAsODYsMTExLDIxNSwyMTgsMjE5LDI3MiwyNzMsMjc0LDI3NSwyNzYsMjc3LDI3OCwyNzksMjgwLDI4MSwyODIsMjgzLDI4NCwyODUsMjg2XSwkVnEyPVsxMywxNiwyOCwyOSwzMiw4MCw4NiwyMTUsMjE4LDIxOSwyNzIsMjczLDI3NCwyNzUsMjc2LDI3NywyNzgsMjc5LDI4MCwyODEsMjgyLDI4MywyODQsMjg1LDI4NiwzMDYsMzA3XSwkVnIyPVsxMywxNiwyOCwyOSwzMiw4MCw4NiwyMTUsMjE4LDIxOSwyNzIsMjczLDI3NCwyNzUsMjc2LDI3NywyNzgsMjc5LDI4MCwyODEsMjgyLDI4MywyODQsMjg1LDI4NiwyOTMsMzA2LDMwNywzMDksMzEwXSwkVnMyPVsxLDU2MV0sJFZ0Mj1bMSw1NjJdLCRWdTI9WzIsMzEwXSwkVnYyPVsxMywxNiwzMiwxODcsMjEzLDI4Nl07XG52YXIgcGFyc2VyID0ge3RyYWNlOiBmdW5jdGlvbiB0cmFjZSAoKSB7IH0sXG55eToge30sXG5zeW1ib2xzXzoge1wiZXJyb3JcIjoyLFwiUXVlcnlPclVwZGF0ZVwiOjMsXCJQcm9sb2d1ZVwiOjQsXCJRdWVyeU9yVXBkYXRlX2dyb3VwMFwiOjUsXCJFT0ZcIjo2LFwiUHJvbG9ndWVfcmVwZXRpdGlvbjBcIjo3LFwiUXVlcnlcIjo4LFwiUXVlcnlfZ3JvdXAwXCI6OSxcIlF1ZXJ5X29wdGlvbjBcIjoxMCxcIkJhc2VEZWNsXCI6MTEsXCJCQVNFXCI6MTIsXCJJUklSRUZcIjoxMyxcIlByZWZpeERlY2xcIjoxNCxcIlBSRUZJWFwiOjE1LFwiUE5BTUVfTlNcIjoxNixcIlNlbGVjdFF1ZXJ5XCI6MTcsXCJTZWxlY3RDbGF1c2VcIjoxOCxcIlNlbGVjdFF1ZXJ5X3JlcGV0aXRpb24wXCI6MTksXCJXaGVyZUNsYXVzZVwiOjIwLFwiU29sdXRpb25Nb2RpZmllclwiOjIxLFwiU3ViU2VsZWN0XCI6MjIsXCJTdWJTZWxlY3Rfb3B0aW9uMFwiOjIzLFwiU0VMRUNUXCI6MjQsXCJTZWxlY3RDbGF1c2Vfb3B0aW9uMFwiOjI1LFwiU2VsZWN0Q2xhdXNlX2dyb3VwMFwiOjI2LFwiU2VsZWN0Q2xhdXNlSXRlbVwiOjI3LFwiVkFSXCI6MjgsXCIoXCI6MjksXCJFeHByZXNzaW9uXCI6MzAsXCJBU1wiOjMxLFwiKVwiOjMyLFwiQ29uc3RydWN0UXVlcnlcIjozMyxcIkNPTlNUUlVDVFwiOjM0LFwiQ29uc3RydWN0VGVtcGxhdGVcIjozNSxcIkNvbnN0cnVjdFF1ZXJ5X3JlcGV0aXRpb24wXCI6MzYsXCJDb25zdHJ1Y3RRdWVyeV9yZXBldGl0aW9uMVwiOjM3LFwiV0hFUkVcIjozOCxcIntcIjozOSxcIkNvbnN0cnVjdFF1ZXJ5X29wdGlvbjBcIjo0MCxcIn1cIjo0MSxcIkRlc2NyaWJlUXVlcnlcIjo0MixcIkRFU0NSSUJFXCI6NDMsXCJEZXNjcmliZVF1ZXJ5X2dyb3VwMFwiOjQ0LFwiRGVzY3JpYmVRdWVyeV9yZXBldGl0aW9uMFwiOjQ1LFwiRGVzY3JpYmVRdWVyeV9vcHRpb24wXCI6NDYsXCJBc2tRdWVyeVwiOjQ3LFwiQVNLXCI6NDgsXCJBc2tRdWVyeV9yZXBldGl0aW9uMFwiOjQ5LFwiRGF0YXNldENsYXVzZVwiOjUwLFwiRlJPTVwiOjUxLFwiRGF0YXNldENsYXVzZV9vcHRpb24wXCI6NTIsXCJpcmlcIjo1MyxcIldoZXJlQ2xhdXNlX29wdGlvbjBcIjo1NCxcIkdyb3VwR3JhcGhQYXR0ZXJuXCI6NTUsXCJTb2x1dGlvbk1vZGlmaWVyX29wdGlvbjBcIjo1NixcIlNvbHV0aW9uTW9kaWZpZXJfb3B0aW9uMVwiOjU3LFwiU29sdXRpb25Nb2RpZmllcl9vcHRpb24yXCI6NTgsXCJTb2x1dGlvbk1vZGlmaWVyX29wdGlvbjNcIjo1OSxcIkdyb3VwQ2xhdXNlXCI6NjAsXCJHUk9VUFwiOjYxLFwiQllcIjo2MixcIkdyb3VwQ2xhdXNlX3JlcGV0aXRpb25fcGx1czBcIjo2MyxcIkdyb3VwQ29uZGl0aW9uXCI6NjQsXCJCdWlsdEluQ2FsbFwiOjY1LFwiRnVuY3Rpb25DYWxsXCI6NjYsXCJIYXZpbmdDbGF1c2VcIjo2NyxcIkhBVklOR1wiOjY4LFwiSGF2aW5nQ2xhdXNlX3JlcGV0aXRpb25fcGx1czBcIjo2OSxcIk9yZGVyQ2xhdXNlXCI6NzAsXCJPUkRFUlwiOjcxLFwiT3JkZXJDbGF1c2VfcmVwZXRpdGlvbl9wbHVzMFwiOjcyLFwiT3JkZXJDb25kaXRpb25cIjo3MyxcIkFTQ1wiOjc0LFwiQnJhY2tldHRlZEV4cHJlc3Npb25cIjo3NSxcIkRFU0NcIjo3NixcIkNvbnN0cmFpbnRcIjo3NyxcIkxpbWl0T2Zmc2V0Q2xhdXNlc1wiOjc4LFwiTElNSVRcIjo3OSxcIklOVEVHRVJcIjo4MCxcIk9GRlNFVFwiOjgxLFwiVmFsdWVzQ2xhdXNlXCI6ODIsXCJWQUxVRVNcIjo4MyxcIklubGluZURhdGFcIjo4NCxcIklubGluZURhdGFfcmVwZXRpdGlvbjBcIjo4NSxcIk5JTFwiOjg2LFwiSW5saW5lRGF0YV9yZXBldGl0aW9uMVwiOjg3LFwiSW5saW5lRGF0YV9yZXBldGl0aW9uX3BsdXMyXCI6ODgsXCJJbmxpbmVEYXRhX3JlcGV0aXRpb24zXCI6ODksXCJEYXRhQmxvY2tWYWx1ZVwiOjkwLFwiTGl0ZXJhbFwiOjkxLFwiVU5ERUZcIjo5MixcIkRhdGFCbG9ja1ZhbHVlTGlzdFwiOjkzLFwiRGF0YUJsb2NrVmFsdWVMaXN0X3JlcGV0aXRpb25fcGx1czBcIjo5NCxcIlVwZGF0ZVwiOjk1LFwiVXBkYXRlX3JlcGV0aXRpb24wXCI6OTYsXCJVcGRhdGUxXCI6OTcsXCJVcGRhdGVfb3B0aW9uMFwiOjk4LFwiTE9BRFwiOjk5LFwiVXBkYXRlMV9vcHRpb24wXCI6MTAwLFwiVXBkYXRlMV9vcHRpb24xXCI6MTAxLFwiVXBkYXRlMV9ncm91cDBcIjoxMDIsXCJVcGRhdGUxX29wdGlvbjJcIjoxMDMsXCJHcmFwaFJlZkFsbFwiOjEwNCxcIlVwZGF0ZTFfZ3JvdXAxXCI6MTA1LFwiVXBkYXRlMV9vcHRpb24zXCI6MTA2LFwiR3JhcGhPckRlZmF1bHRcIjoxMDcsXCJUT1wiOjEwOCxcIkNSRUFURVwiOjEwOSxcIlVwZGF0ZTFfb3B0aW9uNFwiOjExMCxcIkdSQVBIXCI6MTExLFwiSU5TRVJUREFUQVwiOjExMixcIlF1YWRQYXR0ZXJuXCI6MTEzLFwiREVMRVRFREFUQVwiOjExNCxcIkRFTEVURVdIRVJFXCI6MTE1LFwiVXBkYXRlMV9vcHRpb241XCI6MTE2LFwiSW5zZXJ0Q2xhdXNlXCI6MTE3LFwiVXBkYXRlMV9vcHRpb242XCI6MTE4LFwiVXBkYXRlMV9yZXBldGl0aW9uMFwiOjExOSxcIlVwZGF0ZTFfb3B0aW9uN1wiOjEyMCxcIkRlbGV0ZUNsYXVzZVwiOjEyMSxcIlVwZGF0ZTFfb3B0aW9uOFwiOjEyMixcIlVwZGF0ZTFfcmVwZXRpdGlvbjFcIjoxMjMsXCJERUxFVEVcIjoxMjQsXCJJTlNFUlRcIjoxMjUsXCJVc2luZ0NsYXVzZVwiOjEyNixcIlVTSU5HXCI6MTI3LFwiVXNpbmdDbGF1c2Vfb3B0aW9uMFwiOjEyOCxcIldpdGhDbGF1c2VcIjoxMjksXCJXSVRIXCI6MTMwLFwiSW50b0dyYXBoQ2xhdXNlXCI6MTMxLFwiSU5UT1wiOjEzMixcIkRFRkFVTFRcIjoxMzMsXCJHcmFwaE9yRGVmYXVsdF9vcHRpb24wXCI6MTM0LFwiR3JhcGhSZWZBbGxfZ3JvdXAwXCI6MTM1LFwiUXVhZFBhdHRlcm5fb3B0aW9uMFwiOjEzNixcIlF1YWRQYXR0ZXJuX3JlcGV0aXRpb24wXCI6MTM3LFwiUXVhZHNOb3RUcmlwbGVzXCI6MTM4LFwiUXVhZHNOb3RUcmlwbGVzX2dyb3VwMFwiOjEzOSxcIlF1YWRzTm90VHJpcGxlc19vcHRpb24wXCI6MTQwLFwiUXVhZHNOb3RUcmlwbGVzX29wdGlvbjFcIjoxNDEsXCJRdWFkc05vdFRyaXBsZXNfb3B0aW9uMlwiOjE0MixcIlRyaXBsZXNUZW1wbGF0ZVwiOjE0MyxcIlRyaXBsZXNUZW1wbGF0ZV9yZXBldGl0aW9uMFwiOjE0NCxcIlRyaXBsZXNTYW1lU3ViamVjdFwiOjE0NSxcIlRyaXBsZXNUZW1wbGF0ZV9vcHRpb24wXCI6MTQ2LFwiR3JvdXBHcmFwaFBhdHRlcm5TdWJcIjoxNDcsXCJHcm91cEdyYXBoUGF0dGVyblN1Yl9vcHRpb24wXCI6MTQ4LFwiR3JvdXBHcmFwaFBhdHRlcm5TdWJfcmVwZXRpdGlvbjBcIjoxNDksXCJHcm91cEdyYXBoUGF0dGVyblN1YlRhaWxcIjoxNTAsXCJHcmFwaFBhdHRlcm5Ob3RUcmlwbGVzXCI6MTUxLFwiR3JvdXBHcmFwaFBhdHRlcm5TdWJUYWlsX29wdGlvbjBcIjoxNTIsXCJHcm91cEdyYXBoUGF0dGVyblN1YlRhaWxfb3B0aW9uMVwiOjE1MyxcIlRyaXBsZXNCbG9ja1wiOjE1NCxcIlRyaXBsZXNCbG9ja19yZXBldGl0aW9uMFwiOjE1NSxcIlRyaXBsZXNTYW1lU3ViamVjdFBhdGhcIjoxNTYsXCJUcmlwbGVzQmxvY2tfb3B0aW9uMFwiOjE1NyxcIkdyYXBoUGF0dGVybk5vdFRyaXBsZXNfcmVwZXRpdGlvbjBcIjoxNTgsXCJPUFRJT05BTFwiOjE1OSxcIk1JTlVTXCI6MTYwLFwiR3JhcGhQYXR0ZXJuTm90VHJpcGxlc19ncm91cDBcIjoxNjEsXCJTRVJWSUNFXCI6MTYyLFwiR3JhcGhQYXR0ZXJuTm90VHJpcGxlc19vcHRpb24wXCI6MTYzLFwiR3JhcGhQYXR0ZXJuTm90VHJpcGxlc19ncm91cDFcIjoxNjQsXCJGSUxURVJcIjoxNjUsXCJCSU5EXCI6MTY2LFwiRnVuY3Rpb25DYWxsX29wdGlvbjBcIjoxNjcsXCJGdW5jdGlvbkNhbGxfcmVwZXRpdGlvbjBcIjoxNjgsXCJFeHByZXNzaW9uTGlzdFwiOjE2OSxcIkV4cHJlc3Npb25MaXN0X3JlcGV0aXRpb24wXCI6MTcwLFwiQ29uc3RydWN0VGVtcGxhdGVfb3B0aW9uMFwiOjE3MSxcIkNvbnN0cnVjdFRyaXBsZXNcIjoxNzIsXCJDb25zdHJ1Y3RUcmlwbGVzX3JlcGV0aXRpb24wXCI6MTczLFwiQ29uc3RydWN0VHJpcGxlc19vcHRpb24wXCI6MTc0LFwiVmFyT3JUZXJtXCI6MTc1LFwiUHJvcGVydHlMaXN0Tm90RW1wdHlcIjoxNzYsXCJUcmlwbGVzTm9kZVwiOjE3NyxcIlByb3BlcnR5TGlzdFwiOjE3OCxcIlByb3BlcnR5TGlzdF9vcHRpb24wXCI6MTc5LFwiVmVyYk9iamVjdExpc3RcIjoxODAsXCJQcm9wZXJ0eUxpc3ROb3RFbXB0eV9yZXBldGl0aW9uMFwiOjE4MSxcIlNlbWlPcHRpb25hbFZlcmJPYmplY3RMaXN0XCI6MTgyLFwiO1wiOjE4MyxcIlNlbWlPcHRpb25hbFZlcmJPYmplY3RMaXN0X29wdGlvbjBcIjoxODQsXCJWZXJiXCI6MTg1LFwiT2JqZWN0TGlzdFwiOjE4NixcImFcIjoxODcsXCJPYmplY3RMaXN0X3JlcGV0aXRpb24wXCI6MTg4LFwiR3JhcGhOb2RlXCI6MTg5LFwiUHJvcGVydHlMaXN0UGF0aE5vdEVtcHR5XCI6MTkwLFwiVHJpcGxlc05vZGVQYXRoXCI6MTkxLFwiVHJpcGxlc1NhbWVTdWJqZWN0UGF0aF9vcHRpb24wXCI6MTkyLFwiUHJvcGVydHlMaXN0UGF0aE5vdEVtcHR5X2dyb3VwMFwiOjE5MyxcIlByb3BlcnR5TGlzdFBhdGhOb3RFbXB0eV9yZXBldGl0aW9uMFwiOjE5NCxcIkdyYXBoTm9kZVBhdGhcIjoxOTUsXCJQcm9wZXJ0eUxpc3RQYXRoTm90RW1wdHlfcmVwZXRpdGlvbjFcIjoxOTYsXCJQcm9wZXJ0eUxpc3RQYXRoTm90RW1wdHlUYWlsXCI6MTk3LFwiUHJvcGVydHlMaXN0UGF0aE5vdEVtcHR5VGFpbF9ncm91cDBcIjoxOTgsXCJQYXRoXCI6MTk5LFwiUGF0aF9yZXBldGl0aW9uMFwiOjIwMCxcIlBhdGhTZXF1ZW5jZVwiOjIwMSxcIlBhdGhTZXF1ZW5jZV9yZXBldGl0aW9uMFwiOjIwMixcIlBhdGhFbHRPckludmVyc2VcIjoyMDMsXCJQYXRoRWx0XCI6MjA0LFwiUGF0aFByaW1hcnlcIjoyMDUsXCJQYXRoRWx0X29wdGlvbjBcIjoyMDYsXCJQYXRoRWx0T3JJbnZlcnNlX29wdGlvbjBcIjoyMDcsXCIhXCI6MjA4LFwiUGF0aE5lZ2F0ZWRQcm9wZXJ0eVNldFwiOjIwOSxcIlBhdGhPbmVJblByb3BlcnR5U2V0XCI6MjEwLFwiUGF0aE5lZ2F0ZWRQcm9wZXJ0eVNldF9yZXBldGl0aW9uMFwiOjIxMSxcIlBhdGhOZWdhdGVkUHJvcGVydHlTZXRfb3B0aW9uMFwiOjIxMixcIl5cIjoyMTMsXCJUcmlwbGVzTm9kZV9yZXBldGl0aW9uX3BsdXMwXCI6MjE0LFwiW1wiOjIxNSxcIl1cIjoyMTYsXCJUcmlwbGVzTm9kZVBhdGhfcmVwZXRpdGlvbl9wbHVzMFwiOjIxNyxcIkJMQU5LX05PREVfTEFCRUxcIjoyMTgsXCJBTk9OXCI6MjE5LFwiQ29uZGl0aW9uYWxBbmRFeHByZXNzaW9uXCI6MjIwLFwiRXhwcmVzc2lvbl9yZXBldGl0aW9uMFwiOjIyMSxcIkV4cHJlc3Npb25UYWlsXCI6MjIyLFwifHxcIjoyMjMsXCJSZWxhdGlvbmFsRXhwcmVzc2lvblwiOjIyNCxcIkNvbmRpdGlvbmFsQW5kRXhwcmVzc2lvbl9yZXBldGl0aW9uMFwiOjIyNSxcIkNvbmRpdGlvbmFsQW5kRXhwcmVzc2lvblRhaWxcIjoyMjYsXCImJlwiOjIyNyxcIkFkZGl0aXZlRXhwcmVzc2lvblwiOjIyOCxcIlJlbGF0aW9uYWxFeHByZXNzaW9uX2dyb3VwMFwiOjIyOSxcIlJlbGF0aW9uYWxFeHByZXNzaW9uX29wdGlvbjBcIjoyMzAsXCJJTlwiOjIzMSxcIk11bHRpcGxpY2F0aXZlRXhwcmVzc2lvblwiOjIzMixcIkFkZGl0aXZlRXhwcmVzc2lvbl9yZXBldGl0aW9uMFwiOjIzMyxcIkFkZGl0aXZlRXhwcmVzc2lvblRhaWxcIjoyMzQsXCJBZGRpdGl2ZUV4cHJlc3Npb25UYWlsX2dyb3VwMFwiOjIzNSxcIk51bWVyaWNMaXRlcmFsUG9zaXRpdmVcIjoyMzYsXCJBZGRpdGl2ZUV4cHJlc3Npb25UYWlsX3JlcGV0aXRpb24wXCI6MjM3LFwiTnVtZXJpY0xpdGVyYWxOZWdhdGl2ZVwiOjIzOCxcIkFkZGl0aXZlRXhwcmVzc2lvblRhaWxfcmVwZXRpdGlvbjFcIjoyMzksXCJVbmFyeUV4cHJlc3Npb25cIjoyNDAsXCJNdWx0aXBsaWNhdGl2ZUV4cHJlc3Npb25fcmVwZXRpdGlvbjBcIjoyNDEsXCJNdWx0aXBsaWNhdGl2ZUV4cHJlc3Npb25UYWlsXCI6MjQyLFwiTXVsdGlwbGljYXRpdmVFeHByZXNzaW9uVGFpbF9ncm91cDBcIjoyNDMsXCJVbmFyeUV4cHJlc3Npb25fb3B0aW9uMFwiOjI0NCxcIlByaW1hcnlFeHByZXNzaW9uXCI6MjQ1LFwiLVwiOjI0NixcIkFnZ3JlZ2F0ZVwiOjI0NyxcIkZVTkNfQVJJVFkwXCI6MjQ4LFwiRlVOQ19BUklUWTFcIjoyNDksXCJGVU5DX0FSSVRZMlwiOjI1MCxcIixcIjoyNTEsXCJJRlwiOjI1MixcIkJ1aWx0SW5DYWxsX2dyb3VwMFwiOjI1MyxcIkJPVU5EXCI6MjU0LFwiQk5PREVcIjoyNTUsXCJCdWlsdEluQ2FsbF9vcHRpb24wXCI6MjU2LFwiRVhJU1RTXCI6MjU3LFwiQ09VTlRcIjoyNTgsXCJBZ2dyZWdhdGVfb3B0aW9uMFwiOjI1OSxcIkFnZ3JlZ2F0ZV9ncm91cDBcIjoyNjAsXCJGVU5DX0FHR1JFR0FURVwiOjI2MSxcIkFnZ3JlZ2F0ZV9vcHRpb24xXCI6MjYyLFwiR1JPVVBfQ09OQ0FUXCI6MjYzLFwiQWdncmVnYXRlX29wdGlvbjJcIjoyNjQsXCJBZ2dyZWdhdGVfb3B0aW9uM1wiOjI2NSxcIkdyb3VwQ29uY2F0U2VwYXJhdG9yXCI6MjY2LFwiU0VQQVJBVE9SXCI6MjY3LFwiPVwiOjI2OCxcIlN0cmluZ1wiOjI2OSxcIkxBTkdUQUdcIjoyNzAsXCJeXlwiOjI3MSxcIkRFQ0lNQUxcIjoyNzIsXCJET1VCTEVcIjoyNzMsXCJ0cnVlXCI6Mjc0LFwiZmFsc2VcIjoyNzUsXCJTVFJJTkdfTElURVJBTDFcIjoyNzYsXCJTVFJJTkdfTElURVJBTDJcIjoyNzcsXCJTVFJJTkdfTElURVJBTF9MT05HMVwiOjI3OCxcIlNUUklOR19MSVRFUkFMX0xPTkcyXCI6Mjc5LFwiSU5URUdFUl9QT1NJVElWRVwiOjI4MCxcIkRFQ0lNQUxfUE9TSVRJVkVcIjoyODEsXCJET1VCTEVfUE9TSVRJVkVcIjoyODIsXCJJTlRFR0VSX05FR0FUSVZFXCI6MjgzLFwiREVDSU1BTF9ORUdBVElWRVwiOjI4NCxcIkRPVUJMRV9ORUdBVElWRVwiOjI4NSxcIlBOQU1FX0xOXCI6Mjg2LFwiUXVlcnlPclVwZGF0ZV9ncm91cDBfb3B0aW9uMFwiOjI4NyxcIlByb2xvZ3VlX3JlcGV0aXRpb24wX2dyb3VwMFwiOjI4OCxcIlNlbGVjdENsYXVzZV9vcHRpb24wX2dyb3VwMFwiOjI4OSxcIkRJU1RJTkNUXCI6MjkwLFwiUkVEVUNFRFwiOjI5MSxcIlNlbGVjdENsYXVzZV9ncm91cDBfcmVwZXRpdGlvbl9wbHVzMFwiOjI5MixcIipcIjoyOTMsXCJEZXNjcmliZVF1ZXJ5X2dyb3VwMF9yZXBldGl0aW9uX3BsdXMwX2dyb3VwMFwiOjI5NCxcIkRlc2NyaWJlUXVlcnlfZ3JvdXAwX3JlcGV0aXRpb25fcGx1czBcIjoyOTUsXCJOQU1FRFwiOjI5NixcIlNJTEVOVFwiOjI5NyxcIkNMRUFSXCI6Mjk4LFwiRFJPUFwiOjI5OSxcIkFERFwiOjMwMCxcIk1PVkVcIjozMDEsXCJDT1BZXCI6MzAyLFwiQUxMXCI6MzAzLFwiLlwiOjMwNCxcIlVOSU9OXCI6MzA1LFwifFwiOjMwNixcIi9cIjozMDcsXCJQYXRoRWx0X29wdGlvbjBfZ3JvdXAwXCI6MzA4LFwiP1wiOjMwOSxcIitcIjozMTAsXCIhPVwiOjMxMSxcIjxcIjozMTIsXCI+XCI6MzEzLFwiPD1cIjozMTQsXCI+PVwiOjMxNSxcIk5PVFwiOjMxNixcIkNPTkNBVFwiOjMxNyxcIkNPQUxFU0NFXCI6MzE4LFwiU1VCU1RSXCI6MzE5LFwiUkVHRVhcIjozMjAsXCJSRVBMQUNFXCI6MzIxLFwiJGFjY2VwdFwiOjAsXCIkZW5kXCI6MX0sXG50ZXJtaW5hbHNfOiB7MjpcImVycm9yXCIsNjpcIkVPRlwiLDEyOlwiQkFTRVwiLDEzOlwiSVJJUkVGXCIsMTU6XCJQUkVGSVhcIiwxNjpcIlBOQU1FX05TXCIsMjQ6XCJTRUxFQ1RcIiwyODpcIlZBUlwiLDI5OlwiKFwiLDMxOlwiQVNcIiwzMjpcIilcIiwzNDpcIkNPTlNUUlVDVFwiLDM4OlwiV0hFUkVcIiwzOTpcIntcIiw0MTpcIn1cIiw0MzpcIkRFU0NSSUJFXCIsNDg6XCJBU0tcIiw1MTpcIkZST01cIiw2MTpcIkdST1VQXCIsNjI6XCJCWVwiLDY4OlwiSEFWSU5HXCIsNzE6XCJPUkRFUlwiLDc0OlwiQVNDXCIsNzY6XCJERVNDXCIsNzk6XCJMSU1JVFwiLDgwOlwiSU5URUdFUlwiLDgxOlwiT0ZGU0VUXCIsODM6XCJWQUxVRVNcIiw4NjpcIk5JTFwiLDkyOlwiVU5ERUZcIiw5OTpcIkxPQURcIiwxMDg6XCJUT1wiLDEwOTpcIkNSRUFURVwiLDExMTpcIkdSQVBIXCIsMTEyOlwiSU5TRVJUREFUQVwiLDExNDpcIkRFTEVURURBVEFcIiwxMTU6XCJERUxFVEVXSEVSRVwiLDEyNDpcIkRFTEVURVwiLDEyNTpcIklOU0VSVFwiLDEyNzpcIlVTSU5HXCIsMTMwOlwiV0lUSFwiLDEzMjpcIklOVE9cIiwxMzM6XCJERUZBVUxUXCIsMTU5OlwiT1BUSU9OQUxcIiwxNjA6XCJNSU5VU1wiLDE2MjpcIlNFUlZJQ0VcIiwxNjU6XCJGSUxURVJcIiwxNjY6XCJCSU5EXCIsMTgzOlwiO1wiLDE4NzpcImFcIiwyMDg6XCIhXCIsMjEzOlwiXlwiLDIxNTpcIltcIiwyMTY6XCJdXCIsMjE4OlwiQkxBTktfTk9ERV9MQUJFTFwiLDIxOTpcIkFOT05cIiwyMjM6XCJ8fFwiLDIyNzpcIiYmXCIsMjMxOlwiSU5cIiwyNDY6XCItXCIsMjQ4OlwiRlVOQ19BUklUWTBcIiwyNDk6XCJGVU5DX0FSSVRZMVwiLDI1MDpcIkZVTkNfQVJJVFkyXCIsMjUxOlwiLFwiLDI1MjpcIklGXCIsMjU0OlwiQk9VTkRcIiwyNTU6XCJCTk9ERVwiLDI1NzpcIkVYSVNUU1wiLDI1ODpcIkNPVU5UXCIsMjYxOlwiRlVOQ19BR0dSRUdBVEVcIiwyNjM6XCJHUk9VUF9DT05DQVRcIiwyNjc6XCJTRVBBUkFUT1JcIiwyNjg6XCI9XCIsMjcwOlwiTEFOR1RBR1wiLDI3MTpcIl5eXCIsMjcyOlwiREVDSU1BTFwiLDI3MzpcIkRPVUJMRVwiLDI3NDpcInRydWVcIiwyNzU6XCJmYWxzZVwiLDI3NjpcIlNUUklOR19MSVRFUkFMMVwiLDI3NzpcIlNUUklOR19MSVRFUkFMMlwiLDI3ODpcIlNUUklOR19MSVRFUkFMX0xPTkcxXCIsMjc5OlwiU1RSSU5HX0xJVEVSQUxfTE9ORzJcIiwyODA6XCJJTlRFR0VSX1BPU0lUSVZFXCIsMjgxOlwiREVDSU1BTF9QT1NJVElWRVwiLDI4MjpcIkRPVUJMRV9QT1NJVElWRVwiLDI4MzpcIklOVEVHRVJfTkVHQVRJVkVcIiwyODQ6XCJERUNJTUFMX05FR0FUSVZFXCIsMjg1OlwiRE9VQkxFX05FR0FUSVZFXCIsMjg2OlwiUE5BTUVfTE5cIiwyOTA6XCJESVNUSU5DVFwiLDI5MTpcIlJFRFVDRURcIiwyOTM6XCIqXCIsMjk2OlwiTkFNRURcIiwyOTc6XCJTSUxFTlRcIiwyOTg6XCJDTEVBUlwiLDI5OTpcIkRST1BcIiwzMDA6XCJBRERcIiwzMDE6XCJNT1ZFXCIsMzAyOlwiQ09QWVwiLDMwMzpcIkFMTFwiLDMwNDpcIi5cIiwzMDU6XCJVTklPTlwiLDMwNjpcInxcIiwzMDc6XCIvXCIsMzA5OlwiP1wiLDMxMDpcIitcIiwzMTE6XCIhPVwiLDMxMjpcIjxcIiwzMTM6XCI+XCIsMzE0OlwiPD1cIiwzMTU6XCI+PVwiLDMxNjpcIk5PVFwiLDMxNzpcIkNPTkNBVFwiLDMxODpcIkNPQUxFU0NFXCIsMzE5OlwiU1VCU1RSXCIsMzIwOlwiUkVHRVhcIiwzMjE6XCJSRVBMQUNFXCJ9LFxucHJvZHVjdGlvbnNfOiBbMCxbMywzXSxbNCwxXSxbOCwyXSxbMTEsMl0sWzE0LDNdLFsxNyw0XSxbMjIsNF0sWzE4LDNdLFsyNywxXSxbMjcsNV0sWzMzLDVdLFszMyw3XSxbNDIsNV0sWzQ3LDRdLFs1MCwzXSxbMjAsMl0sWzIxLDRdLFs2MCwzXSxbNjQsMV0sWzY0LDFdLFs2NCwzXSxbNjQsNV0sWzY0LDFdLFs2NywyXSxbNzAsM10sWzczLDJdLFs3MywyXSxbNzMsMV0sWzczLDFdLFs3OCwyXSxbNzgsMl0sWzc4LDRdLFs3OCw0XSxbODIsMl0sWzg0LDRdLFs4NCw0XSxbODQsNl0sWzkwLDFdLFs5MCwxXSxbOTAsMV0sWzkzLDNdLFs5NSwzXSxbOTcsNF0sWzk3LDNdLFs5Nyw1XSxbOTcsNF0sWzk3LDJdLFs5NywyXSxbOTcsMl0sWzk3LDZdLFs5Nyw2XSxbMTIxLDJdLFsxMTcsMl0sWzEyNiwzXSxbMTI5LDJdLFsxMzEsM10sWzEwNywxXSxbMTA3LDJdLFsxMDQsMl0sWzEwNCwxXSxbMTEzLDRdLFsxMzgsN10sWzE0MywzXSxbNTUsM10sWzU1LDNdLFsxNDcsMl0sWzE1MCwzXSxbMTU0LDNdLFsxNTEsMl0sWzE1MSwyXSxbMTUxLDJdLFsxNTEsM10sWzE1MSw0XSxbMTUxLDJdLFsxNTEsNl0sWzE1MSwxXSxbNzcsMV0sWzc3LDFdLFs3NywxXSxbNjYsMl0sWzY2LDZdLFsxNjksMV0sWzE2OSw0XSxbMzUsM10sWzE3MiwzXSxbMTQ1LDJdLFsxNDUsMl0sWzE3OCwxXSxbMTc2LDJdLFsxODIsMl0sWzE4MCwyXSxbMTg1LDFdLFsxODUsMV0sWzE4NSwxXSxbMTg2LDJdLFsxNTYsMl0sWzE1NiwyXSxbMTkwLDRdLFsxOTcsMV0sWzE5NywzXSxbMTk5LDJdLFsyMDEsMl0sWzIwNCwyXSxbMjAzLDJdLFsyMDUsMV0sWzIwNSwxXSxbMjA1LDJdLFsyMDUsM10sWzIwOSwxXSxbMjA5LDFdLFsyMDksNF0sWzIxMCwxXSxbMjEwLDFdLFsyMTAsMl0sWzIxMCwyXSxbMTc3LDNdLFsxNzcsM10sWzE5MSwzXSxbMTkxLDNdLFsxODksMV0sWzE4OSwxXSxbMTk1LDFdLFsxOTUsMV0sWzE3NSwxXSxbMTc1LDFdLFsxNzUsMV0sWzE3NSwxXSxbMTc1LDFdLFsxNzUsMV0sWzMwLDJdLFsyMjIsMl0sWzIyMCwyXSxbMjI2LDJdLFsyMjQsMV0sWzIyNCwzXSxbMjI0LDRdLFsyMjgsMl0sWzIzNCwyXSxbMjM0LDJdLFsyMzQsMl0sWzIzMiwyXSxbMjQyLDJdLFsyNDAsMl0sWzI0MCwyXSxbMjQwLDJdLFsyNDUsMV0sWzI0NSwxXSxbMjQ1LDFdLFsyNDUsMV0sWzI0NSwxXSxbMjQ1LDFdLFs3NSwzXSxbNjUsMV0sWzY1LDJdLFs2NSw0XSxbNjUsNl0sWzY1LDhdLFs2NSwyXSxbNjUsNF0sWzY1LDJdLFs2NSw0XSxbNjUsM10sWzI0Nyw1XSxbMjQ3LDVdLFsyNDcsNl0sWzI2Niw0XSxbOTEsMV0sWzkxLDJdLFs5MSwzXSxbOTEsMV0sWzkxLDFdLFs5MSwxXSxbOTEsMV0sWzkxLDFdLFs5MSwxXSxbOTEsMV0sWzI2OSwxXSxbMjY5LDFdLFsyNjksMV0sWzI2OSwxXSxbMjM2LDFdLFsyMzYsMV0sWzIzNiwxXSxbMjM4LDFdLFsyMzgsMV0sWzIzOCwxXSxbNTMsMV0sWzUzLDFdLFs1MywxXSxbMjg3LDBdLFsyODcsMV0sWzUsMV0sWzUsMV0sWzI4OCwxXSxbMjg4LDFdLFs3LDBdLFs3LDJdLFs5LDFdLFs5LDFdLFs5LDFdLFs5LDFdLFsxMCwwXSxbMTAsMV0sWzE5LDBdLFsxOSwyXSxbMjMsMF0sWzIzLDFdLFsyODksMV0sWzI4OSwxXSxbMjUsMF0sWzI1LDFdLFsyOTIsMV0sWzI5MiwyXSxbMjYsMV0sWzI2LDFdLFszNiwwXSxbMzYsMl0sWzM3LDBdLFszNywyXSxbNDAsMF0sWzQwLDFdLFsyOTQsMV0sWzI5NCwxXSxbMjk1LDFdLFsyOTUsMl0sWzQ0LDFdLFs0NCwxXSxbNDUsMF0sWzQ1LDJdLFs0NiwwXSxbNDYsMV0sWzQ5LDBdLFs0OSwyXSxbNTIsMF0sWzUyLDFdLFs1NCwwXSxbNTQsMV0sWzU2LDBdLFs1NiwxXSxbNTcsMF0sWzU3LDFdLFs1OCwwXSxbNTgsMV0sWzU5LDBdLFs1OSwxXSxbNjMsMV0sWzYzLDJdLFs2OSwxXSxbNjksMl0sWzcyLDFdLFs3MiwyXSxbODUsMF0sWzg1LDJdLFs4NywwXSxbODcsMl0sWzg4LDFdLFs4OCwyXSxbODksMF0sWzg5LDJdLFs5NCwxXSxbOTQsMl0sWzk2LDBdLFs5Niw0XSxbOTgsMF0sWzk4LDJdLFsxMDAsMF0sWzEwMCwxXSxbMTAxLDBdLFsxMDEsMV0sWzEwMiwxXSxbMTAyLDFdLFsxMDMsMF0sWzEwMywxXSxbMTA1LDFdLFsxMDUsMV0sWzEwNSwxXSxbMTA2LDBdLFsxMDYsMV0sWzExMCwwXSxbMTEwLDFdLFsxMTYsMF0sWzExNiwxXSxbMTE4LDBdLFsxMTgsMV0sWzExOSwwXSxbMTE5LDJdLFsxMjAsMF0sWzEyMCwxXSxbMTIyLDBdLFsxMjIsMV0sWzEyMywwXSxbMTIzLDJdLFsxMjgsMF0sWzEyOCwxXSxbMTM0LDBdLFsxMzQsMV0sWzEzNSwxXSxbMTM1LDFdLFsxMzUsMV0sWzEzNiwwXSxbMTM2LDFdLFsxMzcsMF0sWzEzNywyXSxbMTM5LDFdLFsxMzksMV0sWzE0MCwwXSxbMTQwLDFdLFsxNDEsMF0sWzE0MSwxXSxbMTQyLDBdLFsxNDIsMV0sWzE0NCwwXSxbMTQ0LDNdLFsxNDYsMF0sWzE0NiwxXSxbMTQ4LDBdLFsxNDgsMV0sWzE0OSwwXSxbMTQ5LDJdLFsxNTIsMF0sWzE1MiwxXSxbMTUzLDBdLFsxNTMsMV0sWzE1NSwwXSxbMTU1LDNdLFsxNTcsMF0sWzE1NywxXSxbMTU4LDBdLFsxNTgsM10sWzE2MSwxXSxbMTYxLDFdLFsxNjMsMF0sWzE2MywxXSxbMTY0LDFdLFsxNjQsMV0sWzE2NywwXSxbMTY3LDFdLFsxNjgsMF0sWzE2OCwzXSxbMTcwLDBdLFsxNzAsM10sWzE3MSwwXSxbMTcxLDFdLFsxNzMsMF0sWzE3MywzXSxbMTc0LDBdLFsxNzQsMV0sWzE3OSwwXSxbMTc5LDFdLFsxODEsMF0sWzE4MSwyXSxbMTg0LDBdLFsxODQsMV0sWzE4OCwwXSxbMTg4LDNdLFsxOTIsMF0sWzE5MiwxXSxbMTkzLDFdLFsxOTMsMV0sWzE5NCwwXSxbMTk0LDNdLFsxOTYsMF0sWzE5NiwyXSxbMTk4LDFdLFsxOTgsMV0sWzIwMCwwXSxbMjAwLDNdLFsyMDIsMF0sWzIwMiwzXSxbMzA4LDFdLFszMDgsMV0sWzMwOCwxXSxbMjA2LDBdLFsyMDYsMV0sWzIwNywwXSxbMjA3LDFdLFsyMTEsMF0sWzIxMSwzXSxbMjEyLDBdLFsyMTIsMV0sWzIxNCwxXSxbMjE0LDJdLFsyMTcsMV0sWzIxNywyXSxbMjIxLDBdLFsyMjEsMl0sWzIyNSwwXSxbMjI1LDJdLFsyMjksMV0sWzIyOSwxXSxbMjI5LDFdLFsyMjksMV0sWzIyOSwxXSxbMjI5LDFdLFsyMzAsMF0sWzIzMCwxXSxbMjMzLDBdLFsyMzMsMl0sWzIzNSwxXSxbMjM1LDFdLFsyMzcsMF0sWzIzNywyXSxbMjM5LDBdLFsyMzksMl0sWzI0MSwwXSxbMjQxLDJdLFsyNDMsMV0sWzI0MywxXSxbMjQ0LDBdLFsyNDQsMV0sWzI1MywxXSxbMjUzLDFdLFsyNTMsMV0sWzI1MywxXSxbMjUzLDFdLFsyNTYsMF0sWzI1NiwxXSxbMjU5LDBdLFsyNTksMV0sWzI2MCwxXSxbMjYwLDFdLFsyNjIsMF0sWzI2MiwxXSxbMjY0LDBdLFsyNjQsMV0sWzI2NSwwXSxbMjY1LDFdXSxcbnBlcmZvcm1BY3Rpb246IGZ1bmN0aW9uIGFub255bW91cyh5eXRleHQsIHl5bGVuZywgeXlsaW5lbm8sIHl5LCB5eXN0YXRlIC8qIGFjdGlvblsxXSAqLywgJCQgLyogdnN0YWNrICovLCBfJCAvKiBsc3RhY2sgKi8pIHtcbi8qIHRoaXMgPT0geXl2YWwgKi9cblxudmFyICQwID0gJCQubGVuZ3RoIC0gMTtcbnN3aXRjaCAoeXlzdGF0ZSkge1xuY2FzZSAxOlxuXG4gICAgICAkJFskMC0xXSA9ICQkWyQwLTFdIHx8IHt9O1xuICAgICAgaWYgKFBhcnNlci5iYXNlKVxuICAgICAgICAkJFskMC0xXS5iYXNlID0gUGFyc2VyLmJhc2U7XG4gICAgICBQYXJzZXIuYmFzZSA9IGJhc2UgPSBiYXNlUGF0aCA9IGJhc2VSb290ID0gJyc7XG4gICAgICAkJFskMC0xXS5wcmVmaXhlcyA9IFBhcnNlci5wcmVmaXhlcztcbiAgICAgIFBhcnNlci5wcmVmaXhlcyA9IG51bGw7XG4gICAgICByZXR1cm4gJCRbJDAtMV07XG4gICAgXG5icmVhaztcbmNhc2UgMzpcbnRoaXMuJCA9IGV4dGVuZCgkJFskMC0xXSwgJCRbJDBdLCB7IHR5cGU6ICdxdWVyeScgfSk7XG5icmVhaztcbmNhc2UgNDpcblxuICAgICAgUGFyc2VyLmJhc2UgPSByZXNvbHZlSVJJKCQkWyQwXSlcbiAgICAgIGJhc2UgPSBiYXNlUGF0aCA9IGJhc2VSb290ID0gJyc7XG4gICAgXG5icmVhaztcbmNhc2UgNTpcblxuICAgICAgaWYgKCFQYXJzZXIucHJlZml4ZXMpIFBhcnNlci5wcmVmaXhlcyA9IHt9O1xuICAgICAgJCRbJDAtMV0gPSAkJFskMC0xXS5zdWJzdHIoMCwgJCRbJDAtMV0ubGVuZ3RoIC0gMSk7XG4gICAgICAkJFskMF0gPSByZXNvbHZlSVJJKCQkWyQwXSk7XG4gICAgICBQYXJzZXIucHJlZml4ZXNbJCRbJDAtMV1dID0gJCRbJDBdO1xuICAgIFxuYnJlYWs7XG5jYXNlIDY6XG50aGlzLiQgPSBleHRlbmQoJCRbJDAtM10sIGdyb3VwRGF0YXNldHMoJCRbJDAtMl0pLCAkJFskMC0xXSwgJCRbJDBdKTtcbmJyZWFrO1xuY2FzZSA3OlxudGhpcy4kID0gZXh0ZW5kKCQkWyQwLTNdLCAkJFskMC0yXSwgJCRbJDAtMV0sICQkWyQwXSwgeyB0eXBlOiAncXVlcnknIH0pO1xuYnJlYWs7XG5jYXNlIDg6XG50aGlzLiQgPSBleHRlbmQoeyBxdWVyeVR5cGU6ICdTRUxFQ1QnLCB2YXJpYWJsZXM6ICQkWyQwXSA9PT0gJyonID8gWycqJ10gOiAkJFskMF0gfSwgJCRbJDAtMV0gJiYgKCQkWyQwLTJdID0gbG93ZXJjYXNlKCQkWyQwLTFdKSwgJCRbJDAtMV0gPSB7fSwgJCRbJDAtMV1bJCRbJDAtMl1dID0gdHJ1ZSwgJCRbJDAtMV0pKTtcbmJyZWFrO1xuY2FzZSA5OiBjYXNlIDkyOiBjYXNlIDEyNDogY2FzZSAxNTE6XG50aGlzLiQgPSB0b1ZhcigkJFskMF0pO1xuYnJlYWs7XG5jYXNlIDEwOiBjYXNlIDIyOlxudGhpcy4kID0gZXhwcmVzc2lvbigkJFskMC0zXSwgeyB2YXJpYWJsZTogdG9WYXIoJCRbJDAtMV0pIH0pO1xuYnJlYWs7XG5jYXNlIDExOlxudGhpcy4kID0gZXh0ZW5kKHsgcXVlcnlUeXBlOiAnQ09OU1RSVUNUJywgdGVtcGxhdGU6ICQkWyQwLTNdIH0sIGdyb3VwRGF0YXNldHMoJCRbJDAtMl0pLCAkJFskMC0xXSwgJCRbJDBdKTtcbmJyZWFrO1xuY2FzZSAxMjpcbnRoaXMuJCA9IGV4dGVuZCh7IHF1ZXJ5VHlwZTogJ0NPTlNUUlVDVCcsIHRlbXBsYXRlOiAkJFskMC0yXSA9ICgkJFskMC0yXSA/ICQkWyQwLTJdLnRyaXBsZXMgOiBbXSkgfSwgZ3JvdXBEYXRhc2V0cygkJFskMC01XSksIHsgd2hlcmU6IFsgeyB0eXBlOiAnYmdwJywgdHJpcGxlczogYXBwZW5kQWxsVG8oW10sICQkWyQwLTJdKSB9IF0gfSwgJCRbJDBdKTtcbmJyZWFrO1xuY2FzZSAxMzpcbnRoaXMuJCA9IGV4dGVuZCh7IHF1ZXJ5VHlwZTogJ0RFU0NSSUJFJywgdmFyaWFibGVzOiAkJFskMC0zXSA9PT0gJyonID8gWycqJ10gOiAkJFskMC0zXS5tYXAodG9WYXIpIH0sIGdyb3VwRGF0YXNldHMoJCRbJDAtMl0pLCAkJFskMC0xXSwgJCRbJDBdKTtcbmJyZWFrO1xuY2FzZSAxNDpcbnRoaXMuJCA9IGV4dGVuZCh7IHF1ZXJ5VHlwZTogJ0FTSycgfSwgZ3JvdXBEYXRhc2V0cygkJFskMC0yXSksICQkWyQwLTFdLCAkJFskMF0pO1xuYnJlYWs7XG5jYXNlIDE1OiBjYXNlIDU0OlxudGhpcy4kID0geyBpcmk6ICQkWyQwXSwgbmFtZWQ6ICEhJCRbJDAtMV0gfTtcbmJyZWFrO1xuY2FzZSAxNjpcbnRoaXMuJCA9IHsgd2hlcmU6ICQkWyQwXS5wYXR0ZXJucyB9O1xuYnJlYWs7XG5jYXNlIDE3OlxudGhpcy4kID0gZXh0ZW5kKCQkWyQwLTNdLCAkJFskMC0yXSwgJCRbJDAtMV0sICQkWyQwXSk7XG5icmVhaztcbmNhc2UgMTg6XG50aGlzLiQgPSB7IGdyb3VwOiAkJFskMF0gfTtcbmJyZWFrO1xuY2FzZSAxOTogY2FzZSAyMDogY2FzZSAyNjogY2FzZSAyODpcbnRoaXMuJCA9IGV4cHJlc3Npb24oJCRbJDBdKTtcbmJyZWFrO1xuY2FzZSAyMTpcbnRoaXMuJCA9IGV4cHJlc3Npb24oJCRbJDAtMV0pO1xuYnJlYWs7XG5jYXNlIDIzOiBjYXNlIDI5OlxudGhpcy4kID0gZXhwcmVzc2lvbih0b1ZhcigkJFskMF0pKTtcbmJyZWFrO1xuY2FzZSAyNDpcbnRoaXMuJCA9IHsgaGF2aW5nOiAkJFskMF0gfTtcbmJyZWFrO1xuY2FzZSAyNTpcbnRoaXMuJCA9IHsgb3JkZXI6ICQkWyQwXSB9O1xuYnJlYWs7XG5jYXNlIDI3OlxudGhpcy4kID0gZXhwcmVzc2lvbigkJFskMF0sIHsgZGVzY2VuZGluZzogdHJ1ZSB9KTtcbmJyZWFrO1xuY2FzZSAzMDpcbnRoaXMuJCA9IHsgbGltaXQ6ICB0b0ludCgkJFskMF0pIH07XG5icmVhaztcbmNhc2UgMzE6XG50aGlzLiQgPSB7IG9mZnNldDogdG9JbnQoJCRbJDBdKSB9O1xuYnJlYWs7XG5jYXNlIDMyOlxudGhpcy4kID0geyBsaW1pdDogdG9JbnQoJCRbJDAtMl0pLCBvZmZzZXQ6IHRvSW50KCQkWyQwXSkgfTtcbmJyZWFrO1xuY2FzZSAzMzpcbnRoaXMuJCA9IHsgbGltaXQ6IHRvSW50KCQkWyQwXSksIG9mZnNldDogdG9JbnQoJCRbJDAtMl0pIH07XG5icmVhaztcbmNhc2UgMzQ6XG50aGlzLiQgPSB7IHR5cGU6ICd2YWx1ZXMnLCB2YWx1ZXM6ICQkWyQwXSB9O1xuYnJlYWs7XG5jYXNlIDM1OlxuXG4gICAgICAkJFskMC0zXSA9IHRvVmFyKCQkWyQwLTNdKTtcbiAgICAgIHRoaXMuJCA9ICQkWyQwLTFdLm1hcChmdW5jdGlvbih2KSB7IHZhciBvID0ge307IG9bJCRbJDAtM11dID0gdjsgcmV0dXJuIG87IH0pXG4gICAgXG5icmVhaztcbmNhc2UgMzY6XG5cbiAgICAgIHRoaXMuJCA9ICQkWyQwLTFdLm1hcChmdW5jdGlvbigpIHsgcmV0dXJuIHt9OyB9KVxuICAgIFxuYnJlYWs7XG5jYXNlIDM3OlxuXG4gICAgICB2YXIgbGVuZ3RoID0gJCRbJDAtNF0ubGVuZ3RoO1xuICAgICAgJCRbJDAtNF0gPSAkJFskMC00XS5tYXAodG9WYXIpO1xuICAgICAgdGhpcy4kID0gJCRbJDAtMV0ubWFwKGZ1bmN0aW9uICh2YWx1ZXMpIHtcbiAgICAgICAgaWYgKHZhbHVlcy5sZW5ndGggIT09IGxlbmd0aClcbiAgICAgICAgICB0aHJvdyBFcnJvcignSW5jb25zaXN0ZW50IFZBTFVFUyBsZW5ndGgnKTtcbiAgICAgICAgdmFyIHZhbHVlc09iamVjdCA9IHt9O1xuICAgICAgICBmb3IodmFyIGkgPSAwOyBpPGxlbmd0aDsgaSsrKVxuICAgICAgICAgIHZhbHVlc09iamVjdFskJFskMC00XVtpXV0gPSB2YWx1ZXNbaV07XG4gICAgICAgIHJldHVybiB2YWx1ZXNPYmplY3Q7XG4gICAgICB9KTtcbiAgICBcbmJyZWFrO1xuY2FzZSA0MDpcbnRoaXMuJCA9IHVuZGVmaW5lZDtcbmJyZWFrO1xuY2FzZSA0MTogY2FzZSA4NDogY2FzZSAxMDg6IGNhc2UgMTUyOlxudGhpcy4kID0gJCRbJDAtMV07XG5icmVhaztcbmNhc2UgNDI6XG50aGlzLiQgPSB7IHR5cGU6ICd1cGRhdGUnLCB1cGRhdGVzOiBhcHBlbmRUbygkJFskMC0yXSwgJCRbJDAtMV0pIH07XG5icmVhaztcbmNhc2UgNDM6XG50aGlzLiQgPSBleHRlbmQoeyB0eXBlOiAnbG9hZCcsIHNpbGVudDogISEkJFskMC0yXSwgc291cmNlOiAkJFskMC0xXSB9LCAkJFskMF0gJiYgeyBkZXN0aW5hdGlvbjogJCRbJDBdIH0pO1xuYnJlYWs7XG5jYXNlIDQ0OlxudGhpcy4kID0geyB0eXBlOiBsb3dlcmNhc2UoJCRbJDAtMl0pLCBzaWxlbnQ6ICEhJCRbJDAtMV0sIGdyYXBoOiAkJFskMF0gfTtcbmJyZWFrO1xuY2FzZSA0NTpcbnRoaXMuJCA9IHsgdHlwZTogbG93ZXJjYXNlKCQkWyQwLTRdKSwgc2lsZW50OiAhISQkWyQwLTNdLCBzb3VyY2U6ICQkWyQwLTJdLCBkZXN0aW5hdGlvbjogJCRbJDBdIH07XG5icmVhaztcbmNhc2UgNDY6XG50aGlzLiQgPSB7IHR5cGU6ICdjcmVhdGUnLCBzaWxlbnQ6ICEhJCRbJDAtMl0sIGdyYXBoOiB7IHR5cGU6ICdncmFwaCcsIG5hbWU6ICQkWyQwXSB9IH07XG5icmVhaztcbmNhc2UgNDc6XG50aGlzLiQgPSB7IHVwZGF0ZVR5cGU6ICdpbnNlcnQnLCAgICAgIGluc2VydDogJCRbJDBdIH07XG5icmVhaztcbmNhc2UgNDg6XG50aGlzLiQgPSB7IHVwZGF0ZVR5cGU6ICdkZWxldGUnLCAgICAgIGRlbGV0ZTogJCRbJDBdIH07XG5icmVhaztcbmNhc2UgNDk6XG50aGlzLiQgPSB7IHVwZGF0ZVR5cGU6ICdkZWxldGV3aGVyZScsIGRlbGV0ZTogJCRbJDBdIH07XG5icmVhaztcbmNhc2UgNTA6XG50aGlzLiQgPSBleHRlbmQoeyB1cGRhdGVUeXBlOiAnaW5zZXJ0ZGVsZXRlJyB9LCAkJFskMC01XSwgeyBpbnNlcnQ6ICQkWyQwLTRdIHx8IFtdIH0sIHsgZGVsZXRlOiAkJFskMC0zXSB8fCBbXSB9LCBncm91cERhdGFzZXRzKCQkWyQwLTJdKSwgeyB3aGVyZTogJCRbJDBdLnBhdHRlcm5zIH0pO1xuYnJlYWs7XG5jYXNlIDUxOlxudGhpcy4kID0gZXh0ZW5kKHsgdXBkYXRlVHlwZTogJ2luc2VydGRlbGV0ZScgfSwgJCRbJDAtNV0sIHsgZGVsZXRlOiAkJFskMC00XSB8fCBbXSB9LCB7IGluc2VydDogJCRbJDAtM10gfHwgW10gfSwgZ3JvdXBEYXRhc2V0cygkJFskMC0yXSksIHsgd2hlcmU6ICQkWyQwXS5wYXR0ZXJucyB9KTtcbmJyZWFrO1xuY2FzZSA1MjogY2FzZSA1MzogY2FzZSA1NjogY2FzZSAxNDM6XG50aGlzLiQgPSAkJFskMF07XG5icmVhaztcbmNhc2UgNTU6XG50aGlzLiQgPSB7IGdyYXBoOiAkJFskMF0gfTtcbmJyZWFrO1xuY2FzZSA1NzpcbnRoaXMuJCA9IHsgdHlwZTogJ2dyYXBoJywgZGVmYXVsdDogdHJ1ZSB9O1xuYnJlYWs7XG5jYXNlIDU4OiBjYXNlIDU5OlxudGhpcy4kID0geyB0eXBlOiAnZ3JhcGgnLCBuYW1lOiAkJFskMF0gfTtcbmJyZWFrO1xuY2FzZSA2MDpcbiB0aGlzLiQgPSB7fTsgdGhpcy4kW2xvd2VyY2FzZSgkJFskMF0pXSA9IHRydWU7IFxuYnJlYWs7XG5jYXNlIDYxOlxudGhpcy4kID0gJCRbJDAtMl0gPyB1bmlvbkFsbCgkJFskMC0xXSwgWyQkWyQwLTJdXSkgOiB1bmlvbkFsbCgkJFskMC0xXSk7XG5icmVhaztcbmNhc2UgNjI6XG5cbiAgICAgIHZhciBncmFwaCA9IGV4dGVuZCgkJFskMC0zXSB8fCB7IHRyaXBsZXM6IFtdIH0sIHsgdHlwZTogJ2dyYXBoJywgbmFtZTogdG9WYXIoJCRbJDAtNV0pIH0pO1xuICAgICAgdGhpcy4kID0gJCRbJDBdID8gW2dyYXBoLCAkJFskMF1dIDogW2dyYXBoXTtcbiAgICBcbmJyZWFrO1xuY2FzZSA2MzogY2FzZSA2ODpcbnRoaXMuJCA9IHsgdHlwZTogJ2JncCcsIHRyaXBsZXM6IHVuaW9uQWxsKCQkWyQwLTJdLCBbJCRbJDAtMV1dKSB9O1xuYnJlYWs7XG5jYXNlIDY0OlxudGhpcy4kID0geyB0eXBlOiAnZ3JvdXAnLCBwYXR0ZXJuczogWyAkJFskMC0xXSBdIH07XG5icmVhaztcbmNhc2UgNjU6XG50aGlzLiQgPSB7IHR5cGU6ICdncm91cCcsIHBhdHRlcm5zOiAkJFskMC0xXSB9O1xuYnJlYWs7XG5jYXNlIDY2OlxudGhpcy4kID0gJCRbJDAtMV0gPyB1bmlvbkFsbChbJCRbJDAtMV1dLCAkJFskMF0pIDogdW5pb25BbGwoJCRbJDBdKTtcbmJyZWFrO1xuY2FzZSA2NzpcbnRoaXMuJCA9ICQkWyQwXSA/IFskJFskMC0yXSwgJCRbJDBdXSA6ICQkWyQwLTJdO1xuYnJlYWs7XG5jYXNlIDY5OlxuXG4gICAgICBpZiAoJCRbJDAtMV0ubGVuZ3RoKVxuICAgICAgICB0aGlzLiQgPSB7IHR5cGU6ICd1bmlvbicsIHBhdHRlcm5zOiB1bmlvbkFsbCgkJFskMC0xXS5tYXAoZGVncm91cFNpbmdsZSksIFtkZWdyb3VwU2luZ2xlKCQkWyQwXSldKSB9O1xuICAgICAgZWxzZVxuICAgICAgICB0aGlzLiQgPSAkJFskMF07XG4gICAgXG5icmVhaztcbmNhc2UgNzA6XG50aGlzLiQgPSBleHRlbmQoJCRbJDBdLCB7IHR5cGU6ICdvcHRpb25hbCcgfSk7XG5icmVhaztcbmNhc2UgNzE6XG50aGlzLiQgPSBleHRlbmQoJCRbJDBdLCB7IHR5cGU6ICdtaW51cycgfSk7XG5icmVhaztcbmNhc2UgNzI6XG50aGlzLiQgPSBleHRlbmQoJCRbJDBdLCB7IHR5cGU6ICdncmFwaCcsIG5hbWU6IHRvVmFyKCQkWyQwLTFdKSB9KTtcbmJyZWFrO1xuY2FzZSA3MzpcbnRoaXMuJCA9IGV4dGVuZCgkJFskMF0sIHsgdHlwZTogJ3NlcnZpY2UnLCBuYW1lOiB0b1ZhcigkJFskMC0xXSksIHNpbGVudDogISEkJFskMC0yXSB9KTtcbmJyZWFrO1xuY2FzZSA3NDpcbnRoaXMuJCA9IHsgdHlwZTogJ2ZpbHRlcicsIGV4cHJlc3Npb246ICQkWyQwXSB9O1xuYnJlYWs7XG5jYXNlIDc1OlxudGhpcy4kID0geyB0eXBlOiAnYmluZCcsIHZhcmlhYmxlOiB0b1ZhcigkJFskMC0xXSksIGV4cHJlc3Npb246ICQkWyQwLTNdIH07XG5icmVhaztcbmNhc2UgODA6XG50aGlzLiQgPSB7IHR5cGU6ICdmdW5jdGlvbkNhbGwnLCBmdW5jdGlvbjogJCRbJDAtMV0sIGFyZ3M6IFtdIH07XG5icmVhaztcbmNhc2UgODE6XG50aGlzLiQgPSB7IHR5cGU6ICdmdW5jdGlvbkNhbGwnLCBmdW5jdGlvbjogJCRbJDAtNV0sIGFyZ3M6IGFwcGVuZFRvKCQkWyQwLTJdLCAkJFskMC0xXSksIGRpc3RpbmN0OiAhISQkWyQwLTNdIH07XG5icmVhaztcbmNhc2UgODI6IGNhc2UgOTk6IGNhc2UgMTEwOiBjYXNlIDE5NjogY2FzZSAyMDQ6IGNhc2UgMjE2OiBjYXNlIDIxODogY2FzZSAyMjg6IGNhc2UgMjMyOiBjYXNlIDI1MjogY2FzZSAyNTQ6IGNhc2UgMjU4OiBjYXNlIDI2MjogY2FzZSAyODU6IGNhc2UgMjkxOiBjYXNlIDMwMjogY2FzZSAzMTI6IGNhc2UgMzE4OiBjYXNlIDMyNDogY2FzZSAzMjg6IGNhc2UgMzM4OiBjYXNlIDM0MDogY2FzZSAzNDQ6IGNhc2UgMzUwOiBjYXNlIDM1NDogY2FzZSAzNjA6IGNhc2UgMzYyOiBjYXNlIDM2NjogY2FzZSAzNjg6IGNhc2UgMzc3OiBjYXNlIDM4NTogY2FzZSAzODc6IGNhc2UgMzk3OiBjYXNlIDQwMTogY2FzZSA0MDM6IGNhc2UgNDA1OlxudGhpcy4kID0gW107XG5icmVhaztcbmNhc2UgODM6XG50aGlzLiQgPSBhcHBlbmRUbygkJFskMC0yXSwgJCRbJDAtMV0pO1xuYnJlYWs7XG5jYXNlIDg1OlxudGhpcy4kID0gdW5pb25BbGwoJCRbJDAtMl0sIFskJFskMC0xXV0pO1xuYnJlYWs7XG5jYXNlIDg2OiBjYXNlIDk2OlxudGhpcy4kID0gJCRbJDBdLm1hcChmdW5jdGlvbiAodCkgeyByZXR1cm4gZXh0ZW5kKHRyaXBsZSgkJFskMC0xXSksIHQpOyB9KTtcbmJyZWFrO1xuY2FzZSA4NzpcbnRoaXMuJCA9IGFwcGVuZEFsbFRvKCQkWyQwXS5tYXAoZnVuY3Rpb24gKHQpIHsgcmV0dXJuIGV4dGVuZCh0cmlwbGUoJCRbJDAtMV0uZW50aXR5KSwgdCk7IH0pLCAkJFskMC0xXS50cmlwbGVzKSAvKiB0aGUgc3ViamVjdCBpcyBhIGJsYW5rIG5vZGUsIHBvc3NpYmx5IHdpdGggbW9yZSB0cmlwbGVzICovO1xuYnJlYWs7XG5jYXNlIDg5OlxudGhpcy4kID0gdW5pb25BbGwoWyQkWyQwLTFdXSwgJCRbJDBdKTtcbmJyZWFrO1xuY2FzZSA5MDpcbnRoaXMuJCA9IHVuaW9uQWxsKCQkWyQwXSk7XG5icmVhaztcbmNhc2UgOTE6XG50aGlzLiQgPSBvYmplY3RMaXN0VG9UcmlwbGVzKCQkWyQwLTFdLCAkJFskMF0pO1xuYnJlYWs7XG5jYXNlIDk0OiBjYXNlIDEwNjogY2FzZSAxMTM6XG50aGlzLiQgPSBSREZfVFlQRTtcbmJyZWFrO1xuY2FzZSA5NTpcbnRoaXMuJCA9IGFwcGVuZFRvKCQkWyQwLTFdLCAkJFskMF0pO1xuYnJlYWs7XG5jYXNlIDk3OlxudGhpcy4kID0gISQkWyQwXSA/ICQkWyQwLTFdLnRyaXBsZXMgOiBhcHBlbmRBbGxUbygkJFskMF0ubWFwKGZ1bmN0aW9uICh0KSB7IHJldHVybiBleHRlbmQodHJpcGxlKCQkWyQwLTFdLmVudGl0eSksIHQpOyB9KSwgJCRbJDAtMV0udHJpcGxlcykgLyogdGhlIHN1YmplY3QgaXMgYSBibGFuayBub2RlLCBwb3NzaWJseSB3aXRoIG1vcmUgdHJpcGxlcyAqLztcbmJyZWFrO1xuY2FzZSA5ODpcbnRoaXMuJCA9IG9iamVjdExpc3RUb1RyaXBsZXModG9WYXIoJCRbJDAtM10pLCBhcHBlbmRUbygkJFskMC0yXSwgJCRbJDAtMV0pLCAkJFskMF0pO1xuYnJlYWs7XG5jYXNlIDEwMDpcbnRoaXMuJCA9IG9iamVjdExpc3RUb1RyaXBsZXModG9WYXIoJCRbJDAtMV0pLCAkJFskMF0pO1xuYnJlYWs7XG5jYXNlIDEwMTpcbnRoaXMuJCA9ICQkWyQwLTFdLmxlbmd0aCA/IHBhdGgoJ3wnLGFwcGVuZFRvKCQkWyQwLTFdLCAkJFskMF0pKSA6ICQkWyQwXTtcbmJyZWFrO1xuY2FzZSAxMDI6XG50aGlzLiQgPSAkJFskMC0xXS5sZW5ndGggPyBwYXRoKCcvJywgYXBwZW5kVG8oJCRbJDAtMV0sICQkWyQwXSkpIDogJCRbJDBdO1xuYnJlYWs7XG5jYXNlIDEwMzpcbnRoaXMuJCA9ICQkWyQwXSA/IHBhdGgoJCRbJDBdLCBbJCRbJDAtMV1dKSA6ICQkWyQwLTFdO1xuYnJlYWs7XG5jYXNlIDEwNDpcbnRoaXMuJCA9ICQkWyQwLTFdID8gcGF0aCgkJFskMC0xXSwgWyQkWyQwXV0pIDogJCRbJDBdOztcbmJyZWFrO1xuY2FzZSAxMDc6IGNhc2UgMTE0OlxudGhpcy4kID0gcGF0aCgkJFskMC0xXSwgWyQkWyQwXV0pO1xuYnJlYWs7XG5jYXNlIDExMTpcbnRoaXMuJCA9IHBhdGgoJ3wnLCBhcHBlbmRUbygkJFskMC0yXSwgJCRbJDAtMV0pKTtcbmJyZWFrO1xuY2FzZSAxMTU6XG50aGlzLiQgPSBwYXRoKCQkWyQwLTFdLCBbUkRGX1RZUEVdKTtcbmJyZWFrO1xuY2FzZSAxMTY6IGNhc2UgMTE4OlxudGhpcy4kID0gY3JlYXRlTGlzdCgkJFskMC0xXSk7XG5icmVhaztcbmNhc2UgMTE3OiBjYXNlIDExOTpcbnRoaXMuJCA9IGNyZWF0ZUFub255bW91c09iamVjdCgkJFskMC0xXSk7XG5icmVhaztcbmNhc2UgMTIwOlxudGhpcy4kID0geyBlbnRpdHk6ICQkWyQwXSwgdHJpcGxlczogW10gfSAvKiBmb3IgY29uc2lzdGVuY3kgd2l0aCBUcmlwbGVzTm9kZSAqLztcbmJyZWFrO1xuY2FzZSAxMjI6XG50aGlzLiQgPSB7IGVudGl0eTogJCRbJDBdLCB0cmlwbGVzOiBbXSB9IC8qIGZvciBjb25zaXN0ZW5jeSB3aXRoIFRyaXBsZXNOb2RlUGF0aCAqLztcbmJyZWFrO1xuY2FzZSAxMjg6XG50aGlzLiQgPSBibGFuaygpO1xuYnJlYWs7XG5jYXNlIDEyOTpcbnRoaXMuJCA9IFJERl9OSUw7XG5icmVhaztcbmNhc2UgMTMwOiBjYXNlIDEzMjogY2FzZSAxMzc6IGNhc2UgMTQxOlxudGhpcy4kID0gY3JlYXRlT3BlcmF0aW9uVHJlZSgkJFskMC0xXSwgJCRbJDBdKTtcbmJyZWFrO1xuY2FzZSAxMzE6XG50aGlzLiQgPSBbJ3x8JywgJCRbJDBdXTtcbmJyZWFrO1xuY2FzZSAxMzM6XG50aGlzLiQgPSBbJyYmJywgJCRbJDBdXTtcbmJyZWFrO1xuY2FzZSAxMzU6XG50aGlzLiQgPSBvcGVyYXRpb24oJCRbJDAtMV0sIFskJFskMC0yXSwgJCRbJDBdXSk7XG5icmVhaztcbmNhc2UgMTM2OlxudGhpcy4kID0gb3BlcmF0aW9uKCQkWyQwLTJdID8gJ25vdGluJyA6ICdpbicsIFskJFskMC0zXSwgJCRbJDBdXSk7XG5icmVhaztcbmNhc2UgMTM4OiBjYXNlIDE0MjpcbnRoaXMuJCA9IFskJFskMC0xXSwgJCRbJDBdXTtcbmJyZWFrO1xuY2FzZSAxMzk6XG50aGlzLiQgPSBbJysnLCBjcmVhdGVPcGVyYXRpb25UcmVlKCQkWyQwLTFdLCAkJFskMF0pXTtcbmJyZWFrO1xuY2FzZSAxNDA6XG50aGlzLiQgPSBbJy0nLCBjcmVhdGVPcGVyYXRpb25UcmVlKCQkWyQwLTFdLnJlcGxhY2UoJy0nLCAnJyksICQkWyQwXSldO1xuYnJlYWs7XG5jYXNlIDE0NDpcbnRoaXMuJCA9IG9wZXJhdGlvbigkJFskMC0xXSwgWyQkWyQwXV0pO1xuYnJlYWs7XG5jYXNlIDE0NTpcbnRoaXMuJCA9IG9wZXJhdGlvbignVU1JTlVTJywgWyQkWyQwXV0pO1xuYnJlYWs7XG5jYXNlIDE1NDpcbnRoaXMuJCA9IG9wZXJhdGlvbihsb3dlcmNhc2UoJCRbJDAtMV0pKTtcbmJyZWFrO1xuY2FzZSAxNTU6XG50aGlzLiQgPSBvcGVyYXRpb24obG93ZXJjYXNlKCQkWyQwLTNdKSwgWyQkWyQwLTFdXSk7XG5icmVhaztcbmNhc2UgMTU2OlxudGhpcy4kID0gb3BlcmF0aW9uKGxvd2VyY2FzZSgkJFskMC01XSksIFskJFskMC0zXSwgJCRbJDAtMV1dKTtcbmJyZWFrO1xuY2FzZSAxNTc6XG50aGlzLiQgPSBvcGVyYXRpb24obG93ZXJjYXNlKCQkWyQwLTddKSwgWyQkWyQwLTVdLCAkJFskMC0zXSwgJCRbJDAtMV1dKTtcbmJyZWFrO1xuY2FzZSAxNTg6XG50aGlzLiQgPSBvcGVyYXRpb24obG93ZXJjYXNlKCQkWyQwLTFdKSwgJCRbJDBdKTtcbmJyZWFrO1xuY2FzZSAxNTk6XG50aGlzLiQgPSBvcGVyYXRpb24oJ2JvdW5kJywgW3RvVmFyKCQkWyQwLTFdKV0pO1xuYnJlYWs7XG5jYXNlIDE2MDpcbnRoaXMuJCA9IG9wZXJhdGlvbigkJFskMC0xXSwgW10pO1xuYnJlYWs7XG5jYXNlIDE2MTpcbnRoaXMuJCA9IG9wZXJhdGlvbigkJFskMC0zXSwgWyQkWyQwLTFdXSk7XG5icmVhaztcbmNhc2UgMTYyOlxudGhpcy4kID0gb3BlcmF0aW9uKCQkWyQwLTJdID8gJ25vdGV4aXN0cycgOidleGlzdHMnLCBbZGVncm91cFNpbmdsZSgkJFskMF0pXSk7XG5icmVhaztcbmNhc2UgMTYzOiBjYXNlIDE2NDpcbnRoaXMuJCA9IGV4cHJlc3Npb24oJCRbJDAtMV0sIHsgdHlwZTogJ2FnZ3JlZ2F0ZScsIGFnZ3JlZ2F0aW9uOiBsb3dlcmNhc2UoJCRbJDAtNF0pLCBkaXN0aW5jdDogISEkJFskMC0yXSB9KTtcbmJyZWFrO1xuY2FzZSAxNjU6XG50aGlzLiQgPSBleHByZXNzaW9uKCQkWyQwLTJdLCB7IHR5cGU6ICdhZ2dyZWdhdGUnLCBhZ2dyZWdhdGlvbjogbG93ZXJjYXNlKCQkWyQwLTVdKSwgZGlzdGluY3Q6ICEhJCRbJDAtM10sIHNlcGFyYXRvcjogJCRbJDAtMV0gfHwgJyAnIH0pO1xuYnJlYWs7XG5jYXNlIDE2NjpcbnRoaXMuJCA9ICQkWyQwXS5zdWJzdHIoMSwgJCRbJDBdLmxlbmd0aCAtIDIpO1xuYnJlYWs7XG5jYXNlIDE2ODpcbnRoaXMuJCA9ICQkWyQwLTFdICsgbG93ZXJjYXNlKCQkWyQwXSk7XG5icmVhaztcbmNhc2UgMTY5OlxudGhpcy4kID0gJCRbJDAtMl0gKyAnXl4nICsgJCRbJDBdO1xuYnJlYWs7XG5jYXNlIDE3MDogY2FzZSAxODQ6XG50aGlzLiQgPSBjcmVhdGVMaXRlcmFsKCQkWyQwXSwgWFNEX0lOVEVHRVIpO1xuYnJlYWs7XG5jYXNlIDE3MTogY2FzZSAxODU6XG50aGlzLiQgPSBjcmVhdGVMaXRlcmFsKCQkWyQwXSwgWFNEX0RFQ0lNQUwpO1xuYnJlYWs7XG5jYXNlIDE3MjogY2FzZSAxODY6XG50aGlzLiQgPSBjcmVhdGVMaXRlcmFsKGxvd2VyY2FzZSgkJFskMF0pLCBYU0RfRE9VQkxFKTtcbmJyZWFrO1xuY2FzZSAxNzU6XG50aGlzLiQgPSBYU0RfVFJVRTtcbmJyZWFrO1xuY2FzZSAxNzY6XG50aGlzLiQgPSBYU0RfRkFMU0U7XG5icmVhaztcbmNhc2UgMTc3OiBjYXNlIDE3ODpcbnRoaXMuJCA9IHVuZXNjYXBlU3RyaW5nKCQkWyQwXSwgMSk7XG5icmVhaztcbmNhc2UgMTc5OiBjYXNlIDE4MDpcbnRoaXMuJCA9IHVuZXNjYXBlU3RyaW5nKCQkWyQwXSwgMyk7XG5icmVhaztcbmNhc2UgMTgxOlxudGhpcy4kID0gY3JlYXRlTGl0ZXJhbCgkJFskMF0uc3Vic3RyKDEpLCBYU0RfSU5URUdFUik7XG5icmVhaztcbmNhc2UgMTgyOlxudGhpcy4kID0gY3JlYXRlTGl0ZXJhbCgkJFskMF0uc3Vic3RyKDEpLCBYU0RfREVDSU1BTCk7XG5icmVhaztcbmNhc2UgMTgzOlxudGhpcy4kID0gY3JlYXRlTGl0ZXJhbCgkJFskMF0uc3Vic3RyKDEpLnRvTG93ZXJDYXNlKCksIFhTRF9ET1VCTEUpO1xuYnJlYWs7XG5jYXNlIDE4NzpcbnRoaXMuJCA9IHJlc29sdmVJUkkoJCRbJDBdKTtcbmJyZWFrO1xuY2FzZSAxODg6XG5cbiAgICAgIHZhciBuYW1lUG9zID0gJCRbJDBdLmluZGV4T2YoJzonKSxcbiAgICAgICAgICBwcmVmaXggPSAkJFskMF0uc3Vic3RyKDAsIG5hbWVQb3MpLFxuICAgICAgICAgIGV4cGFuc2lvbiA9IFBhcnNlci5wcmVmaXhlc1twcmVmaXhdO1xuICAgICAgaWYgKCFleHBhbnNpb24pIHRocm93IG5ldyBFcnJvcignVW5rbm93biBwcmVmaXg6ICcgKyBwcmVmaXgpO1xuICAgICAgdGhpcy4kID0gcmVzb2x2ZUlSSShleHBhbnNpb24gKyAkJFskMF0uc3Vic3RyKG5hbWVQb3MgKyAxKSk7XG4gICAgXG5icmVhaztcbmNhc2UgMTg5OlxuXG4gICAgICAkJFskMF0gPSAkJFskMF0uc3Vic3RyKDAsICQkWyQwXS5sZW5ndGggLSAxKTtcbiAgICAgIGlmICghKCQkWyQwXSBpbiBQYXJzZXIucHJlZml4ZXMpKSB0aHJvdyBuZXcgRXJyb3IoJ1Vua25vd24gcHJlZml4OiAnICsgJCRbJDBdKTtcbiAgICAgIHRoaXMuJCA9IHJlc29sdmVJUkkoUGFyc2VyLnByZWZpeGVzWyQkWyQwXV0pO1xuICAgIFxuYnJlYWs7XG5jYXNlIDE5NzogY2FzZSAyMDU6IGNhc2UgMjEzOiBjYXNlIDIxNzogY2FzZSAyMTk6IGNhc2UgMjI1OiBjYXNlIDIyOTogY2FzZSAyMzM6IGNhc2UgMjQ3OiBjYXNlIDI0OTogY2FzZSAyNTE6IGNhc2UgMjUzOiBjYXNlIDI1NTogY2FzZSAyNTc6IGNhc2UgMjU5OiBjYXNlIDI2MTogY2FzZSAyODY6IGNhc2UgMjkyOiBjYXNlIDMwMzogY2FzZSAzMTk6IGNhc2UgMzUxOiBjYXNlIDM2MzogY2FzZSAzODI6IGNhc2UgMzg0OiBjYXNlIDM4NjogY2FzZSAzODg6IGNhc2UgMzk4OiBjYXNlIDQwMjogY2FzZSA0MDQ6IGNhc2UgNDA2OlxuJCRbJDAtMV0ucHVzaCgkJFskMF0pO1xuYnJlYWs7XG5jYXNlIDIxMjogY2FzZSAyMjQ6IGNhc2UgMjQ2OiBjYXNlIDI0ODogY2FzZSAyNTA6IGNhc2UgMjU2OiBjYXNlIDI2MDogY2FzZSAzODE6IGNhc2UgMzgzOlxudGhpcy4kID0gWyQkWyQwXV07XG5icmVhaztcbmNhc2UgMjYzOlxuJCRbJDAtM10ucHVzaCgkJFskMC0yXSk7XG5icmVhaztcbmNhc2UgMzEzOiBjYXNlIDMyNTogY2FzZSAzMjk6IGNhc2UgMzM5OiBjYXNlIDM0MTogY2FzZSAzNDU6IGNhc2UgMzU1OiBjYXNlIDM2MTogY2FzZSAzNjc6IGNhc2UgMzY5OiBjYXNlIDM3ODpcbiQkWyQwLTJdLnB1c2goJCRbJDAtMV0pO1xuYnJlYWs7XG59XG59LFxudGFibGU6IFtvKCRWMCwkVjEsezM6MSw0OjIsNzozfSksezE6WzNdfSxvKCRWMixbMiwyNjJdLHs1OjQsODo1LDI4Nzo2LDk6Nyw5NTo4LDE3OjksMzM6MTAsNDI6MTEsNDc6MTIsOTY6MTMsMTg6MTQsNjpbMiwxOTBdLDI0OiRWMywzNDpbMSwxNV0sNDM6WzEsMTZdLDQ4OlsxLDE3XX0pLG8oWzYsMjQsMzQsNDMsNDgsOTksMTA5LDExMiwxMTQsMTE1LDEyNCwxMjUsMTMwLDI5OCwyOTksMzAwLDMwMSwzMDJdLFsyLDJdLHsyODg6MTksMTE6MjAsMTQ6MjEsMTI6WzEsMjJdLDE1OlsxLDIzXX0pLHs2OlsxLDI0XX0sezY6WzIsMTkyXX0sezY6WzIsMTkzXX0sezY6WzIsMjAyXSwxMDoyNSw4MjoyNiw4MzokVjR9LHs2OlsyLDE5MV19LG8oJFY1LFsyLDE5OF0pLG8oJFY1LFsyLDE5OV0pLG8oJFY1LFsyLDIwMF0pLG8oJFY1LFsyLDIwMV0pLHs5NzoyOCw5OTpbMSwyOV0sMTAyOjMwLDEwNTozMSwxMDk6WzEsMzJdLDExMjpbMSwzM10sMTE0OlsxLDM0XSwxMTU6WzEsMzVdLDExNjozNiwxMjA6MzcsMTI0OlsyLDI4N10sMTI1OlsyLDI4MV0sMTI5OjQzLDEzMDpbMSw0NF0sMjk4OlsxLDM4XSwyOTk6WzEsMzldLDMwMDpbMSw0MF0sMzAxOlsxLDQxXSwzMDI6WzEsNDJdfSxvKCRWNixbMiwyMDRdLHsxOTo0NX0pLG8oJFY3LFsyLDIxOF0sezM1OjQ2LDM3OjQ3LDM5OlsxLDQ4XX0pLHsxMzokVjgsMTY6JFY5LDI4OiRWYSw0NDo0OSw1Mzo1NCwyODY6JFZiLDI5MzpbMSw1MV0sMjk0OjUyLDI5NTo1MH0sbygkVjYsWzIsMjMyXSx7NDk6NTh9KSxvKCRWYyxbMiwyMTBdLHsyNTo1OSwyODk6NjAsMjkwOlsxLDYxXSwyOTE6WzEsNjJdfSksbygkVjAsWzIsMTk3XSksbygkVjAsWzIsMTk0XSksbygkVjAsWzIsMTk1XSksezEzOlsxLDYzXX0sezE2OlsxLDY0XX0sezE6WzIsMV19LHs2OlsyLDNdfSx7NjpbMiwyMDNdfSx7Mjg6WzEsNjZdLDI5OlsxLDY4XSw4NDo2NSw4NjpbMSw2N119LHs2OlsyLDI2NF0sOTg6NjksMTgzOlsxLDcwXX0sbygkVmQsWzIsMjY2XSx7MTAwOjcxLDI5NzpbMSw3Ml19KSxvKCRWZSxbMiwyNzJdLHsxMDM6NzMsMjk3OlsxLDc0XX0pLG8oJFZmLFsyLDI3N10sezEwNjo3NSwyOTc6WzEsNzZdfSksezExMDo3NywxMTE6WzIsMjc5XSwyOTc6WzEsNzhdfSx7Mzk6JFZnLDExMzo3OX0sezM5OiRWZywxMTM6ODF9LHszOTokVmcsMTEzOjgyfSx7MTE3OjgzLDEyNTokVmh9LHsxMjE6ODUsMTI0OiRWaX0sbygkVmosWzIsMjcwXSksbygkVmosWzIsMjcxXSksbygkVmssWzIsMjc0XSksbygkVmssWzIsMjc1XSksbygkVmssWzIsMjc2XSksezEyNDpbMiwyODhdLDEyNTpbMiwyODJdfSx7MTM6JFY4LDE2OiRWOSw1Mzo4NywyODY6JFZifSx7MjA6ODgsMzg6JFZsLDM5OiRWbSw1MDo4OSw1MTokVm4sNTQ6OTB9LG8oJFY2LFsyLDIxNl0sezM2OjkzfSksezM4OlsxLDk0XSw1MDo5NSw1MTokVm59LG8oJFZvLFsyLDM0NF0sezE3MTo5NiwxNzI6OTcsMTczOjk4LDQxOlsyLDM0Ml19KSxvKCRWcCxbMiwyMjhdLHs0NTo5OX0pLG8oJFZwLFsyLDIyNl0sezUzOjU0LDI5NDoxMDAsMTM6JFY4LDE2OiRWOSwyODokVmEsMjg2OiRWYn0pLG8oJFZwLFsyLDIyN10pLG8oJFZxLFsyLDIyNF0pLG8oJFZxLFsyLDIyMl0pLG8oJFZxLFsyLDIyM10pLG8oJFZyLFsyLDE4N10pLG8oJFZyLFsyLDE4OF0pLG8oJFZyLFsyLDE4OV0pLHsyMDoxMDEsMzg6JFZsLDM5OiRWbSw1MDoxMDIsNTE6JFZuLDU0OjkwfSx7MjY6MTAzLDI3OjEwNiwyODokVnMsMjk6JFZ0LDI5MjoxMDQsMjkzOlsxLDEwNV19LG8oJFZjLFsyLDIxMV0pLG8oJFZjLFsyLDIwOF0pLG8oJFZjLFsyLDIwOV0pLG8oJFYwLFsyLDRdKSx7MTM6WzEsMTA5XX0sbygkVnUsWzIsMzRdKSx7Mzk6WzEsMTEwXX0sezM5OlsxLDExMV19LHsyODpbMSwxMTNdLDg4OjExMn0sezY6WzIsNDJdfSxvKCRWMCwkVjEsezc6Myw0OjExNH0pLHsxMzokVjgsMTY6JFY5LDUzOjExNSwyODY6JFZifSxvKCRWZCxbMiwyNjddKSx7MTA0OjExNiwxMTE6WzEsMTE3XSwxMzM6WzEsMTE5XSwxMzU6MTE4LDI5NjpbMSwxMjBdLDMwMzpbMSwxMjFdfSxvKCRWZSxbMiwyNzNdKSxvKCRWZCwkVnYsezEwNzoxMjIsMTM0OjEyNCwxMTE6JFZ3LDEzMzokVnh9KSxvKCRWZixbMiwyNzhdKSx7MTExOlsxLDEyNl19LHsxMTE6WzIsMjgwXX0sbygkVnksWzIsNDddKSxvKCRWbywkVnosezEzNjoxMjcsMTQzOjEyOCwxNDQ6MTI5LDQxOiRWQSwxMTE6JFZBfSksbygkVnksWzIsNDhdKSxvKCRWeSxbMiw0OV0pLG8oJFZCLFsyLDI4M10sezExODoxMzAsMTIxOjEzMSwxMjQ6JFZpfSksezM5OiRWZywxMTM6MTMyfSxvKCRWQixbMiwyODldLHsxMjI6MTMzLDExNzoxMzQsMTI1OiRWaH0pLHszOTokVmcsMTEzOjEzNX0sbyhbMTI0LDEyNV0sWzIsNTVdKSxvKCRWQywkVkQsezIxOjEzNiw1NjoxMzcsNjA6MTM4LDYxOiRWRX0pLG8oJFY2LFsyLDIwNV0pLHszOTokVkYsNTU6MTQwfSxvKCRWZCxbMiwyMzRdLHs1MjoxNDIsMjk2OlsxLDE0M119KSx7Mzk6WzIsMjM3XX0sezIwOjE0NCwzODokVmwsMzk6JFZtLDUwOjE0NSw1MTokVm4sNTQ6OTB9LHszOTpbMSwxNDZdfSxvKCRWNyxbMiwyMTldKSx7NDE6WzEsMTQ3XX0sezQxOlsyLDM0M119LHsxMzokVjgsMTY6JFY5LDI4OiRWRywyOTokVkgsNTM6MTUyLDgwOiRWSSw4NjokVkosOTE6MTUzLDE0NToxNDgsMTc1OjE0OSwxNzc6MTUwLDIxNTokVkssMjE4OiRWTCwyMTk6JFZNLDIzNjoxNjMsMjM4OjE2NCwyNjk6MTU5LDI3MjokVk4sMjczOiRWTywyNzQ6JFZQLDI3NTokVlEsMjc2OiRWUiwyNzc6JFZTLDI3ODokVlQsMjc5OiRWVSwyODA6JFZWLDI4MTokVlcsMjgyOiRWWCwyODM6JFZZLDI4NDokVlosMjg1OiRWXywyODY6JFZifSxvKCRWJCxbMiwyMzBdLHs1NDo5MCw0NjoxNzcsNTA6MTc4LDIwOjE3OSwzODokVmwsMzk6JFZtLDUxOiRWbn0pLG8oJFZxLFsyLDIyNV0pLG8oJFZDLCRWRCx7NTY6MTM3LDYwOjEzOCwyMToxODAsNjE6JFZFfSksbygkVjYsWzIsMjMzXSksbygkVjYsWzIsOF0pLG8oJFY2LFsyLDIxNF0sezI3OjE4MSwyODokVnMsMjk6JFZ0fSksbygkVjYsWzIsMjE1XSksbygkVjAxLFsyLDIxMl0pLG8oJFYwMSxbMiw5XSksbygkVjExLCRWMjEsezMwOjE4MiwyMjA6MTgzLDIyNDoxODQsMjI4OjE4NSwyMzI6MTg2LDI0MDoxODcsMjQ0OjE4OCwyMDg6JFYzMSwyNDY6JFY0MSwzMTA6JFY1MX0pLG8oJFYwLFsyLDVdKSxvKCRWNjEsWzIsMjUyXSx7ODU6MTkyfSksbygkVjcxLFsyLDI1NF0sezg3OjE5M30pLHsyODpbMSwxOTVdLDMyOlsxLDE5NF19LG8oJFY4MSxbMiwyNTZdKSxvKCRWMixbMiwyNjNdLHs2OlsyLDI2NV19KSxvKCRWeSxbMiwyNjhdLHsxMDE6MTk2LDEzMToxOTcsMTMyOlsxLDE5OF19KSxvKCRWeSxbMiw0NF0pLHsxMzokVjgsMTY6JFY5LDUzOjE5OSwyODY6JFZifSxvKCRWeSxbMiw2MF0pLG8oJFZ5LFsyLDI5N10pLG8oJFZ5LFsyLDI5OF0pLG8oJFZ5LFsyLDI5OV0pLHsxMDg6WzEsMjAwXX0sbygkVjkxLFsyLDU3XSksezEzOiRWOCwxNjokVjksNTM6MjAxLDI4NjokVmJ9LG8oJFZkLFsyLDI5Nl0pLHsxMzokVjgsMTY6JFY5LDUzOjIwMiwyODY6JFZifSxvKCRWYTEsWzIsMzAyXSx7MTM3OjIwM30pLG8oJFZhMSxbMiwzMDFdKSx7MTM6JFY4LDE2OiRWOSwyODokVkcsMjk6JFZILDUzOjE1Miw4MDokVkksODY6JFZKLDkxOjE1MywxNDU6MjA0LDE3NToxNDksMTc3OjE1MCwyMTU6JFZLLDIxODokVkwsMjE5OiRWTSwyMzY6MTYzLDIzODoxNjQsMjY5OjE1OSwyNzI6JFZOLDI3MzokVk8sMjc0OiRWUCwyNzU6JFZRLDI3NjokVlIsMjc3OiRWUywyNzg6JFZULDI3OTokVlUsMjgwOiRWViwyODE6JFZXLDI4MjokVlgsMjgzOiRWWSwyODQ6JFZaLDI4NTokVl8sMjg2OiRWYn0sbygkVkIsWzIsMjg1XSx7MTE5OjIwNX0pLG8oJFZCLFsyLDI4NF0pLG8oWzM4LDEyNCwxMjddLFsyLDUzXSksbygkVkIsWzIsMjkxXSx7MTIzOjIwNn0pLG8oJFZCLFsyLDI5MF0pLG8oWzM4LDEyNSwxMjddLFsyLDUyXSksbygkVjUsWzIsNl0pLG8oJFZiMSxbMiwyNDBdLHs1NzoyMDcsNjc6MjA4LDY4OlsxLDIwOV19KSxvKCRWQyxbMiwyMzldKSx7NjI6WzEsMjEwXX0sbyhbNiw0MSw2MSw2OCw3MSw3OSw4MSw4M10sWzIsMTZdKSxvKCRWbywkVmMxLHsyMjoyMTEsMTQ3OjIxMiwxODoyMTMsMTQ4OjIxNCwxNTQ6MjE1LDE1NToyMTYsMjQ6JFYzLDM5OiRWZDEsNDE6JFZkMSw4MzokVmQxLDExMTokVmQxLDE1OTokVmQxLDE2MDokVmQxLDE2MjokVmQxLDE2NTokVmQxLDE2NjokVmQxfSksezEzOiRWOCwxNjokVjksNTM6MjE3LDI4NjokVmJ9LG8oJFZkLFsyLDIzNV0pLG8oJFZDLCRWRCx7NTY6MTM3LDYwOjEzOCwyMToyMTgsNjE6JFZFfSksbygkVjYsWzIsMjE3XSksbygkVm8sJFZ6LHsxNDQ6MTI5LDQwOjIxOSwxNDM6MjIwLDQxOlsyLDIyMF19KSxvKCRWNixbMiw4NF0pLHs0MTpbMiwzNDZdLDE3NDoyMjEsMzA0OlsxLDIyMl19LHsxMzokVjgsMTY6JFY5LDI4OiRWZTEsNTM6MjI3LDE3NjoyMjMsMTgwOjIyNCwxODU6MjI1LDE4NzokVmYxLDI4NjokVmJ9LG8oJFZnMSxbMiwzNDhdLHsxODA6MjI0LDE4NToyMjUsNTM6MjI3LDE3ODoyMjksMTc5OjIzMCwxNzY6MjMxLDEzOiRWOCwxNjokVjksMjg6JFZlMSwxODc6JFZmMSwyODY6JFZifSksbygkVmgxLFsyLDEyNF0pLG8oJFZoMSxbMiwxMjVdKSxvKCRWaDEsWzIsMTI2XSksbygkVmgxLFsyLDEyN10pLG8oJFZoMSxbMiwxMjhdKSxvKCRWaDEsWzIsMTI5XSksezEzOiRWOCwxNjokVjksMjg6JFZHLDI5OiRWSCw1MzoxNTIsODA6JFZJLDg2OiRWSiw5MToxNTMsMTc1OjIzNCwxNzc6MjM1LDE4OToyMzMsMjE0OjIzMiwyMTU6JFZLLDIxODokVkwsMjE5OiRWTSwyMzY6MTYzLDIzODoxNjQsMjY5OjE1OSwyNzI6JFZOLDI3MzokVk8sMjc0OiRWUCwyNzU6JFZRLDI3NjokVlIsMjc3OiRWUywyNzg6JFZULDI3OTokVlUsMjgwOiRWViwyODE6JFZXLDI4MjokVlgsMjgzOiRWWSwyODQ6JFZaLDI4NTokVl8sMjg2OiRWYn0sezEzOiRWOCwxNjokVjksMjg6JFZlMSw1MzoyMjcsMTc2OjIzNiwxODA6MjI0LDE4NToyMjUsMTg3OiRWZjEsMjg2OiRWYn0sbygkVmkxLFsyLDE2N10sezI3MDpbMSwyMzddLDI3MTpbMSwyMzhdfSksbygkVmkxLFsyLDE3MF0pLG8oJFZpMSxbMiwxNzFdKSxvKCRWaTEsWzIsMTcyXSksbygkVmkxLFsyLDE3M10pLG8oJFZpMSxbMiwxNzRdKSxvKCRWaTEsWzIsMTc1XSksbygkVmkxLFsyLDE3Nl0pLG8oJFZqMSxbMiwxNzddKSxvKCRWajEsWzIsMTc4XSksbygkVmoxLFsyLDE3OV0pLG8oJFZqMSxbMiwxODBdKSxvKCRWaTEsWzIsMTgxXSksbygkVmkxLFsyLDE4Ml0pLG8oJFZpMSxbMiwxODNdKSxvKCRWaTEsWzIsMTg0XSksbygkVmkxLFsyLDE4NV0pLG8oJFZpMSxbMiwxODZdKSxvKCRWQywkVkQsezU2OjEzNyw2MDoxMzgsMjE6MjM5LDYxOiRWRX0pLG8oJFZwLFsyLDIyOV0pLG8oJFYkLFsyLDIzMV0pLG8oJFY1LFsyLDE0XSksbygkVjAxLFsyLDIxM10pLHszMTpbMSwyNDBdfSxvKCRWazEsWzIsMzg1XSx7MjIxOjI0MX0pLG8oJFZsMSxbMiwzODddLHsyMjU6MjQyfSksbygkVmwxLFsyLDEzNF0sezIyOToyNDMsMjMwOjI0NCwyMzE6WzIsMzk1XSwyNjg6WzEsMjQ1XSwzMTE6WzEsMjQ2XSwzMTI6WzEsMjQ3XSwzMTM6WzEsMjQ4XSwzMTQ6WzEsMjQ5XSwzMTU6WzEsMjUwXSwzMTY6WzEsMjUxXX0pLG8oJFZtMSxbMiwzOTddLHsyMzM6MjUyfSksbygkVm4xLFsyLDQwNV0sezI0MToyNTN9KSx7MTM6JFY4LDE2OiRWOSwyODokVm8xLDI5OiRWcDEsNTM6MjU3LDY1OjI1Niw2NjoyNTgsNzU6MjU1LDgwOiRWSSw5MToyNTksMjM2OjE2MywyMzg6MTY0LDI0NToyNTQsMjQ3OjI2MiwyNDg6JFZxMSwyNDk6JFZyMSwyNTA6JFZzMSwyNTI6JFZ0MSwyNTM6MjY3LDI1NDokVnUxLDI1NTokVnYxLDI1NjoyNzAsMjU3OiRWdzEsMjU4OiRWeDEsMjYxOiRWeTEsMjYzOiRWejEsMjY5OjE1OSwyNzI6JFZOLDI3MzokVk8sMjc0OiRWUCwyNzU6JFZRLDI3NjokVlIsMjc3OiRWUywyNzg6JFZULDI3OTokVlUsMjgwOiRWViwyODE6JFZXLDI4MjokVlgsMjgzOiRWWSwyODQ6JFZaLDI4NTokVl8sMjg2OiRWYiwzMTY6JFZBMSwzMTc6JFZCMSwzMTg6JFZDMSwzMTk6JFZEMSwzMjA6JFZFMSwzMjE6JFZGMX0sezEzOiRWOCwxNjokVjksMjg6JFZvMSwyOTokVnAxLDUzOjI1Nyw2NToyNTYsNjY6MjU4LDc1OjI1NSw4MDokVkksOTE6MjU5LDIzNjoxNjMsMjM4OjE2NCwyNDU6MjgwLDI0NzoyNjIsMjQ4OiRWcTEsMjQ5OiRWcjEsMjUwOiRWczEsMjUyOiRWdDEsMjUzOjI2NywyNTQ6JFZ1MSwyNTU6JFZ2MSwyNTY6MjcwLDI1NzokVncxLDI1ODokVngxLDI2MTokVnkxLDI2MzokVnoxLDI2OToxNTksMjcyOiRWTiwyNzM6JFZPLDI3NDokVlAsMjc1OiRWUSwyNzY6JFZSLDI3NzokVlMsMjc4OiRWVCwyNzk6JFZVLDI4MDokVlYsMjgxOiRWVywyODI6JFZYLDI4MzokVlksMjg0OiRWWiwyODU6JFZfLDI4NjokVmIsMzE2OiRWQTEsMzE3OiRWQjEsMzE4OiRWQzEsMzE5OiRWRDEsMzIwOiRWRTEsMzIxOiRWRjF9LHsxMzokVjgsMTY6JFY5LDI4OiRWbzEsMjk6JFZwMSw1MzoyNTcsNjU6MjU2LDY2OjI1OCw3NToyNTUsODA6JFZJLDkxOjI1OSwyMzY6MTYzLDIzODoxNjQsMjQ1OjI4MSwyNDc6MjYyLDI0ODokVnExLDI0OTokVnIxLDI1MDokVnMxLDI1MjokVnQxLDI1MzoyNjcsMjU0OiRWdTEsMjU1OiRWdjEsMjU2OjI3MCwyNTc6JFZ3MSwyNTg6JFZ4MSwyNjE6JFZ5MSwyNjM6JFZ6MSwyNjk6MTU5LDI3MjokVk4sMjczOiRWTywyNzQ6JFZQLDI3NTokVlEsMjc2OiRWUiwyNzc6JFZTLDI3ODokVlQsMjc5OiRWVSwyODA6JFZWLDI4MTokVlcsMjgyOiRWWCwyODM6JFZZLDI4NDokVlosMjg1OiRWXywyODY6JFZiLDMxNjokVkExLDMxNzokVkIxLDMxODokVkMxLDMxOTokVkQxLDMyMDokVkUxLDMyMTokVkYxfSxvKCRWMTEsWzIsNDEwXSksezEzOiRWOCwxNjokVjksNDE6WzEsMjgyXSw1MzoyODQsODA6JFZJLDkwOjI4Myw5MToyODUsOTI6JFZHMSwyMzY6MTYzLDIzODoxNjQsMjY5OjE1OSwyNzI6JFZOLDI3MzokVk8sMjc0OiRWUCwyNzU6JFZRLDI3NjokVlIsMjc3OiRWUywyNzg6JFZULDI3OTokVlUsMjgwOiRWViwyODE6JFZXLDI4MjokVlgsMjgzOiRWWSwyODQ6JFZaLDI4NTokVl8sMjg2OiRWYn0sezQxOlsxLDI4N10sODY6WzEsMjg4XX0sezM5OlsxLDI4OV19LG8oJFY4MSxbMiwyNTddKSxvKCRWeSxbMiw0M10pLG8oJFZ5LFsyLDI2OV0pLHsxMTE6WzEsMjkwXX0sbygkVnksWzIsNTldKSxvKCRWZCwkVnYsezEzNDoxMjQsMTA3OjI5MSwxMTE6JFZ3LDEzMzokVnh9KSxvKCRWOTEsWzIsNThdKSxvKCRWeSxbMiw0Nl0pLHs0MTpbMSwyOTJdLDExMTpbMSwyOTRdLDEzODoyOTN9LG8oJFZhMSxbMiwzMTRdLHsxNDY6Mjk1LDMwNDpbMSwyOTZdfSksezM4OlsxLDI5N10sMTI2OjI5OCwxMjc6JFZIMX0sezM4OlsxLDMwMF0sMTI2OjMwMSwxMjc6JFZIMX0sbygkVkkxLFsyLDI0Ml0sezU4OjMwMiw3MDozMDMsNzE6WzEsMzA0XX0pLG8oJFZiMSxbMiwyNDFdKSx7MTM6JFY4LDE2OiRWOSwyOTokVnAxLDUzOjMxMCw2NTozMDgsNjY6MzA5LDY5OjMwNSw3NTozMDcsNzc6MzA2LDI0NzoyNjIsMjQ4OiRWcTEsMjQ5OiRWcjEsMjUwOiRWczEsMjUyOiRWdDEsMjUzOjI2NywyNTQ6JFZ1MSwyNTU6JFZ2MSwyNTY6MjcwLDI1NzokVncxLDI1ODokVngxLDI2MTokVnkxLDI2MzokVnoxLDI4NjokVmIsMzE2OiRWQTEsMzE3OiRWQjEsMzE4OiRWQzEsMzE5OiRWRDEsMzIwOiRWRTEsMzIxOiRWRjF9LHsxMzokVjgsMTY6JFY5LDI4OiRWSjEsMjk6JFZLMSw1MzozMTAsNjM6MzExLDY0OjMxMiw2NTozMTMsNjY6MzE0LDI0NzoyNjIsMjQ4OiRWcTEsMjQ5OiRWcjEsMjUwOiRWczEsMjUyOiRWdDEsMjUzOjI2NywyNTQ6JFZ1MSwyNTU6JFZ2MSwyNTY6MjcwLDI1NzokVncxLDI1ODokVngxLDI2MTokVnkxLDI2MzokVnoxLDI4NjokVmIsMzE2OiRWQTEsMzE3OiRWQjEsMzE4OiRWQzEsMzE5OiRWRDEsMzIwOiRWRTEsMzIxOiRWRjF9LHs0MTpbMSwzMTddfSx7NDE6WzEsMzE4XX0sezIwOjMxOSwzODokVmwsMzk6JFZtLDU0OjkwfSxvKCRWTDEsWzIsMzE4XSx7MTQ5OjMyMH0pLG8oJFZMMSxbMiwzMTddKSx7MTM6JFY4LDE2OiRWOSwyODokVkcsMjk6JFZNMSw1MzoxNTIsODA6JFZJLDg2OiRWSiw5MToxNTMsMTU2OjMyMSwxNzU6MzIyLDE5MTozMjMsMjE1OiRWTjEsMjE4OiRWTCwyMTk6JFZNLDIzNjoxNjMsMjM4OjE2NCwyNjk6MTU5LDI3MjokVk4sMjczOiRWTywyNzQ6JFZQLDI3NTokVlEsMjc2OiRWUiwyNzc6JFZTLDI3ODokVlQsMjc5OiRWVSwyODA6JFZWLDI4MTokVlcsMjgyOiRWWCwyODM6JFZZLDI4NDokVlosMjg1OiRWXywyODY6JFZifSxvKCRWcCxbMiwxNV0pLG8oJFY1LFsyLDExXSksezQxOlsxLDMyNl19LHs0MTpbMiwyMjFdfSx7NDE6WzIsODVdfSxvKCRWbyxbMiwzNDVdLHs0MTpbMiwzNDddfSksbygkVmcxLFsyLDg2XSksbygkVk8xLFsyLDM1MF0sezE4MTozMjd9KSxvKCRWbywkVlAxLHsxODY6MzI4LDE4ODozMjl9KSxvKCRWbyxbMiw5Ml0pLG8oJFZvLFsyLDkzXSksbygkVm8sWzIsOTRdKSxvKCRWZzEsWzIsODddKSxvKCRWZzEsWzIsODhdKSxvKCRWZzEsWzIsMzQ5XSksezEzOiRWOCwxNjokVjksMjg6JFZHLDI5OiRWSCwzMjpbMSwzMzBdLDUzOjE1Miw4MDokVkksODY6JFZKLDkxOjE1MywxNzU6MjM0LDE3NzoyMzUsMTg5OjMzMSwyMTU6JFZLLDIxODokVkwsMjE5OiRWTSwyMzY6MTYzLDIzODoxNjQsMjY5OjE1OSwyNzI6JFZOLDI3MzokVk8sMjc0OiRWUCwyNzU6JFZRLDI3NjokVlIsMjc3OiRWUywyNzg6JFZULDI3OTokVlUsMjgwOiRWViwyODE6JFZXLDI4MjokVlgsMjgzOiRWWSwyODQ6JFZaLDI4NTokVl8sMjg2OiRWYn0sbygkVlExLFsyLDM4MV0pLG8oJFZSMSxbMiwxMjBdKSxvKCRWUjEsWzIsMTIxXSksezIxNjpbMSwzMzJdfSxvKCRWaTEsWzIsMTY4XSksezEzOiRWOCwxNjokVjksNTM6MzMzLDI4NjokVmJ9LG8oJFY1LFsyLDEzXSksezI4OlsxLDMzNF19LG8oWzMxLDMyLDE4MywyNTFdLFsyLDEzMF0sezIyMjozMzUsMjIzOlsxLDMzNl19KSxvKCRWazEsWzIsMTMyXSx7MjI2OjMzNywyMjc6WzEsMzM4XX0pLG8oJFYxMSwkVjIxLHsyMzI6MTg2LDI0MDoxODcsMjQ0OjE4OCwyMjg6MzM5LDIwODokVjMxLDI0NjokVjQxLDMxMDokVjUxfSksezIzMTpbMSwzNDBdfSxvKCRWUzEsWzIsMzg5XSksbygkVlMxLFsyLDM5MF0pLG8oJFZTMSxbMiwzOTFdKSxvKCRWUzEsWzIsMzkyXSksbygkVlMxLFsyLDM5M10pLG8oJFZTMSxbMiwzOTRdKSx7MjMxOlsyLDM5Nl19LG8oWzMxLDMyLDE4MywyMjMsMjI3LDIzMSwyNTEsMjY4LDMxMSwzMTIsMzEzLDMxNCwzMTUsMzE2XSxbMiwxMzddLHsyMzQ6MzQxLDIzNTozNDIsMjM2OjM0MywyMzg6MzQ0LDI0NjpbMSwzNDZdLDI4MDokVlYsMjgxOiRWVywyODI6JFZYLDI4MzokVlksMjg0OiRWWiwyODU6JFZfLDMxMDpbMSwzNDVdfSksbygkVm0xLFsyLDE0MV0sezI0MjozNDcsMjQzOjM0OCwyOTM6JFZUMSwzMDc6JFZVMX0pLG8oJFZuMSxbMiwxNDNdKSxvKCRWbjEsWzIsMTQ2XSksbygkVm4xLFsyLDE0N10pLG8oJFZuMSxbMiwxNDhdLHsyOTokVlYxLDg2OiRWVzF9KSxvKCRWbjEsWzIsMTQ5XSksbygkVm4xLFsyLDE1MF0pLG8oJFZuMSxbMiwxNTFdKSxvKCRWMTEsJFYyMSx7MjIwOjE4MywyMjQ6MTg0LDIyODoxODUsMjMyOjE4NiwyNDA6MTg3LDI0NDoxODgsMzA6MzUzLDIwODokVjMxLDI0NjokVjQxLDMxMDokVjUxfSksbygkVlgxLFsyLDE1M10pLHs4NjpbMSwzNTRdfSx7Mjk6WzEsMzU1XX0sezI5OlsxLDM1Nl19LHsyOTpbMSwzNTddfSx7Mjk6JFZZMSw4NjokVloxLDE2OTozNTh9LHsyOTpbMSwzNjFdfSx7Mjk6WzEsMzYzXSw4NjpbMSwzNjJdfSx7MjU3OlsxLDM2NF19LHsyOTpbMSwzNjVdfSx7Mjk6WzEsMzY2XX0sezI5OlsxLDM2N119LG8oJFZfMSxbMiw0MTFdKSxvKCRWXzEsWzIsNDEyXSksbygkVl8xLFsyLDQxM10pLG8oJFZfMSxbMiw0MTRdKSxvKCRWXzEsWzIsNDE1XSksezI1NzpbMiw0MTddfSxvKCRWbjEsWzIsMTQ0XSksbygkVm4xLFsyLDE0NV0pLG8oJFZ1LFsyLDM1XSksbygkVjYxLFsyLDI1M10pLG8oJFYkMSxbMiwzOF0pLG8oJFYkMSxbMiwzOV0pLG8oJFYkMSxbMiw0MF0pLG8oJFZ1LFsyLDM2XSksbygkVjcxLFsyLDI1NV0pLG8oJFYwMixbMiwyNThdLHs4OTozNjh9KSx7MTM6JFY4LDE2OiRWOSw1MzozNjksMjg2OiRWYn0sbygkVnksWzIsNDVdKSxvKFs2LDM4LDEyNCwxMjUsMTI3LDE4M10sWzIsNjFdKSxvKCRWYTEsWzIsMzAzXSksezEzOiRWOCwxNjokVjksMjg6WzEsMzcxXSw1MzozNzIsMTM5OjM3MCwyODY6JFZifSxvKCRWYTEsWzIsNjNdKSxvKCRWbyxbMiwzMTNdLHs0MTokVjEyLDExMTokVjEyfSksezM5OiRWRiw1NTozNzN9LG8oJFZCLFsyLDI4Nl0pLG8oJFZkLFsyLDI5M10sezEyODozNzQsMjk2OlsxLDM3NV19KSx7Mzk6JFZGLDU1OjM3Nn0sbygkVkIsWzIsMjkyXSksbygkVjIyLFsyLDI0NF0sezU5OjM3Nyw3ODozNzgsNzk6WzEsMzc5XSw4MTpbMSwzODBdfSksbygkVkkxLFsyLDI0M10pLHs2MjpbMSwzODFdfSxvKCRWYjEsWzIsMjRdLHsyNDc6MjYyLDI1MzoyNjcsMjU2OjI3MCw3NTozMDcsNjU6MzA4LDY2OjMwOSw1MzozMTAsNzc6MzgyLDEzOiRWOCwxNjokVjksMjk6JFZwMSwyNDg6JFZxMSwyNDk6JFZyMSwyNTA6JFZzMSwyNTI6JFZ0MSwyNTQ6JFZ1MSwyNTU6JFZ2MSwyNTc6JFZ3MSwyNTg6JFZ4MSwyNjE6JFZ5MSwyNjM6JFZ6MSwyODY6JFZiLDMxNjokVkExLDMxNzokVkIxLDMxODokVkMxLDMxOTokVkQxLDMyMDokVkUxLDMyMTokVkYxfSksbygkVjMyLFsyLDI0OF0pLG8oJFY0MixbMiw3N10pLG8oJFY0MixbMiw3OF0pLG8oJFY0MixbMiw3OV0pLHsyOTokVlYxLDg2OiRWVzF9LG8oJFZDLFsyLDE4XSx7MjQ3OjI2MiwyNTM6MjY3LDI1NjoyNzAsNTM6MzEwLDY1OjMxMyw2NjozMTQsNjQ6MzgzLDEzOiRWOCwxNjokVjksMjg6JFZKMSwyOTokVksxLDI0ODokVnExLDI0OTokVnIxLDI1MDokVnMxLDI1MjokVnQxLDI1NDokVnUxLDI1NTokVnYxLDI1NzokVncxLDI1ODokVngxLDI2MTokVnkxLDI2MzokVnoxLDI4NjokVmIsMzE2OiRWQTEsMzE3OiRWQjEsMzE4OiRWQzEsMzE5OiRWRDEsMzIwOiRWRTEsMzIxOiRWRjF9KSxvKCRWNTIsWzIsMjQ2XSksbygkVjUyLFsyLDE5XSksbygkVjUyLFsyLDIwXSksbygkVjExLCRWMjEsezIyMDoxODMsMjI0OjE4NCwyMjg6MTg1LDIzMjoxODYsMjQwOjE4NywyNDQ6MTg4LDMwOjM4NCwyMDg6JFYzMSwyNDY6JFY0MSwzMTA6JFY1MX0pLG8oJFY1MixbMiwyM10pLG8oJFY2MixbMiw2NF0pLG8oJFY2MixbMiw2NV0pLG8oJFZDLCRWRCx7NTY6MTM3LDYwOjEzOCwyMTozODUsNjE6JFZFfSksezM5OlsyLDMyOF0sNDE6WzIsNjZdLDgyOjM5NSw4MzokVjQsMTExOlsxLDM5MV0sMTUwOjM4NiwxNTE6Mzg3LDE1ODozODgsMTU5OlsxLDM4OV0sMTYwOlsxLDM5MF0sMTYyOlsxLDM5Ml0sMTY1OlsxLDM5M10sMTY2OlsxLDM5NF19LG8oJFZMMSxbMiwzMjZdLHsxNTc6Mzk2LDMwNDpbMSwzOTddfSksbygkVjcyLCRWODIsezE5MDozOTgsMTkzOjM5OSwxOTk6NDAwLDIwMDo0MDIsMjg6JFY5Mn0pLG8oJFZhMixbMiwzNTZdLHsxOTM6Mzk5LDE5OTo0MDAsMjAwOjQwMiwxOTI6NDAzLDE5MDo0MDQsMTM6JFY4MiwxNjokVjgyLDI5OiRWODIsMTg3OiRWODIsMjA4OiRWODIsMjEzOiRWODIsMjg2OiRWODIsMjg6JFY5Mn0pLHsxMzokVjgsMTY6JFY5LDI4OiRWRywyOTokVk0xLDUzOjE1Miw4MDokVkksODY6JFZKLDkxOjE1MywxNzU6NDA3LDE5MTo0MDgsMTk1OjQwNiwyMTU6JFZOMSwyMTc6NDA1LDIxODokVkwsMjE5OiRWTSwyMzY6MTYzLDIzODoxNjQsMjY5OjE1OSwyNzI6JFZOLDI3MzokVk8sMjc0OiRWUCwyNzU6JFZRLDI3NjokVlIsMjc3OiRWUywyNzg6JFZULDI3OTokVlUsMjgwOiRWViwyODE6JFZXLDI4MjokVlgsMjgzOiRWWSwyODQ6JFZaLDI4NTokVl8sMjg2OiRWYn0sbygkVjcyLCRWODIsezE5MzozOTksMTk5OjQwMCwyMDA6NDAyLDE5MDo0MDksMjg6JFY5Mn0pLG8oJFZDLCRWRCx7NTY6MTM3LDYwOjEzOCwyMTo0MTAsNjE6JFZFfSksbyhbNDEsMTExLDIxNiwzMDRdLFsyLDg5XSx7MTgyOjQxMSwxODM6WzEsNDEyXX0pLG8oJFZPMSxbMiw5MV0pLHsxMzokVjgsMTY6JFY5LDI4OiRWRywyOTokVkgsNTM6MTUyLDgwOiRWSSw4NjokVkosOTE6MTUzLDE3NToyMzQsMTc3OjIzNSwxODk6NDEzLDIxNTokVkssMjE4OiRWTCwyMTk6JFZNLDIzNjoxNjMsMjM4OjE2NCwyNjk6MTU5LDI3MjokVk4sMjczOiRWTywyNzQ6JFZQLDI3NTokVlEsMjc2OiRWUiwyNzc6JFZTLDI3ODokVlQsMjc5OiRWVSwyODA6JFZWLDI4MTokVlcsMjgyOiRWWCwyODM6JFZZLDI4NDokVlosMjg1OiRWXywyODY6JFZifSxvKCRWYjIsWzIsMTE2XSksbygkVlExLFsyLDM4Ml0pLG8oJFZiMixbMiwxMTddKSxvKCRWaTEsWzIsMTY5XSksezMyOlsxLDQxNF19LG8oJFZrMSxbMiwzODZdKSxvKCRWMTEsJFYyMSx7MjI0OjE4NCwyMjg6MTg1LDIzMjoxODYsMjQwOjE4NywyNDQ6MTg4LDIyMDo0MTUsMjA4OiRWMzEsMjQ2OiRWNDEsMzEwOiRWNTF9KSxvKCRWbDEsWzIsMzg4XSksbygkVjExLCRWMjEsezIyODoxODUsMjMyOjE4NiwyNDA6MTg3LDI0NDoxODgsMjI0OjQxNiwyMDg6JFYzMSwyNDY6JFY0MSwzMTA6JFY1MX0pLG8oJFZsMSxbMiwxMzVdKSx7Mjk6JFZZMSw4NjokVloxLDE2OTo0MTd9LG8oJFZtMSxbMiwzOThdKSxvKCRWMTEsJFYyMSx7MjQwOjE4NywyNDQ6MTg4LDIzMjo0MTgsMjA4OiRWMzEsMjQ2OiRWNDEsMzEwOiRWNTF9KSxvKCRWbjEsWzIsNDAxXSx7MjM3OjQxOX0pLG8oJFZuMSxbMiw0MDNdLHsyMzk6NDIwfSksbygkVlMxLFsyLDM5OV0pLG8oJFZTMSxbMiw0MDBdKSxvKCRWbjEsWzIsNDA2XSksbygkVjExLCRWMjEsezI0NDoxODgsMjQwOjQyMSwyMDg6JFYzMSwyNDY6JFY0MSwzMTA6JFY1MX0pLG8oJFZTMSxbMiw0MDddKSxvKCRWUzEsWzIsNDA4XSksbygkVlgxLFsyLDgwXSksbygkVlMxLFsyLDMzNl0sezE2Nzo0MjIsMjkwOlsxLDQyM119KSx7MzI6WzEsNDI0XX0sbygkVlgxLFsyLDE1NF0pLG8oJFYxMSwkVjIxLHsyMjA6MTgzLDIyNDoxODQsMjI4OjE4NSwyMzI6MTg2LDI0MDoxODcsMjQ0OjE4OCwzMDo0MjUsMjA4OiRWMzEsMjQ2OiRWNDEsMzEwOiRWNTF9KSxvKCRWMTEsJFYyMSx7MjIwOjE4MywyMjQ6MTg0LDIyODoxODUsMjMyOjE4NiwyNDA6MTg3LDI0NDoxODgsMzA6NDI2LDIwODokVjMxLDI0NjokVjQxLDMxMDokVjUxfSksbygkVjExLCRWMjEsezIyMDoxODMsMjI0OjE4NCwyMjg6MTg1LDIzMjoxODYsMjQwOjE4NywyNDQ6MTg4LDMwOjQyNywyMDg6JFYzMSwyNDY6JFY0MSwzMTA6JFY1MX0pLG8oJFZYMSxbMiwxNThdKSxvKCRWWDEsWzIsODJdKSxvKCRWUzEsWzIsMzQwXSx7MTcwOjQyOH0pLHsyODpbMSw0MjldfSxvKCRWWDEsWzIsMTYwXSksbygkVjExLCRWMjEsezIyMDoxODMsMjI0OjE4NCwyMjg6MTg1LDIzMjoxODYsMjQwOjE4NywyNDQ6MTg4LDMwOjQzMCwyMDg6JFYzMSwyNDY6JFY0MSwzMTA6JFY1MX0pLHszOTokVkYsNTU6NDMxfSxvKCRWYzIsWzIsNDE4XSx7MjU5OjQzMiwyOTA6WzEsNDMzXX0pLG8oJFZTMSxbMiw0MjJdLHsyNjI6NDM0LDI5MDpbMSw0MzVdfSksbygkVlMxLFsyLDQyNF0sezI2NDo0MzYsMjkwOlsxLDQzN119KSx7Mjk6WzEsNDQwXSw0MTpbMSw0MzhdLDkzOjQzOX0sbygkVnksWzIsNTZdKSx7Mzk6WzEsNDQxXX0sezM5OlsyLDMwNF19LHszOTpbMiwzMDVdfSxvKCRWeSxbMiw1MF0pLHsxMzokVjgsMTY6JFY5LDUzOjQ0MiwyODY6JFZifSxvKCRWZCxbMiwyOTRdKSxvKCRWeSxbMiw1MV0pLG8oJFYyMixbMiwxN10pLG8oJFYyMixbMiwyNDVdKSx7ODA6WzEsNDQzXX0sezgwOlsxLDQ0NF19LHsxMzokVjgsMTY6JFY5LDI4OiRWZDIsMjk6JFZwMSw1MzozMTAsNjU6MzA4LDY2OjMwOSw3Mjo0NDUsNzM6NDQ2LDc0OiRWZTIsNzU6MzA3LDc2OiRWZjIsNzc6NDQ5LDI0NzoyNjIsMjQ4OiRWcTEsMjQ5OiRWcjEsMjUwOiRWczEsMjUyOiRWdDEsMjUzOjI2NywyNTQ6JFZ1MSwyNTU6JFZ2MSwyNTY6MjcwLDI1NzokVncxLDI1ODokVngxLDI2MTokVnkxLDI2MzokVnoxLDI4NjokVmIsMzE2OiRWQTEsMzE3OiRWQjEsMzE4OiRWQzEsMzE5OiRWRDEsMzIwOiRWRTEsMzIxOiRWRjF9LG8oJFYzMixbMiwyNDldKSxvKCRWNTIsWzIsMjQ3XSksezMxOlsxLDQ1Ml0sMzI6WzEsNDUxXX0sezIzOjQ1Myw0MTpbMiwyMDZdLDgyOjQ1NCw4MzokVjR9LG8oJFZMMSxbMiwzMTldKSxvKCRWZzIsWzIsMzIwXSx7MTUyOjQ1NSwzMDQ6WzEsNDU2XX0pLHszOTokVkYsNTU6NDU3fSx7Mzk6JFZGLDU1OjQ1OH0sezM5OiRWRiw1NTo0NTl9LHsxMzokVjgsMTY6JFY5LDI4OlsxLDQ2MV0sNTM6NDYyLDE2MTo0NjAsMjg2OiRWYn0sbygkVmgyLFsyLDMzMl0sezE2Mzo0NjMsMjk3OlsxLDQ2NF19KSx7MTM6JFY4LDE2OiRWOSwyOTokVnAxLDUzOjMxMCw2NTozMDgsNjY6MzA5LDc1OjMwNyw3Nzo0NjUsMjQ3OjI2MiwyNDg6JFZxMSwyNDk6JFZyMSwyNTA6JFZzMSwyNTI6JFZ0MSwyNTM6MjY3LDI1NDokVnUxLDI1NTokVnYxLDI1NjoyNzAsMjU3OiRWdzEsMjU4OiRWeDEsMjYxOiRWeTEsMjYzOiRWejEsMjg2OiRWYiwzMTY6JFZBMSwzMTc6JFZCMSwzMTg6JFZDMSwzMTk6JFZEMSwzMjA6JFZFMSwzMjE6JFZGMX0sezI5OlsxLDQ2Nl19LG8oJFZpMixbMiw3Nl0pLG8oJFZMMSxbMiw2OF0pLG8oJFZvLFsyLDMyNV0sezM5OiRWajIsNDE6JFZqMiw4MzokVmoyLDExMTokVmoyLDE1OTokVmoyLDE2MDokVmoyLDE2MjokVmoyLDE2NTokVmoyLDE2NjokVmoyfSksbygkVmEyLFsyLDk2XSksbygkVm8sWzIsMzYwXSx7MTk0OjQ2N30pLG8oJFZvLFsyLDM1OF0pLG8oJFZvLFsyLDM1OV0pLG8oJFY3MixbMiwzNjhdLHsyMDE6NDY4LDIwMjo0Njl9KSxvKCRWYTIsWzIsOTddKSxvKCRWYTIsWzIsMzU3XSksezEzOiRWOCwxNjokVjksMjg6JFZHLDI5OiRWTTEsMzI6WzEsNDcwXSw1MzoxNTIsODA6JFZJLDg2OiRWSiw5MToxNTMsMTc1OjQwNywxOTE6NDA4LDE5NTo0NzEsMjE1OiRWTjEsMjE4OiRWTCwyMTk6JFZNLDIzNjoxNjMsMjM4OjE2NCwyNjk6MTU5LDI3MjokVk4sMjczOiRWTywyNzQ6JFZQLDI3NTokVlEsMjc2OiRWUiwyNzc6JFZTLDI3ODokVlQsMjc5OiRWVSwyODA6JFZWLDI4MTokVlcsMjgyOiRWWCwyODM6JFZZLDI4NDokVlosMjg1OiRWXywyODY6JFZifSxvKCRWUTEsWzIsMzgzXSksbygkVlIxLFsyLDEyMl0pLG8oJFZSMSxbMiwxMjNdKSx7MjE2OlsxLDQ3Ml19LG8oJFY1LFsyLDEyXSksbygkVk8xLFsyLDM1MV0pLG8oJFZPMSxbMiwzNTJdLHsxODU6MjI1LDUzOjIyNywxODQ6NDczLDE4MDo0NzQsMTM6JFY4LDE2OiRWOSwyODokVmUxLDE4NzokVmYxLDI4NjokVmJ9KSxvKCRWazIsWzIsOTVdLHsyNTE6WzEsNDc1XX0pLG8oJFYwMSxbMiwxMF0pLG8oJFZrMSxbMiwxMzFdKSxvKCRWbDEsWzIsMTMzXSksbygkVmwxLFsyLDEzNl0pLG8oJFZtMSxbMiwxMzhdKSxvKCRWbTEsWzIsMTM5XSx7MjQzOjM0OCwyNDI6NDc2LDI5MzokVlQxLDMwNzokVlUxfSksbygkVm0xLFsyLDE0MF0sezI0MzozNDgsMjQyOjQ3NywyOTM6JFZUMSwzMDc6JFZVMX0pLG8oJFZuMSxbMiwxNDJdKSxvKCRWUzEsWzIsMzM4XSx7MTY4OjQ3OH0pLG8oJFZTMSxbMiwzMzddKSxvKFs2LDEzLDE2LDI4LDI5LDMxLDMyLDM5LDQxLDcxLDc0LDc2LDc5LDgwLDgxLDgzLDg2LDExMSwxNTksMTYwLDE2MiwxNjUsMTY2LDE4MywyMTUsMjE4LDIxOSwyMjMsMjI3LDIzMSwyNDYsMjQ4LDI0OSwyNTAsMjUxLDI1MiwyNTQsMjU1LDI1NywyNTgsMjYxLDI2MywyNjgsMjcyLDI3MywyNzQsMjc1LDI3NiwyNzcsMjc4LDI3OSwyODAsMjgxLDI4MiwyODMsMjg0LDI4NSwyODYsMjkzLDMwNCwzMDcsMzEwLDMxMSwzMTIsMzEzLDMxNCwzMTUsMzE2LDMxNywzMTgsMzE5LDMyMCwzMjFdLFsyLDE1Ml0pLHszMjpbMSw0NzldfSx7MjUxOlsxLDQ4MF19LHsyNTE6WzEsNDgxXX0sbygkVjExLCRWMjEsezIyMDoxODMsMjI0OjE4NCwyMjg6MTg1LDIzMjoxODYsMjQwOjE4NywyNDQ6MTg4LDMwOjQ4MiwyMDg6JFYzMSwyNDY6JFY0MSwzMTA6JFY1MX0pLHszMjpbMSw0ODNdfSx7MzI6WzEsNDg0XX0sbygkVlgxLFsyLDE2Ml0pLG8oJFYxMSwkVjIxLHsyMjA6MTgzLDIyNDoxODQsMjI4OjE4NSwyMzI6MTg2LDI0MDoxODcsMjQ0OjE4OCwyNjA6NDg1LDMwOjQ4NywyMDg6JFYzMSwyNDY6JFY0MSwyOTM6WzEsNDg2XSwzMTA6JFY1MX0pLG8oJFZjMixbMiw0MTldKSxvKCRWMTEsJFYyMSx7MjIwOjE4MywyMjQ6MTg0LDIyODoxODUsMjMyOjE4NiwyNDA6MTg3LDI0NDoxODgsMzA6NDg4LDIwODokVjMxLDI0NjokVjQxLDMxMDokVjUxfSksbygkVlMxLFsyLDQyM10pLG8oJFYxMSwkVjIxLHsyMjA6MTgzLDIyNDoxODQsMjI4OjE4NSwyMzI6MTg2LDI0MDoxODcsMjQ0OjE4OCwzMDo0ODksMjA4OiRWMzEsMjQ2OiRWNDEsMzEwOiRWNTF9KSxvKCRWUzEsWzIsNDI1XSksbygkVnUsWzIsMzddKSxvKCRWMDIsWzIsMjU5XSksezEzOiRWOCwxNjokVjksNTM6Mjg0LDgwOiRWSSw5MDo0OTEsOTE6Mjg1LDkyOiRWRzEsOTQ6NDkwLDIzNjoxNjMsMjM4OjE2NCwyNjk6MTU5LDI3MjokVk4sMjczOiRWTywyNzQ6JFZQLDI3NTokVlEsMjc2OiRWUiwyNzc6JFZTLDI3ODokVlQsMjc5OiRWVSwyODA6JFZWLDI4MTokVlcsMjgyOiRWWCwyODM6JFZZLDI4NDokVlosMjg1OiRWXywyODY6JFZifSxvKCRWbywkVnosezE0NDoxMjksMTQwOjQ5MiwxNDM6NDkzLDQxOlsyLDMwNl19KSxvKCRWQixbMiw1NF0pLG8oJFYyMixbMiwzMF0sezgxOlsxLDQ5NF19KSxvKCRWMjIsWzIsMzFdLHs3OTpbMSw0OTVdfSksbygkVkkxLFsyLDI1XSx7MjQ3OjI2MiwyNTM6MjY3LDI1NjoyNzAsNzU6MzA3LDY1OjMwOCw2NjozMDksNTM6MzEwLDc3OjQ0OSw3Mzo0OTYsMTM6JFY4LDE2OiRWOSwyODokVmQyLDI5OiRWcDEsNzQ6JFZlMiw3NjokVmYyLDI0ODokVnExLDI0OTokVnIxLDI1MDokVnMxLDI1MjokVnQxLDI1NDokVnUxLDI1NTokVnYxLDI1NzokVncxLDI1ODokVngxLDI2MTokVnkxLDI2MzokVnoxLDI4NjokVmIsMzE2OiRWQTEsMzE3OiRWQjEsMzE4OiRWQzEsMzE5OiRWRDEsMzIwOiRWRTEsMzIxOiRWRjF9KSxvKCRWbDIsWzIsMjUwXSksezI5OiRWcDEsNzU6NDk3fSx7Mjk6JFZwMSw3NTo0OTh9LG8oJFZsMixbMiwyOF0pLG8oJFZsMixbMiwyOV0pLG8oJFY1MixbMiwyMV0pLHsyODpbMSw0OTldfSx7NDE6WzIsN119LHs0MTpbMiwyMDddfSxvKCRWbywkVmMxLHsxNTU6MjE2LDE1Mzo1MDAsMTU0OjUwMSwzOTokVm0yLDQxOiRWbTIsODM6JFZtMiwxMTE6JFZtMiwxNTk6JFZtMiwxNjA6JFZtMiwxNjI6JFZtMiwxNjU6JFZtMiwxNjY6JFZtMn0pLG8oJFZnMixbMiwzMjFdKSxvKCRWaTIsWzIsNjldLHszMDU6WzEsNTAyXX0pLG8oJFZpMixbMiw3MF0pLG8oJFZpMixbMiw3MV0pLHszOTokVkYsNTU6NTAzfSx7Mzk6WzIsMzMwXX0sezM5OlsyLDMzMV19LHsxMzokVjgsMTY6JFY5LDI4OlsxLDUwNV0sNTM6NTA2LDE2NDo1MDQsMjg2OiRWYn0sbygkVmgyLFsyLDMzM10pLG8oJFZpMixbMiw3NF0pLG8oJFYxMSwkVjIxLHsyMjA6MTgzLDIyNDoxODQsMjI4OjE4NSwyMzI6MTg2LDI0MDoxODcsMjQ0OjE4OCwzMDo1MDcsMjA4OiRWMzEsMjQ2OiRWNDEsMzEwOiRWNTF9KSx7MTM6JFY4LDE2OiRWOSwyODokVkcsMjk6JFZNMSw1MzoxNTIsODA6JFZJLDg2OiRWSiw5MToxNTMsMTc1OjQwNywxOTE6NDA4LDE5NTo1MDgsMjE1OiRWTjEsMjE4OiRWTCwyMTk6JFZNLDIzNjoxNjMsMjM4OjE2NCwyNjk6MTU5LDI3MjokVk4sMjczOiRWTywyNzQ6JFZQLDI3NTokVlEsMjc2OiRWUiwyNzc6JFZTLDI3ODokVlQsMjc5OiRWVSwyODA6JFZWLDI4MTokVlcsMjgyOiRWWCwyODM6JFZZLDI4NDokVlosMjg1OiRWXywyODY6JFZifSxvKCRWUTEsWzIsMTAxXSx7MzA2OlsxLDUwOV19KSxvKCRWbjIsWzIsMzc1XSx7MjAzOjUxMCwyMDc6NTExLDIxMzpbMSw1MTJdfSksbygkVmgxLFsyLDExOF0pLG8oJFZRMSxbMiwzODRdKSxvKCRWaDEsWzIsMTE5XSksbygkVk8xLFsyLDkwXSksbygkVk8xLFsyLDM1M10pLG8oJFZvLFsyLDM1NV0pLG8oJFZuMSxbMiw0MDJdKSxvKCRWbjEsWzIsNDA0XSksbygkVjExLCRWMjEsezIyMDoxODMsMjI0OjE4NCwyMjg6MTg1LDIzMjoxODYsMjQwOjE4NywyNDQ6MTg4LDMwOjUxMywyMDg6JFYzMSwyNDY6JFY0MSwzMTA6JFY1MX0pLG8oJFZYMSxbMiwxNTVdKSxvKCRWMTEsJFYyMSx7MjIwOjE4MywyMjQ6MTg0LDIyODoxODUsMjMyOjE4NiwyNDA6MTg3LDI0NDoxODgsMzA6NTE0LDIwODokVjMxLDI0NjokVjQxLDMxMDokVjUxfSksbygkVjExLCRWMjEsezIyMDoxODMsMjI0OjE4NCwyMjg6MTg1LDIzMjoxODYsMjQwOjE4NywyNDQ6MTg4LDMwOjUxNSwyMDg6JFYzMSwyNDY6JFY0MSwzMTA6JFY1MX0pLHszMjpbMSw1MTZdLDI1MTpbMSw1MTddfSxvKCRWWDEsWzIsMTU5XSksbygkVlgxLFsyLDE2MV0pLHszMjpbMSw1MThdfSx7MzI6WzIsNDIwXX0sezMyOlsyLDQyMV19LHszMjpbMSw1MTldfSx7MzI6WzIsNDI2XSwxODM6WzEsNTIyXSwyNjU6NTIwLDI2Njo1MjF9LHsxMzokVjgsMTY6JFY5LDMyOlsxLDUyM10sNTM6Mjg0LDgwOiRWSSw5MDo1MjQsOTE6Mjg1LDkyOiRWRzEsMjM2OjE2MywyMzg6MTY0LDI2OToxNTksMjcyOiRWTiwyNzM6JFZPLDI3NDokVlAsMjc1OiRWUSwyNzY6JFZSLDI3NzokVlMsMjc4OiRWVCwyNzk6JFZVLDI4MDokVlYsMjgxOiRWVywyODI6JFZYLDI4MzokVlksMjg0OiRWWiwyODU6JFZfLDI4NjokVmJ9LG8oJFZvMixbMiwyNjBdKSx7NDE6WzEsNTI1XX0sezQxOlsyLDMwN119LHs4MDpbMSw1MjZdfSx7ODA6WzEsNTI3XX0sbygkVmwyLFsyLDI1MV0pLG8oJFZsMixbMiwyNl0pLG8oJFZsMixbMiwyN10pLHszMjpbMSw1MjhdfSxvKCRWTDEsWzIsNjddKSxvKCRWTDEsWzIsMzIzXSksezM5OlsyLDMyOV19LG8oJFZpMixbMiw3Ml0pLHszOTokVkYsNTU6NTI5fSx7Mzk6WzIsMzM0XX0sezM5OlsyLDMzNV19LHszMTpbMSw1MzBdfSxvKCRWazIsWzIsMzYyXSx7MTk2OjUzMSwyNTE6WzEsNTMyXX0pLG8oJFY3MixbMiwzNjddKSxvKFsxMywxNiwyOCwyOSwzMiw4MCw4NiwyMTUsMjE4LDIxOSwyNzIsMjczLDI3NCwyNzUsMjc2LDI3NywyNzgsMjc5LDI4MCwyODEsMjgyLDI4MywyODQsMjg1LDI4NiwzMDZdLFsyLDEwMl0sezMwNzpbMSw1MzNdfSksezEzOiRWOCwxNjokVjksMjk6WzEsNTM5XSw1Mzo1MzYsMTg3OlsxLDUzN10sMjA0OjUzNCwyMDU6NTM1LDIwODpbMSw1MzhdLDI4NjokVmJ9LG8oJFZuMixbMiwzNzZdKSx7MzI6WzEsNTQwXSwyNTE6WzEsNTQxXX0sezMyOlsxLDU0Ml19LHsyNTE6WzEsNTQzXX0sbygkVlgxLFsyLDgzXSksbygkVlMxLFsyLDM0MV0pLG8oJFZYMSxbMiwxNjNdKSxvKCRWWDEsWzIsMTY0XSksezMyOlsxLDU0NF19LHszMjpbMiw0MjddfSx7MjY3OlsxLDU0NV19LG8oJFYwMixbMiw0MV0pLG8oJFZvMixbMiwyNjFdKSxvKCRWcDIsWzIsMzA4XSx7MTQxOjU0NiwzMDQ6WzEsNTQ3XX0pLG8oJFYyMixbMiwzMl0pLG8oJFYyMixbMiwzM10pLG8oJFY1MixbMiwyMl0pLG8oJFZpMixbMiw3M10pLHsyODpbMSw1NDhdfSxvKFszOSw0MSw4MywxMTEsMTU5LDE2MCwxNjIsMTY1LDE2NiwyMTYsMzA0XSxbMiw5OF0sezE5Nzo1NDksMTgzOlsxLDU1MF19KSxvKCRWbyxbMiwzNjFdKSxvKCRWNzIsWzIsMzY5XSksbygkVnEyLFsyLDEwNF0pLG8oJFZxMixbMiwzNzNdLHsyMDY6NTUxLDMwODo1NTIsMjkzOlsxLDU1NF0sMzA5OlsxLDU1M10sMzEwOlsxLDU1NV19KSxvKCRWcjIsWzIsMTA1XSksbygkVnIyLFsyLDEwNl0pLHsxMzokVjgsMTY6JFY5LDI5OlsxLDU1OV0sNTM6NTYwLDg2OlsxLDU1OF0sMTg3OiRWczIsMjA5OjU1NiwyMTA6NTU3LDIxMzokVnQyLDI4NjokVmJ9LG8oJFY3MiwkVjgyLHsyMDA6NDAyLDE5OTo1NjN9KSxvKCRWWDEsWzIsODFdKSxvKCRWUzEsWzIsMzM5XSksbygkVlgxLFsyLDE1Nl0pLG8oJFYxMSwkVjIxLHsyMjA6MTgzLDIyNDoxODQsMjI4OjE4NSwyMzI6MTg2LDI0MDoxODcsMjQ0OjE4OCwzMDo1NjQsMjA4OiRWMzEsMjQ2OiRWNDEsMzEwOiRWNTF9KSxvKCRWWDEsWzIsMTY1XSksezI2ODpbMSw1NjVdfSxvKCRWbywkVnosezE0NDoxMjksMTQyOjU2NiwxNDM6NTY3LDQxOiRWdTIsMTExOiRWdTJ9KSxvKCRWcDIsWzIsMzA5XSksezMyOlsxLDU2OF19LG8oJFZrMixbMiwzNjNdKSxvKCRWazIsWzIsOTldLHsyMDA6NDAyLDE5ODo1NjksMTk5OjU3MCwxMzokVjgyLDE2OiRWODIsMjk6JFY4MiwxODc6JFY4MiwyMDg6JFY4MiwyMTM6JFY4MiwyODY6JFY4MiwyODpbMSw1NzFdfSksbygkVnEyLFsyLDEwM10pLG8oJFZxMixbMiwzNzRdKSxvKCRWcTIsWzIsMzcwXSksbygkVnEyLFsyLDM3MV0pLG8oJFZxMixbMiwzNzJdKSxvKCRWcjIsWzIsMTA3XSksbygkVnIyLFsyLDEwOV0pLG8oJFZyMixbMiwxMTBdKSxvKCRWdjIsWzIsMzc3XSx7MjExOjU3Mn0pLG8oJFZyMixbMiwxMTJdKSxvKCRWcjIsWzIsMTEzXSksezEzOiRWOCwxNjokVjksNTM6NTczLDE4NzpbMSw1NzRdLDI4NjokVmJ9LHszMjpbMSw1NzVdfSx7MzI6WzEsNTc2XX0sezI2OTo1NzcsMjc2OiRWUiwyNzc6JFZTLDI3ODokVlQsMjc5OiRWVX0sbygkVmExLFsyLDYyXSksbygkVmExLFsyLDMxMV0pLG8oJFZpMixbMiw3NV0pLG8oJFZvLCRWUDEsezE4ODozMjksMTg2OjU3OH0pLG8oJFZvLFsyLDM2NF0pLG8oJFZvLFsyLDM2NV0pLHsxMzokVjgsMTY6JFY5LDMyOlsyLDM3OV0sNTM6NTYwLDE4NzokVnMyLDIxMDo1ODAsMjEyOjU3OSwyMTM6JFZ0MiwyODY6JFZifSxvKCRWcjIsWzIsMTE0XSksbygkVnIyLFsyLDExNV0pLG8oJFZyMixbMiwxMDhdKSxvKCRWWDEsWzIsMTU3XSksezMyOlsyLDE2Nl19LG8oJFZrMixbMiwxMDBdKSx7MzI6WzEsNTgxXX0sezMyOlsyLDM4MF0sMzA2OlsxLDU4Ml19LG8oJFZyMixbMiwxMTFdKSxvKCRWdjIsWzIsMzc4XSldLFxuZGVmYXVsdEFjdGlvbnM6IHs1OlsyLDE5Ml0sNjpbMiwxOTNdLDg6WzIsMTkxXSwyNDpbMiwxXSwyNTpbMiwzXSwyNjpbMiwyMDNdLDY5OlsyLDQyXSw3ODpbMiwyODBdLDkyOlsyLDIzN10sOTc6WzIsMzQzXSwyMjA6WzIsMjIxXSwyMjE6WzIsODVdLDI1MTpbMiwzOTZdLDI3OTpbMiw0MTddLDM3MTpbMiwzMDRdLDM3MjpbMiwzMDVdLDQ1MzpbMiw3XSw0NTQ6WzIsMjA3XSw0NjE6WzIsMzMwXSw0NjI6WzIsMzMxXSw0ODY6WzIsNDIwXSw0ODc6WzIsNDIxXSw0OTM6WzIsMzA3XSw1MDI6WzIsMzI5XSw1MDU6WzIsMzM0XSw1MDY6WzIsMzM1XSw1MjE6WzIsNDI3XSw1Nzc6WzIsMTY2XX0sXG5wYXJzZUVycm9yOiBmdW5jdGlvbiBwYXJzZUVycm9yIChzdHIsIGhhc2gpIHtcbiAgICBpZiAoaGFzaC5yZWNvdmVyYWJsZSkge1xuICAgICAgICB0aGlzLnRyYWNlKHN0cik7XG4gICAgfSBlbHNlIHtcbiAgICAgICAgdmFyIGVycm9yID0gbmV3IEVycm9yKHN0cik7XG4gICAgICAgIGVycm9yLmhhc2ggPSBoYXNoO1xuICAgICAgICB0aHJvdyBlcnJvcjtcbiAgICB9XG59LFxucGFyc2U6IGZ1bmN0aW9uIHBhcnNlKGlucHV0KSB7XG4gICAgdmFyIHNlbGYgPSB0aGlzLCBzdGFjayA9IFswXSwgdHN0YWNrID0gW10sIHZzdGFjayA9IFtudWxsXSwgbHN0YWNrID0gW10sIHRhYmxlID0gdGhpcy50YWJsZSwgeXl0ZXh0ID0gJycsIHl5bGluZW5vID0gMCwgeXlsZW5nID0gMCwgcmVjb3ZlcmluZyA9IDAsIFRFUlJPUiA9IDIsIEVPRiA9IDE7XG4gICAgdmFyIGFyZ3MgPSBsc3RhY2suc2xpY2UuY2FsbChhcmd1bWVudHMsIDEpO1xuICAgIHZhciBsZXhlciA9IE9iamVjdC5jcmVhdGUodGhpcy5sZXhlcik7XG4gICAgdmFyIHNoYXJlZFN0YXRlID0geyB5eToge30gfTtcbiAgICBmb3IgKHZhciBrIGluIHRoaXMueXkpIHtcbiAgICAgICAgaWYgKE9iamVjdC5wcm90b3R5cGUuaGFzT3duUHJvcGVydHkuY2FsbCh0aGlzLnl5LCBrKSkge1xuICAgICAgICAgICAgc2hhcmVkU3RhdGUueXlba10gPSB0aGlzLnl5W2tdO1xuICAgICAgICB9XG4gICAgfVxuICAgIGxleGVyLnNldElucHV0KGlucHV0LCBzaGFyZWRTdGF0ZS55eSk7XG4gICAgc2hhcmVkU3RhdGUueXkubGV4ZXIgPSBsZXhlcjtcbiAgICBzaGFyZWRTdGF0ZS55eS5wYXJzZXIgPSB0aGlzO1xuICAgIGlmICh0eXBlb2YgbGV4ZXIueXlsbG9jID09ICd1bmRlZmluZWQnKSB7XG4gICAgICAgIGxleGVyLnl5bGxvYyA9IHt9O1xuICAgIH1cbiAgICB2YXIgeXlsb2MgPSBsZXhlci55eWxsb2M7XG4gICAgbHN0YWNrLnB1c2goeXlsb2MpO1xuICAgIHZhciByYW5nZXMgPSBsZXhlci5vcHRpb25zICYmIGxleGVyLm9wdGlvbnMucmFuZ2VzO1xuICAgIGlmICh0eXBlb2Ygc2hhcmVkU3RhdGUueXkucGFyc2VFcnJvciA9PT0gJ2Z1bmN0aW9uJykge1xuICAgICAgICB0aGlzLnBhcnNlRXJyb3IgPSBzaGFyZWRTdGF0ZS55eS5wYXJzZUVycm9yO1xuICAgIH0gZWxzZSB7XG4gICAgICAgIHRoaXMucGFyc2VFcnJvciA9IE9iamVjdC5nZXRQcm90b3R5cGVPZih0aGlzKS5wYXJzZUVycm9yO1xuICAgIH1cbiAgICBmdW5jdGlvbiBwb3BTdGFjayhuKSB7XG4gICAgICAgIHN0YWNrLmxlbmd0aCA9IHN0YWNrLmxlbmd0aCAtIDIgKiBuO1xuICAgICAgICB2c3RhY2subGVuZ3RoID0gdnN0YWNrLmxlbmd0aCAtIG47XG4gICAgICAgIGxzdGFjay5sZW5ndGggPSBsc3RhY2subGVuZ3RoIC0gbjtcbiAgICB9XG4gICAgX3Rva2VuX3N0YWNrOlxuICAgICAgICB2YXIgbGV4ID0gZnVuY3Rpb24gKCkge1xuICAgICAgICAgICAgdmFyIHRva2VuO1xuICAgICAgICAgICAgdG9rZW4gPSBsZXhlci5sZXgoKSB8fCBFT0Y7XG4gICAgICAgICAgICBpZiAodHlwZW9mIHRva2VuICE9PSAnbnVtYmVyJykge1xuICAgICAgICAgICAgICAgIHRva2VuID0gc2VsZi5zeW1ib2xzX1t0b2tlbl0gfHwgdG9rZW47XG4gICAgICAgICAgICB9XG4gICAgICAgICAgICByZXR1cm4gdG9rZW47XG4gICAgICAgIH07XG4gICAgdmFyIHN5bWJvbCwgcHJlRXJyb3JTeW1ib2wsIHN0YXRlLCBhY3Rpb24sIGEsIHIsIHl5dmFsID0ge30sIHAsIGxlbiwgbmV3U3RhdGUsIGV4cGVjdGVkO1xuICAgIHdoaWxlICh0cnVlKSB7XG4gICAgICAgIHN0YXRlID0gc3RhY2tbc3RhY2subGVuZ3RoIC0gMV07XG4gICAgICAgIGlmICh0aGlzLmRlZmF1bHRBY3Rpb25zW3N0YXRlXSkge1xuICAgICAgICAgICAgYWN0aW9uID0gdGhpcy5kZWZhdWx0QWN0aW9uc1tzdGF0ZV07XG4gICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICBpZiAoc3ltYm9sID09PSBudWxsIHx8IHR5cGVvZiBzeW1ib2wgPT0gJ3VuZGVmaW5lZCcpIHtcbiAgICAgICAgICAgICAgICBzeW1ib2wgPSBsZXgoKTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgICAgIGFjdGlvbiA9IHRhYmxlW3N0YXRlXSAmJiB0YWJsZVtzdGF0ZV1bc3ltYm9sXTtcbiAgICAgICAgfVxuICAgICAgICAgICAgICAgICAgICBpZiAodHlwZW9mIGFjdGlvbiA9PT0gJ3VuZGVmaW5lZCcgfHwgIWFjdGlvbi5sZW5ndGggfHwgIWFjdGlvblswXSkge1xuICAgICAgICAgICAgICAgIHZhciBlcnJTdHIgPSAnJztcbiAgICAgICAgICAgICAgICBleHBlY3RlZCA9IFtdO1xuICAgICAgICAgICAgICAgIGZvciAocCBpbiB0YWJsZVtzdGF0ZV0pIHtcbiAgICAgICAgICAgICAgICAgICAgaWYgKHRoaXMudGVybWluYWxzX1twXSAmJiBwID4gVEVSUk9SKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICBleHBlY3RlZC5wdXNoKCdcXCcnICsgdGhpcy50ZXJtaW5hbHNfW3BdICsgJ1xcJycpO1xuICAgICAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgIGlmIChsZXhlci5zaG93UG9zaXRpb24pIHtcbiAgICAgICAgICAgICAgICAgICAgZXJyU3RyID0gJ1BhcnNlIGVycm9yIG9uIGxpbmUgJyArICh5eWxpbmVubyArIDEpICsgJzpcXG4nICsgbGV4ZXIuc2hvd1Bvc2l0aW9uKCkgKyAnXFxuRXhwZWN0aW5nICcgKyBleHBlY3RlZC5qb2luKCcsICcpICsgJywgZ290IFxcJycgKyAodGhpcy50ZXJtaW5hbHNfW3N5bWJvbF0gfHwgc3ltYm9sKSArICdcXCcnO1xuICAgICAgICAgICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICAgICAgICAgIGVyclN0ciA9ICdQYXJzZSBlcnJvciBvbiBsaW5lICcgKyAoeXlsaW5lbm8gKyAxKSArICc6IFVuZXhwZWN0ZWQgJyArIChzeW1ib2wgPT0gRU9GID8gJ2VuZCBvZiBpbnB1dCcgOiAnXFwnJyArICh0aGlzLnRlcm1pbmFsc19bc3ltYm9sXSB8fCBzeW1ib2wpICsgJ1xcJycpO1xuICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICB0aGlzLnBhcnNlRXJyb3IoZXJyU3RyLCB7XG4gICAgICAgICAgICAgICAgICAgIHRleHQ6IGxleGVyLm1hdGNoLFxuICAgICAgICAgICAgICAgICAgICB0b2tlbjogdGhpcy50ZXJtaW5hbHNfW3N5bWJvbF0gfHwgc3ltYm9sLFxuICAgICAgICAgICAgICAgICAgICBsaW5lOiBsZXhlci55eWxpbmVubyxcbiAgICAgICAgICAgICAgICAgICAgbG9jOiB5eWxvYyxcbiAgICAgICAgICAgICAgICAgICAgZXhwZWN0ZWQ6IGV4cGVjdGVkXG4gICAgICAgICAgICAgICAgfSk7XG4gICAgICAgICAgICB9XG4gICAgICAgIGlmIChhY3Rpb25bMF0gaW5zdGFuY2VvZiBBcnJheSAmJiBhY3Rpb24ubGVuZ3RoID4gMSkge1xuICAgICAgICAgICAgdGhyb3cgbmV3IEVycm9yKCdQYXJzZSBFcnJvcjogbXVsdGlwbGUgYWN0aW9ucyBwb3NzaWJsZSBhdCBzdGF0ZTogJyArIHN0YXRlICsgJywgdG9rZW46ICcgKyBzeW1ib2wpO1xuICAgICAgICB9XG4gICAgICAgIHN3aXRjaCAoYWN0aW9uWzBdKSB7XG4gICAgICAgIGNhc2UgMTpcbiAgICAgICAgICAgIHN0YWNrLnB1c2goc3ltYm9sKTtcbiAgICAgICAgICAgIHZzdGFjay5wdXNoKGxleGVyLnl5dGV4dCk7XG4gICAgICAgICAgICBsc3RhY2sucHVzaChsZXhlci55eWxsb2MpO1xuICAgICAgICAgICAgc3RhY2sucHVzaChhY3Rpb25bMV0pO1xuICAgICAgICAgICAgc3ltYm9sID0gbnVsbDtcbiAgICAgICAgICAgIGlmICghcHJlRXJyb3JTeW1ib2wpIHtcbiAgICAgICAgICAgICAgICB5eWxlbmcgPSBsZXhlci55eWxlbmc7XG4gICAgICAgICAgICAgICAgeXl0ZXh0ID0gbGV4ZXIueXl0ZXh0O1xuICAgICAgICAgICAgICAgIHl5bGluZW5vID0gbGV4ZXIueXlsaW5lbm87XG4gICAgICAgICAgICAgICAgeXlsb2MgPSBsZXhlci55eWxsb2M7XG4gICAgICAgICAgICAgICAgaWYgKHJlY292ZXJpbmcgPiAwKSB7XG4gICAgICAgICAgICAgICAgICAgIHJlY292ZXJpbmctLTtcbiAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgICAgIHN5bWJvbCA9IHByZUVycm9yU3ltYm9sO1xuICAgICAgICAgICAgICAgIHByZUVycm9yU3ltYm9sID0gbnVsbDtcbiAgICAgICAgICAgIH1cbiAgICAgICAgICAgIGJyZWFrO1xuICAgICAgICBjYXNlIDI6XG4gICAgICAgICAgICBsZW4gPSB0aGlzLnByb2R1Y3Rpb25zX1thY3Rpb25bMV1dWzFdO1xuICAgICAgICAgICAgeXl2YWwuJCA9IHZzdGFja1t2c3RhY2subGVuZ3RoIC0gbGVuXTtcbiAgICAgICAgICAgIHl5dmFsLl8kID0ge1xuICAgICAgICAgICAgICAgIGZpcnN0X2xpbmU6IGxzdGFja1tsc3RhY2subGVuZ3RoIC0gKGxlbiB8fCAxKV0uZmlyc3RfbGluZSxcbiAgICAgICAgICAgICAgICBsYXN0X2xpbmU6IGxzdGFja1tsc3RhY2subGVuZ3RoIC0gMV0ubGFzdF9saW5lLFxuICAgICAgICAgICAgICAgIGZpcnN0X2NvbHVtbjogbHN0YWNrW2xzdGFjay5sZW5ndGggLSAobGVuIHx8IDEpXS5maXJzdF9jb2x1bW4sXG4gICAgICAgICAgICAgICAgbGFzdF9jb2x1bW46IGxzdGFja1tsc3RhY2subGVuZ3RoIC0gMV0ubGFzdF9jb2x1bW5cbiAgICAgICAgICAgIH07XG4gICAgICAgICAgICBpZiAocmFuZ2VzKSB7XG4gICAgICAgICAgICAgICAgeXl2YWwuXyQucmFuZ2UgPSBbXG4gICAgICAgICAgICAgICAgICAgIGxzdGFja1tsc3RhY2subGVuZ3RoIC0gKGxlbiB8fCAxKV0ucmFuZ2VbMF0sXG4gICAgICAgICAgICAgICAgICAgIGxzdGFja1tsc3RhY2subGVuZ3RoIC0gMV0ucmFuZ2VbMV1cbiAgICAgICAgICAgICAgICBdO1xuICAgICAgICAgICAgfVxuICAgICAgICAgICAgciA9IHRoaXMucGVyZm9ybUFjdGlvbi5hcHBseSh5eXZhbCwgW1xuICAgICAgICAgICAgICAgIHl5dGV4dCxcbiAgICAgICAgICAgICAgICB5eWxlbmcsXG4gICAgICAgICAgICAgICAgeXlsaW5lbm8sXG4gICAgICAgICAgICAgICAgc2hhcmVkU3RhdGUueXksXG4gICAgICAgICAgICAgICAgYWN0aW9uWzFdLFxuICAgICAgICAgICAgICAgIHZzdGFjayxcbiAgICAgICAgICAgICAgICBsc3RhY2tcbiAgICAgICAgICAgIF0uY29uY2F0KGFyZ3MpKTtcbiAgICAgICAgICAgIGlmICh0eXBlb2YgciAhPT0gJ3VuZGVmaW5lZCcpIHtcbiAgICAgICAgICAgICAgICByZXR1cm4gcjtcbiAgICAgICAgICAgIH1cbiAgICAgICAgICAgIGlmIChsZW4pIHtcbiAgICAgICAgICAgICAgICBzdGFjayA9IHN0YWNrLnNsaWNlKDAsIC0xICogbGVuICogMik7XG4gICAgICAgICAgICAgICAgdnN0YWNrID0gdnN0YWNrLnNsaWNlKDAsIC0xICogbGVuKTtcbiAgICAgICAgICAgICAgICBsc3RhY2sgPSBsc3RhY2suc2xpY2UoMCwgLTEgKiBsZW4pO1xuICAgICAgICAgICAgfVxuICAgICAgICAgICAgc3RhY2sucHVzaCh0aGlzLnByb2R1Y3Rpb25zX1thY3Rpb25bMV1dWzBdKTtcbiAgICAgICAgICAgIHZzdGFjay5wdXNoKHl5dmFsLiQpO1xuICAgICAgICAgICAgbHN0YWNrLnB1c2goeXl2YWwuXyQpO1xuICAgICAgICAgICAgbmV3U3RhdGUgPSB0YWJsZVtzdGFja1tzdGFjay5sZW5ndGggLSAyXV1bc3RhY2tbc3RhY2subGVuZ3RoIC0gMV1dO1xuICAgICAgICAgICAgc3RhY2sucHVzaChuZXdTdGF0ZSk7XG4gICAgICAgICAgICBicmVhaztcbiAgICAgICAgY2FzZSAzOlxuICAgICAgICAgICAgcmV0dXJuIHRydWU7XG4gICAgICAgIH1cbiAgICB9XG4gICAgcmV0dXJuIHRydWU7XG59fTtcblxuICAvKlxuICAgIFNQQVJRTCBwYXJzZXIgaW4gdGhlIEppc29uIHBhcnNlciBnZW5lcmF0b3IgZm9ybWF0LlxuICAqL1xuXG4gIC8vIENvbW1vbiBuYW1lc3BhY2VzIGFuZCBlbnRpdGllc1xuICB2YXIgUkRGID0gJ2h0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMnLFxuICAgICAgUkRGX1RZUEUgID0gUkRGICsgJ3R5cGUnLFxuICAgICAgUkRGX0ZJUlNUID0gUkRGICsgJ2ZpcnN0JyxcbiAgICAgIFJERl9SRVNUICA9IFJERiArICdyZXN0JyxcbiAgICAgIFJERl9OSUwgICA9IFJERiArICduaWwnLFxuICAgICAgWFNEID0gJ2h0dHA6Ly93d3cudzMub3JnLzIwMDEvWE1MU2NoZW1hIycsXG4gICAgICBYU0RfSU5URUdFUiAgPSBYU0QgKyAnaW50ZWdlcicsXG4gICAgICBYU0RfREVDSU1BTCAgPSBYU0QgKyAnZGVjaW1hbCcsXG4gICAgICBYU0RfRE9VQkxFICAgPSBYU0QgKyAnZG91YmxlJyxcbiAgICAgIFhTRF9CT09MRUFOICA9IFhTRCArICdib29sZWFuJyxcbiAgICAgIFhTRF9UUlVFID0gICdcInRydWVcIl5eJyAgKyBYU0RfQk9PTEVBTixcbiAgICAgIFhTRF9GQUxTRSA9ICdcImZhbHNlXCJeXicgKyBYU0RfQk9PTEVBTjtcblxuICB2YXIgYmFzZSA9ICcnLCBiYXNlUGF0aCA9ICcnLCBiYXNlUm9vdCA9ICcnO1xuXG4gIC8vIFJldHVybnMgYSBsb3dlcmNhc2UgdmVyc2lvbiBvZiB0aGUgZ2l2ZW4gc3RyaW5nXG4gIGZ1bmN0aW9uIGxvd2VyY2FzZShzdHJpbmcpIHtcbiAgICByZXR1cm4gc3RyaW5nLnRvTG93ZXJDYXNlKCk7XG4gIH1cblxuICAvLyBBcHBlbmRzIHRoZSBpdGVtIHRvIHRoZSBhcnJheSBhbmQgcmV0dXJucyB0aGUgYXJyYXlcbiAgZnVuY3Rpb24gYXBwZW5kVG8oYXJyYXksIGl0ZW0pIHtcbiAgICByZXR1cm4gYXJyYXkucHVzaChpdGVtKSwgYXJyYXk7XG4gIH1cblxuICAvLyBBcHBlbmRzIHRoZSBpdGVtcyB0byB0aGUgYXJyYXkgYW5kIHJldHVybnMgdGhlIGFycmF5XG4gIGZ1bmN0aW9uIGFwcGVuZEFsbFRvKGFycmF5LCBpdGVtcykge1xuICAgIHJldHVybiBhcnJheS5wdXNoLmFwcGx5KGFycmF5LCBpdGVtcyksIGFycmF5O1xuICB9XG5cbiAgLy8gRXh0ZW5kcyBhIGJhc2Ugb2JqZWN0IHdpdGggcHJvcGVydGllcyBvZiBvdGhlciBvYmplY3RzXG4gIGZ1bmN0aW9uIGV4dGVuZChiYXNlKSB7XG4gICAgaWYgKCFiYXNlKSBiYXNlID0ge307XG4gICAgZm9yICh2YXIgaSA9IDEsIGwgPSBhcmd1bWVudHMubGVuZ3RoLCBhcmc7IGkgPCBsICYmIChhcmcgPSBhcmd1bWVudHNbaV0gfHwge30pOyBpKyspXG4gICAgICBmb3IgKHZhciBuYW1lIGluIGFyZylcbiAgICAgICAgYmFzZVtuYW1lXSA9IGFyZ1tuYW1lXTtcbiAgICByZXR1cm4gYmFzZTtcbiAgfVxuXG4gIC8vIENyZWF0ZXMgYW4gYXJyYXkgdGhhdCBjb250YWlucyBhbGwgaXRlbXMgb2YgdGhlIGdpdmVuIGFycmF5c1xuICBmdW5jdGlvbiB1bmlvbkFsbCgpIHtcbiAgICB2YXIgdW5pb24gPSBbXTtcbiAgICBmb3IgKHZhciBpID0gMCwgbCA9IGFyZ3VtZW50cy5sZW5ndGg7IGkgPCBsOyBpKyspXG4gICAgICB1bmlvbiA9IHVuaW9uLmNvbmNhdC5hcHBseSh1bmlvbiwgYXJndW1lbnRzW2ldKTtcbiAgICByZXR1cm4gdW5pb247XG4gIH1cblxuICAvLyBSZXNvbHZlcyBhbiBJUkkgYWdhaW5zdCBhIGJhc2UgcGF0aFxuICBmdW5jdGlvbiByZXNvbHZlSVJJKGlyaSkge1xuICAgIC8vIFN0cmlwIG9mZiBwb3NzaWJsZSBhbmd1bGFyIGJyYWNrZXRzXG4gICAgaWYgKGlyaVswXSA9PT0gJzwnKVxuICAgICAgaXJpID0gaXJpLnN1YnN0cmluZygxLCBpcmkubGVuZ3RoIC0gMSk7XG4gICAgLy8gUmV0dXJuIGFic29sdXRlIElSSXMgdW5tb2RpZmllZFxuICAgIGlmICgvXlthLXpdKzovLnRlc3QoaXJpKSlcbiAgICAgIHJldHVybiBpcmk7XG4gICAgaWYgKCFQYXJzZXIuYmFzZSlcbiAgICAgIHRocm93IG5ldyBFcnJvcignQ2Fubm90IHJlc29sdmUgcmVsYXRpdmUgSVJJICcgKyBpcmkgKyAnIGJlY2F1c2Ugbm8gYmFzZSBJUkkgd2FzIHNldC4nKTtcbiAgICBpZiAoIWJhc2UpIHtcbiAgICAgIGJhc2UgPSBQYXJzZXIuYmFzZTtcbiAgICAgIGJhc2VQYXRoID0gYmFzZS5yZXBsYWNlKC9bXlxcLzpdKiQvLCAnJyk7XG4gICAgICBiYXNlUm9vdCA9IGJhc2UubWF0Y2goL14oPzpbYS16XSs6XFwvKik/W15cXC9dKi8pWzBdO1xuICAgIH1cbiAgICBzd2l0Y2ggKGlyaVswXSkge1xuICAgIC8vIEFuIGVtcHR5IHJlbGF0aXZlIElSSSBpbmRpY2F0ZXMgdGhlIGJhc2UgSVJJXG4gICAgY2FzZSB1bmRlZmluZWQ6XG4gICAgICByZXR1cm4gYmFzZTtcbiAgICAvLyBSZXNvbHZlIHJlbGF0aXZlIGZyYWdtZW50IElSSXMgYWdhaW5zdCB0aGUgYmFzZSBJUklcbiAgICBjYXNlICcjJzpcbiAgICAgIHJldHVybiBiYXNlICsgaXJpO1xuICAgIC8vIFJlc29sdmUgcmVsYXRpdmUgcXVlcnkgc3RyaW5nIElSSXMgYnkgcmVwbGFjaW5nIHRoZSBxdWVyeSBzdHJpbmdcbiAgICBjYXNlICc/JzpcbiAgICAgIHJldHVybiBiYXNlLnJlcGxhY2UoLyg/OlxcPy4qKT8kLywgaXJpKTtcbiAgICAvLyBSZXNvbHZlIHJvb3QgcmVsYXRpdmUgSVJJcyBhdCB0aGUgcm9vdCBvZiB0aGUgYmFzZSBJUklcbiAgICBjYXNlICcvJzpcbiAgICAgIHJldHVybiBiYXNlUm9vdCArIGlyaTtcbiAgICAvLyBSZXNvbHZlIGFsbCBvdGhlciBJUklzIGF0IHRoZSBiYXNlIElSSSdzIHBhdGhcbiAgICBkZWZhdWx0OlxuICAgICAgcmV0dXJuIGJhc2VQYXRoICsgaXJpO1xuICAgIH1cbiAgfVxuXG4gIC8vIElmIHRoZSBpdGVtIGlzIGEgdmFyaWFibGUsIGVuc3VyZXMgaXQgc3RhcnRzIHdpdGggYSBxdWVzdGlvbiBtYXJrXG4gIGZ1bmN0aW9uIHRvVmFyKHZhcmlhYmxlKSB7XG4gICAgaWYgKHZhcmlhYmxlKSB7XG4gICAgICB2YXIgZmlyc3QgPSB2YXJpYWJsZVswXTtcbiAgICAgIGlmIChmaXJzdCA9PT0gJz8nKSByZXR1cm4gdmFyaWFibGU7XG4gICAgICBpZiAoZmlyc3QgPT09ICckJykgcmV0dXJuICc/JyArIHZhcmlhYmxlLnN1YnN0cigxKTtcbiAgICB9XG4gICAgcmV0dXJuIHZhcmlhYmxlO1xuICB9XG5cbiAgLy8gQ3JlYXRlcyBhbiBvcGVyYXRpb24gd2l0aCB0aGUgZ2l2ZW4gbmFtZSBhbmQgYXJndW1lbnRzXG4gIGZ1bmN0aW9uIG9wZXJhdGlvbihvcGVyYXRvck5hbWUsIGFyZ3MpIHtcbiAgICByZXR1cm4geyB0eXBlOiAnb3BlcmF0aW9uJywgb3BlcmF0b3I6IG9wZXJhdG9yTmFtZSwgYXJnczogYXJncyB8fCBbXSB9O1xuICB9XG5cbiAgLy8gQ3JlYXRlcyBhbiBleHByZXNzaW9uIHdpdGggdGhlIGdpdmVuIHR5cGUgYW5kIGF0dHJpYnV0ZXNcbiAgZnVuY3Rpb24gZXhwcmVzc2lvbihleHByLCBhdHRyKSB7XG4gICAgdmFyIGV4cHJlc3Npb24gPSB7IGV4cHJlc3Npb246IGV4cHIgfTtcbiAgICBpZiAoYXR0cilcbiAgICAgIGZvciAodmFyIGEgaW4gYXR0cilcbiAgICAgICAgZXhwcmVzc2lvblthXSA9IGF0dHJbYV07XG4gICAgcmV0dXJuIGV4cHJlc3Npb247XG4gIH1cblxuICAvLyBDcmVhdGVzIGEgcGF0aCB3aXRoIHRoZSBnaXZlbiB0eXBlIGFuZCBpdGVtc1xuICBmdW5jdGlvbiBwYXRoKHR5cGUsIGl0ZW1zKSB7XG4gICAgcmV0dXJuIHsgdHlwZTogJ3BhdGgnLCBwYXRoVHlwZTogdHlwZSwgaXRlbXM6IGl0ZW1zIH07XG4gIH1cblxuICAvLyBUcmFuc2Zvcm1zIGEgbGlzdCBvZiBvcGVyYXRpb25zIHR5cGVzIGFuZCBhcmd1bWVudHMgaW50byBhIHRyZWUgb2Ygb3BlcmF0aW9uc1xuICBmdW5jdGlvbiBjcmVhdGVPcGVyYXRpb25UcmVlKGluaXRpYWxFeHByZXNzaW9uLCBvcGVyYXRpb25MaXN0KSB7XG4gICAgZm9yICh2YXIgaSA9IDAsIGwgPSBvcGVyYXRpb25MaXN0Lmxlbmd0aCwgaXRlbTsgaSA8IGwgJiYgKGl0ZW0gPSBvcGVyYXRpb25MaXN0W2ldKTsgaSsrKVxuICAgICAgaW5pdGlhbEV4cHJlc3Npb24gPSBvcGVyYXRpb24oaXRlbVswXSwgW2luaXRpYWxFeHByZXNzaW9uLCBpdGVtWzFdXSk7XG4gICAgcmV0dXJuIGluaXRpYWxFeHByZXNzaW9uO1xuICB9XG5cbiAgLy8gR3JvdXAgZGF0YXNldHMgYnkgZGVmYXVsdCBhbmQgbmFtZWRcbiAgZnVuY3Rpb24gZ3JvdXBEYXRhc2V0cyhmcm9tQ2xhdXNlcykge1xuICAgIHZhciBkZWZhdWx0cyA9IFtdLCBuYW1lZCA9IFtdLCBsID0gZnJvbUNsYXVzZXMubGVuZ3RoLCBmcm9tQ2xhdXNlO1xuICAgIGZvciAodmFyIGkgPSAwOyBpIDwgbCAmJiAoZnJvbUNsYXVzZSA9IGZyb21DbGF1c2VzW2ldKTsgaSsrKVxuICAgICAgKGZyb21DbGF1c2UubmFtZWQgPyBuYW1lZCA6IGRlZmF1bHRzKS5wdXNoKGZyb21DbGF1c2UuaXJpKTtcbiAgICByZXR1cm4gbCA/IHsgZnJvbTogeyBkZWZhdWx0OiBkZWZhdWx0cywgbmFtZWQ6IG5hbWVkIH0gfSA6IG51bGw7XG4gIH1cblxuICAvLyBDb252ZXJ0cyB0aGUgbnVtYmVyIHRvIGEgc3RyaW5nXG4gIGZ1bmN0aW9uIHRvSW50KHN0cmluZykge1xuICAgIHJldHVybiBwYXJzZUludChzdHJpbmcsIDEwKTtcbiAgfVxuXG4gIC8vIFRyYW5zZm9ybXMgYSBwb3NzaWJseSBzaW5nbGUgZ3JvdXAgaW50byBpdHMgcGF0dGVybnNcbiAgZnVuY3Rpb24gZGVncm91cFNpbmdsZShncm91cCkge1xuICAgIHJldHVybiBncm91cC50eXBlID09PSAnZ3JvdXAnICYmIGdyb3VwLnBhdHRlcm5zLmxlbmd0aCA9PT0gMSA/IGdyb3VwLnBhdHRlcm5zWzBdIDogZ3JvdXA7XG4gIH1cblxuICAvLyBDcmVhdGVzIGEgbGl0ZXJhbCB3aXRoIHRoZSBnaXZlbiB2YWx1ZSBhbmQgdHlwZVxuICBmdW5jdGlvbiBjcmVhdGVMaXRlcmFsKHZhbHVlLCB0eXBlKSB7XG4gICAgcmV0dXJuICdcIicgKyB2YWx1ZSArICdcIl5eJyArIHR5cGU7XG4gIH1cblxuICAvLyBDcmVhdGVzIGEgdHJpcGxlIHdpdGggdGhlIGdpdmVuIHN1YmplY3QsIHByZWRpY2F0ZSwgYW5kIG9iamVjdFxuICBmdW5jdGlvbiB0cmlwbGUoc3ViamVjdCwgcHJlZGljYXRlLCBvYmplY3QpIHtcbiAgICB2YXIgdHJpcGxlID0ge307XG4gICAgaWYgKHN1YmplY3QgICAhPSBudWxsKSB0cmlwbGUuc3ViamVjdCAgID0gc3ViamVjdDtcbiAgICBpZiAocHJlZGljYXRlICE9IG51bGwpIHRyaXBsZS5wcmVkaWNhdGUgPSBwcmVkaWNhdGU7XG4gICAgaWYgKG9iamVjdCAgICAhPSBudWxsKSB0cmlwbGUub2JqZWN0ICAgID0gb2JqZWN0O1xuICAgIHJldHVybiB0cmlwbGU7XG4gIH1cblxuICAvLyBDcmVhdGVzIGEgbmV3IGJsYW5rIG5vZGUgaWRlbnRpZmllclxuICBmdW5jdGlvbiBibGFuaygpIHtcbiAgICByZXR1cm4gJ186YicgKyBibGFua0lkKys7XG4gIH07XG4gIHZhciBibGFua0lkID0gMDtcbiAgUGFyc2VyLl9yZXNldEJsYW5rcyA9IGZ1bmN0aW9uICgpIHsgYmxhbmtJZCA9IDA7IH1cblxuICAvLyBSZWd1bGFyIGV4cHJlc3Npb24gYW5kIHJlcGxhY2VtZW50IHN0cmluZ3MgdG8gZXNjYXBlIHN0cmluZ3NcbiAgdmFyIGVzY2FwZVNlcXVlbmNlID0gL1xcXFx1KFthLWZBLUYwLTldezR9KXxcXFxcVShbYS1mQS1GMC05XXs4fSl8XFxcXCguKS9nLFxuICAgICAgZXNjYXBlUmVwbGFjZW1lbnRzID0geyAnXFxcXCc6ICdcXFxcJywgXCInXCI6IFwiJ1wiLCAnXCInOiAnXCInLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAndCc6ICdcXHQnLCAnYic6ICdcXGInLCAnbic6ICdcXG4nLCAncic6ICdcXHInLCAnZic6ICdcXGYnIH0sXG4gICAgICBmcm9tQ2hhckNvZGUgPSBTdHJpbmcuZnJvbUNoYXJDb2RlO1xuXG4gIC8vIFRyYW5zbGF0ZXMgZXNjYXBlIGNvZGVzIGluIHRoZSBzdHJpbmcgaW50byB0aGVpciB0ZXh0dWFsIGVxdWl2YWxlbnRcbiAgZnVuY3Rpb24gdW5lc2NhcGVTdHJpbmcoc3RyaW5nLCB0cmltTGVuZ3RoKSB7XG4gICAgc3RyaW5nID0gc3RyaW5nLnN1YnN0cmluZyh0cmltTGVuZ3RoLCBzdHJpbmcubGVuZ3RoIC0gdHJpbUxlbmd0aCk7XG4gICAgdHJ5IHtcbiAgICAgIHN0cmluZyA9IHN0cmluZy5yZXBsYWNlKGVzY2FwZVNlcXVlbmNlLCBmdW5jdGlvbiAoc2VxdWVuY2UsIHVuaWNvZGU0LCB1bmljb2RlOCwgZXNjYXBlZENoYXIpIHtcbiAgICAgICAgdmFyIGNoYXJDb2RlO1xuICAgICAgICBpZiAodW5pY29kZTQpIHtcbiAgICAgICAgICBjaGFyQ29kZSA9IHBhcnNlSW50KHVuaWNvZGU0LCAxNik7XG4gICAgICAgICAgaWYgKGlzTmFOKGNoYXJDb2RlKSkgdGhyb3cgbmV3IEVycm9yKCk7IC8vIGNhbiBuZXZlciBoYXBwZW4gKHJlZ2V4KSwgYnV0IGhlbHBzIHBlcmZvcm1hbmNlXG4gICAgICAgICAgcmV0dXJuIGZyb21DaGFyQ29kZShjaGFyQ29kZSk7XG4gICAgICAgIH1cbiAgICAgICAgZWxzZSBpZiAodW5pY29kZTgpIHtcbiAgICAgICAgICBjaGFyQ29kZSA9IHBhcnNlSW50KHVuaWNvZGU4LCAxNik7XG4gICAgICAgICAgaWYgKGlzTmFOKGNoYXJDb2RlKSkgdGhyb3cgbmV3IEVycm9yKCk7IC8vIGNhbiBuZXZlciBoYXBwZW4gKHJlZ2V4KSwgYnV0IGhlbHBzIHBlcmZvcm1hbmNlXG4gICAgICAgICAgaWYgKGNoYXJDb2RlIDwgMHhGRkZGKSByZXR1cm4gZnJvbUNoYXJDb2RlKGNoYXJDb2RlKTtcbiAgICAgICAgICByZXR1cm4gZnJvbUNoYXJDb2RlKDB4RDgwMCArICgoY2hhckNvZGUgLT0gMHgxMDAwMCkgPj4gMTApLCAweERDMDAgKyAoY2hhckNvZGUgJiAweDNGRikpO1xuICAgICAgICB9XG4gICAgICAgIGVsc2Uge1xuICAgICAgICAgIHZhciByZXBsYWNlbWVudCA9IGVzY2FwZVJlcGxhY2VtZW50c1tlc2NhcGVkQ2hhcl07XG4gICAgICAgICAgaWYgKCFyZXBsYWNlbWVudCkgdGhyb3cgbmV3IEVycm9yKCk7XG4gICAgICAgICAgcmV0dXJuIHJlcGxhY2VtZW50O1xuICAgICAgICB9XG4gICAgICB9KTtcbiAgICB9XG4gICAgY2F0Y2ggKGVycm9yKSB7IHJldHVybiAnJzsgfVxuICAgIHJldHVybiAnXCInICsgc3RyaW5nICsgJ1wiJztcbiAgfVxuXG4gIC8vIENyZWF0ZXMgYSBsaXN0LCBjb2xsZWN0aW5nIGl0cyAocG9zc2libHkgYmxhbmspIGl0ZW1zIGFuZCB0cmlwbGVzIGFzc29jaWF0ZWQgd2l0aCB0aG9zZSBpdGVtc1xuICBmdW5jdGlvbiBjcmVhdGVMaXN0KG9iamVjdHMpIHtcbiAgICB2YXIgbGlzdCA9IGJsYW5rKCksIGhlYWQgPSBsaXN0LCBsaXN0SXRlbXMgPSBbXSwgbGlzdFRyaXBsZXMsIHRyaXBsZXMgPSBbXTtcbiAgICBvYmplY3RzLmZvckVhY2goZnVuY3Rpb24gKG8pIHsgbGlzdEl0ZW1zLnB1c2goby5lbnRpdHkpOyBhcHBlbmRBbGxUbyh0cmlwbGVzLCBvLnRyaXBsZXMpOyB9KTtcblxuICAgIC8vIEJ1aWxkIGFuIFJERiBsaXN0IG91dCBvZiB0aGUgaXRlbXNcbiAgICBmb3IgKHZhciBpID0gMCwgaiA9IDAsIGwgPSBsaXN0SXRlbXMubGVuZ3RoLCBsaXN0VHJpcGxlcyA9IEFycmF5KGwgKiAyKTsgaSA8IGw7KVxuICAgICAgbGlzdFRyaXBsZXNbaisrXSA9IHRyaXBsZShoZWFkLCBSREZfRklSU1QsIGxpc3RJdGVtc1tpXSksXG4gICAgICBsaXN0VHJpcGxlc1tqKytdID0gdHJpcGxlKGhlYWQsIFJERl9SRVNULCAgaGVhZCA9ICsraSA8IGwgPyBibGFuaygpIDogUkRGX05JTCk7XG5cbiAgICAvLyBSZXR1cm4gdGhlIGxpc3QncyBpZGVudGlmaWVyLCBpdHMgdHJpcGxlcywgYW5kIHRoZSB0cmlwbGVzIGFzc29jaWF0ZWQgd2l0aCBpdHMgaXRlbXNcbiAgICByZXR1cm4geyBlbnRpdHk6IGxpc3QsIHRyaXBsZXM6IGFwcGVuZEFsbFRvKGxpc3RUcmlwbGVzLCB0cmlwbGVzKSB9O1xuICB9XG5cbiAgLy8gQ3JlYXRlcyBhIGJsYW5rIG5vZGUgaWRlbnRpZmllciwgY29sbGVjdGluZyB0cmlwbGVzIHdpdGggdGhhdCBibGFuayBub2RlIGFzIHN1YmplY3RcbiAgZnVuY3Rpb24gY3JlYXRlQW5vbnltb3VzT2JqZWN0KHByb3BlcnR5TGlzdCkge1xuICAgIHZhciBlbnRpdHkgPSBibGFuaygpO1xuICAgIHJldHVybiB7XG4gICAgICBlbnRpdHk6IGVudGl0eSxcbiAgICAgIHRyaXBsZXM6IHByb3BlcnR5TGlzdC5tYXAoZnVuY3Rpb24gKHQpIHsgcmV0dXJuIGV4dGVuZCh0cmlwbGUoZW50aXR5KSwgdCk7IH0pXG4gICAgfTtcbiAgfVxuXG4gIC8vIENvbGxlY3RzIGFsbCAocG9zc2libHkgYmxhbmspIG9iamVjdHMsIGFuZCB0cmlwbGVzIHRoYXQgaGF2ZSB0aGVtIGFzIHN1YmplY3RcbiAgZnVuY3Rpb24gb2JqZWN0TGlzdFRvVHJpcGxlcyhwcmVkaWNhdGUsIG9iamVjdExpc3QsIG90aGVyVHJpcGxlcykge1xuICAgIHZhciBvYmplY3RzID0gW10sIHRyaXBsZXMgPSBbXTtcbiAgICBvYmplY3RMaXN0LmZvckVhY2goZnVuY3Rpb24gKGwpIHtcbiAgICAgIG9iamVjdHMucHVzaCh0cmlwbGUobnVsbCwgcHJlZGljYXRlLCBsLmVudGl0eSkpO1xuICAgICAgYXBwZW5kQWxsVG8odHJpcGxlcywgbC50cmlwbGVzKTtcbiAgICB9KTtcbiAgICByZXR1cm4gdW5pb25BbGwob2JqZWN0cywgb3RoZXJUcmlwbGVzIHx8IFtdLCB0cmlwbGVzKTtcbiAgfVxuXG4gIC8vIFNpbXBsaWZpZXMgZ3JvdXBzIGJ5IG1lcmdpbmcgYWRqYWNlbnQgQkdQc1xuICBmdW5jdGlvbiBtZXJnZUFkamFjZW50QkdQcyhncm91cHMpIHtcbiAgICB2YXIgbWVyZ2VkID0gW10sIGN1cnJlbnRCZ3A7XG4gICAgZm9yICh2YXIgaSA9IDAsIGdyb3VwOyBncm91cCA9IGdyb3Vwc1tpXTsgaSsrKSB7XG4gICAgICBzd2l0Y2ggKGdyb3VwLnR5cGUpIHtcbiAgICAgICAgLy8gQWRkIGEgQkdQJ3MgdHJpcGxlcyB0byB0aGUgY3VycmVudCBCR1BcbiAgICAgICAgY2FzZSAnYmdwJzpcbiAgICAgICAgICBpZiAoZ3JvdXAudHJpcGxlcy5sZW5ndGgpIHtcbiAgICAgICAgICAgIGlmICghY3VycmVudEJncClcbiAgICAgICAgICAgICAgYXBwZW5kVG8obWVyZ2VkLCBjdXJyZW50QmdwID0gZ3JvdXApO1xuICAgICAgICAgICAgZWxzZVxuICAgICAgICAgICAgICBhcHBlbmRBbGxUbyhjdXJyZW50QmdwLnRyaXBsZXMsIGdyb3VwLnRyaXBsZXMpO1xuICAgICAgICAgIH1cbiAgICAgICAgICBicmVhaztcbiAgICAgICAgLy8gQWxsIG90aGVyIGdyb3VwcyBicmVhayB1cCBhIEJHUFxuICAgICAgICBkZWZhdWx0OlxuICAgICAgICAgIC8vIE9ubHkgYWRkIHRoZSBncm91cCBpZiBpdHMgcGF0dGVybiBpcyBub24tZW1wdHlcbiAgICAgICAgICBpZiAoIWdyb3VwLnBhdHRlcm5zIHx8IGdyb3VwLnBhdHRlcm5zLmxlbmd0aCA+IDApIHtcbiAgICAgICAgICAgIGFwcGVuZFRvKG1lcmdlZCwgZ3JvdXApO1xuICAgICAgICAgICAgY3VycmVudEJncCA9IG51bGw7XG4gICAgICAgICAgfVxuICAgICAgfVxuICAgIH1cbiAgICByZXR1cm4gbWVyZ2VkO1xuICB9XG4vKiBnZW5lcmF0ZWQgYnkgamlzb24tbGV4IDAuMy40ICovXG52YXIgbGV4ZXIgPSAoZnVuY3Rpb24oKXtcbnZhciBsZXhlciA9ICh7XG5cbkVPRjoxLFxuXG5wYXJzZUVycm9yOmZ1bmN0aW9uIHBhcnNlRXJyb3Ioc3RyLCBoYXNoKSB7XG4gICAgICAgIGlmICh0aGlzLnl5LnBhcnNlcikge1xuICAgICAgICAgICAgdGhpcy55eS5wYXJzZXIucGFyc2VFcnJvcihzdHIsIGhhc2gpO1xuICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgdGhyb3cgbmV3IEVycm9yKHN0cik7XG4gICAgICAgIH1cbiAgICB9LFxuXG4vLyByZXNldHMgdGhlIGxleGVyLCBzZXRzIG5ldyBpbnB1dFxuc2V0SW5wdXQ6ZnVuY3Rpb24gKGlucHV0LCB5eSkge1xuICAgICAgICB0aGlzLnl5ID0geXkgfHwgdGhpcy55eSB8fCB7fTtcbiAgICAgICAgdGhpcy5faW5wdXQgPSBpbnB1dDtcbiAgICAgICAgdGhpcy5fbW9yZSA9IHRoaXMuX2JhY2t0cmFjayA9IHRoaXMuZG9uZSA9IGZhbHNlO1xuICAgICAgICB0aGlzLnl5bGluZW5vID0gdGhpcy55eWxlbmcgPSAwO1xuICAgICAgICB0aGlzLnl5dGV4dCA9IHRoaXMubWF0Y2hlZCA9IHRoaXMubWF0Y2ggPSAnJztcbiAgICAgICAgdGhpcy5jb25kaXRpb25TdGFjayA9IFsnSU5JVElBTCddO1xuICAgICAgICB0aGlzLnl5bGxvYyA9IHtcbiAgICAgICAgICAgIGZpcnN0X2xpbmU6IDEsXG4gICAgICAgICAgICBmaXJzdF9jb2x1bW46IDAsXG4gICAgICAgICAgICBsYXN0X2xpbmU6IDEsXG4gICAgICAgICAgICBsYXN0X2NvbHVtbjogMFxuICAgICAgICB9O1xuICAgICAgICBpZiAodGhpcy5vcHRpb25zLnJhbmdlcykge1xuICAgICAgICAgICAgdGhpcy55eWxsb2MucmFuZ2UgPSBbMCwwXTtcbiAgICAgICAgfVxuICAgICAgICB0aGlzLm9mZnNldCA9IDA7XG4gICAgICAgIHJldHVybiB0aGlzO1xuICAgIH0sXG5cbi8vIGNvbnN1bWVzIGFuZCByZXR1cm5zIG9uZSBjaGFyIGZyb20gdGhlIGlucHV0XG5pbnB1dDpmdW5jdGlvbiAoKSB7XG4gICAgICAgIHZhciBjaCA9IHRoaXMuX2lucHV0WzBdO1xuICAgICAgICB0aGlzLnl5dGV4dCArPSBjaDtcbiAgICAgICAgdGhpcy55eWxlbmcrKztcbiAgICAgICAgdGhpcy5vZmZzZXQrKztcbiAgICAgICAgdGhpcy5tYXRjaCArPSBjaDtcbiAgICAgICAgdGhpcy5tYXRjaGVkICs9IGNoO1xuICAgICAgICB2YXIgbGluZXMgPSBjaC5tYXRjaCgvKD86XFxyXFxuP3xcXG4pLiovZyk7XG4gICAgICAgIGlmIChsaW5lcykge1xuICAgICAgICAgICAgdGhpcy55eWxpbmVubysrO1xuICAgICAgICAgICAgdGhpcy55eWxsb2MubGFzdF9saW5lKys7XG4gICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICB0aGlzLnl5bGxvYy5sYXN0X2NvbHVtbisrO1xuICAgICAgICB9XG4gICAgICAgIGlmICh0aGlzLm9wdGlvbnMucmFuZ2VzKSB7XG4gICAgICAgICAgICB0aGlzLnl5bGxvYy5yYW5nZVsxXSsrO1xuICAgICAgICB9XG5cbiAgICAgICAgdGhpcy5faW5wdXQgPSB0aGlzLl9pbnB1dC5zbGljZSgxKTtcbiAgICAgICAgcmV0dXJuIGNoO1xuICAgIH0sXG5cbi8vIHVuc2hpZnRzIG9uZSBjaGFyIChvciBhIHN0cmluZykgaW50byB0aGUgaW5wdXRcbnVucHV0OmZ1bmN0aW9uIChjaCkge1xuICAgICAgICB2YXIgbGVuID0gY2gubGVuZ3RoO1xuICAgICAgICB2YXIgbGluZXMgPSBjaC5zcGxpdCgvKD86XFxyXFxuP3xcXG4pL2cpO1xuXG4gICAgICAgIHRoaXMuX2lucHV0ID0gY2ggKyB0aGlzLl9pbnB1dDtcbiAgICAgICAgdGhpcy55eXRleHQgPSB0aGlzLnl5dGV4dC5zdWJzdHIoMCwgdGhpcy55eXRleHQubGVuZ3RoIC0gbGVuKTtcbiAgICAgICAgLy90aGlzLnl5bGVuZyAtPSBsZW47XG4gICAgICAgIHRoaXMub2Zmc2V0IC09IGxlbjtcbiAgICAgICAgdmFyIG9sZExpbmVzID0gdGhpcy5tYXRjaC5zcGxpdCgvKD86XFxyXFxuP3xcXG4pL2cpO1xuICAgICAgICB0aGlzLm1hdGNoID0gdGhpcy5tYXRjaC5zdWJzdHIoMCwgdGhpcy5tYXRjaC5sZW5ndGggLSAxKTtcbiAgICAgICAgdGhpcy5tYXRjaGVkID0gdGhpcy5tYXRjaGVkLnN1YnN0cigwLCB0aGlzLm1hdGNoZWQubGVuZ3RoIC0gMSk7XG5cbiAgICAgICAgaWYgKGxpbmVzLmxlbmd0aCAtIDEpIHtcbiAgICAgICAgICAgIHRoaXMueXlsaW5lbm8gLT0gbGluZXMubGVuZ3RoIC0gMTtcbiAgICAgICAgfVxuICAgICAgICB2YXIgciA9IHRoaXMueXlsbG9jLnJhbmdlO1xuXG4gICAgICAgIHRoaXMueXlsbG9jID0ge1xuICAgICAgICAgICAgZmlyc3RfbGluZTogdGhpcy55eWxsb2MuZmlyc3RfbGluZSxcbiAgICAgICAgICAgIGxhc3RfbGluZTogdGhpcy55eWxpbmVubyArIDEsXG4gICAgICAgICAgICBmaXJzdF9jb2x1bW46IHRoaXMueXlsbG9jLmZpcnN0X2NvbHVtbixcbiAgICAgICAgICAgIGxhc3RfY29sdW1uOiBsaW5lcyA/XG4gICAgICAgICAgICAgICAgKGxpbmVzLmxlbmd0aCA9PT0gb2xkTGluZXMubGVuZ3RoID8gdGhpcy55eWxsb2MuZmlyc3RfY29sdW1uIDogMClcbiAgICAgICAgICAgICAgICAgKyBvbGRMaW5lc1tvbGRMaW5lcy5sZW5ndGggLSBsaW5lcy5sZW5ndGhdLmxlbmd0aCAtIGxpbmVzWzBdLmxlbmd0aCA6XG4gICAgICAgICAgICAgIHRoaXMueXlsbG9jLmZpcnN0X2NvbHVtbiAtIGxlblxuICAgICAgICB9O1xuXG4gICAgICAgIGlmICh0aGlzLm9wdGlvbnMucmFuZ2VzKSB7XG4gICAgICAgICAgICB0aGlzLnl5bGxvYy5yYW5nZSA9IFtyWzBdLCByWzBdICsgdGhpcy55eWxlbmcgLSBsZW5dO1xuICAgICAgICB9XG4gICAgICAgIHRoaXMueXlsZW5nID0gdGhpcy55eXRleHQubGVuZ3RoO1xuICAgICAgICByZXR1cm4gdGhpcztcbiAgICB9LFxuXG4vLyBXaGVuIGNhbGxlZCBmcm9tIGFjdGlvbiwgY2FjaGVzIG1hdGNoZWQgdGV4dCBhbmQgYXBwZW5kcyBpdCBvbiBuZXh0IGFjdGlvblxubW9yZTpmdW5jdGlvbiAoKSB7XG4gICAgICAgIHRoaXMuX21vcmUgPSB0cnVlO1xuICAgICAgICByZXR1cm4gdGhpcztcbiAgICB9LFxuXG4vLyBXaGVuIGNhbGxlZCBmcm9tIGFjdGlvbiwgc2lnbmFscyB0aGUgbGV4ZXIgdGhhdCB0aGlzIHJ1bGUgZmFpbHMgdG8gbWF0Y2ggdGhlIGlucHV0LCBzbyB0aGUgbmV4dCBtYXRjaGluZyBydWxlIChyZWdleCkgc2hvdWxkIGJlIHRlc3RlZCBpbnN0ZWFkLlxucmVqZWN0OmZ1bmN0aW9uICgpIHtcbiAgICAgICAgaWYgKHRoaXMub3B0aW9ucy5iYWNrdHJhY2tfbGV4ZXIpIHtcbiAgICAgICAgICAgIHRoaXMuX2JhY2t0cmFjayA9IHRydWU7XG4gICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICByZXR1cm4gdGhpcy5wYXJzZUVycm9yKCdMZXhpY2FsIGVycm9yIG9uIGxpbmUgJyArICh0aGlzLnl5bGluZW5vICsgMSkgKyAnLiBZb3UgY2FuIG9ubHkgaW52b2tlIHJlamVjdCgpIGluIHRoZSBsZXhlciB3aGVuIHRoZSBsZXhlciBpcyBvZiB0aGUgYmFja3RyYWNraW5nIHBlcnN1YXNpb24gKG9wdGlvbnMuYmFja3RyYWNrX2xleGVyID0gdHJ1ZSkuXFxuJyArIHRoaXMuc2hvd1Bvc2l0aW9uKCksIHtcbiAgICAgICAgICAgICAgICB0ZXh0OiBcIlwiLFxuICAgICAgICAgICAgICAgIHRva2VuOiBudWxsLFxuICAgICAgICAgICAgICAgIGxpbmU6IHRoaXMueXlsaW5lbm9cbiAgICAgICAgICAgIH0pO1xuXG4gICAgICAgIH1cbiAgICAgICAgcmV0dXJuIHRoaXM7XG4gICAgfSxcblxuLy8gcmV0YWluIGZpcnN0IG4gY2hhcmFjdGVycyBvZiB0aGUgbWF0Y2hcbmxlc3M6ZnVuY3Rpb24gKG4pIHtcbiAgICAgICAgdGhpcy51bnB1dCh0aGlzLm1hdGNoLnNsaWNlKG4pKTtcbiAgICB9LFxuXG4vLyBkaXNwbGF5cyBhbHJlYWR5IG1hdGNoZWQgaW5wdXQsIGkuZS4gZm9yIGVycm9yIG1lc3NhZ2VzXG5wYXN0SW5wdXQ6ZnVuY3Rpb24gKCkge1xuICAgICAgICB2YXIgcGFzdCA9IHRoaXMubWF0Y2hlZC5zdWJzdHIoMCwgdGhpcy5tYXRjaGVkLmxlbmd0aCAtIHRoaXMubWF0Y2gubGVuZ3RoKTtcbiAgICAgICAgcmV0dXJuIChwYXN0Lmxlbmd0aCA+IDIwID8gJy4uLic6JycpICsgcGFzdC5zdWJzdHIoLTIwKS5yZXBsYWNlKC9cXG4vZywgXCJcIik7XG4gICAgfSxcblxuLy8gZGlzcGxheXMgdXBjb21pbmcgaW5wdXQsIGkuZS4gZm9yIGVycm9yIG1lc3NhZ2VzXG51cGNvbWluZ0lucHV0OmZ1bmN0aW9uICgpIHtcbiAgICAgICAgdmFyIG5leHQgPSB0aGlzLm1hdGNoO1xuICAgICAgICBpZiAobmV4dC5sZW5ndGggPCAyMCkge1xuICAgICAgICAgICAgbmV4dCArPSB0aGlzLl9pbnB1dC5zdWJzdHIoMCwgMjAtbmV4dC5sZW5ndGgpO1xuICAgICAgICB9XG4gICAgICAgIHJldHVybiAobmV4dC5zdWJzdHIoMCwyMCkgKyAobmV4dC5sZW5ndGggPiAyMCA/ICcuLi4nIDogJycpKS5yZXBsYWNlKC9cXG4vZywgXCJcIik7XG4gICAgfSxcblxuLy8gZGlzcGxheXMgdGhlIGNoYXJhY3RlciBwb3NpdGlvbiB3aGVyZSB0aGUgbGV4aW5nIGVycm9yIG9jY3VycmVkLCBpLmUuIGZvciBlcnJvciBtZXNzYWdlc1xuc2hvd1Bvc2l0aW9uOmZ1bmN0aW9uICgpIHtcbiAgICAgICAgdmFyIHByZSA9IHRoaXMucGFzdElucHV0KCk7XG4gICAgICAgIHZhciBjID0gbmV3IEFycmF5KHByZS5sZW5ndGggKyAxKS5qb2luKFwiLVwiKTtcbiAgICAgICAgcmV0dXJuIHByZSArIHRoaXMudXBjb21pbmdJbnB1dCgpICsgXCJcXG5cIiArIGMgKyBcIl5cIjtcbiAgICB9LFxuXG4vLyB0ZXN0IHRoZSBsZXhlZCB0b2tlbjogcmV0dXJuIEZBTFNFIHdoZW4gbm90IGEgbWF0Y2gsIG90aGVyd2lzZSByZXR1cm4gdG9rZW5cbnRlc3RfbWF0Y2g6ZnVuY3Rpb24obWF0Y2gsIGluZGV4ZWRfcnVsZSkge1xuICAgICAgICB2YXIgdG9rZW4sXG4gICAgICAgICAgICBsaW5lcyxcbiAgICAgICAgICAgIGJhY2t1cDtcblxuICAgICAgICBpZiAodGhpcy5vcHRpb25zLmJhY2t0cmFja19sZXhlcikge1xuICAgICAgICAgICAgLy8gc2F2ZSBjb250ZXh0XG4gICAgICAgICAgICBiYWNrdXAgPSB7XG4gICAgICAgICAgICAgICAgeXlsaW5lbm86IHRoaXMueXlsaW5lbm8sXG4gICAgICAgICAgICAgICAgeXlsbG9jOiB7XG4gICAgICAgICAgICAgICAgICAgIGZpcnN0X2xpbmU6IHRoaXMueXlsbG9jLmZpcnN0X2xpbmUsXG4gICAgICAgICAgICAgICAgICAgIGxhc3RfbGluZTogdGhpcy5sYXN0X2xpbmUsXG4gICAgICAgICAgICAgICAgICAgIGZpcnN0X2NvbHVtbjogdGhpcy55eWxsb2MuZmlyc3RfY29sdW1uLFxuICAgICAgICAgICAgICAgICAgICBsYXN0X2NvbHVtbjogdGhpcy55eWxsb2MubGFzdF9jb2x1bW5cbiAgICAgICAgICAgICAgICB9LFxuICAgICAgICAgICAgICAgIHl5dGV4dDogdGhpcy55eXRleHQsXG4gICAgICAgICAgICAgICAgbWF0Y2g6IHRoaXMubWF0Y2gsXG4gICAgICAgICAgICAgICAgbWF0Y2hlczogdGhpcy5tYXRjaGVzLFxuICAgICAgICAgICAgICAgIG1hdGNoZWQ6IHRoaXMubWF0Y2hlZCxcbiAgICAgICAgICAgICAgICB5eWxlbmc6IHRoaXMueXlsZW5nLFxuICAgICAgICAgICAgICAgIG9mZnNldDogdGhpcy5vZmZzZXQsXG4gICAgICAgICAgICAgICAgX21vcmU6IHRoaXMuX21vcmUsXG4gICAgICAgICAgICAgICAgX2lucHV0OiB0aGlzLl9pbnB1dCxcbiAgICAgICAgICAgICAgICB5eTogdGhpcy55eSxcbiAgICAgICAgICAgICAgICBjb25kaXRpb25TdGFjazogdGhpcy5jb25kaXRpb25TdGFjay5zbGljZSgwKSxcbiAgICAgICAgICAgICAgICBkb25lOiB0aGlzLmRvbmVcbiAgICAgICAgICAgIH07XG4gICAgICAgICAgICBpZiAodGhpcy5vcHRpb25zLnJhbmdlcykge1xuICAgICAgICAgICAgICAgIGJhY2t1cC55eWxsb2MucmFuZ2UgPSB0aGlzLnl5bGxvYy5yYW5nZS5zbGljZSgwKTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgfVxuXG4gICAgICAgIGxpbmVzID0gbWF0Y2hbMF0ubWF0Y2goLyg/Olxcclxcbj98XFxuKS4qL2cpO1xuICAgICAgICBpZiAobGluZXMpIHtcbiAgICAgICAgICAgIHRoaXMueXlsaW5lbm8gKz0gbGluZXMubGVuZ3RoO1xuICAgICAgICB9XG4gICAgICAgIHRoaXMueXlsbG9jID0ge1xuICAgICAgICAgICAgZmlyc3RfbGluZTogdGhpcy55eWxsb2MubGFzdF9saW5lLFxuICAgICAgICAgICAgbGFzdF9saW5lOiB0aGlzLnl5bGluZW5vICsgMSxcbiAgICAgICAgICAgIGZpcnN0X2NvbHVtbjogdGhpcy55eWxsb2MubGFzdF9jb2x1bW4sXG4gICAgICAgICAgICBsYXN0X2NvbHVtbjogbGluZXMgP1xuICAgICAgICAgICAgICAgICAgICAgICAgIGxpbmVzW2xpbmVzLmxlbmd0aCAtIDFdLmxlbmd0aCAtIGxpbmVzW2xpbmVzLmxlbmd0aCAtIDFdLm1hdGNoKC9cXHI/XFxuPy8pWzBdLmxlbmd0aCA6XG4gICAgICAgICAgICAgICAgICAgICAgICAgdGhpcy55eWxsb2MubGFzdF9jb2x1bW4gKyBtYXRjaFswXS5sZW5ndGhcbiAgICAgICAgfTtcbiAgICAgICAgdGhpcy55eXRleHQgKz0gbWF0Y2hbMF07XG4gICAgICAgIHRoaXMubWF0Y2ggKz0gbWF0Y2hbMF07XG4gICAgICAgIHRoaXMubWF0Y2hlcyA9IG1hdGNoO1xuICAgICAgICB0aGlzLnl5bGVuZyA9IHRoaXMueXl0ZXh0Lmxlbmd0aDtcbiAgICAgICAgaWYgKHRoaXMub3B0aW9ucy5yYW5nZXMpIHtcbiAgICAgICAgICAgIHRoaXMueXlsbG9jLnJhbmdlID0gW3RoaXMub2Zmc2V0LCB0aGlzLm9mZnNldCArPSB0aGlzLnl5bGVuZ107XG4gICAgICAgIH1cbiAgICAgICAgdGhpcy5fbW9yZSA9IGZhbHNlO1xuICAgICAgICB0aGlzLl9iYWNrdHJhY2sgPSBmYWxzZTtcbiAgICAgICAgdGhpcy5faW5wdXQgPSB0aGlzLl9pbnB1dC5zbGljZShtYXRjaFswXS5sZW5ndGgpO1xuICAgICAgICB0aGlzLm1hdGNoZWQgKz0gbWF0Y2hbMF07XG4gICAgICAgIHRva2VuID0gdGhpcy5wZXJmb3JtQWN0aW9uLmNhbGwodGhpcywgdGhpcy55eSwgdGhpcywgaW5kZXhlZF9ydWxlLCB0aGlzLmNvbmRpdGlvblN0YWNrW3RoaXMuY29uZGl0aW9uU3RhY2subGVuZ3RoIC0gMV0pO1xuICAgICAgICBpZiAodGhpcy5kb25lICYmIHRoaXMuX2lucHV0KSB7XG4gICAgICAgICAgICB0aGlzLmRvbmUgPSBmYWxzZTtcbiAgICAgICAgfVxuICAgICAgICBpZiAodG9rZW4pIHtcbiAgICAgICAgICAgIHJldHVybiB0b2tlbjtcbiAgICAgICAgfSBlbHNlIGlmICh0aGlzLl9iYWNrdHJhY2spIHtcbiAgICAgICAgICAgIC8vIHJlY292ZXIgY29udGV4dFxuICAgICAgICAgICAgZm9yICh2YXIgayBpbiBiYWNrdXApIHtcbiAgICAgICAgICAgICAgICB0aGlzW2tdID0gYmFja3VwW2tdO1xuICAgICAgICAgICAgfVxuICAgICAgICAgICAgcmV0dXJuIGZhbHNlOyAvLyBydWxlIGFjdGlvbiBjYWxsZWQgcmVqZWN0KCkgaW1wbHlpbmcgdGhlIG5leHQgcnVsZSBzaG91bGQgYmUgdGVzdGVkIGluc3RlYWQuXG4gICAgICAgIH1cbiAgICAgICAgcmV0dXJuIGZhbHNlO1xuICAgIH0sXG5cbi8vIHJldHVybiBuZXh0IG1hdGNoIGluIGlucHV0XG5uZXh0OmZ1bmN0aW9uICgpIHtcbiAgICAgICAgaWYgKHRoaXMuZG9uZSkge1xuICAgICAgICAgICAgcmV0dXJuIHRoaXMuRU9GO1xuICAgICAgICB9XG4gICAgICAgIGlmICghdGhpcy5faW5wdXQpIHtcbiAgICAgICAgICAgIHRoaXMuZG9uZSA9IHRydWU7XG4gICAgICAgIH1cblxuICAgICAgICB2YXIgdG9rZW4sXG4gICAgICAgICAgICBtYXRjaCxcbiAgICAgICAgICAgIHRlbXBNYXRjaCxcbiAgICAgICAgICAgIGluZGV4O1xuICAgICAgICBpZiAoIXRoaXMuX21vcmUpIHtcbiAgICAgICAgICAgIHRoaXMueXl0ZXh0ID0gJyc7XG4gICAgICAgICAgICB0aGlzLm1hdGNoID0gJyc7XG4gICAgICAgIH1cbiAgICAgICAgdmFyIHJ1bGVzID0gdGhpcy5fY3VycmVudFJ1bGVzKCk7XG4gICAgICAgIGZvciAodmFyIGkgPSAwOyBpIDwgcnVsZXMubGVuZ3RoOyBpKyspIHtcbiAgICAgICAgICAgIHRlbXBNYXRjaCA9IHRoaXMuX2lucHV0Lm1hdGNoKHRoaXMucnVsZXNbcnVsZXNbaV1dKTtcbiAgICAgICAgICAgIGlmICh0ZW1wTWF0Y2ggJiYgKCFtYXRjaCB8fCB0ZW1wTWF0Y2hbMF0ubGVuZ3RoID4gbWF0Y2hbMF0ubGVuZ3RoKSkge1xuICAgICAgICAgICAgICAgIG1hdGNoID0gdGVtcE1hdGNoO1xuICAgICAgICAgICAgICAgIGluZGV4ID0gaTtcbiAgICAgICAgICAgICAgICBpZiAodGhpcy5vcHRpb25zLmJhY2t0cmFja19sZXhlcikge1xuICAgICAgICAgICAgICAgICAgICB0b2tlbiA9IHRoaXMudGVzdF9tYXRjaCh0ZW1wTWF0Y2gsIHJ1bGVzW2ldKTtcbiAgICAgICAgICAgICAgICAgICAgaWYgKHRva2VuICE9PSBmYWxzZSkge1xuICAgICAgICAgICAgICAgICAgICAgICAgcmV0dXJuIHRva2VuO1xuICAgICAgICAgICAgICAgICAgICB9IGVsc2UgaWYgKHRoaXMuX2JhY2t0cmFjaykge1xuICAgICAgICAgICAgICAgICAgICAgICAgbWF0Y2ggPSBmYWxzZTtcbiAgICAgICAgICAgICAgICAgICAgICAgIGNvbnRpbnVlOyAvLyBydWxlIGFjdGlvbiBjYWxsZWQgcmVqZWN0KCkgaW1wbHlpbmcgYSBydWxlIE1JU21hdGNoLlxuICAgICAgICAgICAgICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgICAgICAgICAgICAgLy8gZWxzZTogdGhpcyBpcyBhIGxleGVyIHJ1bGUgd2hpY2ggY29uc3VtZXMgaW5wdXQgd2l0aG91dCBwcm9kdWNpbmcgYSB0b2tlbiAoZS5nLiB3aGl0ZXNwYWNlKVxuICAgICAgICAgICAgICAgICAgICAgICAgcmV0dXJuIGZhbHNlO1xuICAgICAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgICAgfSBlbHNlIGlmICghdGhpcy5vcHRpb25zLmZsZXgpIHtcbiAgICAgICAgICAgICAgICAgICAgYnJlYWs7XG4gICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgfVxuICAgICAgICB9XG4gICAgICAgIGlmIChtYXRjaCkge1xuICAgICAgICAgICAgdG9rZW4gPSB0aGlzLnRlc3RfbWF0Y2gobWF0Y2gsIHJ1bGVzW2luZGV4XSk7XG4gICAgICAgICAgICBpZiAodG9rZW4gIT09IGZhbHNlKSB7XG4gICAgICAgICAgICAgICAgcmV0dXJuIHRva2VuO1xuICAgICAgICAgICAgfVxuICAgICAgICAgICAgLy8gZWxzZTogdGhpcyBpcyBhIGxleGVyIHJ1bGUgd2hpY2ggY29uc3VtZXMgaW5wdXQgd2l0aG91dCBwcm9kdWNpbmcgYSB0b2tlbiAoZS5nLiB3aGl0ZXNwYWNlKVxuICAgICAgICAgICAgcmV0dXJuIGZhbHNlO1xuICAgICAgICB9XG4gICAgICAgIGlmICh0aGlzLl9pbnB1dCA9PT0gXCJcIikge1xuICAgICAgICAgICAgcmV0dXJuIHRoaXMuRU9GO1xuICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgcmV0dXJuIHRoaXMucGFyc2VFcnJvcignTGV4aWNhbCBlcnJvciBvbiBsaW5lICcgKyAodGhpcy55eWxpbmVubyArIDEpICsgJy4gVW5yZWNvZ25pemVkIHRleHQuXFxuJyArIHRoaXMuc2hvd1Bvc2l0aW9uKCksIHtcbiAgICAgICAgICAgICAgICB0ZXh0OiBcIlwiLFxuICAgICAgICAgICAgICAgIHRva2VuOiBudWxsLFxuICAgICAgICAgICAgICAgIGxpbmU6IHRoaXMueXlsaW5lbm9cbiAgICAgICAgICAgIH0pO1xuICAgICAgICB9XG4gICAgfSxcblxuLy8gcmV0dXJuIG5leHQgbWF0Y2ggdGhhdCBoYXMgYSB0b2tlblxubGV4OmZ1bmN0aW9uIGxleCAoKSB7XG4gICAgICAgIHZhciByID0gdGhpcy5uZXh0KCk7XG4gICAgICAgIGlmIChyKSB7XG4gICAgICAgICAgICByZXR1cm4gcjtcbiAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgIHJldHVybiB0aGlzLmxleCgpO1xuICAgICAgICB9XG4gICAgfSxcblxuLy8gYWN0aXZhdGVzIGEgbmV3IGxleGVyIGNvbmRpdGlvbiBzdGF0ZSAocHVzaGVzIHRoZSBuZXcgbGV4ZXIgY29uZGl0aW9uIHN0YXRlIG9udG8gdGhlIGNvbmRpdGlvbiBzdGFjaylcbmJlZ2luOmZ1bmN0aW9uIGJlZ2luIChjb25kaXRpb24pIHtcbiAgICAgICAgdGhpcy5jb25kaXRpb25TdGFjay5wdXNoKGNvbmRpdGlvbik7XG4gICAgfSxcblxuLy8gcG9wIHRoZSBwcmV2aW91c2x5IGFjdGl2ZSBsZXhlciBjb25kaXRpb24gc3RhdGUgb2ZmIHRoZSBjb25kaXRpb24gc3RhY2tcbnBvcFN0YXRlOmZ1bmN0aW9uIHBvcFN0YXRlICgpIHtcbiAgICAgICAgdmFyIG4gPSB0aGlzLmNvbmRpdGlvblN0YWNrLmxlbmd0aCAtIDE7XG4gICAgICAgIGlmIChuID4gMCkge1xuICAgICAgICAgICAgcmV0dXJuIHRoaXMuY29uZGl0aW9uU3RhY2sucG9wKCk7XG4gICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICByZXR1cm4gdGhpcy5jb25kaXRpb25TdGFja1swXTtcbiAgICAgICAgfVxuICAgIH0sXG5cbi8vIHByb2R1Y2UgdGhlIGxleGVyIHJ1bGUgc2V0IHdoaWNoIGlzIGFjdGl2ZSBmb3IgdGhlIGN1cnJlbnRseSBhY3RpdmUgbGV4ZXIgY29uZGl0aW9uIHN0YXRlXG5fY3VycmVudFJ1bGVzOmZ1bmN0aW9uIF9jdXJyZW50UnVsZXMgKCkge1xuICAgICAgICBpZiAodGhpcy5jb25kaXRpb25TdGFjay5sZW5ndGggJiYgdGhpcy5jb25kaXRpb25TdGFja1t0aGlzLmNvbmRpdGlvblN0YWNrLmxlbmd0aCAtIDFdKSB7XG4gICAgICAgICAgICByZXR1cm4gdGhpcy5jb25kaXRpb25zW3RoaXMuY29uZGl0aW9uU3RhY2tbdGhpcy5jb25kaXRpb25TdGFjay5sZW5ndGggLSAxXV0ucnVsZXM7XG4gICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICByZXR1cm4gdGhpcy5jb25kaXRpb25zW1wiSU5JVElBTFwiXS5ydWxlcztcbiAgICAgICAgfVxuICAgIH0sXG5cbi8vIHJldHVybiB0aGUgY3VycmVudGx5IGFjdGl2ZSBsZXhlciBjb25kaXRpb24gc3RhdGU7IHdoZW4gYW4gaW5kZXggYXJndW1lbnQgaXMgcHJvdmlkZWQgaXQgcHJvZHVjZXMgdGhlIE4tdGggcHJldmlvdXMgY29uZGl0aW9uIHN0YXRlLCBpZiBhdmFpbGFibGVcbnRvcFN0YXRlOmZ1bmN0aW9uIHRvcFN0YXRlIChuKSB7XG4gICAgICAgIG4gPSB0aGlzLmNvbmRpdGlvblN0YWNrLmxlbmd0aCAtIDEgLSBNYXRoLmFicyhuIHx8IDApO1xuICAgICAgICBpZiAobiA+PSAwKSB7XG4gICAgICAgICAgICByZXR1cm4gdGhpcy5jb25kaXRpb25TdGFja1tuXTtcbiAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgIHJldHVybiBcIklOSVRJQUxcIjtcbiAgICAgICAgfVxuICAgIH0sXG5cbi8vIGFsaWFzIGZvciBiZWdpbihjb25kaXRpb24pXG5wdXNoU3RhdGU6ZnVuY3Rpb24gcHVzaFN0YXRlIChjb25kaXRpb24pIHtcbiAgICAgICAgdGhpcy5iZWdpbihjb25kaXRpb24pO1xuICAgIH0sXG5cbi8vIHJldHVybiB0aGUgbnVtYmVyIG9mIHN0YXRlcyBjdXJyZW50bHkgb24gdGhlIHN0YWNrXG5zdGF0ZVN0YWNrU2l6ZTpmdW5jdGlvbiBzdGF0ZVN0YWNrU2l6ZSgpIHtcbiAgICAgICAgcmV0dXJuIHRoaXMuY29uZGl0aW9uU3RhY2subGVuZ3RoO1xuICAgIH0sXG5vcHRpb25zOiB7XCJmbGV4XCI6dHJ1ZSxcImNhc2UtaW5zZW5zaXRpdmVcIjp0cnVlfSxcbnBlcmZvcm1BY3Rpb246IGZ1bmN0aW9uIGFub255bW91cyh5eSx5eV8sJGF2b2lkaW5nX25hbWVfY29sbGlzaW9ucyxZWV9TVEFSVCkge1xudmFyIFlZU1RBVEU9WVlfU1RBUlQ7XG5zd2l0Y2goJGF2b2lkaW5nX25hbWVfY29sbGlzaW9ucykge1xuY2FzZSAwOi8qIGlnbm9yZSAqL1xuYnJlYWs7XG5jYXNlIDE6cmV0dXJuIDEyXG5icmVhaztcbmNhc2UgMjpyZXR1cm4gMTVcbmJyZWFrO1xuY2FzZSAzOnJldHVybiAyNFxuYnJlYWs7XG5jYXNlIDQ6cmV0dXJuIDI5MFxuYnJlYWs7XG5jYXNlIDU6cmV0dXJuIDI5MVxuYnJlYWs7XG5jYXNlIDY6cmV0dXJuIDI5XG5icmVhaztcbmNhc2UgNzpyZXR1cm4gMzFcbmJyZWFrO1xuY2FzZSA4OnJldHVybiAzMlxuYnJlYWs7XG5jYXNlIDk6cmV0dXJuIDI5M1xuYnJlYWs7XG5jYXNlIDEwOnJldHVybiAzNFxuYnJlYWs7XG5jYXNlIDExOnJldHVybiAzOFxuYnJlYWs7XG5jYXNlIDEyOnJldHVybiAzOVxuYnJlYWs7XG5jYXNlIDEzOnJldHVybiA0MVxuYnJlYWs7XG5jYXNlIDE0OnJldHVybiA0M1xuYnJlYWs7XG5jYXNlIDE1OnJldHVybiA0OFxuYnJlYWs7XG5jYXNlIDE2OnJldHVybiA1MVxuYnJlYWs7XG5jYXNlIDE3OnJldHVybiAyOTZcbmJyZWFrO1xuY2FzZSAxODpyZXR1cm4gNjFcbmJyZWFrO1xuY2FzZSAxOTpyZXR1cm4gNjJcbmJyZWFrO1xuY2FzZSAyMDpyZXR1cm4gNjhcbmJyZWFrO1xuY2FzZSAyMTpyZXR1cm4gNzFcbmJyZWFrO1xuY2FzZSAyMjpyZXR1cm4gNzRcbmJyZWFrO1xuY2FzZSAyMzpyZXR1cm4gNzZcbmJyZWFrO1xuY2FzZSAyNDpyZXR1cm4gNzlcbmJyZWFrO1xuY2FzZSAyNTpyZXR1cm4gODFcbmJyZWFrO1xuY2FzZSAyNjpyZXR1cm4gODNcbmJyZWFrO1xuY2FzZSAyNzpyZXR1cm4gMTgzXG5icmVhaztcbmNhc2UgMjg6cmV0dXJuIDk5XG5icmVhaztcbmNhc2UgMjk6cmV0dXJuIDI5N1xuYnJlYWs7XG5jYXNlIDMwOnJldHVybiAxMzJcbmJyZWFrO1xuY2FzZSAzMTpyZXR1cm4gMjk4XG5icmVhaztcbmNhc2UgMzI6cmV0dXJuIDI5OVxuYnJlYWs7XG5jYXNlIDMzOnJldHVybiAxMDlcbmJyZWFrO1xuY2FzZSAzNDpyZXR1cm4gMzAwXG5icmVhaztcbmNhc2UgMzU6cmV0dXJuIDEwOFxuYnJlYWs7XG5jYXNlIDM2OnJldHVybiAzMDFcbmJyZWFrO1xuY2FzZSAzNzpyZXR1cm4gMzAyXG5icmVhaztcbmNhc2UgMzg6cmV0dXJuIDExMlxuYnJlYWs7XG5jYXNlIDM5OnJldHVybiAxMTRcbmJyZWFrO1xuY2FzZSA0MDpyZXR1cm4gMTE1XG5icmVhaztcbmNhc2UgNDE6cmV0dXJuIDEzMFxuYnJlYWs7XG5jYXNlIDQyOnJldHVybiAxMjRcbmJyZWFrO1xuY2FzZSA0MzpyZXR1cm4gMTI1XG5icmVhaztcbmNhc2UgNDQ6cmV0dXJuIDEyN1xuYnJlYWs7XG5jYXNlIDQ1OnJldHVybiAxMzNcbmJyZWFrO1xuY2FzZSA0NjpyZXR1cm4gMTExXG5icmVhaztcbmNhc2UgNDc6cmV0dXJuIDMwM1xuYnJlYWs7XG5jYXNlIDQ4OnJldHVybiAzMDRcbmJyZWFrO1xuY2FzZSA0OTpyZXR1cm4gMTU5XG5icmVhaztcbmNhc2UgNTA6cmV0dXJuIDE2MlxuYnJlYWs7XG5jYXNlIDUxOnJldHVybiAxNjZcbmJyZWFrO1xuY2FzZSA1MjpyZXR1cm4gOTJcbmJyZWFrO1xuY2FzZSA1MzpyZXR1cm4gMTYwXG5icmVhaztcbmNhc2UgNTQ6cmV0dXJuIDMwNVxuYnJlYWs7XG5jYXNlIDU1OnJldHVybiAxNjVcbmJyZWFrO1xuY2FzZSA1NjpyZXR1cm4gMjUxXG5icmVhaztcbmNhc2UgNTc6cmV0dXJuIDE4N1xuYnJlYWs7XG5jYXNlIDU4OnJldHVybiAzMDZcbmJyZWFrO1xuY2FzZSA1OTpyZXR1cm4gMzA3XG5icmVhaztcbmNhc2UgNjA6cmV0dXJuIDIxM1xuYnJlYWs7XG5jYXNlIDYxOnJldHVybiAzMDlcbmJyZWFrO1xuY2FzZSA2MjpyZXR1cm4gMzEwXG5icmVhaztcbmNhc2UgNjM6cmV0dXJuIDIwOFxuYnJlYWs7XG5jYXNlIDY0OnJldHVybiAyMTVcbmJyZWFrO1xuY2FzZSA2NTpyZXR1cm4gMjE2XG5icmVhaztcbmNhc2UgNjY6cmV0dXJuIDIyM1xuYnJlYWs7XG5jYXNlIDY3OnJldHVybiAyMjdcbmJyZWFrO1xuY2FzZSA2ODpyZXR1cm4gMjY4XG5icmVhaztcbmNhc2UgNjk6cmV0dXJuIDMxMVxuYnJlYWs7XG5jYXNlIDcwOnJldHVybiAzMTJcbmJyZWFrO1xuY2FzZSA3MTpyZXR1cm4gMzEzXG5icmVhaztcbmNhc2UgNzI6cmV0dXJuIDMxNFxuYnJlYWs7XG5jYXNlIDczOnJldHVybiAzMTVcbmJyZWFrO1xuY2FzZSA3NDpyZXR1cm4gMjMxXG5icmVhaztcbmNhc2UgNzU6cmV0dXJuIDMxNlxuYnJlYWs7XG5jYXNlIDc2OnJldHVybiAyNDZcbmJyZWFrO1xuY2FzZSA3NzpyZXR1cm4gMjU0XG5icmVhaztcbmNhc2UgNzg6cmV0dXJuIDI1NVxuYnJlYWs7XG5jYXNlIDc5OnJldHVybiAyNDhcbmJyZWFrO1xuY2FzZSA4MDpyZXR1cm4gMjQ5XG5icmVhaztcbmNhc2UgODE6cmV0dXJuIDI1MFxuYnJlYWs7XG5jYXNlIDgyOnJldHVybiAzMTdcbmJyZWFrO1xuY2FzZSA4MzpyZXR1cm4gMzE4XG5icmVhaztcbmNhc2UgODQ6cmV0dXJuIDI1MlxuYnJlYWs7XG5jYXNlIDg1OnJldHVybiAzMjBcbmJyZWFrO1xuY2FzZSA4NjpyZXR1cm4gMzE5XG5icmVhaztcbmNhc2UgODc6cmV0dXJuIDMyMVxuYnJlYWs7XG5jYXNlIDg4OnJldHVybiAyNTdcbmJyZWFrO1xuY2FzZSA4OTpyZXR1cm4gMjU4XG5icmVhaztcbmNhc2UgOTA6cmV0dXJuIDI2MVxuYnJlYWs7XG5jYXNlIDkxOnJldHVybiAyNjNcbmJyZWFrO1xuY2FzZSA5MjpyZXR1cm4gMjY3XG5icmVhaztcbmNhc2UgOTM6cmV0dXJuIDI3MVxuYnJlYWs7XG5jYXNlIDk0OnJldHVybiAyNzRcbmJyZWFrO1xuY2FzZSA5NTpyZXR1cm4gMjc1XG5icmVhaztcbmNhc2UgOTY6cmV0dXJuIDEzXG5icmVhaztcbmNhc2UgOTc6cmV0dXJuIDE2XG5icmVhaztcbmNhc2UgOTg6cmV0dXJuIDI4NlxuYnJlYWs7XG5jYXNlIDk5OnJldHVybiAyMThcbmJyZWFrO1xuY2FzZSAxMDA6cmV0dXJuIDI4XG5icmVhaztcbmNhc2UgMTAxOnJldHVybiAyNzBcbmJyZWFrO1xuY2FzZSAxMDI6cmV0dXJuIDgwXG5icmVhaztcbmNhc2UgMTAzOnJldHVybiAyNzJcbmJyZWFrO1xuY2FzZSAxMDQ6cmV0dXJuIDI3M1xuYnJlYWs7XG5jYXNlIDEwNTpyZXR1cm4gMjgwXG5icmVhaztcbmNhc2UgMTA2OnJldHVybiAyODFcbmJyZWFrO1xuY2FzZSAxMDc6cmV0dXJuIDI4MlxuYnJlYWs7XG5jYXNlIDEwODpyZXR1cm4gMjgzXG5icmVhaztcbmNhc2UgMTA5OnJldHVybiAyODRcbmJyZWFrO1xuY2FzZSAxMTA6cmV0dXJuIDI4NVxuYnJlYWs7XG5jYXNlIDExMTpyZXR1cm4gJ0VYUE9ORU5UJ1xuYnJlYWs7XG5jYXNlIDExMjpyZXR1cm4gMjc2XG5icmVhaztcbmNhc2UgMTEzOnJldHVybiAyNzdcbmJyZWFrO1xuY2FzZSAxMTQ6cmV0dXJuIDI3OFxuYnJlYWs7XG5jYXNlIDExNTpyZXR1cm4gMjc5XG5icmVhaztcbmNhc2UgMTE2OnJldHVybiA4NlxuYnJlYWs7XG5jYXNlIDExNzpyZXR1cm4gMjE5XG5icmVhaztcbmNhc2UgMTE4OnJldHVybiA2XG5icmVhaztcbmNhc2UgMTE5OnJldHVybiAnSU5WQUxJRCdcbmJyZWFrO1xuY2FzZSAxMjA6Y29uc29sZS5sb2coeXlfLnl5dGV4dCk7XG5icmVhaztcbn1cbn0sXG5ydWxlczogWy9eKD86XFxzK3wjW15cXG5cXHJdKikvaSwvXig/OkJBU0UpL2ksL14oPzpQUkVGSVgpL2ksL14oPzpTRUxFQ1QpL2ksL14oPzpESVNUSU5DVCkvaSwvXig/OlJFRFVDRUQpL2ksL14oPzpcXCgpL2ksL14oPzpBUykvaSwvXig/OlxcKSkvaSwvXig/OlxcKikvaSwvXig/OkNPTlNUUlVDVCkvaSwvXig/OldIRVJFKS9pLC9eKD86XFx7KS9pLC9eKD86XFx9KS9pLC9eKD86REVTQ1JJQkUpL2ksL14oPzpBU0spL2ksL14oPzpGUk9NKS9pLC9eKD86TkFNRUQpL2ksL14oPzpHUk9VUCkvaSwvXig/OkJZKS9pLC9eKD86SEFWSU5HKS9pLC9eKD86T1JERVIpL2ksL14oPzpBU0MpL2ksL14oPzpERVNDKS9pLC9eKD86TElNSVQpL2ksL14oPzpPRkZTRVQpL2ksL14oPzpWQUxVRVMpL2ksL14oPzo7KS9pLC9eKD86TE9BRCkvaSwvXig/OlNJTEVOVCkvaSwvXig/OklOVE8pL2ksL14oPzpDTEVBUikvaSwvXig/OkRST1ApL2ksL14oPzpDUkVBVEUpL2ksL14oPzpBREQpL2ksL14oPzpUTykvaSwvXig/Ok1PVkUpL2ksL14oPzpDT1BZKS9pLC9eKD86SU5TRVJUXFxzK0RBVEEpL2ksL14oPzpERUxFVEVcXHMrREFUQSkvaSwvXig/OkRFTEVURVxccytXSEVSRSkvaSwvXig/OldJVEgpL2ksL14oPzpERUxFVEUpL2ksL14oPzpJTlNFUlQpL2ksL14oPzpVU0lORykvaSwvXig/OkRFRkFVTFQpL2ksL14oPzpHUkFQSCkvaSwvXig/OkFMTCkvaSwvXig/OlxcLikvaSwvXig/Ok9QVElPTkFMKS9pLC9eKD86U0VSVklDRSkvaSwvXig/OkJJTkQpL2ksL14oPzpVTkRFRikvaSwvXig/Ok1JTlVTKS9pLC9eKD86VU5JT04pL2ksL14oPzpGSUxURVIpL2ksL14oPzosKS9pLC9eKD86YSkvaSwvXig/OlxcfCkvaSwvXig/OlxcLykvaSwvXig/OlxcXikvaSwvXig/OlxcPykvaSwvXig/OlxcKykvaSwvXig/OiEpL2ksL14oPzpcXFspL2ksL14oPzpcXF0pL2ksL14oPzpcXHxcXHwpL2ksL14oPzomJikvaSwvXig/Oj0pL2ksL14oPzohPSkvaSwvXig/OjwpL2ksL14oPzo+KS9pLC9eKD86PD0pL2ksL14oPzo+PSkvaSwvXig/OklOKS9pLC9eKD86Tk9UKS9pLC9eKD86LSkvaSwvXig/OkJPVU5EKS9pLC9eKD86Qk5PREUpL2ksL14oPzooUkFORHxOT1d8VVVJRHxTVFJVVUlEKSkvaSwvXig/OihMQU5HfERBVEFUWVBFfElSSXxVUkl8QUJTfENFSUx8RkxPT1J8Uk9VTkR8U1RSTEVOfFNUUnxVQ0FTRXxMQ0FTRXxFTkNPREVfRk9SX1VSSXxZRUFSfE1PTlRIfERBWXxIT1VSU3xNSU5VVEVTfFNFQ09ORFN8VElNRVpPTkV8VFp8TUQ1fFNIQTF8U0hBMjU2fFNIQTM4NHxTSEE1MTJ8aXNJUkl8aXNVUkl8aXNCTEFOS3xpc0xJVEVSQUx8aXNOVU1FUklDKSkvaSwvXig/OihMQU5HTUFUQ0hFU3xDT05UQUlOU3xTVFJTVEFSVFN8U1RSRU5EU3xTVFJCRUZPUkV8U1RSQUZURVJ8U1RSTEFOR3xTVFJEVHxzYW1lVGVybSkpL2ksL14oPzpDT05DQVQpL2ksL14oPzpDT0FMRVNDRSkvaSwvXig/OklGKS9pLC9eKD86UkVHRVgpL2ksL14oPzpTVUJTVFIpL2ksL14oPzpSRVBMQUNFKS9pLC9eKD86RVhJU1RTKS9pLC9eKD86Q09VTlQpL2ksL14oPzpTVU18TUlOfE1BWHxBVkd8U0FNUExFKS9pLC9eKD86R1JPVVBfQ09OQ0FUKS9pLC9eKD86U0VQQVJBVE9SKS9pLC9eKD86XFxeXFxeKS9pLC9eKD86dHJ1ZSkvaSwvXig/OmZhbHNlKS9pLC9eKD86KDwoW148PlxcXCJcXHtcXH1cXHxcXF5gXFxcXFxcdTAwMDAtXFx1MDAyMF0pKj4pKS9pLC9eKD86KCgoW0EtWl18W2Etel18W1xcdTAwQzAtXFx1MDBENl18W1xcdTAwRDgtXFx1MDBGNl18W1xcdTAwRjgtXFx1MDJGRl18W1xcdTAzNzAtXFx1MDM3RF18W1xcdTAzN0YtXFx1MUZGRl18W1xcdTIwMEMtXFx1MjAwRF18W1xcdTIwNzAtXFx1MjE4Rl18W1xcdTJDMDAtXFx1MkZFRl18W1xcdTMwMDEtXFx1RDdGRl18W1xcdUY5MDAtXFx1RkRDRl18W1xcdUZERjAtXFx1RkZGRF18W1xcdUQ4MDAtXFx1REI3Rl1bXFx1REMwMC1cXHVERkZGXSkoKCgoKD86KFtBLVpdfFthLXpdfFtcXHUwMEMwLVxcdTAwRDZdfFtcXHUwMEQ4LVxcdTAwRjZdfFtcXHUwMEY4LVxcdTAyRkZdfFtcXHUwMzcwLVxcdTAzN0RdfFtcXHUwMzdGLVxcdTFGRkZdfFtcXHUyMDBDLVxcdTIwMERdfFtcXHUyMDcwLVxcdTIxOEZdfFtcXHUyQzAwLVxcdTJGRUZdfFtcXHUzMDAxLVxcdUQ3RkZdfFtcXHVGOTAwLVxcdUZEQ0ZdfFtcXHVGREYwLVxcdUZGRkRdfFtcXHVEODAwLVxcdURCN0ZdW1xcdURDMDAtXFx1REZGRl0pfF8pKXwtfFswLTldfFxcdTAwQjd8W1xcdTAzMDAtXFx1MDM2Rl18W1xcdTIwM0YtXFx1MjA0MF0pfFxcLikqKCgoPzooW0EtWl18W2Etel18W1xcdTAwQzAtXFx1MDBENl18W1xcdTAwRDgtXFx1MDBGNl18W1xcdTAwRjgtXFx1MDJGRl18W1xcdTAzNzAtXFx1MDM3RF18W1xcdTAzN0YtXFx1MUZGRl18W1xcdTIwMEMtXFx1MjAwRF18W1xcdTIwNzAtXFx1MjE4Rl18W1xcdTJDMDAtXFx1MkZFRl18W1xcdTMwMDEtXFx1RDdGRl18W1xcdUY5MDAtXFx1RkRDRl18W1xcdUZERjAtXFx1RkZGRF18W1xcdUQ4MDAtXFx1REI3Rl1bXFx1REMwMC1cXHVERkZGXSl8XykpfC18WzAtOV18XFx1MDBCN3xbXFx1MDMwMC1cXHUwMzZGXXxbXFx1MjAzRi1cXHUyMDQwXSkpPyk/OikpL2ksL14oPzooKCgoW0EtWl18W2Etel18W1xcdTAwQzAtXFx1MDBENl18W1xcdTAwRDgtXFx1MDBGNl18W1xcdTAwRjgtXFx1MDJGRl18W1xcdTAzNzAtXFx1MDM3RF18W1xcdTAzN0YtXFx1MUZGRl18W1xcdTIwMEMtXFx1MjAwRF18W1xcdTIwNzAtXFx1MjE4Rl18W1xcdTJDMDAtXFx1MkZFRl18W1xcdTMwMDEtXFx1RDdGRl18W1xcdUY5MDAtXFx1RkRDRl18W1xcdUZERjAtXFx1RkZGRF18W1xcdUQ4MDAtXFx1REI3Rl1bXFx1REMwMC1cXHVERkZGXSkoKCgoKD86KFtBLVpdfFthLXpdfFtcXHUwMEMwLVxcdTAwRDZdfFtcXHUwMEQ4LVxcdTAwRjZdfFtcXHUwMEY4LVxcdTAyRkZdfFtcXHUwMzcwLVxcdTAzN0RdfFtcXHUwMzdGLVxcdTFGRkZdfFtcXHUyMDBDLVxcdTIwMERdfFtcXHUyMDcwLVxcdTIxOEZdfFtcXHUyQzAwLVxcdTJGRUZdfFtcXHUzMDAxLVxcdUQ3RkZdfFtcXHVGOTAwLVxcdUZEQ0ZdfFtcXHVGREYwLVxcdUZGRkRdfFtcXHVEODAwLVxcdURCN0ZdW1xcdURDMDAtXFx1REZGRl0pfF8pKXwtfFswLTldfFxcdTAwQjd8W1xcdTAzMDAtXFx1MDM2Rl18W1xcdTIwM0YtXFx1MjA0MF0pfFxcLikqKCgoPzooW0EtWl18W2Etel18W1xcdTAwQzAtXFx1MDBENl18W1xcdTAwRDgtXFx1MDBGNl18W1xcdTAwRjgtXFx1MDJGRl18W1xcdTAzNzAtXFx1MDM3RF18W1xcdTAzN0YtXFx1MUZGRl18W1xcdTIwMEMtXFx1MjAwRF18W1xcdTIwNzAtXFx1MjE4Rl18W1xcdTJDMDAtXFx1MkZFRl18W1xcdTMwMDEtXFx1RDdGRl18W1xcdUY5MDAtXFx1RkRDRl18W1xcdUZERjAtXFx1RkZGRF18W1xcdUQ4MDAtXFx1REI3Rl1bXFx1REMwMC1cXHVERkZGXSl8XykpfC18WzAtOV18XFx1MDBCN3xbXFx1MDMwMC1cXHUwMzZGXXxbXFx1MjAzRi1cXHUyMDQwXSkpPyk/OikoKCgoPzooW0EtWl18W2Etel18W1xcdTAwQzAtXFx1MDBENl18W1xcdTAwRDgtXFx1MDBGNl18W1xcdTAwRjgtXFx1MDJGRl18W1xcdTAzNzAtXFx1MDM3RF18W1xcdTAzN0YtXFx1MUZGRl18W1xcdTIwMEMtXFx1MjAwRF18W1xcdTIwNzAtXFx1MjE4Rl18W1xcdTJDMDAtXFx1MkZFRl18W1xcdTMwMDEtXFx1RDdGRl18W1xcdUY5MDAtXFx1RkRDRl18W1xcdUZERjAtXFx1RkZGRF18W1xcdUQ4MDAtXFx1REI3Rl1bXFx1REMwMC1cXHVERkZGXSl8XykpfDp8WzAtOV18KCglKFswLTldfFtBLUZdfFthLWZdKShbMC05XXxbQS1GXXxbYS1mXSkpfChcXFxcKF98fnxcXC58LXwhfFxcJHwmfCd8XFwofFxcKXxcXCp8XFwrfCx8O3w9fFxcL3xcXD98I3xAfCUpKSkpKCgoKCg/OihbQS1aXXxbYS16XXxbXFx1MDBDMC1cXHUwMEQ2XXxbXFx1MDBEOC1cXHUwMEY2XXxbXFx1MDBGOC1cXHUwMkZGXXxbXFx1MDM3MC1cXHUwMzdEXXxbXFx1MDM3Ri1cXHUxRkZGXXxbXFx1MjAwQy1cXHUyMDBEXXxbXFx1MjA3MC1cXHUyMThGXXxbXFx1MkMwMC1cXHUyRkVGXXxbXFx1MzAwMS1cXHVEN0ZGXXxbXFx1RjkwMC1cXHVGRENGXXxbXFx1RkRGMC1cXHVGRkZEXXxbXFx1RDgwMC1cXHVEQjdGXVtcXHVEQzAwLVxcdURGRkZdKXxfKSl8LXxbMC05XXxcXHUwMEI3fFtcXHUwMzAwLVxcdTAzNkZdfFtcXHUyMDNGLVxcdTIwNDBdKXxcXC58OnwoKCUoWzAtOV18W0EtRl18W2EtZl0pKFswLTldfFtBLUZdfFthLWZdKSl8KFxcXFwoX3x+fFxcLnwtfCF8XFwkfCZ8J3xcXCh8XFwpfFxcKnxcXCt8LHw7fD18XFwvfFxcP3wjfEB8JSkpKSkqKCgoKD86KFtBLVpdfFthLXpdfFtcXHUwMEMwLVxcdTAwRDZdfFtcXHUwMEQ4LVxcdTAwRjZdfFtcXHUwMEY4LVxcdTAyRkZdfFtcXHUwMzcwLVxcdTAzN0RdfFtcXHUwMzdGLVxcdTFGRkZdfFtcXHUyMDBDLVxcdTIwMERdfFtcXHUyMDcwLVxcdTIxOEZdfFtcXHUyQzAwLVxcdTJGRUZdfFtcXHUzMDAxLVxcdUQ3RkZdfFtcXHVGOTAwLVxcdUZEQ0ZdfFtcXHVGREYwLVxcdUZGRkRdfFtcXHVEODAwLVxcdURCN0ZdW1xcdURDMDAtXFx1REZGRl0pfF8pKXwtfFswLTldfFxcdTAwQjd8W1xcdTAzMDAtXFx1MDM2Rl18W1xcdTIwM0YtXFx1MjA0MF0pfDp8KCglKFswLTldfFtBLUZdfFthLWZdKShbMC05XXxbQS1GXXxbYS1mXSkpfChcXFxcKF98fnxcXC58LXwhfFxcJHwmfCd8XFwofFxcKXxcXCp8XFwrfCx8O3w9fFxcL3xcXD98I3xAfCUpKSkpKT8pKSkvaSwvXig/OihfOigoKD86KFtBLVpdfFthLXpdfFtcXHUwMEMwLVxcdTAwRDZdfFtcXHUwMEQ4LVxcdTAwRjZdfFtcXHUwMEY4LVxcdTAyRkZdfFtcXHUwMzcwLVxcdTAzN0RdfFtcXHUwMzdGLVxcdTFGRkZdfFtcXHUyMDBDLVxcdTIwMERdfFtcXHUyMDcwLVxcdTIxOEZdfFtcXHUyQzAwLVxcdTJGRUZdfFtcXHUzMDAxLVxcdUQ3RkZdfFtcXHVGOTAwLVxcdUZEQ0ZdfFtcXHVGREYwLVxcdUZGRkRdfFtcXHVEODAwLVxcdURCN0ZdW1xcdURDMDAtXFx1REZGRl0pfF8pKXxbMC05XSkoKCgoKD86KFtBLVpdfFthLXpdfFtcXHUwMEMwLVxcdTAwRDZdfFtcXHUwMEQ4LVxcdTAwRjZdfFtcXHUwMEY4LVxcdTAyRkZdfFtcXHUwMzcwLVxcdTAzN0RdfFtcXHUwMzdGLVxcdTFGRkZdfFtcXHUyMDBDLVxcdTIwMERdfFtcXHUyMDcwLVxcdTIxOEZdfFtcXHUyQzAwLVxcdTJGRUZdfFtcXHUzMDAxLVxcdUQ3RkZdfFtcXHVGOTAwLVxcdUZEQ0ZdfFtcXHVGREYwLVxcdUZGRkRdfFtcXHVEODAwLVxcdURCN0ZdW1xcdURDMDAtXFx1REZGRl0pfF8pKXwtfFswLTldfFxcdTAwQjd8W1xcdTAzMDAtXFx1MDM2Rl18W1xcdTIwM0YtXFx1MjA0MF0pfFxcLikqKCgoPzooW0EtWl18W2Etel18W1xcdTAwQzAtXFx1MDBENl18W1xcdTAwRDgtXFx1MDBGNl18W1xcdTAwRjgtXFx1MDJGRl18W1xcdTAzNzAtXFx1MDM3RF18W1xcdTAzN0YtXFx1MUZGRl18W1xcdTIwMEMtXFx1MjAwRF18W1xcdTIwNzAtXFx1MjE4Rl18W1xcdTJDMDAtXFx1MkZFRl18W1xcdTMwMDEtXFx1RDdGRl18W1xcdUY5MDAtXFx1RkRDRl18W1xcdUZERjAtXFx1RkZGRF18W1xcdUQ4MDAtXFx1REI3Rl1bXFx1REMwMC1cXHVERkZGXSl8XykpfC18WzAtOV18XFx1MDBCN3xbXFx1MDMwMC1cXHUwMzZGXXxbXFx1MjAzRi1cXHUyMDQwXSkpPykpL2ksL14oPzooW1xcP1xcJF0oKCgoPzooW0EtWl18W2Etel18W1xcdTAwQzAtXFx1MDBENl18W1xcdTAwRDgtXFx1MDBGNl18W1xcdTAwRjgtXFx1MDJGRl18W1xcdTAzNzAtXFx1MDM3RF18W1xcdTAzN0YtXFx1MUZGRl18W1xcdTIwMEMtXFx1MjAwRF18W1xcdTIwNzAtXFx1MjE4Rl18W1xcdTJDMDAtXFx1MkZFRl18W1xcdTMwMDEtXFx1RDdGRl18W1xcdUY5MDAtXFx1RkRDRl18W1xcdUZERjAtXFx1RkZGRF18W1xcdUQ4MDAtXFx1REI3Rl1bXFx1REMwMC1cXHVERkZGXSl8XykpfFswLTldKSgoKD86KFtBLVpdfFthLXpdfFtcXHUwMEMwLVxcdTAwRDZdfFtcXHUwMEQ4LVxcdTAwRjZdfFtcXHUwMEY4LVxcdTAyRkZdfFtcXHUwMzcwLVxcdTAzN0RdfFtcXHUwMzdGLVxcdTFGRkZdfFtcXHUyMDBDLVxcdTIwMERdfFtcXHUyMDcwLVxcdTIxOEZdfFtcXHUyQzAwLVxcdTJGRUZdfFtcXHUzMDAxLVxcdUQ3RkZdfFtcXHVGOTAwLVxcdUZEQ0ZdfFtcXHVGREYwLVxcdUZGRkRdfFtcXHVEODAwLVxcdURCN0ZdW1xcdURDMDAtXFx1REZGRl0pfF8pKXxbMC05XXxcXHUwMEI3fFtcXHUwMzAwLVxcdTAzNkZdfFtcXHUyMDNGLVxcdTIwNDBdKSopKSkvaSwvXig/OihAW2EtekEtWl0rKC1bYS16QS1aMC05XSspKikpL2ksL14oPzooWzAtOV0rKSkvaSwvXig/OihbMC05XSpcXC5bMC05XSspKS9pLC9eKD86KFswLTldK1xcLlswLTldKihbZUVdWystXT9bMC05XSspfFxcLihbMC05XSkrKFtlRV1bKy1dP1swLTldKyl8KFswLTldKSsoW2VFXVsrLV0/WzAtOV0rKSkpL2ksL14oPzooXFwrKFswLTldKykpKS9pLC9eKD86KFxcKyhbMC05XSpcXC5bMC05XSspKSkvaSwvXig/OihcXCsoWzAtOV0rXFwuWzAtOV0qKFtlRV1bKy1dP1swLTldKyl8XFwuKFswLTldKSsoW2VFXVsrLV0/WzAtOV0rKXwoWzAtOV0pKyhbZUVdWystXT9bMC05XSspKSkpL2ksL14oPzooLShbMC05XSspKSkvaSwvXig/OigtKFswLTldKlxcLlswLTldKykpKS9pLC9eKD86KC0oWzAtOV0rXFwuWzAtOV0qKFtlRV1bKy1dP1swLTldKyl8XFwuKFswLTldKSsoW2VFXVsrLV0/WzAtOV0rKXwoWzAtOV0pKyhbZUVdWystXT9bMC05XSspKSkpL2ksL14oPzooW2VFXVsrLV0/WzAtOV0rKSkvaSwvXig/OignKChbXlxcdTAwMjdcXHUwMDVDXFx1MDAwQVxcdTAwMERdKXwoXFxcXFt0Ym5yZlxcXFxcXFwiJ118XFxcXHUoWzAtOV18W0EtRl18W2EtZl0pKFswLTldfFtBLUZdfFthLWZdKShbMC05XXxbQS1GXXxbYS1mXSkoWzAtOV18W0EtRl18W2EtZl0pfFxcXFxVKFswLTldfFtBLUZdfFthLWZdKShbMC05XXxbQS1GXXxbYS1mXSkoWzAtOV18W0EtRl18W2EtZl0pKFswLTldfFtBLUZdfFthLWZdKShbMC05XXxbQS1GXXxbYS1mXSkoWzAtOV18W0EtRl18W2EtZl0pKFswLTldfFtBLUZdfFthLWZdKShbMC05XXxbQS1GXXxbYS1mXSkpKSonKSkvaSwvXig/OihcIigoW15cXHUwMDIyXFx1MDA1Q1xcdTAwMEFcXHUwMDBEXSl8KFxcXFxbdGJucmZcXFxcXFxcIiddfFxcXFx1KFswLTldfFtBLUZdfFthLWZdKShbMC05XXxbQS1GXXxbYS1mXSkoWzAtOV18W0EtRl18W2EtZl0pKFswLTldfFtBLUZdfFthLWZdKXxcXFxcVShbMC05XXxbQS1GXXxbYS1mXSkoWzAtOV18W0EtRl18W2EtZl0pKFswLTldfFtBLUZdfFthLWZdKShbMC05XXxbQS1GXXxbYS1mXSkoWzAtOV18W0EtRl18W2EtZl0pKFswLTldfFtBLUZdfFthLWZdKShbMC05XXxbQS1GXXxbYS1mXSkoWzAtOV18W0EtRl18W2EtZl0pKSkqXCIpKS9pLC9eKD86KCcnJygoJ3wnJyk/KFteJ1xcXFxdfChcXFxcW3RibnJmXFxcXFxcXCInXXxcXFxcdShbMC05XXxbQS1GXXxbYS1mXSkoWzAtOV18W0EtRl18W2EtZl0pKFswLTldfFtBLUZdfFthLWZdKShbMC05XXxbQS1GXXxbYS1mXSl8XFxcXFUoWzAtOV18W0EtRl18W2EtZl0pKFswLTldfFtBLUZdfFthLWZdKShbMC05XXxbQS1GXXxbYS1mXSkoWzAtOV18W0EtRl18W2EtZl0pKFswLTldfFtBLUZdfFthLWZdKShbMC05XXxbQS1GXXxbYS1mXSkoWzAtOV18W0EtRl18W2EtZl0pKFswLTldfFtBLUZdfFthLWZdKSkpKSonJycpKS9pLC9eKD86KFwiXCJcIigoXCJ8XCJcIik/KFteXFxcIlxcXFxdfChcXFxcW3RibnJmXFxcXFxcXCInXXxcXFxcdShbMC05XXxbQS1GXXxbYS1mXSkoWzAtOV18W0EtRl18W2EtZl0pKFswLTldfFtBLUZdfFthLWZdKShbMC05XXxbQS1GXXxbYS1mXSl8XFxcXFUoWzAtOV18W0EtRl18W2EtZl0pKFswLTldfFtBLUZdfFthLWZdKShbMC05XXxbQS1GXXxbYS1mXSkoWzAtOV18W0EtRl18W2EtZl0pKFswLTldfFtBLUZdfFthLWZdKShbMC05XXxbQS1GXXxbYS1mXSkoWzAtOV18W0EtRl18W2EtZl0pKFswLTldfFtBLUZdfFthLWZdKSkpKSpcIlwiXCIpKS9pLC9eKD86KFxcKChcXHUwMDIwfFxcdTAwMDl8XFx1MDAwRHxcXHUwMDBBKSpcXCkpKS9pLC9eKD86KFxcWyhcXHUwMDIwfFxcdTAwMDl8XFx1MDAwRHxcXHUwMDBBKSpcXF0pKS9pLC9eKD86JCkvaSwvXig/Oi4pL2ksL14oPzouKS9pXSxcbmNvbmRpdGlvbnM6IHtcIklOSVRJQUxcIjp7XCJydWxlc1wiOlswLDEsMiwzLDQsNSw2LDcsOCw5LDEwLDExLDEyLDEzLDE0LDE1LDE2LDE3LDE4LDE5LDIwLDIxLDIyLDIzLDI0LDI1LDI2LDI3LDI4LDI5LDMwLDMxLDMyLDMzLDM0LDM1LDM2LDM3LDM4LDM5LDQwLDQxLDQyLDQzLDQ0LDQ1LDQ2LDQ3LDQ4LDQ5LDUwLDUxLDUyLDUzLDU0LDU1LDU2LDU3LDU4LDU5LDYwLDYxLDYyLDYzLDY0LDY1LDY2LDY3LDY4LDY5LDcwLDcxLDcyLDczLDc0LDc1LDc2LDc3LDc4LDc5LDgwLDgxLDgyLDgzLDg0LDg1LDg2LDg3LDg4LDg5LDkwLDkxLDkyLDkzLDk0LDk1LDk2LDk3LDk4LDk5LDEwMCwxMDEsMTAyLDEwMywxMDQsMTA1LDEwNiwxMDcsMTA4LDEwOSwxMTAsMTExLDExMiwxMTMsMTE0LDExNSwxMTYsMTE3LDExOCwxMTksMTIwXSxcImluY2x1c2l2ZVwiOnRydWV9fVxufSk7XG5yZXR1cm4gbGV4ZXI7XG59KSgpO1xucGFyc2VyLmxleGVyID0gbGV4ZXI7XG5mdW5jdGlvbiBQYXJzZXIgKCkge1xuICB0aGlzLnl5ID0ge307XG59XG5QYXJzZXIucHJvdG90eXBlID0gcGFyc2VyO3BhcnNlci5QYXJzZXIgPSBQYXJzZXI7XG5yZXR1cm4gbmV3IFBhcnNlcjtcbn0pKCk7XG5cblxuaWYgKHR5cGVvZiByZXF1aXJlICE9PSAndW5kZWZpbmVkJyAmJiB0eXBlb2YgZXhwb3J0cyAhPT0gJ3VuZGVmaW5lZCcpIHtcbmV4cG9ydHMucGFyc2VyID0gU3BhcnFsUGFyc2VyO1xuZXhwb3J0cy5QYXJzZXIgPSBTcGFycWxQYXJzZXIuUGFyc2VyO1xuZXhwb3J0cy5wYXJzZSA9IGZ1bmN0aW9uICgpIHsgcmV0dXJuIFNwYXJxbFBhcnNlci5wYXJzZS5hcHBseShTcGFycWxQYXJzZXIsIGFyZ3VtZW50cyk7IH07XG5leHBvcnRzLm1haW4gPSBmdW5jdGlvbiBjb21tb25qc01haW4gKGFyZ3MpIHtcbiAgICBpZiAoIWFyZ3NbMV0pIHtcbiAgICAgICAgY29uc29sZS5sb2coJ1VzYWdlOiAnK2FyZ3NbMF0rJyBGSUxFJyk7XG4gICAgICAgIHByb2Nlc3MuZXhpdCgxKTtcbiAgICB9XG4gICAgdmFyIHNvdXJjZSA9IHJlcXVpcmUoJ2ZzJykucmVhZEZpbGVTeW5jKHJlcXVpcmUoJ3BhdGgnKS5ub3JtYWxpemUoYXJnc1sxXSksIFwidXRmOFwiKTtcbiAgICByZXR1cm4gZXhwb3J0cy5wYXJzZXIucGFyc2Uoc291cmNlKTtcbn07XG5pZiAodHlwZW9mIG1vZHVsZSAhPT0gJ3VuZGVmaW5lZCcgJiYgcmVxdWlyZS5tYWluID09PSBtb2R1bGUpIHtcbiAgZXhwb3J0cy5tYWluKHByb2Nlc3MuYXJndi5zbGljZSgxKSk7XG59XG59IiwidmFyIFBhcnNlciA9IHJlcXVpcmUoJy4vbGliL1NwYXJxbFBhcnNlcicpLlBhcnNlcjtcbnZhciBHZW5lcmF0b3IgPSByZXF1aXJlKCcuL2xpYi9TcGFycWxHZW5lcmF0b3InKTtcblxubW9kdWxlLmV4cG9ydHMgPSB7XG4gIC8qKlxuICAgKiBDcmVhdGVzIGEgU1BBUlFMIHBhcnNlciB3aXRoIHRoZSBnaXZlbiBwcmUtZGVmaW5lZCBwcmVmaXhlcyBhbmQgYmFzZSBJUklcbiAgICogQHBhcmFtIHByZWZpeGVzIHsgW3ByZWZpeDogc3RyaW5nXTogc3RyaW5nIH1cbiAgICogQHBhcmFtIGJhc2VJUkkgc3RyaW5nXG4gICAqL1xuICBQYXJzZXI6IGZ1bmN0aW9uIChwcmVmaXhlcywgYmFzZUlSSSkge1xuICAgIC8vIENyZWF0ZSBhIGNvcHkgb2YgdGhlIHByZWZpeGVzXG4gICAgdmFyIHByZWZpeGVzQ29weSA9IHt9O1xuICAgIGZvciAodmFyIHByZWZpeCBpbiBwcmVmaXhlcyB8fCB7fSlcbiAgICAgIHByZWZpeGVzQ29weVtwcmVmaXhdID0gcHJlZml4ZXNbcHJlZml4XTtcblxuICAgIC8vIENyZWF0ZSBhIG5ldyBwYXJzZXIgd2l0aCB0aGUgZ2l2ZW4gcHJlZml4ZXNcbiAgICAvLyAoV29ya2Fyb3VuZCBmb3IgaHR0cHM6Ly9naXRodWIuY29tL3phYWNoL2ppc29uL2lzc3Vlcy8yNDEpXG4gICAgdmFyIHBhcnNlciA9IG5ldyBQYXJzZXIoKTtcbiAgICBwYXJzZXIucGFyc2UgPSBmdW5jdGlvbiAoKSB7XG4gICAgICBQYXJzZXIuYmFzZSA9IGJhc2VJUkkgfHwgJyc7XG4gICAgICBQYXJzZXIucHJlZml4ZXMgPSBPYmplY3QuY3JlYXRlKHByZWZpeGVzQ29weSk7XG4gICAgICByZXR1cm4gUGFyc2VyLnByb3RvdHlwZS5wYXJzZS5hcHBseShwYXJzZXIsIGFyZ3VtZW50cyk7XG4gICAgfTtcbiAgICBwYXJzZXIuX3Jlc2V0QmxhbmtzID0gUGFyc2VyLl9yZXNldEJsYW5rcztcbiAgICByZXR1cm4gcGFyc2VyO1xuICB9LFxuICBHZW5lcmF0b3I6IEdlbmVyYXRvcixcbn07XG4iLCJtb2R1bGUuZXhwb3J0cyA9IGZ1bmN0aW9uKG1vZHVsZSkge1xuXHRpZiAoIW1vZHVsZS53ZWJwYWNrUG9seWZpbGwpIHtcblx0XHRtb2R1bGUuZGVwcmVjYXRlID0gZnVuY3Rpb24oKSB7fTtcblx0XHRtb2R1bGUucGF0aHMgPSBbXTtcblx0XHQvLyBtb2R1bGUucGFyZW50ID0gdW5kZWZpbmVkIGJ5IGRlZmF1bHRcblx0XHRpZiAoIW1vZHVsZS5jaGlsZHJlbikgbW9kdWxlLmNoaWxkcmVuID0gW107XG5cdFx0T2JqZWN0LmRlZmluZVByb3BlcnR5KG1vZHVsZSwgXCJsb2FkZWRcIiwge1xuXHRcdFx0ZW51bWVyYWJsZTogdHJ1ZSxcblx0XHRcdGdldDogZnVuY3Rpb24oKSB7XG5cdFx0XHRcdHJldHVybiBtb2R1bGUubDtcblx0XHRcdH1cblx0XHR9KTtcblx0XHRPYmplY3QuZGVmaW5lUHJvcGVydHkobW9kdWxlLCBcImlkXCIsIHtcblx0XHRcdGVudW1lcmFibGU6IHRydWUsXG5cdFx0XHRnZXQ6IGZ1bmN0aW9uKCkge1xuXHRcdFx0XHRyZXR1cm4gbW9kdWxlLmk7XG5cdFx0XHR9XG5cdFx0fSk7XG5cdFx0bW9kdWxlLndlYnBhY2tQb2x5ZmlsbCA9IDE7XG5cdH1cblx0cmV0dXJuIG1vZHVsZTtcbn07XG4iLCJpbXBvcnQgeyBQYXJzZXIsIERlc2NyaWJlUXVlcnksIFZhcmlhYmxlLCBWYXJpYWJsZUV4cHJlc3Npb24sIFRlcm0gfSBmcm9tICdzcGFycWxqcyc7XG5pbXBvcnQgeyBRdWVyeUJ1aWxkZXIgfSBmcm9tICcuL1F1ZXJ5QnVpbGRlcic7XG5cbmV4cG9ydCBjbGFzcyBEZXNjcmliZUJ1aWxkZXIgZXh0ZW5kcyBRdWVyeUJ1aWxkZXJcbntcblxuICAgIGNvbnN0cnVjdG9yKGRlc2NyaWJlOiBEZXNjcmliZVF1ZXJ5KVxuICAgIHtcbiAgICAgICAgc3VwZXIoZGVzY3JpYmUpO1xuICAgIH1cblxuICAgIHB1YmxpYyBzdGF0aWMgZnJvbVN0cmluZyhxdWVyeVN0cmluZzogc3RyaW5nLCBwcmVmaXhlcz86IHsgW3ByZWZpeDogc3RyaW5nXTogc3RyaW5nOyB9IHwgdW5kZWZpbmVkLCBiYXNlSVJJPzogc3RyaW5nIHwgdW5kZWZpbmVkKTogRGVzY3JpYmVCdWlsZGVyXG4gICAge1xuICAgICAgICBsZXQgcXVlcnkgPSBuZXcgUGFyc2VyKHByZWZpeGVzLCBiYXNlSVJJKS5wYXJzZShxdWVyeVN0cmluZyk7XG4gICAgICAgIGlmICghPERlc2NyaWJlUXVlcnk+cXVlcnkpIHRocm93IG5ldyBFcnJvcihcIk9ubHkgREVTQ0lCRSBpcyBzdXBwb3J0ZWRcIik7XG5cbiAgICAgICAgcmV0dXJuIG5ldyBEZXNjcmliZUJ1aWxkZXIoPERlc2NyaWJlUXVlcnk+cXVlcnkpO1xuICAgIH1cblxuICAgIHB1YmxpYyBzdGF0aWMgbmV3KCk6IERlc2NyaWJlQnVpbGRlclxuICAgIHtcbiAgICAgICAgcmV0dXJuIG5ldyBEZXNjcmliZUJ1aWxkZXIoe1xuICAgICAgICAgIFwicXVlcnlUeXBlXCI6IFwiREVTQ1JJQkVcIixcbiAgICAgICAgICBcInZhcmlhYmxlc1wiOiBbXG4gICAgICAgICAgICBcIipcIlxuICAgICAgICAgIF0sXG4gICAgICAgICAgXCJ0eXBlXCI6IFwicXVlcnlcIixcbiAgICAgICAgICBcInByZWZpeGVzXCI6IHt9XG4gICAgICAgIH0pO1xuICAgIH1cblxuICAgIHB1YmxpYyB2YXJpYWJsZXNBbGwoKTogRGVzY3JpYmVCdWlsZGVyXG4gICAge1xuICAgICAgICB0aGlzLmdldFF1ZXJ5KCkudmFyaWFibGVzID0gWyBcIipcIiBdO1xuXG4gICAgICAgIHJldHVybiB0aGlzO1xuICAgIH1cblxuICAgIHB1YmxpYyB2YXJpYWJsZXModmFyaWFibGVzOiBWYXJpYWJsZVtdKTogRGVzY3JpYmVCdWlsZGVyXG4gICAge1xuICAgICAgICB0aGlzLmdldFF1ZXJ5KCkudmFyaWFibGVzID0gdmFyaWFibGVzO1xuXG4gICAgICAgIHJldHVybiB0aGlzO1xuICAgIH1cblxuICAgIHB1YmxpYyB2YXJpYWJsZSh0ZXJtOiBUZXJtKTogRGVzY3JpYmVCdWlsZGVyXG4gICAge1xuICAgICAgICB0aGlzLmdldFF1ZXJ5KCkudmFyaWFibGVzLnB1c2goPFRlcm0gJiBcIipcIj50ZXJtKTtcblxuICAgICAgICByZXR1cm4gdGhpcztcbiAgICB9XG5cbiAgICBwdWJsaWMgaXNWYXJpYWJsZSh0ZXJtOiBUZXJtKTogYm9vbGVhblxuICAgIHtcbiAgICAgICAgcmV0dXJuIHRoaXMuZ2V0UXVlcnkoKS52YXJpYWJsZXMuaW5jbHVkZXMoPFRlcm0gJiBcIipcIj50ZXJtKTtcbiAgICB9XG5cbiAgICBwcm90ZWN0ZWQgZ2V0UXVlcnkoKTogRGVzY3JpYmVRdWVyeVxuICAgIHtcbiAgICAgICAgcmV0dXJuIDxEZXNjcmliZVF1ZXJ5PnN1cGVyLmdldFF1ZXJ5KCk7XG4gICAgfVxuXG4gICAgcHVibGljIGJ1aWxkKCk6IERlc2NyaWJlUXVlcnlcbiAgICB7XG4gICAgICAgIHJldHVybiA8RGVzY3JpYmVRdWVyeT5zdXBlci5idWlsZCgpO1xuICAgIH1cblxufSIsImltcG9ydCB7IFBhcnNlciwgUXVlcnksIEJhc2VRdWVyeSwgUGF0dGVybiwgRXhwcmVzc2lvbiwgQmxvY2tQYXR0ZXJuLCBGaWx0ZXJQYXR0ZXJuLCBCZ3BQYXR0ZXJuLCBHcmFwaFBhdHRlcm4sIEdyb3VwUGF0dGVybiwgT3BlcmF0aW9uRXhwcmVzc2lvbiwgVHJpcGxlLCBUZXJtLCBQcm9wZXJ0eVBhdGgsIEdlbmVyYXRvciwgU3BhcnFsR2VuZXJhdG9yIH0gZnJvbSAnc3BhcnFsanMnO1xuXG5leHBvcnQgY2xhc3MgUXVlcnlCdWlsZGVyXG57XG5cbiAgICBwcml2YXRlIHJlYWRvbmx5IHF1ZXJ5OiBRdWVyeTtcbiAgICBwcml2YXRlIHJlYWRvbmx5IGdlbmVyYXRvcjogU3BhcnFsR2VuZXJhdG9yO1xuXG4gICAgY29uc3RydWN0b3IocXVlcnk6IFF1ZXJ5KVxuICAgIHtcbiAgICAgICAgdGhpcy5xdWVyeSA9IHF1ZXJ5O1xuICAgICAgICB0aGlzLmdlbmVyYXRvciA9IG5ldyBHZW5lcmF0b3IoKTtcbiAgICAgICAgaWYgKCF0aGlzLnF1ZXJ5LnByZWZpeGVzKSB0aGlzLnF1ZXJ5LnByZWZpeGVzID0ge307XG4gICAgfVxuXG4gICAgcHVibGljIHN0YXRpYyBmcm9tU3RyaW5nKHF1ZXJ5U3RyaW5nOiBzdHJpbmcsIHByZWZpeGVzPzogeyBbcHJlZml4OiBzdHJpbmddOiBzdHJpbmc7IH0gfCB1bmRlZmluZWQsIGJhc2VJUkk/OiBzdHJpbmcgfCB1bmRlZmluZWQpOiBRdWVyeUJ1aWxkZXJcbiAgICB7XG4gICAgICAgIGxldCBxdWVyeSA9IG5ldyBQYXJzZXIocHJlZml4ZXMsIGJhc2VJUkkpLnBhcnNlKHF1ZXJ5U3RyaW5nKTtcbiAgICAgICAgaWYgKCE8UXVlcnk+cXVlcnkpIHRocm93IG5ldyBFcnJvcihcIk9ubHkgU1BBUlFMIHF1ZXJpZXMgYXJlIHN1cHBvcnRlZCwgbm90IHVwZGF0ZXNcIik7XG5cbiAgICAgICAgcmV0dXJuIG5ldyBRdWVyeUJ1aWxkZXIoPFF1ZXJ5PnF1ZXJ5KTtcbiAgICB9XG5cbiAgICBwdWJsaWMgd2hlcmUocGF0dGVybjogUGF0dGVybltdKTogUXVlcnlCdWlsZGVyXG4gICAge1xuICAgICAgICB0aGlzLmdldFF1ZXJ5KCkud2hlcmUgPSBwYXR0ZXJuO1xuXG4gICAgICAgIHJldHVybiB0aGlzO1xuICAgIH1cblxuICAgIHB1YmxpYyB3aGVyZVBhdHRlcm4ocGF0dGVybjogUGF0dGVybik6IFF1ZXJ5QnVpbGRlclxuICAgIHtcbiAgICAgICAgaWYgKCF0aGlzLmdldFF1ZXJ5KCkud2hlcmUpIHRoaXMud2hlcmUoW10pO1xuICAgICAgICB0aGlzLmdldFF1ZXJ5KCkud2hlcmUhLnB1c2gocGF0dGVybik7XG5cbiAgICAgICAgcmV0dXJuIHRoaXM7XG4gICAgfVxuXG4gICAgcHVibGljIGJncFRyaXBsZXModHJpcGxlczogVHJpcGxlW10pOiBRdWVyeUJ1aWxkZXJcbiAgICB7XG4gICAgICAgIC8vIGlmIHRoZSBsYXN0IHBhdHRlcm4gaXMgQkdQLCBhcHBlbmQgdHJpcGxlcyB0byBpdCBpbnN0ZWFkIG9mIGFkZGluZyBuZXcgQkdQXG4gICAgICAgIGlmICh0aGlzLmdldFF1ZXJ5KCkud2hlcmUpXG4gICAgICAgIHtcbiAgICAgICAgICAgIGxldCBsYXN0UGF0dGVybiA9IHRoaXMuZ2V0UXVlcnkoKS53aGVyZSFbdGhpcy5nZXRRdWVyeSgpLndoZXJlIS5sZW5ndGggLSAxXTtcbiAgICAgICAgICAgIGlmIChsYXN0UGF0dGVybi50eXBlID09PSBcImJncFwiKVxuICAgICAgICAgICAge1xuICAgICAgICAgICAgICAgIGxhc3RQYXR0ZXJuLnRyaXBsZXMgPSBsYXN0UGF0dGVybi50cmlwbGVzLmNvbmNhdCh0cmlwbGVzKTtcbiAgICAgICAgICAgICAgICByZXR1cm4gdGhpcztcbiAgICAgICAgICAgIH1cbiAgICAgICAgfVxuXG4gICAgICAgIHJldHVybiB0aGlzLndoZXJlUGF0dGVybihRdWVyeUJ1aWxkZXIuYmdwKHRyaXBsZXMpKTtcbiAgICB9XG5cbiAgICBwdWJsaWMgYmdwVHJpcGxlKHRyaXBsZTogVHJpcGxlKTogUXVlcnlCdWlsZGVyXG4gICAge1xuICAgICAgICByZXR1cm4gdGhpcy5iZ3BUcmlwbGVzKFt0cmlwbGVdKTtcbiAgICB9XG5cbiAgICBwcm90ZWN0ZWQgZ2V0UXVlcnkoKTogUXVlcnlcbiAgICB7XG4gICAgICAgIHJldHVybiB0aGlzLnF1ZXJ5O1xuICAgIH1cblxuICAgIHByb3RlY3RlZCBnZXRHZW5lcmF0b3IoKTogU3BhcnFsR2VuZXJhdG9yXG4gICAge1xuICAgICAgICByZXR1cm4gdGhpcy5nZW5lcmF0b3I7XG4gICAgfVxuXG4gICAgcHVibGljIGJ1aWxkKCk6IFF1ZXJ5XG4gICAge1xuICAgICAgICByZXR1cm4gdGhpcy5nZXRRdWVyeSgpO1xuICAgIH1cblxuICAgIHB1YmxpYyB0b1N0cmluZygpOiBzdHJpbmdcbiAgICB7XG4gICAgICAgIHJldHVybiB0aGlzLmdldEdlbmVyYXRvcigpLnN0cmluZ2lmeSh0aGlzLmdldFF1ZXJ5KCkpO1xuICAgIH1cblxuICAgIHB1YmxpYyBzdGF0aWMgdGVybSh2YWx1ZTogc3RyaW5nKTogVGVybVxuICAgIHtcbiAgICAgICAgcmV0dXJuIDxUZXJtPnZhbHVlO1xuICAgIH1cblxuICAgIHB1YmxpYyBzdGF0aWMgdmFyKHZhck5hbWU6IHN0cmluZyk6IFRlcm1cbiAgICB7XG4gICAgICAgIHJldHVybiA8VGVybT4oXCI/XCIgKyB2YXJOYW1lKTtcbiAgICB9XG5cbiAgICBwdWJsaWMgc3RhdGljIGxpdGVyYWwodmFsdWU6IHN0cmluZyk6IFRlcm1cbiAgICB7XG4gICAgICAgIHJldHVybiA8VGVybT4oXCJcXFwiXCIgKyB2YWx1ZSArIFwiXFxcIlwiKTtcbiAgICB9XG5cbiAgICBwdWJsaWMgc3RhdGljIHR5cGVkTGl0ZXJhbCh2YWx1ZTogc3RyaW5nLCBkYXRhdHlwZTogc3RyaW5nKTogVGVybVxuICAgIHtcbiAgICAgICAgcmV0dXJuIDxUZXJtPihcIlxcXCJcIiArIHZhbHVlICsgXCJcXFwiXl5cIiArIGRhdGF0eXBlKTtcbiAgICB9XG5cbiAgICBwdWJsaWMgc3RhdGljIHVyaSh2YWx1ZTogc3RyaW5nKTogVGVybVxuICAgIHtcbiAgICAgICAgcmV0dXJuIDxUZXJtPnZhbHVlO1xuICAgIH1cblxuICAgIHB1YmxpYyBzdGF0aWMgdHJpcGxlKHN1YmplY3Q6IFRlcm0sIHByZWRpY2F0ZTogUHJvcGVydHlQYXRoIHwgVGVybSwgb2JqZWN0OiBUZXJtKTogVHJpcGxlXG4gICAge1xuICAgICAgICByZXR1cm4ge1xuICAgICAgICAgICAgXCJzdWJqZWN0XCI6IHN1YmplY3QsXG4gICAgICAgICAgICBcInByZWRpY2F0ZVwiOiBwcmVkaWNhdGUsXG4gICAgICAgICAgICBcIm9iamVjdFwiOiBvYmplY3RcbiAgICAgICAgfTtcbiAgICB9XG5cbiAgICBwdWJsaWMgc3RhdGljIGJncCh0cmlwbGVzOiBUcmlwbGVbXSk6IEJncFBhdHRlcm5cbiAgICB7XG4gICAgICAgIHJldHVybiB7XG4gICAgICAgICAgXCJ0eXBlXCI6IFwiYmdwXCIsXG4gICAgICAgICAgXCJ0cmlwbGVzXCI6IHRyaXBsZXNcbiAgICAgICAgfTtcbiAgICB9XG5cbiAgICBwdWJsaWMgc3RhdGljIGdyYXBoKG5hbWU6IHN0cmluZywgcGF0dGVybnM6IFBhdHRlcm5bXSk6IEdyYXBoUGF0dGVyblxuICAgIHtcbiAgICAgICAgcmV0dXJuIHtcbiAgICAgICAgICAgIFwidHlwZVwiOiBcImdyYXBoXCIsXG4gICAgICAgICAgICBcIm5hbWVcIjogPFRlcm0+bmFtZSxcbiAgICAgICAgICAgIFwicGF0dGVybnNcIjogcGF0dGVybnNcbiAgICAgICAgfVxuICAgIH1cblxuICAgIHB1YmxpYyBzdGF0aWMgZ3JvdXAocGF0dGVybnM6IFBhdHRlcm5bXSk6IEdyb3VwUGF0dGVyblxuICAgIHtcbiAgICAgICAgcmV0dXJuIHtcbiAgICAgICAgICAgIFwidHlwZVwiOiBcImdyb3VwXCIsXG4gICAgICAgICAgICBcInBhdHRlcm5zXCI6IHBhdHRlcm5zXG4gICAgICAgIH1cbiAgICB9XG5cbiAgICBwdWJsaWMgc3RhdGljIHVuaW9uKHBhdHRlcm5zOiBQYXR0ZXJuW10pOiBCbG9ja1BhdHRlcm5cbiAgICB7XG4gICAgICAgIHJldHVybiB7XG4gICAgICAgICAgICBcInR5cGVcIjogXCJ1bmlvblwiLFxuICAgICAgICAgICAgXCJwYXR0ZXJuc1wiOiBwYXR0ZXJuc1xuICAgICAgICB9XG4gICAgfVxuXG4gICAgcHVibGljIHN0YXRpYyBmaWx0ZXIoZXhwcmVzc2lvbjogRXhwcmVzc2lvbik6IEZpbHRlclBhdHRlcm5cbiAgICB7XG4gICAgICAgIHJldHVybiB7XG4gICAgICAgICAgICBcInR5cGVcIjogXCJmaWx0ZXJcIixcbiAgICAgICAgICAgIFwiZXhwcmVzc2lvblwiOiBleHByZXNzaW9uXG4gICAgICAgIH1cbiAgICB9XG5cbiAgICBwdWJsaWMgc3RhdGljIG9wZXJhdGlvbihvcGVyYXRvcjogc3RyaW5nLCBhcmdzOiBFeHByZXNzaW9uW10pOiBPcGVyYXRpb25FeHByZXNzaW9uXG4gICAge1xuICAgICAgICByZXR1cm4ge1xuICAgICAgICAgICAgXCJ0eXBlXCI6IFwib3BlcmF0aW9uXCIsXG4gICAgICAgICAgICBcIm9wZXJhdG9yXCI6IG9wZXJhdG9yLFxuICAgICAgICAgICAgXCJhcmdzXCI6IGFyZ3NcbiAgICAgICAgfTtcbiAgICB9XG5cbiAgICBwdWJsaWMgc3RhdGljIGluKHRlcm06IFRlcm0sIGxpc3Q6IFRlcm1bXSk6IE9wZXJhdGlvbkV4cHJlc3Npb25cbiAgICB7XG4gICAgICAgIHJldHVybiBRdWVyeUJ1aWxkZXIub3BlcmF0aW9uKFwiaW5cIiwgWyB0ZXJtLCBsaXN0IF0pO1xuICAgIH1cblxuICAgIHB1YmxpYyBzdGF0aWMgcmVnZXgodGVybTogVGVybSwgcGF0dGVybjogVGVybSwgY2FzZUluc2Vuc2l0aXZlPzogYm9vbGVhbik6IE9wZXJhdGlvbkV4cHJlc3Npb25cbiAgICB7XG4gICAgICAgIGxldCBleHByZXNzaW9uOiBPcGVyYXRpb25FeHByZXNzaW9uID0ge1xuICAgICAgICAgICAgXCJ0eXBlXCI6IFwib3BlcmF0aW9uXCIsXG4gICAgICAgICAgICBcIm9wZXJhdG9yXCI6IFwicmVnZXhcIixcbiAgICAgICAgICAgIFwiYXJnc1wiOiBbIHRlcm0sIDxUZXJtPihcIlxcXCJcIiArIHBhdHRlcm4gKyBcIlxcXCJcIikgXVxuICAgICAgICB9O1xuXG4gICAgICAgIGlmIChjYXNlSW5zZW5zaXRpdmUpIGV4cHJlc3Npb24uYXJncy5wdXNoKDxUZXJtPlwiXFxcImlcXFwiXCIpO1xuXG4gICAgICAgIHJldHVybiBleHByZXNzaW9uO1xuICAgIH1cblxuICAgIHB1YmxpYyBzdGF0aWMgZXEoYXJnMTogRXhwcmVzc2lvbiwgYXJnMjogRXhwcmVzc2lvbik6IE9wZXJhdGlvbkV4cHJlc3Npb25cbiAgICB7XG4gICAgICAgIHJldHVybiBRdWVyeUJ1aWxkZXIub3BlcmF0aW9uKFwiPVwiLCBbIGFyZzEsIGFyZzIgXSk7XG4gICAgfVxuXG4gICAgcHVibGljIHN0YXRpYyBzdHIoYXJnOiBFeHByZXNzaW9uKTogT3BlcmF0aW9uRXhwcmVzc2lvblxuICAgIHtcbiAgICAgICAgcmV0dXJuIFF1ZXJ5QnVpbGRlci5vcGVyYXRpb24oXCJzdHJcIiwgWyBhcmcgXSk7XG4gICAgfVxuXG59IiwiZXhwb3J0IHsgUXVlcnlCdWlsZGVyIH0gZnJvbSAnLi9RdWVyeUJ1aWxkZXInO1xuZXhwb3J0IHsgU2VsZWN0QnVpbGRlciB9IGZyb20gJy4vU2VsZWN0QnVpbGRlcic7XG5leHBvcnQgeyBEZXNjcmliZUJ1aWxkZXIgfSBmcm9tICcuL0Rlc2NyaWJlQnVpbGRlcic7IiwiaW1wb3J0IHsgUGFyc2VyLCBTZWxlY3RRdWVyeSwgT3JkZXJpbmcsIFRlcm0sIFZhcmlhYmxlLCBFeHByZXNzaW9uIH0gZnJvbSAnc3BhcnFsanMnO1xuaW1wb3J0IHsgUXVlcnlCdWlsZGVyIH0gZnJvbSAnLi9RdWVyeUJ1aWxkZXInO1xuXG5leHBvcnQgY2xhc3MgU2VsZWN0QnVpbGRlciBleHRlbmRzIFF1ZXJ5QnVpbGRlclxue1xuXG4gICAgY29uc3RydWN0b3Ioc2VsZWN0OiBTZWxlY3RRdWVyeSlcbiAgICB7XG4gICAgICAgIHN1cGVyKHNlbGVjdCk7XG4gICAgfVxuXG4gICAgcHVibGljIHN0YXRpYyBmcm9tU3RyaW5nKHF1ZXJ5U3RyaW5nOiBzdHJpbmcsIHByZWZpeGVzPzogeyBbcHJlZml4OiBzdHJpbmddOiBzdHJpbmc7IH0gfCB1bmRlZmluZWQsIGJhc2VJUkk/OiBzdHJpbmcgfCB1bmRlZmluZWQpOiBTZWxlY3RCdWlsZGVyXG4gICAge1xuICAgICAgICBsZXQgcXVlcnkgPSBuZXcgUGFyc2VyKHByZWZpeGVzLCBiYXNlSVJJKS5wYXJzZShxdWVyeVN0cmluZyk7XG4gICAgICAgIGlmICghPFNlbGVjdFF1ZXJ5PnF1ZXJ5KSB0aHJvdyBuZXcgRXJyb3IoXCJPbmx5IFNFTEVDVCBpcyBzdXBwb3J0ZWRcIik7XG5cbiAgICAgICAgcmV0dXJuIG5ldyBTZWxlY3RCdWlsZGVyKDxTZWxlY3RRdWVyeT5xdWVyeSk7XG4gICAgfVxuXG4gICAgcHVibGljIHZhcmlhYmxlc0FsbCgpOiBTZWxlY3RCdWlsZGVyXG4gICAge1xuICAgICAgICB0aGlzLmdldFF1ZXJ5KCkudmFyaWFibGVzID0gWyBcIipcIiBdO1xuXG4gICAgICAgIHJldHVybiB0aGlzO1xuICAgIH1cblxuICAgIHB1YmxpYyB2YXJpYWJsZXModmFyaWFibGVzOiBWYXJpYWJsZVtdKTogU2VsZWN0QnVpbGRlclxuICAgIHtcbiAgICAgICAgdGhpcy5nZXRRdWVyeSgpLnZhcmlhYmxlcyA9IHZhcmlhYmxlcztcblxuICAgICAgICByZXR1cm4gdGhpcztcbiAgICB9XG5cbiAgICBwdWJsaWMgdmFyaWFibGUodGVybTogVGVybSk6IFNlbGVjdEJ1aWxkZXJcbiAgICB7XG4gICAgICAgIHRoaXMuZ2V0UXVlcnkoKS52YXJpYWJsZXMucHVzaCg8VGVybSAmIFwiKlwiPnRlcm0pO1xuXG4gICAgICAgIHJldHVybiB0aGlzO1xuICAgIH1cblxuICAgIHB1YmxpYyBpc1ZhcmlhYmxlKHRlcm06IFRlcm0pOiBib29sZWFuXG4gICAge1xuICAgICAgICByZXR1cm4gdGhpcy5nZXRRdWVyeSgpLnZhcmlhYmxlcy5pbmNsdWRlcyg8VGVybSAmIFwiKlwiPnRlcm0pO1xuICAgIH1cblxuICAgIHB1YmxpYyBvcmRlckJ5KG9yZGVyaW5nOiBPcmRlcmluZyk6IFNlbGVjdEJ1aWxkZXJcbiAgICB7XG4gICAgICAgIGlmICghdGhpcy5nZXRRdWVyeSgpLm9yZGVyKSB0aGlzLmdldFF1ZXJ5KCkub3JkZXIgPSBbXTtcbiAgICAgICAgdGhpcy5nZXRRdWVyeSgpLm9yZGVyIS5wdXNoKG9yZGVyaW5nKTtcblxuICAgICAgICByZXR1cm4gdGhpcztcbiAgICB9XG5cbiAgICBwdWJsaWMgb2Zmc2V0KG9mZnNldDogbnVtYmVyKTogU2VsZWN0QnVpbGRlclxuICAgIHtcbiAgICAgICAgdGhpcy5nZXRRdWVyeSgpLm9mZnNldCA9IG9mZnNldDtcblxuICAgICAgICByZXR1cm4gdGhpcztcbiAgICB9XG5cbiAgICBwdWJsaWMgbGltaXQobGltaXQ6IG51bWJlcik6IFNlbGVjdEJ1aWxkZXJcbiAgICB7XG4gICAgICAgIHRoaXMuZ2V0UXVlcnkoKS5saW1pdCA9IGxpbWl0O1xuXG4gICAgICAgIHJldHVybiB0aGlzO1xuICAgIH1cblxuICAgIHByb3RlY3RlZCBnZXRRdWVyeSgpOiBTZWxlY3RRdWVyeVxuICAgIHtcbiAgICAgICAgcmV0dXJuIDxTZWxlY3RRdWVyeT5zdXBlci5nZXRRdWVyeSgpO1xuICAgIH1cblxuICAgIHB1YmxpYyBidWlsZCgpOiBTZWxlY3RRdWVyeVxuICAgIHtcbiAgICAgICAgcmV0dXJuIDxTZWxlY3RRdWVyeT5zdXBlci5idWlsZCgpO1xuICAgIH1cblxuICAgIHB1YmxpYyBzdGF0aWMgb3JkZXJpbmcoZXhwcjogRXhwcmVzc2lvbiwgZGVzYz86IGJvb2xlYW4pOiBPcmRlcmluZ1xuICAgIHtcbiAgICAgICAgbGV0IG9yZGVyaW5nOiBPcmRlcmluZyA9IHtcbiAgICAgICAgICBcImV4cHJlc3Npb25cIjogZXhwcixcbiAgICAgICAgfTtcblxuICAgICAgICBpZiAoZGVzYyAhPT0gdW5kZWZpbmVkICYmIGRlc2MgPT0gdHJ1ZSkgb3JkZXJpbmcuZGVzY2VuZGluZyA9IGRlc2M7XG5cbiAgICAgICAgcmV0dXJuIG9yZGVyaW5nO1xuICAgIH1cblxufSIsIi8qIChpZ25vcmVkKSAqLyIsIi8qIChpZ25vcmVkKSAqLyJdLCJzb3VyY2VSb290IjoiIn0=