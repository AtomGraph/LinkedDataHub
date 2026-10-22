/*
 * Copyright 2020 Martynas Jusevičius <martynas@atomgraph.com>.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.atomgraph.server.mapper;

import com.atomgraph.core.MediaTypes;
import jakarta.inject.Inject;
import jakarta.ws.rs.HttpMethod;
import jakarta.ws.rs.NotSupportedException;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.ExceptionMapper;
import org.apache.jena.rdf.model.ResourceFactory;

/**
 * Maps unsupported request media types to 415 responses.
 * A rejected <code>PATCH</code> advertises the patch format that is accepted in <code>Accept-Patch</code> (RFC 5789, section 2.2).
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class NotSupportedExceptionMapper extends ExceptionMapperBase implements ExceptionMapper<NotSupportedException>
{

    /** The <code>Accept-Patch</code> header name (RFC 5789, section 3.1) */
    public static final String ACCEPT_PATCH = "Accept-Patch";

    @Inject
    public NotSupportedExceptionMapper(MediaTypes mediaTypes)
    {
        super(mediaTypes);
    }

    @Override
    public Response toResponse(NotSupportedException ex)
    {
        Response.ResponseBuilder builder = getResponseBuilder(toResource(ex, ex.getResponse().getStatusInfo(),
                        ResourceFactory.createResource("http://www.w3.org/2011/http-statusCodes#UnsupportedMediaType")).
                    getModel()).
                status(ex.getResponse().getStatusInfo());

        if (HttpMethod.PATCH.equalsIgnoreCase(getRequest().getMethod()))
            builder.header(ACCEPT_PATCH, com.atomgraph.core.MediaType.APPLICATION_SPARQL_UPDATE);

        return builder.build();
    }
    
}
