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

import java.util.Optional;
import javax.inject.Inject;
import javax.ws.rs.NotFoundException;
import javax.ws.rs.Path;

/**
 *
 * @author Martynas Jusevičius <martynas@atomgraph.com>
 */
@Path("{path: .+}")
public class Dispatcher
{
    
    private final Optional<com.atomgraph.processor.model.Application> application;
    
    @Inject
    public Dispatcher(Optional<com.atomgraph.processor.model.Application> application)
    {
        this.application = application;
    }
    
    
    @Path("{path: .+}")
    public Object getSubResource()
    {
        if (getApplication().isEmpty()) throw new NotFoundException("Application not found");

        return ResourceBase.class;
    }
    
    public Optional<com.atomgraph.processor.model.Application> getApplication()
    {
        return application;
    }
    
}
