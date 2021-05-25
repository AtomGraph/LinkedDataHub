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

import com.atomgraph.client.vocabulary.AC;
import com.atomgraph.core.MediaTypes;
import com.atomgraph.linkeddatahub.apps.model.Application;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import org.apache.jena.rdf.model.ResourceFactory;
import javax.ws.rs.core.Response;
import javax.ws.rs.ext.ExceptionMapper;
import javax.ws.rs.ext.Provider;
import com.atomgraph.linkeddatahub.server.exception.auth.AuthorizationException;
import com.atomgraph.linkeddatahub.vocabulary.LACL;
import com.atomgraph.processor.model.TemplateCall;
import com.atomgraph.server.mapper.ExceptionMapperBase;
import com.atomgraph.server.vocabulary.HTTP;
import java.net.URI;
import java.util.Optional;
import javax.inject.Inject;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.EntityTag;
import javax.ws.rs.core.SecurityContext;
import javax.ws.rs.core.UriBuilder;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.rdf.model.Resource;
import org.glassfish.jersey.uri.UriComponent;

/**
 * JAX-RS mapper for authorization exceptions.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Provider
public class AuthorizationExceptionMapper extends ExceptionMapperBase implements ExceptionMapper<AuthorizationException>
{
    
    private final SecurityContext securityContext;
    private final Optional<Application> application;

    @Inject
    public AuthorizationExceptionMapper(Optional<Ontology> ontology, Optional<TemplateCall> templateCall, MediaTypes mediaTypes, @Context SecurityContext securityContext, Optional<Application> application)
    {
        super(ontology, templateCall, mediaTypes);
        this.securityContext = securityContext;
        this.application = application;
    }
    
    @Override
    public Response toResponse(AuthorizationException ex)
    {
        Resource exRes = toResource(ex, Response.Status.FORBIDDEN,
            ResourceFactory.createResource("http://www.w3.org/2011/http-statusCodes#Forbidden")).
                addLiteral(HTTP.absoluteURI, ex.getAbsolutePath().toString());
        
        // add link to the endpoint for access requests. TO-DO: make the URIs configurable or best - retrieve from sitemap/dataset
        if (getApplication().isPresent() && getSecurityContext().getUserPrincipal() != null)
        {
            if (getApplication().get().canAs(EndUserApplication.class))
            {
                Resource adminBase = getApplication().get().as(EndUserApplication.class).getAdminApplication().getBase();

                URI requestClassURI = UriBuilder.fromUri(adminBase.getURI()).path("ns").fragment(LACL.AuthorizationRequest.getLocalName()).build();
                // we URI-encode values ourselves because Jersey 1.x UriBuilder fails to do so: https://java.net/jira/browse/JERSEY-1717
                String encodedRequestClassURI = UriComponent.encode(requestClassURI.toString(), UriComponent.Type.UNRESERVED);
                //String encodedRequestURI = UriComponent.encode(ex.getAbsolutePath().toString(), UriComponent.Type.UNRESERVED);

                URI requestAccessURI = UriBuilder.fromUri(adminBase.getURI()).
                    path(com.atomgraph.linkeddatahub.Application.REQUEST_ACCESS_PATH).
                    queryParam(AC.forClass.getLocalName(), encodedRequestClassURI).
                    //queryParam(LACL.requestAccessTo.getLocalName(), encodedRequestURI).
                    build();

                exRes.addProperty(LACL.requestAccess, exRes.getModel().createResource(requestAccessURI.toString()));
            }
        }
        

        return getResponseBuilder(exRes.getModel()).
            status(Response.Status.FORBIDDEN).
            tag((EntityTag)null). // unset EntityTag as it leads to caching of the 403 responses?
            build();
    }

    public SecurityContext getSecurityContext()
    {
        return securityContext;
    }
    
    public Optional<Application> getApplication()
    {
        return application;
    }
    
}
