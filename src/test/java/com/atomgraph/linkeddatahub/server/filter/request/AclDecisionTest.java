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

import com.atomgraph.linkeddatahub.server.security.AccessModes;
import com.atomgraph.linkeddatahub.server.util.AuthorizationParams;
import com.atomgraph.linkeddatahub.server.util.DocumentContext;
import com.atomgraph.linkeddatahub.vocabulary.ACL;
import com.atomgraph.linkeddatahub.vocabulary.LDHC;
import com.atomgraph.spinrdf.vocabulary.SPIN;
import java.io.StringReader;
import java.nio.file.Files;
import java.nio.file.Path;
import javax.xml.parsers.DocumentBuilderFactory;
import org.apache.jena.query.Dataset;
import org.apache.jena.query.DatasetFactory;
import org.apache.jena.query.ParameterizedSparqlString;
import org.apache.jena.query.QueryExecution;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.ResourceFactory;
import org.apache.jena.riot.Lang;
import org.apache.jena.riot.RDFParser;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assumptions.assumeTrue;

/**
 * The authorization decision - the document context query and the ACL query as <code>web.xml</code> configures them -
 * over the seeded authorizations of a fresh install, run in memory. One decision serves both dataspaces, so what keeps
 * the end-user grants out of the admin dataspace is what the grants say: the end-user ones are scoped by the hierarchy
 * (<code>acl:default</code> on the end-user root), the admin role by the admin one.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class AclDecisionTest
{

    private static final String END_USER = "https://localhost:4443/";
    private static final String ADMIN = "https://admin.localhost:4443/";

    private static final String CONTAINER = END_USER + "container/";
    private static final String ITEM = END_USER + "container/item/";
    private static final String UPLOAD = END_USER + "uploads/0123456789abcdef";
    private static final String SPARQL = END_USER + "sparql";
    private static final String ADMIN_SPARQL = ADMIN + "sparql";
    private static final String FULL_CONTROL = ADMIN + "acl/authorizations/full-control/";
    private static final String GROUPS = ADMIN + "acl/groups/";
    private static final String OWNERS = ADMIN + "acl/groups/owners/";
    private static final String USERS = ADMIN + "acl/users/";
    private static final String OWNED_ADMIN_DOC = ADMIN + "acl/authorizations/owned/";

    private static final Resource OWNER = agent("owner");
    private static final Resource WRITER = agent("writer");
    private static final Resource READER = agent("reader");
    private static final Resource DOCUMENT_OWNER = agent("document-owner");
    private static final Resource STRANGER = agent("stranger");

    private String contextQuery, aclQuery;
    private Dataset endUser, admin;

    private static Resource agent(String name)
    {
        return ResourceFactory.createResource(ADMIN + "acl/agents/" + name + "/#this");
    }

    private static String param(org.w3c.dom.Document webXml, String name)
    {
        NodeList params = webXml.getElementsByTagName("context-param");
        for (int i = 0; i < params.getLength(); i++)
        {
            Element param = (Element)params.item(i);
            if (param.getElementsByTagName("param-name").item(0).getTextContent().trim().equals(name))
                return param.getElementsByTagName("param-value").item(0).getTextContent();
        }
        throw new IllegalStateException(name + " is not configured");
    }

    private static void parse(Dataset dataset, String trig, String base)
    {
        RDFParser.create().source(new StringReader(trig)).base(base).lang(Lang.TRIG).parse(dataset);
    }

    @BeforeEach
    public void load() throws Exception
    {
        // the seeds are outside the webapp sources, which are all a Docker build of the image has
        assumeTrue(Files.exists(Path.of("platform/datasets/admin.trig")), "the platform seeds are not in this build");

        org.w3c.dom.Document webXml = DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(Path.of("src/main/webapp/WEB-INF/web.xml").toFile());
        contextQuery = param(webXml, LDHC.documentContextQuery.getURI());
        aclQuery = param(webXml, LDHC.aclQuery.getURI());

        // the admin dataset of a fresh install: admin.trig and the namespace ontology, as the entrypoint loads them
        admin = DatasetFactory.create();
        parse(admin, Files.readString(Path.of("platform/datasets/admin.trig")), ADMIN);
        parse(admin, Files.readString(Path.of("platform/namespace-ontology.trig.template")).replace("${end_user_origin}", END_USER.substring(0, END_USER.length() - 1)), ADMIN);
        parse(admin, String.format("""
            <%1$s> { <%1$s#this> <http://xmlns.com/foaf/0.1/member> <%4$s> . }
            <%2$s> { <%2$s#this> <http://xmlns.com/foaf/0.1/member> <%5$s> . }
            <%3$s> { <%3$s#this> <http://xmlns.com/foaf/0.1/member> <%6$s> . }
            <%7$s> { <%7$s> a <https://w3id.org/atomgraph/linkeddatahub/document-hierarchy#Item> ;
                         <http://rdfs.org/sioc/ns#has_container> <%8$s> ;
                         <http://www.w3.org/ns/auth/acl#owner> <%9$s> . }
            """, OWNERS, GROUPS + "writers/", GROUPS + "readers/", OWNER, WRITER, READER,
            OWNED_ADMIN_DOC, ADMIN + "acl/authorizations/", DOCUMENT_OWNER), ADMIN);

        endUser = DatasetFactory.create();
        parse(endUser, String.format("""
            @prefix dh:   <https://w3id.org/atomgraph/linkeddatahub/document-hierarchy#> .
            @prefix def:  <https://w3id.org/atomgraph/linkeddatahub/default#> .
            @prefix sioc: <http://rdfs.org/sioc/ns#> .
            @prefix acl:  <http://www.w3.org/ns/auth/acl#> .
            <%1$s> { <%1$s> a def:Root ; acl:owner <%4$s> . }
            <%2$s> { <%2$s> a dh:Container ; sioc:has_parent <%1$s> ; acl:owner <%4$s> . }
            <%3$s> { <%3$s> a dh:Item ; sioc:has_container <%2$s> ; acl:owner <%5$s> .
                     <%6$s> a <http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#FileDataObject> . }
            """, END_USER, CONTAINER, ITEM, OWNER, DOCUMENT_OWNER, UPLOAD), END_USER);
    }

    /** The decision of <code>AuthorizationFilter.authorize()</code> for a document that exists. */
    private boolean allowed(Resource agent, Resource mode, String document)
    {
        Dataset store = document.startsWith(ADMIN) ? admin : endUser;
        Resource accessTo = ResourceFactory.createResource(document);

        ParameterizedSparqlString contextPss = new ParameterizedSparqlString(contextQuery);
        contextPss.setIri(SPIN.THIS_VAR_NAME, document);
        DocumentContext context;
        try (QueryExecution qex = QueryExecution.create(contextPss.asQuery(), store))
        {
            context = new DocumentContext(qex.execSelect());
        }

        ParameterizedSparqlString aclPss = new ParameterizedSparqlString(context.applyTo(new ParameterizedSparqlString(aclQuery).asQuery()).toString());
        aclPss.setParams(new AuthorizationParams(ResourceFactory.createResource(ADMIN), accessTo, agent, context.isOwner(agent)).get());
        try (QueryExecution qex = QueryExecution.create(aclPss.asQuery(), admin))
        {
            Model authorizations = qex.execDescribe();
            return AccessModes.covering(mode).stream().anyMatch(m -> authorizations.contains(null, ACL.mode, m));
        }
    }

    /** What <code>ldh admin make-public</code> writes. */
    private void makePublic()
    {
        parse(admin, String.format("""
            @prefix acl:  <http://www.w3.org/ns/auth/acl#> .
            @prefix foaf: <http://xmlns.com/foaf/0.1/> .
            <%1$sacl/authorizations/public/> { <%1$sacl/authorizations/public/#this>
                acl:accessTo <%2$s>, <%2$ssparql> ; acl:default <%2$s> . }
            <%1$sacl/authorizations/public-sparql/> { <%1$sacl/authorizations/public-sparql/> foaf:primaryTopic <%1$sacl/authorizations/public-sparql/#this> .
                <%1$sacl/authorizations/public-sparql/#this> a acl:Authorization ; acl:agentClass foaf:Agent, acl:AuthenticatedAgent ;
                    acl:accessTo <%2$ssparql> ; acl:mode acl:Append . }
            """, ADMIN, END_USER), ADMIN);
    }

    @Test
    public void ownersAdministerBothDataspaces()
    {
        for (String document : new String[] { END_USER, ITEM, SPARQL, ADMIN, ADMIN_SPARQL, FULL_CONTROL, OWNERS, USERS })
        {
            assertTrue(allowed(OWNER, ACL.Read, document), document);
            assertTrue(allowed(OWNER, ACL.Write, document), document);
        }
    }

    @Test
    public void writersWriteTheEndUserDataspaceOnly()
    {
        assertTrue(allowed(WRITER, ACL.Write, ITEM));
        assertTrue(allowed(WRITER, ACL.Append, CONTAINER));
        for (String document : new String[] { ADMIN, ADMIN_SPARQL, FULL_CONTROL, OWNERS, USERS })
        {
            assertFalse(allowed(WRITER, ACL.Write, document), document);
            assertFalse(allowed(WRITER, ACL.Read, document), document);
        }
    }

    @Test
    public void readersReadTheEndUserDataspaceOnly()
    {
        assertTrue(allowed(READER, ACL.Read, ITEM));
        assertTrue(allowed(READER, ACL.Read, UPLOAD), "an upload is read through its class, nfo:FileDataObject");
        assertFalse(allowed(READER, ACL.Write, ITEM));
        assertFalse(allowed(READER, ACL.Read, FULL_CONTROL));
    }

    @Test
    public void ownersOfADocumentWriteItAndNothingElse()
    {
        assertTrue(allowed(DOCUMENT_OWNER, ACL.Write, ITEM));
        assertFalse(allowed(DOCUMENT_OWNER, ACL.Write, CONTAINER));
        assertFalse(allowed(DOCUMENT_OWNER, ACL.Read, END_USER));
        assertFalse(allowed(DOCUMENT_OWNER, ACL.Write, OWNED_ADMIN_DOC), "owner access is scoped to the end-user dataspace");
    }

    @Test
    public void nobodyElseHasAccessUntilMadePublic()
    {
        assertFalse(allowed(STRANGER, ACL.Read, ITEM));
        assertFalse(allowed(null, ACL.Read, ITEM));
    }

    @Test
    public void publicReachesTheEndUserDataspaceOnly()
    {
        makePublic();

        assertTrue(allowed(null, ACL.Read, ITEM));
        assertTrue(allowed(STRANGER, ACL.Read, ITEM));
        assertFalse(allowed(STRANGER, ACL.Write, ITEM));
        assertTrue(allowed(null, ACL.Read, SPARQL), "queries over GET");
        assertTrue(allowed(null, ACL.Append, SPARQL), "queries over POST");
        assertFalse(allowed(null, ACL.Append, ITEM));
        for (String document : new String[] { ADMIN, FULL_CONTROL, OWNERS, USERS })
        {
            assertFalse(allowed(null, ACL.Read, document), document);
            assertFalse(allowed(STRANGER, ACL.Read, document), document);
        }
    }

    @Test
    public void controlGrantsNothing()
    {
        parse(admin, String.format("""
            @prefix acl: <http://www.w3.org/ns/auth/acl#> .
            <%1$sacl/authorizations/control/> { <%1$sacl/authorizations/control/> <http://xmlns.com/foaf/0.1/primaryTopic> <%1$sacl/authorizations/control/#this> .
                <%1$sacl/authorizations/control/#this> a acl:Authorization ; acl:agent <%2$s> ; acl:mode acl:Control ; acl:accessTo <%3$s> . }
            """, ADMIN, STRANGER, ITEM), ADMIN);

        assertFalse(allowed(STRANGER, ACL.Write, ITEM));
        assertFalse(allowed(STRANGER, ACL.Read, ADMIN));
    }

    @Test
    public void membershipCountsOnlyInTheGroupsOwnDocument()
    {
        // the statement is in another admin document, not in the group's
        parse(admin, String.format("""
            <%1$sacl/agents/stranger/> { <%2$s#this> <http://xmlns.com/foaf/0.1/member> <%3$s> . }
            """, ADMIN, OWNERS, STRANGER), ADMIN);

        assertFalse(allowed(STRANGER, ACL.Read, FULL_CONTROL));
        assertFalse(allowed(STRANGER, ACL.Write, ITEM));
    }

    @Test
    public void authorizationCountsOnlyInItsOwnDocument()
    {
        // an authorization described in a document whose primary topic it is not
        parse(admin, String.format("""
            @prefix acl: <http://www.w3.org/ns/auth/acl#> .
            <%1$sacl/agents/stranger/> { <%1$sacl/agents/stranger/#auth> a acl:Authorization ; acl:agent <%2$s> ;
                acl:mode acl:Write ; acl:accessTo <%3$s> . }
            """, ADMIN, STRANGER, ITEM), ADMIN);

        assertFalse(allowed(STRANGER, ACL.Write, ITEM));
    }

}
