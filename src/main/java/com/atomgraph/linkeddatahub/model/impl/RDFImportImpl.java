/**
 *  Copyright 2020 Martynas Jusevičius <martynas@atomgraph.com>
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

import com.atomgraph.core.vocabulary.SD;
import com.atomgraph.linkeddatahub.model.RDFImport;
import com.atomgraph.linkeddatahub.vocabulary.APL;
import com.atomgraph.spinrdf.vocabulary.SPIN;
import org.apache.jena.enhanced.EnhGraph;
import org.apache.jena.enhanced.EnhNode;
import org.apache.jena.enhanced.Implementation;
import org.apache.jena.graph.Node;
import org.apache.jena.ontology.ConversionException;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.vocabulary.RDF;

/**
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class RDFImportImpl extends ImportImpl implements RDFImport
{
    
    public static Implementation factory = new Implementation() 
    {
        
        @Override
        public EnhNode wrap(Node node, EnhGraph enhGraph)
        {
            if (canWrap(node, enhGraph))
            {
                return new RDFImportImpl(node, enhGraph);
            }
            else
            {
                throw new ConversionException( "Cannot convert node " + node.toString() + " to Import: it does not have rdf:type apl:RDFImport or equivalent");
            }
        }

        @Override
        public boolean canWrap(Node node, EnhGraph eg)
        {
            if (eg == null) throw new IllegalArgumentException("EnhGraph cannot be null");

            return eg.asGraph().contains(node, RDF.type.asNode(), APL.RDFImport.asNode());
        }
    };
    
    public RDFImportImpl(Node n, EnhGraph g)
    {
        super(n, g);
    }

    @Override
    public Resource getQuery()
    {
        return getPropertyResourceValue(SPIN.query);
    }

    @Override
    public Resource getGraphName()
    {
        return getPropertyResourceValue(SD.name);
    }
    
}
