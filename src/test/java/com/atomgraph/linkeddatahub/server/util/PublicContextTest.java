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

import com.atomgraph.linkeddatahub.dataspaces.model.AdminDataspace;
import com.atomgraph.linkeddatahub.dataspaces.model.Dataspace;
import com.atomgraph.linkeddatahub.dataspaces.model.EndUserDataspace;
import com.atomgraph.linkeddatahub.vocabulary.LDS;
import java.io.StringReader;
import org.apache.jena.enhanced.BuiltinPersonalities;
import org.apache.jena.query.Dataset;
import org.apache.jena.query.DatasetFactory;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.riot.Lang;
import org.apache.jena.riot.RDFParser;
import org.apache.jena.vocabulary.DCTerms;
import org.apache.jena.vocabulary.RDF;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

/**
 * Tests that the public view of the context dataset keeps the dataspace descriptions, withholds the services and
 * credentials, and publishes the admin pairing.
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class PublicContextTest
{

    static
    {
        org.apache.jena.sys.JenaSystem.init(); // before BuiltinPersonalities, whose static initializer otherwise starts Jena out of order
    }

    /** The shape of <code>system.nq</code>: dataspaces.trig, system.trig and the credentials secret merged by graph name. */
    private static final String CONTEXT = """
        PREFIX lds:  <https://w3id.org/atomgraph/linkeddatahub/dataspaces#>
        PREFIX ac:   <https://w3id.org/atomgraph/client#>
        PREFIX a:    <https://w3id.org/atomgraph/core#>
        PREFIX sd:   <http://www.w3.org/ns/sparql-service-description#>
        PREFIX dct:  <http://purl.org/dc/terms/>
        PREFIX doap: <http://usefulinc.com/ns/doap#>

        <urn:linkeddatahub:apps/end-user> {
            <urn:linkeddatahub:apps/end-user> a lds:Dataspace, lds:EndUserDataspace ;
                dct:title "LinkedDataHub" ;
                lds:origin <https://localhost:4443> ;
                lds:ontology <https://localhost:4443/ns#> ;
                ac:stylesheet <https://localhost:4443/static/xsl/layout.xsl> ;
                lds:public true ;
                lds:service <urn:linkeddatahub:services/end-user> ;
                lds:versioningRepository <urn:linkeddatahub:versioning/end-user> .
        }
        <urn:linkeddatahub:apps/admin> {
            <urn:linkeddatahub:apps/admin> a lds:Dataspace, lds:AdminDataspace ;
                dct:title "LinkedDataHub admin" ;
                lds:origin <https://admin.localhost:4443> ;
                lds:service <urn:linkeddatahub:services/admin> .
        }
        <urn:linkeddatahub:apps/orphan> {
            <urn:linkeddatahub:apps/orphan> a lds:Dataspace, lds:EndUserDataspace ;
                dct:title "Orphan" ;
                lds:origin <https://orphan.localhost:4443> .
        }
        <urn:linkeddatahub:services/end-user> {
            <urn:linkeddatahub:services/end-user> a sd:Service ;
                sd:endpoint <http://fuseki:3030/end-user/sparql> ;
                a:graphStore <http://fuseki:3030/end-user/> ;
                a:authUser "user" ;
                a:authPwd "secret-password" ;
                a:authToken "secret-bearer" .
        }
        <urn:linkeddatahub:versioning/end-user> {
            <urn:linkeddatahub:versioning/end-user> a doap:GitRepository ;
                doap:location <https://github.com/example/versions> ;
                a:authToken "secret-github" .
        }
        """;

    private static Model context;
    private static Model view;

    @BeforeAll
    public static void setUp()
    {
        BuiltinPersonalities.model.add(AdminDataspace.class, new com.atomgraph.linkeddatahub.dataspaces.model.admin.impl.AdminDataspaceImplementation());
        BuiltinPersonalities.model.add(EndUserDataspace.class, new com.atomgraph.linkeddatahub.dataspaces.model.end_user.impl.EndUserDataspaceImplementation());
        BuiltinPersonalities.model.add(Dataspace.class, new com.atomgraph.linkeddatahub.dataspaces.model.impl.DataspaceImplementation());

        Dataset dataset = DatasetFactory.create();
        RDFParser.create().source(new StringReader(CONTEXT)).lang(Lang.TRIG).parse(dataset);
        context = dataset.getUnionModel();
        view = PublicContext.of(context, false);
    }

    @Test
    public void testWithholdsCredentials()
    {
        assertFalse(view.listStatements().toList().stream().anyMatch(stmt -> stmt.getPredicate().getURI().startsWith("https://w3id.org/atomgraph/core#")));
        assertFalse(view.listStatements().toList().stream().anyMatch(stmt -> stmt.getObject().isLiteral() && stmt.getString().startsWith("secret")));
    }

    @Test
    public void testWithholdsServicesAndRepositories()
    {
        assertFalse(view.contains(view.createResource("urn:linkeddatahub:services/end-user"), null));
        assertFalse(view.contains(view.createResource("urn:linkeddatahub:versioning/end-user"), null));
        assertFalse(view.contains(null, LDS.service));
        assertFalse(view.contains(null, LDS.versioningRepository));
        assertFalse(view.listStatements().toList().stream().anyMatch(stmt -> stmt.getObject().isURIResource() && stmt.getResource().getURI().contains("fuseki")));
    }

    @Test
    public void testKeepsEveryDataspace()
    {
        assertEquals(3, view.listResourcesWithProperty(RDF.type, LDS.Dataspace).toList().size());

        Resource endUser = view.createResource("urn:linkeddatahub:apps/end-user");
        assertTrue(endUser.hasProperty(RDF.type, LDS.EndUserDataspace));
        assertTrue(endUser.hasLiteral(DCTerms.title, "LinkedDataHub"));
        assertTrue(endUser.hasProperty(LDS.origin, view.createResource("https://localhost:4443")));
        assertTrue(endUser.hasProperty(LDS.ontology, view.createResource("https://localhost:4443/ns#")));
        assertTrue(view.createResource("urn:linkeddatahub:apps/admin").hasProperty(RDF.type, LDS.AdminDataspace));
    }

    @Test
    public void testPublishesAdminPairing()
    {
        assertTrue(view.contains(view.createResource("urn:linkeddatahub:apps/end-user"), LDS.admin, view.createResource("https://admin.localhost:4443/")));
        // an admin dataspace has no admin, and an end-user dataspace without one gets none
        assertFalse(view.contains(view.createResource("urn:linkeddatahub:apps/admin"), LDS.admin));
        assertFalse(view.contains(view.createResource("urn:linkeddatahub:apps/orphan"), LDS.admin));
    }

    @Test
    public void testPublishesAssistantOnlyWhenEnabled()
    {
        assertFalse(view.contains(null, LDS.assistant));

        // every dataspace, admin included: the assistant opens wherever a document can be appended to
        Model enabled = PublicContext.of(context, true);
        assertEquals(3, enabled.listResourcesWithProperty(LDS.assistant, true).toList().size());
    }

}
