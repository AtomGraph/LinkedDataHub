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

import javax.ws.rs.core.Context;
import javax.ws.rs.core.Response;
import com.atomgraph.server.exception.ModelException;
import com.atomgraph.server.model.QueriedResource;
import javax.ws.rs.container.ResourceContext;

/**
 * JAX-RS mapper for model exceptions.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ModelExceptionMapper extends com.atomgraph.server.mapper.ModelExceptionMapper
{
    @Context private ResourceContext resourceContext;

    @Override
    public Response toResponse(ModelException ex)
    {
        if (getQueriedResource() != null) ex.getModel().add(getQueriedResource().describe().getDefaultModel());
        
        return super.toResponse(ex);
    }
    
    public QueriedResource getQueriedResource()
    {
        return getResourceContext().getResource(QueriedResource.class);
    }
    
    public ResourceContext getResourceContext()
    {
        return resourceContext;
    }
    
}
