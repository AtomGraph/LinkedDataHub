/**
 *  Copyright 2020 Martynas Jusevičius <martynas@atomgraph.com>
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

import com.atomgraph.processor.model.TemplateCall;
import com.atomgraph.processor.vocabulary.LDT;
import java.util.Optional;
import javax.ws.rs.container.ContainerRequestContext;
import javax.ws.rs.core.Context;
import javax.ws.rs.ext.Provider;
import org.glassfish.hk2.api.Factory;
import org.glassfish.hk2.api.ServiceLocator;

/**
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Provider
public class TemplateCallFactory implements Factory<Optional<TemplateCall>>
{

    @Context private ServiceLocator serviceLocator;

    @Override
    public Optional<TemplateCall> provide()
    {
        return getTemplateCall(getContainerRequestContext());
    }

    @Override
    public void dispose(Optional<TemplateCall> instance)
    {
    }
    
    public Optional<TemplateCall> getTemplateCall(ContainerRequestContext crc)
    {
        return (Optional<TemplateCall>)crc.getProperty(LDT.TemplateCall.getURI());
    }
    
    public ContainerRequestContext getContainerRequestContext()
    {
        return serviceLocator.getService(ContainerRequestContext.class);
    }
    
}
