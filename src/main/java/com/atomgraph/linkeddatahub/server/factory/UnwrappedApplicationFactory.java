/**
 *  Copyright 2025 Martynas Jusevičius <martynas@atomgraph.com>
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

import com.atomgraph.linkeddatahub.apps.model.Application;
import jakarta.inject.Inject;
import jakarta.ws.rs.ext.Provider;
import java.util.Optional;
import org.glassfish.hk2.api.Factory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS factory that unwraps Optional&lt;Application&gt; for direct injection.
 * This allows resource constructors to inject Application directly while
 * filters and providers can inject Optional&lt;Application&gt;.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 * @see ApplicationFactory
 */
@Provider
public class UnwrappedApplicationFactory implements Factory<Application>
{

    private static final Logger log = LoggerFactory.getLogger(UnwrappedApplicationFactory.class);

    @Inject jakarta.inject.Provider<Optional<Application>> optionalApp;

    @Override
    public Application provide()
    {
        Optional<Application> appOpt = optionalApp.get();

        if (!appOpt.isPresent())
        {
            if (log.isErrorEnabled()) log.error("Application not present when unwrapping in UnwrappedApplicationFactory");
            return null; // This should only happen if ApplicationFilter threw NotFoundException
        }

        return appOpt.get();
    }

    @Override
    public void dispose(Application t)
    {
    }

}
