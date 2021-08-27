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
package com.atomgraph.linkeddatahub.server.model.impl;

import com.atomgraph.client.MediaTypes;
import com.atomgraph.client.util.DataManager;
import com.atomgraph.client.vocabulary.AC;
import com.atomgraph.linkeddatahub.client.filter.WebIDDelegationFilter;
import com.atomgraph.linkeddatahub.model.Agent;
import java.net.URI;
import javax.inject.Inject;
import javax.servlet.http.HttpServletRequest;
import javax.ws.rs.QueryParam;
import javax.ws.rs.client.WebTarget;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.HttpHeaders;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Request;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.SecurityContext;
import javax.ws.rs.core.UriInfo;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.util.FileManager;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class ExternalProxyResourceBase extends com.atomgraph.client.model.impl.ProxyResourceBase
{

    private static final Logger log = LoggerFactory.getLogger(ExternalProxyResourceBase.class);

    private final UriInfo uriInfo;
    private final DataManager dataManager;
    
    @Inject
    public ExternalProxyResourceBase(@Context UriInfo uriInfo, @Context Request request, @Context HttpHeaders httpHeaders, MediaTypes mediaTypes, @Context SecurityContext securityContext,
            com.atomgraph.linkeddatahub.Application system, @Context HttpServletRequest httpServletRequest,
            DataManager dataManager)
    {
        this(uriInfo, request, httpHeaders, mediaTypes, securityContext,
                uriInfo.getQueryParameters().getFirst(AC.uri.getLocalName()) == null ? null : URI.create(uriInfo.getQueryParameters().getFirst(AC.uri.getLocalName())),
                uriInfo.getQueryParameters().getFirst(AC.endpoint.getLocalName()) == null ? null : URI.create(uriInfo.getQueryParameters().getFirst(AC.endpoint.getLocalName())),
                uriInfo.getQueryParameters().getFirst(AC.accept.getLocalName()) == null ? null : MediaType.valueOf(uriInfo.getQueryParameters().getFirst(AC.accept.getLocalName())),
                uriInfo.getQueryParameters().getFirst(AC.mode.getLocalName()) == null ? null : URI.create(uriInfo.getQueryParameters().getFirst(AC.mode.getLocalName())),
                system, httpServletRequest, dataManager);
    }
    
    protected ExternalProxyResourceBase(@Context UriInfo uriInfo, @Context Request request, @Context HttpHeaders httpHeaders, MediaTypes mediaTypes, @Context SecurityContext securityContext,
            @QueryParam("uri") URI uri, @QueryParam("endpoint") URI endpoint, @QueryParam("accept") MediaType accept, @QueryParam("mode") URI mode,
            com.atomgraph.linkeddatahub.Application system, @Context HttpServletRequest httpServletRequest,
            DataManager dataManager)
    {
        super(uriInfo, request, httpHeaders, mediaTypes, uri, endpoint, accept, mode, system.getClient(), httpServletRequest);
        this.uriInfo = uriInfo;
        this.dataManager = dataManager;
        
        if (securityContext.getUserPrincipal() instanceof Agent &&
            securityContext.getAuthenticationScheme().equals(SecurityContext.CLIENT_CERT_AUTH))
            super.getWebTarget().register(new WebIDDelegationFilter((Agent)securityContext.getUserPrincipal()));
    }
    
    /**
     * Forwards GET request and returns response from remote resource.
     * 
     * @param target target URI
     * @return response
     */
    @Override
    public Response get(WebTarget target)
    {
        // check if we have the model in the cache first and if yes, return it from there instead making an HTTP request
        if (((FileManager)getDataManager()).hasCachedModel(target.getUri().toString()) ||
                (getDataManager().isResolvingMapped() && getDataManager().isMapped(target.getUri().toString()))) // read mapped URIs (such as system ontologies) from a file
        {
            if (log.isDebugEnabled()) log.debug("hasCachedModel({}): {}", target.getUri(), ((FileManager)getDataManager()).hasCachedModel(target.getUri().toString()));
            if (log.isDebugEnabled()) log.debug("isMapped({}): {}", target.getUri(), getDataManager().isMapped(target.getUri().toString()));
            return getResponse(getDataManager().loadModel(target.getUri().toString()));
        }
        
        // do not return the whole document if only a single resource (fragment) is requested
        if (getUriInfo().getQueryParameters().containsKey(AC.mode.getLocalName()) && 
                getUriInfo().getQueryParameters().getFirst(AC.mode.getLocalName()).equals("fragment")) // used in client.xsl
        {
            try (Response cr = target.request(getReadableMediaTypes()).get())
            {
                Model description = cr.readEntity(Model.class);
                description = ModelFactory.createDefaultModel().add(description.getResource(target.getUri().toString()).listProperties());
                return getResponse(description);
            }
        }

        return super.get(target);
    }
    
    public UriInfo getUriInfo()
    {
        return uriInfo;
    }
    
    public DataManager getDataManager()
    {
        return dataManager;
    }
    
}
