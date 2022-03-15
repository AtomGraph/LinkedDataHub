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

import com.atomgraph.linkeddatahub.model.CSVImport;
import com.atomgraph.linkeddatahub.vocabulary.LDH;
import com.atomgraph.spinrdf.vocabulary.SPIN;
import org.apache.jena.enhanced.EnhGraph;
import org.apache.jena.enhanced.EnhNode;
import org.apache.jena.enhanced.Implementation;
import org.apache.jena.graph.Node;
import org.apache.jena.ontology.ConversionException;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.vocabulary.RDF;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * CSV import implementation.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class CSVImportImpl extends ImportImpl implements CSVImport
{

    private static final Logger log = LoggerFactory.getLogger(CSVImportImpl.class);

    /**
     * The implementation factory.
     */
    public static Implementation factory = new Implementation() 
    {
        
        @Override
        public EnhNode wrap(Node node, EnhGraph enhGraph)
        {
            if (canWrap(node, enhGraph))
            {
                return new CSVImportImpl(node, enhGraph);
            }
            else
            {
                throw new ConversionException( "Cannot convert node " + node.toString() + " to Import: it does not have rdf:type apl:CSVImport or equivalent");
            }
        }

        @Override
        public boolean canWrap(Node node, EnhGraph eg)
        {
            if (eg == null) throw new IllegalArgumentException("EnhGraph cannot be null");

            return eg.asGraph().contains(node, RDF.type.asNode(), LDH.CSVImport.asNode());
        }
    };

    /**
     * Constructs instance from node and graph.
     * 
     * @param n node
     * @param g graph
     */
    public CSVImportImpl(Node n, EnhGraph g)
    {
        super(n, g);
    }

    @Override
    public Resource getQuery()
    {
        return getPropertyResourceValue(SPIN.query);
    }

    @Override
    public char getDelimiter()
    {
        return getRequiredProperty(LDH.delimiter).getChar();
    }
    
}
