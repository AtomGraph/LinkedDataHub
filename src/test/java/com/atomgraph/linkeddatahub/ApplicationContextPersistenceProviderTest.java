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
package com.atomgraph.linkeddatahub;

import com.atomgraph.linkeddatahub.server.util.ContextPersistence;
import com.atomgraph.linkeddatahub.server.util.ContextPersistenceProvider;
import jakarta.servlet.ServletContext;
import java.util.List;
import org.apache.jena.query.Dataset;
import org.apache.jena.query.DatasetFactory;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Which provider keeps the dataspace descriptions: none means the files, one is used, several are refused.
 */
public class ApplicationContextPersistenceProviderTest
{

    @Test
    public void testNoProviderMeansTheFiles()
    {
        assertNull(Application.contextPersistenceProvider(List.of()));
    }

    @Test
    public void testTheOneProviderIsUsed()
    {
        ContextPersistenceProvider provider = new StoreProvider();
        assertSame(provider, Application.contextPersistenceProvider(List.of(provider)));
    }

    @Test
    public void testSeveralProvidersAreRefused()
    {
        IllegalStateException ex = assertThrows(IllegalStateException.class,
            () -> Application.contextPersistenceProvider(List.of(new StoreProvider(), new OtherStoreProvider())));
        assertTrue(ex.getMessage().contains(StoreProvider.class.getName()) && ex.getMessage().contains(OtherStoreProvider.class.getName()), ex.getMessage());
    }

    static class StoreProvider implements ContextPersistenceProvider
    {

        @Override
        public ContextPersistence getPersistence(ServletContext servletContext)
        {
            return new ContextPersistence()
            {

                @Override
                public Dataset load()
                {
                    return DatasetFactory.create();
                }

                @Override
                public void persist(Dataset dataset)
                {
                }

            };
        }

    }

    static class OtherStoreProvider extends StoreProvider
    {
    }

}
