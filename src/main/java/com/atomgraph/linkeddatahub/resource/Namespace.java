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
import javax.ws.rs.ext.Providers;
import com.atomgraph.core.MediaTypes;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.client.util.DataManager;
import com.atomgraph.linkeddatahub.server.model.impl.GraphStoreImpl;
import java.net.URI;
import java.util.Optional;
import javax.inject.Inject;
import javax.servlet.ServletConfig;
import javax.ws.rs.DefaultValue;
import javax.ws.rs.GET;
import javax.ws.rs.QueryParam;
import javax.ws.rs.core.UriInfo;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS resource that handles namespace item requests.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class Namespace extends GraphStoreImpl
{

    private static final Logger log = LoggerFactory.getLogger(Namespace.class);

    private final URI uri;
    
    @Inject
    public Namespace(@Context UriInfo uriInfo, @Context Request request, Optional<Service> service, MediaTypes mediaTypes,
            Optional<com.atomgraph.linkeddatahub.apps.model.Application> application, Optional<Ontology> ontology,
            DataManager dataManager,
            @Context Providers providers, com.atomgraph.linkeddatahub.Application system, @Context ServletConfig servletConfig)
    {
        super(request, service, mediaTypes, uriInfo, providers, system);
        this.uri = uriInfo.getAbsolutePath();
        if (log.isDebugEnabled()) log.debug("Constructing {}", getClass());
    }
    
    @GET
    @Override
    public Response get(@QueryParam("default") @DefaultValue("false") Boolean defaultGraph, @QueryParam("graph") URI graphUri)
    {
        //Resource ontology = getOntResource().getPropertyResourceValue(FOAF.primaryTopic);
        // To-DO: hard-coding "#" is not great
        String ontologyURI = getURI().toString() + "#";

        Model model = ModelFactory.createDefaultModel();
        getSystem().getOntModelSpec().getDocumentManager().getFileManager().readModel(model, ontologyURI);
        
        return getResponse(model);
    }
    
    
    public URI getURI()
    {
        return uri;
    }
    
}