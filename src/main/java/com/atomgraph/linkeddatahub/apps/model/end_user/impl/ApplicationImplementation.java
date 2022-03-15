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
package com.atomgraph.linkeddatahub.apps.model.end_user.impl;

import com.atomgraph.linkeddatahub.vocabulary.LAPP;
import org.apache.jena.enhanced.EnhGraph;
import org.apache.jena.enhanced.EnhNode;
import org.apache.jena.enhanced.Implementation;
import org.apache.jena.graph.Node;
import org.apache.jena.ontology.ConversionException;
import org.apache.jena.vocabulary.RDF;

/**
 * Jena's implementation factory.
 * 
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class ApplicationImplementation extends Implementation
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
            throw new ConversionException( "Cannot convert node " + node.toString() + " to EndUserApplication: it does not have rdf:type lapp:EndUserApplication or equivalent");
        }
    }

    @Override
    public boolean canWrap(Node node, EnhGraph eg)
    {
        if (eg == null) throw new IllegalArgumentException("EnhGraph cannot be null");

        return eg.asGraph().contains(node, RDF.type.asNode(), LAPP.EndUserApplication.asNode());
    }

}
