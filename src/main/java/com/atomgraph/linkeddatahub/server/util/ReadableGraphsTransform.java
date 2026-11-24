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

import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Deque;
import java.util.List;
import java.util.Set;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.function.Supplier;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.apache.jena.graph.Node;
import org.apache.jena.graph.Triple;
import org.apache.jena.query.Query;
import org.apache.jena.sparql.algebra.Algebra;
import org.apache.jena.sparql.algebra.Op;
import org.apache.jena.sparql.algebra.OpAsQuery;
import org.apache.jena.sparql.algebra.OpVisitor;
import org.apache.jena.sparql.algebra.OpVisitorBase;
import org.apache.jena.sparql.algebra.TransformCopy;
import org.apache.jena.sparql.algebra.Transformer;
import org.apache.jena.sparql.algebra.op.OpBGP;
import org.apache.jena.sparql.algebra.op.OpDatasetNames;
import org.apache.jena.sparql.algebra.op.OpExt;
import org.apache.jena.sparql.algebra.op.OpFilter;
import org.apache.jena.sparql.algebra.op.OpGraph;
import org.apache.jena.sparql.algebra.op.OpPath;
import org.apache.jena.sparql.algebra.op.OpProcedure;
import org.apache.jena.sparql.algebra.op.OpPropFunc;
import org.apache.jena.sparql.algebra.op.OpQuad;
import org.apache.jena.sparql.algebra.op.OpQuadBlock;
import org.apache.jena.sparql.algebra.op.OpQuadPattern;
import org.apache.jena.sparql.algebra.op.OpTable;
import org.apache.jena.sparql.algebra.op.OpTriple;
import org.apache.jena.sparql.core.BasicPattern;
import org.apache.jena.sparql.core.Quad;
import org.apache.jena.sparql.core.Var;
import org.apache.jena.sparql.expr.E_Exists;
import org.apache.jena.sparql.expr.E_NotExists;
import org.apache.jena.sparql.expr.Expr;
import org.apache.jena.sparql.expr.ExprFunctionOp;
import org.apache.jena.sparql.expr.ExprList;
import org.apache.jena.sparql.expr.ExprTransform;
import org.apache.jena.sparql.expr.ExprTransformCopy;
import org.apache.jena.sparql.expr.NodeValue;
import org.apache.jena.sparql.syntax.Element;
import org.apache.jena.sparql.syntax.ElementFilter;
import org.apache.jena.sparql.syntax.ElementGroup;
import org.apache.jena.sparql.syntax.ElementNamedGraph;
import org.apache.jena.sparql.syntax.ElementPathBlock;
import org.apache.jena.sparql.syntax.syntaxtransform.ElementTransformCopyBase;
import org.apache.jena.sparql.syntax.syntaxtransform.ElementTransformer;
import org.apache.jena.vocabulary.RDF;

/**
 * Rewrites a query so that it reads only the graphs an agent may read: every place a graph is read is joined with the
 * condition of {@link Grants#guard(Node, Supplier)} on that graph, so the store answers the query as if it held only
 * those graphs. The rewrite works on the query's algebra, where each pattern that reads data is a node of its own, and
 * keeps track of the graph each one reads, the way the quad form of the algebra does:
 * <ul>
 * <li><code>GRAPH g { … }</code>, with <code>g</code> a variable or an IRI, and <code>GRAPH ?g {}</code>, which only
 * lists graph names, are filtered by the condition on <code>g</code>.</li>
 * <li>The default graph holds no documents and no authorization can name it, so a pattern over it has no solutions -
 * unless the request's dataset description builds it from graphs the agent may read, which the caller checks
 * ({@link Authorizer#readable(List, Grants)}).</li>
 * <li>A property function the service declares (<code>sd:propertyFeature</code>, such as a text index's
 * <code>text:query</code>) reads an index rather than a graph, inside <code>GRAPH</code> or out of it, so its subject
 * has to be described in a graph the agent may read.</li>
 * <li><code>SERVICE</code> is left as it is: the remote endpoint decides what it answers.</li>
 * </ul>
 * The union graph is refused: a pattern over it has no one graph to check.
 * <p>
 * The output is standard SPARQL 1.1 - <code>FILTER</code>, <code>EXISTS</code>, <code>VALUES</code> and
 * <code>STRSTARTS</code> - so the rewrite does not depend on the store.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ReadableGraphsTransform extends TransformCopy
{

    private static final Pattern VARIABLE = Pattern.compile("[?$]([\\p{L}\\p{N}_]+)");

    private final Grants grants;
    private final boolean defaultGraphReadable;
    private final Set<Node> propertyFeatures;
    private final Supplier<String> prefixes;
    private final Deque<Node> graphs;

    /**
     * Constructs the transform.
     *
     * @param grants what the agent may read
     * @param defaultGraphReadable true if the default graph is built from graphs the agent may read
     * @param propertyFeatures the property functions the service declares
     * @param prefixes supplies variable prefixes that no variable of the query starts with
     * @param graphs the graph each pattern reads, innermost first; the visitors of {@link #rewrite} keep it
     */
    protected ReadableGraphsTransform(Grants grants, boolean defaultGraphReadable, Set<Node> propertyFeatures, Supplier<String> prefixes, Deque<Node> graphs)
    {
        this.grants = grants;
        this.defaultGraphReadable = defaultGraphReadable;
        this.propertyFeatures = propertyFeatures;
        this.prefixes = prefixes;
        this.graphs = graphs;
    }

    /**
     * Returns the query rewritten to read only the graphs the grants reach. The query form, its projection and its
     * solution modifiers are kept; only the pattern changes. The query's own <code>FROM</code> and
     * <code>FROM NAMED</code> are kept too: the caller decides the dataset (see {@link Authorizer#readable(List, Grants)}).
     *
     * @param query query
     * @param grants what the agent may read
     * @param defaultGraphReadable true if the default graph is built from graphs the agent may read
     * @param propertyFeatures the property functions the service declares
     * @return rewritten query
     * @throws IllegalArgumentException if the query reads the union graph
     */
    public static Query rewrite(Query query, Grants grants, boolean defaultGraphReadable, Set<Node> propertyFeatures)
    {
        if (query == null) throw new IllegalArgumentException("Query cannot be null");
        if (grants == null) throw new IllegalArgumentException("Grants cannot be null");
        if (propertyFeatures == null) throw new IllegalArgumentException("Property features cannot be null");

        Query rewritten = query.cloneQuery();
        if (query.getQueryPattern() == null) return rewritten; // DESCRIBE <uri> reads the default graph only, which the caller decides

        Deque<Node> graphs = new ArrayDeque<>();
        graphs.push(Quad.defaultGraphNodeGenerated);
        OpVisitor before = new OpVisitorBase()
        {
            @Override
            public void visit(OpGraph opGraph)
            {
                graphs.push(opGraph.getNode());
            }
        };
        OpVisitor after = new OpVisitorBase()
        {
            @Override
            public void visit(OpGraph opGraph)
            {
                graphs.pop();
            }
        };

        ReadableGraphsTransform transform = new ReadableGraphsTransform(grants, defaultGraphReadable, propertyFeatures, prefixes(query), graphs);
        Op op = Transformer.transformSkipService(transform, null, Algebra.compile(query.getQueryPattern()), before, after);
        rewritten.setQueryPattern(ElementTransformer.transform(OpAsQuery.asElement(op), new ElementTransformCopyBase(), GROUPED_PATTERNS));
        return rewritten;
    }

    /**
     * Wraps the pattern of every <code>EXISTS</code> and <code>NOT EXISTS</code> in a group. Converting algebra back to
     * syntax can give a pattern that is a single <code>GRAPH</code> block, which serializes as
     * <code>NOT EXISTS GRAPH ?g { … }</code>, and that is not SPARQL.
     */
    private static final ExprTransform GROUPED_PATTERNS = new ExprTransformCopy()
    {
        @Override
        public Expr transform(ExprFunctionOp funcOp, ExprList args, Op opArg)
        {
            Element pattern = ElementTransformer.transform(funcOp.getElement(), new ElementTransformCopyBase(), this);
            if (!(pattern instanceof ElementGroup))
            {
                ElementGroup group = new ElementGroup();
                group.addElement(pattern);
                pattern = group;
            }

            return funcOp instanceof E_NotExists ? new E_NotExists(pattern) : new E_Exists(pattern);
        }
    };

    /**
     * Returns a supplier of variable prefixes that no variable of the query starts with, so that the variables of the
     * conditions added to it cannot capture any of its own. Every variable is written as <code>?name</code> or
     * <code>$name</code> in the query's text, so a prefix that starts none of those words starts no variable.
     *
     * @param query query
     * @return prefix supplier
     */
    public static Supplier<String> prefixes(Query query)
    {
        List<String> names = new ArrayList<>();
        Matcher matcher = VARIABLE.matcher(query.serialize());
        while (matcher.find()) names.add(matcher.group(1));

        String stem = "acl";
        while (true)
        {
            String candidate = stem;
            if (names.stream().noneMatch(name -> name.startsWith(candidate))) break;
            stem = stem + "_";
        }

        String prefix = stem;
        AtomicInteger counter = new AtomicInteger();
        return () -> prefix + counter.incrementAndGet() + "_";
    }

    @Override
    public Op transform(OpGraph opGraph, Op subOp)
    {
        Node graph = opGraph.getNode();
        if (Quad.isUnionGraph(graph)) throw new IllegalArgumentException("The union graph is not readable through this endpoint; use GRAPH ?g instead");
        if (Quad.isDefaultGraph(graph)) return super.transform(opGraph, subOp); // its patterns were decided as default graph ones

        return guard(graph, super.transform(opGraph, subOp));
    }

    @Override
    public Op transform(OpDatasetNames opDatasetNames)
    {
        Node graph = opDatasetNames.getGraphNode();
        if (Quad.isUnionGraph(graph)) throw new IllegalArgumentException("The union graph is not readable through this endpoint; use GRAPH ?g instead");

        return guard(graph, super.transform(opDatasetNames));
    }

    @Override
    public Op transform(OpBGP opBGP)
    {
        List<Triple> triples = opBGP.getPattern().getList();
        if (triples.isEmpty()) return super.transform(opBGP);

        boolean data = triples.stream().anyMatch(triple -> !isPropertyFeature(triple) && !isListOfPropertyFeature(triples, triple));
        if (data && !isGraphReadable()) return OpTable.empty();

        Op op = super.transform(opBGP);
        for (Triple triple : triples)
            if (isPropertyFeature(triple))
            {
                Expr described = described(subject(triples, triple.getSubject()));
                if (described.equals(NodeValue.FALSE)) return OpTable.empty();
                op = OpFilter.filter(described, op);
            }

        return op;
    }

    @Override
    public Op transform(OpTriple opTriple)
    {
        return transform(new OpBGP(BasicPattern.wrap(List.of(opTriple.getTriple()))));
    }

    @Override
    public Op transform(OpPath opPath)
    {
        if (!isGraphReadable()) return OpTable.empty();

        return super.transform(opPath);
    }

    @Override
    public Op transform(OpQuadPattern opQuadPattern)
    {
        throw new IllegalArgumentException("Quad patterns are not expected in a query's algebra");
    }

    @Override
    public Op transform(OpQuadBlock opQuadBlock)
    {
        throw new IllegalArgumentException("Quad blocks are not expected in a query's algebra");
    }

    @Override
    public Op transform(OpQuad opQuad)
    {
        throw new IllegalArgumentException("Quads are not expected in a query's algebra");
    }

    @Override
    public Op transform(OpPropFunc opPropFunc, Op subOp)
    {
        throw new IllegalArgumentException("Property functions are not expected in a query's algebra before optimization");
    }

    @Override
    public Op transform(OpProcedure opProc, Op subOp)
    {
        throw new IllegalArgumentException("Procedures are not supported");
    }

    @Override
    public Op transform(OpExt opExt)
    {
        throw new IllegalArgumentException("Algebra extensions are not supported");
    }

    /**
     * Returns the operation filtered by the condition on the graph, or no solutions if no graph can meet it.
     *
     * @param graph graph node
     * @param op operation that reads the graph
     * @return filtered operation
     */
    protected Op guard(Node graph, Op op)
    {
        Expr guard = getGrants().guard(graph, getPrefixes());
        if (guard.equals(NodeValue.FALSE)) return OpTable.empty();

        return OpFilter.filter(guard, op);
    }

    /**
     * Returns the condition that a resource is described in a graph the agent may read: what a property function that
     * reads an index finds has to be there too.
     *
     * @param subject the resource
     * @return boolean expression
     */
    protected Expr described(Node subject)
    {
        if (getGrants().isEmpty()) return NodeValue.FALSE;

        String prefix = getPrefixes().get();
        Var graph = Var.alloc(prefix + "g");
        ElementPathBlock triple = new ElementPathBlock();
        triple.addTriple(Triple.create(subject, Var.alloc(prefix + "p"), Var.alloc(prefix + "o")));

        ElementGroup group = new ElementGroup();
        group.addElement(new ElementNamedGraph(graph, triple));
        group.addElement(new ElementFilter(getGrants().guard(graph, getPrefixes())));
        return new E_Exists(group);
    }

    /**
     * Returns the resource a property function is about: its subject, or the first member of its subject list,
     * <code>(?s ?score) text:query "…"</code>, whose list nodes the same pattern describes.
     *
     * @param triples the pattern
     * @param subject the property function's subject
     * @return resource node
     */
    protected Node subject(List<Triple> triples, Node subject)
    {
        return triples.stream().
            filter(triple -> triple.getSubject().equals(subject) && triple.getPredicate().equals(RDF.first.asNode())).
            map(Triple::getObject).
            findFirst().
            orElse(subject);
    }

    /**
     * Returns true if the triple calls a property function the service declares.
     *
     * @param triple triple
     * @return true for a property function
     */
    protected boolean isPropertyFeature(Triple triple)
    {
        return getPropertyFeatures().contains(triple.getPredicate());
    }

    /**
     * Returns true if the triple is part of the argument list of a property function the service declares: an
     * <code>rdf:first</code> or <code>rdf:rest</code> triple of a list node another one reaches from its subject.
     *
     * @param triples the pattern
     * @param triple triple
     * @return true for a list triple of a property function
     */
    protected boolean isListOfPropertyFeature(List<Triple> triples, Triple triple)
    {
        if (!triple.getPredicate().equals(RDF.first.asNode()) && !triple.getPredicate().equals(RDF.rest.asNode())) return false;

        for (Triple call : triples)
            if (isPropertyFeature(call))
                for (Node node = call.getSubject(); node != null; node = rest(triples, node))
                    if (node.equals(triple.getSubject())) return true;

        return false;
    }

    /**
     * Returns the next node of a list the pattern describes, or null at its end.
     *
     * @param triples the pattern
     * @param node a list node
     * @return the next list node
     */
    private static Node rest(List<Triple> triples, Node node)
    {
        return triples.stream().
            filter(triple -> triple.getSubject().equals(node) && triple.getPredicate().equals(RDF.rest.asNode()) && !triple.getObject().equals(RDF.nil.asNode())).
            map(Triple::getObject).
            findFirst().
            orElse(null);
    }

    /**
     * Returns true if the graph the current pattern reads may be read as far as the dataset goes: a named graph is
     * checked by the condition on <code>GRAPH</code>, the default graph only by the caller.
     *
     * @return true unless the pattern reads an unreadable default graph
     */
    protected boolean isGraphReadable()
    {
        return !Quad.isDefaultGraph(getGraphs().peek()) || isDefaultGraphReadable();
    }

    /**
     * Returns what the agent may read.
     *
     * @return grants
     */
    public Grants getGrants()
    {
        return grants;
    }

    /**
     * Returns true if the default graph is built from graphs the agent may read.
     *
     * @return true for a readable default graph
     */
    public boolean isDefaultGraphReadable()
    {
        return defaultGraphReadable;
    }

    /**
     * Returns the property functions the service declares.
     *
     * @return property function IRIs
     */
    public Set<Node> getPropertyFeatures()
    {
        return propertyFeatures;
    }

    /**
     * Returns the supplier of variable prefixes.
     *
     * @return prefix supplier
     */
    public Supplier<String> getPrefixes()
    {
        return prefixes;
    }

    /**
     * Returns the graph each pattern reads, innermost first.
     *
     * @return graph stack
     */
    public Deque<Node> getGraphs()
    {
        return graphs;
    }

}
