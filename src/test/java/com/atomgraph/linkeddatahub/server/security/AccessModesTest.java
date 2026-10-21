/*
 * Copyright 2026 Martynas Jusevičius <martynas@atomgraph.com>.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.atomgraph.linkeddatahub.server.security;

import com.atomgraph.linkeddatahub.model.auth.Authorization;
import com.atomgraph.linkeddatahub.model.auth.impl.AuthorizationImpl;
import com.atomgraph.linkeddatahub.vocabulary.ACL;
import java.net.URI;
import java.util.Set;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.enhanced.BuiltinPersonalities;
import org.apache.jena.vocabulary.RDF;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Unit tests for {@link AccessModes}, the access mode hierarchy read from the bundled ACL ontology, and for the
 * modes {@link AuthorizationContext} reports from it.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class AccessModesTest
{

    @BeforeAll
    public static void registerPersonalities()
    {
        BuiltinPersonalities.model.add(Authorization.class, AuthorizationImpl.factory); // as Application does at startup
    }

    @Test
    public void testAppendIsCoveredByWrite()
    {
        assertEquals(Set.of(ACL.Append, ACL.Write), AccessModes.covering(ACL.Append));
    }

    @Test
    public void testWriteIsCoveredByItselfOnly()
    {
        assertEquals(Set.of(ACL.Write), AccessModes.covering(ACL.Write));
    }

    @Test
    public void testReadAndControlAreCoveredByThemselvesOnly()
    {
        assertEquals(Set.of(ACL.Read), AccessModes.covering(ACL.Read));
        assertEquals(Set.of(ACL.Control), AccessModes.covering(ACL.Control));
    }

    @Test
    public void testWriteCoversAppend()
    {
        assertEquals(Set.of(ACL.Write, ACL.Append), AccessModes.covered(ACL.Write));
    }

    @Test
    public void testAppendCoversItselfOnly()
    {
        assertEquals(Set.of(ACL.Append), AccessModes.covered(ACL.Append));
    }

    @Test
    public void testAccessIsNotAMode()
    {
        assertTrue(AccessModes.covering(ACL.Access).isEmpty());
        assertTrue(AccessModes.covered(ACL.Access).isEmpty());
    }

    @Test
    public void testNullModeRejected()
    {
        assertThrows(IllegalArgumentException.class, () -> AccessModes.covering(null));
        assertThrows(IllegalArgumentException.class, () -> AccessModes.covered(null));
    }

    @Test
    public void testContextReportsCoveredModes()
    {
        Model model = ModelFactory.createDefaultModel();
        model.createResource("https://localhost/acl/authorizations/1/#this").
            addProperty(RDF.type, ACL.Authorization).
            addProperty(ACL.mode, ACL.Read).
            addProperty(ACL.mode, ACL.Write);

        assertEquals(Set.of(URI.create(ACL.Read.getURI()), URI.create(ACL.Write.getURI()), URI.create(ACL.Append.getURI())),
            new AuthorizationContext(model).getModeURIs());
    }

    @Test
    public void testContextDoesNotWidenAppend()
    {
        Model model = ModelFactory.createDefaultModel();
        model.createResource("https://localhost/acl/authorizations/1/#this").
            addProperty(RDF.type, ACL.Authorization).
            addProperty(ACL.mode, ACL.Append);

        assertEquals(Set.of(URI.create(ACL.Append.getURI())), new AuthorizationContext(model).getModeURIs());
    }

}
