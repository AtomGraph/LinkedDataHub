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
package com.atomgraph.linkeddatahub.resource.namespace;

import javax.ws.rs.core.Context;
import javax.ws.rs.core.Request;
import javax.ws.rs.core.Response;
import javax.ws.rs.ext.Providers;
import com.atomgraph.core.MediaTypes;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.client.util.DataManager;
import com.atomgraph.linkeddatahub.server.model.impl.GraphStoreImpl;
import com.atomgraph.linkeddatahub.server.util.OntologyLoader;
import com.atomgraph.linkeddatahub.server.util.SPARQLClientOntologyLoader;
import com.atomgraph.processor.model.TemplateCall;
import java.net.URI;
import java.util.Optional;
import javax.inject.Inject;
import javax.servlet.ServletConfig;
import javax.ws.rs.DefaultValue;
import javax.ws.rs.QueryParam;
import javax.ws.rs.core.UriInfo;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.ResourceFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS resource that handles namespace item requests.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class Item extends GraphStoreImpl
{

    private static final Logger log = LoggerFactory.getLogger(Item.class);

    private final URI uri;
    private final com.atomgraph.linkeddatahub.apps.model.Application application;
    private final OntologyLoader ontLoader;
    
    @Inject
    public Item(@Context UriInfo uriInfo, @Context Request request, Optional<Service> service, MediaTypes mediaTypes,
            Optional<com.atomgraph.linkeddatahub.apps.model.Application> application, Optional<Ontology> ontology, Optional<TemplateCall> templateCall,
            DataManager dataManager,
            @Context Providers providers, com.atomgraph.linkeddatahub.Application system, @Context ServletConfig servletConfig)
    {
        super(request, service, mediaTypes, uriInfo, providers, system);
        this.uri = uriInfo.getAbsolutePath();
        this.application = application.get();
        if (log.isDebugEnabled()) log.debug("Constructing {}", getClass());

        ontLoader = new SPARQLClientOntologyLoader(system.getOntModelSpec(), system.getSitemapQuery());
    }
    
    @Override
    public Response get(@QueryParam("default") @DefaultValue("false") Boolean defaultGraph, @QueryParam("graph") URI graphUri)
    {
        //Resource ontology = getOntResource().getPropertyResourceValue(FOAF.primaryTopic);
        // hard-coding "#" is not great but it does not seem possible to construct the ontology URI in aplt:SubOntology query
        Resource ontology = ResourceFactory.createResource(getURI().toString() + "#");

        final Model model;
        if (getApplication().canAs(EndUserApplication.class))
            model = getOntologyLoader().getModel(getApplication().as(EndUserApplication.class).getAdminApplication().getService(), ontology.getURI());
        else
            model = getOntologyLoader().getModel(getApplication().getService(), ontology.getURI());
        
        return getResponse(model);
    }
    
    
    public URI getURI()
    {
        return uri;
    }
 
    public com.atomgraph.linkeddatahub.apps.model.Application getApplication()
    {
        return application;
    }
    
    public OntologyLoader getOntologyLoader()
    {
        return ontLoader;
    }
    
}