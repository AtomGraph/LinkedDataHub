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

import com.atomgraph.linkeddatahub.model.XMLImport;
import com.atomgraph.linkeddatahub.vocabulary.APL;
import java.net.URI;
import org.apache.jena.enhanced.EnhGraph;
import org.apache.jena.enhanced.EnhNode;
import org.apache.jena.enhanced.Implementation;
import org.apache.jena.graph.Node;
import org.apache.jena.ontology.ConversionException;
import org.apache.jena.vocabulary.RDF;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class XMLImportImpl extends ImportImpl implements XMLImport
{
    
    private static final Logger log = LoggerFactory.getLogger(XMLImportImpl.class);

    public static Implementation factory = new Implementation() 
    {
        
        @Override
        public EnhNode wrap(Node node, EnhGraph enhGraph)
        {
            if (canWrap(node, enhGraph))
            {
                return new XMLImportImpl(node, enhGraph);
            }
            else
            {
                throw new ConversionException( "Cannot convert node " + node.toString() + " to Import: it does not have rdf:type apl:XMLImport or equivalent");
            }
        }

        @Override
        public boolean canWrap(Node node, EnhGraph eg)
        {
            if (eg == null) throw new IllegalArgumentException("EnhGraph cannot be null");

            return eg.asGraph().contains(node, RDF.type.asNode(), APL.XMLImport.asNode());
        }
    };
    
    // TO-DO: load media types from apl:CSVImport restriction?
    public static javax.ws.rs.core.MediaType[] MEDIA_TYPES = { com.atomgraph.linkeddatahub.MediaType.valueOf(URI.create("http://www.sparontologies.net/mediatype/application/xml")), 
        com.atomgraph.linkeddatahub.MediaType.valueOf(URI.create("http://www.sparontologies.net/mediatype/text/xml")) };
    
    public XMLImportImpl(Node n, EnhGraph g)
    {
        super(n, g);
    }

}
