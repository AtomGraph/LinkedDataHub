/**
 *  Copyright 2020 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.resource.module;

import com.atomgraph.client.util.DataManager;
import com.atomgraph.core.MediaTypes;
import com.atomgraph.linkeddatahub.apps.model.AdminApplication;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.server.model.ClientUriInfo;
import com.atomgraph.linkeddatahub.server.model.impl.ResourceBase;
import com.atomgraph.linkeddatahub.vocabulary.FOAF;
import com.atomgraph.linkeddatahub.vocabulary.LMOD;
import com.atomgraph.processor.model.TemplateCall;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.util.Calendar;
import java.util.Optional;
import javax.inject.Inject;
import javax.servlet.http.HttpServletRequest;
import javax.ws.rs.WebApplicationException;
import javax.ws.rs.container.ResourceContext;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.HttpHeaders;
import javax.ws.rs.core.Request;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.SecurityContext;
import javax.ws.rs.core.UriInfo;
import javax.ws.rs.ext.Providers;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.query.Dataset;
import org.apache.jena.query.DatasetFactory;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.riot.Lang;
import org.apache.jena.riot.RDFDataMgr;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 *
 * @author Martynas Jusevičius <martynas@atomgraph.com>
 */
public class Item extends ResourceBase
{
    
    private static final Logger log = LoggerFactory.getLogger(Item.class);

    @Inject
    public Item(@Context UriInfo uriInfo, ClientUriInfo clientUriInfo, @Context Request request, MediaTypes mediaTypes,
            Service service, com.atomgraph.linkeddatahub.apps.model.Application application,
            Ontology ontology, Optional<TemplateCall> templateCall,
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
    }
    
    @Override
    public Response get() // TO-DO: switch to POST
    {
        if (getUriInfo().getQueryParameters().containsKey("install"))
        {
            Dataset description = describe();
            Resource doc = description.getDefaultModel().getResource(getURI().toString());
            Resource module = doc.getPropertyResourceValue(FOAF.primaryTopic);
            // we assume we're inside AdminApplication
            EndUserApplication endUserApp = getApplication().as(AdminApplication.class).getEndUserApplication();
            installDataset(getService(), getApplication().getBase().getURI(), module.getPropertyResourceValue(LMOD.adminDataset).getURI());
            installDataset(endUserApp.getService(), endUserApp.getBase().getURI(), module.getPropertyResourceValue(LMOD.endUserDataset).getURI());
        }
        
        return super.get();
    }
    
    public void installDataset(Service service, String baseURI, String datasetURI)
    {
        try (InputStream datasetStream = getDatasetInputStream(datasetURI))
        {
            Dataset dataset = DatasetFactory.create();
            RDFDataMgr.read(dataset, datasetStream, baseURI, Lang.TRIG);
            dataset = splitDefaultModel(dataset.getDefaultModel(), URI.create(baseURI), getAgent(), Calendar.getInstance()); // split the default graphs into named graphs and add provenance metadata
            service.getDatasetQuadAccessor().add(dataset);
        }
        catch (IOException ex)
        {
            if (log.isErrorEnabled()) log.error("Error installing dataset to service '{}'", service);
            throw new WebApplicationException(ex);
        }
    }
    
    public InputStream getDatasetInputStream(String uri)
    {
        return getClient().target(uri).request().get(InputStream.class);
    }
    
}
