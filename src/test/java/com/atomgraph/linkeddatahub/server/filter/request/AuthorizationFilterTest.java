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
package com.atomgraph.linkeddatahub.server.filter.request;

import com.atomgraph.linkeddatahub.vocabulary.ACL;
import jakarta.ws.rs.HttpMethod;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.vocabulary.RDF;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

/**
 * Unit tests for the pure authorization logic in {@link AuthorizationFilter}:
 * the HTTP-method-to-access-mode contract, mode lookup over the ACL ontology's mode hierarchy, and the owner grant.
 * These methods do not touch the injected collaborators, so the filter is exercised directly.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class AuthorizationFilterTest
{


    // HTTP method -> ACL access mode: a security-critical contract (a regression here silently changes what each verb requires)

    @Test
    public void testReadMethodsRequireRead()
    {
        assertEquals(ACL.Read, AuthorizationFilter.ACCESS_MODES.get(HttpMethod.GET));
        assertEquals(ACL.Read, AuthorizationFilter.ACCESS_MODES.get(HttpMethod.HEAD));
    }

    @Test
    public void testPostRequiresAppend()
    {
        assertEquals(ACL.Append, AuthorizationFilter.ACCESS_MODES.get(HttpMethod.POST));
    }

    @Test
    public void testWriteMethodsRequireWrite()
    {
        assertEquals(ACL.Write, AuthorizationFilter.ACCESS_MODES.get(HttpMethod.PUT));
        assertEquals(ACL.Write, AuthorizationFilter.ACCESS_MODES.get(HttpMethod.DELETE));
        assertEquals(ACL.Write, AuthorizationFilter.ACCESS_MODES.get(HttpMethod.PATCH));
    }

    @Test
    public void testUnknownMethodHasNoAccessMode()
    {
        assertNull(AuthorizationFilter.ACCESS_MODES.get(HttpMethod.OPTIONS));
    }

    // getAccessMode: the mode follows what the operation does - a create-only PUT only adds

    @Test
    public void testCreateOnlyPutRequiresAppend()
    {
        assertEquals(ACL.Append, AuthorizationFilter.getAccessMode(HttpMethod.PUT, "*"));
        assertEquals(ACL.Append, AuthorizationFilter.getAccessMode(HttpMethod.PUT, " * "));
    }

    @Test
    public void testPutWithoutCreateOnlyPreconditionRequiresWrite()
    {
        assertEquals(ACL.Write, AuthorizationFilter.getAccessMode(HttpMethod.PUT, null));
        assertEquals(ACL.Write, AuthorizationFilter.getAccessMode(HttpMethod.PUT, "\"some-tag\""));
    }

    @Test
    public void testIfNoneMatchDoesNotChangeOtherMethods()
    {
        assertEquals(ACL.Write, AuthorizationFilter.getAccessMode(HttpMethod.DELETE, "*"));
        assertEquals(ACL.Write, AuthorizationFilter.getAccessMode(HttpMethod.PATCH, "*"));
        assertEquals(ACL.Read, AuthorizationFilter.getAccessMode(HttpMethod.GET, "*"));
        assertEquals(ACL.Append, AuthorizationFilter.getAccessMode(HttpMethod.POST, null));
    }

    // getAuthorizationByMode: find an authorization in the model that grants the requested mode

    @Test
    public void testFindsAuthorizationGrantingMode()
    {
        Model model = ModelFactory.createDefaultModel();
        Resource auth = model.createResource("https://localhost/acl/authorizations/1/#this").
            addProperty(RDF.type, ACL.Authorization).
            addProperty(ACL.mode, ACL.Read).
            addProperty(ACL.mode, ACL.Append);

        assertEquals(auth, new AuthorizationFilter().getAuthorizationByMode(model, ACL.Read));
        assertEquals(auth, new AuthorizationFilter().getAuthorizationByMode(model, ACL.Append));
    }

    @Test
    public void testReturnsNullWhenNoAuthorizationGrantsMode()
    {
        Model model = ModelFactory.createDefaultModel();
        model.createResource("https://localhost/acl/authorizations/1/#this").
            addProperty(RDF.type, ACL.Authorization).
            addProperty(ACL.mode, ACL.Read);

        assertNull(new AuthorizationFilter().getAuthorizationByMode(model, ACL.Write));
    }

    // getAuthorizationByMode follows the ACL ontology: acl:Append rdfs:subClassOf acl:Write

    @Test
    public void testWriteGrantCoversAppend()
    {
        Model model = ModelFactory.createDefaultModel();
        Resource auth = model.createResource("https://localhost/acl/authorizations/1/#this").
            addProperty(RDF.type, ACL.Authorization).
            addProperty(ACL.mode, ACL.Write);

        assertEquals(auth, new AuthorizationFilter().getAuthorizationByMode(model, ACL.Append));
    }

    @Test
    public void testAppendGrantDoesNotCoverWrite()
    {
        Model model = ModelFactory.createDefaultModel();
        model.createResource("https://localhost/acl/authorizations/1/#this").
            addProperty(RDF.type, ACL.Authorization).
            addProperty(ACL.mode, ACL.Append);

        assertNull(new AuthorizationFilter().getAuthorizationByMode(model, ACL.Write));
    }

    @Test
    public void testReadGrantCoversNeitherWriteMode()
    {
        Model model = ModelFactory.createDefaultModel();
        model.createResource("https://localhost/acl/authorizations/1/#this").
            addProperty(RDF.type, ACL.Authorization).
            addProperty(ACL.mode, ACL.Read);

        assertNull(new AuthorizationFilter().getAuthorizationByMode(model, ACL.Append));
        assertNull(new AuthorizationFilter().getAuthorizationByMode(model, ACL.Write));
    }

    @Test
    public void testAccessGrantCoversNothing()
    {
        Model model = ModelFactory.createDefaultModel();
        model.createResource("https://localhost/acl/authorizations/1/#this").
            addProperty(RDF.type, ACL.Authorization).
            addProperty(ACL.mode, ACL.Access);

        assertNull(new AuthorizationFilter().getAuthorizationByMode(model, ACL.Read));
        assertNull(new AuthorizationFilter().getAuthorizationByMode(model, ACL.Append));
        assertNull(new AuthorizationFilter().getAuthorizationByMode(model, ACL.Write));
        assertNull(new AuthorizationFilter().getAuthorizationByMode(model, ACL.Control));
    }

}
