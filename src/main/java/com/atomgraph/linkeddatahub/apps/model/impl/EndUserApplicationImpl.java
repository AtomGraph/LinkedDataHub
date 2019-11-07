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

import com.atomgraph.linkeddatahub.apps.model.AdminApplication;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import org.apache.jena.enhanced.EnhGraph;
import org.apache.jena.graph.Node;
import org.apache.jena.rdf.model.Resource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import com.atomgraph.linkeddatahub.vocabulary.LAPP;
import org.apache.jena.enhanced.EnhNode;
import org.apache.jena.enhanced.Implementation;
import org.apache.jena.ontology.ConversionException;
import org.apache.jena.vocabulary.RDF;

/**
 * End-user application implementation.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class EndUserApplicationImpl extends ApplicationImpl implements EndUserApplication
{

    private static final Logger log = LoggerFactory.getLogger(EndUserApplicationImpl.class);
        
    public static Implementation factory = new Implementation()
    {

        @Override
        public EnhNode wrap(Node node, EnhGraph enhGraph)
        {
            if (canWrap(node, enhGraph))
            {
                return new EndUserApplicationImpl(node, enhGraph);
            }
            else
            {
                throw new ConversionException( "Cannot convert node " + node.toString() + " to EndUserApplication: it does not have rdf:type lapp:EndUserApplication or equivalent");
            }
        }

        @Override
        public boolean canWrap(Node node, EnhGraph eg)
        {
            if (eg == null) throw new IllegalArgumentException("EnhGraph cannot be null");

            return eg.asGraph().contains(node, RDF.type.asNode(), LAPP.EndUserApplication.asNode());
        }

    };

    public EndUserApplicationImpl(Node n, EnhGraph g)
    {
        super(n, g);
    }
    
    @Override
    public AdminApplication getAdminApplication()
    {
        Resource app = getPropertyResourceValue(LAPP.adminApplication);
        if (app != null) return app.as(AdminApplication.class);
        
        return null;
    }
    
}
