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
import com.sun.jersey.api.core.HttpContext;
import com.sun.jersey.api.core.ResourceContext;
import java.net.URI;
import java.util.List;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.HttpHeaders;
import javax.ws.rs.core.Request;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.SecurityContext;
import javax.ws.rs.ext.Providers;
import com.atomgraph.core.MediaTypes;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.server.model.impl.ClientUriInfo;
import com.atomgraph.linkeddatahub.client.DataManager;
import com.atomgraph.linkeddatahub.server.provider.OntologyProvider;
import com.atomgraph.linkeddatahub.server.model.impl.ResourceBase;
import com.atomgraph.linkeddatahub.vocabulary.LSMT;
import com.atomgraph.processor.util.TemplateCall;
import com.sun.jersey.api.client.Client;
import javax.annotation.PostConstruct;
import javax.ws.rs.core.Application;
import javax.ws.rs.core.UriInfo;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.sparql.vocabulary.FOAF;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS resource that handles ontology item requests.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class Item extends ResourceBase
{

    private static final Logger log = LoggerFactory.getLogger(Item.class);

    public Item(@Context UriInfo uriInfo, @Context ClientUriInfo clientUriInfo, @Context Request request, @Context MediaTypes mediaTypes,
            @Context Service service, @Context com.atomgraph.linkeddatahub.apps.model.Application application,
            @Context Ontology ontology, @Context TemplateCall templateCall,
            @Context HttpHeaders httpHeaders, @Context ResourceContext resourceContext,
            @Context Client client,
            @Context HttpContext httpContext, @Context SecurityContext securityContext,
            @Context DataManager dataManager, @Context Providers providers,
            @Context Application system)
    {
        super(uriInfo, clientUriInfo, request, mediaTypes,
                service, application, ontology, templateCall,
                httpHeaders, resourceContext,
                client,
                httpContext, securityContext,
                dataManager, providers,
                system);
    }
    
    @PostConstruct
    public void init()
    {
        getOntResource().getOntModel().add(describe().getDefaultModel());
    }
    
    @Override
    public Response get()
    {
        Resource ontology = getOntResource().getPropertyResourceValue(FOAF.primaryTopic);
        
        if (getTemplateCall().hasArgument(LSMT.clear)) // this is just a flag, we don't need the argument value. TO-DO: change to post()!
        {
            if (ontology == null)
            {
                if (log.isErrorEnabled()) log.error("Cannot clear ontology - no ontology is foaf:primaryTopic of this document: {}", getURI());
                throw new IllegalStateException("Cannot clear ontology - no ontology is foaf:primaryTopic of this document: " + getURI());
            }
            
            String ontologyURI = ontology.getURI();
            
            if (OntDocumentManager.getInstance().getFileManager().hasCachedModel(ontologyURI))
            {
                OntDocumentManager.getInstance().getFileManager().removeCacheModel(ontologyURI);
                
                OntologyProvider ontProvider = new OntologyProvider(getSystem().getOntModelSpec(), getSystem().getSitemapQuery());
                ontProvider.getOntology(getApplication(),
                        getApplication().getService(),
                        ontologyURI,
                        getSystem().getOntModelSpec(),
                        getOntology().getOntModel());
            }
            
            List<String> referers = getHttpHeaders().getRequestHeader("Referer");
            if (referers != null && !referers.isEmpty())
                return Response.seeOther(URI.create(referers.get(0))).build();
        }
        
        return super.get();
    }
    
}