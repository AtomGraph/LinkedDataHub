/**
 *  Copyright 2026 Martynas Jusevičius <martynas@atomgraph.com>
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */
package com.atomgraph.linkeddatahub.writer.function;

import com.atomgraph.linkeddatahub.vocabulary.LDH;
import net.sf.saxon.s9api.ExtensionFunction;
import net.sf.saxon.s9api.ItemType;
import net.sf.saxon.s9api.OccurrenceIndicator;
import net.sf.saxon.s9api.QName;
import net.sf.saxon.s9api.SaxonApiException;
import net.sf.saxon.s9api.SequenceType;
import net.sf.saxon.s9api.XdmAtomicValue;
import net.sf.saxon.s9api.XdmValue;
import org.apache.jena.atlas.json.JsonArray;
import org.apache.jena.atlas.json.JsonObject;
import org.apache.jena.datatypes.xsd.XSDDatatype;
import org.apache.jena.graph.Node;
import org.apache.jena.graph.Triple;
import org.apache.jena.query.Query;
import org.apache.jena.query.QueryFactory;
import org.apache.jena.query.QueryParseException;
import org.apache.jena.sparql.syntax.Element;
import org.apache.jena.sparql.syntax.ElementGroup;

/**
 * Server-side counterpart of the browser's SPARQL.js 2.x <code>Parser</code>, backing the Saxon
 * declaration of the <code>ldh:parse-query</code> stylesheet function so that
 * <code>ldh:construct-instance</code> runs identically on both products.
 * <p>
 * This is deliberately NOT a full SPARQL.js replacement: it emits only the subset of the parse
 * tree that the stylesheets consume — a <code>template</code> array of triple maps and a
 * <code>where</code> array whose non-emptiness marks a query that cannot be instantiated as a pure
 * template (SPARQL.js puts the actual parsed patterns there; only the emptiness test is shared).
 * Term strings follow the SPARQL.js 2.x serialization expected by
 * <code>ldh:triples-to-descriptions</code>: bare URIs (no angle brackets), <code>_:label</code>
 * blank nodes, <code>?name</code> variables, and <code>"lex"</code> /
 * <code>"lex"@lang</code> / <code>"lex"^^datatypeURI</code> literals with the datatype URI
 * unwrapped — a 2.x quirk that the stylesheet regexes depend on. Divergences from SPARQL.js:
 * blank node labels are Jena's parser-allocated ones, not the source labels (downstream only needs
 * per-query consistency — <code>ldh:instance-term</code> prefixes them per constructor); variables
 * are normalized to the <code>?</code> sigil (SPARQL.js preserves <code>$</code>, and the
 * stylesheets accept both); plain literals are emitted without <code>^^xsd:string</code> to match
 * SPARQL.js 2.x, although Jena types them as such per RDF 1.1.
 * <p>
 * If SPARQL.js is ever upgraded to 3.x (see the TO-DO in <code>ldh:triples-to-descriptions</code>),
 * this function, <code>ldh:triples-to-descriptions</code> and <code>ldh:construct-instance</code>
 * must change in lockstep.
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class ParseQuery implements ExtensionFunction
{

    @Override
    public QName getName()
    {
        return new QName(LDH.NS, "parse-query");
    }

    @Override
    public SequenceType getResultType()
    {
        return SequenceType.makeSequenceType(ItemType.STRING, OccurrenceIndicator.ONE);
    }

    @Override
    public SequenceType[] getArgumentTypes()
    {
        return new SequenceType[]
        {
            SequenceType.makeSequenceType(ItemType.STRING, OccurrenceIndicator.ONE),
        };
    }

    @Override
    public XdmValue call(XdmValue[] arguments) throws SaxonApiException
    {
        try
        {
            Query query = QueryFactory.create(arguments[0].itemAt(0).getStringValue());
            JsonObject json = new JsonObject();
            JsonArray template = new JsonArray();
            JsonArray where = new JsonArray();

            if (query.isConstructType())
                for (Triple triple : query.getConstructTemplate().getBGP().getList())
                {
                    JsonObject map = new JsonObject();
                    map.put("subject", term(triple.getSubject()));
                    map.put("predicate", term(triple.getPredicate()));
                    map.put("object", term(triple.getObject()));
                    template.add(map);
                }
            else
                where.add(new JsonObject()); // not a CONSTRUCT: mark as non-instantiable

            Element pattern = query.getQueryPattern();
            if (pattern != null && !(pattern instanceof ElementGroup && ((ElementGroup)pattern).isEmpty()))
                where.add(new JsonObject());

            json.put("template", template);
            json.put("where", where);
            return new XdmAtomicValue(json.toString());
        }
        catch (QueryParseException ex)
        {
            throw new SaxonApiException(ex);
        }
    }

    private String term(Node node)
    {
        if (node.isVariable()) return "?" + node.getName();
        if (node.isBlank()) return "_:" + node.getBlankNodeLabel();
        if (node.isLiteral())
        {
            String lex = "\"" + node.getLiteralLexicalForm() + "\"";
            if (!node.getLiteralLanguage().isEmpty()) return lex + "@" + node.getLiteralLanguage();
            if (node.getLiteralDatatypeURI() != null && !node.getLiteralDatatypeURI().equals(XSDDatatype.XSDstring.getURI())) return lex + "^^" + node.getLiteralDatatypeURI();
            return lex;
        }
        return node.getURI();
    }

}
