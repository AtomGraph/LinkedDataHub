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

import javax.ws.rs.core.Context;
import javax.ws.rs.core.Request;
import javax.ws.rs.core.Response;
import com.atomgraph.core.MediaTypes;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.client.util.DataManager;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import com.atomgraph.linkeddatahub.model.CSVImport;
import com.atomgraph.linkeddatahub.model.Import;
import com.atomgraph.linkeddatahub.model.RDFImport;
import com.atomgraph.linkeddatahub.resource.graph.Item;
import com.atomgraph.linkeddatahub.server.model.impl.GraphStoreImpl;
import java.net.URI;
import java.util.Optional;
import javax.inject.Inject;
import javax.servlet.ServletConfig;
import javax.ws.rs.BadRequestException;
import javax.ws.rs.DefaultValue;
import javax.ws.rs.GET;
import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.QueryParam;
import javax.ws.rs.core.Response.Status;
import javax.ws.rs.core.UriInfo;
import javax.ws.rs.ext.Providers;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.rdf.model.InfModel;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.NodeIterator;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.sparql.vocabulary.FOAF;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS endpoint that handles CSV data imports.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class Imports extends GraphStoreImpl
{
    private static final Logger log = LoggerFactory.getLogger(Imports.class);
    
    private final URI uri;
    private final DataManager dataManager;

    /**
     * Constructs endpoint for asynchronous CSV and RDF data imports.
     * 
     * @param request current request
     * @param uriInfo current URI info
     * @param mediaTypes supported media types
     * @param application matched application
     * @param ontology matched application's ontology
     * @param service matched application's service
     * @param dataManager RDF data manager
     * @param providers JAX-RS providers
     * @param system system application 
     * @param servletConfig servlet config
     */
    @Inject
    public Imports(@Context Request request, @Context UriInfo uriInfo, MediaTypes mediaTypes,
            com.atomgraph.linkeddatahub.apps.model.Application application, Optional<Ontology> ontology, Optional<Service> service,
            DataManager dataManager,
            @Context Providers providers, com.atomgraph.linkeddatahub.Application system, @Context ServletConfig servletConfig)
    {
        super(request, uriInfo, mediaTypes, application, ontology, service, providers, system);
        this.uri = uriInfo.getAbsolutePath();
        this.dataManager = dataManager;
        if (log.isDebugEnabled()) log.debug("Constructing {}", getClass());
    }

    /**
     * Returns item as JAX-RS sub-resource.
     * 
     * @return item class
     */
    @Path("{path: .*}")
    public Object getSubResource()
    {
        return Item.class;
    }
        
    @GET
    @Override
    public Response get(@QueryParam("default") @DefaultValue("false") Boolean defaultGraph, @QueryParam("graph") URI graphUri)
    {
        return super.get(false, getURI());
    }
    
    @POST
    @Override
    public Response post(Model model, @QueryParam("default") @DefaultValue("false") Boolean defaultGraph, @QueryParam("graph") URI graphUri)
    {
        Response constructor = super.post(model, defaultGraph, graphUri); // construct Import
        
        if (constructor.getStatus() == Status.CREATED.getStatusCode()) // import created
        {
            URI importGraphUri = constructor.getLocation();
            //Model importModel = (Model)super.get(false, importGraphUri).getEntity();
            InfModel infModel = ModelFactory.createRDFSModel(getOntology().getOntModel(), model);
            Resource doc = infModel.createResource(importGraphUri.toString());
            
            NodeIterator it = infModel.listObjectsOfProperty(doc, FOAF.primaryTopic);
            try
            {
                if (it.hasNext())
                {
                    Resource topic = it.next().asResource();

                    if (topic != null && topic.canAs(Import.class))
                    {
                        Service adminService = getApplication().canAs(EndUserApplication.class) ? getApplication().as(EndUserApplication.class).getAdminApplication().getService() : null;
                        // start the import asynchroniously
                        if (topic.canAs(CSVImport.class))
                            getSystem().submitImport(topic.as(CSVImport.class), getApplication(), getApplication().getService(), adminService, getUriInfo().getBaseUri().toString(), getDataManager());
                        if (topic.canAs(RDFImport.class))
                            getSystem().submitImport(topic.as(RDFImport.class), getApplication(), getApplication().getService(), adminService, getUriInfo().getBaseUri().toString(), getDataManager());
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
        
        return constructor;
    }
    
    /**
     * Returns URI of this resource.
     * 
     * @return URI
     */
    public URI getURI()
    {
        return uri;
    }
 
    /**
     * Returns RDF data manager.
     * 
     * @return data manager
     */
    public DataManager getDataManager()
    {
        return dataManager;
    }
    
}