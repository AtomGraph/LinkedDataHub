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
import javax.inject.Inject;
import javax.ws.rs.container.ContainerRequestContext;
import javax.ws.rs.container.ContainerResponseContext;
import javax.ws.rs.container.ContainerResponseFilter;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.SecurityContext;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.vocabulary.RDF;

/**
 * Records each HTTP interaction in a timestamped meta named graph.
 * The same logic can be found in Docker container's <code>split-default-graph.rq.template</code>.
 * 
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class ProvenanceFilter implements ContainerResponseFilter
{

    @Context SecurityContext securityContext;
    
    @Inject Optional<Service> service;

    @Override
    public void filter(ContainerRequestContext request, ContainerResponseContext response)throws IOException
    {
        if (getService().isPresent())
        {
            String graphUri = request.getUriInfo().getAbsolutePath().toString();
            String graphGraphUri = "urn:uuid:" + UUID.randomUUID().toString();

            Model model = ModelFactory.createDefaultModel();
            model.createResource().
                addProperty(RDF.type, SD.NamedGraph).
                addProperty(SD.name, model.createResource(graphUri)).
                addProperty(PROV.wasAttributedTo, getAgent()).
                addLiteral(PROV.generatedAtTime, GregorianCalendar.getInstance());
                // TO-DO: ACL access mode?
            
            getService().get().getDatasetAccessor().putModel(graphGraphUri, model);
        }
    }

    /**
     * Gets agent authenticated for the current request.
     * 
     * @return agent
     */
    public Agent getAgent()
    {
        if (getSecurityContext() != null &&
                getSecurityContext().getUserPrincipal() != null &&
                getSecurityContext().getUserPrincipal() instanceof Agent)
            return (Agent)getSecurityContext().getUserPrincipal();
        
        return null;
    }
    
    public SecurityContext getSecurityContext()
    {
        return securityContext;
    }
    
    public Optional<Service> getService()
    {
        return service;
    }
    
}
