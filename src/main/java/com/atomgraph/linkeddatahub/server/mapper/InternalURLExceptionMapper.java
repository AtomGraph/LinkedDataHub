/**
 *  Copyright 2025 Martynas Jusevičius <martynas@atomgraph.com>
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
import com.atomgraph.linkeddatahub.server.exception.InternalURLException;
import com.atomgraph.server.mapper.ExceptionMapperBase;
import jakarta.inject.Inject;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.ExceptionMapper;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.ResourceFactory;

/**
 * JAX-RS mapper for internal URL exceptions.
 * Maps {@link InternalURLException} to HTTP 400 Bad Request response.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class InternalURLExceptionMapper extends ExceptionMapperBase implements ExceptionMapper<InternalURLException>
{

    /**
     * Constructs exception mapper from media type registry.
     *
     * @param mediaTypes registry of readable/writable media types
     */
    @Inject
    public InternalURLExceptionMapper(MediaTypes mediaTypes)
    {
        super(mediaTypes);
    }

    @Override
    public Response toResponse(InternalURLException ex)
    {
        Resource resource = toResource(ex, Response.Status.BAD_REQUEST,
                    ResourceFactory.createResource("http://www.w3.org/2011/http-statusCodes#BadRequest"));

        return getResponseBuilder(resource.getModel()).
            status(Response.Status.BAD_REQUEST).
            build();
    }

}
