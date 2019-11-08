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

import com.atomgraph.core.exception.NotFoundException;
import com.atomgraph.linkeddatahub.vocabulary.LAPP;
import com.atomgraph.processor.vocabulary.LDT;
import com.sun.jersey.spi.container.ContainerRequest;
import com.sun.jersey.spi.container.ContainerRequestFilter;
import com.sun.jersey.spi.container.ContainerResponseFilter;
import com.sun.jersey.spi.container.ResourceFilter;
import javax.servlet.http.HttpServletRequest;
import javax.ws.rs.core.Application;
import javax.ws.rs.core.Context;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.vocabulary.RDF;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Request filter that sets request attribute with name <code>ldt:Application</code> and current application as the value
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ApplicationFilter implements ResourceFilter, ContainerRequestFilter
{

    private static final Logger log = LoggerFactory.getLogger(ApplicationFilter.class);

    @Context HttpServletRequest httpServletRequest;
    @Context Application system;

    @Override
    public ContainerRequest filter(ContainerRequest request)
    {
        Resource appResource = getSystem().matchApp(request.getAbsolutePath());
        if (appResource != null)
        {
            // instead of InfModel, do faster explicit checks for subclasses and add rdf:type
            if (!appResource.canAs(com.atomgraph.linkeddatahub.apps.model.EndUserApplication.class) &&
                    !appResource.canAs(com.atomgraph.linkeddatahub.apps.model.AdminApplication.class))
                throw new IllegalStateException("Resource with ldt:base <" + appResource.getPropertyResourceValue(LDT.base) + "> cannot be cast to lapp:Application");
            
            appResource.addProperty(RDF.type, LAPP.Application); // without rdf:type, cannot cast to Application

            com.atomgraph.linkeddatahub.apps.model.Application app = appResource.as(com.atomgraph.linkeddatahub.apps.model.Application.class);
            getHttpServletRequest().setAttribute(LAPP.Application.getURI(), app);

            request.setUris(app.getBaseURI(), request.getRequestUri());
        }
        else
        {
            if (log.isDebugEnabled()) log.debug("Resource {} has not matched any Application, returning 404 Not Found", request.getAbsolutePath());
            throw new NotFoundException("Application not found");
        }
        
        return request;
    }

    @Override
    public ContainerRequestFilter getRequestFilter()
    {
        return this;
    }

    @Override
    public ContainerResponseFilter getResponseFilter()
    {
        return null;
    }
    
    public HttpServletRequest getHttpServletRequest()
    {
        return httpServletRequest;
    }

    public com.atomgraph.linkeddatahub.Application getSystem()
    {
        return (com.atomgraph.linkeddatahub.Application)system;
    }
    
}
