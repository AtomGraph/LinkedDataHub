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
import java.util.List;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.HttpHeaders;
import javax.ws.rs.core.Request;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.SecurityContext;
import javax.ws.rs.ext.Providers;
import com.atomgraph.core.MediaTypes;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.server.model.ClientUriInfo;
import com.atomgraph.client.util.DataManager;
import com.atomgraph.linkeddatahub.server.model.impl.ResourceBase;
import com.atomgraph.linkeddatahub.server.util.SPARQLClientOntologyLoader;
import com.atomgraph.linkeddatahub.vocabulary.LSMT;
import com.atomgraph.processor.model.TemplateCall;
import java.util.Optional;
import javax.annotation.PostConstruct;
import javax.inject.Inject;
import javax.ws.rs.container.ResourceContext;
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

    @Inject
    public Item(@Context UriInfo uriInfo, @Context ClientUriInfo clientUriInfo, @Context Request request, MediaTypes mediaTypes,
            Service service, com.atomgraph.linkeddatahub.apps.model.Application application,
            Ontology ontology, Optional<TemplateCall> templateCall,
            @Context HttpHeaders httpHeaders, @Context ResourceContext resourceContext,
            @Context SecurityContext securityContext,
            DataManager dataManager, @Context Providers providers,
            com.atomgraph.linkeddatahub.Application system)
    {
        super(uriInfo, clientUriInfo, request, mediaTypes,
                service, application, ontology, templateCall,
                httpHeaders, resourceContext,
                securityContext,
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
        
        if (getTemplateCall().get().hasArgument(LSMT.clear)) // this is just a flag, we don't need the argument value. TO-DO: change to post()!
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
  
                new SPARQLClientOntologyLoader(getSystem().getOntModelSpec(), getSystem().getSitemapQuery()).getOntology(getApplication());
            }
            
            List<String> referers = getHttpHeaders().getRequestHeader("Referer");
            if (referers != null && !referers.isEmpty())
                return Response.seeOther(URI.create(referers.get(0))).build();
        }
        
        return super.get();
    }
    
}