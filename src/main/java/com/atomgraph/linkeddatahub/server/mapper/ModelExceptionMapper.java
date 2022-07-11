// Copyright 2019 Martynas Jusevičius <martynas@atomgraph.com>
// SPDX-FileCopyrightText: 2017-2022 2017 Martynas Jusevicius, <martynas@atomgraph.com> et al.
//
// SPDX-License-Identifier: Apache-2.0

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
import javax.ws.rs.core.Context;
import javax.ws.rs.core.Response;
import com.atomgraph.server.exception.ModelException;
import com.atomgraph.server.model.QueriedResource;
import javax.inject.Inject;
import javax.ws.rs.container.ResourceContext;

/**
 * JAX-RS mapper for model exceptions.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ModelExceptionMapper extends com.atomgraph.server.mapper.ModelExceptionMapper
{

    @Context ResourceContext resourceContext;
    
    /**
     * Constructs mapper from media types.
     * 
     * @param mediaTypes registry of readable/writable media types
     */
    @Inject
    public ModelExceptionMapper(MediaTypes mediaTypes)
    {
        super(mediaTypes);
    }

    @Override
    public Response toResponse(ModelException ex)
    {
        if (getQueriedResource() != null) ex.getModel().add(getQueriedResource().describe());
        
        return super.toResponse(ex);
    }
    
    /**
     * Returns the current RDF resource.
     * 
     * @return RDF resource
     */
    public QueriedResource getQueriedResource()
    {
        return getResourceContext().getResource(QueriedResource.class);
    }
    
    /**
     * Returns JAX-RS resource context.
     * 
     * @return resource context
     */
    public ResourceContext getResourceContext()
    {
        return resourceContext;
    }
    
}
