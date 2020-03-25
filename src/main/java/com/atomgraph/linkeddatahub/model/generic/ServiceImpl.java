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
package com.atomgraph.linkeddatahub.model.generic;

import com.atomgraph.core.MediaTypes;
import com.atomgraph.core.client.GraphStoreClient;
import com.atomgraph.core.client.QuadStoreClient;
import com.atomgraph.core.client.SPARQLClient;
import com.atomgraph.core.model.DatasetQuadAccessor;
import com.atomgraph.core.model.EndpointAccessor;
import com.atomgraph.core.model.impl.remote.DatasetAccessorImpl;
import com.atomgraph.core.model.impl.remote.DatasetQuadAccessorImpl;
import com.atomgraph.core.model.impl.remote.EndpointAccessorImpl;
import com.atomgraph.core.vocabulary.A;
import com.atomgraph.core.vocabulary.SD;
import com.atomgraph.linkeddatahub.model.Service;
import com.sun.jersey.api.client.Client;
import com.sun.jersey.api.client.WebResource;
import com.sun.jersey.api.client.filter.ClientFilter;
import com.sun.jersey.api.client.filter.HTTPBasicAuthFilter;
import java.net.URI;
import javax.ws.rs.core.UriBuilder;
import org.apache.jena.enhanced.EnhGraph;
import org.apache.jena.graph.Node;
import org.apache.jena.query.DatasetAccessor;
import org.apache.jena.rdf.model.Property;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.ResourceFactory;
import org.apache.jena.rdf.model.Statement;
import org.apache.jena.rdf.model.impl.ResourceImpl;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ServiceImpl extends ResourceImpl implements Service
{

    private static final Logger log = LoggerFactory.getLogger(ServiceImpl.class);

    private static final Property AUTH_USER = ResourceFactory.createProperty(org.apache.jena.sparql.engine.http.Service.queryAuthUser.getSymbol());
    private static final Property AUTH_PWD = ResourceFactory.createProperty(org.apache.jena.sparql.engine.http.Service.queryAuthPwd.getSymbol());

    private final Client client;
    private final MediaTypes mediaTypes;
    private final Integer maxGetRequestSize;
    private final URI proxy;
    
    public ServiceImpl(Node n, EnhGraph g, Client client, MediaTypes mediaTypes, Integer maxGetRequestSize, URI proxy)
    {
        super(n, g);
        this.client = client;
        this.mediaTypes = mediaTypes;
        this.maxGetRequestSize = maxGetRequestSize;
        this.proxy = proxy;
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
    public String getAuthUser()
    {
        Statement authUser = getProperty(AUTH_USER);
        if (authUser != null) return authUser.getString();
        
        return null;
    }

    @Override
    public String getAuthPwd()
    {
        Statement authPwd = getProperty(AUTH_PWD);
        if (authPwd != null) return authPwd.getString();
        
        return null;
    }

    @Override
    public SPARQLClient getSPARQLClient()
    {
        return getSPARQLClient(getClient().resource(getProxiedURI(URI.create(getSPARQLEndpoint().getURI()))));
    }
    
    public SPARQLClient getSPARQLClient(WebResource resource)
    {
        SPARQLClient sparqlClient;
        
        if (getMaxGetRequestSize() != null)
            sparqlClient = SPARQLClient.create(resource, getMediaTypes(), getMaxGetRequestSize());
        else
            sparqlClient = SPARQLClient.create(resource, getMediaTypes());
        
        if (getAuthUser() != null && getAuthPwd() != null)
        {
            ClientFilter authFilter = new HTTPBasicAuthFilter(getAuthUser(), getAuthPwd());
            sparqlClient.getWebResource().addFilter(authFilter);
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
        return getGraphStoreClient(getClient().resource(getProxiedURI(URI.create(getGraphStore().getURI()))));
    }
    
    public GraphStoreClient getGraphStoreClient(WebResource resource)
    {
        GraphStoreClient graphStoreClient = GraphStoreClient.create(resource);
        
        if (getAuthUser() != null && getAuthPwd() != null)
        {
            ClientFilter authFilter = new HTTPBasicAuthFilter(getAuthUser(), getAuthPwd());
            graphStoreClient.getWebResource().addFilter(authFilter);
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
        if (getQuadStore() != null) 
            return getQuadStoreClient(getClient().resource(getProxiedURI(URI.create(getQuadStore().getURI()))));
        
        return null;
    }
    
    public QuadStoreClient getQuadStoreClient(WebResource resource)
    {
        QuadStoreClient quadStoreClient = QuadStoreClient.create(resource);
        
        if (getAuthUser() != null && getAuthPwd() != null)
        {
            ClientFilter authFilter = new HTTPBasicAuthFilter(getAuthUser(), getAuthPwd());
            quadStoreClient.getWebResource().addFilter(authFilter);
        }
        
        return quadStoreClient;
    }
    
    @Override
    public DatasetQuadAccessor getDatasetQuadAccessor()
    {
        return new DatasetQuadAccessorImpl(getQuadStoreClient());
    }
    
    protected URI getProxiedURI(final URI uri)
    {
        // if service proxyURI is set, change the URI host/port to proxyURI host/port
        if (getProxy() != null)
            return UriBuilder.fromUri(uri).
                    host(getProxy().getHost()).
                    port(getProxy().getPort()).
                    build();
        
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

    @Override
    public URI getProxy()
    {
        return proxy;
    }
    
}
