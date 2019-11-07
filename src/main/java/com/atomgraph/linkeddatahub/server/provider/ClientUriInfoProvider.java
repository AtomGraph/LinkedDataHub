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
package com.atomgraph.linkeddatahub.server.provider;

import com.atomgraph.linkeddatahub.server.model.impl.ClientUriInfo;
import com.sun.jersey.core.spi.component.ComponentContext;
import com.sun.jersey.spi.inject.Injectable;
import com.sun.jersey.spi.inject.PerRequestTypeInjectableProvider;
import javax.servlet.http.HttpServletRequest;
import javax.ws.rs.core.Context;
import javax.ws.rs.ext.ContextResolver;
import javax.ws.rs.ext.Provider;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS provider of client URI information.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Provider
public class ClientUriInfoProvider extends PerRequestTypeInjectableProvider<Context, ClientUriInfo> implements ContextResolver<ClientUriInfo>
{

    private static final Logger log = LoggerFactory.getLogger(ClientUriInfoProvider.class);

    @Context HttpServletRequest httpServletRequest;

    public ClientUriInfoProvider()
    {
        super(ClientUriInfo.class);
    }

    @Override
    public Injectable<ClientUriInfo> getInjectable(ComponentContext ic, Context a)
    {
        return new Injectable<ClientUriInfo>()
        {
            @Override
            public ClientUriInfo getValue()
            {
                return getClientUriInfo(getHttpServletRequest());
            }
        };
    }

    @Override
    public ClientUriInfo getContext(Class<?> type)
    {
        return getClientUriInfo(getHttpServletRequest());
    }
    
    public ClientUriInfo getClientUriInfo(HttpServletRequest httpServletRequest)
    {
        return (ClientUriInfo)httpServletRequest.getAttribute(ClientUriInfo.class.getName());
    }
    
    public HttpServletRequest getHttpServletRequest()
    {
        return httpServletRequest;
    }
    
}
