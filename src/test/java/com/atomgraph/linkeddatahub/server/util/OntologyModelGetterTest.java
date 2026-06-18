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

import com.atomgraph.core.client.SPARQLClient;
import com.atomgraph.linkeddatahub.apps.model.AdminApplication;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.model.ServiceContext;
import jakarta.ws.rs.core.MultivaluedMap;
import jakarta.ws.rs.core.Response;
import org.apache.jena.ontology.OntModelSpec;
import org.apache.jena.query.Query;
import org.apache.jena.query.QueryFactory;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.util.FileManager;
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
 * Characterization tests for {@link OntologyModelGetter}, which resolves an ontology model
 * SPARQL-first (admin endpoint CONSTRUCT) and falls back to the FileManager only when the
 * SPARQL result is empty.
 *
 * Pins the current resolution order so the migration to a {@code GraphRepository.get(uri)}
 * can be proven to retain it.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@ExtendWith(MockitoExtension.class)
public class OntologyModelGetterTest
{

    private static final String ONTOLOGY_URI = "http://example.org/ontology#";
    private static final Query ONTOLOGY_QUERY = QueryFactory.create("CONSTRUCT { ?ontology ?p ?o } WHERE { ?ontology ?p ?o }");

    @Mock com.atomgraph.linkeddatahub.Application system;
    @Mock EndUserApplication app;
    @Mock AdminApplication adminApp;
    @Mock Service service;
    @Mock ServiceContext serviceContext;
    @Mock SPARQLClient sparqlClient;
    @Mock Response response;

    private void stubSPARQLChain(Model sparqlResult)
    {
        when(app.getAdminApplication()).thenReturn(adminApp);
        when(adminApp.getService()).thenReturn(service);
        when(system.getServiceContext(service)).thenReturn(serviceContext);
        when(serviceContext.getSPARQLClient()).thenReturn(sparqlClient);
        when(sparqlClient.query(any(Query.class), eq(Model.class), any(MultivaluedMap.class), any(MultivaluedMap.class))).thenReturn(response);
        when(response.readEntity(Model.class)).thenReturn(sparqlResult);
    }

    /** A non-empty admin SPARQL CONSTRUCT result is returned directly; the FileManager is not consulted. */
    @Test
    public void testSPARQLResultUsedWhenNonEmpty()
    {
        Model sparqlResult = ModelFactory.createDefaultModel();
        sparqlResult.createResource(ONTOLOGY_URI).addProperty(org.apache.jena.vocabulary.RDF.type, org.apache.jena.vocabulary.OWL.Ontology);
        stubSPARQLChain(sparqlResult);

        OntModelSpec spec = new OntModelSpec(OntModelSpec.OWL_MEM);
        FileManager fileManager = org.mockito.Mockito.mock(FileManager.class);
        spec.getDocumentManager().setFileManager(fileManager);

        OntologyModelGetter getter = new OntologyModelGetter(app, system, spec, ONTOLOGY_QUERY);
        Model result = getter.getModel(ONTOLOGY_URI);

        assertSame(sparqlResult, result);
        verify(fileManager, never()).loadModel(any());
    }

    /** An empty SPARQL result falls back to FileManager.loadModel(uri). */
    @Test
    public void testFallsBackToFileManagerWhenSPARQLEmpty()
    {
        Model empty = ModelFactory.createDefaultModel();
        stubSPARQLChain(empty);

        OntModelSpec spec = new OntModelSpec(OntModelSpec.OWL_MEM);
        FileManager fileManager = org.mockito.Mockito.mock(FileManager.class);
        spec.getDocumentManager().setFileManager(fileManager);
        Model fallback = ModelFactory.createDefaultModel();
        fallback.createResource(ONTOLOGY_URI);
        when(fileManager.loadModel(ONTOLOGY_URI)).thenReturn(fallback);

        OntologyModelGetter getter = new OntologyModelGetter(app, system, spec, ONTOLOGY_QUERY);
        Model result = getter.getModel(ONTOLOGY_URI);

        assertSame(fallback, result);
    }

}
