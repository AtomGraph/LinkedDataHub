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
package com.atomgraph.linkeddatahub.server.mapper;

import com.atomgraph.core.MediaTypes;
import com.atomgraph.linkeddatahub.server.exception.ResourceExistsException;
import com.atomgraph.server.mapper.ExceptionMapperBase;
import java.util.Optional;
import javax.inject.Inject;
import javax.ws.rs.container.ResourceContext;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.HttpHeaders;
import org.apache.jena.rdf.model.ResourceFactory;

import javax.ws.rs.core.Response;
import javax.ws.rs.ext.ExceptionMapper;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.query.DatasetFactory;
import org.apache.jena.rdf.model.Resource;

/**
 * JAX-RS mapper for resource conflict exceptions.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ResourceExistsExceptionMapper extends ExceptionMapperBase implements ExceptionMapper<ResourceExistsException>
{

    private final ResourceContext resourceContext;
    
    @Inject
    public ResourceExistsExceptionMapper(Optional<Ontology> ontology, MediaTypes mediaTypes, @Context ResourceContext resourceContext)
    {
        super(ontology, Optional.empty(), mediaTypes);
        this.resourceContext = resourceContext;
    }
    
    @Override
    public Response toResponse(ResourceExistsException ex)
    {
        //ex.getModel().add(getQueriedResource().describe().getDefaultModel());

        Resource exception = toResource(ex, Response.Status.CONFLICT,
            ResourceFactory.createResource("http://www.w3.org/2011/http-statusCodes#Conflict"));
        ex.getModel().add(exception.getModel());
        
        return getResponseBuilder(DatasetFactory.create(ex.getModel())).
            status(Response.Status.CONFLICT).
            header(HttpHeaders.LOCATION, ex.getURI()).
            build();
    }
    
//    public QueriedResource getQueriedResource()
//    {
//        return getResourceContext().matchResource(getUriInfo().getRequestUri(), QueriedResource.class);
//    }
    
    public ResourceContext getResourceContext()
    {
        return resourceContext;
    }
    
}
