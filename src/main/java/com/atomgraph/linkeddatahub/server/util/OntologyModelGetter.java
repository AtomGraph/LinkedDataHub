/**
 *  Copyright 2022 Martynas Jusevičius <martynas@atomgraph.com>
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

import com.atomgraph.client.vocabulary.LDT;
import com.atomgraph.core.MediaTypes;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import com.atomgraph.processor.exception.OntologyException;
import javax.ws.rs.client.Client;
import org.apache.jena.ontology.OntModelSpec;
import org.apache.jena.query.ParameterizedSparqlString;
import org.apache.jena.query.Query;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.ModelReader;
import org.apache.jena.util.FileManager;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


/**
 * Application's ontology model getter.
 * Loads ontology model using the configured ontology query
 */
public class OntologyModelGetter implements org.apache.jena.rdf.model.ModelGetter
{

    private static final Logger log = LoggerFactory.getLogger(OntologyModelGetter.class);

    private final EndUserApplication app;
    private final OntModelSpec ontModelSpec;
    private final Query ontologyQuery;

    
    /**
     * Constructs ontology getter for application.
     * 
     * @param app end-user application resource
     * @param ontModelSpec ontology specification
     * @param ontologyQuery SPARQL query that loads ontology terms
     * @param client HTTP client
     * @param mediaTypes registry of readable/writable media types
     */
    public OntologyModelGetter(EndUserApplication app, OntModelSpec ontModelSpec, Query ontologyQuery, Client client, MediaTypes mediaTypes)
    {
        this(app, ontModelSpec, ontologyQuery);
    }
    
    /**
     * Constructs ontology getter for application.
     * 
     * @param app end-user application resource
     * @param ontModelSpec ontology specification
     * @param ontologyQuery SPARQL query that loads ontology terms
     */
    public OntologyModelGetter(EndUserApplication app, OntModelSpec ontModelSpec, Query ontologyQuery)
    {
        this.app = app;
        this.ontModelSpec = ontModelSpec;
        this.ontologyQuery = ontologyQuery;
    }

    @Override
    public Model getModel(String uri)
    {
        // attempt to load ontology model from the admin endpoint. TO-DO: is that necessary if ontologies terms are now stored in a single graph?
        ParameterizedSparqlString ontologyPss = new ParameterizedSparqlString(getOntologyQuery().toString());
        ontologyPss.setIri(LDT.ontology.getLocalName(), uri);
        Model model = getApplication().getAdminApplication().getService().getSPARQLClient().loadModel(ontologyPss.asQuery());
        
        if (!model.isEmpty()) return model;

        // if SPARQL result model is empty, fallback to FileManager
        FileManager fileManager = getOntModelSpec().getDocumentManager().getFileManager();
        return fileManager.loadModel(uri, getApplication().getBase().getURI(), null);
    }

    @Override
    public Model getModel(String uri, ModelReader loadIfAbsent) 
    {
        try
        {
            return getModel(uri);
        }
        catch (OntologyException ex)
        {
            return loadIfAbsent.readModel(ModelFactory.createDefaultModel(), uri);
        }
    }

    /**
     * Returns the application.
     * 
     * @return application resource
     */
    public EndUserApplication getApplication()
    {
        return app;
    }

    /**
     * Returns ontology specification.
     * 
     * @return ontology specification
     */
    public OntModelSpec getOntModelSpec()
    {
        return ontModelSpec;
    }

    /**
     * Returns the SPARQL query used to load ontology terms.
     * 
     * @return SPARQL query
     */
    public Query getOntologyQuery()
    {
        return ontologyQuery;
    }
    
}