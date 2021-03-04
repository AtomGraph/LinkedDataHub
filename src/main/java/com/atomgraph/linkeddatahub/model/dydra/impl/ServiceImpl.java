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
package com.atomgraph.linkeddatahub.model.dydra.impl;

import com.atomgraph.core.MediaTypes;
import com.atomgraph.linkeddatahub.vocabulary.Dydra;
import org.apache.jena.enhanced.EnhGraph;
import org.apache.jena.graph.Node;
import org.apache.jena.rdf.model.Resource;
import com.atomgraph.linkeddatahub.model.dydra.Service;
import com.atomgraph.linkeddatahub.vocabulary.dydra.URN;
import org.apache.jena.rdf.model.Statement;
import com.atomgraph.linkeddatahub.client.SesameProtocolClient;
import com.atomgraph.linkeddatahub.client.dydra.GraphStoreClient;
import com.atomgraph.linkeddatahub.client.dydra.QuadStoreClient;
import java.net.URI;
import javax.ws.rs.client.Client;
import javax.ws.rs.client.ClientRequestFilter;
import javax.ws.rs.client.WebTarget;
import org.glassfish.jersey.client.authentication.HttpAuthenticationFeature;

/**
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ServiceImpl extends com.atomgraph.linkeddatahub.model.generic.ServiceImpl implements Service
{

    public ServiceImpl(Node n, EnhGraph g, Client client, MediaTypes mediaTypes, Integer maxGetRequestSize)
    {
        super(n, g, client, mediaTypes, maxGetRequestSize);
    }

    @Override
    public Resource getRepository()
    {
        return getPropertyResourceValue(Dydra.repository);
    }

    @Override
    public Resource getSPARQLEndpoint()
    {
        if (getRepository().getURI().endsWith("/")) return getModel().createResource(getRepository().getURI() + "sparql");
            
        // does not use sd:endpoint property
        return getModel().createResource(getRepository().getURI() + "/sparql");
    }

    @Override
    public Resource getGraphStore()
    {
        if (getRepository().getURI().endsWith("/")) return getModel().createResource(getRepository().getURI() + "service");

        // does not use a:graphStore property
        return getModel().createResource(getRepository().getURI() + "/service");
    }
    
    @Override
    public Resource getQuadStore()
    {
        return getGraphStore(); // quad store is also /service
    }
    
    @Override
    public String getAccessToken()
    {
        Statement accessToken = getProperty(URN.accessToken);
        if (accessToken != null) return accessToken.getString();
        
        return null;
    }
    
    @Override
    public SesameProtocolClient getSPARQLClient()
    {
        return getSPARQLClient(getClient().target(getProxiedURI(URI.create(getSPARQLEndpoint().getURI()))));
    }
    
    @Override
    public SesameProtocolClient getSPARQLClient(WebTarget resource) // uses SesameProtocolClient which supports remote bindings
    {
        SesameProtocolClient sparqlClient;
        
        if (getMaxGetRequestSize() != null)
            sparqlClient = new SesameProtocolClient(resource, getMediaTypes(), getMaxGetRequestSize());
        else
            sparqlClient = new SesameProtocolClient(resource, getMediaTypes());
        
        if (getAuthUser() != null && getAuthPwd() != null)
        {
            HttpAuthenticationFeature authFeature = HttpAuthenticationFeature.basicBuilder().
                credentials(getAuthUser(), getAuthPwd()).
                build();
            
            sparqlClient.getEndpoint().register(authFeature);
        }
        if (getAccessToken() != null)
        {
            ClientRequestFilter authFilter = new AuthTokenFilter(getAccessToken());
            sparqlClient.register(authFilter);
        }
        
        return sparqlClient;
    }

    @Override
    public GraphStoreClient getGraphStoreClient(WebTarget resource)
    {
        GraphStoreClient graphStoreClient = GraphStoreClient.create(resource);
        
        if (getAuthUser() != null && getAuthPwd() != null)
        {
            HttpAuthenticationFeature authFeature = HttpAuthenticationFeature.basicBuilder().
                credentials(getAuthUser(), getAuthPwd()).
                build();
            
            graphStoreClient.getEndpoint().register(authFeature);
        }
        
        if (getAccessToken() != null) graphStoreClient.register(new AuthTokenFilter(getAccessToken())); // TO-DO
        
        return graphStoreClient;
    }
    
    @Override
    public QuadStoreClient getQuadStoreClient(WebTarget resource)
    {
        QuadStoreClient quadStoreClient = QuadStoreClient.create(resource);
        
        if (getAuthUser() != null && getAuthPwd() != null)
        {
            HttpAuthenticationFeature authFeature = HttpAuthenticationFeature.basicBuilder().
                credentials(getAuthUser(), getAuthPwd()).
                build();
            
            quadStoreClient.getEndpoint().register(authFeature);
        }
        
        if (getAccessToken() != null) quadStoreClient.register(new AuthTokenFilter(getAccessToken())); // TO-DO
        
        return quadStoreClient;
    }

}
