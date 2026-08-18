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
package com.atomgraph.linkeddatahub.server.filter.response;

import com.atomgraph.client.vocabulary.AC;
import com.atomgraph.linkeddatahub.model.auth.Agent;
import com.atomgraph.linkeddatahub.server.model.impl.DocumentHierarchyGraphStoreImpl;
import java.io.IOException;
import java.net.URI;
import java.util.Optional;
import java.util.Set;
import jakarta.annotation.Priority;
import jakarta.inject.Inject;
import jakarta.ws.rs.HttpMethod;
import jakarta.ws.rs.Priorities;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerResponseContext;
import jakarta.ws.rs.container.ContainerResponseFilter;
import jakarta.ws.rs.core.Response;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Schedules a versioning commit after each successful document write.
 * The commit itself runs asynchronously in {@link com.atomgraph.linkeddatahub.server.util.GraphVersioningService}
 * by reconciling the graph's repository file with its current store state, so this filter never
 * delays or fails the response.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Priority(Priorities.USER + 100)
public class VersioningFilter implements ContainerResponseFilter
{

    private static final Logger log = LoggerFactory.getLogger(VersioningFilter.class);

    /** HTTP methods that modify a document graph */
    public static final Set<String> WRITE_METHODS = Set.of(HttpMethod.POST, HttpMethod.PUT, HttpMethod.PATCH, HttpMethod.DELETE);

    @Inject com.atomgraph.linkeddatahub.Application system;
    @Inject jakarta.inject.Provider<Optional<com.atomgraph.linkeddatahub.apps.model.Application>> app;

    @Override
    public void filter(ContainerRequestContext request, ContainerResponseContext response) throws IOException
    {
        if (!WRITE_METHODS.contains(request.getMethod())) return;
        if (response.getStatusInfo().getFamily() != Response.Status.Family.SUCCESSFUL) return; // excludes the PUT 308 redirect and error responses
        if (request.getProperty(AC.uri.getURI()) != null) return; // proxied request — not a local document write

        Optional<com.atomgraph.linkeddatahub.apps.model.Application> application = getApplication();
        if (application == null || application.isEmpty()) return;

        // only document graphs are versioned — literal-path resources (SPARQL endpoint, settings, ACL access, sign-up, packages) are not
        if (request.getUriInfo().getMatchedResources().stream().noneMatch(DocumentHierarchyGraphStoreImpl.class::isInstance)) return;

        String appURI = application.get().getURI();
        if (getSystem().getGraphVersioningService().getRepository(appURI).isEmpty()) return;

        URI graphURI = request.getUriInfo().getAbsolutePath();
        String agentWebID = request.getSecurityContext().getUserPrincipal() instanceof Agent agent ? agent.getURI() : "anonymous";

        if (log.isDebugEnabled()) log.debug("Scheduling versioning commit of graph <{}> after {} by <{}>", graphURI, request.getMethod(), agentWebID);
        getSystem().getGraphVersioningService().commitAsync(getSystem().getServiceContext(application.get().getService()),
            appURI, application.get().getBaseURI(), graphURI, agentWebID, request.getMethod());
    }

    /**
     * Returns the system application.
     *
     * @return system application
     */
    public com.atomgraph.linkeddatahub.Application getSystem()
    {
        return system;
    }

    /**
     * Returns the (optional) matched application.
     *
     * @return optional application
     */
    public Optional<com.atomgraph.linkeddatahub.apps.model.Application> getApplication()
    {
        return app.get();
    }

}
