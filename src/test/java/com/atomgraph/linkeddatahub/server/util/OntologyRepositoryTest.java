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

import com.atomgraph.core.client.GraphStoreClient;
import com.atomgraph.linkeddatahub.apps.model.AdminApplication;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.model.ServiceContext;
import jakarta.ws.rs.core.MultivaluedMap;
import jakarta.ws.rs.core.Response;
import org.apache.jena.graph.Graph;
import org.apache.jena.graph.NodeFactory;
import org.apache.jena.query.Query;
import org.apache.jena.query.QueryFactory;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.vocabulary.OWL;
import org.apache.jena.vocabulary.RDF;
import org.apache.jena.vocabulary.RDFS;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Characterization tests for {@link OntologyRepository}, which resolves an ontology graph
 * SPARQL-first (admin endpoint CONSTRUCT) and falls back to the superclass (bundled mapping / HTTP)
 * only when the SPARQL result is empty.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@ExtendWith(MockitoExtension.class)
public class OntologyRepositoryTest
{

    private static final String ONTOLOGY_URI = "http://example.org/ontology#";
    private static final Query ONTOLOGY_QUERY = QueryFactory.create("CONSTRUCT { ?ontology ?p ?o } WHERE { ?ontology ?p ?o }");

    @Mock com.atomgraph.linkeddatahub.Application system;
    @Mock EndUserApplication app;
    @Mock AdminApplication adminApp;
    @Mock Service service;
    @Mock ServiceContext serviceContext;
    @Mock com.atomgraph.core.client.SPARQLClient sparqlClient;
    @Mock Response response;
    @Mock GraphStoreClient gsc;

    private void stubSPARQLChain(Model sparqlResult)
    {
        when(app.getAdminApplication()).thenReturn(adminApp);
        when(adminApp.getService()).thenReturn(service);
        when(system.getServiceContext(service)).thenReturn(serviceContext);
        when(serviceContext.getSPARQLClient()).thenReturn(sparqlClient);
        when(sparqlClient.query(any(Query.class), eq(Model.class), any(MultivaluedMap.class), any(MultivaluedMap.class))).thenReturn(response);
        when(response.readEntity(Model.class)).thenReturn(sparqlResult);
    }

    /** A non-empty admin SPARQL CONSTRUCT result is returned directly; the HTTP fallback is not used. */
    @Test
    public void testSPARQLResultUsedWhenNonEmpty()
    {
        Model sparqlResult = ModelFactory.createDefaultModel();
        sparqlResult.createResource(ONTOLOGY_URI).addProperty(RDF.type, OWL.Ontology);
        stubSPARQLChain(sparqlResult);

        OntologyRepository repository = new OntologyRepository(app, system, gsc, ONTOLOGY_QUERY);
        Graph result = repository.get(ONTOLOGY_URI);

        assertTrue(result.contains(NodeFactory.createURI(ONTOLOGY_URI), RDF.type.asNode(), OWL.Ontology.asNode()));
        verify(gsc, never()).getModel(any());
    }

    /** An empty SPARQL result falls back to the Graph Store client (HTTP) load. */
    @Test
    public void testFallsBackToHttpWhenSPARQLEmpty()
    {
        Model empty = ModelFactory.createDefaultModel();
        stubSPARQLChain(empty);

        Model fallback = ModelFactory.createDefaultModel();
        fallback.createResource(ONTOLOGY_URI).addProperty(RDFS.label, "fallback");
        when(gsc.getModel(ONTOLOGY_URI)).thenReturn(fallback);

        OntologyRepository repository = new OntologyRepository(app, system, gsc, ONTOLOGY_QUERY);
        Graph result = repository.get(ONTOLOGY_URI);

        assertTrue(result.contains(NodeFactory.createURI(ONTOLOGY_URI), RDFS.label.asNode(), NodeFactory.createLiteralString("fallback")));
    }

}
