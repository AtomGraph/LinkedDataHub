/**
 *  Copyright 2026 Martynas Jusevičius <martynas@atomgraph.com>
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */
package com.atomgraph.linkeddatahub.server.util;

import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import javax.xml.transform.stream.StreamSource;
import net.sf.saxon.om.NamespaceMap;
import net.sf.saxon.s9api.Axis;
import net.sf.saxon.s9api.DocumentBuilder;
import net.sf.saxon.s9api.Processor;
import net.sf.saxon.s9api.QName;
import net.sf.saxon.s9api.SaxonApiException;
import net.sf.saxon.s9api.XdmNode;
import net.sf.saxon.s9api.XdmNodeKind;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * What a package stylesheet may declare and call, checked as XML before it is composed with the platform's.
 *
 * Import precedence keeps a package from overriding the platform's own rules (see {@link StylesheetComposer}), but not
 * from overriding another package, from adding rules where the platform has none, or from acting on the page. The
 * contract closes those: a package declares templates only in the open modes and names only in its own namespace,
 * changes no global setting, imports nothing, and has no effect of its own. It renders: no interactive XSLT
 * (<code>ixsl:</code>) at all, no reading of resources or the environment, no code chosen at run time. What a rule
 * returns, the platform places; what a package wants done, it declares as an action the platform carries out. See
 * <code>PACKAGE-CONTRACT.md</code>.
 *
 * With no <code>ixsl:</code> and no I/O a package rule can only compute, so it may call any platform function, named
 * template or open mode without the platform's code being analysed for what it does.
 *
 * The platform side is derived from the platform's stylesheets, never listed by hand, so it cannot drift from them:
 * the open modes are the modes declared or matched in the modules below the composition marker
 * (<code>hooks.xsl</code>, <code>client/hooks.xsl</code> and what they import), the unnamed mode included when they
 * have mode-less rules; the collecting modes are those whose <code>xsl:mode</code> carries
 * <code>ldh:collecting="true"</code>.
 *
 * Function calls are found by a lexer that skips string literals and comments, not by parsing: the expressions refer
 * to functions of the platform that no static context here can declare.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class PackageContract
{

    private static final Logger log = LoggerFactory.getLogger(PackageContract.class);

    /** XSLT namespace */
    public static final String XSL_NS = "http://www.w3.org/1999/XSL/Transform";
    /** Saxon-JS interactive XSLT namespace */
    public static final String IXSL_NS = "http://saxonica.com/ns/interactiveXSLT";
    /** XPath functions namespace */
    public static final String FN_NS = "http://www.w3.org/2005/xpath-functions";
    /** LinkedDataHub namespace */
    public static final String LDH_NS = "https://w3id.org/atomgraph/linkeddatahub#";
    /** Web-Client namespace */
    public static final String AC_NS = "https://w3id.org/atomgraph/client#";
    /** Dataspaces namespace */
    public static final String LDS_NS = "https://w3id.org/atomgraph/linkeddatahub/dataspaces#";
    /** The name of the unnamed mode, as the mode attribute spells it */
    public static final String UNNAMED_MODE = "#unnamed";
    /** Suffix of the import href that marks the composition point, as in {@link StylesheetComposer} */
    public static final String MARKER_SUFFIX = "hooks.xsl";

    /** Namespaces a package may not declare names in; the empty string is no namespace */
    public static final Set<String> PLATFORM_NAMESPACES = Set.of(LDH_NS, AC_NS, LDS_NS, "http://www.w3.org/1999/xhtml", "http://www.w3.org/2000/svg", "");

    /** Functions that read a resource or the environment */
    public static final Set<String> IO_FUNCTIONS = Set.of(
        clark(FN_NS, "document"), clark(FN_NS, "doc"), clark(FN_NS, "doc-available"),
        clark(FN_NS, "unparsed-text"), clark(FN_NS, "unparsed-text-lines"), clark(FN_NS, "unparsed-text-available"),
        clark(FN_NS, "json-doc"), clark(FN_NS, "collection"), clark(FN_NS, "uri-collection"),
        clark(FN_NS, "environment-variable"), clark(FN_NS, "available-environment-variables"));

    /** Functions and instructions that run code chosen at run time, which no static check can follow */
    public static final Set<String> DYNAMIC_FUNCTIONS = Set.of(
        clark(FN_NS, "function-lookup"), clark(FN_NS, "transform"), clark(FN_NS, "load-xquery-module"));

    /** Top-level declarations that change the whole composed stylesheet */
    public static final Set<String> GLOBAL_DECLARATIONS = Set.of(
        "output", "strip-space", "preserve-space", "decimal-format", "namespace-alias", "global-context-item", "character-map");

    /** Declarations that bring in other modules */
    public static final Set<String> IMPORT_DECLARATIONS = Set.of("import", "include", "use-package", "import-schema");

    /** Top-level declarations whose name must be in the package's own namespace */
    public static final Set<String> NAMED_DECLARATIONS = Set.of("function", "template", "variable", "param", "key", "accumulator", "attribute-set", "mode");

    /** Attributes of XSLT instructions that hold an expression or a pattern rather than an attribute value template */
    public static final Set<String> EXPRESSION_ATTRIBUTES = Set.of(
        "select", "test", "use", "match", "group-by", "group-adjacent", "group-starting-with", "group-ending-with",
        "value", "from", "count", "initial-value", "use-when", "with-params", "context-item", "for-each-item", "for-each-source");

    private static final QName MODE = new QName("mode");
    private static final QName NAME = new QName("name");
    private static final QName MATCH = new QName("match");
    private static final QName HREF = new QName("href");
    private static final QName ID = new QName("id");
    private static final QName DEFAULT_MODE = new QName("default-mode");
    private static final QName EXPAND_TEXT = new QName("expand-text");
    private static final QName XSL_EXPAND_TEXT = new QName(XSL_NS, "expand-text");
    private static final QName COLLECTING = new QName(LDH_NS, "collecting");

    /**
     * A breach of the contract.
     *
     * @param rule the rule broken: modes, names, globals, imports, ixsl, io, dynamic, ids or collecting
     * @param element the element that breaks it, as its qualified name
     * @param line the element's line in the stylesheet, or -1 if unknown
     * @param detail what about it breaks the rule
     */
    public record Violation(String rule, String element, int line, String detail)
    {
        @Override
        public String toString()
        {
            return rule + " (line " + line + ", " + element + "): " + detail;
        }
    }

    private final Processor processor;
    private final Set<String> openModes;
    private final Set<String> collectingModes;

    /**
     * Constructs a contract from what the platform opens and collects.
     *
     * @param processor Saxon processor the stylesheets are read with
     * @param openModes open modes, as Clark names, the unnamed mode as {@value #UNNAMED_MODE}
     * @param collectingModes collecting modes, as Clark names
     */
    public PackageContract(Processor processor, Set<String> openModes, Set<String> collectingModes)
    {
        this.processor = processor;
        this.openModes = Collections.unmodifiableSet(openModes);
        this.collectingModes = Collections.unmodifiableSet(collectingModes);
    }

    /**
     * Derives the contract from the platform's entry stylesheets, following their imports and includes.
     * A module that cannot be read is logged and left out; whatever only it would have declared is then unknown to the
     * contract, so the result is as strict as the modules that were read.
     *
     * @param processor Saxon processor
     * @param entries entry stylesheets (the server's layout and the client's), as URLs that resolve their relative imports
     * @return the contract
     */
    public static PackageContract fromPlatform(Processor processor, List<URL> entries)
    {
        Map<String, XdmNode> modules = new LinkedHashMap<>();
        Set<String> openModules = new HashSet<>();
        for (URL entry : entries) load(processor, entry, false, modules, openModules);

        Set<String> openModes = new HashSet<>();
        Set<String> collectingModes = new HashSet<>();

        for (Map.Entry<String, XdmNode> module : modules.entrySet())
        {
            XdmNode stylesheet = documentElement(module.getValue());
            if (stylesheet == null) continue;
            boolean open = openModules.contains(module.getKey());

            for (XdmNode decl : elements(stylesheet))
            {
                if (!XSL_NS.equals(ns(decl))) continue;

                if (local(decl).equals("mode") && decl.getAttributeValue(NAME) != null)
                {
                    String mode = qname(decl, decl.getAttributeValue(NAME));
                    if (open) openModes.add(mode);
                    if ("true".equals(decl.getAttributeValue(COLLECTING))) collectingModes.add(mode);
                }

                if (open && local(decl).equals("template") && decl.getAttributeValue(MATCH) != null)
                    for (String mode : modes(decl, stylesheet)) if (!mode.equals("#all")) openModes.add(mode);
            }
        }

        if (log.isDebugEnabled()) log.debug("Package contract: {} modules, {} open modes, {} collecting modes", modules.size(), openModes.size(), collectingModes.size());
        return new PackageContract(processor, openModes, collectingModes);
    }

    /**
     * Checks a package stylesheet.
     *
     * @param url the stylesheet
     * @return violations, empty if it keeps the contract
     * @throws IOException the stylesheet could not be read
     * @throws SaxonApiException the stylesheet is not well-formed XML
     */
    public List<Violation> check(URL url) throws IOException, SaxonApiException
    {
        try (InputStream is = url.openStream())
        {
            return check(parse(getProcessor(), new StreamSource(is, url.toString())));
        }
    }

    /**
     * Checks a package stylesheet.
     *
     * @param doc the stylesheet document, read with line numbering
     * @return violations, empty if it keeps the contract
     */
    public List<Violation> check(XdmNode doc)
    {
        List<Violation> violations = new ArrayList<>();
        XdmNode stylesheet = documentElement(doc);
        if (stylesheet == null || !XSL_NS.equals(ns(stylesheet)))
        {
            violations.add(new Violation("imports", stylesheet != null ? stylesheet.getNodeName().toString() : "", -1, "not an XSLT stylesheet"));
            return violations;
        }

        for (XdmNode decl : elements(stylesheet))
        {
            if (!XSL_NS.equals(ns(decl))) continue;
            String local = local(decl);

            if (IMPORT_DECLARATIONS.contains(local))
                violations.add(violation("imports", decl, "a package is one module" + (decl.getAttributeValue(HREF) != null ? "; imports " + decl.getAttributeValue(HREF) : "")));
            if (GLOBAL_DECLARATIONS.contains(local))
                violations.add(violation("globals", decl, "changes the whole composed stylesheet"));

            if (local.equals("mode"))
            {
                String name = decl.getAttributeValue(NAME);
                if (name == null) violations.add(violation("globals", decl, "declares the unnamed mode"));
                else if (PLATFORM_NAMESPACES.contains(namespace(qname(decl, name))) || openModes.contains(qname(decl, name)))
                    violations.add(violation("globals", decl, "re-declares the platform's mode " + name));
            }
            else if (NAMED_DECLARATIONS.contains(local) && decl.getAttributeValue(NAME) != null)
            {
                String name = qname(decl, decl.getAttributeValue(NAME));
                if (PLATFORM_NAMESPACES.contains(namespace(name)))
                    violations.add(violation("names", decl, decl.getAttributeValue(NAME) + " is not in the package's own namespace"));
            }

            if (local.equals("template") && decl.getAttributeValue(MATCH) != null)
            {
                List<String> modes = modes(decl, stylesheet);
                for (String mode : modes)
                {
                    if (mode.equals("#all")) violations.add(violation("modes", decl, "matches in every mode"));
                    else if (!openModes.contains(mode)) violations.add(violation("modes", decl, "mode " + label(mode) + " is not open to packages"));
                }
                if (modes.stream().anyMatch(collectingModes::contains) && !endsWithNextMatch(decl))
                    violations.add(violation("collecting", decl, "a rule in a collecting mode must end with xsl:next-match, or it hides the other packages' contributions"));
            }
        }

        for (XdmNode elem : descendants(stylesheet))
        {
            String name = clark(ns(elem), local(elem));
            if (IXSL_NS.equals(ns(elem))) violations.add(violation("ixsl", elem, "acts on the page; return the content and let the platform place it, or declare an action"));
            for (XdmNode attr : attributes(elem))
            {
                if (IXSL_NS.equals(ns(attr))) violations.add(violation("ixsl", elem, attr.getNodeName() + " marks code that acts on the page"));
                if (XSL_NS.equals(ns(elem)) && local(attr).startsWith("_") && ns(attr).isEmpty())
                    violations.add(violation("dynamic", elem, "shadow attribute " + local(attr) + " builds an expression at compile time"));
            }

            if (name.equals(clark(XSL_NS, "result-document"))) violations.add(violation("io", elem, "writes a result document; return the content and let the platform place it"));
            if (name.equals(clark(XSL_NS, "evaluate"))) violations.add(violation("dynamic", elem, "evaluates an expression built at run time"));

            if (!XSL_NS.equals(ns(elem)) && !IXSL_NS.equals(ns(elem)) && elem.getAttributeValue(ID) != null)
                violations.add(violation("ids", elem, "id \"" + elem.getAttributeValue(ID) + "\": the platform finds its own elements by id; address the package's markup by class"));
            if (name.equals(clark(XSL_NS, "attribute")) && "id".equals(elem.getAttributeValue(NAME)))
                violations.add(violation("ids", elem, "constructs an id attribute"));

            for (String call : calls(elem))
            {
                String fn = function(elem, call);
                if (IXSL_NS.equals(namespace(fn))) violations.add(violation("ixsl", elem, call + " reaches the page, the window or JavaScript"));
                else if (IO_FUNCTIONS.contains(fn)) violations.add(violation("io", elem, call + " reads a resource or the environment; the platform makes the requests"));
                else if (DYNAMIC_FUNCTIONS.contains(fn)) violations.add(violation("dynamic", elem, call + " calls code chosen at run time"));
            }
        }

        return violations;
    }

    /**
     * Returns true if a template's last instruction is <code>xsl:next-match</code>.
     *
     * @param template template element
     * @return true if it ends with next-match
     */
    public static boolean endsWithNextMatch(XdmNode template)
    {
        XdmNode last = null;
        for (XdmNode child : elements(template))
            if (!(XSL_NS.equals(ns(child)) && (local(child).equals("param") || local(child).equals("context-item")))) last = child;
        return last != null && XSL_NS.equals(ns(last)) && local(last).equals("next-match");
    }

    // PLATFORM MODULES

    private static void load(Processor processor, URL url, boolean open, Map<String, XdmNode> modules, Set<String> openModules)
    {
        String key = url.toString();
        if (open) openModules.add(key);
        if (modules.containsKey(key))
        {
            if (open) markOpen(key, modules, openModules); // reached again from the marker: what it imports is open too
            return;
        }

        XdmNode doc;
        try (InputStream is = url.openStream())
        {
            doc = parse(processor, new StreamSource(is, key));
        }
        catch (IOException | SaxonApiException ex)
        {
            if (log.isWarnEnabled()) log.warn("Package contract: could not read platform module <{}>, leaving it out", url, ex);
            return;
        }
        modules.put(key, doc);

        XdmNode stylesheet = documentElement(doc);
        if (stylesheet == null) return;
        for (XdmNode decl : elements(stylesheet))
            if (XSL_NS.equals(ns(decl)) && (local(decl).equals("import") || local(decl).equals("include")) && decl.getAttributeValue(HREF) != null)
            {
                String href = decl.getAttributeValue(HREF);
                try
                {
                    // a module is open if it is the marker import or below it; an include shares its includer's tier
                    boolean below = open || (local(decl).equals("import") && href.endsWith(MARKER_SUFFIX));
                    load(processor, new URL(url, href), below, modules, openModules);
                }
                catch (IOException ex)
                {
                    if (log.isWarnEnabled()) log.warn("Package contract: could not resolve <{}> against <{}>", href, url, ex);
                }
            }
    }

    private static void markOpen(String module, Map<String, XdmNode> modules, Set<String> openModules)
    {
        XdmNode doc = modules.get(module);
        XdmNode stylesheet = doc != null ? documentElement(doc) : null;
        if (stylesheet == null) return;
        for (XdmNode decl : elements(stylesheet))
            if (XSL_NS.equals(ns(decl)) && (local(decl).equals("import") || local(decl).equals("include")) && decl.getAttributeValue(HREF) != null)
                try
                {
                    String key = new URL(new URL(module), decl.getAttributeValue(HREF)).toString();
                    if (openModules.add(key)) markOpen(key, modules, openModules);
                }
                catch (IOException ex)
                {
                    // already reported when the module was loaded
                }
    }

    // STYLESHEET STRUCTURE

    /**
     * Returns the modes a template rule is in, as Clark names.
     */
    private static List<String> modes(XdmNode template, XdmNode stylesheet)
    {
        String mode = template.getAttributeValue(MODE);
        if (mode == null) return List.of(defaultMode(stylesheet));
        List<String> modes = new ArrayList<>();
        for (String token : mode.trim().split("\\s+"))
        {
            if (token.equals("#default")) modes.add(defaultMode(stylesheet));
            else if (token.equals("#unnamed")) modes.add(UNNAMED_MODE);
            else if (token.equals("#all")) modes.add("#all");
            else modes.add(qname(template, token));
        }
        return modes;
    }

    private static String defaultMode(XdmNode stylesheet)
    {
        String mode = stylesheet.getAttributeValue(DEFAULT_MODE);
        return mode == null || mode.equals("#unnamed") ? UNNAMED_MODE : qname(stylesheet, mode);
    }

    /**
     * Returns the function names an element's own expressions call or reference, as lexical QNames: its expression
     * attributes, the expressions in its attribute value templates, and its text value templates.
     */
    private static List<String> calls(XdmNode elem)
    {
        List<String> calls = new ArrayList<>();
        boolean xsl = XSL_NS.equals(ns(elem));
        boolean ixsl = IXSL_NS.equals(ns(elem));

        for (XdmNode attr : attributes(elem))
        {
            String value = attr.getStringValue();
            boolean expression = (xsl && ns(attr).isEmpty() && EXPRESSION_ATTRIBUTES.contains(local(attr))) ||
                (ixsl && ns(attr).isEmpty()) ||
                (!xsl && XSL_NS.equals(ns(attr)) && local(attr).equals("use-when"));
            if (expression) calls.addAll(names(value));
            else for (String avt : avt(value)) calls.addAll(names(avt));
        }

        if (expandText(elem))
            for (XdmNode child : elem.children())
                if (child.getNodeKind() == XdmNodeKind.TEXT)
                    for (String tvt : avt(child.getStringValue())) calls.addAll(names(tvt));

        return calls;
    }

    private static boolean expandText(XdmNode elem)
    {
        for (XdmNode node = elem; node != null && node.getNodeKind() == XdmNodeKind.ELEMENT; node = node.getParent())
        {
            String value = XSL_NS.equals(ns(node)) ? node.getAttributeValue(EXPAND_TEXT) : node.getAttributeValue(XSL_EXPAND_TEXT);
            if (value != null) return value.trim().equals("yes") || value.trim().equals("true") || value.trim().equals("1");
        }
        return false;
    }

    // LEXING

    /**
     * Returns the expressions inside an attribute value template, unescaping <code>{{</code> and <code>}}</code>.
     *
     * @param value attribute or text value
     * @return the enclosed expressions
     */
    public static List<String> avt(String value)
    {
        List<String> expressions = new ArrayList<>();
        int i = 0, n = value.length();
        while (i < n)
        {
            char c = value.charAt(i);
            if (c == '{' && i + 1 < n && value.charAt(i + 1) == '{') { i += 2; continue; }
            if (c == '{')
            {
                int end = closing(value, i + 1);
                expressions.add(value.substring(i + 1, end));
                i = end + 1;
                continue;
            }
            i++;
        }
        return expressions;
    }

    /**
     * Returns the index of the brace closing an enclosed expression that starts at the given index, skipping string
     * literals, comments and nested braces (maps, arrays, inline functions); the end of the string if unclosed.
     */
    private static int closing(String expr, int start)
    {
        int depth = 0, i = start, n = expr.length();
        while (i < n)
        {
            char c = expr.charAt(i);
            if (c == '\'' || c == '"') { i = skipString(expr, i); continue; }
            if (c == '(' && i + 1 < n && expr.charAt(i + 1) == ':') { i = skipComment(expr, i); continue; }
            if (c == '{') depth++;
            if (c == '}') { if (depth == 0) return i; depth--; }
            i++;
        }
        return n;
    }

    /**
     * Returns the names an XPath expression calls or references as functions: a lexical QName or an EQName followed,
     * after optional whitespace and comments, by <code>(</code>, or by <code>#</code> and an arity. String literals and
     * comments are skipped; a name after <code>$</code> or before <code>::</code> is not a function. Keywords followed
     * by a parenthesis (<code>if</code>, <code>node</code>, <code>return</code>...) come back as names too: they resolve
     * to no function in a namespace the contract cares about.
     *
     * @param expr expression
     * @return lexical function names
     */
    public static List<String> names(String expr)
    {
        List<String> names = new ArrayList<>();
        int i = 0, n = expr.length();
        while (i < n)
        {
            char c = expr.charAt(i);
            if (c == '\'' || c == '"') { i = skipString(expr, i); continue; }
            if (c == '(' && i + 1 < n && expr.charAt(i + 1) == ':') { i = skipComment(expr, i); continue; }

            boolean braced = c == 'Q' && i + 1 < n && expr.charAt(i + 1) == '{';
            if ((braced || isNameStart(c)) && (i == 0 || !isNameChar(expr.charAt(i - 1))))
            {
                int start = i;
                if (braced)
                {
                    int close = expr.indexOf('}', i);
                    if (close < 0) return names;
                    i = close + 1;
                    while (i < n && isNameChar(expr.charAt(i))) i++;
                }
                else
                {
                    while (i < n && isNameChar(expr.charAt(i))) i++;
                    if (i + 1 < n && expr.charAt(i) == ':' && isNameStart(expr.charAt(i + 1)))
                    {
                        i++;
                        while (i < n && isNameChar(expr.charAt(i))) i++;
                    }
                }
                String name = expr.substring(start, i);
                if (precededByDollar(expr, start)) continue;

                int j = skipSpace(expr, i);
                if (j + 1 < n && expr.charAt(j) == ':' && expr.charAt(j + 1) == ':') continue; // an axis
                if (j < n && expr.charAt(j) == '(' && !(j + 1 < n && expr.charAt(j + 1) == ':')) names.add(name);
                else if (j + 1 < n && expr.charAt(j) == '#' && Character.isDigit(expr.charAt(j + 1))) names.add(name);
                continue;
            }
            i++;
        }
        return names;
    }

    private static boolean precededByDollar(String expr, int start)
    {
        int k = start - 1;
        while (k >= 0 && Character.isWhitespace(expr.charAt(k))) k--;
        return k >= 0 && expr.charAt(k) == '$';
    }

    private static int skipSpace(String expr, int i)
    {
        int n = expr.length();
        while (i < n)
        {
            if (Character.isWhitespace(expr.charAt(i))) i++;
            else if (expr.charAt(i) == '(' && i + 1 < n && expr.charAt(i + 1) == ':') i = skipComment(expr, i);
            else break;
        }
        return i;
    }

    private static int skipString(String expr, int i)
    {
        char quote = expr.charAt(i);
        int n = expr.length();
        i++;
        while (i < n)
        {
            if (expr.charAt(i) == quote)
            {
                if (i + 1 < n && expr.charAt(i + 1) == quote) { i += 2; continue; }
                return i + 1;
            }
            i++;
        }
        return n;
    }

    private static int skipComment(String expr, int i)
    {
        int depth = 0, n = expr.length();
        while (i < n)
        {
            if (expr.startsWith("(:", i)) { depth++; i += 2; continue; }
            if (expr.startsWith(":)", i)) { depth--; i += 2; if (depth == 0) return i; continue; }
            i++;
        }
        return n;
    }

    private static boolean isNameStart(char c)
    {
        return Character.isLetter(c) || c == '_' || c > 0x7F;
    }

    private static boolean isNameChar(char c)
    {
        return isNameStart(c) || Character.isDigit(c) || c == '-' || c == '.';
    }

    // NAMES

    /**
     * Resolves a function name: an EQName as written, a prefixed name by the element's in-scope namespaces, an
     * unprefixed one in the functions namespace.
     */
    private static String function(XdmNode elem, String lexical)
    {
        if (lexical.startsWith("Q{")) return "{" + lexical.substring(2);
        int colon = lexical.indexOf(':');
        if (colon < 0) return clark(FN_NS, lexical);
        net.sf.saxon.om.NamespaceUri uri = namespaces(elem).getURIForPrefix(lexical.substring(0, colon), false);
        return clark(uri != null ? uri.toString() : "#undeclared", lexical.substring(colon + 1));
    }

    /**
     * Resolves a QName-valued attribute (a mode, a template or function name): an unprefixed name is in no namespace.
     */
    private static String qname(XdmNode elem, String lexical)
    {
        lexical = lexical.trim();
        if (lexical.startsWith("Q{")) return "{" + lexical.substring(2);
        int colon = lexical.indexOf(':');
        if (colon < 0) return clark("", lexical);
        net.sf.saxon.om.NamespaceUri uri = namespaces(elem).getURIForPrefix(lexical.substring(0, colon), false);
        return clark(uri != null ? uri.toString() : "#undeclared", lexical.substring(colon + 1));
    }

    private static NamespaceMap namespaces(XdmNode elem)
    {
        return elem.getUnderlyingNode().getAllNamespaces();
    }

    /**
     * Returns a Clark name, <code>{uri}local</code>.
     *
     * @param uri namespace URI, empty for none
     * @param local local name
     * @return Clark name
     */
    public static String clark(String uri, String local)
    {
        return "{" + uri + "}" + local;
    }

    private static String namespace(String clark)
    {
        return clark.substring(1, clark.indexOf('}'));
    }

    private static String label(String clark)
    {
        if (clark.equals(UNNAMED_MODE)) return "the unnamed mode";
        if (clark.startsWith("{}")) return clark.substring(2);
        for (Map.Entry<String, String> prefix : PREFIXES.entrySet())
            if (clark.startsWith("{" + prefix.getKey() + "}")) return prefix.getValue() + ":" + clark.substring(prefix.getKey().length() + 2);
        return clark;
    }

    /** Prefixes the messages name the platform's namespaces with */
    private static final Map<String, String> PREFIXES = Map.of(LDH_NS, "ldh", AC_NS, "ac", LDS_NS, "lds", IXSL_NS, "ixsl", FN_NS, "fn", XSL_NS, "xsl");

    // NODES

    private static XdmNode parse(Processor processor, StreamSource source) throws SaxonApiException
    {
        DocumentBuilder builder = processor.newDocumentBuilder();
        builder.setLineNumbering(true);
        return builder.build(source);
    }

    private static Violation violation(String rule, XdmNode elem, String detail)
    {
        return new Violation(rule, elem.getNodeName().toString(), elem.getLineNumber(), detail);
    }

    private static XdmNode documentElement(XdmNode doc)
    {
        for (XdmNode child : doc.children()) if (child.getNodeKind() == XdmNodeKind.ELEMENT) return child;
        return null;
    }

    private static List<XdmNode> elements(XdmNode parent)
    {
        List<XdmNode> elements = new ArrayList<>();
        for (XdmNode child : parent.children()) if (child.getNodeKind() == XdmNodeKind.ELEMENT) elements.add(child);
        return elements;
    }

    private static List<XdmNode> descendants(XdmNode parent)
    {
        List<XdmNode> descendants = new ArrayList<>();
        parent.axisIterator(Axis.DESCENDANT).forEachRemaining(node -> { if (node.getNodeKind() == XdmNodeKind.ELEMENT) descendants.add(node); });
        return descendants;
    }

    private static List<XdmNode> attributes(XdmNode elem)
    {
        List<XdmNode> attributes = new ArrayList<>();
        elem.axisIterator(Axis.ATTRIBUTE).forEachRemaining(attributes::add);
        return attributes;
    }

    private static String ns(XdmNode node)
    {
        return node.getNodeName().getNamespace();
    }

    private static String local(XdmNode node)
    {
        return node.getNodeName().getLocalName();
    }

    /**
     * Returns the Saxon processor.
     *
     * @return processor
     */
    public Processor getProcessor()
    {
        return processor;
    }

    /**
     * Returns the open modes.
     *
     * @return Clark names, the unnamed mode as {@value #UNNAMED_MODE}
     */
    public Set<String> getOpenModes()
    {
        return openModes;
    }

    /**
     * Returns the collecting modes.
     *
     * @return Clark names
     */
    public Set<String> getCollectingModes()
    {
        return collectingModes;
    }

}
