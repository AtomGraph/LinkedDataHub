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
package com.atomgraph.linkeddatahub.server.filter.request;

import com.atomgraph.client.vocabulary.AC;
import com.atomgraph.linkeddatahub.apps.model.Client;
import com.atomgraph.linkeddatahub.vocabulary.APL;
import com.atomgraph.linkeddatahub.vocabulary.LAPP;
import com.atomgraph.processor.vocabulary.LDT;
import java.io.IOException;
import java.net.URI;
import java.util.Optional;
import javax.annotation.Priority;
import javax.inject.Inject;
import javax.ws.rs.container.ContainerRequestContext;
import javax.ws.rs.container.ContainerRequestFilter;
import javax.ws.rs.container.PreMatching;
import javax.ws.rs.core.UriBuilder;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.vocabulary.RDF;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Request filter that sets request attribute with name <code>ldt:Application</code> and current application as the value
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@PreMatching
@Priority(700)
public class ApplicationFilter implements ContainerRequestFilter
{

    private static final Logger log = LoggerFactory.getLogger(ApplicationFilter.class);
    
    @Inject com.atomgraph.linkeddatahub.Application system;

    @Override
    public void filter(ContainerRequestContext request) throws IOException
    {
        // there always have to be a client app
        Resource clientAppResource = getSystem().matchApp(request.getUriInfo().getAbsolutePath());
        if (clientAppResource == null) throw new IllegalStateException("Request URI '" + request.getUriInfo().getAbsolutePath() + "' has not matched any Application");

        // instead of InfModel, do faster explicit checks for subclasses and add rdf:type
        if (!clientAppResource.canAs(com.atomgraph.linkeddatahub.apps.model.Application.class) &&
                !clientAppResource.canAs(com.atomgraph.linkeddatahub.apps.model.EndUserApplication.class) &&
                !clientAppResource.canAs(com.atomgraph.linkeddatahub.apps.model.AdminApplication.class))
            throw new IllegalStateException("Resource with ldt:base <" + clientAppResource.getPropertyResourceValue(LDT.base) + "> cannot be cast to lapp:Application");

        clientAppResource.addProperty(RDF.type, LAPP.Application); // without rdf:type, cannot cast to Application
        com.atomgraph.linkeddatahub.apps.model.Application clientApp = clientAppResource.as(com.atomgraph.linkeddatahub.apps.model.Application.class);
        request.setProperty(APL.client.getURI(), Optional.of(new Client(clientApp))); // wrap into a helper class so it doesn't interfere with injection of Application

        // there might also be a server app (which might be equal to the client app)
        if (request.getUriInfo().getQueryParameters().containsKey(AC.uri.getLocalName()))
        {
            // override request URI using ?uri query param
            final URI requestURI = URI.create(request.getUriInfo().getQueryParameters().getFirst(AC.uri.getLocalName()));
            final URI matchURI = UriBuilder.fromUri(requestURI).replaceQuery(null).fragment(null).build(); // strip query parameters and fragment

            Resource appResource = getSystem().matchApp(matchURI);
            if (appResource != null)
            {
                // instead of InfModel, do faster explicit checks for subclasses and add rdf:type
                if (!appResource.canAs(com.atomgraph.linkeddatahub.apps.model.Application.class) &&
                        !appResource.canAs(com.atomgraph.linkeddatahub.apps.model.EndUserApplication.class) &&
                        !appResource.canAs(com.atomgraph.linkeddatahub.apps.model.AdminApplication.class))
                    throw new IllegalStateException("Resource with ldt:base <" + appResource.getPropertyResourceValue(LDT.base) + "> cannot be cast to lapp:Application");

                appResource.addProperty(RDF.type, LAPP.Application); // without rdf:type, cannot cast to Application

                com.atomgraph.linkeddatahub.apps.model.Application serverApp = appResource.as(com.atomgraph.linkeddatahub.apps.model.Application.class);
                if (log.isDebugEnabled()) log.debug("Request URI <{}> has matched a remote (server) Application <{}>", requestURI, serverApp.getURI());
                request.setProperty(LAPP.Application.getURI(), Optional.of(serverApp));
                request.setRequestUri(serverApp.getBaseURI(), requestURI);
            }
            else
            {
                if (log.isDebugEnabled()) log.debug("Request URI <{}> has not matched any Application", requestURI);
                request.setProperty(LAPP.Application.getURI(), Optional.empty());
            }
        }
        else
        {
            if (log.isDebugEnabled()) log.debug("Request URI <{}> has matched the local (client) Application <{}>", request.getUriInfo().getRequestUri(), clientApp.getURI());
            request.setProperty(LAPP.Application.getURI(), Optional.of(clientApp));
            request.setRequestUri(clientApp.getBaseURI(), request.getUriInfo().getRequestUri());
        }
    }

    public com.atomgraph.linkeddatahub.Application getSystem()
    {
        return system;
    }
    
}