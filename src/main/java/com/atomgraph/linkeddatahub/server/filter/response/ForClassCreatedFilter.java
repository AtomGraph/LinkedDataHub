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

import com.atomgraph.linkeddatahub.vocabulary.APLT;
import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;
import javax.annotation.Priority;
import javax.ws.rs.BadRequestException;
import javax.ws.rs.HttpMethod;
import javax.ws.rs.InternalServerErrorException;
import javax.ws.rs.Priorities;
import javax.ws.rs.container.ContainerRequestContext;
import javax.ws.rs.container.ContainerResponseContext;
import javax.ws.rs.container.ContainerResponseFilter;
import javax.ws.rs.core.HttpHeaders;
import javax.ws.rs.core.Response;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ResIterator;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.ResourceFactory;
import org.apache.jena.sparql.vocabulary.FOAF;
import org.apache.jena.vocabulary.RDF;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Redirect POST responses to the created resource.
 * Resource URI is extracted by looking for the resource of type <code>forClass</code> (which is supplied by a request URL param) in the response's RDF graph.
 * 
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
@Priority(Priorities.USER + 350)
public class ForClassCreatedFilter implements ContainerResponseFilter
{

    private static final Logger log = LoggerFactory.getLogger(ForClassCreatedFilter.class);

    @Override
    public void filter(ContainerRequestContext req, ContainerResponseContext resp) throws IOException
    {
        if (req.getMethod().equals(HttpMethod.POST) && resp.hasEntity() && resp.getEntity() instanceof Model &&
                req.getUriInfo().getQueryParameters().containsKey(APLT.forClass.getLocalName()))
        {
            try
            {
                URI forClass = new URI(req.getUriInfo().getQueryParameters().getFirst(APLT.forClass.getLocalName()));

                Resource instance = getCreatedDocument((Model)resp.getEntity(), ResourceFactory.createResource(forClass.toString()));
                if (instance == null || !instance.isURIResource()) throw new BadRequestException("aplt:ForClass typed resource not found in model");

                try
                {
                    URI graphUri = URI.create(instance.getURI());
                    graphUri = new URI(graphUri.getScheme(), graphUri.getSchemeSpecificPart(), null).normalize(); // strip the possible fragment identifier
                    resp.getHeaders().putSingle(HttpHeaders.LOCATION, graphUri);
                    resp.setStatusInfo(Response.Status.CREATED);
                }
                catch (URISyntaxException ex)
                {
                    // shouldn't happen
                    throw new InternalServerErrorException(ex);
                }
            }
            catch (URISyntaxException ex)
            {
                if (log.isErrorEnabled()) log.error("?forClass URL param value <{}> is an invalid URI", ex.getInput());
                throw new BadRequestException(ex);
            }
        }
    }

    /**
     * Extracts the individual that is being created from the input RDF graph.
     * 
     * @param model RDF input graph
     * @param forClass RDF class
     * @return RDF resource
     */
    public Resource getCreatedDocument(Model model, Resource forClass)
    {
        if (model == null) throw new IllegalArgumentException("Model cannot be null");
        
        ResIterator it = model.listSubjectsWithProperty(RDF.type, forClass);
        try
        {
            if (it.hasNext())
            {
                Resource created = it.next();
                
                // handle creation of "things" - they are not documents themselves, so we return the attached document instead
                if (created.hasProperty(FOAF.isPrimaryTopicOf))
                    return created.getPropertyResourceValue(FOAF.isPrimaryTopicOf);
                else
                    return created;
            }
        }
        finally
        {
            it.close();
        }
        
        return null;
    }
    
}
