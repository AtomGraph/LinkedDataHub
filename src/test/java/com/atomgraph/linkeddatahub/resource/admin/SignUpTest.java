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
package com.atomgraph.linkeddatahub.resource.admin;

import com.atomgraph.linkeddatahub.vocabulary.Cert;
import com.atomgraph.linkeddatahub.vocabulary.DH;
import com.atomgraph.linkeddatahub.vocabulary.FOAF;
import com.atomgraph.linkeddatahub.vocabulary.LACL;
import com.atomgraph.linkeddatahub.vocabulary.SIOC;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.vocabulary.DCTerms;
import org.apache.jena.vocabulary.RDF;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * The agent description a sign-up stores: the agent's own statements and the blank nodes they lead to, and nothing
 * the payload says about any other resource.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class SignUpTest
{

    private static final String CONTAINER = "https://admin.localhost:4443/acl/agents/";
    private static final String GROUP = "https://admin.localhost:4443/acl/groups/owners/#this";

    /** The payload of the sign-up form, with a statement about another resource added. */
    private static Model payload()
    {
        Model model = ModelFactory.createDefaultModel();
        Resource key = model.createResource().addLiteral(LACL.password, "password");
        Resource agent = model.createResource().
            addProperty(RDF.type, FOAF.Person).
            addLiteral(FOAF.givenName, "John").
            addProperty(Cert.key, key);
        agent.addProperty(FOAF.primaryTopic, agent);
        model.createResource().
            addProperty(RDF.type, DH.Item).
            addProperty(SIOC.HAS_CONTAINER, model.createResource(CONTAINER)).
            addLiteral(DCTerms.title, "whatever").
            addProperty(FOAF.primaryTopic, agent);
        model.createResource(GROUP).addProperty(FOAF.member, agent);
        return model;
    }

    @Test
    public void testDescriptionKeepsAgentAndItsBlankNodes()
    {
        Model payload = payload();
        Model description = SignUp.getAgentDescription(payload);

        Resource agent = payload.listResourcesWithProperty(RDF.type, FOAF.Person).next();
        assertTrue(description.contains(agent, FOAF.givenName));
        assertTrue(description.contains(agent, FOAF.primaryTopic, agent));
        assertTrue(description.contains(agent.getPropertyResourceValue(Cert.key), LACL.password));
    }

    @Test
    public void testDescriptionLeavesOutOtherResources()
    {
        Model description = SignUp.getAgentDescription(payload());

        assertFalse(description.contains(description.createResource(GROUP), FOAF.member));
        assertFalse(description.contains(null, SIOC.HAS_CONTAINER));
        assertFalse(description.contains(null, RDF.type, DH.Item));
    }

    @Test
    public void testDescriptionWithoutPersonIsEmpty()
    {
        Model payload = ModelFactory.createDefaultModel();
        payload.createResource(GROUP).addProperty(FOAF.member, payload.createResource());

        assertTrue(SignUp.getAgentDescription(payload).isEmpty());
    }

}
