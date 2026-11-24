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

import com.atomgraph.linkeddatahub.vocabulary.ACL;
import com.atomgraph.spinrdf.vocabulary.SPIN;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Supplier;
import org.apache.jena.graph.Node;
import org.apache.jena.query.QuerySolution;
import org.apache.jena.query.ResultSet;
import org.apache.jena.rdf.model.RDFNode;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.sparql.core.Var;
import org.apache.jena.sparql.engine.binding.Binding;
import org.apache.jena.sparql.expr.E_Exists;
import org.apache.jena.sparql.expr.E_LogicalAnd;
import org.apache.jena.sparql.expr.E_LogicalOr;
import org.apache.jena.sparql.expr.E_Str;
import org.apache.jena.sparql.expr.E_StrStartsWith;
import org.apache.jena.sparql.expr.Expr;
import org.apache.jena.sparql.expr.ExprLib;
import org.apache.jena.sparql.expr.NodeValue;
import org.apache.jena.sparql.graph.NodeTransform;
import org.apache.jena.sparql.syntax.Element;
import org.apache.jena.sparql.syntax.ElementData;
import org.apache.jena.sparql.syntax.ElementGroup;
import org.apache.jena.sparql.syntax.syntaxtransform.ElementTransform;
import org.apache.jena.sparql.syntax.syntaxtransform.ElementTransformSubst;
import org.apache.jena.sparql.syntax.syntaxtransform.ElementTransformer;
import org.apache.jena.sparql.syntax.syntaxtransform.ExprTransformNodeElement;

/**
 * What an agent may access in a dataspace, as the decision for one document needs it turned around: the
 * <code>(?Rel ?Target)</code> rows the agent's authorizations name, which a document's own rows (its
 * {@link DocumentContext}) have to meet. {@link DocumentContext} fixes the document and asks for the authorizations;
 * this fixes the agent and asks of a graph whether its context meets them, using the same document context query, with
 * <code>$this</code> bound to the graph.
 * <p>
 * A row may carry a condition: a row of the document's own context that has to be there too. The owner's
 * authorizations are the one such case today - they count only on a document whose own graph names the agent as its
 * <code>acl:owner</code>, so they are rows on the condition <code>(acl:owner agent)</code>.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 * @see com.atomgraph.linkeddatahub.vocabulary.LDHC#documentContextQuery
 * @see com.atomgraph.linkeddatahub.vocabulary.LDHC#aclQuery
 */
public class Grants
{

    /**
     * A <code>(?Rel ?Target)</code> row.
     *
     * @param rel the tag: <code>acl:accessTo</code>, <code>acl:default</code>, <code>acl:accessToClass</code> or <code>acl:owner</code>
     * @param target what the tag names
     */
    public record Row(Node rel, Node target) {}

    private final Element context;
    private final String base;
    private final boolean all;
    private final List<Row> rows;
    private final Map<Row, List<Row>> conditional;

    /**
     * Constructs the grants of an agent.
     *
     * @param context the pattern of the document context query
     * @param base the dataspace's base URI, which every graph of the dataspace is under
     * @param all true if the dataspace lets anyone read it, which leaves only the dataspace to check
     * @param rows the rows that hold on any document
     * @param conditional the rows that hold only on a document whose own context has the key row
     */
    public Grants(Element context, String base, boolean all, List<Row> rows, Map<Row, List<Row>> conditional)
    {
        if (context == null) throw new IllegalArgumentException("Context pattern cannot be null");
        if (base == null) throw new IllegalArgumentException("Base URI cannot be null");
        if (rows == null) throw new IllegalArgumentException("Rows cannot be null");
        if (conditional == null) throw new IllegalArgumentException("Conditional rows cannot be null");

        this.context = context;
        this.base = base;
        this.all = all;
        this.rows = Collections.unmodifiableList(new ArrayList<>(rows));
        this.conditional = Collections.unmodifiableMap(new LinkedHashMap<>(conditional));
    }

    /**
     * Returns the grants of an agent from the rows its authorizations name as a non-owner and as an owner: what the
     * owner's add holds on the condition <code>(acl:owner agent)</code>.
     *
     * @param context the pattern of the document context query
     * @param base the dataspace's base URI
     * @param agent agent resource or null
     * @param rows the rows of the agent as a non-owner
     * @param ownerRows the rows of the agent as an owner
     * @return grants
     */
    public static Grants of(Element context, String base, Resource agent, List<Row> rows, List<Row> ownerRows)
    {
        List<Row> ownerOnly = new ArrayList<>(ownerRows);
        ownerOnly.removeAll(rows);
        if (agent == null || ownerOnly.isEmpty()) return new Grants(context, base, false, rows, Map.of());

        return new Grants(context, base, false, rows, Map.of(new Row(ACL.owner.asNode(), agent.asNode()), ownerOnly));
    }

    /**
     * Reads <code>(?Rel ?Target)</code> rows from a result set.
     *
     * @param resultSet result of the grant query
     * @return rows
     */
    public static List<Row> rows(ResultSet resultSet)
    {
        List<Row> rows = new ArrayList<>();
        while (resultSet.hasNext())
        {
            QuerySolution solution = resultSet.next();
            Resource rel = solution.getResource(DocumentContext.REL_VAR_NAME);
            RDFNode target = solution.get(DocumentContext.TARGET_VAR_NAME);
            if (rel != null && target != null) rows.add(new Row(rel.asNode(), target.asNode()));
        }
        return rows;
    }

    /**
     * Returns true if no graph can meet these grants, so that a pattern over any graph has no solutions.
     *
     * @return true if nothing is granted
     */
    public boolean isEmpty()
    {
        return !isAll() && getRows().isEmpty() && getConditional().isEmpty();
    }

    /**
     * Returns the condition a graph has to meet for these grants to reach it.
     * The graph has to be one of the dataspace's: the decision for a document is made by the dataspace its URI belongs
     * to, which the request's origin selects, so one dataspace's authorizations never decide another's graphs where
     * the two share a store. Then its context has to meet an unconditional row, or a conditional one together with
     * the row the condition names. The condition is checked first, as a separate <code>EXISTS</code>: it binds the
     * graph's context to one row, where the grant rows alone would match every row of it.
     * <p>
     * Every <code>EXISTS</code> holds the context pattern first and the rows after it, never one context pattern joined
     * to another. The context pattern reads the graph from <code>$this</code>, which inside <code>EXISTS</code> is a
     * variable of the enclosing query; SPARQL substitutes it, but a store may instead pass the enclosing solution into
     * the pattern, and then only the left side of a join receives it. A context pattern on the right side would bind
     * <code>?Target</code> to nothing in <code>BIND($this AS ?Target)</code>, and match every row of its tag.
     * <p>
     * Every variable of the context query is renamed with a prefix the caller supplies, so that none of them can
     * capture a variable of the query the condition is placed in: an <code>EXISTS</code> sees the bindings around it.
     *
     * @param graph the graph: a variable or an IRI
     * @param prefixes supplies variable prefixes that no variable of the enclosing query starts with
     * @return boolean expression
     */
    public Expr guard(Node graph, Supplier<String> prefixes)
    {
        if (graph == null) throw new IllegalArgumentException("Graph node cannot be null");
        if (prefixes == null) throw new IllegalArgumentException("Prefix supplier cannot be null");

        Expr dataspace = new E_StrStartsWith(new E_Str(ExprLib.nodeToExpr(graph)), NodeValue.makeString(getBase()));
        if (isAll()) return dataspace;

        List<Expr> matches = new ArrayList<>();
        if (!getRows().isEmpty()) matches.add(new E_Exists(match(graph, prefixes.get(), getRows())));
        getConditional().forEach((condition, conditionalRows) ->
            matches.add(new E_LogicalAnd(new E_Exists(match(graph, prefixes.get(), List.of(condition))),
                new E_Exists(match(graph, prefixes.get(), conditionalRows)))));
        if (matches.isEmpty()) return NodeValue.FALSE;

        return new E_LogicalAnd(dataspace, matches.stream().reduce(E_LogicalOr::new).get());
    }

    /**
     * Returns the context of the graph joined with the given rows: a match is a row of both.
     *
     * @param graph the graph
     * @param prefix the prefix of the context query's variables
     * @param matchRows rows to match
     * @return graph pattern
     */
    protected Element match(Node graph, String prefix, List<Row> matchRows)
    {
        NodeTransform rename = node ->
        {
            if (!node.isVariable()) return node;
            if (node.getName().equals(SPIN.THIS_VAR_NAME)) return graph;
            return Var.alloc(prefix + node.getName());
        };
        ElementTransform transform = new ElementTransformSubst(rename);

        Var rel = Var.alloc(prefix + DocumentContext.REL_VAR_NAME), target = Var.alloc(prefix + DocumentContext.TARGET_VAR_NAME);
        ElementData data = new ElementData(List.of(rel, target), matchRows.stream().
            map(row -> Binding.builder().add(rel, row.rel()).add(target, row.target()).build()).
            toList());

        ElementGroup group = new ElementGroup();
        group.addElement(ElementTransformer.transform(getContext(), transform, new ExprTransformNodeElement(rename, transform)));
        group.addElement(data);
        return group;
    }

    /**
     * Returns the pattern of the document context query.
     *
     * @return graph pattern
     */
    public Element getContext()
    {
        return context;
    }

    /**
     * Returns the base URI of the dataspace.
     *
     * @return base URI
     */
    public String getBase()
    {
        return base;
    }

    /**
     * Returns true if the dataspace lets anyone read it.
     *
     * @return true for a dataspace read without authorization
     */
    public boolean isAll()
    {
        return all;
    }

    /**
     * Returns the rows that hold on any document.
     *
     * @return rows
     */
    public List<Row> getRows()
    {
        return rows;
    }

    /**
     * Returns the rows that hold only on a document whose own context has the key row.
     *
     * @return rows by condition
     */
    public Map<Row, List<Row>> getConditional()
    {
        return conditional;
    }

}
