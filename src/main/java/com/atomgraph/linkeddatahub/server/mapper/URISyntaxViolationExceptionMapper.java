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
import com.atomgraph.linkeddatahub.server.exception.URISyntaxViolationException;
import com.atomgraph.linkeddatahub.vocabulary.LDH;
import com.atomgraph.server.mapper.ExceptionMapperBase;
import static com.atomgraph.server.status.UnprocessableEntityStatus.UNPROCESSABLE_ENTITY;
import jakarta.inject.Inject;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.ExceptionMapper;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.ResourceFactory;
import org.apache.jena.vocabulary.RDF;

/**
 * JAX-RS mapper for writes refused for malformed IRIs. Answered 422, as a constraint violation is: the request is
 * well-formed HTTP whose content cannot be stored, and the response names each value, so a form can mark it.
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class URISyntaxViolationExceptionMapper extends ExceptionMapperBase implements ExceptionMapper<URISyntaxViolationException>
{

    /**
     * Constructs mapper from media type registry.
     *
     * @param mediaTypes registry of readable/writable media types
     */
    @Inject
    public URISyntaxViolationExceptionMapper(MediaTypes mediaTypes)
    {
        super(mediaTypes);
    }

    @Override
    public Response toResponse(URISyntaxViolationException ex)
    {
        Resource exception = toResource(ex, UNPROCESSABLE_ENTITY,
            ResourceFactory.createResource("http://www.w3.org/2011/http-statusCodes#UnprocessableEntity"));
        ex.getModel().add(exception.getModel());
        // connect the Response to each violation, as the constraint violation mappers do
        ex.getModel().listSubjectsWithProperty(RDF.type, LDH.URISyntaxViolation).toList().forEach(violation ->
            ex.getModel().add(exception, ResourceFactory.createProperty("http://www.w3.org/ns/prov#wasDerivedFrom"), violation));

        return getResponseBuilder(ex.getModel()).
            status(UNPROCESSABLE_ENTITY).
            build();
    }

}
