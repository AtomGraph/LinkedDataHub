/**
 *  Copyright 2019 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.sitemap.resource.ontology;

import org.apache.jena.ontology.OntDocumentManager;
import java.net.URI;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.Request;
import javax.ws.rs.core.Response;
import javax.ws.rs.ext.Providers;
import com.atomgraph.core.MediaTypes;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.client.util.DataManager;
import com.atomgraph.linkeddatahub.server.model.impl.GraphStoreImpl;
import com.atomgraph.linkeddatahub.server.util.SPARQLClientOntologyLoader;
import com.atomgraph.linkeddatahub.vocabulary.LSMT;
import java.util.Optional;
import javax.annotation.PostConstruct;
import javax.inject.Inject;
import javax.ws.rs.DefaultValue;
import javax.ws.rs.GET;
import javax.ws.rs.QueryParam;
import javax.ws.rs.core.UriInfo;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.sparql.vocabulary.FOAF;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS resource that handles ontology item requests.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class Item extends GraphStoreImpl
{

    private static final Logger log = LoggerFactory.getLogger(Item.class);

    private final URI uri;
    private final com.atomgraph.linkeddatahub.apps.model.Application application;
    private final Ontology ontology;
    private final Resource resource;
    
    @Inject
    public Item(@Context UriInfo uriInfo, @Context Request request, Optional<Service> service, MediaTypes mediaTypes,
            Optional<com.atomgraph.linkeddatahub.apps.model.Application> application, Optional<Ontology> ontology,
            DataManager dataManager,
            @Context Providers providers, com.atomgraph.linkeddatahub.Application system)
    {
        super(request, service, mediaTypes, uriInfo, providers, system);
        this.uri = uriInfo.getAbsolutePath();
        this.application = application.get();
        this.ontology = ontology.get();
        this.resource = ModelFactory.createDefaultModel().createResource(uri.toString());
        if (log.isDebugEnabled()) log.debug("Constructing {}", getClass());
    }
    
    @PostConstruct
    public void init()
    {
        getResource().getModel().add(getDatasetAccessor().getModel(getURI().toString()));
    }
    
    @GET
    @Override
    public Response get(@QueryParam("default") @DefaultValue("false") Boolean defaultGraph, @QueryParam("graph") URI graphUri)
    {
        Resource topic = getResource().getPropertyResourceValue(FOAF.primaryTopic); // ontology is the topic
        
        if (getUriInfo().getQueryParameters().containsKey(LSMT.clear.getLocalName())) // this is just a flag, we don't need the argument value. TO-DO: change to post()!
        {
            if (topic == null)
            {
                if (log.isErrorEnabled()) log.error("Cannot clear ontology - no ontology is foaf:primaryTopic of this document: {}", getURI());
                throw new IllegalStateException("Cannot clear ontology - no ontology is foaf:primaryTopic of this document: " + getURI());
            }
            
            String ontologyURI = topic.getURI();
            
            if (OntDocumentManager.getInstance().getFileManager().hasCachedModel(ontologyURI))
            {
                OntDocumentManager.getInstance().getFileManager().removeCacheModel(ontologyURI);
  
                // here be dragons! Without explicitly reloading the cleared ontology here, owl:import with its URI can lead to a request loopback later on
                new SPARQLClientOntologyLoader(getSystem().getOntModelSpec(), getSystem().getSitemapQuery()).
                    getOntology(getApplication(),
                        getApplication().getService(),
                        ontologyURI,
                        getSystem().getOntModelSpec(),
                        getOntology().getOntModel());
            }
//            
//            List<String> referers = getHttpHeaders().getRequestHeader("Referer");
//            if (referers != null && !referers.isEmpty())
//                return Response.seeOther(URI.create(referers.get(0))).build();
        }
        
        return super.get(defaultGraph, getURI());
    }
    
    public URI getURI()
    {
        return uri;
    }
    
    private com.atomgraph.linkeddatahub.apps.model.Application getApplication()
    {
        return application;
    }
    
    public Ontology getOntology()
    {
        return ontology;
    }
    
    public Resource getResource()
    {
        return resource;
    }
    
}