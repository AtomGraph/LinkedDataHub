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
package com.atomgraph.linkeddatahub.model;

import com.atomgraph.core.MediaTypes;
import com.atomgraph.core.client.GraphStoreClient;
import com.atomgraph.core.client.QuadStoreClient;
import com.atomgraph.core.client.SPARQLClient;
import com.atomgraph.core.model.EndpointAccessor;
import com.atomgraph.core.model.impl.remote.EndpointAccessorImpl;
import jakarta.ws.rs.client.Client;
import jakarta.ws.rs.client.WebTarget;
import jakarta.ws.rs.core.UriBuilder;
import java.net.URI;
import org.glassfish.jersey.client.authentication.HttpAuthenticationFeature;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Deployment context for a SPARQL service.
 * Pairs a pure-data {@link Service} with the infrastructure config needed to
 * actually communicate with it: an HTTP client, media-type registry, and an optional
 * backend-proxy URI that rewrites internal endpoint URIs before sending requests.
 *
 * <p>Instances are created and owned by
 * {@link com.atomgraph.linkeddatahub.Application} during startup and exposed via
 * {@code getServiceContext(Service)}.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ServiceContext
{

    private static final Logger log = LoggerFactory.getLogger(ServiceContext.class);

    private final Service service;
    private final Client client;
    private final MediaTypes mediaTypes;
    private final Integer maxGetRequestSize;
    private final URI backendProxy;

    /**
     * Constructs a service context without a backend proxy.
     *
     * @param service the SPARQL service description
     * @param client HTTP client
     * @param mediaTypes registry of readable/writable media types
     * @param maxGetRequestSize the maximum size of SPARQL {@code GET} requests
     */
    public ServiceContext(Service service, Client client, MediaTypes mediaTypes, Integer maxGetRequestSize)
    {
        this(service, client, mediaTypes, maxGetRequestSize, null);
    }

    /**
     * Constructs a service context with an optional backend proxy.
     *
     * @param service the SPARQL service description
     * @param client HTTP client
     * @param mediaTypes registry of readable/writable media types
     * @param maxGetRequestSize the maximum size of SPARQL {@code GET} requests
     * @param backendProxy backend proxy URI used to rewrite internal endpoint URIs, or {@code null}
     */
    public ServiceContext(Service service, Client client, MediaTypes mediaTypes, Integer maxGetRequestSize, URI backendProxy)
    {
        if (service == null) throw new IllegalArgumentException("Service cannot be null");
        if (client == null) throw new IllegalArgumentException("Client cannot be null");
        if (mediaTypes == null) throw new IllegalArgumentException("MediaTypes cannot be null");
        this.service = service;
        this.client = client;
        this.mediaTypes = mediaTypes;
        this.maxGetRequestSize = maxGetRequestSize;
        this.backendProxy = backendProxy;
    }

    /**
     * Returns the SPARQL Protocol client for this service, with proxy routing applied.
     *
     * @return SPARQL client
     */
    public SPARQLClient getSPARQLClient()
    {
        return getSPARQLClient(getClient().target(getProxiedURI(URI.create(getService().getSPARQLEndpoint().getURI()))));
    }

    /**
     * Creates a SPARQL Protocol client for the specified URI web target.
     *
     * @param webTarget URI web target
     * @return SPARQL client
     */
    public SPARQLClient getSPARQLClient(WebTarget webTarget)
    {
        SPARQLClient sparqlClient;

        if (getMaxGetRequestSize() != null)
            sparqlClient = SPARQLClient.create(getMediaTypes(), webTarget, getMaxGetRequestSize());
        else
            sparqlClient = SPARQLClient.create(getMediaTypes(), webTarget);

        if (getService().getAuthUser() != null && getService().getAuthPwd() != null)
        {
            HttpAuthenticationFeature authFeature = HttpAuthenticationFeature.basicBuilder().
                credentials(getService().getAuthUser(), getService().getAuthPwd()).
                build();

            sparqlClient.getEndpoint().register(authFeature);
        }

        return sparqlClient;
    }

    /**
     * Returns the endpoint accessor for this service.
     *
     * @return endpoint accessor
     */
    public EndpointAccessor getEndpointAccessor()
    {
        return new EndpointAccessorImpl(getSPARQLClient());
    }

    /**
     * Returns the Graph Store Protocol client for this service, with proxy routing applied.
     *
     * @return GSP client
     */
    public GraphStoreClient getGraphStoreClient()
    {
        return getGraphStoreClient(getProxiedURI(URI.create(getService().getGraphStore().getURI())));
    }

    /**
     * Creates a Graph Store Protocol client for the specified endpoint URI.
     *
     * @param endpoint endpoint URI
     * @return GSP client
     */
    public GraphStoreClient getGraphStoreClient(URI endpoint)
    {
        GraphStoreClient graphStoreClient = GraphStoreClient.create(getClient(), getMediaTypes(), endpoint);

        if (getService().getAuthUser() != null && getService().getAuthPwd() != null)
        {
            HttpAuthenticationFeature authFeature = HttpAuthenticationFeature.basicBuilder().
                credentials(getService().getAuthUser(), getService().getAuthPwd()).
                build();

            graphStoreClient.register(authFeature);
        }

        return graphStoreClient;
    }

    /**
     * Returns the quad store client for this service, with proxy routing applied.
     * Returns {@code null} if the service has no quad store configured.
     *
     * @return quad store client, or {@code null}
     */
    public QuadStoreClient getQuadStoreClient()
    {
        if (getService().getQuadStore() != null)
            return getQuadStoreClient(getClient().target(getProxiedURI(URI.create(getService().getQuadStore().getURI()))));

        return null;
    }

    /**
     * Creates a quad store client for the specified URI web target.
     *
     * @param webTarget URI web target
     * @return quad store client
     */
    public QuadStoreClient getQuadStoreClient(WebTarget webTarget)
    {
        QuadStoreClient quadStoreClient = QuadStoreClient.create(webTarget);

        if (getService().getAuthUser() != null && getService().getAuthPwd() != null)
        {
            HttpAuthenticationFeature authFeature = HttpAuthenticationFeature.basicBuilder().
                credentials(getService().getAuthUser(), getService().getAuthPwd()).
                build();

            quadStoreClient.getEndpoint().register(authFeature);
        }

        return quadStoreClient;
    }

    /**
     * Rewrites the given URI by replacing its scheme/host/port with those of the backend proxy.
     * If no backend proxy is configured, the URI is returned unchanged.
     *
     * @param uri input URI
     * @return proxied URI
     */
    public URI getProxiedURI(final URI uri)
    {
        if (getBackendProxy() != null)
        {
            return UriBuilder.fromUri(uri).
                    scheme(getBackendProxy().getScheme()).
                    host(getBackendProxy().getHost()).
                    port(getBackendProxy().getPort()).
                    build();
        }

        return uri;
    }

    /**
     * Returns the SPARQL service description.
     *
     * @return service
     */
    public Service getService()
    {
        return service;
    }

    /**
     * Returns the HTTP client.
     *
     * @return HTTP client
     */
    public Client getClient()
    {
        return client;
    }

    /**
     * Returns the media type registry.
     *
     * @return media types
     */
    public MediaTypes getMediaTypes()
    {
        return mediaTypes;
    }

    /**
     * Returns the maximum size of SPARQL {@code GET} requests.
     *
     * @return request size in bytes, or {@code null} if not configured
     */
    public Integer getMaxGetRequestSize()
    {
        return maxGetRequestSize;
    }

    /**
     * Returns the backend proxy URI, used for cache invalidation BAN requests and endpoint URI rewriting.
     *
     * @return backend proxy URI, or {@code null} if not configured
     */
    public URI getBackendProxy()
    {
        return backendProxy;
    }

}
