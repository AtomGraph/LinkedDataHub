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
package com.atomgraph.linkeddatahub.server.factory;

import com.atomgraph.linkeddatahub.apps.model.ClientApplication;
import com.atomgraph.linkeddatahub.vocabulary.APL;
import com.atomgraph.linkeddatahub.vocabulary.LAPP;
import java.util.Optional;
import javax.ws.rs.container.ContainerRequestContext;
import javax.ws.rs.core.Context;
import javax.ws.rs.ext.Provider;
import org.glassfish.hk2.api.Factory;
import org.glassfish.hk2.api.ServiceLocator;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 * @see com.atomgraph.linkeddatahub.server.model.impl.Dispatcher
 */
@Provider
public class ClientApplicationFactory implements Factory<Optional<ClientApplication>>
{

    private static final Logger log = LoggerFactory.getLogger(ClientApplicationFactory.class);
    
    @Context private ServiceLocator serviceLocator;
    
    @Override
    public Optional<ClientApplication> provide()
    {
        return getApplication(getContainerRequestContext());
    }

    @Override
    public void dispose(Optional<ClientApplication> t)
    {
    }
    
    public Optional<ClientApplication> getApplication(ContainerRequestContext crc)
    {
        return (Optional<ClientApplication>)crc.getProperty(APL.client.getURI());
    }
    
    public ContainerRequestContext getContainerRequestContext()
    {
        return serviceLocator.getService(ContainerRequestContext.class);
    }
    

}
