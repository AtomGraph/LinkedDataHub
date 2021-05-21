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
package com.atomgraph.linkeddatahub.server.model.impl;

import com.atomgraph.core.MediaTypes;
import com.atomgraph.linkeddatahub.model.Service;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.Optional;
import javax.inject.Inject;
import javax.ws.rs.DefaultValue;
import javax.ws.rs.POST;
import javax.ws.rs.QueryParam;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.Request;
import javax.ws.rs.core.Response;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ResIterator;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * LinkedDataHub Graph Store implementation.
 * We need to subclass the Core class because we're injecting a subclass of Service.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class GraphStoreImpl extends com.atomgraph.core.model.impl.GraphStoreImpl
{
    
    private static final Logger log = LoggerFactory.getLogger(GraphStoreImpl.class);

    @Inject
    public GraphStoreImpl(@Context Request request, Optional<Service> service, MediaTypes mediaTypes)
    {
        super(request, service.get(), mediaTypes);
    }
    
    @POST
    @Override
    public Response post(Model model, @QueryParam("default") @DefaultValue("false") Boolean defaultGraph, @QueryParam("graph") URI graphUri)
    {
        if (log.isDebugEnabled()) log.debug("POST Graph Store request with RDF payload: {} payload size(): {}", model, model.size());
        
        if (model.isEmpty()) return Response.noContent().build();
        
        if (defaultGraph)
        {
            if (log.isDebugEnabled()) log.debug("POST Model to default graph");
            getDatasetAccessor().add(model);
            return Response.ok().build();
        }
        else
        {
            final boolean existingGraph;
            if (graphUri != null) existingGraph = getDatasetAccessor().containsModel(graphUri.toString());
            else
            {
                existingGraph = false;
                
                ResIterator it = model.listSubjects();
                try
                {
                    // TO-DO: this is really fragile, we should get rid of this and require an explicit graphUri
                    graphUri = URI.create(it.next().getURI()); // there has to be a subject resource since we checked (above) that the model is not empty
                    graphUri = new URI(graphUri.getScheme(), graphUri.getSchemeSpecificPart(), null).normalize(); // strip the possible fragment identifier
                }
                catch (URISyntaxException ex)
                {
                    // shouldn't happen
                }
                finally
                {
                    it.close();
                }
            }

            // is this implemented correctly? The specification is not very clear.
            if (log.isDebugEnabled()) log.debug("POST Model to named graph with URI: {} Did it already exist? {}", graphUri, existingGraph);
            getDatasetAccessor().add(graphUri.toString(), model);

            if (existingGraph) return Response.ok().build();
            else return Response.created(graphUri).build();
        }
    }
    
}