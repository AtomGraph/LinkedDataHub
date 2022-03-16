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

import com.atomgraph.core.MediaTypes;
import com.atomgraph.linkeddatahub.apps.model.AdminApplication;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import static com.atomgraph.linkeddatahub.resource.oauth2.google.Authorize.REFERER_PARAM_NAME;
import com.atomgraph.linkeddatahub.server.filter.request.auth.IDTokenFilter;
import com.atomgraph.server.mapper.ExceptionMapperBase;
import com.auth0.jwt.exceptions.TokenExpiredException;
import java.net.URI;
import javax.inject.Inject;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.NewCookie;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.Response.ResponseBuilder;
import javax.ws.rs.core.Response.Status;
import javax.ws.rs.core.UriBuilder;
import javax.ws.rs.core.UriInfo;
import javax.ws.rs.ext.ExceptionMapper;
import org.apache.jena.rdf.model.ResourceFactory;

/**
 * Token expiration exception mapper
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class TokenExpiredExceptionMapper extends ExceptionMapperBase implements ExceptionMapper<TokenExpiredException>
{

    @Context UriInfo uriInfo;
    @Inject javax.inject.Provider<com.atomgraph.linkeddatahub.apps.model.Application> application;

    /**
     * Constructs mapper from media types.
     * 
     * @param mediaTypes registry of readable/writable media types
     */
    @Inject
    public TokenExpiredExceptionMapper(MediaTypes mediaTypes)
    {
        super(mediaTypes);
    }

    @Override
    public Response toResponse(TokenExpiredException ex)
    {
        String path = getApplication().getBaseURI().getPath();
        NewCookie expiredCookie = new NewCookie(IDTokenFilter.COOKIE_NAME, "", path, null, NewCookie.DEFAULT_VERSION, null, 0, false);

        ResponseBuilder builder = getResponseBuilder(toResource(ex, Response.Status.BAD_REQUEST,
                    ResourceFactory.createResource("http://www.w3.org/2011/http-statusCodes#BadRequest")).
                getModel()).
            cookie(expiredCookie);
        
        URI redirectUri = UriBuilder.fromUri(getAdminApplication().getBaseURI()).
            path("/oauth2/authorize/google"). // TO-DO: move to config?
            queryParam(REFERER_PARAM_NAME, getUriInfo().getRequestUri()). // we need to retain URL query parameters
            build();
        
        if (!getUriInfo().getAbsolutePath().equals(redirectUri)) // prevent a perpetual redirect loop
            builder.status(Status.SEE_OTHER).
                location(redirectUri); // TO-DO: extract
        
        return builder.build();
    }
    
    /**
     * Returns admin application of the current dataspace.
     * 
     * @return admin application resource
     */
    public AdminApplication getAdminApplication()
    {
        if (getApplication().canAs(EndUserApplication.class))
            return getApplication().as(EndUserApplication.class).getAdminApplication();
        else
            return getApplication().as(AdminApplication.class);
    }
    
    /**
     * Returns current application.
     * 
     * @return application resource
     */
    public com.atomgraph.linkeddatahub.apps.model.Application getApplication()
    {
        return application.get();
    }
    
    @Override
    public UriInfo getUriInfo()
    {
        return uriInfo;
    }
    
}
