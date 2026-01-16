/*
 * Copyright 2017 Martynas Jusevičius <martynas@atomgraph.com>.
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
import org.apache.jena.rdf.model.ResourceFactory;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.ExceptionMapper;
import com.atomgraph.core.exception.ConfigurationException;
import jakarta.inject.Inject;

/**
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ConfigurationExceptionMapper extends ExceptionMapperBase implements ExceptionMapper<ConfigurationException>
{

    @Inject
    public ConfigurationExceptionMapper(MediaTypes mediaTypes)
    {
        super(mediaTypes);
    }

    @Override
    public Response toResponse(ConfigurationException ex)
    {
        return getResponseBuilder(toResource(ex, Response.Status.INTERNAL_SERVER_ERROR,
                        ResourceFactory.createResource("http://www.w3.org/2011/http-statusCodes#InternalServerError")).
                    getModel()).
                status(Response.Status.INTERNAL_SERVER_ERROR).
                build();
    }
    
}
