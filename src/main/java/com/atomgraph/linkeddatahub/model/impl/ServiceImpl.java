// Copyright 2019 Martynas Jusevičius <martynas@atomgraph.com>
// SPDX-FileCopyrightText: 2017-2022 2017 Martynas Jusevicius, <martynas@atomgraph.com> et al.
//
// SPDX-License-Identifier: Apache-2.0


/**
 *  Copyright 2019 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.model.impl;

import com.atomgraph.core.MediaTypes;
import com.atomgraph.core.client.GraphStoreClient;
import com.atomgraph.core.client.QuadStoreClient;
import com.atomgraph.core.client.SPARQLClient;
import com.atomgraph.core.model.DatasetAccessor;
import com.atomgraph.core.model.DatasetQuadAccessor;
import com.atomgraph.core.model.EndpointAccessor;
import com.atomgraph.core.model.impl.remote.DatasetAccessorImpl;
import com.atomgraph.core.model.impl.remote.DatasetQuadAccessorImpl;
import com.atomgraph.core.model.impl.remote.EndpointAccessorImpl;
import com.atomgraph.core.vocabulary.A;
import com.atomgraph.core.vocabulary.SD;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.vocabulary.LAPP;
import java.net.URI;
import javax.ws.rs.client.Client;
import javax.ws.rs.client.WebTarget;
import javax.ws.rs.core.UriBuilder;
import org.apache.jena.enhanced.EnhGraph;
import org.apache.jena.graph.Node;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.Statement;
import org.apache.jena.rdf.model.impl.ResourceImpl;
import org.glassfish.jersey.client.authentication.HttpAuthenticationFeature;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * SPARQL service implementation.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ServiceImpl extends ResourceImpl implements Service
{

    private static final Logger log = LoggerFactory.getLogger(ServiceImpl.class);

    private final Client client;
    private final MediaTypes mediaTypes;
    private final Integer maxGetRequestSize;
    
    /**
     * Constructs instance from node, graph, and HTTP config.
     * 
     * @param n node
     * @param g graph
     * @param client HTTP client
     * @param mediaTypes registry of readable/writable media types
     * @param maxGetRequestSize the maximum size of SPARQL <code>GET</code> requests
     */
    public ServiceImpl(Node n, EnhGraph g, Client client, MediaTypes mediaTypes, Integer maxGetRequestSize)
    {
        super(n, g);
        this.client = client;
        this.mediaTypes = mediaTypes;
        this.maxGetRequestSize = maxGetRequestSize;
    }
    
    @Override
    public Resource getSPARQLEndpoint()
    {
        return getPropertyResourceValue(SD.endpoint);
    }

    @Override
    public Resource getGraphStore()
    {
        return getPropertyResourceValue(A.graphStore);
    }

    @Override
    public Resource getQuadStore()
    {
        return getPropertyResourceValue(A.quadStore);
    }
    
    @Override
    public Resource getProxy()
    {
        return getPropertyResourceValue(LAPP.proxy);
    }
    
    @Override
    public String getAuthUser()
    {
        Statement authUser = getProperty(A.authUser);
        if (authUser != null) return authUser.getString();
        
        return null;
    }

    @Override
    public String getAuthPwd()
    {
        Statement authPwd = getProperty(A.authPwd);
        if (authPwd != null) return authPwd.getString();
        
        return null;
    }

    @Override
    public SPARQLClient getSPARQLClient()
    {
        return getSPARQLClient(getClient().target(getProxiedURI(URI.create(getSPARQLEndpoint().getURI()))));
    }
    
    /**
     * Creates SPARQL Protocol client for the specified URI web target.
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
        
        if (getAuthUser() != null && getAuthPwd() != null)
        {
            HttpAuthenticationFeature authFeature = HttpAuthenticationFeature.basicBuilder().
                credentials(getAuthUser(), getAuthPwd()).
                build();
            
            sparqlClient.getEndpoint().register(authFeature);
        }
        
        return sparqlClient;
    }
    
    @Override
    public EndpointAccessor getEndpointAccessor()
    {
        return new EndpointAccessorImpl(getSPARQLClient());
    }

    @Override
    public GraphStoreClient getGraphStoreClient()
    {
        return getGraphStoreClient(getClient().target(getProxiedURI(URI.create(getGraphStore().getURI()))));
    }
    
    /**
     * Creates Graph Store Protocol client for the specified URI web target.
     * 
     * @param webTarget URI web target
     * @return GSP client
     */
    public GraphStoreClient getGraphStoreClient(WebTarget webTarget)
    {
        GraphStoreClient graphStoreClient = GraphStoreClient.create(webTarget);
        
        if (getAuthUser() != null && getAuthPwd() != null)
        {
            HttpAuthenticationFeature authFeature = HttpAuthenticationFeature.basicBuilder().
                credentials(getAuthUser(), getAuthPwd()).
                build();
            
            graphStoreClient.getEndpoint().register(authFeature);
        }
        
        return graphStoreClient;
    }
    
    @Override
    public DatasetAccessor getDatasetAccessor()
    {
        return new DatasetAccessorImpl(getGraphStoreClient());
    }

    @Override
    public QuadStoreClient getQuadStoreClient()
    {
        if (getQuadStore() != null) return getQuadStoreClient(getClient().target(getProxiedURI(URI.create(getQuadStore().getURI()))));
        
        return null;
    }
    
    /**
     * Creates Graph Store Protocol client for a given URI target.
     * 
     * @param webTarget URI web target
     * @return GSP client
     */
    public QuadStoreClient getQuadStoreClient(WebTarget webTarget)
    {
        QuadStoreClient quadStoreClient = QuadStoreClient.create(webTarget);
        
        if (getAuthUser() != null && getAuthPwd() != null)
        {
            HttpAuthenticationFeature authFeature = HttpAuthenticationFeature.basicBuilder().
                credentials(getAuthUser(), getAuthPwd()).
                build();
            
            quadStoreClient.getEndpoint().register(authFeature);
        }
        
        return quadStoreClient;
    }
    
    @Override
    public DatasetQuadAccessor getDatasetQuadAccessor()
    {
        return new DatasetQuadAccessorImpl(getQuadStoreClient());
    }
    
    /**
     * Rewrites the given URI using the proxy URI.
     * 
     * @param uri input URI
     * @return proxied URI
     */
    protected URI getProxiedURI(final URI uri)
    {
        // if service proxyURI is set, change the URI host/port to proxyURI host/port
        if (getProxy() != null)
        {
            final URI proxyURI = URI.create(getProxy().getURI());
            
            return UriBuilder.fromUri(uri).
                    scheme(proxyURI.getScheme()).
                    host(proxyURI.getHost()).
                    port(proxyURI.getPort()).
                    build();
        }
        
        return uri;
    }

    @Override
    public Client getClient()
    {
        return client;
    }

    @Override
    public MediaTypes getMediaTypes()
    {
        return mediaTypes;
    }

    @Override
    public Integer getMaxGetRequestSize()
    {
        return maxGetRequestSize;
    }

}
