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
package com.atomgraph.linkeddatahub.apps.model.impl;

import com.atomgraph.client.vocabulary.AC;
import com.atomgraph.core.MediaTypes;
import com.atomgraph.core.client.LinkedDataClient;
import com.atomgraph.linkeddatahub.apps.model.Application;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.vocabulary.FOAF;
import com.atomgraph.linkeddatahub.vocabulary.LAPP;
import com.atomgraph.processor.vocabulary.LDT;
import org.apache.jena.enhanced.EnhGraph;
import org.apache.jena.graph.Node;
import org.apache.jena.rdf.model.Resource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.net.URI;
import javax.ws.rs.client.Client;
import javax.ws.rs.core.UriBuilder;
import org.apache.jena.rdf.model.impl.ResourceImpl;

/**
 * Application implementation.
 * Extends RDF resource implementation.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ApplicationImpl extends ResourceImpl implements Application
{
    private static final Logger log = LoggerFactory.getLogger(ApplicationImpl.class);

    private final Client client;
    private final MediaTypes mediaTypes;
    private final Integer maxGetRequestSize;
    
    public ApplicationImpl(Node n, EnhGraph g, Client client, MediaTypes mediaTypes, Integer maxGetRequestSize)
    {
        super(n, g);
        this.client = client;
        this.mediaTypes = mediaTypes;
        this.maxGetRequestSize = maxGetRequestSize;
    }
    
    @Override
    public Resource getBase()
    {
        return getPropertyResourceValue(LDT.base);
    }
    
    @Override
    public URI getBaseURI()
    {
        return URI.create(getBase().getURI());
    }

    @Override
    public Resource getMaker()
    {
        return getPropertyResourceValue(FOAF.maker);
    }
    
    @Override
    public Resource getOntology()
    {
        return getPropertyResourceValue(LDT.ontology);
    }

    @Override
    public Service getService()
    {
        Resource service = getPropertyResourceValue(LDT.service);
        
        if (service != null)
        {
            // cast to specific implementations
            if (service.canAs(com.atomgraph.linkeddatahub.model.DydraService.class)) return service.as(com.atomgraph.linkeddatahub.model.DydraService.class);

            return service.as(Service.class);
        }
        
        return null;
    }

    @Override
    public Resource getStylesheet()
    {
        return getPropertyResourceValue(AC.stylesheet);
    }
    
    @Override
    public Resource getProxy()
    {
        return getPropertyResourceValue(LAPP.proxy);
    }
    
    @Override
    public LinkedDataClient getLinkedDataClient(URI uri)
    {
        return LinkedDataClient.create(getClient().target(getProxiedURI(uri)), getMediaTypes());
    }
    
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
