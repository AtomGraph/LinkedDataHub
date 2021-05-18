/**
 *  Copyright 2021 Martynas Jusevičius <martynas@atomgraph.com>
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

import com.atomgraph.linkeddatahub.resource.graph.Item;
import com.atomgraph.linkeddatahub.server.model.ClientUriInfo;
import java.util.Optional;
import javax.inject.Inject;
import javax.ws.rs.Path;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Path("/")
public class Dispatcher
{
    
    private static final Logger log = LoggerFactory.getLogger(Dispatcher.class);

    private final Optional<com.atomgraph.processor.model.Application> application;
//    private final UriInfo uriInfo;
    private final ClientUriInfo clientUriInfo;
//    private final Optional<TemplateCall> templateCall;
    
    @Inject
    public Dispatcher(Optional<com.atomgraph.processor.model.Application> application, ClientUriInfo clientUriInfo)
    {
        this.application = application;
//        this.uriInfo = uriInfo;
        this.clientUriInfo = clientUriInfo;
//        this.templateCall = templateCall;
    }
    
    @Path("{path: .*}")
    public Object getSubResource()
    {
        if (getApplication().isEmpty())
        {
            if (log.isDebugEnabled()) log.debug("No Application matched request URI '{}', dispatching to ProxyResourceBase", getClientUriInfo().getRequestUri());
            return ProxyResourceBase.class;
        }

        // resource class loading based on the ldt:loadClass value
//        if (getTemplateCall().isPresent() && getTemplateCall().get().getTemplate().getLoadClass() != null)
//        {
//            Resource javaClass = getTemplateCall().get().getTemplate().getLoadClass();
//            if (!javaClass.isURIResource())
//            {
//                if (log.isErrorEnabled()) log.error("ldt:loadClass value of template '{}' is not a URI resource", getTemplateCall().get().getTemplate());
//                throw new OntologyException("ldt:loadClass value of template '" + getTemplateCall().get().getTemplate() + "' is not a URI resource");
//            }
//
//            Class clazz = ClsLoader.loadClass(javaClass.getURI());
//            if (clazz == null)
//            {
//                if (log.isErrorEnabled()) log.error("Java class with URI '{}' could not be loaded", javaClass.getURI());
//                throw new OntologyException("Java class with URI '" + javaClass.getURI() + "' not found");
//            }
//
//            if (log.isDebugEnabled()) log.debug("Loading Java class with URI: {}", javaClass.getURI());
//            return clazz;
//        }

        if (getClientUriInfo().getAbsolutePath().equals(getClientUriInfo().getBaseUri().resolve("sparql"))) return SPARQLEndpointImpl.class;
        if (getClientUriInfo().getAbsolutePath().equals(getClientUriInfo().getBaseUri().resolve("service"))) return GraphStoreImpl.class;
        
        return getResourceClass();
    }
    
    public Class getResourceClass()
    {
        return Item.class;
    }
    
    public Optional<com.atomgraph.processor.model.Application> getApplication()
    {
        return application;
    }
    
//    public UriInfo getUriInfo()
//    {
//        return uriInfo;
//    }
    
    public ClientUriInfo getClientUriInfo()
    {
        return clientUriInfo;
    }
//    
//    public Optional<TemplateCall> getTemplateCall()
//    {
//        return templateCall;
//    }
    
}
