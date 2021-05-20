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
package com.atomgraph.linkeddatahub.resource.imports;

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
import com.atomgraph.linkeddatahub.server.model.impl.GraphStoreImpl;
import com.atomgraph.processor.model.TemplateCall;
import java.net.URI;
import java.util.Optional;
import javax.inject.Inject;
import javax.servlet.ServletConfig;
import javax.ws.rs.DefaultValue;
import javax.ws.rs.GET;
import javax.ws.rs.POST;
import javax.ws.rs.QueryParam;
import javax.ws.rs.core.Response.Status;
import javax.ws.rs.core.UriInfo;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.sparql.vocabulary.FOAF;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS resource that handles CSV data imports.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class Container extends GraphStoreImpl
{
    private static final Logger log = LoggerFactory.getLogger(Container.class);
    
    private final UriInfo uriInfo;
    private final URI uri;
    private final com.atomgraph.linkeddatahub.apps.model.Application application;
    private final DataManager dataManager;
    private com.atomgraph.linkeddatahub.Application system;

    @Inject
    public Container(@Context UriInfo uriInfo, @Context Request request, MediaTypes mediaTypes,
            Optional<Service> service, Optional<com.atomgraph.linkeddatahub.apps.model.Application> application, Optional<Ontology> ontology, Optional<TemplateCall> templateCall,
            DataManager dataManager,
            com.atomgraph.linkeddatahub.Application system, @Context ServletConfig servletConfig)
    {
        super(request, service, mediaTypes);
        this.uriInfo = uriInfo;
        this.uri = uriInfo.getAbsolutePath();
        this.application = application.get();
        this.dataManager = dataManager;
        this.system = system;
        if (log.isDebugEnabled()) log.debug("Constructing {}", getClass());
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
        Response constructor = super.post(model, false, null); // construct Import
        
        if (constructor.getStatus() == Status.CREATED.getStatusCode()) // import created
        {
            URI importGraphUri = constructor.getLocation();
            Model importModel = (Model)get(false, importGraphUri).getEntity();
            Resource doc = importModel.createResource(importGraphUri.toString());
            Resource topic = doc.getPropertyResourceValue(FOAF.primaryTopic);
            
            if (topic != null && topic.canAs(Import.class))
            {
                Resource provGraph = null;
//                QuerySolutionMap qsm = new QuerySolutionMap();
//                qsm.add(FOAF.Document.getLocalName(), doc);
                

                Service adminService = getApplication().canAs(EndUserApplication.class) ? getApplication().as(EndUserApplication.class).getAdminApplication().getService() : null;
                // start the import asynchroniously
                if (topic.canAs(CSVImport.class))
                    getSystem().submitImport(topic.as(CSVImport.class), provGraph, getApplication().getService(), adminService, getUriInfo().getBaseUri().toString(), getDataManager());
                if (topic.canAs(RDFImport.class))
                    getSystem().submitImport(topic.as(RDFImport.class), provGraph, getApplication().getService(), adminService, getUriInfo().getBaseUri().toString(), getDataManager());
            }
            else
                if (log.isErrorEnabled()) log.error("Topic '{}' cannot be cast to Import", topic);
        }
        
        return constructor;
    }
    
    public UriInfo getUriInfo()
    {
        return uriInfo;
    }
    
    public URI getURI()
    {
        return uri;
    }
 
    public com.atomgraph.linkeddatahub.apps.model.Application getApplication()
    {
        return application;
    }
    
    public com.atomgraph.linkeddatahub.Application getSystem()
    {
        return system;
    }
    
    public DataManager getDataManager()
    {
        return dataManager;
    }
    
}