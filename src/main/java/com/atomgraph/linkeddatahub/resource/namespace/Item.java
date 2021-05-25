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
import javax.ws.rs.core.HttpHeaders;
import javax.ws.rs.core.Request;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.SecurityContext;
import javax.ws.rs.ext.Providers;
import com.atomgraph.core.MediaTypes;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.server.model.ClientUriInfo;
import com.atomgraph.client.util.DataManager;
import com.atomgraph.linkeddatahub.server.util.OntologyLoader;
import com.atomgraph.linkeddatahub.server.model.impl.ResourceBase;
import com.atomgraph.linkeddatahub.server.util.SPARQLClientOntologyLoader;
import com.atomgraph.processor.model.TemplateCall;
import java.util.Optional;
import javax.inject.Inject;
import javax.servlet.http.HttpServletRequest;
import javax.ws.rs.container.ResourceContext;
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
public class Item extends ResourceBase
{

    private static final Logger log = LoggerFactory.getLogger(Item.class);

    private final OntologyLoader ontLoader;
    
    @Inject
    public Item(@Context UriInfo uriInfo, ClientUriInfo clientUriInfo, @Context Request request, MediaTypes mediaTypes,
            Optional<Service> service, Optional<com.atomgraph.linkeddatahub.apps.model.Application> application,
            Optional<Ontology> ontology, Optional<TemplateCall> templateCall,
            @Context HttpHeaders httpHeaders, @Context ResourceContext resourceContext,
            @Context HttpServletRequest httpServletRequest, @Context SecurityContext securityContext,
            DataManager dataManager, @Context Providers providers,
            com.atomgraph.linkeddatahub.Application system)
    {
        super(uriInfo, clientUriInfo, request, mediaTypes,
                service, application, ontology, templateCall,
                httpHeaders, resourceContext,
                httpServletRequest, securityContext,
                dataManager, providers,
                system);
        ontLoader = new SPARQLClientOntologyLoader(system.getOntModelSpec(), system.getSitemapQuery());
    }
    
    @Override
    public Response get()
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
    
    public OntologyLoader getOntologyLoader()
    {
        return ontLoader;
    }
    
}