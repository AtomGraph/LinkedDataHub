/**
 *  Copyright 2026 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.server.util;

import jakarta.servlet.ServletContext;
import java.io.IOException;

/**
 * SPI interface for providing the {@link ContextPersistence} the platform runs on.
 * Implementations are discovered via {@link java.util.ServiceLoader}. With none on the classpath the platform keeps
 * the descriptions in files; with more than one it refuses to start rather than pick one.
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public interface ContextPersistenceProvider
{

    /**
     * Returns the persistence of the dataspace descriptions. Called once, while the platform is being constructed.
     *
     * @param servletContext the servlet context, for the provider's own init parameters
     * @return the persistence
     * @throws IOException if the store it describes cannot be reached
     */
    ContextPersistence getPersistence(ServletContext servletContext) throws IOException;

}
