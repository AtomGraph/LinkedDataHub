/**
 *  Copyright 2020 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.server.mapper.auth.oauth2;

import com.atomgraph.linkeddatahub.server.filter.request.auth.IDTokenFilter;
import com.atomgraph.server.mapper.ExceptionMapperBase;
import com.auth0.jwt.exceptions.TokenExpiredException;
import java.net.URI;
import javax.inject.Inject;
import javax.ws.rs.core.NewCookie;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.Response.Status;
import javax.ws.rs.ext.ExceptionMapper;
import org.apache.jena.query.DatasetFactory;
import org.apache.jena.rdf.model.ResourceFactory;

/**
 *
 * @author Martynas Jusevičius <martynas@atomgraph.com>
 */
public class TokenExpiredExceptionMapper extends ExceptionMapperBase implements ExceptionMapper<TokenExpiredException>
{
    
    @Inject com.atomgraph.linkeddatahub.apps.model.Application app;

    @Override
    public Response toResponse(TokenExpiredException ex)
    {
        String path = getApplication().getBaseURI().getPath();
        NewCookie expiredCookie = new NewCookie(IDTokenFilter.COOKIE_NAME, "", path, null, NewCookie.DEFAULT_VERSION, null, 0, false);

        return getResponseBuilder(DatasetFactory.create(toResource(ex, Response.Status.BAD_REQUEST,
                    ResourceFactory.createResource("http://www.w3.org/2011/http-statusCodes#BadRequest")).
                getModel())).
            cookie(expiredCookie).
            status(Status.SEE_OTHER).
            location(URI.create("https://localhost:4443/admin/oauth2/authorize/google")).
            build();
    }
    
    public com.atomgraph.linkeddatahub.apps.model.Application getApplication()
    {
        return app;
    }
    
}
