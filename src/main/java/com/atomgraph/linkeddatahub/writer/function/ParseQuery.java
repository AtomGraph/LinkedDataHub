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
 * Server-side counterpart of the browser's Traqula <code>Parser</code>, backing the Saxon
 * declaration of the <code>ldh:parse-query</code> stylesheet function for
 * <code>ldh:construct-instance</code>.
 * <p>
 * The stylesheet consumes the Traqula query and pattern keys, including typed RDF terms. The
 * server only needs the construct template and whether the WHERE group is empty; it does not
 * manufacture a second parser AST for query patterns.
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
            JsonObject template = new JsonObject();
            JsonArray triples = new JsonArray();
            JsonObject where = new JsonObject();
            JsonArray patterns = new JsonArray();

            if (query.isConstructType())
                for (Triple triple : query.getConstructTemplate().getBGP().getList())
                {
                    JsonObject map = new JsonObject();
                    map.put("type", "triple");
                    map.put("subject", term(triple.getSubject()));
                    map.put("predicate", term(triple.getPredicate()));
                    map.put("object", term(triple.getObject()));
                    map.put("loc", loc());
                    triples.add(map);
                }

            Element pattern = query.getQueryPattern();
            if (pattern != null && !(pattern instanceof ElementGroup && ((ElementGroup)pattern).isEmpty()))
                patterns.add(new JsonObject()); // only emptiness is consumed by construct-instance

            template.put("type", "pattern");
            template.put("subType", "bgp");
            template.put("triples", triples);
            template.put("loc", loc());
            where.put("type", "pattern");
            where.put("subType", "group");
            where.put("patterns", patterns);
            where.put("loc", loc());
            json.put("type", "query");
            json.put("subType", query.isConstructType() ? "construct" : query.isDescribeType() ? "describe" : query.isAskType() ? "ask" : "select");
            json.put("template", template);
            json.put("where", where);
            json.put("loc", loc());
            return new XdmAtomicValue(json.toString());
        }
        catch (QueryParseException ex)
        {
            throw new SaxonApiException(ex);
        }
    }

    private JsonObject term(Node node)
    {
        JsonObject term = new JsonObject();
        term.put("type", "term");
        if (node.isVariable())
        {
            term.put("subType", "variable");
            term.put("value", node.getName());
        }
        else if (node.isBlank())
        {
            term.put("subType", "blankNode");
            term.put("value", node.getBlankNodeLabel());
        }
        if (node.isLiteral())
        {
            term.put("subType", "literal");
            term.put("value", node.getLiteralLexicalForm());
            if (!node.getLiteralLanguage().isEmpty()) term.put("langOrIri", node.getLiteralLanguage());
            else if (node.getLiteralDatatypeURI() != null && !node.getLiteralDatatypeURI().equals(XSDDatatype.XSDstring.getURI()))
            {
                JsonObject datatype = new JsonObject();
                datatype.put("type", "term");
                datatype.put("subType", "namedNode");
                datatype.put("value", node.getLiteralDatatypeURI());
                datatype.put("loc", loc());
                term.put("langOrIri", datatype);
            }
        }
        else if (node.isURI())
        {
            term.put("subType", "namedNode");
            term.put("value", node.getURI());
        }
        term.put("loc", loc());
        return term;
    }

    private JsonObject loc()
    {
        JsonObject loc = new JsonObject();
        loc.put("sourceLocationType", "autoGenerate");
        return loc;
    }

}
