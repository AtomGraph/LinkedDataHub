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
package com.atomgraph.linkeddatahub.writer.factory;

import com.atomgraph.client.vocabulary.AC;
import com.atomgraph.linkeddatahub.writer.Mode;
import java.util.Collections;
import java.util.List;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.core.Context;
import org.glassfish.hk2.api.Factory;
import org.glassfish.hk2.api.ServiceLocator;
import jakarta.ws.rs.ext.Provider;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Factory for creating mode instances.
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
@Provider
public class ModeFactory implements Factory<List<Mode>>
{

    private static final Logger log = LoggerFactory.getLogger(ModeFactory.class);

    @Context private ServiceLocator serviceLocator;
    
    @Override
    public List<Mode> provide()
    {
        return (List<Mode>)getContainerRequestContext().getProperty(AC.mode.getURI());
    }

    @Override
    public void dispose(List<Mode> arg0)
    {
    }

    /**
     * Returns request context
     * 
     * @return request context
     */
    public ContainerRequestContext getContainerRequestContext()
    {
        return serviceLocator.getService(ContainerRequestContext.class);
    }
    
}
