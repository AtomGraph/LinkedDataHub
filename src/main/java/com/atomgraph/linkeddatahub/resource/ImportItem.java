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
package com.atomgraph.linkeddatahub.resource;

import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.Request;
import jakarta.ws.rs.core.Response;
import com.atomgraph.core.MediaTypes;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import com.atomgraph.linkeddatahub.client.LinkedDataClient;
import com.atomgraph.linkeddatahub.model.CSVImport;
import com.atomgraph.linkeddatahub.model.RDFImport;
import com.atomgraph.linkeddatahub.resource.graph.Item;
import com.atomgraph.linkeddatahub.server.security.AgentContext;
import java.net.URI;
import java.util.Optional;
import jakarta.inject.Inject;
import jakarta.servlet.ServletConfig;
import jakarta.ws.rs.BadRequestException;
import jakarta.ws.rs.DefaultValue;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.Response.Status;
import jakarta.ws.rs.core.SecurityContext;
import jakarta.ws.rs.core.UriInfo;
import jakarta.ws.rs.ext.Providers;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.NodeIterator;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.sparql.vocabulary.FOAF;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS endpoint that handles CSV and RDF data imports.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ImportItem extends Item
{
    private static final Logger log = LoggerFactory.getLogger(ImportItem.class);

    /**
     * Constructs endpoint for asynchronous CSV and RDF data imports.
     * 
     * @param request current request
     * @param uriInfo current URI info
     * @param mediaTypes supported media types
     * @param application matched application
     * @param ontology matched application's ontology
     * @param service matched application's service
     * @param securityContext JAX-RS security context
     * @param agentContext authenticated agent's context
     * @param providers JAX-RS providers
     * @param system system application 
     * @param servletConfig servlet config
     */
    @Inject
    public ImportItem(@Context Request request, @Context UriInfo uriInfo, MediaTypes mediaTypes,
            com.atomgraph.linkeddatahub.apps.model.Application application, Optional<Ontology> ontology, Optional<Service> service,
            @Context SecurityContext securityContext, Optional<AgentContext> agentContext,
            @Context Providers providers, com.atomgraph.linkeddatahub.Application system, @Context ServletConfig servletConfig)
    {
        super(request, uriInfo, mediaTypes, application, ontology, service, securityContext, agentContext, providers, system);
        if (log.isDebugEnabled()) log.debug("Constructing {}", getClass());
    }
    
    @PUT
    @Override
    public Response put(Model model, @QueryParam("default") @DefaultValue("false") Boolean defaultGraph, @QueryParam("graph") URI graphUriUnused)
    {
        Response response = super.put(model, defaultGraph, getURI()); // construct Import
        
        if (response.getStatus() == Status.CREATED.getStatusCode()) // import created
        {
            URI graphUri = response.getLocation();
            Resource doc = model.createResource(graphUri.toString());
            
            NodeIterator it = model.listObjectsOfProperty(doc, FOAF.primaryTopic);
            try
            {
                if (it.hasNext())
                {
                    Resource topic = it.next().asResource();

                    if (topic != null && !topic.canAs(CSVImport.class) && !topic.canAs(RDFImport.class))
                    {
                        Service adminService = getApplication().canAs(EndUserApplication.class) ? getApplication().as(EndUserApplication.class).getAdminApplication().getService() : null;
                        LinkedDataClient ldc = LinkedDataClient.create(getSystem().getClient(), getSystem().getMediaTypes()).
                            delegation(getUriInfo().getBaseUri(), getAgentContext().orElse(null));
                        
                        // start the import asynchroniously
                        if (topic.canAs(CSVImport.class))
                            getSystem().submitImport(topic.as(CSVImport.class), getApplication(), getApplication().getService(), adminService, getUriInfo().getBaseUri().toString(), ldc);
                        if (topic.canAs(RDFImport.class))
                            getSystem().submitImport(topic.as(RDFImport.class), getApplication(), getApplication().getService(), adminService, getUriInfo().getBaseUri().toString(), ldc);
                    }
                    else
                        if (log.isErrorEnabled()) log.error("Topic '{}' cannot be cast to Import", topic);
                }
                else
                {
                    if (log.isErrorEnabled()) log.error("Import resource for document <{}> not found in graph", doc);
                    throw new BadRequestException("Import resource for document <" + doc + "> not found in graph");
                }
            }
            finally
            {
                it.close();
            }
        }
        
        return response;
    }
    
}