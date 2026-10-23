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
package com.atomgraph.linkeddatahub.resource.acl;

import com.atomgraph.linkeddatahub.model.auth.Agent;
import com.atomgraph.linkeddatahub.model.auth.impl.AgentImpl;
import com.atomgraph.linkeddatahub.server.security.AgentContext;
import com.atomgraph.linkeddatahub.vocabulary.ACL;
import jakarta.ws.rs.ForbiddenException;
import jakarta.ws.rs.NotAllowedException;
import jakarta.ws.rs.WebApplicationException;
import java.util.Optional;
import java.util.Set;
import org.apache.jena.enhanced.EnhGraph;
import org.apache.jena.graph.NodeFactory;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.vocabulary.RDF;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.CALLS_REAL_METHODS;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * Tests that invalid access requests are rejected with client errors before anything is written.
 * The constructor needs the servlet configuration, so the instance is a Mockito mock calling the real methods,
 * with the agent context stubbed; the validation runs before any service is touched.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class AccessRequestTest
{

    private static final String AGENT_URI = "https://localhost:4443/admin/acl/agents/a/#this";

    protected AccessRequest getAccessRequest(Optional<AgentContext> agentContext)
    {
        AccessRequest accessRequest = mock(AccessRequest.class, CALLS_REAL_METHODS);
        doReturn(agentContext).when(accessRequest).getAgentContext();
        return accessRequest;
    }

    protected Optional<AgentContext> getAgentContext(String agentURI)
    {
        Model model = ModelFactory.createDefaultModel();
        Agent agent = new AgentImpl(NodeFactory.createURI(agentURI), (EnhGraph)model);
        AgentContext agentContext = mock(AgentContext.class);
        when(agentContext.getAgent()).thenReturn(agent);
        return Optional.of(agentContext);
    }

    protected Resource addAuthorization(Model model, String agentURI)
    {
        Resource authorization = model.createResource().
            addProperty(RDF.type, ACL.Authorization).
            addProperty(ACL.mode, ACL.Read);
        if (agentURI != null) authorization.addProperty(ACL.agent, model.createResource(agentURI));
        return authorization;
    }

    @Test
    public void testNoAuthorizationIs422()
    {
        WebApplicationException ex = assertThrows(WebApplicationException.class,
            () -> getAccessRequest(getAgentContext(AGENT_URI)).post(ModelFactory.createDefaultModel()));
        assertEquals(422, ex.getResponse().getStatus());
    }

    @Test
    public void testMissingAgentIs422()
    {
        Model model = ModelFactory.createDefaultModel();
        addAuthorization(model, null);

        WebApplicationException ex = assertThrows(WebApplicationException.class,
            () -> getAccessRequest(getAgentContext(AGENT_URI)).post(model));
        assertEquals(422, ex.getResponse().getStatus());
    }

    @Test
    public void testAgentMismatchIs403()
    {
        Model model = ModelFactory.createDefaultModel();
        addAuthorization(model, "https://localhost:4443/admin/acl/agents/b/#this");

        assertThrows(ForbiddenException.class, () -> getAccessRequest(getAgentContext(AGENT_URI)).post(model));
    }

    @Test
    public void testOneMismatchAmongSeveralIs403()
    {
        Model model = ModelFactory.createDefaultModel();
        addAuthorization(model, AGENT_URI);
        addAuthorization(model, "https://localhost:4443/admin/acl/agents/b/#this");

        assertThrows(ForbiddenException.class, () -> getAccessRequest(getAgentContext(AGENT_URI)).post(model));
    }

    @Test
    public void testUnauthenticatedIs403()
    {
        Model model = ModelFactory.createDefaultModel();
        addAuthorization(model, AGENT_URI);

        assertThrows(ForbiddenException.class, () -> getAccessRequest(Optional.empty()).post(model));
    }

    @Test
    public void testGetIs405AllowingPost()
    {
        NotAllowedException ex = assertThrows(NotAllowedException.class, () -> getAccessRequest(Optional.empty()).get());
        assertEquals(Set.of("POST", "OPTIONS"), ex.getResponse().getAllowedMethods());
    }

}
