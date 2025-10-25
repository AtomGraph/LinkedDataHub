/**
 *  Copyright 2021 Martynas Jusevičius <martynas@atomgraph.com>
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
import com.atomgraph.client.vocabulary.LDT;
import com.atomgraph.core.util.Link;
import com.atomgraph.core.vocabulary.SD;
import com.atomgraph.linkeddatahub.apps.model.Application;
import com.atomgraph.linkeddatahub.apps.model.Dataset;
import com.atomgraph.linkeddatahub.model.auth.Agent;
import com.atomgraph.linkeddatahub.server.model.impl.Dispatcher;
import com.atomgraph.linkeddatahub.server.security.AuthorizationContext;
import com.atomgraph.linkeddatahub.vocabulary.ACL;
import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import jakarta.annotation.Priority;
import jakarta.inject.Inject;
import jakarta.ws.rs.Priorities;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerResponseContext;
import jakarta.ws.rs.container.ContainerResponseFilter;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.Response;
import java.util.regex.Pattern;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Response filter that sets <code>Link</code> response headers with hypermedia links.
 * 
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
@Priority(Priorities.USER + 300)
public class ResponseHeadersFilter implements ContainerResponseFilter
{

    private static final Logger log = LoggerFactory.getLogger(ResponseHeadersFilter.class);
    private static final Pattern LINK_SPLITTER = Pattern.compile(",(?=\\s*<)"); // split on commas before next '<'

    @Inject jakarta.inject.Provider<Optional<Application>> app;
    @Inject jakarta.inject.Provider<Optional<Dataset>> dataset;
    @Inject jakarta.inject.Provider<Optional<AuthorizationContext>> authorizationContext;

    @Override
    public void filter(ContainerRequestContext request, ContainerResponseContext response)throws IOException
    {
        if (response.getStatusInfo().equals(Response.Status.NO_CONTENT))
            response.getHeaders().remove(HttpHeaders.CONTENT_TYPE); // needs to be explicitly unset for some reason

        if (request.getSecurityContext().getUserPrincipal() instanceof Agent)
        {
            Agent agent = ((Agent)(request.getSecurityContext().getUserPrincipal()));
            response.getHeaders().add(HttpHeaders.LINK, new Link(URI.create(agent.getURI()), ACL.agent.getURI(), null));
        }

        if (getAuthorizationContext().isPresent())
            getAuthorizationContext().get().getModeURIs().forEach(mode -> response.getHeaders().add(HttpHeaders.LINK, new Link(mode, ACL.mode.getURI(), null)));

        List<Object> linkValues = response.getHeaders().get(HttpHeaders.LINK);
        List<Link> links = parseLinkHeaderValues(linkValues);

        if (getLinksByRel(links, SD.endpoint.getURI()).isEmpty())
            // add Link rel=sd:endpoint.
            // TO-DO: The external SPARQL endpoint URL is different from the internal one currently specified as sd:endpoint in the context dataset
            response.getHeaders().add(HttpHeaders.LINK, new Link(request.getUriInfo().getBaseUriBuilder().path(Dispatcher.class, "getSPARQLEndpoint").build(), SD.endpoint.getURI(), null));

        // Only add application-specific links if application is present
        if (getApplication().isPresent())
        {
            Application application = getApplication().get();
            // add Link rel=ldt:ontology, if the ontology URI is specified
            if (application.getOntology() != null)
                response.getHeaders().add(HttpHeaders.LINK, new Link(URI.create(application.getOntology().getURI()), LDT.ontology.getURI(), null));
            // add Link rel=ac:stylesheet, if the stylesheet URI is specified
            if (application.getStylesheet() != null)
                response.getHeaders().add(HttpHeaders.LINK, new Link(URI.create(application.getStylesheet().getURI()), AC.stylesheet.getURI(), null));
        }

        if (response.getHeaders().get(HttpHeaders.LINK) != null)
        {
            // combine Link header values into a single value because Saxon-JS 2.x is not able to deal with duplicate header names: https://saxonica.plan.io/issues/5199
            String linkValue = response.getHeaders().get(HttpHeaders.LINK).toString();
            response.getHeaders().putSingle(HttpHeaders.LINK, linkValue.substring(1, linkValue.length() - 1)); // trim leading and trailing bracket added by toString()
        }
    }

    /**
    * Parses HTTP <code>Link</code> headers into individual {@link Link} objects.
    * 
    * Handles both multiple header fields and comma-separated values
    * within a single header field.
    *
    * @param linkValues raw <code>Link</code> header values (may contain multiple entries)
    * @return flat list of parsed {@link Link} objects
    */
    protected List<Link> parseLinkHeaderValues(List<Object> linkValues)
    {
        List<Link> out = new ArrayList<>();
        if (linkValues == null) return out;

        for (Object hv : linkValues)
        {
            String[] parts = LINK_SPLITTER.split(hv.toString());
            for (String part : parts)
            {
                try
                {
                     out.add(Link.valueOf(part.trim()));
                }
                 catch (URISyntaxException e)
                {
                    // ignore invalid entries
                }
            }
        }

        return out;
    }

    /**
     * Returns all <code>Link</code> headers that match the given <code>rel</code> attribute.
     * 
     * @param links link list
     * @param rel <code>rel</code> value
     * @return filtered header list
     */
    protected List<Link> getLinksByRel(List<Link> links, String rel)
    {
        return links == null
            ? List.of()
            : links.stream()
                   .filter(link -> rel.equals(link.getRel()))
                   .toList();
    }
    
    /**
     * Returns the current application.
     *
     * @return optional application resource
     */
    public Optional<com.atomgraph.linkeddatahub.apps.model.Application> getApplication()
    {
        return app.get();
    }
    
    /**
     * Returns the current (optional) dataset resource.
     * 
     * @return optional dataset
     */
    public Optional<Dataset> getDataset()
    {
        return dataset.get();
    }
    
    /**
     * Returns the current (optional) authorization context.
     * 
     * @return optional authorization context
     */
    public Optional<AuthorizationContext> getAuthorizationContext()
    {
        return authorizationContext.get();
    }
    
}
