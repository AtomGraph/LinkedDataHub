/**
 *  Copyright 2022 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.server.filter.response;

import com.atomgraph.client.vocabulary.AC;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.vocabulary.LDH;
import java.io.IOException;
import java.util.Optional;
import javax.annotation.Priority;
import javax.inject.Inject;
import javax.ws.rs.Priorities;
import javax.ws.rs.container.ContainerRequestContext;
import javax.ws.rs.container.ContainerResponseContext;
import javax.ws.rs.container.ContainerResponseFilter;
import javax.ws.rs.core.Response.Status;
import org.apache.jena.query.Query;
import org.apache.jena.query.QueryFactory;
import org.apache.jena.rdf.model.Model;

/**
 * This filter retrieves local triples for the Linked Data resource being browsed.
 * External LD resources can be unreachable or not found or have different properties than the local ones.
 * 
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
@Priority(Priorities.USER + 150)
public class LocalResourceLookupFilter implements ContainerResponseFilter
{

    @Inject javax.inject.Provider<Optional<Service>> service;

    @Override
    public void filter(ContainerRequestContext req, ContainerResponseContext resp) throws IOException
    {
        if (req.getUriInfo().getQueryParameters().containsKey(AC.uri.getLocalName()))
        {
            String uri = req.getUriInfo().getQueryParameters().getFirst(AC.uri.getLocalName());
            Query query = QueryFactory.create("DESCRIBE <" + uri + ">");
            Model localModel = getService().get().getSPARQLClient().loadModel(query);
            
            if (!localModel.isEmpty()) // append the local model to the remote model
            {
                req.setProperty(LDH.localGraph.getURI(), localModel); // used by the ModelXSLTWriter
                
                if (resp.hasEntity() && resp.getEntity() instanceof Model) ((Model)resp.getEntity()).add(localModel);
                else resp.setEntity(localModel);
                
                resp.setStatusInfo(Status.OK);
            }
        }
    }

    /**
     * Returns (optional) SPARQL service of the current application.
     * 
     * @return optional service
     */
    public Optional<Service> getService()
    {
        return service.get();
    }
    
}
