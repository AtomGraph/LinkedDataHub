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
import com.atomgraph.linkeddatahub.client.exception.ResponseContentTooLargeException;
import com.atomgraph.linkeddatahub.vocabulary.LDH;
import com.atomgraph.server.mapper.ExceptionMapperBase;
import jakarta.inject.Inject;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.ExceptionMapper;
import org.apache.jena.rdf.model.ResourceFactory;
import org.apache.jena.vocabulary.RDF;

/**
 * JAX-RS mapper for a response refused for its length: a SPARQL endpoint's query result, or content the
 * Linked Data proxy fetched. The status stays 502 - what was too large is the upstream's response - and
 * the description is typed, so a caller can tell the refusal from an upstream that could not be reached.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ResponseContentTooLargeExceptionMapper extends ExceptionMapperBase implements ExceptionMapper<ResponseContentTooLargeException>
{

    /**
     * Constructs mapper from media type registry.
     *
     * @param mediaTypes registry of readable/writable media types
     */
    @Inject
    public ResponseContentTooLargeExceptionMapper(MediaTypes mediaTypes)
    {
        super(mediaTypes);
    }

    @Override
    public Response toResponse(ResponseContentTooLargeException ex)
    {
        return getResponseBuilder(toResource(ex, Response.Status.BAD_GATEWAY,
                    ResourceFactory.createResource("http://www.w3.org/2011/http-statusCodes#BadGateway")).
                addProperty(RDF.type, LDH.ResponseTooLarge).
                getModel()).
            status(Response.Status.BAD_GATEWAY).
            build();
    }

}
