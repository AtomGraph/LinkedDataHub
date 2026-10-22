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
package com.atomgraph.linkeddatahub.resource;

import jakarta.ws.rs.NotAllowedException;
import java.util.Set;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.CALLS_REAL_METHODS;
import static org.mockito.Mockito.mock;

/**
 * Tests that the namespace endpoint's 405 names the methods it allows.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class NamespaceTest
{

    @Test
    public void testUpdateNotAllowedCarriesAllow()
    {
        NotAllowedException ex = mock(Namespace.class, CALLS_REAL_METHODS).updateNotAllowed();

        assertEquals(405, ex.getResponse().getStatus());
        assertEquals(Set.of("GET", "HEAD", "OPTIONS", "POST"), ex.getResponse().getAllowedMethods());
    }

}
