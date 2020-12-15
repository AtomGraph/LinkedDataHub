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
package com.atomgraph.linkeddatahub.resource.oauth2.google;

import com.atomgraph.core.MediaTypes;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.server.model.ClientUriInfo;
import com.atomgraph.client.util.DataManager;
import com.atomgraph.linkeddatahub.server.model.impl.ResourceBase;
import com.atomgraph.linkeddatahub.resource.graph.Item;
import com.atomgraph.linkeddatahub.vocabulary.APLT;
import com.atomgraph.linkeddatahub.vocabulary.Google;
import com.atomgraph.processor.model.Template;
import com.atomgraph.processor.model.TemplateCall;
import java.net.URI;
import java.util.Optional;
import java.util.UUID;
import javax.inject.Inject;
import javax.servlet.http.HttpServletRequest;
import javax.ws.rs.WebApplicationException;
import javax.ws.rs.container.ResourceContext;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.HttpHeaders;
import javax.ws.rs.core.Request;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.SecurityContext;
import javax.ws.rs.core.UriBuilder;
import javax.ws.rs.core.UriInfo;
import javax.ws.rs.ext.Providers;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.rdf.model.Statement;
import org.glassfish.jersey.uri.UriComponent;
import org.mindrot.jbcrypt.BCrypt;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class Authorize extends ResourceBase
{
    
    public static final String ENDPOINT_URI = "https://accounts.google.com/o/oauth2/v2/auth";
    public static final String SCOPE = "openid email profile"; // "email profile";


    private static final Logger log = LoggerFactory.getLogger(Item.class);

    @Inject
    public Authorize(@Context UriInfo uriInfo, ClientUriInfo clientUriInfo, @Context Request request, MediaTypes mediaTypes,
            Service service, com.atomgraph.linkeddatahub.apps.model.Application application,
            Ontology ontology, Optional<TemplateCall> templateCall,
            @Context HttpHeaders httpHeaders, @Context ResourceContext resourceContext,
            @Context HttpServletRequest httpServletRequest, @Context SecurityContext securityContext,
            DataManager dataManager, @Context Providers providers,
            com.atomgraph.linkeddatahub.Application system)
    {
        super(uriInfo, clientUriInfo, request, mediaTypes,
            uriInfo.getAbsolutePath(),
            service, application,
            ontology, templateCall,
            httpHeaders, resourceContext,
            httpServletRequest, securityContext,
            dataManager, providers,
            system);
        
        if (log.isDebugEnabled()) log.debug("Constructing {}", getClass());
    }
    
    @Override
    public Response get()
    {
        String clientID = "94623832214-l46itt9or8ov4oejndd15b2gv266aqml.apps.googleusercontent.com";
        
//        Statement clientStmt = getApplication().getProperty(Google.clientID);
//        if (clientStmt == null || !clientStmt.getObject().isLiteral())
//        {
//            if (log.isWarnEnabled()) log.warn("Google client ID not specified for application '{}'", getApplication().getURI());
//            throw new WebApplicationException(new IllegalStateException("Google client ID not specified for application '" + getApplication().getURI() + "'"));
//        }
//        String clientID = clientStmt.getString();

        URI redirectUri = getUriInfo().getBaseUriBuilder().
            path(getOntology().getOntModel().getOntClass(APLT.OAuth2Login.getURI()).
                as(Template.class).getMatch().toString()). // has to be a URI template without parameters
            build();

        String state = BCrypt.hashpw(UUID.randomUUID().toString() + clientID, BCrypt.gensalt());
        
        UriBuilder authUriBuilder = UriBuilder.fromUri(ENDPOINT_URI).
            queryParam("response_type", "code").
            queryParam("client_id", clientID).
            queryParam("redirect_uri", redirectUri).
            queryParam("scope", SCOPE).
            queryParam("state", state).
            queryParam("nonce", UUID.randomUUID().toString());
        
        return Response.seeOther(authUriBuilder.build()).build();
    }
        
}
