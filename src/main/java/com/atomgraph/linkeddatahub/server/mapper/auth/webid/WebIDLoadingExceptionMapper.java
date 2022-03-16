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
package com.atomgraph.linkeddatahub.server.mapper.auth.webid;

import com.atomgraph.core.MediaTypes;
import com.atomgraph.linkeddatahub.server.exception.auth.webid.WebIDLoadingException;
import com.atomgraph.server.mapper.ExceptionMapperBase;
import javax.inject.Inject;
import javax.ws.rs.core.Response;
import javax.ws.rs.ext.ExceptionMapper;
import org.apache.jena.rdf.model.ResourceFactory;

/**
 * JAX-RS mapper for WebID loading exceptions.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class WebIDLoadingExceptionMapper extends ExceptionMapperBase implements ExceptionMapper<WebIDLoadingException>
{

    /**
     * Constructs mapper from media types.
     * 
     * @param mediaTypes registry of readable/writable media types
     */
    @Inject
    public WebIDLoadingExceptionMapper(MediaTypes mediaTypes)
    {
        super(mediaTypes);
    }
    
    @Override
    public Response toResponse(WebIDLoadingException ex)
    {
        return getResponseBuilder(toResource(ex, Response.Status.BAD_REQUEST,
                    ResourceFactory.createResource("http://www.w3.org/2011/http-statusCodes#BadRequest")).
                getModel()).
            status(Response.Status.BAD_REQUEST).
            build();
    }
    
}
