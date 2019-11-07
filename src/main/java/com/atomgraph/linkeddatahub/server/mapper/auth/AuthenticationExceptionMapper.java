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
package com.atomgraph.linkeddatahub.server.mapper.auth;

import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ResourceFactory;
import javax.ws.rs.core.HttpHeaders;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.Response.ResponseBuilder;
import javax.ws.rs.core.Response.Status;
import javax.ws.rs.ext.ExceptionMapper;
import javax.ws.rs.ext.Provider;
import com.atomgraph.core.exception.AuthenticationException;
import com.atomgraph.server.mapper.ExceptionMapperBase;
import org.apache.jena.query.DatasetFactory;

/**
 * JAX-RS mapper for authentication exceptions.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Provider
public class AuthenticationExceptionMapper extends ExceptionMapperBase implements ExceptionMapper<AuthenticationException>
{

    @Override
    public Response toResponse(AuthenticationException ex)
    {
        Model model = toResource(ex, Response.Status.UNAUTHORIZED,
                ResourceFactory.createResource("http://www.w3.org/2011/http-statusCodes#Unauthorized")).
            getModel();
        
        ResponseBuilder builder = getResponseBuilder(DatasetFactory.create(model));
        if (ex.getRealm() != null) builder.header(HttpHeaders.WWW_AUTHENTICATE, "Basic realm=\"" + ex.getRealm() + "\"");

        return builder.status(Status.UNAUTHORIZED).build();
        
        /*
        if (ex.getRealm() != null)
            return Response.
                    status(Status.UNAUTHORIZED).
                    header(HttpHeaders.WWW_AUTHENTICATE, "Basic realm=\"" + ex.getRealm() + "\"").
                    entity(model).
                    build();
        else return Response.
                    status(Status.UNAUTHORIZED).
                    entity(model).
                    build();
        */
    }
    
}
