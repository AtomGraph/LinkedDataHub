/**
 *  Copyright 2021 Martynas Jusevičius <martynas@atomgraph.com>
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

import com.atomgraph.core.vocabulary.SD;
import com.atomgraph.linkeddatahub.model.Agent;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.vocabulary.PROV;
import java.io.IOException;
import java.util.GregorianCalendar;
import java.util.Optional;
import java.util.UUID;
import javax.annotation.Priority;
import javax.inject.Inject;
import javax.ws.rs.HttpMethod;
import javax.ws.rs.Priorities;
import javax.ws.rs.container.ContainerRequestContext;
import javax.ws.rs.container.ContainerResponseContext;
import javax.ws.rs.container.ContainerResponseFilter;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.vocabulary.RDF;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Records each HTTP interaction in a timestamped meta named graph.
 * The same logic can be found in Docker container's <code>split-default-graph.rq.template</code>.
 * 
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
@Priority(Priorities.USER + 100)
public class ProvenanceFilter implements ContainerResponseFilter
{
    
    private static final Logger log = LoggerFactory.getLogger(ProvenanceFilter.class);

    @Inject javax.inject.Provider<Optional<Service>> service;

    @Override
    public void filter(ContainerRequestContext request, ContainerResponseContext response)throws IOException
    {
        if (getService().isPresent() &&
            (request.getMethod().equals(HttpMethod.POST) ||
            request.getMethod().equals(HttpMethod.PUT) ||
            request.getMethod().equals(HttpMethod.PATCH) ||
            request.getMethod().equals(HttpMethod.DELETE)))
        {
            String graphUri = request.getUriInfo().getAbsolutePath().toString();
            String graphGraphUri = "urn:uuid:" + UUID.randomUUID().toString();

            Model model = ModelFactory.createDefaultModel();
            Resource graph = model.createResource().
                addProperty(RDF.type, SD.NamedGraph).
                addProperty(SD.name, model.createResource(graphUri)).
                addLiteral(PROV.generatedAtTime, GregorianCalendar.getInstance());
                // TO-DO: ACL access mode?
            
            if (request.getSecurityContext().getUserPrincipal() instanceof Agent)
            {
                Agent agent = ((Agent)(request.getSecurityContext().getUserPrincipal()));
                graph.addProperty(PROV.wasAttributedTo, agent);
            }
            
            if (log.isDebugEnabled()) log.debug("PUTting {} triples of provenance metadata", graph.getModel().size());
            getService().get().getDatasetAccessor().putModel(graphGraphUri, model);
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
