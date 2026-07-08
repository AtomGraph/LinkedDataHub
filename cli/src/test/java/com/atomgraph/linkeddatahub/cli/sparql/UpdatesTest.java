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

package com.atomgraph.linkeddatahub.cli.sparql;

import java.net.URI;
import org.apache.jena.query.Syntax;
import org.apache.jena.update.UpdateFactory;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Tests for {@link Updates}: every template must be valid standard SPARQL 1.1.
 */
public class UpdatesTest
{

    private static final URI DOC = URI.create("https://localhost:4443/some/");
    private static final URI BASE = URI.create("https://localhost:4443/");
    private static final URI ADMIN_BASE = URI.create("https://admin.localhost:4443/");

    @Test
    public void insertOntologyImportIsValidSPARQL11()
    {
        String update = Updates.insertOntologyImport(DOC, URI.create("https://example.org/ontology#"));

        assertDoesNotThrow(() -> UpdateFactory.create(update, Syntax.syntaxSPARQL_11));
        assertTrue(update.contains("<https://example.org/ontology#>"));
    }

    @Test
    public void insertGroupMemberIsValidSPARQL11()
    {
        String update = Updates.insertGroupMember(DOC, URI.create("https://localhost:4443/agents/x/#this"));

        assertDoesNotThrow(() -> UpdateFactory.create(update, Syntax.syntaxSPARQL_11));
        assertTrue(update.contains("<https://localhost:4443/agents/x/#this>"));
    }

    @Test
    public void removeBlockWithoutBlockKeepsVariable()
    {
        String update = Updates.removeBlock(DOC, null);

        assertDoesNotThrow(() -> UpdateFactory.create(update, Syntax.syntaxSPARQL_11));
        assertTrue(update.contains("?block"));
    }

    @Test
    public void removeBlockWithBlockInjectsIRI()
    {
        String update = Updates.removeBlock(DOC, URI.create("https://localhost:4443/some/#block"));

        assertDoesNotThrow(() -> UpdateFactory.create(update, Syntax.syntaxSPARQL_11));
        assertTrue(update.contains("<https://localhost:4443/some/#block>"));
        assertFalse(update.contains("?block"));
    }

    @Test
    public void makePublicIsValidSPARQL11()
    {
        String update = Updates.makePublic(BASE, ADMIN_BASE);

        assertDoesNotThrow(() -> UpdateFactory.create(update, Syntax.syntaxSPARQL_11));
        assertTrue(update.contains("<https://localhost:4443/sparql>"));
        assertTrue(update.contains("<https://admin.localhost:4443/acl/authorizations/public/#this>"));
        assertTrue(update.contains("<https://admin.localhost:4443/acl/authorizations/public/#sparql-post>"));
    }

}
