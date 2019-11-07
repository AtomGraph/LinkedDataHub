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
import org.apache.jena.enhanced.EnhNode;
import org.apache.jena.enhanced.Implementation;
import org.apache.jena.ontology.ConversionException;
import org.apache.jena.rdf.model.impl.ResourceImpl;
import org.apache.jena.vocabulary.RDF;

/**
 * Application implementation.
 * Extends RDF resource implementation.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ApplicationImpl extends ResourceImpl implements Application
{
    private static final Logger log = LoggerFactory.getLogger(ApplicationImpl.class);

    public static Implementation factory = new Implementation() 
    {
        
        @Override
        public EnhNode wrap(Node node, EnhGraph enhGraph)
        {
            if (canWrap(node, enhGraph))
            {
                return new ApplicationImpl(node, enhGraph);
            }
            else
            {
                throw new ConversionException("Cannot convert node " + node.toString() + " to Application: it does not have rdf:type lapp:Application or equivalent");
            }
        }

        @Override
        public boolean canWrap(Node node, EnhGraph eg)
        {
            if (eg == null) throw new IllegalArgumentException("EnhGraph cannot be null");
            
            return eg.asGraph().contains(node, RDF.type.asNode(), LAPP.Application.asNode());
        }
        
    };
    
    public ApplicationImpl(Node n, EnhGraph g)
    {
        super(n, g);
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
        
        // cast to specific implementations
        if (service.canAs(com.atomgraph.linkeddatahub.model.dydra.Service.class)) service = service.as(com.atomgraph.linkeddatahub.model.dydra.Service.class);
        
        if (service != null) return service.as(Service.class);
        
        return null;
    }

    @Override
    public Resource getStylesheet()
    {
        return getPropertyResourceValue(AC.stylesheet);
    }
    
}
