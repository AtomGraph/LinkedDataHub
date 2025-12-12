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
import com.atomgraph.server.mapper.ExceptionMapperBase;
import com.atomgraph.server.vocabulary.HTTP;
import jakarta.inject.Inject;
import jakarta.ws.rs.ForbiddenException;
import jakarta.ws.rs.core.EntityTag;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.ExceptionMapper;
import jakarta.ws.rs.ext.Provider;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.ResourceFactory;

/**
 * JAX-RS mapper for generic forbidden exceptions.
 * Handles ForbiddenException that are not AuthorizationException (which has its own mapper).
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Provider
public class ForbiddenExceptionMapper extends ExceptionMapperBase implements ExceptionMapper<ForbiddenException>
{

    /**
     * Constructs mapper from media types.
     *
     * @param mediaTypes registry of readable/writable media types
     */
    @Inject
    public ForbiddenExceptionMapper(MediaTypes mediaTypes)
    {
        super(mediaTypes);
    }

    @Override
    public Response toResponse(ForbiddenException ex)
    {
        Resource exRes = toResource(ex, Response.Status.FORBIDDEN,
            ResourceFactory.createResource("http://www.w3.org/2011/http-statusCodes#Forbidden")).
                addLiteral(HTTP.sc, ResourceFactory.createResource("http://www.w3.org/2011/http-statusCodes#Forbidden"));

        return getResponseBuilder(exRes.getModel()).
            status(Response.Status.FORBIDDEN).
            tag((EntityTag)null). // unset EntityTag to prevent caching of 403 responses
            build();
    }

}
