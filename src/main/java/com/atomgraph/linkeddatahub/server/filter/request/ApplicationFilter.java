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
        final URI matchURI, requestURI;
        if (request.getUriInfo().getQueryParameters().containsKey(AC.uri.getLocalName()))
        {
            // override request URI using ?uri query param
            requestURI = URI.create(request.getUriInfo().getQueryParameters().getFirst(AC.uri.getLocalName()));
            matchURI = requestURI; // TO-DO: strip query parameters
        }
        else
        {
            requestURI = request.getUriInfo().getRequestUri();
            matchURI = request.getUriInfo().getAbsolutePath();
        }
        
        Resource appResource = getSystem().matchApp(matchURI);
        if (appResource != null)
        {
            // instead of InfModel, do faster explicit checks for subclasses and add rdf:type
            if (!appResource.canAs(com.atomgraph.linkeddatahub.apps.model.Application.class))
                throw new IllegalStateException("Resource with ldt:base <" + appResource.getPropertyResourceValue(LDT.base) + "> cannot be cast to lapp:Application");
            
            appResource.addProperty(RDF.type, LAPP.Application); // without rdf:type, cannot cast to Application

            com.atomgraph.linkeddatahub.apps.model.Application app = appResource.as(com.atomgraph.linkeddatahub.apps.model.Application.class);
            request.setProperty(LAPP.Application.getURI(), Optional.of(app));

            request.setRequestUri(app.getBaseURI(), requestURI);
        }
        else
        {
            if (log.isDebugEnabled()) log.debug("Request URI {} has not matched any Application", matchURI);
            request.setProperty(LAPP.Application.getURI(), Optional.empty());
        }
    }

    public com.atomgraph.linkeddatahub.Application getSystem()
    {
        return system;
    }
    
}