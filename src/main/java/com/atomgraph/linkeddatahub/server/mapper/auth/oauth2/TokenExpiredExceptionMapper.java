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
import com.atomgraph.linkeddatahub.apps.model.Application;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import static com.atomgraph.linkeddatahub.resource.oauth2.google.Authorize.REFERER_PARAM_NAME;
import com.atomgraph.linkeddatahub.server.filter.request.auth.IDTokenFilter;
import com.atomgraph.processor.model.TemplateCall;
import com.atomgraph.server.mapper.ExceptionMapperBase;
import com.auth0.jwt.exceptions.TokenExpiredException;
import java.net.URI;
import java.util.Optional;
import javax.inject.Inject;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.NewCookie;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.Response.ResponseBuilder;
import javax.ws.rs.core.Response.Status;
import javax.ws.rs.core.UriBuilder;
import javax.ws.rs.core.UriInfo;
import javax.ws.rs.ext.ExceptionMapper;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.query.DatasetFactory;
import org.apache.jena.rdf.model.ResourceFactory;

/**
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class TokenExpiredExceptionMapper extends ExceptionMapperBase implements ExceptionMapper<TokenExpiredException>
{

    private final UriInfo uriInfo;
    private final Optional<com.atomgraph.linkeddatahub.apps.model.Application> app;

    @Inject
    public TokenExpiredExceptionMapper(Optional<Ontology> ontology, Optional<TemplateCall> templateCall, MediaTypes mediaTypes, @Context UriInfo uriInfo, Optional<Application> app)
    {
        super(ontology, templateCall, mediaTypes);
        this.uriInfo = uriInfo;
        this.app = app;
    }

    @Override
    public Response toResponse(TokenExpiredException ex)
    {
        String path = getApplication().get().getBaseURI().getPath();
        NewCookie expiredCookie = new NewCookie(IDTokenFilter.COOKIE_NAME, "", path, null, NewCookie.DEFAULT_VERSION, null, 0, false);

        ResponseBuilder builder = getResponseBuilder(DatasetFactory.create(toResource(ex, Response.Status.BAD_REQUEST,
                    ResourceFactory.createResource("http://www.w3.org/2011/http-statusCodes#BadRequest")).
                getModel())).
            cookie(expiredCookie);
        
        URI redirectUri = UriBuilder.fromUri(getAdminBaseURI()).
            path("/oauth2/authorize/google"). // TO-DO: move to config?
            queryParam(REFERER_PARAM_NAME, getUriInfo().getAbsolutePath()).
            build();
        
        if (!getUriInfo().getAbsolutePath().equals(redirectUri)) // prevent a perpetual redirect loop
            builder.status(Status.SEE_OTHER).
                location(redirectUri); // TO-DO: extract
        
        return builder.build();
    }
    
    public URI getAdminBaseURI()
    {
        if (getApplication().get().canAs(EndUserApplication.class))
            return getApplication().get().as(EndUserApplication.class).getAdminApplication().getBaseURI();
        else
            return getApplication().get().getBaseURI();
    }
    
    public Optional<com.atomgraph.linkeddatahub.apps.model.Application> getApplication()
    {
        return app;
    }
    
    @Override
    public UriInfo getUriInfo()
    {
        return uriInfo;
    }
    
}
