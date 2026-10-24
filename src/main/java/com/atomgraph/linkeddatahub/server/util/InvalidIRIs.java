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
package com.atomgraph.linkeddatahub.server.util;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.apache.jena.graph.Node;
import org.apache.jena.irix.IRIException;
import org.apache.jena.irix.IRIx;
import org.apache.jena.query.QueryParseException;
import org.apache.jena.sparql.core.Quad;
import org.apache.jena.sparql.modify.request.UpdateData;
import org.apache.jena.sparql.modify.request.UpdateDeleteWhere;
import org.apache.jena.sparql.modify.request.UpdateModify;
import org.apache.jena.update.Update;
import org.apache.jena.update.UpdateRequest;

/**
 * Finds the IRIs in a write that are not IRIs, by the same rules Jena's RDF parsers refuse them with.
 * A malformed IRI reaches the server in three shapes: an RDF body the parser stops at, a SPARQL update the lexer
 * stops at, and a SPARQL update the lexer lets through, since it reads an IRI reference as anything between
 * <code>&lt;</code> and <code>&gt;</code> without spaces. Each is reduced to the offending value and its explanation,
 * so a client can be told which value it was.
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class InvalidIRIs
{

    /** The message Jena's RDF parsers give a bad IRI: the position, a prefix some languages add, the IRI in angle brackets, then the explanation */
    private static final Pattern IRI_MESSAGE = Pattern.compile("^(?:\\[line: -?\\d+, col: -?\\d+\\] )?(?:Bad IRI: )?<(.*)> : .*$", Pattern.DOTALL);
    /** The SPARQL parser's message for an unexpected token, which carries the token's own position: the exception's line and column are those of the token before it */
    private static final Pattern UNEXPECTED_TOKEN = Pattern.compile("^Encountered .*? at line (\\d+), column (\\d+)\\.", Pattern.DOTALL);

    private InvalidIRIs()
    {
    }

    /**
     * Checks one IRI.
     *
     * @param iri IRI string
     * @return the explanation if it is not an IRI, empty otherwise
     */
    public static Optional<String> check(String iri)
    {
        if (iri == null) throw new IllegalArgumentException("IRI string cannot be null");

        try
        {
            IRIx.create(iri);
            return Optional.empty();
        }
        catch (IRIException ex)
        {
            return Optional.of(ex.getMessage());
        }
    }

    /**
     * Returns the IRIs of the quads an update writes or deletes that are not IRIs, which the SPARQL lexer let through.
     *
     * @param updateRequest parsed update
     * @return malformed IRIs mapped to their explanations, in the order they appear
     */
    public static Map<String, String> of(UpdateRequest updateRequest)
    {
        if (updateRequest == null) throw new IllegalArgumentException("UpdateRequest cannot be null");

        Map<String, String> violations = new LinkedHashMap<>();
        for (Update update : updateRequest.getOperations())
        {
            if (update instanceof UpdateModify modify)
            {
                addViolations(modify.getDeleteAcc().getQuads(), violations);
                addViolations(modify.getInsertAcc().getQuads(), violations);
            }
            if (update instanceof UpdateData data) addViolations(data.getQuads(), violations);
            if (update instanceof UpdateDeleteWhere deleteWhere) addViolations(deleteWhere.getQuads(), violations);
        }
        return violations;
    }

    private static void addViolations(List<Quad> quads, Map<String, String> violations)
    {
        for (Quad quad : quads)
            for (Node node : new Node[] { quad.getGraph(), quad.getSubject(), quad.getPredicate(), quad.getObject() })
                if (node != null && node.isURI() && !violations.containsKey(node.getURI()))
                    check(node.getURI()).ifPresent(message -> violations.put(node.getURI(), message));
    }

    /**
     * Returns the IRI a parse error is about, if the error is one of Jena's IRI errors.
     * The RDF parsers stop at the first bad IRI and report it only in the message, as
     * <code>&lt;iri&gt; : explanation</code> after the position and, in some languages, <code>Bad IRI:</code>.
     *
     * @param message the parse error's message
     * @return the IRI, if it is a malformed one
     */
    public static Optional<String> fromMessage(String message)
    {
        if (message == null) return Optional.empty();

        Matcher matcher = IRI_MESSAGE.matcher(message);
        if (!matcher.matches()) return Optional.empty();

        String iri = matcher.group(1);
        return check(iri).isPresent() ? Optional.of(iri) : Optional.empty();
    }

    /**
     * Returns the IRI reference a SPARQL syntax error stops at, if the error is the lexer failing on one.
     * The position is read off the message, which gives the unexpected token's own; the exception's line and
     * column are those of the token before it.
     *
     * @param update the update string
     * @param ex the syntax error
     * @return the IRI, if the error is at a malformed one
     * @see #atPosition(String, int, int)
     */
    public static Optional<String> atError(String update, QueryParseException ex)
    {
        if (ex == null) throw new IllegalArgumentException("QueryParseException cannot be null");

        Matcher matcher = UNEXPECTED_TOKEN.matcher(ex.getMessage() != null ? ex.getMessage() : "");
        if (!matcher.find()) return Optional.empty();

        return atPosition(update, Integer.parseInt(matcher.group(1)), Integer.parseInt(matcher.group(2)));
    }

    /**
     * Returns the IRI reference at a position of a SPARQL string, if it is a malformed one.
     * An IRI reference with a space or a <code>&lt;</code> in it is no IRIREF token to the lexer, so the parser
     * reports the <code>&lt;</code> that opens it as an unexpected token, at its line and column. The reference
     * runs from there to the first <code>&gt;</code> that ends a token, which is what a serializer writing
     * <code>&lt;iri&gt;</code> terms leaves behind it.
     *
     * @param update the update string
     * @param line the unexpected token's line, from 1
     * @param column the unexpected token's column, from 1
     * @return the IRI, if the token opens a malformed one
     */
    public static Optional<String> atPosition(String update, int line, int column)
    {
        if (update == null) throw new IllegalArgumentException("Update string cannot be null");

        String[] lines = update.split("\n", -1);
        if (line < 1 || line > lines.length) return Optional.empty();
        String text = lines[line - 1];
        int start = column - 1;
        if (start < 0 || start >= text.length() || text.charAt(start) != '<') return Optional.empty();

        for (int end = text.indexOf('>', start + 1); end != -1; end = text.indexOf('>', end + 1))
            if (end + 1 == text.length() || Character.isWhitespace(text.charAt(end + 1)) || ".;,)]}".indexOf(text.charAt(end + 1)) != -1)
            {
                String iri = text.substring(start + 1, end);
                return check(iri).isPresent() ? Optional.of(iri) : Optional.empty();
            }

        return Optional.empty();
    }

}
