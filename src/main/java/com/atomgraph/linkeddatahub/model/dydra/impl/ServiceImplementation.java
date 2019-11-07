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
import com.atomgraph.linkeddatahub.vocabulary.APL;
import com.sun.jersey.api.client.Client;
import org.apache.jena.enhanced.EnhGraph;
import org.apache.jena.enhanced.EnhNode;
import org.apache.jena.enhanced.Implementation;
import org.apache.jena.graph.Node;
import org.apache.jena.ontology.ConversionException;
import org.apache.jena.vocabulary.RDF;

/**
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ServiceImplementation extends Implementation
{

    private final Client client;
    private final MediaTypes mediaTypes;
    private final Integer maxGetRequestSize;

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
            throw new ConversionException( "Cannot convert node " + node.toString() + " to DydraService: it does not have rdf:type apl:DydraService or equivalent");
        }
    }

    @Override
    public boolean canWrap(Node node, EnhGraph eg)
    {
        if (eg == null) throw new IllegalArgumentException("EnhGraph cannot be null");

        return eg.asGraph().contains(node, RDF.type.asNode(), APL.DydraService.asNode());
    }

    public Client getClient()
    {
        return client;
    }
    
    public MediaTypes getMediaTypes()
    {
        return mediaTypes;
    }
    
    public Integer getMaxGetRequestSize()
    {
        return maxGetRequestSize;
    }
    
}
