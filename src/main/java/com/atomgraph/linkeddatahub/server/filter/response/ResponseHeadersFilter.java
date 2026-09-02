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

import com.atomgraph.client.util.HTMLMediaTypePredicate;
import com.atomgraph.client.vocabulary.AC;
import com.atomgraph.client.vocabulary.LDT;
import com.atomgraph.core.vocabulary.SD;
import com.atomgraph.linkeddatahub.server.util.LanguageNegotiator;
import com.atomgraph.linkeddatahub.apps.model.Application;
import com.atomgraph.linkeddatahub.apps.model.Dataset;
import com.atomgraph.linkeddatahub.model.auth.Agent;
import com.atomgraph.linkeddatahub.server.model.impl.Dispatcher;
import com.atomgraph.linkeddatahub.server.model.impl.DocumentHierarchyGraphStoreImpl;
import com.atomgraph.linkeddatahub.server.security.AuthorizationContext;
import com.atomgraph.linkeddatahub.server.util.Link;
import com.atomgraph.linkeddatahub.vocabulary.ACL;
import com.atomgraph.linkeddatahub.vocabulary.LAPP;
import com.atomgraph.linkeddatahub.writer.TimeMapWriter;
import java.io.IOException;
import java.net.URI;
import java.util.Optional;
import jakarta.annotation.Priority;
import jakarta.inject.Inject;
import jakarta.ws.rs.Priorities;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerResponseContext;
import jakarta.ws.rs.container.ContainerResponseFilter;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.Response;
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

    @Inject com.atomgraph.linkeddatahub.Application system;
    @Inject jakarta.inject.Provider<Optional<Application>> app;
    @Inject jakarta.inject.Provider<Optional<Dataset>> dataset;
    @Inject jakarta.inject.Provider<Optional<AuthorizationContext>> authorizationContext;

    @Override
    public void filter(ContainerRequestContext request, ContainerResponseContext response)throws IOException
    {
        if (response.getStatusInfo().equals(Response.Status.NO_CONTENT))
            response.getHeaders().remove(HttpHeaders.CONTENT_TYPE); // needs to be explicitly unset for some reason

        // Content-Language states the language of the representation, and must agree with the document's own <html lang>.
        // Both come from this one computation. Variant selection cannot supply it: it matched only when the reader's top
        // preference happened to be an offered language, so it announced es on a page holding no Spanish and said nothing
        // at all on a page that was entirely Lithuanian
        // only where the rendering actually depends on language. An RDF representation is byte-identical for every reader -
        // its literals carry their own tags and none is dropped - so it is intended for all language audiences, which RFC 9110
        // spells as no Content-Language at all. Labelling it would also contradict its own Vary, which carries no
        // Accept-Language dimension for exactly the same reason
        if (response.hasEntity() && response.getMediaType() != null && getApplication().isPresent() && new HTMLMediaTypePredicate().test(response.getMediaType()))
            response.getHeaders().putSingle(HttpHeaders.CONTENT_LANGUAGE,
                LanguageNegotiator.publishedTag(request.getAcceptableLanguages(), getSystem().getSupportedLanguages()));

        if (request.getSecurityContext().getUserPrincipal() instanceof Agent)
        {
            Agent agent = ((Agent)(request.getSecurityContext().getUserPrincipal()));
            response.getHeaders().add(HttpHeaders.LINK, new Link(URI.create(agent.getURI()), ACL.agent.getURI(), null));
        }

        boolean isTimeMap = request.getUriInfo().getQueryParameters().containsKey(DocumentHierarchyGraphStoreImpl.TIMEMAP_PARAM_NAME);
        boolean isTimeGate = request.getUriInfo().getQueryParameters().containsKey(DocumentHierarchyGraphStoreImpl.TIMEGATE_PARAM_NAME);
        // historical version, TimeMap and TimeGate views are read-only: advertise acl:Read at most, so the UI disables edit affordances
        boolean isSnapshotRequest = DocumentHierarchyGraphStoreImpl.isSnapshotRequest(request.getUriInfo());

        if (getAuthorizationContext().isPresent())
            getAuthorizationContext().get().getModeURIs().stream().
                filter(mode -> !isSnapshotRequest || mode.toString().equals(ACL.Read.getURI())).
                forEach(mode -> response.getHeaders().add(HttpHeaders.LINK, new Link(mode, ACL.mode.getURI(), null)));

        // for proxy requests the external Link headers are forwarded by ProxyRequestFilter; suppress local-only hypermedia
        boolean isProxyRequest = request.getProperty(AC.uri.getURI()) != null;

        if (!isProxyRequest)
            response.getHeaders().add(HttpHeaders.LINK, new Link(request.getUriInfo().getBaseUriBuilder().path(Dispatcher.class, "getSPARQLEndpoint").build(), SD.endpoint.getURI(), null));

        // Only add application-specific links if application is present and this is not a proxy request
        if (!isProxyRequest && getApplication().isPresent())
        {
            Application application = getApplication().get();
            // add Link rel=lapp:application
            response.getHeaders().add(HttpHeaders.LINK, new Link(URI.create(application.getURI()), LAPP.application.getURI(), null));
            // add Link rel=ldt:ontology, if the ontology URI is specified
            if (application.getOntology() != null)
                response.getHeaders().add(HttpHeaders.LINK, new Link(URI.create(application.getOntology().getURI()), LDT.ontology.getURI(), null));
            // add Memento (RFC 7089) hypermedia, if the document is versioned
            if (getSystem().getGraphVersioningService().getRepository(application.getURI()).isPresent() &&
                    request.getUriInfo().getMatchedResources().stream().anyMatch(DocumentHierarchyGraphStoreImpl.class::isInstance))
            {
                URI originalURI = request.getUriInfo().getAbsolutePath(); // the query is what makes a URI a Memento, TimeMap or TimeGate
                URI timeMapURI = URI.create(originalURI + "?" + DocumentHierarchyGraphStoreImpl.TIMEMAP_PARAM_NAME);
                URI timeGateURI = URI.create(originalURI + "?" + DocumentHierarchyGraphStoreImpl.TIMEGATE_PARAM_NAME);

                // the TimeMap identifies itself with rel=self; everything else points at it with rel=timemap
                if (isTimeMap)
                    response.getHeaders().add(HttpHeaders.LINK, new Link(timeMapURI, "self", TimeMapWriter.APPLICATION_LINK_FORMAT));
                else
                    response.getHeaders().add(HttpHeaders.LINK, new Link(timeMapURI, "timemap", TimeMapWriter.APPLICATION_LINK_FORMAT));

                // the Original Resource MUST advertise a preferred TimeGate; the TimeGate does not link to itself
                if (!isTimeGate)
                    response.getHeaders().add(HttpHeaders.LINK, new Link(timeGateURI, "timegate", null));

                // a Memento and a TimeGate MUST link to the Original Resource, and a TimeMap lists it;
                // the Original Resource itself MUST NOT carry rel=original
                if (isSnapshotRequest)
                    response.getHeaders().add(HttpHeaders.LINK, new Link(originalURI, "original", null));
            }
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
     * Returns the system application.
     *
     * @return system application
     */
    public com.atomgraph.linkeddatahub.Application getSystem()
    {
        return system;
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
