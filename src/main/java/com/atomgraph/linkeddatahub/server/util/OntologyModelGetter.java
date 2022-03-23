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
import com.atomgraph.core.io.ModelProvider;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import com.atomgraph.processor.exception.OntologyException;
import javax.ws.rs.client.Client;
import javax.ws.rs.core.Response;
import org.apache.jena.ontology.OntModelSpec;
import org.apache.jena.query.ParameterizedSparqlString;
import org.apache.jena.query.Query;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.ModelReader;
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
    private final Client client;
    private final javax.ws.rs.core.MediaType[] acceptedTypes;
    
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
        this(app, ontModelSpec, ontologyQuery, client, mediaTypes.getReadable(Model.class).toArray(javax.ws.rs.core.MediaType[]::new));
    }
    
    /**
     * Constructs ontology getter for application.
     * 
     * @param app end-user application resource
     * @param ontModelSpec ontology specification
     * @param ontologyQuery SPARQL query that loads ontology terms
     * @param client HTTP client
     * @param acceptedTypes accepted media types
     */
    public OntologyModelGetter(EndUserApplication app, OntModelSpec ontModelSpec, Query ontologyQuery, Client client, javax.ws.rs.core.MediaType[] acceptedTypes)
    {
        this.app = app;
        this.ontModelSpec = ontModelSpec;
        this.ontologyQuery = ontologyQuery;
        this.client = client;
        this.acceptedTypes = acceptedTypes;
    }

    @Override
    public Model getModel(String uri)
    {
        // attempt to load ontology graph from the admin endpoint. TO-DO: is that necessary if ontologies terms are now stored in a single graph?
        ParameterizedSparqlString ontologyPss = new ParameterizedSparqlString(getOntologyQuery().toString());
        ontologyPss.setIri(LDT.ontology.getLocalName(), uri);
        Model model = getApplication().getAdminApplication().getService().getSPARQLClient().loadModel(ontologyPss.asQuery());

        // if it's empty, fallback to dereferencing the ontology URI
        if (model.isEmpty())
        {
            // TO-DO: use LinkedDataClient
            if (log.isDebugEnabled()) log.debug("Loading Ontology <{}>", uri);
            try (Response cr = getClient().target(uri).
                    request(getAcceptableMediaTypes()).
                    get())
            {
                if (!cr.getStatusInfo().getFamily().equals(Response.Status.Family.SUCCESSFUL))
                {
                    if (log.isErrorEnabled()) log.error("Could not load ontology from URI: <{}>", uri);
                    // TO-DO: replace with Jena's OntologyException
                    throw new OntologyException("Could not load ontology from URI <" + uri + ">");
                }
                
                cr.getHeaders().putSingle(ModelProvider.REQUEST_URI_HEADER, uri); // provide a base URI hint to ModelProvider
                return cr.readEntity(Model.class);
            }
            catch (Exception ex)
            {
                if (log.isErrorEnabled()) log.error("Could not load ontology from URI: <{}>", uri);
                // TO-DO: replace with Jena's OntologyException
                throw new OntologyException("Could not load ontology from URI <" + uri + ">");
            }
        }

        return model;
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

    /**
     * Returns HTTP client.
     * 
     * @return client
     */
    public Client getClient()
    {
        return client;
    }
    
    /**
     * Returns readable media types.
     * 
     * @return media types
     */
    public javax.ws.rs.core.MediaType[] getAcceptableMediaTypes()
    {
        return acceptedTypes;
    }
    
}