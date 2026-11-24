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
import com.atomgraph.linkeddatahub.vocabulary.LDHC;
import java.io.StringReader;
import java.nio.file.Path;
import java.util.List;
import java.util.Map;
import java.util.Set;
import javax.xml.parsers.DocumentBuilderFactory;
import org.apache.jena.graph.NodeFactory;
import org.apache.jena.query.Dataset;
import org.apache.jena.query.DatasetFactory;
import org.apache.jena.query.Query;
import org.apache.jena.query.QueryExecution;
import org.apache.jena.query.QueryFactory;
import org.apache.jena.query.ResultSetFactory;
import org.apache.jena.query.ResultSetRewindable;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.riot.Lang;
import org.apache.jena.riot.RDFParser;
import org.apache.jena.sparql.resultset.ResultsCompare;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * The rewritten query answers over the whole store as the original query does over the graphs the agent may read:
 * <code>⟦rewrite Q⟧ S = ⟦Q⟧ (S ↾ readable)</code>, for the query shapes the client sends and the SPARQL forms around them.
 * The store holds a readable document, an unreadable one beside it in the same container, and the container.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ReadableGraphsTransformTest
{

    private static final String BASE = "https://localhost:4443/";
    private static final String CONTAINER = BASE + "container/";
    private static final String READABLE = CONTAINER + "readable/";
    private static final String UNREADABLE = CONTAINER + "unreadable/";
    private static final String OTHER_DATASPACE = "https://other.localhost:4443/item/";

    private static final String PREFIXES = """
        PREFIX dct:  <http://purl.org/dc/terms/>
        PREFIX sioc: <http://rdfs.org/sioc/ns#>
        PREFIX dh:   <https://w3id.org/atomgraph/linkeddatahub/document-hierarchy#>
        PREFIX foaf: <http://xmlns.com/foaf/0.1/>
        """;

    /** The client's query shapes, and the SPARQL forms a query can read a graph through. */
    private static final List<String> QUERIES = List.of(
        // drawer: type counts, over the default graph and the named ones
        "SELECT DISTINCT ?type (COUNT(?s) AS ?count) { { ?s a ?type } UNION { GRAPH ?g { ?s a ?type } } } GROUP BY ?type ORDER BY DESC(COUNT(?s)) LIMIT 10",
        // drawer: latest resources
        "SELECT DISTINCT ?dated { GRAPH ?graph { ?dated dct:created ?created } } ORDER BY DESC(?created)",
        // container children
        "SELECT DISTINCT ?child { GRAPH ?childGraph { { ?child sioc:has_parent <" + CONTAINER + "> } UNION { ?child sioc:has_container <" + CONTAINER + "> } ?child a ?Type OPTIONAL { ?child dct:title ?title } } } ORDER BY ?title",
        // one document, readable and not
        "SELECT ?p ?o { GRAPH <" + READABLE + "> { ?s ?p ?o } }",
        "SELECT ?p ?o { GRAPH <" + UNREADABLE + "> { ?s ?p ?o } }",
        // backlinks
        "DESCRIBE ?subject { { ?subject ?p <" + CONTAINER + "> } UNION { GRAPH ?g { ?subject ?p <" + CONTAINER + "> } } }",
        // regex search
        "SELECT DISTINCT ?s { GRAPH ?g { ?s dct:title ?t FILTER regex(?t, \"secret\", \"i\") } }",
        // graph names
        "SELECT ?g { GRAPH ?g { } }",
        "SELECT ?g { GRAPH ?g { ?g a ?type } }",
        // patterns that span graphs
        "SELECT ?s ?t { GRAPH ?g { ?s a dh:Item } OPTIONAL { GRAPH ?h { ?s dct:title ?t } } }",
        "SELECT ?s { GRAPH ?g { ?s a dh:Item } FILTER NOT EXISTS { GRAPH ?h { ?x foaf:knows ?s } } }",
        "SELECT ?s { GRAPH ?g { ?s a dh:Item } MINUS { GRAPH ?h { ?s dct:title \"secret\" } } }",
        "SELECT ?s ?r { GRAPH ?g { ?s ?p ?o GRAPH ?h { ?r foaf:knows ?s } } }",
        "SELECT ?g (COUNT(*) AS ?n) { { SELECT ?g ?s { GRAPH ?g { ?s ?p ?o } } } } GROUP BY ?g",
        "SELECT ?x ?y { GRAPH ?g { ?x dct:title/^dct:title ?y } }",
        "SELECT ?s { VALUES ?g { <" + READABLE + "> <" + UNREADABLE + "> } GRAPH ?g { ?s ?p ?o } }",
        "SELECT ?s { BIND(<" + UNREADABLE + "> AS ?g) GRAPH ?g { ?s ?p ?o } }",
        "SELECT ?Rel ?Target ?this { GRAPH ?g { ?Rel ?Target ?this } }",
        "CONSTRUCT { ?s ?p ?o } WHERE { GRAPH ?g { ?s ?p ?o } }",
        "ASK { GRAPH <" + UNREADABLE + "> { ?s ?p ?o } }",
        "ASK { GRAPH ?g { ?s dct:title \"secret\" } }"
    );

    private Dataset store, readable;
    private Grants grants;

    @BeforeEach
    public void load() throws Exception
    {
        org.w3c.dom.Document webXml = DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(Path.of("src/main/webapp/WEB-INF/web.xml").toFile());
        Query contextQuery = QueryFactory.create(param(webXml, LDHC.documentContextQuery.getURI()));

        String trig = String.format("""
            @prefix dh:   <https://w3id.org/atomgraph/linkeddatahub/document-hierarchy#> .
            @prefix dct:  <http://purl.org/dc/terms/> .
            @prefix sioc: <http://rdfs.org/sioc/ns#> .
            @prefix foaf: <http://xmlns.com/foaf/0.1/> .
            @prefix xsd:  <http://www.w3.org/2001/XMLSchema#> .
            <%1$s> { <%1$s> a dh:Container ; dct:title "container" ; dct:created "2026-01-01T00:00:00Z"^^xsd:dateTime . }
            <%2$s> { <%2$s> a dh:Item ; sioc:has_container <%1$s> ; dct:title "public" ; dct:created "2026-01-02T00:00:00Z"^^xsd:dateTime ;
                         foaf:knows <%3$s> . }
            <%3$s> { <%3$s> a dh:Item ; sioc:has_container <%1$s> ; dct:title "secret" ; dct:created "2026-01-03T00:00:00Z"^^xsd:dateTime ;
                         foaf:knows <%2$s> . }
            <%4$s> { <%4$s> a dh:Item ; dct:title "secret" . }
            """, CONTAINER, READABLE, UNREADABLE, OTHER_DATASPACE);
        store = DatasetFactory.create();
        RDFParser.create().source(new StringReader(trig)).lang(Lang.TRIG).parse(store);

        // the agent may read the readable document and, through its class, the container; not the document beside it,
        // and not the other dataspace's item, which is of a class it may read too
        grants = new Grants(contextQuery.getQueryPattern(), BASE, false,
            List.of(new Grants.Row(ACL.accessTo.asNode(), NodeFactory.createURI(READABLE)),
                new Grants.Row(ACL.accessToClass.asNode(), NodeFactory.createURI("https://w3id.org/atomgraph/linkeddatahub/document-hierarchy#Container"))),
            Map.of());

        readable = DatasetFactory.create();
        for (String graph : new String[] { CONTAINER, READABLE }) readable.addNamedModel(graph, store.getNamedModel(graph));
    }

    private static String param(org.w3c.dom.Document webXml, String name)
    {
        NodeList params = webXml.getElementsByTagName("context-param");
        for (int i = 0; i < params.getLength(); i++)
        {
            Element param = (Element)params.item(i);
            if (param.getElementsByTagName("param-name").item(0).getTextContent().trim().equals(name))
                return param.getElementsByTagName("param-value").item(0).getTextContent();
        }
        throw new IllegalStateException(name + " is not configured");
    }

    /** Rewrites the query and parses the text, which is what the store receives. */
    private Query rewrite(Query query)
    {
        return QueryFactory.create(ReadableGraphsTransform.rewrite(query, grants, false, Set.of()).toString());
    }

    @Test
    public void rewrittenQueryAnswersAsOverTheReadableGraphs()
    {
        for (String text : QUERIES)
        {
            Query query = QueryFactory.create(PREFIXES + text);
            Query rewritten = rewrite(query);
            assertEquals(query.queryType(), rewritten.queryType(), text);
            assertEquals(query.getProjectVars(), rewritten.getProjectVars(), text);

            try (QueryExecution expected = QueryExecution.create(query, readable); QueryExecution actual = QueryExecution.create(rewritten, store))
            {
                if (query.isSelectType())
                {
                    ResultSetRewindable e = ResultSetFactory.makeRewindable(expected.execSelect()), a = ResultSetFactory.makeRewindable(actual.execSelect());
                    boolean equal = query.isOrdered() ? ResultsCompare.equalsByTermAndOrder(e, a) : ResultsCompare.equalsByTerm(e, a);
                    assertTrue(equal, text + "\n" + rewritten);
                }
                if (query.isAskType()) assertEquals(expected.execAsk(), actual.execAsk(), text + "\n" + rewritten);
                if (query.isConstructType() || query.isDescribeType())
                {
                    Model e = query.isConstructType() ? expected.execConstruct() : expected.execDescribe();
                    Model a = query.isConstructType() ? actual.execConstruct() : actual.execDescribe();
                    assertTrue(e.isIsomorphicWith(a), text + "\n" + rewritten);
                }
            }
        }
    }

    @Test
    public void unionGraphIsRefused()
    {
        assertThrows(IllegalArgumentException.class, () -> rewrite(QueryFactory.create("SELECT * { GRAPH <urn:x-arq:UnionGraph> { ?s ?p ?o } }")));
        assertThrows(IllegalArgumentException.class, () -> rewrite(QueryFactory.create("SELECT * { GRAPH <urn:x-arq:UnionGraph> { } }")));
    }

    @Test
    public void serviceIsLeftAsItIs()
    {
        Query query = QueryFactory.create("SELECT * { SERVICE <https://example.org/sparql> { ?s ?p ?o } }");
        assertEquals(query.getQueryPattern().toString(), rewrite(query).getQueryPattern().toString());
    }

    @Test
    public void noGrantsReadNothing()
    {
        grants = new Grants(grants.getContext(), BASE, false, List.of(), Map.of());
        try (QueryExecution qex = QueryExecution.create(rewrite(QueryFactory.create("SELECT * { GRAPH ?g { ?s ?p ?o } }")), store))
        {
            assertTrue(!qex.execSelect().hasNext());
        }
    }

    @Test
    public void publicDataspaceReadsItsOwnGraphsOnly()
    {
        grants = new Grants(grants.getContext(), BASE, true, List.of(), Map.of());
        try (QueryExecution qex = QueryExecution.create(rewrite(QueryFactory.create("SELECT DISTINCT ?g { GRAPH ?g { ?s ?p ?o } }")), store))
        {
            Set<String> graphs = new java.util.HashSet<>();
            qex.execSelect().forEachRemaining(row -> graphs.add(row.getResource("g").getURI()));
            assertEquals(Set.of(CONTAINER, READABLE, UNREADABLE), graphs);
        }
    }

}
