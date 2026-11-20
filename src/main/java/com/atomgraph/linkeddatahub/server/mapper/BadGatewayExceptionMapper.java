/**
 *  Copyright 2026 Martynas Jusevičius <martynas@atomgraph.com>
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
import com.atomgraph.core.exception.BadGatewayException;
import com.atomgraph.server.mapper.ExceptionMapperBase;
import jakarta.inject.Inject;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.ExceptionMapper;
import org.apache.jena.rdf.model.ResourceFactory;

/**
 * JAX-RS mapper for an upstream failure: a SPARQL result the store's response cut short, or one that could
 * not be read. The platform answers a description, a 502 included; Core's mapper for the same exception has
 * no entity, and Tomcat fills an empty error response with its own HTML page. The description carries the
 * failure's message as its title and is told from a refused oversize result by the absence of
 * {@link com.atomgraph.linkeddatahub.vocabulary.LDH#ResponseTooLarge}.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 * @see ResponseContentTooLargeExceptionMapper
 */
public class BadGatewayExceptionMapper extends ExceptionMapperBase implements ExceptionMapper<BadGatewayException>
{

    /**
     * Constructs mapper from media type registry.
     *
     * @param mediaTypes registry of readable/writable media types
     */
    @Inject
    public BadGatewayExceptionMapper(MediaTypes mediaTypes)
    {
        super(mediaTypes);
    }

    @Override
    public Response toResponse(BadGatewayException ex)
    {
        return getResponseBuilder(toResource(ex, Response.Status.BAD_GATEWAY,
                    ResourceFactory.createResource("http://www.w3.org/2011/http-statusCodes#BadGateway")).
                getModel()).
            status(Response.Status.BAD_GATEWAY).
            build();
    }

}
