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
import com.atomgraph.core.vocabulary.SD;
import javax.ws.rs.client.Client;
import org.apache.jena.enhanced.EnhGraph;
import org.apache.jena.enhanced.EnhNode;
import org.apache.jena.enhanced.Implementation;
import org.apache.jena.graph.Node;
import org.apache.jena.ontology.ConversionException;
import org.apache.jena.vocabulary.RDF;

/**
 * Jena's implementation factory.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ServiceImplementation extends Implementation
{
    
    private final Client client;
    private final MediaTypes mediaTypes;
    private final Integer maxGetRequestSize;

    /**
     * Constructs factory from HTTP configuration.
     * 
     * @param client HTTP client
     * @param mediaTypes registry of readable/writable media types
     * @param maxGetRequestSize the maximum size of SPARQL <code>GET</code> requests
     */
    public ServiceImplementation(Client client, MediaTypes mediaTypes, Integer maxGetRequestSize)
    {
        this.client = client;
        this.mediaTypes = mediaTypes;
        this.maxGetRequestSize = maxGetRequestSize;
    }
    
    @Override
    public EnhNode wrap(Node node, EnhGraph enhGraph)
    {
        if (canWrap(node, enhGraph))
        {
            return new ServiceImpl(node, enhGraph, getClient(), getMediaTypes(), getMaxGetRequestSize());
        }
        else
        {
            throw new ConversionException( "Cannot convert node " + node.toString() + " to Service: it does not have rdf:type sd:Service or equivalent");
        }
    }

    @Override
    public boolean canWrap(Node node, EnhGraph eg)
    {
        if (eg == null) throw new IllegalArgumentException("EnhGraph cannot be null");

        return eg.asGraph().contains(node, RDF.type.asNode(), SD.Service.asNode());
    }
 
    /**
     * Returns HTTP client.
     * 
     * @return HTTP client
     */
    public Client getClient()
    {
        return client;
    }
    
    /**
     * Returns a registry of readable/writable media types.
     * 
     * @return media type registry
     */
    public MediaTypes getMediaTypes()
    {
        return mediaTypes;
    }
    
    /**
     * Returns the maximum size of SPARQL <code>GET</code> requests.
     * 
     * @return request size in bytes
     */
    public Integer getMaxGetRequestSize()
    {
        return maxGetRequestSize;
    }
    
}
