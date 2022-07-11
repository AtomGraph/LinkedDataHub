// Copyright 2019 Martynas Jusevičius <martynas@atomgraph.com>
// SPDX-FileCopyrightText: 2017-2022 2017 Martynas Jusevicius, <martynas@atomgraph.com> et al.
//
// SPDX-License-Identifier: Apache-2.0

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
package com.atomgraph.linkeddatahub.server.factory;

import javax.ws.rs.core.Context;
import javax.ws.rs.ext.Provider;
import com.atomgraph.linkeddatahub.apps.model.Dataset;
import com.atomgraph.linkeddatahub.vocabulary.LAPP;
import java.util.Optional;
import javax.ws.rs.container.ContainerRequestContext;
import org.glassfish.hk2.api.Factory;
import org.glassfish.hk2.api.ServiceLocator;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS factory for datasets.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 * @see com.atomgraph.linkeddatahub.server.model.impl.Dispatcher
 */
@Provider
public class DatasetFactory implements Factory<Optional<Dataset>>
{
    
    private static final Logger log = LoggerFactory.getLogger(DatasetFactory.class);
    
    @Context private ServiceLocator serviceLocator;
    
    @Override
    public Optional<Dataset> provide()
    {
        return getDataset();
    }

    @Override
    public void dispose(Optional<Dataset> t)
    {
    }
    
    /**
     * Retrieves dataset from the request context.
     * 
     * @return dataset resource
     */
    public Optional<Dataset> getDataset()
    {
        return (Optional<Dataset>)getContainerRequestContext().getProperty(LAPP.Dataset.getURI());
    }
    
    /**
     * Returns request context.
     * 
     * @return request context
     */
    public ContainerRequestContext getContainerRequestContext()
    {
        return serviceLocator.getService(ContainerRequestContext.class);
    }
    
}
